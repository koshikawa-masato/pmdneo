#!/usr/bin/env python3
"""
scripts/analyze-audio.py
PMDNEO 自動 audio gate の WAV 解析 (= numpy + scipy.signal、 librosa 不要)

由来: neo-sisters/scripts/analyze-audio.py を port + PMDNEO 用拡張:
  - skip_seconds (= BIOS boot 区間スキップ)
  - onset detection (= short-time RMS envelope 50ms windows)
  - BPM 推定 (= 60 / median(inter-onset))
  - assert_peak_hz (= 主要周波数が target ±tol 以内か)
  - assert_rms_window (= [start, end] 区間 RMS が threshold より大/小)
  - assert_bpm (= 推定 BPM が target ±tol 以内か)
  - assert_onset_count (= 検出 onset 数が target に一致)
  - baseline diff (= 直前 JSON との差分 report、 memory feedback_log_self_check.md)

使い方:
    python3 analyze-audio.py --input <wav> [options]

    --skip-seconds N           : 先頭 N 秒スキップ (= BIOS boot 区間)
    --json                     : 機械 parse 用 JSON 出力 (= stdout)
    --baseline path.json       : 直前 JSON との差分 report
    --assert-rms-min V         : 全体 RMS が V 以上
    --assert-peak-hz F --tol-hz T : 主要周波数 1 つが F±T Hz 以内
    --assert-bpm B --tol-bpm T : 推定 BPM が B±T 以内
    --assert-onset-count N     : 検出 onset 数 == N
    --assert-rms-window-min S E V: [S秒, E秒] 区間 RMS が V 以上
    --assert-rms-window-max S E V: [S秒, E秒] 区間 RMS が V 以下

Exit code:
    0 = 全 assertion pass + silent でない
    1 = 1 つ以上の assertion fail or silent
    2 = python error (= load 失敗等)
"""

import argparse
import json
import sys
import wave
from pathlib import Path

import numpy as np


def load_wav(path: Path):
    with wave.open(str(path), "rb") as wf:
        n_channels = wf.getnchannels()
        sample_width = wf.getsampwidth()
        framerate = wf.getframerate()
        n_frames = wf.getnframes()
        raw = wf.readframes(n_frames)

    if sample_width == 2:
        samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    elif sample_width == 1:
        samples = (np.frombuffer(raw, dtype=np.uint8).astype(np.float32) - 128.0) / 128.0
    else:
        raise ValueError(f"Unsupported sample width: {sample_width} bytes")

    if n_channels > 1:
        samples = samples.reshape(-1, n_channels).mean(axis=1)

    return {
        "samples": samples,
        "framerate": framerate,
        "n_channels": n_channels,
        "sample_width": sample_width,
        "n_frames": n_frames,
        "duration_sec": n_frames / framerate,
    }


def compute_basic_stats(samples: np.ndarray, framerate: int) -> dict:
    if samples.size == 0:
        return {"rms": 0.0, "peak": 0.0, "zero_cross_rate_per_sec": 0.0}
    rms = float(np.sqrt(np.mean(samples ** 2)))
    peak = float(np.max(np.abs(samples)))
    zero_crosses = int(np.sum(np.abs(np.diff(np.sign(samples))) > 0))
    zero_cross_rate = zero_crosses / (len(samples) / framerate)
    return {
        "rms": rms,
        "peak": peak,
        "zero_cross_rate_per_sec": zero_cross_rate,
    }


