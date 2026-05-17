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
import hashlib
import json
import math
import sys
import wave
from pathlib import Path

# Exit code constants
EXIT_OK = 0
EXIT_ARG_ERROR = 64
EXIT_DATA_ERROR = 65
EXIT_RUNTIME_ERROR = 66
EXIT_INVALID_STATE = 67

# Silence threshold (= linear amplitude、 silence 判定基準)
SILENCE_THRESHOLD = 1e-3  # = -60 dBFS、 sox stat の Maximum amplitude 程度

# Deterministic common-analysis parameters (= ADR-0033 π15.5 design)
COMMON_ANALYSIS_VERSION = "0.1.0"
COMMON_HOP_LENGTH = 256
COMMON_FRAME_LENGTH = 1024
COMMON_N_FFT = 2048
COMMON_N_MELS = 32
COMMON_PYIN_FMIN = 30.0
COMMON_PYIN_FMAX = 1000.0
COMMON_BANDS = {
    "sub": (0.0, 80.0),
    "low": (80.0, 250.0),
    "low_mid": (250.0, 700.0),
    "mid": (700.0, 2000.0),
    "high": (2000.0, 8000.0),
    "air": (8000.0, math.inf),
}

PROFILE_FEATURE_FOCUS = {
    "BD": [
        "band_energy_ratio.sub",
        "band_energy_ratio.low",
        "rough_body_frequency_hz",
        "pitch_drop",
        "attack_ms",
        "decay_1e_ms",
        "tail_length_ms",
    ],
    "SD": [
        "transient_strength",
        "band_energy_ratio.mid",
        "band_energy_ratio.high",
        "noisiness_ratio",
        "decay_1e_ms",
    ],
    "HH": [
        "band_energy_ratio.high",
        "band_energy_ratio.air",
        "spectral_centroid_mean",
        "tail_length_ms",
        "attack_ms",
    ],
    "CYM": [
        "band_energy_ratio.high",
        "band_energy_ratio.air",
        "spectral_contrast_mean",
        "tail_length_ms",
    ],
    "TOM": [
        "band_energy_ratio.low",
        "band_energy_ratio.low_mid",
        "rough_body_frequency_hz",
        "pitch_contour_confidence",
        "decay_1e_ms",
    ],
    "RIM": [
        "transient_strength",
        "band_energy_ratio.mid",
        "band_energy_ratio.high",
        "tail_length_ms",
        "peak_rms_ratio",
    ],
}

PROFILE_PARAMETER_AXES = {
    "BD": ["a_osc1_pitch", "a_osc1_octave", "a_env1_attack", "a_env1_decay", "a_env1_release", "a_env2_decay", "a_lowcut"],
    "SD": ["a_level_noise", "a_env1_attack", "a_env1_decay", "a_filter1_cutoff", "a_ws_drive", "a_level_o1"],
    "HH": ["a_level_noise", "a_filter1_cutoff", "a_env1_decay", "a_env1_release", "a_ws_drive"],
    "CYM": ["a_level_noise", "a_filter1_cutoff", "a_env1_decay", "a_env1_release", "a_filter1_resonance"],
    "TOM": ["a_osc1_pitch", "a_osc1_octave", "a_env1_decay", "a_env1_release", "a_filter1_cutoff"],
    "RIM": ["a_env1_attack", "a_env1_decay", "a_level_noise", "a_ws_drive", "a_lowcut"],
}

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


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def _round_float(value: float, digits: int = 6):
    if isinstance(value, float) and (math.isinf(value) or math.isnan(value)):
        return str(value)
    return round(float(value), digits)


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _read_wav_metadata(path: Path) -> dict:
    with wave.open(str(path), "rb") as w:
        sample_width = w.getsampwidth()
        return {
            "sample_rate": int(w.getframerate()),
            "channels": int(w.getnchannels()),
            "bit_depth": int(sample_width * 8),
            "total_samples": int(w.getnframes()),
            "duration_ms": round(w.getnframes() / w.getframerate() * 1000.0, 3),
        }


def _tolist_rounded(values, digits: int = 6) -> list:
    import numpy as np

    arr = np.asarray(values, dtype=float)
    arr = np.nan_to_num(arr, nan=0.0, posinf=0.0, neginf=0.0)
    return [round(float(v), digits) for v in arr.tolist()]


def _band_masks(freqs) -> dict:
    import numpy as np

    masks = {}
    for name, (lo, hi) in COMMON_BANDS.items():
        if math.isinf(hi):
            masks[name] = freqs >= lo
        else:
            masks[name] = (freqs >= lo) & (freqs < hi)
    return masks


def _frame_rms(y, frame_length: int, hop_length: int):
    import numpy as np

    if len(y) < frame_length:
        frame = np.pad(y, (0, frame_length - len(y)))
        return np.asarray([float(np.sqrt(np.mean(frame ** 2)))])
    starts = range(0, len(y) - frame_length + 1, hop_length)
    return np.asarray([
        float(np.sqrt(np.mean(y[start:start + frame_length] ** 2)))
        for start in starts
    ])


def _log_frequency_spectrogram(power, freqs, n_bands: int):
    import numpy as np

    lo = max(20.0, float(freqs[1]) if len(freqs) > 1 else 20.0)
    hi = max(lo * 2.0, float(freqs[-1]))
    edges = np.geomspace(lo, hi, n_bands + 1)
    rows = []
    for idx in range(n_bands):
        if idx == n_bands - 1:
            mask = (freqs >= edges[idx]) & (freqs <= edges[idx + 1])
        else:
            mask = (freqs >= edges[idx]) & (freqs < edges[idx + 1])
        if not np.any(mask):
            rows.append(np.zeros(power.shape[1]))
        else:
            rows.append(np.mean(power[mask], axis=0))
    spec = np.vstack(rows)
    return 10.0 * np.log10(np.maximum(spec, 1e-12))


