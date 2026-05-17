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

    # === metric_v2 additional features (= π14 新規、 time-varying + perceptual) ===
    # MFCC (= 13 coeff、 mean + std per coefficient = perceptual cepstral timbre)
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
    mfcc_mean = [round(float(v), 3) for v in mfcc.mean(axis=1).tolist()]
    mfcc_std = [round(float(v), 3) for v in mfcc.std(axis=1).tolist()]

    # log-mel spectrogram (= 13 mel bands、 time-varying spectral envelope)
    mel_spec_v2 = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=13)
    log_mel = librosa.power_to_db(mel_spec_v2)
    log_mel_mean = [round(float(v), 2) for v in log_mel.mean(axis=1).tolist()]
    log_mel_std = [round(float(v), 2) for v in log_mel.std(axis=1).tolist()]

    # onset envelope time-series statistics (= attack detail + transient shape)
    onset_strength_mean = round(float(np.mean(onset_env)), 4)
    onset_strength_std = round(float(np.std(onset_env)), 4)
    onset_strength_peak = round(float(np.max(onset_env)), 4)

    # spectral contrast (= 7 bands、 tonal vs noise 軸)
    sc = librosa.feature.spectral_contrast(y=y, sr=sr)
    spectral_contrast_mean = [round(float(v), 2) for v in sc.mean(axis=1).tolist()]

    # spectral flux std (= mean is in v1)
    spectral_flux_std = round(float(np.std(onset_env)), 4)

    # LUFS integrated loudness (= ITU-R BS.1770 perceptual loudness)
    try:
        import pyloudnorm as pyln
        meter = pyln.Meter(sr)
        lufs_integrated = round(float(meter.integrated_loudness(y)), 2)
    except Exception:
        lufs_integrated = float("-inf")  # = silent or too short

    return {
        "waveform_sanity": {
            "total_samples": total_samples,
            "sample_rate": int(sr),
            "duration_sec": round(duration_sec, 6),
            "channels": 1,  # = mono load 指定
        },
        # === v1 features (= scalar、 static aggregates) ===
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
        # === metric_v2 features (= π14 新規) ===
        "mfcc_mean": mfcc_mean,                      # 13 coeff
        "mfcc_std": mfcc_std,                        # 13 coeff
        "log_mel_mean": log_mel_mean,                # 13 mel bands
        "log_mel_std": log_mel_std,                  # 13 mel bands
        "onset_strength_mean": onset_strength_mean,  # scalar
        "onset_strength_std": onset_strength_std,    # scalar
        "onset_strength_peak": onset_strength_peak,  # scalar
        "spectral_contrast_mean": spectral_contrast_mean,  # 7 bands
        "spectral_flux_std": spectral_flux_std,      # scalar
        "lufs_integrated": lufs_integrated,          # scalar = ITU-R BS.1770
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


def audition_check_command(args: argparse.Namespace) -> int:
    """
    π14/π15 audition correlation check = N candidate × human aesthetic score vs metric_v2 score の Spearman correlation.

    threshold (= default 0.7) を超えれば metric_v2 を採用可能 = π16 optimize 着手可、
    超えなければ metric_v3 設計へ戻し (= 「metric pass ≠ aesthetic pass」 規律遵守、
    optimize 実行前 hard gate)。
    """
    import datetime
    import yaml
    from scipy.stats import spearmanr

    if not args.input.exists():
        print(f"error: input YAML not found: {args.input}", file=sys.stderr)
        return EXIT_ARG_ERROR

    input_data = yaml.safe_load(args.input.read_text(encoding="utf-8"))
    candidates_in = input_data.get("candidates", [])
    if not candidates_in:
        print(f"error: input.candidates empty", file=sys.stderr)
        return EXIT_DATA_ERROR

    target_wav = Path(input_data.get("target_wav") or "").expanduser()
    rules_path = Path(input_data.get("rules") or "").expanduser()
    drum_type = input_data.get("drum_type", "BD")

    if not target_wav.exists():
        print(f"error: target_wav not found: {target_wav}", file=sys.stderr)
        return EXIT_ARG_ERROR
    if not rules_path.exists():
        print(f"error: rules YAML not found: {rules_path}", file=sys.stderr)
        return EXIT_ARG_ERROR

    rules = yaml.safe_load(rules_path.read_text(encoding="utf-8"))
    weights = (rules.get("drum_rules") or {}).get(drum_type, {}).get("distance_weights", {})
    if not weights:
        print(f"error: distance_weights not defined for {drum_type}", file=sys.stderr)
        return EXIT_DATA_ERROR

    # Parse --scores (= comma-separated 1-5 integers in order of candidates)
    if args.scores:
        try:
            scores = [int(s.strip()) for s in args.scores.split(",")]
        except ValueError:
            print(f"error: --scores parse failed: {args.scores!r}", file=sys.stderr)
            return EXIT_ARG_ERROR
        if len(scores) != len(candidates_in):
            print(
                f"error: --scores count {len(scores)} != candidates count {len(candidates_in)}",
                file=sys.stderr,
            )
            return EXIT_ARG_ERROR
        for i, s in enumerate(scores):
            if s < 1 or s > 5:
                print(f"error: --scores[{i}] = {s} out of range 1-5", file=sys.stderr)
                return EXIT_ARG_ERROR
    else:
        # Read scores from YAML if --scores not given
        scores = []
        for c in candidates_in:
            s = c.get("human_score")
            if s is None:
                print(f"error: candidate {c.get('id')!r} has no human_score (= use --scores CLI or fill YAML)",
                      file=sys.stderr)
                return EXIT_ARG_ERROR
            scores.append(int(s))

    # Extract target features once
    print(f"# extracting target features from {target_wav}", file=sys.stderr)
    target_features = extract_features(target_wav)

    # Compute metric_v2 score for each candidate
    print(f"# extracting + scoring {len(candidates_in)} candidates", file=sys.stderr)
    candidate_results = []
    for c, score in zip(candidates_in, scores):
        wav_path = Path(c["wav"]).expanduser()
        if not wav_path.exists():
            print(f"# warning: candidate {c.get('id')!r} wav not found: {wav_path}, skipping", file=sys.stderr)
            candidate_results.append({
                "id": c.get("id"),
                "wav": str(wav_path),
                "description": c.get("description", ""),
                "human_score": score,
                "metric_v2_score": None,
                "error": "wav_not_found",
            })
            continue
        try:
            features = extract_features(wav_path)
            metric_score = _compute_distance_score(features, target_features, weights)
        except Exception as exc:
            print(f"# warning: candidate {c.get('id')!r} feature extract failed: {exc}", file=sys.stderr)
            candidate_results.append({
                "id": c.get("id"),
                "wav": str(wav_path),
                "description": c.get("description", ""),
                "human_score": score,
                "metric_v2_score": None,
                "error": "extract_failed",
            })
            continue
        candidate_results.append({
            "id": c.get("id"),
            "wav": str(wav_path),
            "description": c.get("description", ""),
            "human_score": score,
            "metric_v2_score": round(metric_score, 4),
        })

    # Filter valid pairs (= both scores present)
    valid_pairs = [
        (r["human_score"], r["metric_v2_score"])
        for r in candidate_results
        if r.get("metric_v2_score") is not None
    ]
    if len(valid_pairs) < 3:
        print(f"error: only {len(valid_pairs)} valid pairs, need >= 3 for correlation", file=sys.stderr)
        return EXIT_DATA_ERROR

    human_scores = [p[0] for p in valid_pairs]
    metric_scores = [p[1] for p in valid_pairs]

    # Spearman rank correlation
    # Note: human score 高 = 良い = metric score 低 (= distance) なので、 負の correlation が望ましい
    # → -spearman を見るか、 metric score を反転 (5 - metric) してから計算
    # ここでは raw correlation を出して、 解釈 (= 負の方が望ましい) を report に明示
    result = spearmanr(human_scores, metric_scores)
    spearman_r = float(result.correlation if hasattr(result, "correlation") else result[0])
    p_value = float(result.pvalue if hasattr(result, "pvalue") else result[1])

    # Interpretation: ideal = strong negative correlation (= high human score = low metric score)
    # |r| (absolute value) で評価、 threshold は |r| > 0.7
    abs_r = abs(spearman_r)
    correlation_pass = abs_r >= args.threshold
    correlation_direction = "negative_correct" if spearman_r <= 0 else "positive_inverted"

    verdict = (
        "metric_v2 correlates with human audition (= |r| > threshold) → π16 optimize 着手可"
        if correlation_pass and spearman_r <= 0
        else (
            "metric_v2 sign inverted (= human 高 score なのに metric 高 score = 距離大)、 weight 符号 / scale 再検討"
            if correlation_pass and spearman_r > 0
            else "metric_v2 did NOT correlate with human audition、 metric_v3 calibration へ戻す"
        )
    )

    report = {
        "metadata": {
            "generated_at": datetime.datetime.now().isoformat(),
            "generator": "scripts/feature_search.py audition-check",
            "input": str(args.input),
            "target_wav": str(target_wav),
            "rules_file": str(rules_path),
            "drum_type": drum_type,
            "metric_version": rules.get("metric_version", "v2"),
            "threshold_abs_r": args.threshold,
        },
        "candidates": candidate_results,
        "correlation": {
            "spearman_r": round(spearman_r, 4),
            "spearman_abs_r": round(abs_r, 4),
            "p_value": round(p_value, 4),
            "direction": correlation_direction,
            "expected_direction": "negative (= high human score / low metric score)",
            "threshold_abs_r": args.threshold,
            "abs_r_pass": correlation_pass,
            "sign_correct": spearman_r <= 0,
        },
        "verdict": verdict,
        "next_step": (
            "π16: feature_search.py optimize --rules feature-rules-v2.yaml"
            if correlation_pass and spearman_r <= 0
            else "metric_v3 design + audition correlation check re-iterate"
        ),
        "wording_discipline_reminder": [
            "current metric (= weighted L2 v2) correlation with human audition: " + f"{spearman_r:.4f}",
            "「近づいた」 「reference に類似」 等 aesthetic 含意 wording は使わない",
            "metric pass alone ≠ aesthetic pass、 optimizer は final selector ではない、 human aesthetic gate is authoritative",
        ],
    }

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            yaml.safe_dump(report, allow_unicode=True, sort_keys=False, default_flow_style=False),
            encoding="utf-8",
        )
        print(f"# wrote audition-check report: {args.output}", file=sys.stderr)

    print(json.dumps({
        "spearman_r": round(spearman_r, 4),
        "abs_r": round(abs_r, 4),
        "threshold": args.threshold,
        "abs_r_pass": correlation_pass,
        "sign_correct": spearman_r <= 0,
        "verdict": verdict,
        "next_step": report["next_step"],
    }, indent=2, ensure_ascii=False))

    return EXIT_OK if (correlation_pass and spearman_r <= 0) else 68  # = 68 = correlation_fail


