#!/usr/bin/env python3
"""
scripts/analyze-audition-wav.py = ADR-0065 sprint B = audition readiness gate executor

ADR-0065 §決定 13 4 層 engineering gate + §決定 14 Codex Rescue review 5 軸 framework の
executor。 human audition (= 越川氏 listening session) 前に main agent が pass させる
engineering gate (= 41st session δ session 試行 invalid 経路 process failure 再発防止)。

4 層 gate:
  Layer 1 WAV hygiene: duration / RMS / clipping / sample rate / low-freq dominance
  Layer 2 event/trace alignment: MAME trace event match + wav energy correspondence
  Layer 3 reference comparison: production binary baseline L2 + STFT cosine similarity
  Layer 4 audition readiness report: markdown report + verdict

Verdict:
  pass = ALL 4 layers PASS or SKIP (= no fail) → ready_for_audition = true → exit 0
  fail = 1+ layer FAIL → ready_for_audition = false → exit 1

重要 (= memory `feedback_metric_pass_is_not_aesthetic_pass.md` 整合):
  metric pass != aesthetic approve。 gate ALL PASS は「engineering gate clear =
  human audition に出して OK」 を意味する (= 機械的検証通過 = process failure 排除)。
  aesthetic accept (= 越川氏「これで OK」 審美判断) ではない。 aesthetic 判断は user
  authoritative role、 この gate は前段の engineering 検査のみ。

Final thresholds (= ADR-0065 Annex β-10-1 record、 sprint B initial values):
  LR1 = LOW_FREQ_DOMINANCE_THRESHOLD = 0.7 は正常 bass/rhythm material 誤 reject 可能性あり、
        production binary baseline で後続 calibration 必要 = sprint B 完走後 follow-up 候補

Usage:
  python3 scripts/analyze-audition-wav.py \\
    --wav <audio.wav> \\
    --trace <mame_trace.txt> \\
    --expected <expected.json> \\
    [--baseline <baseline.wav>] \\
    --output-json <analysis.json> \\
    --output-report <readiness.md>

Exit code:
  0 = verdict pass + ready_for_audition true
  1 = verdict fail + ready_for_audition false
  2 = python error (= load fail / invalid input)
"""

import argparse
import json
import re
import sys
import wave
from pathlib import Path

import numpy as np


# Final thresholds (= ADR-0065 Annex β-10-1 literal record、 sprint B initial values)
DURATION_TOLERANCE_SEC = 0.1
SILENCE_THRESHOLD_DBFS = -60.0
CLIPPING_THRESHOLD = 0.01  # 1%
SAMPLE_RATE_EXPECTED = 48000
LOW_FREQ_DOMINANCE_THRESHOLD = 0.7  # < cutoff_hz energy fraction
LOW_FREQ_CUTOFF_HZ = 200
L2_DIFF_THRESHOLD = 0.5  # normalized RMS-like waveform diff
SPECTRAL_SIMILARITY_THRESHOLD = 0.6  # STFT magnitude cosine similarity
EVENT_TIMESTAMP_TOLERANCE_US = 10000  # ±10ms
ENERGY_CORRESPONDENCE_WINDOW_PRE_MS = 50
ENERGY_CORRESPONDENCE_WINDOW_POST_MS = 150
ENERGY_CORRESPONDENCE_RATE_THRESHOLD = 0.9


def load_wav(path):
    """Load WAV file. Return (samples_mono_float in [-1,1], sample_rate, n_channels)."""
    with wave.open(str(path), "rb") as wf:
        sr = wf.getframerate()
        n_ch = wf.getnchannels()
        n_frames = wf.getnframes()
        sample_width = wf.getsampwidth()
        raw = wf.readframes(n_frames)

    if sample_width == 1:
        samples = np.frombuffer(raw, dtype=np.uint8).astype(np.float64) - 128.0
        scale = 127.0
    elif sample_width == 2:
        samples = np.frombuffer(raw, dtype=np.int16).astype(np.float64)
        scale = 32768.0
    elif sample_width == 4:
        samples = np.frombuffer(raw, dtype=np.int32).astype(np.float64)
        scale = 2147483648.0
    else:
        raise ValueError(f"Unsupported sample width: {sample_width}")

    if n_ch > 1:
        samples = samples.reshape(-1, n_ch).mean(axis=1)
    samples = samples / scale

    return samples, sr, n_ch