def extract_common_analysis(wav_path: Path) -> dict:
    """
    Extract deterministic common feature set for all 6 drum kinds.

    This is diagnostic data for profile selection and sensitivity tables.
    It is not an acceptance metric.
    """
    import numpy as np
    import scipy.signal
    import soundfile as sf

    metadata = _read_wav_metadata(wav_path)
    y_raw, sr = sf.read(str(wav_path), dtype="float32", always_2d=True)
    y = y_raw.mean(axis=1)
    if len(y) == 0:
        raise ValueError("empty WAV")

    total_samples = int(len(y))
    duration_ms = round(total_samples / sr * 1000.0, 3)
    abs_y = np.abs(y)
    peak_linear = float(np.max(abs_y))
    rms_linear = float(np.sqrt(np.mean(y ** 2)))
    peak_dbfs = linear_to_dbfs(peak_linear)
    rms_dbfs = linear_to_dbfs(rms_linear)
    clipping_count = int(np.sum(abs_y >= 0.999))

    non_silent_idx = np.where(abs_y > SILENCE_THRESHOLD)[0]
    if len(non_silent_idx) == 0:
        onset_idx = 0
        peak_idx = 0
        leading_silence_ms = duration_ms
        trailing_silence_ms = 0.0
        attack_ms = 0.0
        tail_length_ms = 0.0
    else:
        onset_idx = int(non_silent_idx[0])
        peak_idx = int(np.argmax(abs_y))
        leading_silence_ms = onset_idx / sr * 1000.0
        trailing_silence_ms = (total_samples - 1 - int(non_silent_idx[-1])) / sr * 1000.0
        attack_ms = max(0.0, (peak_idx - onset_idx) / sr * 1000.0)
        tail_length_ms = trailing_silence_ms

    if peak_idx < total_samples - 1 and peak_linear > SILENCE_THRESHOLD:
        target_amp = peak_linear / math.e
        post_peak = abs_y[peak_idx:]
        decay_idx_arr = np.where(post_peak < target_amp)[0]
        if len(decay_idx_arr) > 0:
            decay_1e_ms = float(decay_idx_arr[0] / sr * 1000.0)
        else:
            decay_1e_ms = float((total_samples - peak_idx) / sr * 1000.0)
    else:
        decay_1e_ms = 0.0

    attack_window = y[onset_idx : min(onset_idx + int(0.050 * sr), total_samples)]
    if len(attack_window) > 0:
        window_rms = float(np.sqrt(np.mean(attack_window ** 2)))
        transient_strength = float(np.max(np.abs(attack_window)) / window_rms) if window_rms > 0 else 0.0
    else:
        transient_strength = 0.0
    peak_rms_ratio = peak_linear / rms_linear if rms_linear > 0 else 0.0

    nperseg = min(COMMON_N_FFT, len(y))
    noverlap = max(0, nperseg - min(COMMON_HOP_LENGTH, nperseg))
    freqs, _, stft = scipy.signal.stft(
        y,
        fs=sr,
        window="hann",
        nperseg=nperseg,
        noverlap=noverlap,
        nfft=COMMON_N_FFT,
        boundary=None,
        padded=False,
    )
    mag = np.abs(stft)
    power = mag ** 2
    masks = _band_masks(freqs)
    total_energy = float(np.sum(power))
    band_energy_ratio = {}
    band_energy_envelope = {}
    for name, mask in masks.items():
        band_power = power[mask]
        band_total = float(np.sum(band_power))
        band_energy_ratio[name] = round(band_total / total_energy, 6) if total_energy > 0 else 0.0
        band_energy_envelope[name] = _tolist_rounded(np.sum(band_power, axis=0), 6)

    mag_sum = np.sum(mag, axis=0)
    centroid_series = np.divide(
        np.sum(mag * freqs[:, None], axis=0),
        mag_sum,
        out=np.zeros_like(mag_sum),
        where=mag_sum > 0,
    )
    spectral_centroid_mean = float(np.mean(centroid_series)) if len(centroid_series) else 0.0
    if mag.shape[1] > 1:
        positive_diff = np.maximum(np.diff(mag, axis=1), 0.0)
        onset_env = np.concatenate(([0.0], np.sqrt(np.sum(positive_diff ** 2, axis=0))))
    else:
        onset_env = np.zeros(mag.shape[1])
    spectral_flux_mean = float(np.mean(onset_env)) if len(onset_env) else 0.0

    spectral_contrast_mean = []
    for name in COMMON_BANDS:
        band_mag = mag[masks[name]]
        if band_mag.size == 0:
            spectral_contrast_mean.append(0.0)
            continue
        log_band = 20.0 * np.log10(np.maximum(band_mag, 1e-10))
        contrast_series = np.percentile(log_band, 95, axis=0) - np.percentile(log_band, 5, axis=0)
        spectral_contrast_mean.append(round(float(np.mean(contrast_series)), 4))

    log_mel = _log_frequency_spectrogram(power, freqs, COMMON_N_MELS)

    low_body_mask = (freqs >= COMMON_PYIN_FMIN) & (freqs < 700.0)
    low_body_power = power[low_body_mask]
    low_body_freqs = freqs[low_body_mask]
    if low_body_power.size > 0 and float(np.sum(low_body_power)) > 0:
        summed = np.sum(low_body_power, axis=1)
        rough_body_frequency_hz = float(low_body_freqs[int(np.argmax(summed))])
        denom = np.sum(low_body_power, axis=0)
        centroid_num = np.sum(low_body_power * low_body_freqs[:, None], axis=0)
        low_band_centroid_series = np.divide(
            centroid_num,
            denom,
            out=np.zeros_like(centroid_num),
            where=denom > 0,
        )
    else:
        rough_body_frequency_hz = 0.0
        low_band_centroid_series = np.zeros(power.shape[1])

    if low_body_power.size > 0:
        peak_idx_by_frame = np.argmax(low_body_power, axis=0)
        f0_clean = low_body_freqs[peak_idx_by_frame]
        low_total_by_frame = np.sum(low_body_power, axis=0)
        low_peak_by_frame = np.max(low_body_power, axis=0)
        pitch_conf_by_frame = np.divide(
            low_peak_by_frame,
            low_total_by_frame,
            out=np.zeros_like(low_peak_by_frame),
            where=low_total_by_frame > 0,
        )
        voiced = pitch_conf_by_frame > 0.25
        voiced_frame_ratio = float(np.mean(voiced)) if len(voiced) else 0.0
        pitch_contour_confidence = float(np.mean(pitch_conf_by_frame)) if len(pitch_conf_by_frame) else 0.0
    else:
        f0_clean = np.zeros(power.shape[1])
        voiced = np.zeros(power.shape[1], dtype=bool)
        voiced_frame_ratio = 0.0
        pitch_contour_confidence = 0.0

    try:
        import pyloudnorm as pyln

        meter = pyln.Meter(sr)
        integrated_lufs = float(meter.integrated_loudness(y))
    except Exception:
        integrated_lufs = float("-inf")

    noisiness_ratio = _clamp01(
        band_energy_ratio.get("high", 0.0) + band_energy_ratio.get("air", 0.0)
    )

    scalar = {
        "waveform": {
            "duration_ms": duration_ms,
            "sample_rate": int(metadata["sample_rate"]),
            "channels": int(metadata["channels"]),
            "bit_depth": int(metadata["bit_depth"]),
            "total_samples": int(metadata["total_samples"]),
        },
        "level": {
            "peak_dbfs": _round_float(peak_dbfs, 3),
            "rms_dbfs": _round_float(rms_dbfs, 3),
            "integrated_lufs": _round_float(integrated_lufs, 3),
            "clipping_count": clipping_count,
        },
        "timing": {
            "leading_silence_ms": round(float(leading_silence_ms), 3),
            "attack_ms": round(float(attack_ms), 3),
            "decay_1e_ms": round(float(decay_1e_ms), 3),
            "tail_length_ms": round(float(tail_length_ms), 3),
            "transient_strength": round(float(transient_strength), 3),
            "peak_rms_ratio": round(float(peak_rms_ratio), 3),
        },
        "spectrum": {
            "band_energy_ratio": band_energy_ratio,
            "spectral_centroid_mean": round(float(spectral_centroid_mean), 3),
            "spectral_flux_mean": round(float(spectral_flux_mean), 6),
            "spectral_contrast_mean": spectral_contrast_mean,
        },
        "pitchedness_noise": {
            "rough_body_frequency_hz": round(float(rough_body_frequency_hz), 3),
            "pitch_contour_confidence": round(float(pitch_contour_confidence), 6),
            "voiced_frame_ratio": round(float(voiced_frame_ratio), 6),
            "noisiness_ratio": round(float(noisiness_ratio), 6),
        },
    }

    timeseries = {
        "rms_envelope": _tolist_rounded(
            _frame_rms(y, COMMON_FRAME_LENGTH, COMMON_HOP_LENGTH),
            8,
        ),
        "onset_envelope": _tolist_rounded(onset_env, 6),
        "band_energy_envelope": band_energy_envelope,
        "spectral_centroid_series": _tolist_rounded(centroid_series, 3),
        "low_band_centroid_series": _tolist_rounded(low_band_centroid_series, 3),
        "pitch_contour": _tolist_rounded(f0_clean, 3),
        "pitch_voiced": [bool(v) for v in np.asarray(voiced).tolist()],
        "log_mel_spectrogram": [
            _tolist_rounded(row, 3) for row in np.asarray(log_mel, dtype=float)
        ],
    }

    return {
        "schema_version": COMMON_ANALYSIS_VERSION,
        "source_wav": str(wav_path),
        "source_wav_sha256": _sha256_file(wav_path),
        "analysis_params": {
            "hop_length": COMMON_HOP_LENGTH,
            "frame_length": COMMON_FRAME_LENGTH,
            "n_fft": COMMON_N_FFT,
            "n_mels": COMMON_N_MELS,
            "silence_threshold": SILENCE_THRESHOLD,
            "pitch_estimator": "low-band-peak-per-frame",
            "pitch_estimator_fmin": COMMON_PYIN_FMIN,
            "pitch_estimator_fmax": COMMON_PYIN_FMAX,
            "bands": {k: [v[0], None if math.isinf(v[1]) else v[1]] for k, v in COMMON_BANDS.items()},
        },
        "common_features": scalar,
        "timeseries": timeseries,
    }


