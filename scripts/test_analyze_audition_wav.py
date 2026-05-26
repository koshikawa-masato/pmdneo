#!/usr/bin/env python3
"""
scripts/test_analyze_audition_wav.py = ADR-0065 sprint B 4 層 gate executor unit tests

8 test cases (= ADR-0065 Annex β-10-3 literal):
  Case 1: silence wav → FAIL Layer 1 silence (= mimics candidate 3「無音 fadeout」)
  Case 2: low-freq dominated wav → FAIL Layer 1 low-freq dominance (= mimics candidate 2「ものすごい低音持続」)
  Case 3: clean multi-tone wav → PASS Layer 1
  Case 4: clipping wav → FAIL Layer 1 clipping rate
  Case 5: duration mismatch wav → FAIL Layer 1 duration
  Case 6: trace event mismatch → FAIL Layer 2 mismatch_count > 0
  Case 7: readiness report integration (clean + trace + matching events) → PASS + JSON valid + exit 0
  Case 8a: baseline skip (= no --baseline) → Layer 3 skip + pass
  Case 8b: baseline smoke (= same wav as baseline) → Layer 3 PASS L2 ≈ 0, cosine ≈ 1

Synthetic fixtures generated on-the-fly (= no committed binaries).

Run: python3 scripts/test_analyze_audition_wav.py
Exit 0: all 8 cases expected behavior verified
Exit 1: 1+ case unexpected
"""

import json
import subprocess
import sys
import tempfile
import unittest
import wave
from pathlib import Path

import numpy as np


SCRIPT_PATH = Path(__file__).parent / "analyze-audition-wav.py"
SAMPLE_RATE = 48000


def synthesize_silence(duration_sec, sample_rate=SAMPLE_RATE):
    return np.zeros(int(duration_sec * sample_rate), dtype=np.float64)


def synthesize_sine(freq_hz, duration_sec, amplitude=0.5, sample_rate=SAMPLE_RATE):
    t = np.arange(int(duration_sec * sample_rate)) / sample_rate
    return amplitude * np.sin(2 * np.pi * freq_hz * t)


def synthesize_multi_tone(freqs, duration_sec, amplitude=0.3, sample_rate=SAMPLE_RATE):
    total = np.zeros(int(duration_sec * sample_rate), dtype=np.float64)
    for f in freqs:
        total += synthesize_sine(f, duration_sec, amplitude, sample_rate)
    return total / max(1, len(freqs))  # normalize to avoid sum-induced clipping


def synthesize_clipping(duration_sec, sample_rate=SAMPLE_RATE):
    """Saturated signal (= clipping)."""
    samples = synthesize_sine(440, duration_sec, amplitude=2.0, sample_rate=sample_rate)
    return np.clip(samples, -1.0, 1.0)


def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    """Write float samples to 16-bit PCM WAV (mono)."""
    int16 = np.clip(samples * 32767, -32768, 32767).astype(np.int16)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(int16.tobytes())


def write_expected_json(path, duration_sec=1.0, events=None, material="test material", judgment="test sound"):
    data = {
        "material_description": material,
        "judgment_expected": judgment,
        "duration_sec": duration_sec,
    }
    if events is not None:
        data["events"] = events
    with open(path, "w") as f:
        json.dump(data, f)


def write_trace(path, events):
    """Write trace lines: '<ts> <chip> 0x<addr> 0x<value>'."""
    with open(path, "w") as f:
        for ev in events:
            f.write(f"{ev['timestamp_us']} {ev['chip_target']} 0x{ev['register_addr']:02x} 0x{ev['value']:02x}\n")


def run_script(wav, trace, expected, output_json, output_report, baseline=None):
    cmd = [
        sys.executable, str(SCRIPT_PATH),
        "--wav", str(wav),
        "--trace", str(trace),
        "--expected", str(expected),
        "--output-json", str(output_json),
        "--output-report", str(output_report),
    ]
    if baseline:
        cmd.extend(["--baseline", str(baseline)])
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return proc


class AuditionGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not SCRIPT_PATH.exists():
            raise RuntimeError(f"Script not found: {SCRIPT_PATH}")

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tmpdir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def _paths(self, label):
        return (
            self.tmpdir / f"{label}.wav",
            self.tmpdir / f"{label}_trace.txt",
            self.tmpdir / f"{label}_expected.json",
            self.tmpdir / f"{label}_analysis.json",
            self.tmpdir / f"{label}_report.md",
        )

    def test_case1_silence_fadeout(self):
        """Case 1: silence wav → FAIL Layer 1 (= mimics candidate 3「無音 fadeout」)"""
        wav, trace, expected, oj, orp = self._paths("case1")
        write_wav(wav, synthesize_silence(1.0))
        write_trace(trace, [])
        write_expected_json(expected, duration_sec=1.0,
                            material="silence test (= mimics candidate 3 fadeout)",
                            judgment="should detect silence as FAIL")
        proc = run_script(wav, trace, expected, oj, orp)
        self.assertEqual(proc.returncode, 1, f"silence should FAIL: stdout={proc.stdout} stderr={proc.stderr}")
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["verdict"], "fail")
        self.assertFalse(result["ready_for_audition"])
        self.assertEqual(result["layers"]["1_wav_hygiene"]["status"], "fail")
        self.assertIn("silence", result["layers"]["1_wav_hygiene"]["reason"])

    def test_case2_low_freq_dominance(self):
        """Case 2: 100Hz sine → FAIL Layer 1 (= mimics candidate 2「ものすごい低音持続」)"""
        wav, trace, expected, oj, orp = self._paths("case2")
        write_wav(wav, synthesize_sine(100, 1.0, amplitude=0.5))
        write_trace(trace, [])
        write_expected_json(expected, duration_sec=1.0,
                            material="low-freq test (= mimics candidate 2 low-freq persistence)",
                            judgment="should detect abnormal low-freq dominance as FAIL")
        proc = run_script(wav, trace, expected, oj, orp)
        self.assertEqual(proc.returncode, 1)
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["verdict"], "fail")
        self.assertEqual(result["layers"]["1_wav_hygiene"]["status"], "fail")
        self.assertIn("low-frequency dominance", result["layers"]["1_wav_hygiene"]["reason"])

    def test_case3_clean_multi_tone(self):
        """Case 3: 440 + 880 + 1320 Hz balanced → PASS Layer 1"""
        wav, trace, expected, oj, orp = self._paths("case3")
        write_wav(wav, synthesize_multi_tone([440, 880, 1320], 1.0))
        write_trace(trace, [])
        write_expected_json(expected, duration_sec=1.0)
        proc = run_script(wav, trace, expected, oj, orp)
        self.assertEqual(proc.returncode, 0, f"clean should PASS: stdout={proc.stdout} stderr={proc.stderr}")
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["verdict"], "pass")
        self.assertTrue(result["ready_for_audition"])
        self.assertEqual(result["layers"]["1_wav_hygiene"]["status"], "pass")

    def test_case4_clipping(self):
        """Case 4: saturated → FAIL Layer 1 clipping"""
        wav, trace, expected, oj, orp = self._paths("case4")
        write_wav(wav, synthesize_clipping(1.0))
        write_trace(trace, [])
        write_expected_json(expected, duration_sec=1.0)
        proc = run_script(wav, trace, expected, oj, orp)
        self.assertEqual(proc.returncode, 1)
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["verdict"], "fail")
        self.assertIn("clipping", result["layers"]["1_wav_hygiene"]["reason"])

    def test_case5_duration_mismatch(self):
        """Case 5: actual 2s vs expected 1s → FAIL Layer 1 duration"""
        wav, trace, expected, oj, orp = self._paths("case5")
        write_wav(wav, synthesize_multi_tone([440, 880, 1320], 2.0))
        write_trace(trace, [])
        write_expected_json(expected, duration_sec=1.0)
        proc = run_script(wav, trace, expected, oj, orp)
        self.assertEqual(proc.returncode, 1)
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["verdict"], "fail")
        self.assertIn("duration mismatch", result["layers"]["1_wav_hygiene"]["reason"])

    def test_case6_trace_event_mismatch(self):
        """Case 6: expected event present, trace empty → FAIL Layer 2 mismatch"""
        wav, trace, expected, oj, orp = self._paths("case6")
        write_wav(wav, synthesize_multi_tone([440, 880, 1320], 1.0))
        write_trace(trace, [])  # empty trace
        write_expected_json(
            expected,
            duration_sec=1.0,
            events=[
                {"timestamp_us": 100000, "chip_target": "ym2610_a",
                 "register_addr": 0x28, "value": 0xF0, "event_type": "note_on"},
            ],
        )
        proc = run_script(wav, trace, expected, oj, orp)
        self.assertEqual(proc.returncode, 1)
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["verdict"], "fail")
        self.assertEqual(result["layers"]["2_trace_alignment"]["status"], "fail")
        self.assertGreater(result["layers"]["2_trace_alignment"]["metrics"]["mismatch_count"], 0)

    def test_case7_readiness_report_integration(self):
        """Case 7: clean wav + matching trace + valid events → PASS + JSON schema + exit 0"""
        wav, trace, expected, oj, orp = self._paths("case7")
        write_wav(wav, synthesize_multi_tone([440, 880, 1320], 1.0))
        write_trace(trace, [
            {"timestamp_us": 100000, "chip_target": "ym2610_a", "register_addr": 0x28, "value": 0xF0},
        ])
        write_expected_json(
            expected,
            duration_sec=1.0,
            events=[
                {"timestamp_us": 100000, "chip_target": "ym2610_a",
                 "register_addr": 0x28, "value": 0xF0, "event_type": "note_on"},
            ],
            material="case7 integration test",
            judgment="balanced multi-tone audible across full duration",
        )
        proc = run_script(wav, trace, expected, oj, orp)
        self.assertEqual(proc.returncode, 0, f"case7 should PASS: stdout={proc.stdout} stderr={proc.stderr}")
        with open(oj) as f:
            result = json.load(f)
        # JSON schema verification (= NH2 反映 stable fields)
        for k in ["verdict", "ready_for_audition", "layers", "material_description",
                  "judgment_expected", "thresholds_used"]:
            self.assertIn(k, result, f"schema missing: {k}")
        for layer_key in ["1_wav_hygiene", "2_trace_alignment",
                          "3_reference_comparison", "4_readiness_report"]:
            self.assertIn(layer_key, result["layers"])
            self.assertIn("status", result["layers"][layer_key])
        self.assertEqual(result["verdict"], "pass")
        self.assertTrue(result["ready_for_audition"])
        # Readiness report content (= LR2 emphasis verification)
        report = Path(orp).read_text()
        self.assertIn("# Audition Readiness Report", report)
        self.assertIn("READY", report)
        self.assertIn("metric pass != aesthetic accept", report)
        self.assertIn("case7 integration test", report)

    def test_case8a_baseline_skip(self):
        """Case 8a: no --baseline → Layer 3 skip + auto pass"""
        wav, trace, expected, oj, orp = self._paths("case8a")
        write_wav(wav, synthesize_multi_tone([440, 880, 1320], 1.0))
        write_trace(trace, [])
        write_expected_json(expected, duration_sec=1.0)
        proc = run_script(wav, trace, expected, oj, orp, baseline=None)
        self.assertEqual(proc.returncode, 0)
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["layers"]["3_reference_comparison"]["status"], "skip")
        self.assertEqual(result["verdict"], "pass")

    def test_case8b_baseline_smoke(self):
        """Case 8b: baseline = same wav → Layer 3 PASS (L2 ≈ 0, cosine ≈ 1)"""
        wav, trace, expected, oj, orp = self._paths("case8b")
        data = synthesize_multi_tone([440, 880, 1320], 1.0)
        write_wav(wav, data)
        baseline = self.tmpdir / "baseline.wav"
        write_wav(baseline, data)
        write_trace(trace, [])
        write_expected_json(expected, duration_sec=1.0)
        proc = run_script(wav, trace, expected, oj, orp, baseline=baseline)
        self.assertEqual(proc.returncode, 0)
        with open(oj) as f:
            result = json.load(f)
        self.assertEqual(result["layers"]["3_reference_comparison"]["status"], "pass")
        l2 = result["layers"]["3_reference_comparison"]["metrics"]["l2_diff"]
        cs = result["layers"]["3_reference_comparison"]["metrics"]["cosine_similarity"]
        self.assertLess(l2, 0.01, f"L2 should be ~0 for identical wav: got {l2}")
        self.assertGreater(cs, 0.99, f"cosine should be ~1 for identical wav: got {cs}")


if __name__ == "__main__":
    unittest.main(verbosity=2)