def _load_baseline_from_fxp(fxp_path: Path) -> dict:
    """Load all parameter element values from baseline .fxp (= Kick 909ish reference 想定)."""
    import struct
    import xml.etree.ElementTree as ET
    data = fxp_path.read_bytes()
    chunk = data[60 : 60 + struct.unpack(">I", data[56:60])[0]]
    xml_start = chunk.find(b"<?xml")
    xml_end = chunk.find(b"</patch>") + len(b"</patch>")
    root = ET.fromstring(chunk[xml_start:xml_end])
    params = root.find("parameters")
    return {p.tag: p.get("value") for p in params}


def _build_override_args(overrides: dict) -> list[str]:
    """Build --override KEY=VALUE flag list for subprocess invoke."""
    args = []
    for k, v in overrides.items():
        args.extend(["--override", f"{k}={v}"])
    return args


def _compute_distance_score(candidate_features: dict, target_features: dict, weights: dict) -> float:
    """
    Weighted L2 relative distance with vector feature support (= π14 v2 拡張).

    Scalar features = (a - b) / max(|a|, 1) 単純相対差
    Vector features (= list of floats、 例 MFCC 13 / log_mel 13 / spectral_contrast 7)
       = L2 vector distance、 normalized by L2 norm of target vector
    """
    weighted_sq = 0.0
    weight_sum = 0.0
    for key, w in weights.items():
        a = target_features.get(key)
        b = candidate_features.get(key)
        if a is None or b is None:
            continue
        # Vector feature handling (= list of floats)
        if isinstance(a, list) and isinstance(b, list):
            if len(a) != len(b) or len(a) == 0:
                continue
            try:
                squared_diff = sum((float(ai) - float(bi)) ** 2 for ai, bi in zip(a, b))
                target_norm_sq = sum(float(ai) ** 2 for ai in a)
                # Normalize by target L2 norm、 with floor to avoid divide-by-zero
                rel = math.sqrt(squared_diff) / max(math.sqrt(target_norm_sq), 1.0)
            except (TypeError, ValueError):
                continue
            weighted_sq += w * rel ** 2
            weight_sum += w
            continue
        # Scalar feature handling
        if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):
            continue
        if a == float("-inf") or b == float("-inf"):
            continue
        denom = max(abs(a), 1.0)
        rel = (a - b) / denom
        weighted_sq += w * rel ** 2
        weight_sum += w
    if weight_sum <= 0:
        return float("inf")
    return math.sqrt(weighted_sq / weight_sum)