def _triangular_membership(value: float, center: float, width: float) -> float:
    if width <= 0:
        return 0.0
    return _clamp01(1.0 - abs(value - center) / width)


def classify_drum_kind(common_analysis: dict) -> dict:
    """Rule-based deterministic drum-kind classifier for profile selection."""
    features = common_analysis["common_features"]
    bands = features["spectrum"]["band_energy_ratio"]
    timing = features["timing"]
    spectrum = features["spectrum"]
    pn = features["pitchedness_noise"]

    sub = bands.get("sub", 0.0)
    low = bands.get("low", 0.0)
    low_mid = bands.get("low_mid", 0.0)
    mid = bands.get("mid", 0.0)
    high = bands.get("high", 0.0)
    air = bands.get("air", 0.0)
    low_body = sub + low
    tom_body = low + low_mid
    mid_high = mid + high
    high_air = high + air

    centroid = float(spectrum["spectral_centroid_mean"])
    centroid_low = _clamp01(1.0 - centroid / 3000.0)
    centroid_mid = _triangular_membership(centroid, 1800.0, 1800.0)
    centroid_high = _clamp01((centroid - 1500.0) / 5000.0)
    tail = float(timing["tail_length_ms"])
    tail_short = _clamp01(1.0 - tail / 120.0)
    tail_medium = _triangular_membership(tail, 180.0, 220.0)
    tail_long = _clamp01((tail - 220.0) / 500.0)
    transient = _clamp01(float(timing["transient_strength"]) / 5.0)
    pitch_conf = _clamp01(float(pn["pitch_contour_confidence"]))
    noisiness = _clamp01(float(pn["noisiness_ratio"]))

    raw_scores = {
        "BD": (
            0.40 * _clamp01(low_body * 2.0)
            + 0.20 * centroid_low
            + 0.20 * pitch_conf
            + 0.10 * tail_medium
            + 0.10 * _clamp01(transient)
        ),
        "TOM": (
            0.35 * _clamp01(tom_body * 2.0)
            + 0.25 * pitch_conf
            + 0.20 * centroid_mid
            + 0.10 * tail_medium
            + 0.10 * _clamp01(1.0 - sub * 2.0)
        ),
        "SD": (
            0.30 * _clamp01(mid_high * 1.5)
            + 0.25 * noisiness
            + 0.20 * transient
            + 0.15 * tail_medium
            + 0.10 * centroid_mid
        ),
        "RIM": (
            0.35 * transient
            + 0.25 * tail_short
            + 0.25 * _clamp01(mid_high * 1.5)
            + 0.15 * centroid_mid
        ),
        "HH": (
            0.40 * _clamp01(high_air * 1.5)
            + 0.25 * centroid_high
            + 0.20 * tail_short
            + 0.15 * _clamp01(1.0 - pitch_conf)
        ),
        "CYM": (
            0.40 * _clamp01(high_air * 1.5)
            + 0.25 * centroid_high
            + 0.25 * tail_long
            + 0.10 * noisiness
        ),
    }
    candidates = {
        kind: round(_clamp01(score), 6)
        for kind, score in sorted(raw_scores.items(), key=lambda item: (-item[1], item[0]))
    }
    predicted_kind = next(iter(candidates))
    return {
        "schema_version": "0.1.0",
        "predicted_kind": predicted_kind,
        "confidence": candidates[predicted_kind],
        "candidates": candidates,
        "rule_version": "drum-kind-rules-v0.1.0",
        "classifier_scope": "profile-selection-only-not-acceptance",
    }


def build_profile_summary(common_analysis: dict, classifier: dict, profile: str) -> dict:
    """Build a Claude-readable profile summary from common features."""
    features = common_analysis["common_features"]
    bands = features["spectrum"]["band_energy_ratio"]
    timing = features["timing"]
    pn = features["pitchedness_noise"]

    selected = {
        "profile": profile,
        "selected_by": "classifier" if profile == classifier["predicted_kind"] else "override",
        "focus_features": PROFILE_FEATURE_FOCUS[profile],
        "parameter_axes_for_sensitivity": PROFILE_PARAMETER_AXES[profile],
        "feature_snapshot": {
            "band_energy_ratio": bands,
            "attack_ms": timing["attack_ms"],
            "decay_1e_ms": timing["decay_1e_ms"],
            "tail_length_ms": timing["tail_length_ms"],
            "transient_strength": timing["transient_strength"],
            "rough_body_frequency_hz": pn["rough_body_frequency_hz"],
            "pitch_contour_confidence": pn["pitch_contour_confidence"],
            "noisiness_ratio": pn["noisiness_ratio"],
        },
        "wording_discipline": [
            "profile summary is diagnostic only",
            "classifier selects interpretation profile only",
            "human audition remains final gate",
            "optimizer is not involved",
        ],
    }
    return selected


def _write_yaml(path: Path, data: dict) -> None:
    path.write_text(_dump_yaml(data), encoding="utf-8")


def _dump_yaml(data: dict) -> str:
    import yaml

    class NoAliasDumper(yaml.SafeDumper):
        def ignore_aliases(self, data):
            return True

    return yaml.dump(
        data,
        Dumper=NoAliasDumper,
        allow_unicode=True,
        sort_keys=False,
    )


