#!/usr/bin/env python3
"""
PMDNEO ADR-0033 §決定 27 (12) π10 spike = feature-guided parameter search (step 1 = feature extraction).

# ============================================================================
# 9 項目 header (= shell 規律踏襲、 [[interface-fixation-stub-pattern]] 整合)
# ============================================================================
#
# purpose:
#   Surge XT rendered WAV から audio feature を抽出 + 2 WAV 比較で distance metric 算出。
#   ADR-0033 §決定 27 (12) target-feature matching optimization axis の **feature extraction layer のみ**。
#   search loop (= CMA-ES / scipy.optimize) は π11+ で別 subcommand 追加予定、 本 π10 は extract + compare 動作確認まで。
#
# ADR mapping:
#   - ADR-0033 §決定 27 (5)  AI self-analysis 10 項目 = 本 script の feature set base
#   - ADR-0033 §決定 27 (12) target-feature matching optimization axis (= π8 investigation + π9 ADR 反映)
#   - ADR-0033 §決定 14      reference-inspired vs derivative 5 軸 table (= target wav は feature 経由 only、 sample byte 保存禁止)
#   - SURGE_XT_FXP_BRIDGE_INVESTIGATION.md § 15.4 = Kick 909ish.fxp reference values
#   - FEATURE_GUIDED_SYNTHESIS_INVESTIGATION.md § 3.1 = feature list + librosa
#
# input:
#   <wav>  = WAV file (= fxp2wav-surge render 出力想定、 mono 16-bit 44100 Hz)
#
# output:
#   stdout に feature JSON / comparison report
#   exit code 0 で全 feature extraction 成功、 0 以外 = error
#
# format:
#   feature dict (= AI self-analysis 10 項目 + 補助 6 項目 = 16 feature):
#     waveform_sanity:    duration_sec / sample_rate / channels / total_samples
#     peak_amplitude:     max |sample| (= linear 0-1 + dBFS)
#     rms_amplitude:      RMS energy (= linear + dBFS)
#     clipping_count:     |sample| == 1.0 sample 数 (= int16 上限 ±32767 reach)
#     leading_silence_ms: 最初の非無音 sample までの ms
#     trailing_silence_ms: 最後の非無音 sample 以降の ms
#     attack_ms:          onset → peak までの ms
#     decay_curve:        peak 後 envelope の exponential fit (= 1/e 時間 ms)
#     transient_strength: peak / RMS ratio in 50ms attack window
#     spectral_centroid:  STFT 経由「明るさ」 中心周波数 (Hz)
#     spectral_flux:      onset_strength 平均
#     low_band_ratio:     <500 Hz energy 比率 (= BD fundamental 領域)
#     mid_band_ratio:     500-2000 Hz energy 比率
#     high_band_ratio:    >2000 Hz energy 比率 (= HH / CYM 領域)
#     rough_frequency:    fundamental frequency (Hz) via librosa.pyin
#     tail_length_ms:     silence threshold 以下の trailing 持続 ms
#
# future phase (= π11 以降):
#   - π11: distance metric 設計詳細 = weighted L2 + per-drum target threshold
#   - π12: search loop subcommand `optimize` = CMA-ES / scipy.optimize で 6-10 continuous param search
#   - π13: bridge invoke 連携 = fxp_template_patch.py patch 経由 closed loop
#
# exit codes:
#   0  = success
#   64 = arg validation error (= input file path 不正 / nonexistent)
#   65 = data validation error (= WAV read fail / format unexpected)
#   66 = runtime error (= librosa / numpy unexpected error)
#
# examples:
#   $ python3 scripts/feature_search.py extract ~/Projects/surge-spike/test-assets/kick_909ish.wav
#   $ python3 scripts/feature_search.py extract ~/Projects/surge-spike/test-assets/2608_bd.wav --pretty
#   $ python3 scripts/feature_search.py compare \
#         ~/Projects/surge-spike/test-assets/kick_909ish.wav \
#         ~/Projects/surge-spike/test-assets/2608_bd.wav
#
# safety:
#   - read-only WAV file 読込のみ、 出力は stdout
#   - target wav (= reference) の sample byte は保存しない (= ADR-0033 §決定 14 reference-inspired only)
#   - feature dict は数値のみ、 sample data の derivative ではない
#
# ============================================================================
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

# Exit code constants
EXIT_OK = 0
EXIT_ARG_ERROR = 64
EXIT_DATA_ERROR = 65
EXIT_RUNTIME_ERROR = 66

# Silence threshold (= linear amplitude、 silence 判定基準)
SILENCE_THRESHOLD = 1e-3  # = -60 dBFS、 sox stat の Maximum amplitude 程度

# Distance metric weights (= 各 feature の比較 weight、 future tuning 余地)
DISTANCE_WEIGHTS = {
    "peak_amplitude_dbfs": 0.5,
    "rms_amplitude_dbfs": 0.7,
    "clipping_count": 0.2,
    "leading_silence_ms": 0.3,
    "trailing_silence_ms": 0.3,
    "attack_ms": 1.0,
    "decay_1e_ms": 1.5,
    "transient_strength": 0.8,
    "spectral_centroid_hz": 1.0,
    "spectral_flux_mean": 0.5,
    "low_band_ratio": 1.5,
    "mid_band_ratio": 0.7,
    "high_band_ratio": 0.7,
    "rough_frequency_hz": 1.2,
    "tail_length_ms": 0.5,
}


def linear_to_dbfs(x: float) -> float:
    """Convert linear amplitude (= 0-1) to dBFS."""
    if x <= 0:
        return -math.inf
    return 20.0 * math.log10(max(x, 1e-10))


def extract_features(wav_path: Path) -> dict:
    """Extract 16 features from WAV file (= AI self-analysis 10 項目 + 6 補助)."""
    import librosa
    import numpy as np

    y, sr = librosa.load(str(wav_path), sr=None, mono=True)
    total_samples = len(y)
    duration_sec = total_samples / sr

    abs_y = np.abs(y)
    peak_linear = float(np.max(abs_y))
    rms_linear = float(np.sqrt(np.mean(y ** 2)))

    # Clipping count (= |sample| == 1.0、 int16 上限 reach)
    clipping_count = int(np.sum(abs_y >= 0.999))

    # Silence detection
    non_silent_idx = np.where(abs_y > SILENCE_THRESHOLD)[0]
    if len(non_silent_idx) == 0:
        leading_silence_ms = duration_sec * 1000
        trailing_silence_ms = 0.0
        attack_ms = 0.0
        peak_idx = 0
    else:
        leading_silence_ms = float(non_silent_idx[0] / sr * 1000)
        trailing_silence_ms = float((total_samples - 1 - non_silent_idx[-1]) / sr * 1000)
        # Peak position
        peak_idx = int(np.argmax(abs_y))
        # Attack = onset (= leading silence end) → peak
        onset_idx = int(non_silent_idx[0])
        attack_samples = peak_idx - onset_idx
        attack_ms = float(attack_samples / sr * 1000) if attack_samples > 0 else 0.0

    # Decay 1/e time (= peak 後 amplitude が 1/e ≈ 0.368 倍に減衰までの ms)
    if peak_idx < total_samples - 1 and peak_linear > SILENCE_THRESHOLD:
        target_amp = peak_linear / math.e
        post_peak = abs_y[peak_idx:]
        decay_idx_arr = np.where(post_peak < target_amp)[0]
        if len(decay_idx_arr) > 0:
            decay_1e_ms = float(decay_idx_arr[0] / sr * 1000)
        else:
            decay_1e_ms = float((total_samples - peak_idx) / sr * 1000)
    else:
        decay_1e_ms = 0.0

    # Transient strength (= peak / RMS ratio in first 50ms after onset)
    if len(non_silent_idx) > 0 and rms_linear > 0:
        window_samples = int(0.050 * sr)
        attack_window = y[onset_idx : min(onset_idx + window_samples, total_samples)]
        window_rms = float(np.sqrt(np.mean(attack_window ** 2)))
        if window_rms > 0:
            transient_strength = float(np.max(np.abs(attack_window)) / window_rms)
        else:
            transient_strength = 0.0
    else:
        transient_strength = 0.0

    # Spectral features via librosa
    # STFT magnitude → centroid + flux
    stft = librosa.stft(y, n_fft=2048, hop_length=512)
    mag = np.abs(stft)
    freqs = librosa.fft_frequencies(sr=sr, n_fft=2048)

    centroid = librosa.feature.spectral_centroid(S=mag, sr=sr)
    spectral_centroid_hz = float(np.mean(centroid))

    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    spectral_flux_mean = float(np.mean(onset_env))

    # Band energy ratios
    total_energy = float(np.sum(mag))
    if total_energy > 0:
        low_mask = freqs < 500
        mid_mask = (freqs >= 500) & (freqs < 2000)
        high_mask = freqs >= 2000
        low_band_ratio = float(np.sum(mag[low_mask]) / total_energy)
        mid_band_ratio = float(np.sum(mag[mid_mask]) / total_energy)
        high_band_ratio = float(np.sum(mag[high_mask]) / total_energy)
    else:
        low_band_ratio = mid_band_ratio = high_band_ratio = 0.0

    # Rough frequency (= fundamental) via librosa.pyin
    try:
        f0, voiced_flag, _ = librosa.pyin(
            y, fmin=20, fmax=2000, sr=sr,
            frame_length=2048, hop_length=512,
        )
        # voiced かつ NaN でない f0 の median
        valid_f0 = f0[~np.isnan(f0)] if f0 is not None else np.array([])
        if len(valid_f0) > 0:
            rough_frequency_hz = float(np.median(valid_f0))
        else:
            rough_frequency_hz = 0.0
    except Exception:
        rough_frequency_hz = 0.0

    # Tail length (= silence threshold 以下が連続する trailing 持続 ms)
    # = trailing_silence_ms と同じ semantic、 確認用 redundant
    tail_length_ms = trailing_silence_ms

    return {
        "waveform_sanity": {
            "total_samples": total_samples,
            "sample_rate": int(sr),
            "duration_sec": round(duration_sec, 6),
            "channels": 1,  # = mono load 指定
        },
        "peak_amplitude_linear": round(peak_linear, 6),
        "peak_amplitude_dbfs": round(linear_to_dbfs(peak_linear), 3),
        "rms_amplitude_linear": round(rms_linear, 6),
        "rms_amplitude_dbfs": round(linear_to_dbfs(rms_linear), 3),
        "clipping_count": clipping_count,
        "leading_silence_ms": round(leading_silence_ms, 3),
        "trailing_silence_ms": round(trailing_silence_ms, 3),
        "attack_ms": round(attack_ms, 3),
        "decay_1e_ms": round(decay_1e_ms, 3),
        "transient_strength": round(transient_strength, 3),
        "spectral_centroid_hz": round(spectral_centroid_hz, 2),
        "spectral_flux_mean": round(spectral_flux_mean, 4),
        "low_band_ratio": round(low_band_ratio, 4),
        "mid_band_ratio": round(mid_band_ratio, 4),
        "high_band_ratio": round(high_band_ratio, 4),
        "rough_frequency_hz": round(rough_frequency_hz, 2),
        "tail_length_ms": round(tail_length_ms, 3),
    }


def compute_distance(features_a: dict, features_b: dict) -> dict:
    """Compute weighted distance between 2 feature dicts (= simple L2 normalized)."""
    diffs = {}
    weighted_squared_sum = 0.0
    weight_sum = 0.0

    for key, weight in DISTANCE_WEIGHTS.items():
        if key not in features_a or key not in features_b:
            continue
        a = features_a[key]
        b = features_b[key]
        if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):
            continue
        if a == float("-inf") or b == float("-inf"):
            continue  # silent edge case
        # Normalize by reference magnitude (= a) to make relative diff
        denom = max(abs(a), 1.0)  # = 1 floor で 0 除算 + 微小 a での過大評価回避
        rel_diff = (a - b) / denom
        weighted_squared_sum += weight * rel_diff ** 2
        weight_sum += weight
        diffs[key] = {
            "a": a,
            "b": b,
            "abs_diff": round(abs(a - b), 4),
            "rel_diff": round(rel_diff, 4),
            "weight": weight,
        }

    if weight_sum > 0:
        score = math.sqrt(weighted_squared_sum / weight_sum)
    else:
        score = float("inf")

    return {
        "distance_score": round(score, 4),
        "weight_sum": weight_sum,
        "per_feature_diff": diffs,
    }


def extract_command(args: argparse.Namespace) -> int:
    """Extract features from one WAV + dump JSON."""
    if not args.input.exists():
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        return EXIT_ARG_ERROR
    try:
        features = extract_features(args.input)
    except (ValueError, RuntimeError) as exc:
        print(f"error: feature extraction failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR
    except Exception as exc:
        print(f"error: unexpected error: {exc}", file=sys.stderr)
        return EXIT_RUNTIME_ERROR

    output = {"input": str(args.input), "features": features}
    if args.pretty:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(output, ensure_ascii=False))
    return EXIT_OK


def _evaluate_criterion(criterion: str, value: float) -> bool:
    """
    Safely evaluate threshold criterion against value (= rule file DSL parser).

    Supported forms:
      "value < N"     "value > N"
      "value <= N"    "value >= N"
      "value == N"    "value != N"
      "A <= value <= B"  (= range check)
    """
    import re
    s = criterion.strip()

    # Range form: "A <= value <= B"
    m = re.fullmatch(
        r"(-?\d+\.?\d*)\s*<=\s*value\s*<=\s*(-?\d+\.?\d*)",
        s,
    )
    if m:
        lo = float(m.group(1))
        hi = float(m.group(2))
        return lo <= value <= hi

    # Simple binary form: "value OP N"
    m = re.fullmatch(
        r"value\s*(<=|>=|==|!=|<|>)\s*(-?\d+\.?\d*)",
        s,
    )
    if m:
        op = m.group(1)
        threshold = float(m.group(2))
        if op == "<":
            return value < threshold
        if op == ">":
            return value > threshold
        if op == "<=":
            return value <= threshold
        if op == ">=":
            return value >= threshold
        if op == "==":
            return value == threshold
        if op == "!=":
            return value != threshold

    raise ValueError(f"unsupported criterion form: {criterion!r}")


def _get_feature_value(features: dict, feature_name: str):
    """Get feature value (= flat dict + waveform_sanity dict 経由両方対応)."""
    if feature_name in features:
        return features[feature_name]
    # waveform_sanity 内も check
    if "waveform_sanity" in features and feature_name in features["waveform_sanity"]:
        return features["waveform_sanity"][feature_name]
    return None


def validate_command(args: argparse.Namespace) -> int:
    """Validate WAV against per-drum threshold rules + emit analysis-report.yaml format."""
    import datetime
    import yaml

    if not args.input.exists():
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        return EXIT_ARG_ERROR
    if not args.rules.exists():
        print(f"error: rules file not found: {args.rules}", file=sys.stderr)
        return EXIT_ARG_ERROR

    try:
        rules = yaml.safe_load(args.rules.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        print(f"error: rules YAML parse failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    drum_rules = (rules.get("drum_rules") or {}).get(args.drum_type)
    if drum_rules is None:
        print(
            f"error: drum_type {args.drum_type!r} not found in rules "
            f"(= 利用可能: {list((rules.get('drum_rules') or {}).keys())})",
            file=sys.stderr,
        )
        return EXIT_ARG_ERROR

    try:
        features = extract_features(args.input)
    except Exception as exc:
        print(f"error: feature extraction failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    # rule evaluation
    evaluation = []
    for rule in drum_rules.get("thresholds", []):
        feature_name = rule["feature"]
        actual = _get_feature_value(features, feature_name)
        if actual is None:
            evaluation.append({
                "feature": feature_name,
                "criterion": rule["criterion"],
                "actual": None,
                "passed": False,
                "severity": rule.get("severity", "warning"),
                "failure_category": "feature_missing",
                "rationale": f"feature {feature_name!r} not produced by extractor",
            })
            continue
        try:
            passed = _evaluate_criterion(rule["criterion"], float(actual))
        except (ValueError, TypeError) as exc:
            evaluation.append({
                "feature": feature_name,
                "criterion": rule["criterion"],
                "actual": actual,
                "passed": False,
                "severity": rule.get("severity", "warning"),
                "failure_category": "criterion_parse_error",
                "rationale": f"criterion evaluation failed: {exc}",
            })
            continue
        evaluation.append({
            "feature": feature_name,
            "criterion": rule["criterion"],
            "actual": actual,
            "passed": passed,
            "severity": rule.get("severity", "warning"),
            "failure_category": None if passed else rule.get("failure_category", "unspecified"),
            "rationale": rule.get("rationale", ""),
        })

    # summary
    total_rules = len(evaluation)
    passed = sum(1 for e in evaluation if e["passed"])
    critical_fails = sum(
        1 for e in evaluation
        if not e["passed"] and e["severity"] == "critical"
    )
    warning_fails = sum(
        1 for e in evaluation
        if not e["passed"] and e["severity"] == "warning"
    )
    overall_status = "engineering_pass" if critical_fails == 0 else "engineering_fail"
    failure_categories = sorted(
        {e["failure_category"] for e in evaluation if e["failure_category"]}
    )

    output = {
        "metadata": {
            "generated_at": datetime.datetime.now().isoformat(),
            "generator": "scripts/feature_search.py validate",
            "input_wav": str(args.input),
            "drum_type": args.drum_type,
            "rules_file": str(args.rules),
            "rules_version": rules.get("rules_version", "?"),
        },
        "features": features,
        "rule_evaluation": evaluation,
        "summary": {
            "total_rules": total_rules,
            "passed": passed,
            "critical_fails": critical_fails,
            "warning_fails": warning_fails,
            "overall_status": overall_status,
            "failure_categories": failure_categories,
        },
    }

    if args.format == "json":
        print(json.dumps(output, indent=2 if args.pretty else None, ensure_ascii=False))
    else:
        # default = YAML (= analysis-report.yaml 用)
        print(yaml.safe_dump(output, allow_unicode=True, sort_keys=False, default_flow_style=False))

    # exit code reflect engineering_pass
    return EXIT_OK if overall_status == "engineering_pass" else 67  # = 67 = engineering_fail


def compare_command(args: argparse.Namespace) -> int:
    """Compare 2 WAVs + dump distance + per-feature diff."""
    for p in (args.reference, args.target):
        if not p.exists():
            print(f"error: file not found: {p}", file=sys.stderr)
            return EXIT_ARG_ERROR
    try:
        ref_features = extract_features(args.reference)
        tgt_features = extract_features(args.target)
    except Exception as exc:
        print(f"error: feature extraction failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    distance = compute_distance(ref_features, tgt_features)
    output = {
        "reference": str(args.reference),
        "target": str(args.target),
        "reference_features": ref_features,
        "target_features": tgt_features,
        "distance": distance,
    }
    if args.pretty:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(output, ensure_ascii=False))
    return EXIT_OK


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="feature_search.py",
        description="PMDNEO ADR-0033 §決定 27 (12) π10 spike = feature-guided synthesis (extract + compare)",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_extract = subparsers.add_parser(
        "extract",
        help="Extract 16 audio features from WAV (= π10 新規、 read-only)",
    )
    p_extract.add_argument("input", type=Path, help="input WAV file path")
    p_extract.add_argument(
        "--pretty", action="store_true",
        help="pretty-print JSON",
    )

    p_compare = subparsers.add_parser(
        "compare",
        help="Compare 2 WAVs + compute weighted L2 distance (= π10 新規、 read-only)",
    )
    p_compare.add_argument("reference", type=Path, help="reference WAV (= 目標、 例 Kick 909ish.wav)")
    p_compare.add_argument("target", type=Path, help="target WAV (= 現状、 例 2608_bd.wav)")
    p_compare.add_argument(
        "--pretty", action="store_true",
        help="pretty-print JSON",
    )

    p_validate = subparsers.add_parser(
        "validate",
        help="Validate WAV against per-drum rule thresholds + emit analysis-report.yaml (= π11 新規)",
    )
    p_validate.add_argument("input", type=Path, help="input WAV file path")
    p_validate.add_argument(
        "--rules", type=Path,
        default=Path("docs/design/rhythm-patches/synth/feature-rules.yaml"),
        help="rules YAML path (= default: docs/design/rhythm-patches/synth/feature-rules.yaml)",
    )
    p_validate.add_argument(
        "--drum-type",
        choices=["BD", "SD", "CYM", "HH", "TOM", "RIM"],
        default="BD",
        help="drum type for rule lookup (= default: BD)",
    )
    p_validate.add_argument(
        "--format", choices=["yaml", "json"], default="yaml",
        help="output format (= default: yaml for analysis-report.yaml 用)",
    )
    p_validate.add_argument(
        "--pretty", action="store_true",
        help="pretty-print (= JSON 出力時のみ effect)",
    )

    args = parser.parse_args()

    if args.command == "extract":
        return extract_command(args)
    if args.command == "compare":
        return compare_command(args)
    if args.command == "validate":
        return validate_command(args)

    parser.print_help()
    return EXIT_ARG_ERROR


if __name__ == "__main__":
    sys.exit(main())