def compute_rms_dbfs(samples):
    if len(samples) == 0:
        return -float("inf")
    rms = float(np.sqrt(np.mean(samples ** 2)))
    if rms == 0:
        return -float("inf")
    return 20.0 * np.log10(rms)


def compute_clipping_rate(samples):
    if len(samples) == 0:
        return 0.0
    return float(np.mean(np.abs(samples) >= 0.99))


def compute_peak_amplitude(samples):
    if len(samples) == 0:
        return 0.0
    return float(np.max(np.abs(samples)))


def compute_low_freq_fraction(samples, sr, cutoff_hz):
    if len(samples) == 0 or sr <= 0:
        return 0.0
    fft_mag = np.abs(np.fft.rfft(samples))
    freqs = np.fft.rfftfreq(len(samples), 1.0 / sr)
    total_energy = float(np.sum(fft_mag ** 2))
    if total_energy == 0:
        return 0.0
    low_energy = float(np.sum(fft_mag[freqs < cutoff_hz] ** 2))
    return low_energy / total_energy


def layer1_wav_hygiene(samples, sr, n_ch, expected):
    """Layer 1: WAV hygiene check."""
    duration_sec = len(samples) / sr if sr > 0 else 0.0
    rms_dbfs = compute_rms_dbfs(samples)
    clipping_rate = compute_clipping_rate(samples)
    peak_amplitude = compute_peak_amplitude(samples)
    low_freq_fraction = compute_low_freq_fraction(samples, sr, LOW_FREQ_CUTOFF_HZ)
    expected_duration = expected.get("duration_sec")

    fails = []
    if expected_duration is not None:
        diff = abs(duration_sec - expected_duration)
        if diff > DURATION_TOLERANCE_SEC:
            fails.append(
                f"duration mismatch: {duration_sec:.3f}s vs expected {expected_duration:.3f}s "
                f"(diff {diff:.3f}s > tolerance {DURATION_TOLERANCE_SEC}s)"
            )
    if rms_dbfs < SILENCE_THRESHOLD_DBFS:
        rms_display = f"{rms_dbfs:.1f}" if rms_dbfs != -float("inf") else "-inf"
        fails.append(f"silence detected: RMS={rms_display} dBFS (threshold > {SILENCE_THRESHOLD_DBFS} dBFS)")
    if clipping_rate >= CLIPPING_THRESHOLD:
        fails.append(f"clipping rate {clipping_rate:.4f} >= threshold {CLIPPING_THRESHOLD}")
    if sr != SAMPLE_RATE_EXPECTED:
        fails.append(f"sample rate {sr} Hz, expected {SAMPLE_RATE_EXPECTED} Hz")
    if low_freq_fraction > LOW_FREQ_DOMINANCE_THRESHOLD:
        fails.append(
            f"low-frequency dominance: {low_freq_fraction:.3f} > threshold {LOW_FREQ_DOMINANCE_THRESHOLD} "
            f"(< {LOW_FREQ_CUTOFF_HZ} Hz energy fraction) — possible abnormal low-freq persistence"
        )

    rms_metric = round(rms_dbfs, 2) if rms_dbfs != -float("inf") else -999.0
    return {
        "status": "pass" if not fails else "fail",
        "metrics": {
            "duration_sec": round(duration_sec, 4),
            "duration_expected": expected_duration,
            "rms_dbfs": rms_metric,
            "clipping_rate": round(clipping_rate, 6),
            "peak_amplitude": round(peak_amplitude, 4),
            "low_freq_fraction": round(low_freq_fraction, 4),
            "sample_rate": sr,
            "n_channels": n_ch,
        },
        "reason": "; ".join(fails) if fails else "all hygiene checks pass",
    }