def _write_json(path: Path, data: dict) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def analyze_drum_command(args: argparse.Namespace) -> int:
    """Emit deterministic common analysis + classifier + profile artifacts."""
    if not args.input.exists():
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        return EXIT_ARG_ERROR
    if args.profile != "auto" and args.profile not in PROFILE_FEATURE_FOCUS:
        print(f"error: unknown profile: {args.profile}", file=sys.stderr)
        return EXIT_ARG_ERROR

    try:
        common_analysis = extract_common_analysis(args.input)
        classifier = classify_drum_kind(common_analysis)
    except wave.Error as exc:
        print(f"error: WAV metadata read failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR
    except Exception as exc:
        print(f"error: common analysis failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    selected_profile = classifier["predicted_kind"] if args.profile == "auto" else args.profile
    profile_summary = build_profile_summary(common_analysis, classifier, selected_profile)

    scalar_doc = {
        "schema_version": COMMON_ANALYSIS_VERSION,
        "artifact_kind": "analysis-scalar",
        "source_wav": common_analysis["source_wav"],
        "source_wav_sha256": common_analysis["source_wav_sha256"],
        "analysis_params": common_analysis["analysis_params"],
        "common_features": common_analysis["common_features"],
    }
    timeseries_doc = {
        "schema_version": COMMON_ANALYSIS_VERSION,
        "artifact_kind": "analysis-timeseries",
        "source_wav": common_analysis["source_wav"],
        "source_wav_sha256": common_analysis["source_wav_sha256"],
        "analysis_params": common_analysis["analysis_params"],
        "timeseries": common_analysis["timeseries"],
    }
    summary_doc = {
        "schema_version": COMMON_ANALYSIS_VERSION,
        "artifact_kind": "analysis-summary",
        "source_wav": common_analysis["source_wav"],
        "source_wav_sha256": common_analysis["source_wav_sha256"],
        "classifier": classifier,
        "selected_profile": selected_profile,
        "profile_summary": profile_summary,
        "scope": {
            "metric_is_final_judge": False,
            "optimizer_involved": False,
            "human_audition_final_gate": True,
        },
    }

    if args.output_dir is None:
        output = {
            "scalar": scalar_doc,
            "classifier": classifier,
            "profile_summary": profile_summary,
        }
        if args.format == "json":
            print(json.dumps(output, ensure_ascii=False, indent=2, sort_keys=True))
        else:
            print(_dump_yaml(output))
        return EXIT_OK

    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    scalar_path = output_dir / "analysis-scalar.yaml"
    timeseries_path = output_dir / "analysis-timeseries.json"
    summary_path = output_dir / "analysis-summary.yaml"

    _write_yaml(scalar_path, scalar_doc)
    _write_json(timeseries_path, timeseries_doc)
    summary_doc["artifacts"] = {
        "analysis_scalar": scalar_path.name,
        "analysis_scalar_sha256": _sha256_file(scalar_path),
        "analysis_timeseries": timeseries_path.name,
        "analysis_timeseries_sha256": _sha256_file(timeseries_path),
    }
    _write_yaml(summary_path, summary_doc)

    print(
        _dump_yaml(
            {
                "wrote": {
                    "analysis_scalar": str(scalar_path),
                    "analysis_timeseries": str(timeseries_path),
                    "analysis_summary": str(summary_path),
                },
                "selected_profile": selected_profile,
                "predicted_kind": classifier["predicted_kind"],
                "confidence": classifier["confidence"],
            }
        )
    )
    return EXIT_OK


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


def preference_learn_command(args: argparse.Namespace) -> int:
    """
    π15 human preference learning = pairwise comparison + reject label から logistic pairwise ranking 学習.

    feature matching alone does not model human aesthetic preference (= π15 wording 規律)。
    metric correlation (= π14 audition-check) は metric calibration only、 本 subcommand は **preference learning**。
    optimizer は最終 selector ではなく、 preference model も最終 selector ではない、
    越川氏 aesthetic gate is authoritative (= ν 規律維持)。
    """
    import datetime
    import yaml
    import numpy as np
    from sklearn.linear_model import LogisticRegression
    from sklearn.preprocessing import StandardScaler

    if not args.input.exists():
        print(f"error: input YAML not found: {args.input}", file=sys.stderr)
        return EXIT_ARG_ERROR
    input_data = yaml.safe_load(args.input.read_text(encoding="utf-8"))

    candidates = input_data.get("candidates", [])
    pairs_in = (input_data.get("preferences") or {}).get("pairs", [])
    rejected_ids = (input_data.get("preferences") or {}).get("rejected", []) or []

    # ====================================================================
    # acceptance_status gate (= π15.5 corrective、 3 軸独立 protocol)
    # ====================================================================
    # relative preference (= A is better than B) ≠ candidate acceptance (= A is acceptable)。
    # global_reject_all: true なら preference model training を skip、 「relative ranking と
    # absolute acceptance を混同するな」 規律を script レベルで block。
    acceptance_status = input_data.get("acceptance_status") or {}
    global_reject_all = bool(acceptance_status.get("global_reject_all", False))
    accepted_candidates = acceptance_status.get("accepted_candidates", []) or []
    rejected_in_acceptance = acceptance_status.get("rejected_candidates", []) or []

    if global_reject_all:
        invalid_report = {
            "status": "invalid_no_accepted_candidate",
            "reason": "acceptance_status.global_reject_all = true、 全 candidate aesthetic_rejected、 preference model training skip",
            "literal_rules": [
                "relative preference (= A is better than B) ≠ candidate acceptance (= A is acceptable)",
                "pairwise ranking is auxiliary to acceptance gate",
                "all candidates can be globally rejected even if pairwise preferences exist",
                "preference model is not the accepted asset selector",
                "越川氏 aesthetic gate is authoritative",
            ],
            "input": str(args.input),
            "accepted_candidates": accepted_candidates,
            "rejected_candidates": rejected_in_acceptance,
            "pairwise_preferences_count": len(
                [p for p in pairs_in if p.get("preference") in ("A", "B", "tie")]
            ),
            "next_action": "新規 candidate set 生成 + audition v2 protocol (= acceptance gate primary + pairwise relative auxiliary)",
        }
        if hasattr(args, "output") and args.output:
            import datetime
            invalid_report["generated_at"] = datetime.datetime.now().isoformat()
            args.output.write_text(
                yaml.safe_dump(invalid_report, allow_unicode=True, sort_keys=False, width=120),
                encoding="utf-8",
            )
            print(f"# wrote invalid-state report: {args.output}", file=sys.stderr)
        print(
            "INVALID STATE: acceptance_status.global_reject_all = true、 training skip",
            file=sys.stderr,
        )
        print(json.dumps(invalid_report, ensure_ascii=False, indent=2))
        return EXIT_INVALID_STATE

    # Validate preferences are filled
    filled_pairs = [p for p in pairs_in if p.get("preference") in ("A", "B", "tie")]
    if len(filled_pairs) < 3 and not rejected_ids:
        print(
            f"error: only {len(filled_pairs)} filled pairs and 0 rejected (= 越川氏 preference 未入力?)",
            file=sys.stderr,
        )
        return EXIT_DATA_ERROR

    # Extract features for all candidates
    print(f"# extracting features for {len(candidates)} candidates", file=sys.stderr)
    features_dict = {}
    for c in candidates:
        cid = c["id"]
        wav = Path(c["wav"]).expanduser()
        if not wav.exists():
            print(f"# warning: {cid} wav not found: {wav}", file=sys.stderr)
            continue
        try:
            features_dict[cid] = extract_features(wav)
        except Exception as exc:
            print(f"# warning: {cid} extract failed: {exc}", file=sys.stderr)

    # Scalar feature keys (= preference learning では vector feature 含めず robust に保つ、 過学習回避)
    SCALAR_KEYS = [
        "peak_amplitude_dbfs", "rms_amplitude_dbfs", "clipping_count",
        "leading_silence_ms", "trailing_silence_ms", "tail_length_ms",
        "attack_ms", "decay_1e_ms", "transient_strength",
        "spectral_centroid_hz", "spectral_flux_mean",
        "low_band_ratio", "mid_band_ratio", "high_band_ratio",
        "rough_frequency_hz",
        "onset_strength_mean", "onset_strength_std", "onset_strength_peak",
        "spectral_flux_std", "lufs_integrated",
    ]

    def to_vector(features):
        return np.array([
            float(features.get(k, 0.0))
            if features.get(k) not in (None, float("-inf"), float("inf"))
            else 0.0
            for k in SCALAR_KEYS
        ])

    feat_vectors = {cid: to_vector(f) for cid, f in features_dict.items()}

    # Build training dataset
    X = []
    y = []
    pair_records = []

    # Pairwise preference (= "A" means a > b、 "B" means b > a、 "tie" = skip)
    for pair in filled_pairs:
        a_id = pair["candidates"][0]
        b_id = pair["candidates"][1]
        pref = pair["preference"]
        if a_id not in feat_vectors or b_id not in feat_vectors:
            continue
        if pref == "tie":
            pair_records.append({"a": a_id, "b": b_id, "result": "tie", "used_for_training": False})
            continue
        winner, loser = (a_id, b_id) if pref == "A" else (b_id, a_id)
        X.append(feat_vectors[winner] - feat_vectors[loser])
        y.append(1)
        X.append(feat_vectors[loser] - feat_vectors[winner])
        y.append(0)
        pair_records.append({
            "a": a_id, "b": b_id, "result": f"{winner} > {loser}",
            "used_for_training": True,
        })

    # Rejected candidates (= reject < every non-rejected)
    non_rejected = [cid for cid in feat_vectors if cid not in rejected_ids]
    reject_pairs_added = 0
    for reject_id in rejected_ids:
        if reject_id not in feat_vectors:
            continue
        for nr_id in non_rejected:
            X.append(feat_vectors[nr_id] - feat_vectors[reject_id])
            y.append(1)
            X.append(feat_vectors[reject_id] - feat_vectors[nr_id])
            y.append(0)
            reject_pairs_added += 1

    if len(X) < 6:
        print(f"error: only {len(X)} training samples、 need >= 6", file=sys.stderr)
        return EXIT_DATA_ERROR

    X = np.array(X)
    y = np.array(y)

    # Scale + train
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    model = LogisticRegression(C=args.regularization_c, max_iter=1000, random_state=2608)
    model.fit(X_scaled, y)
    train_accuracy = float(model.score(X_scaled, y))

    # Predict per-candidate preference score (= predicted probability of "this candidate > neutral reference")
    # neutral reference = mean feature vector
    neutral_vector = np.mean(list(feat_vectors.values()), axis=0)
    candidate_scores = {}
    for cid, vec in feat_vectors.items():
        diff = (vec - neutral_vector).reshape(1, -1)
        diff_scaled = scaler.transform(diff)
        proba = float(model.predict_proba(diff_scaled)[0, 1])
        candidate_scores[cid] = round(proba, 4)

    # Feature importance (= absolute coefficient value、 standardized)
    feature_importance = sorted(
        zip(SCALAR_KEYS, model.coef_[0].tolist()),
        key=lambda x: abs(x[1]),
        reverse=True,
    )
    top5 = [
        {"feature": k, "coefficient": round(float(c), 4), "abs_coef": round(abs(float(c)), 4)}
        for k, c in feature_importance[:5]
    ]

    # Sort candidates by predicted preference (= descending = best first)
    sorted_candidates = sorted(candidate_scores.items(), key=lambda x: -x[1])

    report = {
        "metadata": {
            "generated_at": datetime.datetime.now().isoformat(),
            "generator": "scripts/feature_search.py preference-learn",
            "input": str(args.input),
            "model_type": "logistic_pairwise_ranking",
            "sklearn_version": __import__("sklearn").__version__,
            "feature_dim": len(SCALAR_KEYS),
            "regularization_c": args.regularization_c,
        },
        "dataset_summary": {
            "total_candidates": len(candidates),
            "candidates_with_features": len(feat_vectors),
            "pairwise_preferences_input": len(pairs_in),
            "pairwise_used_for_training": len([r for r in pair_records if r["used_for_training"]]),
            "ties_skipped": len([r for r in pair_records if r["result"] == "tie"]),
            "rejected_candidates": rejected_ids,
            "reject_implied_pairs_added": reject_pairs_added,
            "total_training_samples": int(len(X)),
        },
        "model_quality": {
            "train_accuracy": round(train_accuracy, 4),
            "intercept": round(float(model.intercept_[0]), 4),
            "note": "train_accuracy >= 0.85 推奨、 < 0.7 だと preference data に矛盾 or 非線形性、 feature 拡張検討",
        },
        "candidate_predicted_preference": {
            "scores": {cid: candidate_scores[cid] for cid, _ in sorted_candidates},
            "interpretation": "0-1 range、 > 0.5 = neutral より preferred、 < 0.5 = neutral より dispreferred",
            "ranking_best_first": [cid for cid, _ in sorted_candidates],
        },
        "feature_importance_top5": top5,
        "feature_importance_note": "absolute coefficient value、 standardized space。 +符号 = 値増加で好まれる、 -符号 = 値減少で好まれる",
        "training_pairs": pair_records,
        "scaler_params": {
            "mean": [round(float(m), 4) for m in scaler.mean_.tolist()],
            "scale": [round(float(s), 4) for s in scaler.scale_.tolist()],
            "feature_keys": SCALAR_KEYS,
        },
        "model_coefficients": {
            k: round(float(c), 6)
            for k, c in zip(SCALAR_KEYS, model.coef_[0].tolist())
        },
        "wording_discipline_reminder": [
            "feature matching alone does not model human aesthetic preference",
            "metric correlation is not preference learning",
            "human preference is the primary objective",
            "feature distance is auxiliary",
            "optimizer is not final selector; preference model is also not final selector",
            "越川氏 aesthetic gate remains authoritative",
        ],
        "next_step_options": [
            "1. preference model を optimize objective に統合 (= π17 候補): score = α * feature_distance + β * (1 - predicted_preference)",
            "2. preference data 拡充 (= さらに pair 追加 / candidate 追加 + 再 train) で model 強化",
            "3. preference 矛盾 detect (= train_accuracy 低い場合) → 越川氏 audition 再検討",
        ],
    }

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            yaml.safe_dump(report, allow_unicode=True, sort_keys=False, default_flow_style=False),
            encoding="utf-8",
        )
        print(f"# wrote preference-model-report: {args.output}", file=sys.stderr)

    print(json.dumps({
        "model_type": "logistic_pairwise_ranking",
        "train_accuracy": round(train_accuracy, 4),
        "total_training_samples": int(len(X)),
        "ranking_best_first": [cid for cid, _ in sorted_candidates],
        "top_feature": top5[0]["feature"] if top5 else None,
        "report": str(args.output) if args.output else None,
    }, indent=2, ensure_ascii=False))

    return EXIT_OK


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


# ============================================================================
# sensitivity-sweep subcommand (= ADR-0033 軌道修正、 one-factor sensitivity table)
# ----------------------------------------------------------------------------
# 1 baseline .fxp / 1 parameter / 1 delta / 1 render / 1 analyze-drum / 1 row。
# optimizer ではない、 best candidate も選ばない、 accept/reject 判断もしない。
# feature delta と effect summary を deterministic に記録するだけ。
# ============================================================================

def _fxp_load_segments(fxp_path: Path) -> dict:
    """Read .fxp → parse VST2 header + chunk segments (= sub3 / xml / trailing)."""
    import importlib.util as _ilu
    import struct as _struct
    script_path = Path(__file__).parent / "fxp_template_patch.py"
    spec = _ilu.spec_from_file_location("_fxp_tp", script_path)
    module = _ilu.module_from_spec(spec)
    spec.loader.exec_module(module)

    data = fxp_path.read_bytes()
    header = module.parse_vst2_header(data)
    chunk_byte_size = _struct.unpack(">I", data[56:60])[0]
    chunk = data[60 : 60 + chunk_byte_size]
    sub3, xml_body, trailing = module.extract_chunk_segments(chunk)
    return {
        "data": data,
        "header": header,
        "chunk_byte_size": chunk_byte_size,
        "sub3": sub3,
        "xml_body": xml_body,
        "trailing": trailing,
        "module": module,
    }


def _fxp_extract_parameter_value(xml_body: bytes, parameter_name: str) -> str | None:
    """Return current value string for <parameter_name value="..."/> or None."""
    import re
    pattern = (
        rb'<' + re.escape(parameter_name.encode()) + rb'\b[^>]*?\bvalue="([^"]+)"'
    )
    match = re.search(pattern, xml_body)
    if match is None:
        return None
    return match.group(1).decode("ascii", errors="replace")


def _fxp_patch_single_parameter(
    baseline_fxp: Path,
    parameter_name: str,
    new_value: str,
    output_fxp: Path,
) -> dict:
    """Patch baseline .fxp で 1 parameter の value を new_value に差し替え、 output_fxp に write。

    Returns dict with old_value / new_value / fxp_sha256 / chunk_byte_size。
    """
    segments = _fxp_load_segments(baseline_fxp)
    module = segments["module"]
    data = segments["data"]
    old_chunk_byte_size = segments["chunk_byte_size"]

    new_xml, old_value = module._modify_xml_element_value(
        segments["xml_body"], parameter_name, new_value
    )
    if old_value is None:
        raise RuntimeError(f"parameter {parameter_name!r} not found in .fxp XML")

    new_chunk = segments["sub3"] + new_xml + segments["trailing"]
    new_chunk_byte_size = len(new_chunk)
    delta_bytes = new_chunk_byte_size - old_chunk_byte_size

    # Reconstruct file = header[0:56] + new chunk_byte_size + new_chunk
    head_prefix = bytearray(data[:60])
    head_prefix[56:60] = new_chunk_byte_size.to_bytes(4, "big")
    # outer byteSize (= field 4-8) も update (= remaining bytes from offset 8 onwards)
    old_total = int.from_bytes(head_prefix[4:8], "big")
    head_prefix[4:8] = (old_total + delta_bytes).to_bytes(4, "big")
    new_data_bytes = bytes(head_prefix) + new_chunk

    # invariant verify (= sub3 header / trailing 不変、 XML well-formed)
    module._verify_patch_invariants(
        data, new_data_bytes, {parameter_name}, {parameter_name}
    )

    output_fxp.parent.mkdir(parents=True, exist_ok=True)
    output_fxp.write_bytes(new_data_bytes)
    return {
        "old_value": old_value,
        "new_value": new_value,
        "fxp_sha256": _sha256_file(output_fxp),
        "chunk_byte_size": new_chunk_byte_size,
    }


def _invoke_fxp2wav_surge(
    producer_cmd: str,
    fxp_path: Path,
    wav_path: Path,
    note: int,
    velocity: int,
    duration_ms: int,
    tail_ms: int,
    sample_rate: int,
    seed: int,
) -> dict:
    """Subprocess invoke external producer (= §決定 25 ι'' = scope-in not repo-in)。"""
    import os
    import subprocess
    env = os.environ.copy()
    env["SURGE_RNG_SEED"] = str(seed)
    wav_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        producer_cmd,
        "--patch", str(fxp_path),
        "--out", str(wav_path),
        "--note", str(note),
        "--velocity", str(velocity),
        "--duration-ms", str(duration_ms),
        "--tail-ms", str(tail_ms),
        "--sample-rate", str(sample_rate),
    ]
    result = subprocess.run(cmd, env=env, capture_output=True, text=True)
    if result.returncode != 0 or not wav_path.exists():
        raise RuntimeError(
            f"fxp2wav-surge invocation failed: returncode={result.returncode}\n"
            f"  cmd: {' '.join(cmd)}\n"
            f"  stderr: {result.stderr[:500]}"
        )
    return {
        "wav_sha256": _sha256_file(wav_path),
        "returncode": result.returncode,
        "producer_cmd": producer_cmd,
        "render_params": {
            "note": note,
            "velocity": velocity,
            "duration_ms": duration_ms,
            "tail_ms": tail_ms,
            "sample_rate": sample_rate,
            "surge_rng_seed": seed,
        },
    }


