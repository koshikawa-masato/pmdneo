#!/usr/bin/env python3
"""PMDNEO IR -> ChipEvent lowering spike (= IR v0.1 SemanticEvent -> v0.2 ChipEvent、 ADR-0034 / 25th session β).

v0.1 IR JSON file を入力に、 SemanticEvent を ChipEvent に lowering した v0.2 IR JSON を出力する read-only spike。 compiler 本体ではなく、 「semantic 層から chip 層に落ちる最小の道がある」 ことの proof。

## lowering rule

| 入力 (= v0.1 SemanticEvent) | 出力 |
|---|---|
| `Tempo` (semantic) | `Tempo` (semantic) として **そのまま保持** |
| `ToneSelect` (semantic, channel.kind=fm) | `FMToneLoad` (chip) 1 件、 同 tick |
| `Note` (semantic, channel.kind=fm) | `FMFrequency` (chip) + `KeyOn` (chip) を同 tick で 2 件、 `KeyOff` (chip) を tick+duration で 1 件、 計 3 件 |
| `Rest` (semantic) | 出力なし (= tick だけ進む、 driver / pipeline 下流で free slot として扱う) |
| `ADPCMATrigger` (chip) | そのまま pass-through |
| `RawRegisterWrite` (raw) | そのまま pass-through |

Note duration は KeyOff 位置決定のみに使う (= duration から KeyOff の絶対 tick = note_tick + duration を計算)。 gate / tie / velocity は v0.2 scope-out。

### Tempo の扱い (= 25th session user 指示で明示)

`Tempo` は **semantic 層に保持** する。 lowering output から除外しない。

理由:

- v0.2 minimal scope の ChipEvent (= FMToneLoad / FMFrequency / KeyOn / KeyOff) に Tempo 等価物はない。
- chip / driver level の tempo 設定は YM2610 Timer A/B register write (= RawRegisterWrite level) で表現するのが正しく、 これは v0.3 以降の `FMTimerSet` 等で別 sprint に分離する。
- spike では Tempo を semantic 層のまま下流 (= compiler / runtime translator / WebApp) に流し、 そこで chip lowering を判断する。

### channel scope

ToneSelect / Note は **channel.kind = "fm" のみ** lowering する。 他 kind (= SSG / ADPCM-A / ADPCM-B / rhythm_kr) は v0.2 minimal scope 外なので EXIT_PARSE で reject (= silent pass 防止)。

ADPCMATrigger / RawRegisterWrite は既存層なので pass-through。

## scope-out

- gate / tie / velocity
- FM3Mode (= 3 ch independent freq、 v0.3 軸 4)
- Volume / Pan (= chip event、 v0.3)
- LoopStart / LoopEnd (= flow control、 v0.3)
- ADPCMBDma (= ADPCM-B、 v0.3)
- SSG ch (= v0.3)
- raw register write lowering (= chip event は block/fnum / operatorMask 抽象維持)
- driver / runtime / .mn / .PNE / .NEO 生成
- compiler 本体改修 / WebApp / CI

## MIDI -> block/fnum 変換

PMDNEO IR canonical (= MIDI note number 0-127) を YM2610 FM frequency 表現 (= 3-bit block + 11-bit fnum) に変換する。 PMD o5 c = MIDI 60 = C4 (= memory project_pmd_voice_ml_verified) を基準に、

- block = (midi // 12) - 1     # MIDI 60 (C4) -> block 4
- semitone = midi % 12          # 0=C, 1=C#, ..., 11=B
- fnum = fnum_table[semitone]   # 1 octave reference table

block が 0-7 範囲外 (= midi 0-11 or 108-127) なら EXIT_PARSE。 仕様外 octave 入力を silent pass しないことが目的。

fnum table は PMD V4.8s 系 OPN 流の代表値 (= octave 4 reference):

  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
  617 654 693 734 778 824 873 925 980 1038 1100 1165

## exit codes

  0  = OK
  64 = argument error (= input not found / JSON parse / required field missing)
  65 = lowering parse error (= 未対応 event 種 / scope 外 channel kind / MIDI out-of-range)
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

FNUM_TABLE = [617, 654, 693, 734, 778, 824, 873, 925, 980, 1038, 1100, 1165]
BLOCK_MIN = 0
BLOCK_MAX = 7

DEFAULT_OPERATOR_MASK = 15

CREATED_BY = "ir-lower-chipevent-spike v0.2 (= 25th session β、 IR v0.1 SemanticEvent -> v0.2 ChipEvent lowering)"


def _midi_to_block_fnum(midi: int) -> tuple[int, int]:
    if not (0 <= midi <= 127):
        raise ValueError(f"MIDI note out of range (0-127): {midi}")
    block = (midi // 12) - 1
    semitone = midi % 12
    if block < BLOCK_MIN or block > BLOCK_MAX:
        raise ValueError(
            f"MIDI note {midi} は YM2610 FM block 範囲 (= {BLOCK_MIN}-{BLOCK_MAX}) 外 (= block 計算結果 {block})。 "
            f"v0.2 minimal scope は spike で octave 範囲外を silent pass しない方針。"
        )
    fnum = FNUM_TABLE[semitone]
    return block, fnum


def _require_fm_channel(event: dict, label: str) -> dict:
    channel = event.get("channel")
    if not isinstance(channel, dict):
        raise ValueError(f"{label} event has no channel field: {event}")
    if channel.get("kind") != "fm":
        raise ValueError(
            f"{label} channel.kind = {channel.get('kind')!r} は v0.2 minimal scope (= FM only) 外。 "
            f"SSG / ADPCM / rhythm_kr は v0.3 以降で別 lowering sprint。"
        )
    return channel


class _OrderAllocator:
    """Output event の tick 内 order を 0 から連番で発行する。"""

    def __init__(self) -> None:
        self._counter: dict[int, int] = {}

    def next(self, tick: int) -> int:
        n = self._counter.get(tick, 0)
        self._counter[tick] = n + 1
        return n


def lower_events(input_events: list[dict]) -> tuple[list[dict], dict]:
    """v0.1 IR events -> v0.2 IR events lowering。

    Returns:
        (output_events, stats) — stats は report 用 dict。
    """
    allocator = _OrderAllocator()
    output: list[dict] = []
    stats = {
        "input_total": len(input_events),
        "tempo_kept": 0,
        "tone_select_lowered": 0,
        "note_lowered": 0,
        "rest_dropped": 0,
        "chip_passthrough": 0,
        "raw_passthrough": 0,
    }

    def emit(tick: int, layer: str, type_: str, **fields) -> None:
        order = allocator.next(tick)
        ev = {
            "tick": tick,
            "order": order,
            "trackId": fields.pop("trackId", 0),
            "layer": layer,
            "type": type_,
        }
        ev.update(fields)
        output.append(ev)

    for ev in input_events:
        tick = ev.get("tick")
        layer = ev.get("layer")
        type_ = ev.get("type")
        track_id = ev.get("trackId", 0)
        if tick is None or layer is None or type_ is None:
            raise ValueError(f"event missing required common field: {ev}")

        if layer == "semantic" and type_ == "Tempo":
            emit(tick, "semantic", "Tempo", trackId=track_id, bpm=ev["bpm"])
            stats["tempo_kept"] += 1
            continue

        if layer == "semantic" and type_ == "ToneSelect":
            channel = _require_fm_channel(ev, "ToneSelect")
            emit(
                tick,
                "chip",
                "FMToneLoad",
                trackId=track_id,
                channel=channel,
                toneId=ev["toneId"],
            )
            stats["tone_select_lowered"] += 1
            continue

        if layer == "semantic" and type_ == "Note":
            channel = _require_fm_channel(ev, "Note")
            midi = ev["note"]
            duration = ev["duration"]
            if duration < 1:
                raise ValueError(f"Note.duration must be >= 1: {ev}")
            block, fnum = _midi_to_block_fnum(midi)
            emit(
                tick,
                "chip",
                "FMFrequency",
                trackId=track_id,
                channel=channel,
                block=block,
                fnum=fnum,
            )
            emit(
                tick,
                "chip",
                "KeyOn",
                trackId=track_id,
                channel=channel,
                operatorMask=DEFAULT_OPERATOR_MASK,
            )
            emit(
                tick + duration,
                "chip",
                "KeyOff",
                trackId=track_id,
                channel=channel,
                operatorMask=DEFAULT_OPERATOR_MASK,
            )
            stats["note_lowered"] += 1
            continue

        if layer == "semantic" and type_ == "Rest":
            stats["rest_dropped"] += 1
            continue

        if layer == "chip" and type_ == "ADPCMATrigger":
            output.append({**ev})
            stats["chip_passthrough"] += 1
            continue

        if layer == "raw" and type_ == "RawRegisterWrite":
            output.append({**ev})
            stats["raw_passthrough"] += 1
            continue

        raise ValueError(
            f"unsupported event for v0.2 lowering: layer={layer!r} type={type_!r} (= v0.3 以降 scope)"
        )

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
        description="PMDNEO IR -> ChipEvent lowering spike (= v0.1 SemanticEvent -> v0.2 ChipEvent、 ADR-0034 / 25th session)",
    )
    parser.add_argument("input", type=Path, help="input IR v0.1 JSON file path")
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