_TRACE_LINE_RE = re.compile(
    r"^\s*(\d+)\s+(\S+)\s+(?:0x)?([0-9a-fA-F]+)\s+(?:0x)?([0-9a-fA-F]+)\s*$"
)


def parse_trace(trace_path):
    """Parse MAME register trace file. Return list of dicts."""
    events = []
    if not trace_path or not Path(trace_path).exists():
        return events
    with open(trace_path) as f:
        for line in f:
            m = _TRACE_LINE_RE.match(line)
            if m:
                events.append({
                    "timestamp_us": int(m.group(1)),
                    "chip_target": m.group(2),
                    "register_addr": int(m.group(3), 16),
                    "value": int(m.group(4), 16),
                })
    return events


def layer2_trace_alignment(trace_path, expected, samples, sr):
    """Layer 2: event/trace alignment + wav energy correspondence.

    Verdict logic (= ADR-0065 Annex β-10-2 spec):
      - expected.events 空 OR trace file 不在 → skip
      - mismatch_count = 0 AND energy_correspondence_rate >= 0.9 → pass
      - mismatch_count > 0 OR energy_correspondence_rate < 0.9 → fail
    """
    expected_events = expected.get("events", [])

    if not expected_events:
        return {
            "status": "skip",
            "metrics": {"trace_event_count": 0, "expected_event_count": 0,
                        "mismatch_count": 0, "energy_correspondence_rate": 1.0,
                        "note_on_events_checked": 0},
            "reason": "no expected events in JSON; skip layer 2",
        }

    # trace file 不在 → skip (= Annex β-10-2 spec literal)
    if not trace_path or not Path(trace_path).exists():
        return {
            "status": "skip",
            "metrics": {"trace_event_count": 0, "expected_event_count": len(expected_events),
                        "mismatch_count": 0, "energy_correspondence_rate": 1.0,
                        "note_on_events_checked": 0,
                        "trace_path": str(trace_path) if trace_path else "not provided"},
            "reason": f"trace file not found ({trace_path}); skip layer 2",
        }

    trace_events = parse_trace(trace_path)

    # Event field match
    mismatch_count = 0
    matched_indices = set()
    for exp in expected_events:
        found = False
        for i, tr in enumerate(trace_events):
            if i in matched_indices:
                continue
            if (
                tr["chip_target"] == exp.get("chip_target")
                and tr["register_addr"] == exp.get("register_addr")
                and tr["value"] == exp.get("value")
                and abs(tr["timestamp_us"] - exp.get("timestamp_us", 0)) <= EVENT_TIMESTAMP_TOLERANCE_US
            ):
                matched_indices.add(i)
                found = True
                break
        if not found:
            mismatch_count += 1

    # WAV energy correspondence (note-on events)
    note_on_events = [e for e in expected_events if e.get("event_type") == "note_on"]
    energy_pass = 0
    energy_fail = 0
    for ev in note_on_events:
        ts_sec = ev.get("timestamp_us", 0) / 1e6
        win_start = max(0, int((ts_sec - ENERGY_CORRESPONDENCE_WINDOW_PRE_MS / 1000.0) * sr))
        win_end = min(len(samples), int((ts_sec + ENERGY_CORRESPONDENCE_WINDOW_POST_MS / 1000.0) * sr))
        if win_end > win_start:
            window = samples[win_start:win_end]
            rms = float(np.sqrt(np.mean(window ** 2)))
            rms_dbfs = 20.0 * np.log10(rms) if rms > 0 else -float("inf")
            if rms_dbfs > SILENCE_THRESHOLD_DBFS:
                energy_pass += 1
            else:
                energy_fail += 1
        else:
            energy_fail += 1

    total_note_on = energy_pass + energy_fail
    energy_rate = energy_pass / total_note_on if total_note_on > 0 else 1.0

    fails = []
    if mismatch_count > 0:
        fails.append(f"{mismatch_count} expected events not found in trace (mandate: 0)")
    if total_note_on > 0 and energy_rate < ENERGY_CORRESPONDENCE_RATE_THRESHOLD:
        fails.append(
            f"wav energy correspondence rate {energy_rate:.3f} < threshold {ENERGY_CORRESPONDENCE_RATE_THRESHOLD}"
        )

    return {
        "status": "pass" if not fails else "fail",
        "metrics": {
            "trace_event_count": len(trace_events),
            "expected_event_count": len(expected_events),
            "mismatch_count": mismatch_count,
            "energy_correspondence_rate": round(energy_rate, 4),
            "note_on_events_checked": total_note_on,
        },
        "reason": "; ".join(fails) if fails else (
            f"all {len(expected_events)} events matched + "
            f"energy correspondence {energy_rate:.3f} >= {ENERGY_CORRESPONDENCE_RATE_THRESHOLD}"
        ),
    }