def _analyze_drum_into(wav_path: Path, output_dir: Path, profile_override: str | None) -> dict:
    """Run common analysis + classifier + profile summary → write 3 artifact + return summary dict。"""
    common_analysis = extract_common_analysis(wav_path)
    classifier = classify_drum_kind(common_analysis)
    selected_profile = (
        classifier["predicted_kind"] if profile_override in (None, "auto") else profile_override
    )
    profile_summary = build_profile_summary(common_analysis, classifier, selected_profile)

    output_dir.mkdir(parents=True, exist_ok=True)
    scalar_path = output_dir / "analysis-scalar.yaml"
    timeseries_path = output_dir / "analysis-timeseries.json"
    summary_path = output_dir / "analysis-summary.yaml"

    scalar_doc = {
        "schema_version": COMMON_ANALYSIS_VERSION,
        "artifact_kind": "analysis-scalar",
        "source_wav": common_analysis["source_wav"],
        "source_wav_sha256": common_analysis["source_wav_sha256"],
        "analysis_params": common_analysis["analysis_params"],
        "common_features": common_analysis["common_features"],
    }
    timeseries_doc = {
        "schema_version": COMMON_ANALYSIS_VERSION,
        "artifact_kind": "analysis-timeseries",
        "source_wav": common_analysis["source_wav"],
        "source_wav_sha256": common_analysis["source_wav_sha256"],
        "analysis_params": common_analysis["analysis_params"],
        "timeseries": common_analysis["timeseries"],
    }
    summary_doc = {
        "schema_version": COMMON_ANALYSIS_VERSION,
        "artifact_kind": "analysis-summary",
        "source_wav": common_analysis["source_wav"],
        "source_wav_sha256": common_analysis["source_wav_sha256"],
        "classifier": classifier,
        "selected_profile": selected_profile,
        "profile_summary": profile_summary,
        "scope": {
            "metric_is_final_judge": False,
            "optimizer_involved": False,
            "human_audition_final_gate": True,
        },
    }

    _write_yaml(scalar_path, scalar_doc)
    _write_json(timeseries_path, timeseries_doc)
    summary_doc["artifacts"] = {
        "analysis_scalar": scalar_path.name,
        "analysis_scalar_sha256": _sha256_file(scalar_path),
        "analysis_timeseries": timeseries_path.name,
        "analysis_timeseries_sha256": _sha256_file(timeseries_path),
    }
    _write_yaml(summary_path, summary_doc)
    return {
        "summary_doc": summary_doc,
        "summary_path": summary_path,
        "scalar_path": scalar_path,
        "timeseries_path": timeseries_path,
        "summary_sha256": _sha256_file(summary_path),
    }


