#!/usr/bin/env python3
"""axis-b-v2-entry-spike.py - 軸 B sub-sprint γ proof spike (= 37th session、 target (c) v2 entry skeleton + 1 register write)

ADR-0045 Annex G G-3-1 target (c) per 37th session γ:
- target (c) = v2 entry routine skeleton + 1 register write
- Codex layer 2 round 1 approve (= 評価軸 8 件 全 PASS、 主軸推奨理由 4 件 因果整合確認、
  must-fix 0 件 + nice-to-have 1 件 (= γ 段 Annex H 記録) + 規律違反 risk 0 件)
- β retrospective review = confirm (= fallback approve 妥当、 PR #53 MERGED ba822cd)

scope (= γ proof spike literal):
- Python standard library only (= argparse / json / sys / dataclasses / typing の標準 module のみ)
- v2 entry routine skeleton (= pmdneo_v2_fm_main 仮称) の期待 register trace を emit
- 1 register write (= FM ch1 op1 TL register、 register address 0x40 on port A)
- register trace primary gate (= 期待 register write byte sequence 比較可能性 literal)
- driver / runtime / compiler / vendor / vromtool.py 完全不変

verify (= γ register trace primary gate):
- v2 entry routine が 1 register write を期待 port (= 0x04 = YM2610 port A address)
  + 期待 addr (= 0x40 = FM op1 TL of ch1) + 期待 value (= part_ctx 入力値) で emit するか
- port routing rule (= ch < 3 → port A 0x04 / ch >= 3 → port B 0x06、 YM2610B 6ch 対応)
- byte count (= 1 register write = 2 port writes = addr + value)

scope-out (= γ scope literal):
- 実 driver Z80 source への 反映 (= δ integration 段以降)
- FM 6ch 全 dispatch (= δ で sub-axis 分解時に拡張)
- SSG 3ch dispatch (= δ で別 entry skeleton として追加)
- F-2-B ch3 4-op individual mode (= δ で integration)
- 軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm dispatch 接続点 (= δ で literal)
- 既存 driver behavior との実 byte-identical 比較 (= 実 driver 実装後の verify gate)

ground truth reference (= 軸 B α Annex B + D-3-a literal):
- vendor/PMDDotNET/PMDDotNETDriver/PMD.cs L1216 fmmain() (= ground truth)
- vendor/PMDDotNET/PMDDotNETDriver/PMD.cs L3079-3084 TL register write (= 0x40 - 1 + part offset)
- src/driver/standalone_test.s L758 fnumset_fm:
- src/driver/standalone_test.s L1063 pmdneo_fm_voice_set:
- src/driver/standalone_test.s L1001 pmdneo_fm_write_reg_ch:
- src/driver/PMD_Z80.inc L1266 fmmain:: (= legacy core entry、 軸 B 不可触保護)

使い方:
  python3 scripts/axis-b-v2-entry-spike.py            # default = self-test + emit
  python3 scripts/axis-b-v2-entry-spike.py --json     # JSON output
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, asdict
from typing import Any


# =============================================================================
# YM2610 / YM2610B chip register constant (= ADR-0045 Annex D + ngdevkit ports.inc)
# =============================================================================

# Z80 port address for YM2610 chip
PORT_YM2610_A0 = 0x04   # port A register address
PORT_YM2610_A1 = 0x05   # port A register data
PORT_YM2610_B0 = 0x06   # port B register address
PORT_YM2610_B1 = 0x07   # port B register data

# FM register: TL (Total Level) for operator
# YM2610 FM register layout (= per chip datasheet、 1 port = 3 ch × 4 op = 12 TL register):
#   0x40-0x42: TL for op1 of ch1/ch2/ch3 (= port A side)
#   0x44-0x46: TL for op2 of ch1/ch2/ch3
#   0x48-0x4A: TL for op3 of ch1/ch2/ch3
#   0x4C-0x4E: TL for op4 of ch1/ch2/ch3
#   (= 0x43 / 0x47 / 0x4B / 0x4F は未定義、 4 byte alignment 慣習で skip)
# Port A handles ch1-3、 Port B handles ch4-6 (= YM2610B、 same layout offset、 1 port 3 ch ずつ)
FM_TL_BASE = 0x40

# Part constant (= standalone_test.s L99 + WORKAREA.inc L14-30)
PART_FM1 = 0  # A、 chip ch1 (port A side)
PART_FM2 = 1  # B、 chip ch2 (port A side)
PART_FM3 = 2  # C、 chip ch3 (port A side)
PART_FM4 = 3  # D、 chip ch4 (port B side、 YM2610B のみ active)
PART_FM5 = 4  # E、 chip ch5 (port B side)
PART_FM6 = 5  # F、 chip ch6 (port B side)


# =============================================================================
# v2 entry routine skeleton data structures
# =============================================================================

@dataclass(frozen=True)
class RegisterWrite:
    """Single YM2610 register write (= addr port write + data port write 2 step)."""
    port_addr: int   # 0x04 (A0) or 0x06 (B0)
    port_data: int   # 0x05 (A1) or 0x07 (B1)
    reg_addr: int    # register address within port-A or port-B space (0x00-0xFF)
    reg_value: int   # 8-bit data value


@dataclass(frozen=True)
class PartCtx:
    """Part context input for v2 entry routine (= per-part workarea 抽象表現)."""
    part: int    # PART_FM1-6 (= 0-5)
    op: int      # operator index 0-3 (= op1-op4)
    tl: int      # TL value 0x00-0x7F (= 7-bit TL field)


# =============================================================================
# v2 entry routine skeleton (= ADR-0045 G-2-1 boundary)
# =============================================================================

def pmdneo_v2_fm_main_skeleton(part_ctx: PartCtx) -> list[RegisterWrite]:
    """軸 B Phase 2 fullscratch driver FM dispatch entry skeleton (= ADR-0045 G-2-1)。

    本 spike では γ proof として、 part context 1 件から 1 register write を emit する
    skeleton の boundary contract を Python で proof する。 実 Z80 driver 実装は δ 以降。

    boundary contract:
    - 入力: PartCtx (= part / op / tl 構造体、 per-part workarea から取得想定)
    - 出力: list[RegisterWrite] (= 1 register write entry、 chip 駆動に変換可能)
    - 副作用: なし (= pure function、 driver source touch なし)

    routing rule:
    - ch < 3 (= PART_FM1/2/3 = A/B/C) → port A (0x04 addr / 0x05 data)
    - ch >= 3 (= PART_FM4/5/6 = D/E/F) → port B (0x06 addr / 0x07 data)

    register address computation:
    - TL register addr = FM_TL_BASE (= 0x40) + (op * 4) + (ch_in_port)
    - ch_in_port = part % 3 (= 0/1/2 for either port A or port B side)

    Args:
        part_ctx: PartCtx (= 1 件 part 入力)

    Returns:
        list of RegisterWrite (= 期待 register trace、 本 spike では len == 1)
    """
    ch = part_ctx.part  # part 番号 = chip ch 番号 (= ADR-0006 §A 規約)

    # Step 1: Port routing (= ch < 3 → port A、 ch >= 3 → port B)
    if ch < 3:
        port_addr = PORT_YM2610_A0
        port_data = PORT_YM2610_A1
    else:
        port_addr = PORT_YM2610_B0
        port_data = PORT_YM2610_B1

    # Step 2: Register address computation
    # ch_in_port = 0/1/2 within port A or port B side
    ch_in_port = ch % 3
    reg_addr = FM_TL_BASE + (part_ctx.op * 4) + ch_in_port

    # Step 3: Emit 1 register write
    return [RegisterWrite(
        port_addr=port_addr,
        port_data=port_data,
        reg_addr=reg_addr,
        reg_value=part_ctx.tl,
    )]


# =============================================================================
# γ register trace primary gate (= ADR-0045 G-2-1 verify)
# =============================================================================

# Expected register trace for FM ch1 op1 TL = 0x14 (= primary gate fixture)
EXPECTED_TRACE_CH1_OP1_TL = [
    RegisterWrite(
        port_addr=PORT_YM2610_A0,  # 0x04
        port_data=PORT_YM2610_A1,  # 0x05
        reg_addr=FM_TL_BASE + 0,    # 0x40 (op1, ch1)
        reg_value=0x14,
    ),
]

# Expected register trace for FM ch4 op1 TL = 0x20 (= port B routing proof)
EXPECTED_TRACE_CH4_OP1_TL = [
    RegisterWrite(
        port_addr=PORT_YM2610_B0,  # 0x06
        port_data=PORT_YM2610_B1,  # 0x07
        reg_addr=FM_TL_BASE + 0,    # 0x40 (op1, ch4 = ch_in_port 0)
        reg_value=0x20,
    ),
]

# Expected register trace for FM ch3 op2 TL = 0x30 (= ch_in_port = 2、 op = 1)
EXPECTED_TRACE_CH3_OP2_TL = [
    RegisterWrite(
        port_addr=PORT_YM2610_A0,  # 0x04 (ch3 = port A side)
        port_data=PORT_YM2610_A1,  # 0x05
        reg_addr=FM_TL_BASE + 4 + 2,  # 0x46 (op2 = +4 offset、 ch3 = +2)
        reg_value=0x30,
    ),
]

# Z80 instruction byte count (= register trace primary gate metric)
# 1 register write = 2 port writes (= OUT (port_addr), reg_addr + OUT (port_data), reg_value)
# Each Z80 "OUT (n), A" instruction = 2 bytes (= opcode 0xD3 + immediate)
# Plus LD A, <value> for setup = 2 bytes each
# Total per register write = 4 + 4 = 8 bytes (粗い見積もり、 実 codegen 依存)
# 本 spike では count を register write 件数 = 1 で確認
EXPECTED_REGISTER_WRITE_COUNT = 1


def self_test() -> bool:
    """γ register trace primary gate self-test (= 3 fixture verify)."""
    results: list[dict[str, Any]] = []
    all_pass = True

    # Test 1: FM ch1 op1 TL = 0x14 (= port A side, ch_in_port = 0, op = 0)
    ctx1 = PartCtx(part=PART_FM1, op=0, tl=0x14)
    trace1 = pmdneo_v2_fm_main_skeleton(ctx1)
    pass1 = trace1 == EXPECTED_TRACE_CH1_OP1_TL
    results.append({
        "test": "ch1_op1_tl_14",
        "input": asdict(ctx1),
        "expected": [asdict(w) for w in EXPECTED_TRACE_CH1_OP1_TL],
        "actual": [asdict(w) for w in trace1],
        "register_write_count": len(trace1),
        "pass": pass1,
    })
    all_pass = all_pass and pass1

    # Test 2: FM ch4 op1 TL = 0x20 (= port B side, ch_in_port = 0, op = 0)
    ctx2 = PartCtx(part=PART_FM4, op=0, tl=0x20)
    trace2 = pmdneo_v2_fm_main_skeleton(ctx2)
    pass2 = trace2 == EXPECTED_TRACE_CH4_OP1_TL
    results.append({
        "test": "ch4_op1_tl_20",
        "input": asdict(ctx2),
        "expected": [asdict(w) for w in EXPECTED_TRACE_CH4_OP1_TL],
        "actual": [asdict(w) for w in trace2],
        "register_write_count": len(trace2),
        "pass": pass2,
    })
    all_pass = all_pass and pass2

    # Test 3: FM ch3 op2 TL = 0x30 (= port A side, ch_in_port = 2, op = 1)
    ctx3 = PartCtx(part=PART_FM3, op=1, tl=0x30)
    trace3 = pmdneo_v2_fm_main_skeleton(ctx3)
    pass3 = trace3 == EXPECTED_TRACE_CH3_OP2_TL
    results.append({
        "test": "ch3_op2_tl_30",
        "input": asdict(ctx3),
        "expected": [asdict(w) for w in EXPECTED_TRACE_CH3_OP2_TL],
        "actual": [asdict(w) for w in trace3],
        "register_write_count": len(trace3),
        "pass": pass3,
    })
    all_pass = all_pass and pass3

    # Test 4: register write count = 1 invariant (= primary gate count metric)
    count_invariant_pass = all(r["register_write_count"] == EXPECTED_REGISTER_WRITE_COUNT for r in results)
    results.append({
        "test": "register_write_count_invariant",
        "expected": EXPECTED_REGISTER_WRITE_COUNT,
        "actual": [r["register_write_count"] for r in results[:3]],
        "pass": count_invariant_pass,
    })
    all_pass = all_pass and count_invariant_pass

    return all_pass, results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="JSON output for self-test results")
    args = parser.parse_args()

    all_pass, results = self_test()

    if args.json:
        print(json.dumps({
            "spike": "axis-b-v2-entry-spike",
            "target": "(c) v2 entry skeleton + 1 register write",
            "tests": results,
            "all_pass": all_pass,
        }, indent=2))
    else:
        print("=== 軸 B sub-sprint γ proof spike (= target (c) v2 entry skeleton + 1 register write) ===")
        print()
        print("ADR-0045 Annex G G-3-1 target (c) per 37th session γ.")
        print("Python standard library only. driver source touch なし。")
        print()
        for r in results:
            status = "PASS" if r["pass"] else "FAIL"
            print(f"[{status}] {r['test']}")
            if not r["pass"]:
                print(f"  expected: {r.get('expected')}")
                print(f"  actual:   {r.get('actual')}")
        print()
        if all_pass:
            print("=== γ proof spike: ALL PASS ===")
        else:
            print("=== γ proof spike: FAIL ===")

    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(main())