def optimize_command(args: argparse.Namespace) -> int:
    """
    π12 black-box optimization closed loop = scipy.optimize.differential_evolution + bridge + render + score.

    LLM is NOT the selector; optimizer is the selector. fixed seed + trial history + engineering gate before human audition.
    """
    import datetime
    import hashlib
    import os
    import subprocess
    import tempfile
    import yaml
    from scipy.optimize import differential_evolution
    import numpy as np

    # ---- 1. Validate inputs ----
    for p, label in [
        (args.template, "template"),
        (args.allowlist, "allowlist"),
        (args.rules, "rules"),
        (args.target_wav, "target_wav"),
        (args.baseline_fxp, "baseline_fxp"),
        (args.fxp2wav_bin, "fxp2wav_bin"),
    ]:
        if not Path(p).expanduser().exists():
            print(f"error: {label} file not found: {p}", file=sys.stderr)
            return EXIT_ARG_ERROR

    template = Path(args.template).expanduser()
    allowlist = Path(args.allowlist).expanduser()
    rules_path = Path(args.rules).expanduser()
    target_wav = Path(args.target_wav).expanduser()
    baseline_fxp = Path(args.baseline_fxp).expanduser()
    fxp2wav_bin = Path(args.fxp2wav_bin).expanduser()
    output_fxp = Path(args.output_fxp).expanduser()
    output_wav = Path(args.output_wav).expanduser()
    output_report = Path(args.output_report).expanduser()
    output_analysis_report = Path(args.output_analysis_report).expanduser()

    # ---- 2. Load rules + search space + weights ----
    rules = yaml.safe_load(rules_path.read_text(encoding="utf-8"))
    drum_rules = (rules.get("drum_rules") or {}).get(args.drum_type)
    if drum_rules is None:
        print(f"error: drum_type {args.drum_type!r} not in rules", file=sys.stderr)
        return EXIT_ARG_ERROR

    search_space = drum_rules.get("search_space")
    if not search_space:
        print(f"error: search_space not defined for drum_type {args.drum_type!r}", file=sys.stderr)
        return EXIT_DATA_ERROR

    weights = drum_rules.get("distance_weights", {})

    # ---- 3. Load baseline (= Kick 909ish reference) + restrict to allowlist + search space exclude ----
    allowlist_data = yaml.safe_load(allowlist.read_text(encoding="utf-8"))
    allowed_names = {p["xml_element_name"] for p in allowlist_data.get("allowed_parameters", []) or []}

    baseline_full = _load_baseline_from_fxp(baseline_fxp)
    # Only keep baseline values that are in allowlist + NOT in search space (= fixed baseline = enum / routing)
    search_keys = list(search_space.keys())
    fixed_baseline = {k: v for k, v in baseline_full.items() if k in allowed_names and k not in search_keys}

    print(f"# search_space: {len(search_keys)} continuous parameters", file=sys.stderr)
    print(f"# fixed_baseline (= Kick 909ish enum/routing): {len(fixed_baseline)} elements", file=sys.stderr)

    # ---- 4. Extract target features (= reference) ----
    print(f"# extracting target features from {target_wav}", file=sys.stderr)
    target_features = extract_features(target_wav)

    # ---- 5. Workdir for transient .fxp / .wav per trial ----
    workdir = Path(tempfile.mkdtemp(prefix="pmdneo-opt-"))
    print(f"# workdir: {workdir}", file=sys.stderr)

    trial_history: list[dict] = []
    best_state = {"score": float("inf"), "params": None, "features": None, "fxp_bytes": None, "wav_bytes": None}

    def objective(x: "np.ndarray") -> float:
        trial_num = len(trial_history)
        # Build overrides
        overrides = dict(fixed_baseline)
        for key, value in zip(search_keys, x):
            overrides[key] = f"{value:.6f}"
        # Bridge invoke
        candidate_fxp = workdir / f"trial_{trial_num:04d}.fxp"
        candidate_wav = workdir / f"trial_{trial_num:04d}.wav"
        try:
            bridge_cmd = [
                sys.executable, "scripts/fxp_template_patch.py", "patch",
                "--template", str(template),
                "--allowlist", str(allowlist),
                "--output", str(candidate_fxp),
            ] + _build_override_args(overrides)
            subprocess.run(bridge_cmd, check=True, capture_output=True, text=True)
            # Render
            render_env = dict(os.environ)
            render_env["SURGE_RNG_SEED"] = str(args.seed)
            render_cmd = [
                str(fxp2wav_bin),
                "--patch", str(candidate_fxp),
                "--out", str(candidate_wav),
                "--note", "36",
                "--velocity", "127",
                "--duration-ms", "800",
            ]
            subprocess.run(render_cmd, check=True, capture_output=True, text=True, env=render_env)
            # Feature extract + score
            candidate_features = extract_features(candidate_wav)
            score = _compute_distance_score(candidate_features, target_features, weights)
        except subprocess.CalledProcessError as exc:
            print(f"# trial {trial_num}: subprocess FAIL = {exc}", file=sys.stderr)
            score = 1e6  # = high penalty
            candidate_features = None
        except Exception as exc:
            print(f"# trial {trial_num}: unexpected FAIL = {exc}", file=sys.stderr)
            score = 1e6
            candidate_features = None

        trial_history.append({
            "trial_num": trial_num,
            "params": {k: float(v) for k, v in zip(search_keys, x.tolist())},
            "score": float(score),
            "features": candidate_features,
        })

        # Update best
        if score < best_state["score"]:
            best_state["score"] = float(score)
            best_state["params"] = {k: float(v) for k, v in zip(search_keys, x.tolist())}
            best_state["features"] = candidate_features
            if candidate_fxp.exists():
                best_state["fxp_bytes"] = candidate_fxp.read_bytes()
            if candidate_wav.exists():
                best_state["wav_bytes"] = candidate_wav.read_bytes()
            print(f"# trial {trial_num}: NEW BEST score={score:.4f}", file=sys.stderr)
        else:
            if trial_num % 10 == 0:
                print(f"# trial {trial_num}: score={score:.4f} (best={best_state['score']:.4f})", file=sys.stderr)

        return score

    # ---- 6. Run optimizer ----
    bounds = [(search_space[k]["min"], search_space[k]["max"]) for k in search_keys]
    print(f"# starting differential_evolution: maxiter={args.max_iter}, popsize={args.popsize}, seed={args.seed}", file=sys.stderr)
    start_ts = datetime.datetime.now()
    try:
        result = differential_evolution(
            objective,
            bounds=bounds,
            seed=args.seed,
            maxiter=args.max_iter,
            popsize=args.popsize,
            tol=0.01,
            workers=1,
            polish=False,  # = skip local refinement to keep deterministic + fast
            init="sobol",
        )
    except Exception as exc:
        print(f"# optimizer failed: {exc}", file=sys.stderr)
        return EXIT_RUNTIME_ERROR
    end_ts = datetime.datetime.now()

    duration_sec = (end_ts - start_ts).total_seconds()
    total_trials = len(trial_history)
    print(f"# optimization complete: {total_trials} trials in {duration_sec:.1f} sec", file=sys.stderr)
    print(f"# best score: {best_state['score']:.4f}", file=sys.stderr)

    # ---- 7. Write best candidate .fxp + .wav ----
    if best_state["fxp_bytes"]:
        output_fxp.parent.mkdir(parents=True, exist_ok=True)
        output_fxp.write_bytes(best_state["fxp_bytes"])
        print(f"# wrote best fxp: {output_fxp}", file=sys.stderr)
    if best_state["wav_bytes"]:
        output_wav.parent.mkdir(parents=True, exist_ok=True)
        output_wav.write_bytes(best_state["wav_bytes"])
        print(f"# wrote best wav: {output_wav}", file=sys.stderr)

    # ---- 8. Engineering gate via validate ----
    engineering_pass = False
    failure_categories = []
    if output_wav.exists():
        # Run validate via subprocess (= same script, validate subcommand)
        validate_cmd = [
            sys.executable, "scripts/feature_search.py", "validate",
            str(output_wav),
            "--rules", str(rules_path),
            "--drum-type", args.drum_type,
            "--format", "yaml",
        ]
        try:
            validate_proc = subprocess.run(validate_cmd, capture_output=True, text=True)
            output_analysis_report.parent.mkdir(parents=True, exist_ok=True)
            output_analysis_report.write_text(validate_proc.stdout, encoding="utf-8")
            analysis_data = yaml.safe_load(validate_proc.stdout)
            engineering_pass = analysis_data["summary"]["overall_status"] == "engineering_pass"
            failure_categories = analysis_data["summary"]["failure_categories"]
            print(f"# engineering gate: {analysis_data['summary']['overall_status']}", file=sys.stderr)
        except Exception as exc:
            print(f"# validate failed: {exc}", file=sys.stderr)

    # ---- 9. Distance threshold check ----
    distance_pass = best_state["score"] <= args.threshold
    overall_engineering_pass = engineering_pass and distance_pass

    # ---- 10. Generate optimization-report.yaml ----
    # Compute hashes
    def _sha256_of(p: Path) -> str:
        return hashlib.sha256(p.read_bytes()).hexdigest()

    # Top 5 candidates by score
    sorted_trials = sorted(trial_history, key=lambda t: t["score"])[:5]
    top5 = [
        {
            "trial_num": t["trial_num"],
            "score": t["score"],
            "params": t["params"],
        }
        for t in sorted_trials
    ]

    # Failure reason histogram (= per-trial validate would be too slow; instead use score-based bucketing)
    score_buckets = {"score<5": 0, "5<=score<20": 0, "20<=score<100": 0, "score>=100": 0}
    for t in trial_history:
        s = t["score"]
        if s < 5: score_buckets["score<5"] += 1
        elif s < 20: score_buckets["5<=score<20"] += 1
        elif s < 100: score_buckets["20<=score<100"] += 1
        else: score_buckets["score>=100"] += 1

    report = {
        "metadata": {
            "generated_at": end_ts.isoformat(),
            "generator": "scripts/feature_search.py optimize",
            "duration_sec": round(duration_sec, 2),
            "drum_type": args.drum_type,
            "rules_file": str(rules_path),
            "rules_version": rules.get("rules_version", "?"),
        },
        "optimizer": {
            "name": "scipy.optimize.differential_evolution",
            "scipy_version": __import__("scipy").__version__,
            "random_seed": args.seed,
            "max_iter": args.max_iter,
            "popsize": args.popsize,
            "init": "sobol",
            "polish": False,
            "tolerance": 0.01,
            "workers": 1,
        },
        "search_space": {
            k: {
                "min": float(search_space[k]["min"]),
                "max": float(search_space[k]["max"]),
                "baseline": float(search_space[k]["baseline"]),
                "scale": search_space[k].get("scale", "unknown"),
            }
            for k in search_keys
        },
        "fixed_baseline": fixed_baseline,
        "fixed_baseline_count": len(fixed_baseline),
        "inputs": {
            "target_wav": str(target_wav),
            "target_wav_sha256": _sha256_of(target_wav),
            "template_fxp": str(template),
            "template_fxp_sha256": _sha256_of(template),
            "baseline_fxp": str(baseline_fxp),
            "baseline_fxp_sha256": _sha256_of(baseline_fxp),
            "allowlist": str(allowlist),
            "allowlist_version": allowlist_data.get("allowlist_version", "?"),
            "fxp2wav_bin": str(fxp2wav_bin),
        },
        "trials": {
            "total": total_trials,
            "duration_sec": round(duration_sec, 2),
            "score_histogram": score_buckets,
        },
        "best_candidate": {
            "score": best_state["score"],
            "params": best_state["params"],
            "features": best_state["features"],
            "output_fxp": str(output_fxp) if best_state["fxp_bytes"] else None,
            "output_fxp_sha256": _sha256_of(output_fxp) if output_fxp.exists() else None,
            "output_wav": str(output_wav) if best_state["wav_bytes"] else None,
            "output_wav_sha256": _sha256_of(output_wav) if output_wav.exists() else None,
        },
        "engineering_gate": {
            "validate_engineering_pass": engineering_pass,
            "failure_categories": failure_categories,
            "distance_threshold": args.threshold,
            "distance_pass": distance_pass,
            "overall_engineering_pass": overall_engineering_pass,
            "analysis_report_path": str(output_analysis_report) if output_analysis_report.exists() else None,
        },
        "top_5_candidates": top5,
        "full_trial_history": [
            {"trial_num": t["trial_num"], "score": t["score"], "params": t["params"]}
            for t in trial_history
        ],
        "reproducibility": {
            "command_template": (
                f"python3 scripts/feature_search.py optimize "
                f"--target-wav {target_wav} --baseline-fxp {baseline_fxp} "
                f"--template {template} --allowlist {allowlist} --rules {rules_path} "
                f"--drum-type {args.drum_type} --seed {args.seed} "
                f"--max-iter {args.max_iter} --popsize {args.popsize} "
                f"--output-fxp {output_fxp} --output-wav {output_wav} "
                f"--output-report {output_report} --output-analysis-report {output_analysis_report}"
            ),
        },
    }

    output_report.parent.mkdir(parents=True, exist_ok=True)
    output_report.write_text(
        yaml.safe_dump(report, allow_unicode=True, sort_keys=False, default_flow_style=False),
        encoding="utf-8",
    )
    print(f"# wrote optimization-report: {output_report}", file=sys.stderr)

    # ---- 11. Cleanup workdir (= optional、 keep for debug if --keep-workdir) ----
    if not args.keep_workdir:
        import shutil
        shutil.rmtree(workdir, ignore_errors=True)

    # ---- 12. Final summary to stdout ----
    print(json.dumps({
        "status": "engineering_pass" if overall_engineering_pass else "engineering_fail",
        "best_score": best_state["score"],
        "distance_threshold": args.threshold,
        "distance_pass": distance_pass,
        "validate_engineering_pass": engineering_pass,
        "failure_categories": failure_categories,
        "total_trials": total_trials,
        "duration_sec": round(duration_sec, 2),
        "output_fxp": str(output_fxp) if best_state["fxp_bytes"] else None,
        "output_wav": str(output_wav) if best_state["wav_bytes"] else None,
        "optimization_report": str(output_report),
        "analysis_report": str(output_analysis_report) if output_analysis_report.exists() else None,
    }, indent=2))

    return EXIT_OK if overall_engineering_pass else 67


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

    p_audition = subparsers.add_parser(
        "audition-check",
        help="π15 audition correlation check = N candidate × human score vs metric_v2 score の Spearman correlation (= π14 新規)",
    )
    p_audition.add_argument("input", type=Path, help="audition-input.yaml = candidates list + target_wav + rules")
    p_audition.add_argument(
        "--scores", type=str, default=None,
        help="comma-separated human aesthetic scores 1-5 (= 例 '5,1,2,4,3,4,2,3'、 candidate 順、 未指定なら input YAML の human_score field 使用)",
    )
    p_audition.add_argument(
        "--threshold", type=float, default=0.7,
        help="absolute Spearman correlation threshold (= default 0.7 越川氏 directive)",
    )
    p_audition.add_argument(
        "--output", type=Path, default=None,
        help="output audition-output.yaml (= optional、 stdout だけでよければ未指定)",
    )

    p_optimize = subparsers.add_parser(
        "optimize",
        help="Black-box optimization closed loop = scipy.optimize.differential_evolution (= π12 新規)",
    )
    p_optimize.add_argument("--template", type=Path, required=True, help="template .fxp path")
    p_optimize.add_argument("--allowlist", type=Path, required=True, help="parameter-allowlist.yaml")
    p_optimize.add_argument("--rules", type=Path, required=True, help="feature-rules.yaml (= search_space + weights)")
    p_optimize.add_argument("--drum-type", choices=["BD", "SD", "CYM", "HH", "TOM", "RIM"], default="BD")
    p_optimize.add_argument("--target-wav", type=Path, required=True, help="reference WAV (= aesthetic target)")
    p_optimize.add_argument("--baseline-fxp", type=Path, required=True, help="baseline fxp (= enum/routing 固定 source、 例 Kick 909ish.fxp)")
    p_optimize.add_argument("--fxp2wav-bin", type=Path, required=True, help="fxp2wav-surge binary path")
    p_optimize.add_argument("--output-fxp", type=Path, required=True, help="best candidate fxp output")
    p_optimize.add_argument("--output-wav", type=Path, required=True, help="best candidate wav output")
    p_optimize.add_argument("--output-report", type=Path, required=True, help="optimization-report.yaml output")
    p_optimize.add_argument("--output-analysis-report", type=Path, required=True, help="analysis-report.yaml output (= best validate)")
    p_optimize.add_argument("--seed", type=int, default=2608, help="random seed (= deterministic)")
    p_optimize.add_argument("--max-iter", type=int, default=5, help="max generations")
    p_optimize.add_argument("--popsize", type=int, default=8, help="population size per generation")
    p_optimize.add_argument("--threshold", type=float, default=5.0, help="distance score threshold for engineering_pass")
    p_optimize.add_argument("--keep-workdir", action="store_true", help="keep tmp workdir for debugging")

    args = parser.parse_args()

    if args.command == "extract":
        return extract_command(args)
    if args.command == "compare":
        return compare_command(args)
    if args.command == "validate":
        return validate_command(args)
    if args.command == "audition-check":
        return audition_check_command(args)
    if args.command == "optimize":
        return optimize_command(args)

    parser.print_help()
    return EXIT_ARG_ERROR


if __name__ == "__main__":
    sys.exit(main())