def _scalar_feature_delta(baseline_snapshot: dict, candidate_snapshot: dict) -> dict:
    """Compute scalar feature delta = candidate - baseline (= profile feature_snapshot)。"""
    delta: dict = {}
    for key, base_val in baseline_snapshot.items():
        if key not in candidate_snapshot:
            continue
        if isinstance(base_val, dict):
            sub_delta: dict = {}
            for sub_key, sub_val in base_val.items():
                cand_sub = candidate_snapshot[key].get(sub_key)
                if isinstance(sub_val, (int, float)) and isinstance(cand_sub, (int, float)):
                    sub_delta[sub_key] = round(cand_sub - sub_val, 6)
            if sub_delta:
                delta[key + "_delta"] = sub_delta
        elif isinstance(base_val, (int, float)) and isinstance(
            candidate_snapshot[key], (int, float)
        ):
            delta[key + "_delta"] = round(candidate_snapshot[key] - base_val, 6)
    return delta


def _effect_summary_from_delta(parameter: str, feature_delta: dict) -> dict:
    """Generate minimum literal effect labels from scalar delta sign。 越川氏 hand-on 追記前提。"""
    primary = None
    secondary: list[str] = []
    # 主要 scalar に対する sign-based literal label (= 越川氏 hand-on で精緻化)
    if "decay_1e_ms_delta" in feature_delta:
        d = feature_delta["decay_1e_ms_delta"]
        if abs(d) > 5:
            primary = "shorter_decay" if d < 0 else "longer_decay"
    if "attack_ms_delta" in feature_delta:
        d = feature_delta["attack_ms_delta"]
        if abs(d) > 2:
            label = "shorter_attack" if d < 0 else "longer_attack"
            if primary is None:
                primary = label
            else:
                secondary.append(label)
    if "rough_body_frequency_hz_delta" in feature_delta:
        d = feature_delta["rough_body_frequency_hz_delta"]
        if abs(d) > 5:
            label = "lower_body_pitch" if d < 0 else "higher_body_pitch"
            if primary is None:
                primary = label
            else:
                secondary.append(label)
    if "tail_length_ms_delta" in feature_delta:
        d = feature_delta["tail_length_ms_delta"]
        if abs(d) > 20:
            label = "shorter_tail" if d < 0 else "longer_tail"
            if primary is None:
                primary = label
            else:
                secondary.append(label)
    return {
        "primary": primary or "no_significant_change",
        "secondary": secondary,
        "note": "machine-generated literal label from scalar delta sign; 越川氏 hand-on 追記で精緻化想定",
    }