def compute_top_freq_peaks(samples: np.ndarray, framerate: int, top_n: int = 5):
    if samples.size < framerate // 4:
        return []
    # 中央 1 秒窓 (= start/end click 除外)
    if len(samples) >= framerate:
        analysis_window = samples[framerate // 4 : framerate // 4 + framerate]
    else:
        analysis_window = samples
    n = len(analysis_window)
    if n == 0:
        return []
    fft = np.fft.rfft(analysis_window * np.hanning(n))
    magnitude = np.abs(fft)
    freqs = np.fft.rfftfreq(n, d=1.0 / framerate)
    valid_mask = freqs >= 20.0
    valid_mag = magnitude * valid_mask
    if valid_mag.max() == 0:
        return []
    top_indices = np.argsort(valid_mag)[-top_n:][::-1]
    threshold = magnitude.max() * 0.05
    return [
        {"freq_hz": float(freqs[i]), "magnitude": float(magnitude[i])}
        for i in top_indices
        if magnitude[i] > threshold
    ]


def detect_onsets(samples: np.ndarray, framerate: int,
                  window_ms: int = 50, threshold_ratio: float = 3.0):
    """short-time RMS envelope 上の急峻な立ち上がり。 onset timestamps (sec)。"""
    if samples.size == 0:
        return []
    win = max(1, int(framerate * window_ms / 1000))
    n_frames = len(samples) // win
    if n_frames < 2:
        return []
    # 各 window の RMS
    rms_env = np.array([
        np.sqrt(np.mean(samples[i * win:(i + 1) * win] ** 2))
        for i in range(n_frames)
    ])
    # 急峻な立ち上がり = 直前 RMS の threshold_ratio 倍超
    eps = 1e-6
    onsets = []
    last_onset_frame = -2
    median_rms = float(np.median(rms_env)) if len(rms_env) > 0 else 0.0
    floor = max(median_rms * 0.5, 0.001)
    for i in range(1, n_frames):
        if rms_env[i] < floor:
            continue
        if rms_env[i] > rms_env[i - 1] * threshold_ratio + eps:
            # 隣接 window の重複検出 を skip
            if i - last_onset_frame >= 2:
                onsets.append(i * window_ms / 1000.0)
                last_onset_frame = i
    return onsets


def estimate_bpm(onsets: list) -> float:
    if len(onsets) < 2:
        return 0.0
    intervals = np.diff(onsets)
    if len(intervals) == 0:
        return 0.0
    median_interval = float(np.median(intervals))
    if median_interval <= 0:
        return 0.0
    # onsets は 1 拍ごとと仮定 (= quarter note)
    bpm = 60.0 / median_interval
    return bpm


def rms_in_window(samples: np.ndarray, framerate: int, start_s: float, end_s: float) -> float:
    s_start = max(0, int(start_s * framerate))
    s_end = min(len(samples), int(end_s * framerate))
    if s_end <= s_start:
        return 0.0
    seg = samples[s_start:s_end]
    return float(np.sqrt(np.mean(seg ** 2)))


def make_assertion(name, expected, actual, passed, **extra):
    return {"name": name, "expected": expected, "actual": actual, "pass": passed, **extra}


def main():
    parser = argparse.ArgumentParser(description="PMDNEO audio gate WAV 解析")
    parser.add_argument("--input", required=True)
    parser.add_argument("--threshold", type=float, default=0.001,
                        help="silent 判定 RMS 閾値 (= 0.001 default)")
    parser.add_argument("--skip-seconds", type=float, default=0.0,
                        help="先頭 N 秒スキップ (= BIOS boot 区間)")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--baseline", default=None,
                        help="直前 JSON との diff report")
    # assertions
    parser.add_argument("--assert-rms-min", type=float, default=None)
    parser.add_argument("--assert-peak-hz", type=float, default=None)
    parser.add_argument("--tol-hz", type=float, default=8.0)
    parser.add_argument("--assert-bpm", type=float, default=None)
    parser.add_argument("--tol-bpm", type=float, default=6.0)
    parser.add_argument("--assert-onset-count", type=int, default=None)
    parser.add_argument("--assert-rms-window-min", nargs=3, default=None,
                        metavar=("START_S", "END_S", "MIN_V"),
                        help="[START_S, END_S] 区間 RMS が MIN_V 以上")
    parser.add_argument("--assert-rms-window-max", nargs=3, default=None,
                        metavar=("START_S", "END_S", "MAX_V"),
                        help="[START_S, END_S] 区間 RMS が MAX_V 以下")
    args = parser.parse_args()

    wav_path = Path(args.input)
    if not wav_path.exists():
        print(f"✗ WAV not found: {wav_path}", file=sys.stderr)
        sys.exit(2)
    try:
        wav_data = load_wav(wav_path)
    except Exception as e:
        print(f"✗ WAV load error: {e}", file=sys.stderr)
        sys.exit(2)

    full_samples = wav_data["samples"]
    framerate = wav_data["framerate"]
    duration = wav_data["duration_sec"]

    # skip-seconds 適用
    skip_n = int(args.skip_seconds * framerate)
    samples = full_samples[skip_n:] if skip_n < len(full_samples) else full_samples[:0]

    # stats
    basic = compute_basic_stats(samples, framerate)
    top_peaks = compute_top_freq_peaks(samples, framerate)
    onsets = detect_onsets(samples, framerate)
    bpm = estimate_bpm(onsets)

    stats = {
        "rms": basic["rms"],
        "peak": basic["peak"],
        "zero_cross_rate_per_sec": basic["zero_cross_rate_per_sec"],
        "top_frequency_peaks": top_peaks,
        "onsets_sec": [round(o, 3) for o in onsets],
        "estimated_bpm": round(bpm, 2),
    }

    # assertions
    assertions = []

    # silent 判定 (= default、 常に評価)
    silent = stats["rms"] < args.threshold
    assertions.append(make_assertion(
        "not_silent", f">= {args.threshold}", stats["rms"], not silent
    ))

    if args.assert_rms_min is not None:
        passed = stats["rms"] >= args.assert_rms_min
        assertions.append(make_assertion(
            "rms_min", args.assert_rms_min, stats["rms"], passed
        ))

    if args.assert_peak_hz is not None:
        # top peaks のいずれかが target ±tol 以内
        target = args.assert_peak_hz
        tol = args.tol_hz
        match = next(
            (p for p in top_peaks if abs(p["freq_hz"] - target) <= tol),
            None,
        )
        passed = match is not None
        actual = match["freq_hz"] if match else (top_peaks[0]["freq_hz"] if top_peaks else 0.0)
        assertions.append(make_assertion(
            "peak_hz", target, actual, passed, tol_hz=tol
        ))

    if args.assert_bpm is not None:
        target = args.assert_bpm
        tol = args.tol_bpm
        passed = abs(stats["estimated_bpm"] - target) <= tol
        assertions.append(make_assertion(
            "bpm", target, stats["estimated_bpm"], passed, tol_bpm=tol
        ))

    if args.assert_onset_count is not None:
        passed = len(onsets) == args.assert_onset_count
        assertions.append(make_assertion(
            "onset_count", args.assert_onset_count, len(onsets), passed
        ))

    if args.assert_rms_window_min is not None:
        s_start, s_end, min_v = args.assert_rms_window_min
        s_start, s_end, min_v = float(s_start), float(s_end), float(min_v)
        # window は full_samples (= skip 適用前) の絶対秒
        rms_w = rms_in_window(full_samples, framerate, s_start, s_end)
        passed = rms_w >= min_v
        assertions.append(make_assertion(
            f"rms_window_min[{s_start},{s_end}]", min_v, rms_w, passed
        ))

    if args.assert_rms_window_max is not None:
        s_start, s_end, max_v = args.assert_rms_window_max
        s_start, s_end, max_v = float(s_start), float(s_end), float(max_v)
        rms_w = rms_in_window(full_samples, framerate, s_start, s_end)
        passed = rms_w <= max_v
        assertions.append(make_assertion(
            f"rms_window_max[{s_start},{s_end}]", max_v, rms_w, passed
        ))

    # baseline diff
    baseline_diff = None
    if args.baseline:
        try:
            with open(args.baseline) as f:
                base = json.load(f)
            base_stats = base.get("stats", {})
            baseline_diff = {
                "rms_delta_pct": (
                    (stats["rms"] - base_stats.get("rms", 0)) / max(base_stats.get("rms", 1e-9), 1e-9) * 100
                ),
                "bpm_delta": stats["estimated_bpm"] - base_stats.get("estimated_bpm", 0),
                "onset_count_delta": len(onsets) - len(base_stats.get("onsets_sec", [])),
            }
            baseline_diff = {k: round(v, 3) for k, v in baseline_diff.items()}
        except Exception as e:
            baseline_diff = {"error": str(e)}

    overall_pass = all(a["pass"] for a in assertions)
    verdict = "pass" if overall_pass else "fail"

    result = {
        "input": str(wav_path),
        "duration_sec": round(duration, 3),
        "framerate": framerate,
        "channels": wav_data["n_channels"],
        "skip_seconds": args.skip_seconds,
        "stats": stats,
        "assertions": assertions,
        "verdict": verdict,
    }
    if baseline_diff:
        result["baseline_diff"] = baseline_diff

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"WAV file:      {wav_path}")
        print(f"  duration:    {duration:.2f} sec  (skip: {args.skip_seconds}s)")
        print(f"  framerate:   {framerate} Hz")
        print(f"  RMS:         {stats['rms']:.6f}")
        print(f"  peak:        {stats['peak']:.6f}")
        print(f"  zero crosses:{stats['zero_cross_rate_per_sec']:.1f} /sec")
        if top_peaks:
            print(f"  top freqs:")
            for p in top_peaks:
                print(f"    {p['freq_hz']:8.2f} Hz  (mag {p['magnitude']:.2e})")
        print(f"  onsets ({len(onsets)}): {[round(o, 3) for o in onsets[:8]]}{'...' if len(onsets) > 8 else ''}")
        print(f"  est BPM:     {stats['estimated_bpm']:.2f}")
        if baseline_diff:
            print(f"  baseline diff: RMS {baseline_diff.get('rms_delta_pct', '?'):+.1f}%, "
                  f"BPM {baseline_diff.get('bpm_delta', '?'):+.2f}, "
                  f"onsets {baseline_diff.get('onset_count_delta', '?'):+d}")
        print(f"  assertions:")
        for a in assertions:
            mark = "✓" if a["pass"] else "✗"
            print(f"    {mark} {a['name']}: expected={a['expected']}, actual={a['actual']}")
        print(f"  verdict:     {'✓ PASS' if overall_pass else '✗ FAIL'}")

    sys.exit(0 if overall_pass else 1)


if __name__ == "__main__":
    main()
