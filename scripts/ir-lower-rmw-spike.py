#!/usr/bin/env python3
"""PMDNEO IR RawRegisterMaskWrite raw-to-raw identity + validation spike (= ADR-0039 §決定 8 / 29th session γ).

v0.5 IR JSON file を入力に、 RawRegisterMaskWrite event + 全 event を raw-to-raw identity で pass-through する spike。 ADR-0039 §決定 6 で FM3Mode raw lowering 実装は別 ADR-0040 候補と分離されており、 本 spike は RMW event 単体の validation + pass-through chain の proof。

「RawRegisterMaskWrite が schema + spike 両 layer で validation 可能 + raw-to-raw identity で下流に流せる」 ことの proof。 compiler 本体 / WebApp / runtime / driver / `.mn` / `.PNE` は touch しない。 既存 ADR-0035 raw spike (= chip → raw lowering) には touch せず、 新規独立 spike (= ADR-0039 §決定 8 で α 時点 fix)。

## scope (= ADR-0039 §決定 8 + §scope-out)

- 入力 v0.5 IR を sort + 重複 reject + timeMode check
- 全 event を raw-to-raw identity pass-through (= output allocator 経由 order 再採番のみ)
- RawRegisterMaskWrite 固有 defense in depth (= port 0-1 / address 0-255 / mask 1-255 / value 0-255 / 必須 field / 型厳密)
- 出力を (tick, order) sort 正規化

## scope-out (= ADR-0039 §scope-out)

- FM3Mode → RawRegisterMaskWrite 生成 (= ADR-0040 候補別 ADR、 chip → raw lowering 実装軸)
- 既存 RawRegisterWrite の RMW 化 (= 既存 event touch なし)
- driver runtime 実 RMW 実行 (= driver code 側責務、 IR は expression 保持のみ)
- optimization layer (= 同 address 連続 RMW merge)
- 既存 ADR-0035 raw spike chain (= chip → raw lowering) と分離、 既存 spike touch なし
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp / aesthetic

## exit codes (= 既存 spike と同)

  0  = OK
  64 = argument error
  65 = lowering parse error (= timeMode delta / 重複 / 必須 field 欠落 / RawRegisterMaskWrite 固有 validation 違反)
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

CREATED_BY = "ir-lower-rmw-spike v0.5 (= 29th session γ、 IR RawRegisterMaskWrite raw-to-raw identity + validation、 ADR-0040 候補別 ADR で chip → raw lowering 実装 defer)"


class _OrderAllocator:
    def __init__(self) -> None:
        self._counter: dict[int, int] = {}

    def next(self, tick: int) -> int:
        n = self._counter.get(tick, 0)
        self._counter[tick] = n + 1
        return n


def _validate_rmw(ev: dict) -> None:
    """RawRegisterMaskWrite 固有 defense in depth validation (= ADR-0039 §決定 3-4 + §決定 8)."""
    for k in ("port", "address", "mask", "value", "trackId"):
        if k not in ev:
            raise ValueError(f"RawRegisterMaskWrite event missing required field {k!r}: {ev}")
    port = ev["port"]
    if type(port) is not int or not (0 <= port <= 1):
        raise ValueError(f"RawRegisterMaskWrite.port must be int 0-1: {port!r}")
    address = ev["address"]
    if type(address) is not int or not (0 <= address <= 255):
        raise ValueError(f"RawRegisterMaskWrite.address must be int 0-255: {address!r}")
    mask = ev["mask"]
    if type(mask) is not int or not (1 <= mask <= 255):
        raise ValueError(
            f"RawRegisterMaskWrite.mask must be int 1-255 (= ADR-0035 §決定 6 規律踏襲、 no-op 防止): {mask!r}"
        )
    value = ev["value"]
    if type(value) is not int or not (0 <= value <= 255):
        raise ValueError(f"RawRegisterMaskWrite.value must be int 0-255: {value!r}")
    if "barrier" in ev and type(ev["barrier"]) is not bool:
        raise ValueError(
            f"RawRegisterMaskWrite.barrier must be boolean: {ev['barrier']!r}"
        )


def lower_events(input_events: list[dict]) -> tuple[list[dict], dict]:
    """v0.5 IR events を raw-to-raw identity で pass-through (= RawRegisterMaskWrite 固有 validation 込み)。"""
    allocator = _OrderAllocator()
    output: list[dict] = []
    stats = {
        "input_total": len(input_events),
        "rmw_validated": 0,
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
        is_rmw = ev.get("layer") == "raw" and ev.get("type") == "RawRegisterMaskWrite"
        if is_rmw:
            _validate_rmw(ev)
            stats["rmw_validated"] += 1
        else:
            stats["other_passthrough"] += 1
        order = allocator.next(tick)
        output.append({**ev, "order": order})

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
        description="PMDNEO IR RawRegisterMaskWrite raw-to-raw identity + validation spike (= ADR-0039 §決定 8 / 29th session γ)",
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
