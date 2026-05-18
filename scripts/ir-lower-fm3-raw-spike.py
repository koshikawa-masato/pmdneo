#!/usr/bin/env python3
"""PMDNEO IR FM3Mode chip event → raw lowering spike (= ADR-0040 §決定 2/3/5/6/7 / 30th session γ).

v0.5 IR JSON file を入力に、 FM3Mode chip event を ADR-0039 §決定 6 接続条件 (= ADR-0040 §決定 2/3 で実装軸として展開) に従って `RawRegisterMaskWrite` + `RawRegisterWrite` 列に lowering する spike。 他 event は raw-to-raw / chip-to-chip / semantic-to-semantic identity pass-through。

ADR-0038 §決定 5 で defer された FM3Mode raw lowering を ADR-0040 で defer 解消した実装軸。 ADR-0039 で v0.5 schema に追加された `RawRegisterMaskWrite` event を 0x27 bit 6 partial bit update に使い、 operator-split FNUM/Block は既存 `RawRegisterWrite` literal で書き出す。

## scope (= ADR-0040 §決定 2/3/5/6/7 + §scope-out)

- 入力 v0.5 IR を sort + 重複 (tick, trackId, order) reject + timeMode check
- FM3Mode chip event を lowering (= enabled=true → 9 events / enabled=false → 1 event)
- 他 event は識別 pass-through (= raw / chip / semantic 全 layer 不問)
- FM3Mode 固有 defense in depth (= operatorBlock 各 0-7 / operatorFnum 各 0-2047 / array length 4 / keyPolicy enum / 必須 field / 型厳密 = type(x) is int / type(x) is bool)
- 出力を (tick, order) sort 正規化

## scope-out (= ADR-0040 §scope-out)

- 0x28 KeyOn 自動挿入 / keyPolicy 解釈 (= 既存 KeyOn lowering 経路に残す)
- mode 切替直前 KeyOff 自動挿入 / diagnostics (= ADR-0038 §決定 5-2 別 sprint defer)
- driver runtime 実 shadow register RMW 実行 (= driver code 側責務、 IR は expression 保持のみ)
- optimization layer (= 同 address 連続 RMW merge / FM3Mode 連続重複削減)
- 既存 ADR-0035 raw spike / ADR-0038 fm3 chip spike / ADR-0039 RMW spike chain は touch なし、 新規独立 spike (= ADR-0040 §決定 7 で α 時点 fix)
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp / aesthetic

## ADR-0040 §決定 5 operator-split register mapping (= literal、 ground truth = PMD V4.8s + PMDDotNET + YM2608 Application Manual Table 2-2)

| operator (IR) | slot (datasheet) | low byte register | high byte register |
|---|---|---:|---:|
| op1 = operatorBlock[0] / operatorFnum[0] | S1 | 0xA9 | 0xAD |
| op2 = operatorBlock[1] / operatorFnum[1] | S3 | 0xAA | 0xAE |
| op3 = operatorBlock[2] / operatorFnum[2] | S2 | 0xA8 | 0xAC |
| op4 = operatorBlock[3] / operatorFnum[3] | S4 | 0xA2 | 0xA6 |

operator IR index と datasheet slot 番号は **非直線対応** (= ADR-0035 §決定 8 operator parameter slot order 踏襲、 PMD/MewFM/ymfm/fmgen 慣習)。

## ADR-0040 §決定 6 emit 順序 invariant

1. RawRegisterMaskWrite(port=0, address=0x27, mask=0x40, value=0x40 or 0x00) (= 0x27 bit 6 制御、 先頭)
2. (enabled=true 時のみ) op1 → op2 → op3 → op4 順、 各 operator pair 内 high → low

byte encoding (= ADR-0035 §決定 5 同形式):
- high byte: `(block << 3) | (fnum >> 8)`
- low byte: `fnum & 0xFF`

## exit codes (= 既存 spike と同)

  0  = OK
  64 = argument error
  65 = lowering parse error (= timeMode delta / 重複 / 必須 field 欠落 / FM3Mode 固有 validation 違反)
  66 = runtime error
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

EXIT_OK = 0
EXIT_ARG = 64
EXIT_PARSE = 65
EXIT_RUNTIME = 66

CREATED_BY = "ir-lower-fm3-raw-spike v0.5 (= 30th session γ、 IR FM3Mode chip event → raw lowering、 ADR-0040 §決定 2/3/5/6 literal 実装、 ADR-0038 §決定 5 defer 解消 + ADR-0039 §決定 6 接続条件 実装軸)"

# ADR-0040 §決定 5 mapping table (= ground truth = PMD V4.8s PMD.ASM L4413/4446/4479/4512 + PMDDotNET PMD.cs L6486/6526/6566/6605 + YM2608 Application Manual Table 2-2)。
# index = FM3Mode operatorBlock[i] / operatorFnum[i] の i (= IR operator index 0-3 = op1-4)。
# 各 entry = (low_address, high_address)、 port は全て 0 固定 (= ch3 共通 register)。
OPERATOR_FREQ_REGISTERS: list[tuple[int, int]] = [
    (0xA9, 0xAD),  # op1 → S1
    (0xAA, 0xAE),  # op2 → S3
    (0xA8, 0xAC),  # op3 → S2
    (0xA2, 0xA6),  # op4 → S4
]

# ADR-0039 §決定 5 0x27 bit 6 preservation literal。
FM3_MODE_PORT = 0
FM3_MODE_ADDRESS = 0x27
FM3_MODE_MASK = 0x40
FM3_MODE_VALUE_ENABLE = 0x40
FM3_MODE_VALUE_DISABLE = 0x00


class _OrderAllocator:
    def __init__(self) -> None:
        self._counter: dict[int, int] = {}

    def next(self, tick: int) -> int:
        n = self._counter.get(tick, 0)
        self._counter[tick] = n + 1
        return n


def _validate_fm3mode(ev: dict) -> None:
    """FM3Mode 固有 defense in depth validation (= ADR-0038 §決定 3 + ADR-0040 §決定 7、 ir-lower-fm3mode-spike.py 同形式)."""
    for k in ("enabled", "operatorEnableMask", "operatorBlock", "operatorFnum", "trackId"):
        if k not in ev:
            raise ValueError(f"FM3Mode event missing required field {k!r}: {ev}")
    enabled = ev["enabled"]
    if type(enabled) is not bool:
        raise ValueError(f"FM3Mode.enabled must be boolean: {enabled!r}")
    mask = ev["operatorEnableMask"]
    if type(mask) is not int or not (1 <= mask <= 15):
        raise ValueError(
            f"FM3Mode.operatorEnableMask must be int 1-15 (= ADR-0035 §決定 6 規律踏襲、 no-op 防止): {mask!r}"
        )
    block = ev["operatorBlock"]
    if not isinstance(block, list) or len(block) != 4:
        raise ValueError(f"FM3Mode.operatorBlock must be array length 4: {block!r}")
    for i, b in enumerate(block):
        if type(b) is not int or not (0 <= b <= 7):
            raise ValueError(f"FM3Mode.operatorBlock[{i}] must be int 0-7: {b!r}")
    fnum = ev["operatorFnum"]
    if not isinstance(fnum, list) or len(fnum) != 4:
        raise ValueError(f"FM3Mode.operatorFnum must be array length 4: {fnum!r}")
    for i, f in enumerate(fnum):
        if type(f) is not int or not (0 <= f <= 2047):
            raise ValueError(f"FM3Mode.operatorFnum[{i}] must be int 0-2047: {f!r}")
    if "keyPolicy" in ev:
        kp = ev["keyPolicy"]
        if kp not in ("all", "operator_masked"):
            raise ValueError(
                f"FM3Mode.keyPolicy must be 'all' or 'operator_masked': {kp!r}"
            )
    if "channel" in ev:
        raise ValueError(
            f"FM3Mode must NOT have channel field (= ADR-0038 §決定 2: FM ch 3 固定): {ev}"
        )


def _lower_fm3mode(ev: dict, allocator: _OrderAllocator) -> list[dict]:
    """ADR-0040 §決定 2/3/5/6 literal: FM3Mode → RawRegisterMaskWrite + RawRegisterWrite 列。

    enabled=true → 9 events (= RMW + 8 件 operator-split RawRegisterWrite)
    enabled=false → 1 event (= RMW のみ、 operatorBlock/Fnum は emit しない、 ADR-0038 §決定 3 placeholder 整合)
    """
    tick = ev["tick"]
    track_id = ev["trackId"]
    enabled = ev["enabled"]
    block_arr = ev["operatorBlock"]
    fnum_arr = ev["operatorFnum"]

    out: list[dict] = []

    # Step 1: RMW(0x27, mask=0x40, value=0x40 or 0x00) (= ADR-0040 §決定 2/3 + ADR-0039 §決定 5)
    rmw_value = FM3_MODE_VALUE_ENABLE if enabled else FM3_MODE_VALUE_DISABLE
    out.append({
        "tick": tick,
        "order": allocator.next(tick),
        "trackId": track_id,
        "layer": "raw",
        "type": "RawRegisterMaskWrite",
        "port": FM3_MODE_PORT,
        "address": FM3_MODE_ADDRESS,
        "mask": FM3_MODE_MASK,
        "value": rmw_value,
    })

    if not enabled:
        # ADR-0040 §決定 3: enabled=false 時は operator-split を emit しない
        return out

    # Step 2: operator-split RawRegisterWrite 8 件 (= op1 → op2 → op3 → op4 順、 各 pair 内 high → low、 ADR-0040 §決定 5/6)
    for op_idx, (low_addr, high_addr) in enumerate(OPERATOR_FREQ_REGISTERS):
        block_val = block_arr[op_idx]
        fnum_val = fnum_arr[op_idx]
        # high byte (= block + fnum high)
        high_data = ((block_val & 0x07) << 3) | ((fnum_val >> 8) & 0x07)
        out.append({
            "tick": tick,
            "order": allocator.next(tick),
            "trackId": track_id,
            "layer": "raw",
            "type": "RawRegisterWrite",
            "port": FM3_MODE_PORT,
            "address": high_addr,
            "data": high_data,
        })
        # low byte (= fnum low、 latch trigger)
        low_data = fnum_val & 0xFF
        out.append({
            "tick": tick,
            "order": allocator.next(tick),
            "trackId": track_id,
            "layer": "raw",
            "type": "RawRegisterWrite",
            "port": FM3_MODE_PORT,
            "address": low_addr,
            "data": low_data,
        })

    return out


def lower_events(input_events: list[dict]) -> tuple[list[dict], dict]:
    """v0.5 IR events を FM3Mode lowering + 他 pass-through で処理 (= ADR-0040 §決定 7)。"""
    allocator = _OrderAllocator()
    output: list[dict] = []
    stats = {
        "input_total": len(input_events),
        "fm3mode_enable_lowered": 0,
        "fm3mode_disable_lowered": 0,
        "other_passthrough": 0,
    }

    for ev in input_events:
        if (
            ev.get("tick") is None
            or ev.get("order") is None
            or ev.get("layer") is None
            or ev.get("type") is None
        ):
            raise ValueError(f"event missing required common field: {ev}")

    seen_keys: dict[tuple[int, int, int], dict] = {}
    for ev in input_events:
        key = (ev["tick"], ev.get("trackId", 0), ev["order"])
        if key in seen_keys:
            raise ValueError(
                f"duplicate (tick, trackId, order) = {key}: 既存 {seen_keys[key]} vs 新 {ev}"
            )
        seen_keys[key] = ev

    sorted_input = sorted(
        input_events, key=lambda e: (e["tick"], e.get("trackId", 0), e["order"])
    )

    for ev in sorted_input:
        tick = ev["tick"]
        is_fm3mode = ev.get("layer") == "chip" and ev.get("type") == "FM3Mode"
        if is_fm3mode:
            _validate_fm3mode(ev)
            lowered = _lower_fm3mode(ev, allocator)
            output.extend(lowered)
            if ev["enabled"]:
                stats["fm3mode_enable_lowered"] += 1
            else:
                stats["fm3mode_disable_lowered"] += 1
        else:
            order = allocator.next(tick)
            output.append({**ev, "order": order})
            stats["other_passthrough"] += 1

    output.sort(key=lambda e: (e["tick"], e["order"]))
    return output, stats


def build_output(input_ir: dict, lowered_events: list[dict]) -> dict:
    metadata = dict(input_ir["metadata"])
    original_created_by = metadata.get("createdBy", "<unknown>")
    metadata["createdBy"] = f"{CREATED_BY} (= lowered from: {original_created_by})"

    out: dict = {
        "metadata": metadata,
        "targetProfile": input_ir["targetProfile"],
        "timing": input_ir["timing"],
        "channels": input_ir.get("channels", []),
        "events": lowered_events,
    }
    for k in ("tones", "sampleRefs", "diagnostics"):
        if k in input_ir:
            out[k] = input_ir[k]
    return out


def main() -> int:
    parser = argparse.ArgumentParser(
        description="PMDNEO IR FM3Mode chip event → raw lowering spike (= ADR-0040 §決定 2/3/5/6/7 / 30th session γ)",
    )
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--stats", action="store_true")
    args = parser.parse_args()

    if not args.input.exists():
        print(f"[FAIL] input file not found: {args.input}", file=sys.stderr)
        return EXIT_ARG

    try:
        input_ir = json.loads(args.input.read_text())
    except json.JSONDecodeError as e:
        print(f"[FAIL] JSON parse error in {args.input}: {e}", file=sys.stderr)
        return EXIT_ARG

    for required in ("metadata", "targetProfile", "timing", "events"):
        if required not in input_ir:
            print(f"[FAIL] input IR missing required field: {required}", file=sys.stderr)
            return EXIT_ARG

    time_mode = input_ir["timing"].get("timeMode", "absolute")
    if time_mode != "absolute":
        print(
            f"[FAIL] lowering error: timing.timeMode = {time_mode!r} は spike scope 外 (= absolute tick のみ)。",
            file=sys.stderr,
        )
        return EXIT_PARSE

    try:
        lowered, stats = lower_events(input_ir["events"])
    except ValueError as e:
        print(f"[FAIL] lowering error: {e}", file=sys.stderr)
        return EXIT_PARSE

    output_ir = build_output(input_ir, lowered)
    text = json.dumps(output_ir, indent=2, ensure_ascii=False) + "\n"

    if args.output:
        args.output.write_text(text)
        print(
            f"[OK] processed {stats['input_total']} events -> {len(lowered)} events: {args.output}",
            file=sys.stderr,
        )
    else:
        sys.stdout.write(text)

    if args.stats:
        print("[stats]", file=sys.stderr)
        for k, v in stats.items():
            print(f"  {k}: {v}", file=sys.stderr)
        print(f"  output_total: {len(lowered)}", file=sys.stderr)

    return EXIT_OK


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as e:
        print(f"[FAIL] unexpected error: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(EXIT_RUNTIME)