def layer3_reference_comparison(samples, baseline_path):
    """Layer 3: reference comparison vs production binary baseline."""
    if baseline_path is None:
        return {
            "status": "skip",
            "metrics": {"baseline": "not provided"},
            "reason": "no --baseline; skip layer 3",
        }
    if not Path(baseline_path).exists():
        return {
            "status": "skip",
            "metrics": {"baseline": "not found"},
            "reason": f"baseline path {baseline_path} not found; skip layer 3",
        }

    try:
        baseline_samples, _, _ = load_wav(baseline_path)
    except Exception as e:
        return {
            "status": "skip",
            "metrics": {"baseline_load_error": str(e)},
            "reason": f"baseline load failed; skip layer 3: {e}",
        }

    min_len = min(len(samples), len(baseline_samples))
    if min_len == 0:
        return {
            "status": "skip",
            "metrics": {"samples_compared": 0},
            "reason": "empty samples or baseline; skip layer 3",
        }

    s1 = samples[:min_len]
    s2 = baseline_samples[:min_len]

    l2_diff = float(np.linalg.norm(s1 - s2) / np.sqrt(min_len))
    fft1 = np.abs(np.fft.rfft(s1))
    fft2 = np.abs(np.fft.rfft(s2))
    n1 = float(np.linalg.norm(fft1))
    n2 = float(np.linalg.norm(fft2))
    cosine_sim = float(np.dot(fft1, fft2) / (n1 * n2)) if n1 > 0 and n2 > 0 else 0.0

    fails = []
    if l2_diff > L2_DIFF_THRESHOLD:
        fails.append(f"L2 waveform diff {l2_diff:.4f} > threshold {L2_DIFF_THRESHOLD}")
    if cosine_sim < SPECTRAL_SIMILARITY_THRESHOLD:
        fails.append(f"spectral cosine similarity {cosine_sim:.4f} < threshold {SPECTRAL_SIMILARITY_THRESHOLD}")

    return {
        "status": "pass" if not fails else "fail",
        "metrics": {
            "l2_diff": round(l2_diff, 6),
            "cosine_similarity": round(cosine_sim, 6),
            "samples_compared": min_len,
        },
        "reason": "; ".join(fails) if fails else (
            f"L2 {l2_diff:.4f} <= {L2_DIFF_THRESHOLD} + cosine {cosine_sim:.4f} >= {SPECTRAL_SIMILARITY_THRESHOLD}"
        ),
    }


