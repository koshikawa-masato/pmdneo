#!/usr/bin/env python3
"""audible-level-sweep-spike.py - 軸 A β-2 sub-sprint spike (= 31st session)

ADR-0042 §決定 5 β-2 規律:
- 案 A mixer 構造 6 levers の individual sweep (= 6 lever 総当たり禁止)
- 最小 cascade verify (= individual sweep PASS 候補集約)
- clipping_count == 0 hard gate (= layer 1 audible-level engineering gate)
- aesthetic 判定なし (= 越川氏 layer 2 audition は永久 scope-out)

入力:
- ベース patch reference (= /private/tmp/pmdneo-plan-a-rejected/2608_bd-plan-a.patch-spec.yaml、 read-only forensic)
- sweep parameter (= 6 lever individual sweep range)
- target audible level (= peak ∈ [-6,-3] dBFS, clipping_count == 0, rms target ± 6 dB)

処理:
- individual sweep (= 1 lever ずつ sweep 値変化、 他 lever は ベース patch 維持)
- 各 sweep 値で analysis trace (= dry-run mode で stub、 actual render は別 step で環境依存)
- layer 1 engineering gate 判定 (= peak/clipping/rms hard gate)
- 最小 cascade verify (= individual sweep PASS 候補を集約 + cascade 時の sum check)

出力 (= /tmp 配置、 repo 投入禁止):
- stdout: analysis-trace JSON literal (= per sweep value、 PASS/FAIL hard gate)
- cascade-verify summary (= 全 lever 統合時の audible level 推定)

mode:
- --dry-run (= default、 render skip + 設計妥当性確認、 stub analysis output)
- --execute (= actual render、 環境依存で本 commit 未実装 stub)

scope-out (= ADR-0042 §決定 5 + 越川氏 directive literal):
- aesthetic 判定 (= 越川氏 layer 2 audition、 永久 user scope)
- 退避 4 artifact 上書き / 削除 / 修正 / normalize (= read-only forensic)
- repo 投入 (= 全 output /tmp 配置)
- normalize / loudness normalize / wav 段階 gain (= 越川氏 directive 永久禁止)

使い方:
  python3 scripts/audible-level-sweep-spike.py [--patch-spec <path>] [--lever <name>] [--sweep-range <values>]
  python3 scripts/audible-level-sweep-spike.py --execute  # 環境依存、 別 step
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

# 軸 A β-2 規律 literal (= ADR-0042 §決定 4 layer 1 audible-level engineering gate)
LAYER1_GATE: dict[str, Any] = {
    "peak_dbfs_range": (-6.0, -3.0),       # peak target window
    "clipping_count_max": 0,                # hard gate (= 0 超は即 FAIL)
    "rms_dbfs_target": -15.0,               # ADR-0033 §π15.14 reject 原因 = -34 dBFS から +19 dB 上方
    "rms_dbfs_tolerance": 6.0,              # ± 6 dB tolerance
}

# Mixer 構造 6 levers (= ADR-0042 §決定 2 採用案 A literal、 Codex layer 2 採用済)
MIXER_LEVERS: list[str] = [
    "a_level_o1",   # OSC1 mixer level (= body 主)
    "a_level_o2",   # OSC2 mixer level (= harmonic)
    "a_level_o3",   # OSC3 mixer level (= optional)
    "a_level_noise",  # Noise mixer level (= click、 ADR-0042 §決定 2 literal 整合)
    "a_volume",     # Scene volume
    "volume",       # Master volume
]

# 退避 4 artifact reference (= read-only forensic、 ADR-0033 §π15.14 § 10.3 規律)
DEFAULT_PATCH_SPEC = "/private/tmp/pmdneo-plan-a-rejected/2608_bd-plan-a.patch-spec.yaml"


def load_patch_spec_readonly(path: Path) -> dict[str, Any]:
    """退避 patch-spec.yaml read-only 読み込み (= reference only、 上書き永久禁止)"""
    if not path.exists():
        print(f"[WARN] patch-spec not found: {path}", file=sys.stderr)
        print(f"[INFO] 退避 4 artifact は ADR-0033 §π15.14 § 10.3 read-only forensic、 不在時は stub reference 使用", file=sys.stderr)
        return {
            "raw": "",
            "path": str(path),
            "available": False,
            "stub": True,
        }
    text = path.read_text()
    return {
        "raw": text[:500],  # head 500 byte 抜粋 (= reference 用、 全文は parse 不要)
        "path": str(path),
        "available": True,
        "byte_size": len(text),
    }


def individual_sweep_design(
    lever: str,
    sweep_range: list[int],
    base_patch: dict[str, Any],
) -> list[dict[str, Any]]:
    """individual sweep = 1 lever ずつ sweep 値変化、 他 lever は ベース patch 維持"""
    candidates: list[dict[str, Any]] = []
    for value in sweep_range:
        candidates.append({
            "lever": lever,
            "value": value,
            "base_patch_ref": base_patch["path"],
            "base_patch_available": base_patch["available"],
            "other_levers": "preserved (= base patch 維持)",
        })
    return candidates


def engineering_gate_check(analysis: dict[str, float]) -> tuple[bool, list[str]]:
    """layer 1 audible-level engineering gate hard gate"""
    failures: list[str] = []
    peak = analysis.get("peak_dbfs", -100.0)
    peak_range = LAYER1_GATE["peak_dbfs_range"]
    if not (peak_range[0] <= peak <= peak_range[1]):
        failures.append(f"peak_dbfs {peak:.2f} not in {peak_range}")
    clipping = analysis.get("clipping_count", 999)
    if clipping > LAYER1_GATE["clipping_count_max"]:
        failures.append(f"clipping_count {clipping} > {LAYER1_GATE['clipping_count_max']} (= hard gate)")
    rms = analysis.get("rms_dbfs", -100.0)
    rms_target = LAYER1_GATE["rms_dbfs_target"]
    rms_tol = LAYER1_GATE["rms_dbfs_tolerance"]
    if not (rms_target - rms_tol <= rms <= rms_target + rms_tol):
        failures.append(f"rms_dbfs {rms:.2f} not in {rms_target} ± {rms_tol}")
    return len(failures) == 0, failures


def dry_run_analysis(candidate: dict[str, Any]) -> dict[str, float]:
    """dry-run mode = render skip、 stub analysis output (= 設計妥当性確認用)

    実環境 render (= Surge XT 等) は別 step で実装、 本 dry-run は spike 設計 + 規律遵守の機械検査のみ。
    """
    # stub: sweep 値に応じた線形応答 (= 設計確認用、 実 audio rendering ではない)
    value = candidate["value"]
    # 簡易応答 model (= sweep value 0-127 範囲を peak -30 〜 0 dBFS に線形 mapping、 完全 stub)
    stub_peak = -30.0 + (value / 127.0) * 27.0  # 0 → -30, 127 → -3 dBFS
    stub_rms = stub_peak - 9.0  # 簡易 -9 dB offset
    stub_clipping = 1 if stub_peak > -1.0 else 0  # -1 dBFS 超で clipping stub
    return {
        "peak_dbfs": stub_peak,
        "clipping_count": stub_clipping,
        "rms_dbfs": stub_rms,
        "dry_run": True,
    }


def cascade_verify_stub(passed_candidates: list[dict[str, Any]]) -> dict[str, Any]:
    """最小 cascade verify (= individual sweep PASS 候補集約時の cascade 時 sum check)"""
    if not passed_candidates:
        return {"cascade_executable": False, "reason": "no individual sweep PASS candidate"}
    # cascade stub: 単純 sum (= 実際は non-linear cascade で別 step が正確)
    total_value = sum(c["candidate"]["value"] for c in passed_candidates)
    return {
        "cascade_executable": True,
        "passed_count": len(passed_candidates),
        "total_sweep_value_sum": total_value,
        "note": "actual cascade non-linear (= waveshaper drive / filter envmod)、 dry-run stub のみ",
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="軸 A β-2 audible-level-sweep-spike (= ADR-0042 §決定 5、 individual sweep + clipping gate)",
        epilog="aesthetic 判定は越川氏 audition (= layer 2)、 本 spike は engineering gate のみ",
    )
    parser.add_argument(
        "--patch-spec", type=Path, default=Path(DEFAULT_PATCH_SPEC),
        help=f"ベース patch-spec.yaml (= 退避 4 artifact read-only forensic、 default {DEFAULT_PATCH_SPEC})",
    )
    parser.add_argument(
        "--lever", default="a_volume",
        help=f"sweep 対象 lever (= MIXER_LEVERS から選択: {MIXER_LEVERS})",
    )
    parser.add_argument(
        "--sweep-range", default="20,40,60,80,100,120",
        help="sweep 値 list (= comma-separated int 0-127)",
    )
    parser.add_argument(
        "--execute", action="store_true",
        help="actual render mode (= 環境依存、 Surge XT 必要、 本 commit 未実装 stub)",
    )
    args = parser.parse_args()

    if args.lever not in MIXER_LEVERS:
        sys.exit(f"[ERROR] lever must be one of {MIXER_LEVERS}")

    if args.execute:
        sys.exit("[ERROR] --execute mode 未実装 (= Surge XT render 環境依存、 別 step で実装、 ADR-0042 §β-3 candidate)")

    try:
        sweep_range = [int(v) for v in args.sweep_range.split(",")]
    except ValueError as e:
        sys.exit(f"[ERROR] sweep-range parse error: {e}")

    # 退避 patch-spec 読み込み (= read-only forensic、 上書き永久禁止)
    base_patch = load_patch_spec_readonly(args.patch_spec)

    # individual sweep 設計 (= 1 lever ずつ、 他 lever 維持)
    candidates = individual_sweep_design(args.lever, sweep_range, base_patch)

    # 各 candidate analysis (= dry-run stub、 actual render は別 step)
    results: list[dict[str, Any]] = []
    for cand in candidates:
        analysis = dry_run_analysis(cand)
        passed, failures = engineering_gate_check(analysis)
        results.append({
            "candidate": cand,
            "analysis": analysis,
            "passed": passed,
            "failures": failures,
        })

    # 最小 cascade verify (= individual sweep PASS 候補集約)
    passed_results = [r for r in results if r["passed"]]
    cascade = cascade_verify_stub(passed_results)

    # analysis trace literal output
    output = {
        "spec_version": "0.1",
        "scope": "ADR-0042 §決定 5 β-2 = 軸 A 専用 spike audible-level-sweep individual sweep + clipping gate",
        "mode": "dry-run (= render skip、 設計妥当性 + engineering gate stub)",
        "lever": args.lever,
        "sweep_range": sweep_range,
        "base_patch_ref": str(args.patch_spec),
        "base_patch_available": base_patch["available"],
        "layer1_gate": LAYER1_GATE,
        "results": results,
        "individual_sweep_summary": {
            "total_candidates": len(results),
            "passed": sum(1 for r in results if r["passed"]),
            "failed": sum(1 for r in results if not r["passed"]),
        },
        "cascade_verify": cascade,
        "scope_out": [
            "aesthetic 判定 (= 越川氏 layer 2 audition、 永久 user scope)",
            "退避 4 artifact 上書き / 削除 / 修正 / normalize (= read-only forensic)",
            "repo 投入 (= 全 output /tmp 配置)",
            "normalize / loudness normalize / wav 段階 gain (= 越川氏 directive 永久禁止)",
            "--execute mode actual render (= 環境依存、 別 step ADR-0042 §β-3 candidate)",
        ],
    }
    print(json.dumps(output, indent=2, ensure_ascii=False))

    # exit code (= layer 1 gate fail でも spike script 自体は OK = exit 0、 fail は results 内 literal)
    return 0


if __name__ == "__main__":
    sys.exit(main())
