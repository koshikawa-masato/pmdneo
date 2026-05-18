#!/usr/bin/env python3
"""PMDNEO IR Tempo -> FMTimerSet lowering spike (= v0.2/v0.3 semantic Tempo -> v0.3 chip FMTimerSet、 ADR-0037 / 27th session γ).

v0.2 または v0.3 IR JSON file を入力に、 driver start 時の initial Tempo (= `(tick, trackId, order)` 昇順 sort 後の最初に出現する Tempo event、 通常 tick=0/trackId=0/order=0 想定だが固定ではない) を chip 層 FMTimerSet (= TIMER-B counter 設定) に lowering した v0.3 IR JSON を出力する read-only spike。 compiler 本体ではなく、 「Tempo semantic から FMTimerSet chip 層に落ちる最小の道がある」 ことの proof。

## lowering rule (= ADR-0037 §決定 1-3 + §決定 6)

| 入力 event | 出力 |
|---|---|
| **initial Tempo (semantic) 1 件のみ** (= sort 後の最初に出現する Tempo) | `FMTimerSet` (chip) 1 件 (= 同 tick、 同 trackId、 counter=128 placeholder + bpm 保持) |
| 上記以外の `Tempo` (semantic) | pass-through (= runtime tempo 変更は ADR-0037 §決定 3-4 で driver runtime 軸 sub-tick accumulator に委譲、 chip 化は defer) |
| 他全 event (= Note/Rest/ToneSelect/FMToneLoad/FMFrequency/KeyOn/KeyOff/ADPCMATrigger/RawRegisterWrite) | pass-through (= allocator で order 再採番) |

**initial Tempo の定義**: 入力 IR を `(tick, trackId, order)` 昇順 sort 後、 最初に出現する Tempo (semantic) 1 件。 通常 driver start = tick=0 + trackId=0 + order=0 想定。

## counter 値 placeholder (= ADR-0037 §決定 3 = 数値 literal defer)

ADR-0037 §決定 3 で「BPM → TIMER-B counter 変換式の数値 literal は driver runtime 軸 (= ADR-0036 関連別 ADR) 同期後に schema/spike 段階で確定」 と defer 規律。 本 spike は **counter = 128 (= 中庸 placeholder)** を使い、 source `bpm` を traceability で保持。 production 用 literal 化は driver runtime 軸 fix 後の別 sprint。

placeholder 採用理由:
- spike の目的は「lowering の道がある」 proof で、 counter 値の正確性は scope-out
- counter=128 = 中庸 8-bit 値、 BPM 紐付け文脈なしで誤認 risk 最小

## 入力 sort 規律 (= 26th session β/26 β/27 β spike 踏襲)

入力 events 配列の array 順は **not authoritative** = IR の `(tick, trackId, order)` フィールドが semantic 真の順序。 lower_events() は処理前に `(tick, trackId, order)` で sort し直す。 同一 (tick, trackId, order) 重複は sort 前に exit 65 reject。

## timing 制約

`timing.timeMode` は `"absolute"` のみ受け付ける (= "delta" は exit 65 reject)。

## scope-out

- BPM → counter 変換 literal (= ADR-0037 §決定 3 defer)
- runtime tempo 変更の chip 化 (= ADR-0037 §決定 3 で sub-tick accumulator 委譲)
- 0x27 register bit 操作 (= ADR-0037 §決定 4 で bit 6 非破壊規律のみ、 他 defer)
- raw register write 展開 (= 26th session β spike の chain 側)
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp / FM3Mode / SSG / pitch correction / aesthetic
- vendor 不可触

## exit codes (= 既存 spike と同)

  0  = OK
  64 = argument error (= input not found / JSON parse / required field missing)
  65 = lowering parse error (= timeMode delta / 重複 / 必須 field 欠落 / Tempo bpm 欠落 等)
  66 = runtime error (= unexpected exception)
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

CREATED_BY = "ir-lower-tempo-spike v0.3 (= 27th session γ、 IR semantic Tempo -> v0.3 chip FMTimerSet lowering、 counter placeholder 128)"

# ADR-0037 §決定 3 = counter 数値 literal は defer、 spike は中庸 placeholder
COUNTER_PLACEHOLDER = 128


class _OrderAllocator:
    """Output event の tick 内 order を 0 から連番で発行する。"""

    def __init__(self) -> None:
        self._counter: dict[int, int] = {}

    def next(self, tick: int) -> int:
        n = self._counter.get(tick, 0)
        self._counter[tick] = n + 1
        return n


def lower_events(input_events: list[dict]) -> tuple[list[dict], dict]:
    """v0.2/v0.3 IR events -> v0.3 IR events lowering (= initial Tempo を FMTimerSet 化、 他は pass-through)。

    Returns:
        (output_events, stats) — stats は report 用 dict。
    """
    allocator = _OrderAllocator()
    output: list[dict] = []
    stats = {
        "input_total": len(input_events),
        "tempo_lowered_to_fmtimerset": 0,
        "tempo_passthrough_runtime": 0,
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
                f"duplicate (tick, trackId, order) = {key}: "
                f"既存 {seen_keys[key]} vs 新 {ev}。 "
                f"重複を許すと Python stable sort 経由で input array 順が silently authoritative 化する。"
            )
        seen_keys[key] = ev

    sorted_input = sorted(
        input_events, key=lambda e: (e["tick"], e.get("trackId", 0), e["order"])
    )

    initial_tempo_lowered = False

    for ev in sorted_input:
        tick = ev["tick"]
        layer = ev["layer"]
        type_ = ev["type"]
        track_id = ev.get("trackId", 0)

        is_tempo = layer == "semantic" and type_ == "Tempo"

        if is_tempo and not initial_tempo_lowered:
            bpm = ev.get("bpm")
            if bpm is None:
                raise ValueError(f"Tempo event missing bpm field: {ev}")
            if type(bpm) not in (int, float) or bpm <= 0:
                raise ValueError(
                    f"Tempo bpm must be positive number (= v0.3 schema exclusiveMinimum 0 整合): {bpm!r}"
                )
            order = allocator.next(tick)
            output.append(
                {
                    "tick": tick,
                    "order": order,
                    "trackId": track_id,
                    "layer": "chip",
                    "type": "FMTimerSet",
                    "counter": COUNTER_PLACEHOLDER,
                    "bpm": bpm,
                }
            )
            initial_tempo_lowered = True
            stats["tempo_lowered_to_fmtimerset"] += 1
            continue

        if is_tempo:
            order = allocator.next(tick)
            output.append({**ev, "order": order})
            stats["tempo_passthrough_runtime"] += 1
            continue

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
    if "tones" in input_ir:
        out["tones"] = input_ir["tones"]
    if "sampleRefs" in input_ir:
        out["sampleRefs"] = input_ir["sampleRefs"]
    if "diagnostics" in input_ir:
        out["diagnostics"] = input_ir["diagnostics"]
    return out


def main() -> int:
    parser = argparse.ArgumentParser(
        description="PMDNEO IR Tempo -> FMTimerSet lowering spike (= initial Tempo を v0.3 chip FMTimerSet 化、 ADR-0037 / 27th session γ)",
    )
    parser.add_argument("input", type=Path, help="input IR v0.2/v0.3 JSON file path")
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="output JSON file path (default: stdout)",
    )
    parser.add_argument(
        "--stats",
        action="store_true",
        help="lowering 統計を stderr に表示する",
    )
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
            print(
                f"[FAIL] input IR missing required field: {required}", file=sys.stderr
            )
            return EXIT_ARG

    time_mode = input_ir["timing"].get("timeMode", "absolute")
    if time_mode != "absolute":
        print(
            f"[FAIL] lowering error: timing.timeMode = {time_mode!r} は spike scope 外 "
            f"(= absolute tick のみ対応、 silent timing 破壊 防止)。",
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
            f"[OK] lowered {stats['input_total']} events -> {len(lowered)} events: {args.output}",
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
        print(
            f"[FAIL] unexpected error: {type(e).__name__}: {e}",
            file=sys.stderr,
        )
        sys.exit(EXIT_RUNTIME)