def layer4_readiness_report(layer1, layer2, layer3, material_description, judgment_expected):
    """Layer 4: audition readiness report generation."""
    layers_status = {
        "1_wav_hygiene": layer1["status"],
        "2_trace_alignment": layer2["status"],
        "3_reference_comparison": layer3["status"],
    }
    all_ready = all(s != "fail" for s in layers_status.values())

    if all_ready:
        verdict_string = "READY"
        verdict_note = (
            "この wav は human audition (= 越川氏 listening session) に出して OK = "
            "engineering gate clear。\n\n"
            "**重要**: metric pass != aesthetic accept。 gate ALL PASS は機械的検証通過 "
            "(= 無音 / 異常音 / duration 不一致 / 異常低音持続 等の process failure 排除) を意味し、 "
            "aesthetic accept (= 越川氏「これで OK」 という審美判断) ではない。 "
            "aesthetic 判断は user authoritative role、 この gate は前段の engineering 検査のみ。 "
            "(= memory `feedback_metric_pass_is_not_aesthetic_pass.md` 整合)"
        )
    else:
        verdict_string = "NOT READY"
        verdict_note = (
            "この wav は **user audition に出してはいけない**。\n\n"
            "1+ layer FAIL = main agent が修正 + retry mandate。 user 判断材料として出さない "
            "(= memory `feedback_main_agent_engineering_responsibility.md` literal "
            "「engineering gate 不足 = Claude Code 自分で直す」)。"
        )

    def fmt(value, default="N/A"):
        return value if value is not None else default

    lines = [
        "# Audition Readiness Report",
        "",
        "## Material 説明",
        material_description if material_description else "(未指定)",
        "",
        "## 期待される sound description",
        judgment_expected if judgment_expected else "(未指定)",
        "",
        "## 4 層 gate 結果",
        "",
        f"### 層 1 WAV hygiene: **{layer1['status'].upper()}**",
        f"- duration: {fmt(layer1['metrics'].get('duration_sec'))} s "
        f"(expected {fmt(layer1['metrics'].get('duration_expected'))} s, tolerance ±{DURATION_TOLERANCE_SEC} s)",
        f"- RMS: {fmt(layer1['metrics'].get('rms_dbfs'))} dBFS (threshold > {SILENCE_THRESHOLD_DBFS} dBFS)",
        f"- clipping rate: {fmt(layer1['metrics'].get('clipping_rate'))} (threshold < {CLIPPING_THRESHOLD})",
        f"- peak amplitude: {fmt(layer1['metrics'].get('peak_amplitude'))}",
        f"- low-freq fraction (< {LOW_FREQ_CUTOFF_HZ} Hz): {fmt(layer1['metrics'].get('low_freq_fraction'))} "
        f"(threshold < {LOW_FREQ_DOMINANCE_THRESHOLD})",
        f"- sample rate: {fmt(layer1['metrics'].get('sample_rate'))} Hz (expected {SAMPLE_RATE_EXPECTED} Hz)",
        f"- reason: {layer1.get('reason')}",
        "",
        f"### 層 2 event/trace alignment: **{layer2['status'].upper()}**",
        f"- trace events: {fmt(layer2['metrics'].get('trace_event_count'))}",
        f"- expected events: {fmt(layer2['metrics'].get('expected_event_count'))}",
        f"- mismatch count: {fmt(layer2['metrics'].get('mismatch_count'))} (mandate: 0)",
        f"- energy correspondence rate: {fmt(layer2['metrics'].get('energy_correspondence_rate'))} "
        f"(threshold >= {ENERGY_CORRESPONDENCE_RATE_THRESHOLD})",
        f"- note-on events checked: {fmt(layer2['metrics'].get('note_on_events_checked'))}",
        f"- reason: {layer2.get('reason')}",
        "",
        f"### 層 3 reference comparison: **{layer3['status'].upper()}**",
        f"- L2 diff: {fmt(layer3['metrics'].get('l2_diff'))} (threshold <= {L2_DIFF_THRESHOLD})",
        f"- cosine similarity: {fmt(layer3['metrics'].get('cosine_similarity'))} "
        f"(threshold >= {SPECTRAL_SIMILARITY_THRESHOLD})",
        f"- reason: {layer3.get('reason')}",
        "",
        f"## 最終 verdict: **{verdict_string}**",
        "",
        verdict_note,
    ]
    return {
        "status": "ready" if all_ready else "not_ready",
        "verdict_string": verdict_string,
        "report": "\n".join(lines),
    }