def sensitivity_sweep_command(args: argparse.Namespace) -> int:
    """π15.5 軌道修正 = one-factor sensitivity table = 1 parameter / 1 delta / 1 render / 1 analyze / 1 row。

    optimizer は呼ばない。 best candidate も選ばない。 accept/reject 判断もしない。
    feature delta と effect summary を deterministic に記録するだけ。
    """
    import csv
    import datetime
    import shutil

    if not args.baseline_fxp.exists():
        print(f"error: baseline fxp not found: {args.baseline_fxp}", file=sys.stderr)
        return EXIT_ARG_ERROR

    # parse deltas
    try:
        deltas = [float(x.strip()) for x in args.deltas.split(",") if x.strip()]
    except ValueError as exc:
        print(f"error: --deltas parse failed: {exc}", file=sys.stderr)
        return EXIT_ARG_ERROR
    if not deltas:
        print("error: --deltas empty", file=sys.stderr)
        return EXIT_ARG_ERROR

    # extract baseline parameter value
    segments = _fxp_load_segments(args.baseline_fxp)
    baseline_value_str = _fxp_extract_parameter_value(
        segments["xml_body"], args.parameter
    )
    if baseline_value_str is None:
        print(
            f"error: parameter {args.parameter!r} not found in {args.baseline_fxp}",
            file=sys.stderr,
        )
        return EXIT_DATA_ERROR
    baseline_value = float(baseline_value_str)

    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    # baseline render + analyze (= delta=0 別扱い、 reference row として記録)
    baseline_dir = output_dir / "baseline"
    baseline_dir.mkdir(parents=True, exist_ok=True)
    baseline_fxp_copy = baseline_dir / "patched.fxp"
    shutil.copy2(args.baseline_fxp, baseline_fxp_copy)
    baseline_wav = baseline_dir / "rendered.wav"
    print(f"# baseline render: {args.baseline_fxp.name}", file=sys.stderr)
    baseline_render = _invoke_fxp2wav_surge(
        args.producer_cmd, baseline_fxp_copy, baseline_wav,
        args.note, args.velocity, args.duration_ms, args.tail_ms,
        args.sample_rate, args.seed,
    )
    print(f"# baseline analyze", file=sys.stderr)
    baseline_analysis = _analyze_drum_into(baseline_wav, baseline_dir, args.profile)
    baseline_snapshot = baseline_analysis["summary_doc"]["profile_summary"]["feature_snapshot"]

    # sweep
    rows = []
    for delta in deltas:
        new_value = baseline_value + delta
        new_value_str = f"{new_value:.6f}"
        delta_label = f"delta_{delta:+.4f}".replace("+", "p").replace("-", "m").replace(".", "_")
        trial_dir = output_dir / delta_label
        trial_dir.mkdir(parents=True, exist_ok=True)

        patched_fxp = trial_dir / "patched.fxp"
        print(f"# {args.parameter} delta={delta:+.4f} → patch + render + analyze", file=sys.stderr)
        patch_info = _fxp_patch_single_parameter(
            args.baseline_fxp, args.parameter, new_value_str, patched_fxp
        )
        rendered_wav = trial_dir / "rendered.wav"
        render_info = _invoke_fxp2wav_surge(
            args.producer_cmd, patched_fxp, rendered_wav,
            args.note, args.velocity, args.duration_ms, args.tail_ms,
            args.sample_rate, args.seed,
        )
        analysis = _analyze_drum_into(rendered_wav, trial_dir, args.profile)
        candidate_snapshot = analysis["summary_doc"]["profile_summary"]["feature_snapshot"]
        feature_delta = _scalar_feature_delta(baseline_snapshot, candidate_snapshot)
        effect_summary = _effect_summary_from_delta(args.parameter, feature_delta)

        rows.append({
            "parameter": args.parameter,
            "baseline_value": baseline_value,
            "delta": delta,
            "new_value": round(new_value, 6),
            "fxp_sha256": patch_info["fxp_sha256"],
            "wav_sha256": render_info["wav_sha256"],
            "analysis_summary_sha256": analysis["summary_sha256"],
            "feature_delta": feature_delta,
            "effect_summary": effect_summary,
            "predicted_kind": analysis["summary_doc"]["classifier"]["predicted_kind"],
            "trial_dir": str(trial_dir),
        })

    # write sensitivity-table.yaml
    table_doc = {
        "schema_version": "0.1.0",
        "artifact_kind": "sensitivity-table",
        "generated_at": datetime.datetime.now().isoformat(),
        "generator": "scripts/feature_search.py sensitivity-sweep",
        "scope": {
            "metric_is_final_judge": False,
            "optimizer_involved": False,
            "human_audition_final_gate": True,
            "selection_decision": False,
            "trial_protocol": "1 parameter / 1 delta / 1 render / 1 analyze / 1 row",
        },
        "baseline": {
            "fxp": str(args.baseline_fxp),
            "label": args.baseline_label,
            "value": baseline_value,
            "render": baseline_render,
            "analysis_summary_sha256": baseline_analysis["summary_sha256"],
            "feature_snapshot": baseline_snapshot,
        },
        "sweep": {
            "parameter": args.parameter,
            "profile": args.profile,
            "deltas": deltas,
            "render_params": {
                "note": args.note,
                "velocity": args.velocity,
                "duration_ms": args.duration_ms,
                "tail_ms": args.tail_ms,
                "sample_rate": args.sample_rate,
                "surge_rng_seed": args.seed,
            },
        },
        "rows": rows,
        "wording_discipline": [
            "this table is diagnostic only",
            "no candidate is accepted or rejected here",
            "effect_summary is machine-generated literal label, not aesthetic judgment",
            "human audition remains final gate",
            "baseline is labeled diagnostic-baseline, not accepted-baseline",
        ],
    }
    table_yaml_path = output_dir / "sensitivity-table.yaml"
    _write_yaml(table_yaml_path, table_doc)

    # write sensitivity-table.csv (= flatten for spreadsheet)
    csv_path = output_dir / "sensitivity-table.csv"
    # 全 feature_delta key を union 化
    all_delta_keys: list = []
    for row in rows:
        for k in row["feature_delta"]:
            if k not in all_delta_keys:
                all_delta_keys.append(k)
    flat_fieldnames = [
        "parameter", "baseline_value", "delta", "new_value",
        "fxp_sha256", "wav_sha256", "analysis_summary_sha256",
        "predicted_kind", "effect_primary",
    ] + all_delta_keys
    with csv_path.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=flat_fieldnames)
        writer.writeheader()
        for row in rows:
            flat: dict = {
                "parameter": row["parameter"],
                "baseline_value": row["baseline_value"],
                "delta": row["delta"],
                "new_value": row["new_value"],
                "fxp_sha256": row["fxp_sha256"],
                "wav_sha256": row["wav_sha256"],
                "analysis_summary_sha256": row["analysis_summary_sha256"],
                "predicted_kind": row["predicted_kind"],
                "effect_primary": row["effect_summary"]["primary"],
            }
            for k in all_delta_keys:
                v = row["feature_delta"].get(k)
                if isinstance(v, dict):
                    flat[k] = json.dumps(v, ensure_ascii=False, sort_keys=True)
                else:
                    flat[k] = v
            writer.writerow(flat)

    print(
        _dump_yaml({
            "wrote": {
                "sensitivity_table_yaml": str(table_yaml_path),
                "sensitivity_table_csv": str(csv_path),
                "baseline_dir": str(baseline_dir),
            },
            "parameter": args.parameter,
            "baseline_value": baseline_value,
            "deltas": deltas,
            "row_count": len(rows),
            "note": "diagnostic only; no accept/reject; optimizer not invoked",
        })
    )
    return EXIT_OK


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

    p_analyze_drum = subparsers.add_parser(
        "analyze-drum",
        help="Deterministic 6-drum common analysis + drum-kind classifier + profile summary (= π15.5 新規)",
    )
    p_analyze_drum.add_argument("input", type=Path, help="input WAV file path")
    p_analyze_drum.add_argument(
        "--output-dir", type=Path, default=None,
        help="directory to write analysis-scalar.yaml / analysis-timeseries.json / analysis-summary.yaml",
    )
    p_analyze_drum.add_argument(
        "--profile",
        choices=["auto", "BD", "SD", "CYM", "HH", "TOM", "RIM"],
        default="auto",
        help="profile override (= default auto via deterministic classifier)",
    )
    p_analyze_drum.add_argument(
        "--format", choices=["yaml", "json"], default="yaml",
        help="stdout format when --output-dir is omitted (= default yaml)",
    )

    p_pref = subparsers.add_parser(
        "preference-learn",
        help="π15 human preference learning = pairwise comparison + reject から logistic pairwise ranking 学習 (= π15 新規、 metric correlation の代替軸)",
    )
    p_pref.add_argument("input", type=Path, help="preference-input.yaml (= candidates + pairs + rejected)")
    p_pref.add_argument(
        "--output", type=Path, default=None,
        help="output preference-model-report.yaml",
    )
    p_pref.add_argument(
        "--regularization-c", type=float, default=1.0,
        help="LogisticRegression C parameter (= 小値ほど強 L2 regularization、 default 1.0)",
    )

    p_audition = subparsers.add_parser(
        "audition-check",
        help="π15 audition correlation check = N candidate × human score vs metric_v2 score の Spearman correlation (= π14 新規、 retroactively replaced by preference-learn in π15)",
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

    p_sweep = subparsers.add_parser(
        "sensitivity-sweep",
        help="One-factor parameter sensitivity sweep (= π15.5 軌道修正、 optimizer 不使用、 1 parameter / 1 delta / 1 render / 1 analyze / 1 row、 best candidate を選ばない、 accept/reject 判断もしない)",
    )
    p_sweep.add_argument("--baseline-fxp", type=Path, required=True, help="baseline .fxp path (= diagnostic-baseline、 accepted candidate ではない)")
    p_sweep.add_argument("--baseline-label", type=str, default="diagnostic-baseline", help="baseline label (= default diagnostic-baseline、 越川氏 directive 例 'diagnostic-baseline / aesthetic-rejected')")
    p_sweep.add_argument("--parameter", type=str, required=True, help="single parameter name (= 例 a_osc1_pitch)")
    p_sweep.add_argument("--deltas", type=str, required=True, help="comma-separated delta values (= 例 '-3,-1,0,1,3'、 baseline + delta = new value)")
    p_sweep.add_argument("--output-dir", type=Path, required=True, help="output directory for table + per-delta artifact")
    p_sweep.add_argument("--producer-cmd", type=str, default="fxp2wav-surge", help="fxp2wav-surge binary path (= default 'fxp2wav-surge' = PATH lookup、 越川氏 環境では絶対 path 推奨)")
    p_sweep.add_argument("--profile", default="auto", choices=["auto", "BD", "SD", "CYM", "HH", "TOM", "RIM"], help="drum profile override (= default auto via classifier)")
    p_sweep.add_argument("--note", type=int, default=36, help="MIDI note (= §決定 26 default 36)")
    p_sweep.add_argument("--velocity", type=int, default=127, help="MIDI velocity (= default 127)")
    p_sweep.add_argument("--duration-ms", type=int, default=800, help="render duration ms (= default 800)")
    p_sweep.add_argument("--tail-ms", type=int, default=200, help="render tail ms (= default 200)")
    p_sweep.add_argument("--sample-rate", type=int, default=44100, help="render sample rate (= default 44100)")
    p_sweep.add_argument("--seed", type=int, default=2608, help="SURGE_RNG_SEED (= default 2608、 deterministic)")

    args = parser.parse_args()

    if args.command == "extract":
        return extract_command(args)
    if args.command == "compare":
        return compare_command(args)
    if args.command == "validate":
        return validate_command(args)
    if args.command == "analyze-drum":
        return analyze_drum_command(args)
    if args.command == "preference-learn":
        return preference_learn_command(args)
    if args.command == "audition-check":
        return audition_check_command(args)
    if args.command == "sensitivity-sweep":
        return sensitivity_sweep_command(args)
    if args.command == "optimize":
        return optimize_command(args)

    parser.print_help()
    return EXIT_ARG_ERROR


if __name__ == "__main__":
    sys.exit(main())