def main():
    parser = argparse.ArgumentParser(
        description="ADR-0065 sprint B = audition readiness gate executor (4 層 engineering gate)"
    )
    parser.add_argument("--wav", required=True, help="Audio wav file path")
    parser.add_argument("--trace", required=True, help="MAME register trace file path (= can be empty)")
    parser.add_argument("--expected", required=True, help="Expected event JSON file path")
    parser.add_argument("--baseline", default=None, help="Production binary baseline wav (= optional)")
    parser.add_argument("--output-json", required=True, help="Output analysis JSON path")
    parser.add_argument("--output-report", required=True, help="Output readiness report markdown path")
    args = parser.parse_args()

    try:
        with open(args.expected) as f:
            expected = json.load(f)
    except Exception as e:
        print(f"ERROR: failed to load expected JSON: {e}", file=sys.stderr)
        sys.exit(2)

    try:
        samples, sr, n_ch = load_wav(args.wav)
    except Exception as e:
        print(f"ERROR: failed to load wav: {e}", file=sys.stderr)
        sys.exit(2)

    layer1 = layer1_wav_hygiene(samples, sr, n_ch, expected)
    layer2 = layer2_trace_alignment(args.trace, expected, samples, sr)
    layer3 = layer3_reference_comparison(samples, args.baseline)
    layer4 = layer4_readiness_report(
        layer1, layer2, layer3,
        expected.get("material_description", ""),
        expected.get("judgment_expected", ""),
    )

    fail_layers = [name for name, l in [("1", layer1), ("2", layer2), ("3", layer3)] if l["status"] == "fail"]
    verdict = "fail" if fail_layers else "pass"
    ready_for_audition = (verdict == "pass")

    analysis = {
        "verdict": verdict,
        "ready_for_audition": ready_for_audition,
        "layers": {
            "1_wav_hygiene": layer1,
            "2_trace_alignment": layer2,
            "3_reference_comparison": layer3,
            "4_readiness_report": {
                "status": layer4["status"],
                "metrics": {
                    "verdict_string": layer4["verdict_string"],
                    "report_path": args.output_report,
                    "layer1_status": layer1["status"],
                    "layer2_status": layer2["status"],
                    "layer3_status": layer3["status"],
                },
                "reason": (
                    "all engineering gate layers PASS or SKIP — ready for audition "
                    "(= metric pass != aesthetic accept、 final aesthetic 判断 = user authoritative)"
                    if layer4["status"] == "ready"
                    else "1+ engineering gate layer FAIL — main agent 修正 + retry mandate "
                    "(= user audition に出さない)"
                ),
            },
        },
        "material_description": expected.get("material_description", ""),
        "judgment_expected": expected.get("judgment_expected", ""),
        "thresholds_used": {
            "duration_tolerance_sec": DURATION_TOLERANCE_SEC,
            "silence_threshold_dbfs": SILENCE_THRESHOLD_DBFS,
            "clipping_threshold": CLIPPING_THRESHOLD,
            "sample_rate_expected": SAMPLE_RATE_EXPECTED,
            "low_freq_dominance_threshold": LOW_FREQ_DOMINANCE_THRESHOLD,
            "low_freq_cutoff_hz": LOW_FREQ_CUTOFF_HZ,
            "l2_diff_threshold": L2_DIFF_THRESHOLD,
            "spectral_similarity_threshold": SPECTRAL_SIMILARITY_THRESHOLD,
            "event_timestamp_tolerance_us": EVENT_TIMESTAMP_TOLERANCE_US,
            "energy_correspondence_window_pre_ms": ENERGY_CORRESPONDENCE_WINDOW_PRE_MS,
            "energy_correspondence_window_post_ms": ENERGY_CORRESPONDENCE_WINDOW_POST_MS,
            "energy_correspondence_rate_threshold": ENERGY_CORRESPONDENCE_RATE_THRESHOLD,
        },
    }

    with open(args.output_json, "w") as f:
        json.dump(analysis, f, indent=2, ensure_ascii=False)
    with open(args.output_report, "w") as f:
        f.write(layer4["report"])

    print(f"Verdict: {verdict}")
    print(f"Ready for audition: {ready_for_audition}")
    if fail_layers:
        print(f"Failed layers: {', '.join(fail_layers)}")
    print(f"Analysis JSON: {args.output_json}")
    print(f"Readiness report: {args.output_report}")

    sys.exit(0 if verdict == "pass" else 1)


if __name__ == "__main__":
    main()
