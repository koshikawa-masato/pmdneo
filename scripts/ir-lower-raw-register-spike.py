#!/usr/bin/env python3
"""PMDNEO IR -> RawRegisterWrite lowering spike (= IR v0.2 ChipEvent -> v0.2 RawRegisterWrite、 ADR-0035 / 26th session β).

v0.2 ChipEvent lowered IR JSON (= 25th session β `ir-lower-chipevent-spike.py` 出力) を入力に、
4 ChipEvent (= FMToneLoad / FMFrequency / KeyOn / KeyOff) を YM2610 RawRegisterWrite 列に lowering した v0.2 IR JSON を出力する read-only spike。 compiler 本体ではなく、 「chip 層から raw 層に落ちる最小の道がある」 ことの proof。

## lowering rule (= ADR-0035 §決定 1-9)

| 入力 event | 出力 |
|---|---|
| `Tempo` (semantic) | `Tempo` (semantic) として **そのまま保持** (= ADR-0035 §決定 2) |
| `FMToneLoad` (chip) | `RawRegisterWrite` (raw) × 25-29 件 (= DT/MUL/TL/KS,AR/AM,DR/SR/SL,RR × 4 op + AL/FB 1 + 任意 SSG-EG × 0-4 op) |
| `FMFrequency` (chip) | `RawRegisterWrite` (raw) × 2 件 (= 0xA4 high → 0xA0 low 順序固定) |
| `KeyOn` (chip) | `RawRegisterWrite` (raw) × 1 件 (= port 0 0x28、 data = (operatorMask << 4) \| ch_code) |
| `KeyOff` (chip) | `RawRegisterWrite` (raw) × 1 件 (= port 0 0x28、 data = ch_code、 上 4 bit clear で全 op release、 ADR-0035 §決定 7) |
| `ADPCMATrigger` (chip) | そのまま pass-through (= chip 1 件のまま、 raw 化は別 sprint) |
| `RawRegisterWrite` (raw) | そのまま pass-through (raw 1 件のまま) |

ADR-0035 §決定 3 で「semantic 残存 (= Note / Rest / ToneSelect) は exit 65 reject」 = 本 spike の入力は v0.2 ChipEvent lowered IR (= 前段 Semantic→Chip lowering 完了済) を想定。

## YM2610 register mapping (= ADR-0035 §決定 4)

| FM index (IR) | port | ch_offset | KeyOn ch_code |
|---:|---:|---:|---:|
| 1 | 0 | 0 | 0x00 |
| 2 | 0 | 1 | 0x01 |
| 3 | 0 | 2 | 0x02 |
| 4 | 1 | 0 | 0x04 |
| 5 | 1 | 1 | 0x05 |
| 6 | 1 | 2 | 0x06 |

KeyOn / KeyOff 0x28 のみ port 0 で全 channel 制御。

## operator slot order (= ADR-0035 §決定 8、 YM2608/YM2610 仕様、 PMD/MewFM 整合)

| operator | slot offset |
|---:|---:|
| op1 | 0x00 |
| op2 | 0x08 |
| op3 | 0x04 |
| op4 | 0x0C |

slot offset を間違えると音色全壊。

## byte encoding (= ADR-0035 §決定 8)

| param 組 | base reg | byte 構成 |
|---|---:|---|
| DT, MUL | 0x30 | `((dt + 3) << 4) \| (mul & 0x0F)` |
| TL | 0x40 | `tl & 0x7F` |
| KS, AR | 0x50 | `((ks & 0x03) << 6) \| (ar & 0x1F)` |
| AM, DR | 0x60 | `((am ? 1 : 0) << 7) \| (dr & 0x1F)` |
| SR | 0x70 | `sr & 0x1F` |
| SL, RR | 0x80 | `((sl & 0x0F) << 4) \| (rr & 0x0F)` |
| SSG-EG | 0x90 | `ssgEg & 0x0F` (operator に field 有時のみ) |
| AL, FB | 0xB0 | `((feedback & 0x07) << 3) \| (algorithm & 0x07)` |

## FMFrequency 順序 invariant (= ADR-0035 §決定 5)

0xA4 (high) → 0xA0 (low) の順で書く。 0xA0 write が latch 確定。 逆順は YM2608/YM2610 で undefined。

## 同 tick pass-through 混在規律 (= ADR-0035 §決定 9 末尾)

入力 IR を `(tick, trackId, order)` 昇順で sort 後、 linear scan で emit する。 ChipEvent は 1 件 raw 複数件に展開、 展開列内部は「tone → freq → keyon → keyoff」 順序維持。 pass-through は 1 件をその layer/type のまま 1 件 emit。 output allocator が emit 順に order を再採番し、 最後に出力全体を (tick, order) で sort 正規化。

## timing 制約 (= ADR-0035 §verify 計画、 25th session β spike 規律踏襲)

`timing.timeMode` は `"absolute"` のみ受け付ける (= 省略時 default = "absolute")。 `"delta"` は spike では reject (exit 65)。

## (tick, trackId, order) 重複 reject (= 25th session β 規律踏襲)

同一 (tick, trackId, order) 重複は Python stable sort 経由で input array 順が silently authoritative 化するため、 sort 前に検出して exit 65 reject。

## scope-out (= ADR-0035 §scope-out)

- driver / runtime / .mn / .PNE / .NEO / WebApp 変更なし
- ADPCM lowering (= ADPCMATrigger は pass-through)
- FM3Mode / Volume / Pan / LoopStart / LoopEnd / ADPCMBDma
- SSG / ADPCM-B / rhythm_kr
- optimization / cache / 重複削減
- pitch correction
- aesthetic / audio audition

## exit codes (= 既存 spike と同)

  0  = OK
  64 = argument error (= input not found / JSON parse / required field missing)
  65 = lowering parse error (= 未対応 event 種 / semantic 残存 / toneId resolve 失敗 / tone schema 違反 / scope 外 channel kind 等)
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

CREATED_BY = "ir-lower-raw-register-spike v0.2 (= 26th session β、 IR v0.2 ChipEvent -> v0.2 RawRegisterWrite lowering)"

# operator slot offset (= ADR-0035 §決定 8、 YM2608/YM2610 流儀)
# operators[] index = 0..3 = op1..op4 を slot offset 0/8/4/12 に map
OP_SLOT_OFFSETS = [0x00, 0x08, 0x04, 0x0C]

# parameter base registers (= ADR-0035 §決定 8)
REG_DT_MUL = 0x30
REG_TL = 0x40
REG_KS_AR = 0x50
REG_AM_DR = 0x60
REG_SR = 0x70
REG_SL_RR = 0x80
REG_SSG_EG = 0x90
REG_AL_FB = 0xB0

REG_FREQ_HIGH = 0xA4
REG_FREQ_LOW = 0xA0

REG_KEY_ONOFF = 0x28
PORT_KEY_ONOFF = 0


def _fm_ch_routing(ch_index: int) -> tuple[int, int, int]:
    """FM ch index 1-6 → (port, ch_offset, ch_code) (= ADR-0035 §決定 4 table)."""
    if not (1 <= ch_index <= 6):
        raise ValueError(
            f"FM channel index out of range (1-6): {ch_index} (= ADR-0035 §決定 4)"
        )
    port = 0 if ch_index <= 3 else 1
    ch_offset = (ch_index - 1) % 3
    # ch_code: ch 1..3 = 0x00..0x02、 ch 4..6 = 0x04..0x06 (= bit 2 で port 識別、 bit 0-1 で ch_offset)
    ch_code = (port << 2) | ch_offset
    return port, ch_offset, ch_code


def _validate_fm_channel(channel: dict, label: str) -> int:
    if not isinstance(channel, dict):
        raise ValueError(f"{label}: channel field missing or not object: {channel!r}")
    if channel.get("kind") != "fm":
        raise ValueError(
            f"{label}: channel.kind = {channel.get('kind')!r} は v0.2 ChipEvent scope 外 "
            f"(= FM only、 SSG/ADPCM/rhythm_kr は v0.3 以降)"
        )
    idx = channel.get("index")
    if type(idx) is not int:
        raise ValueError(f"{label}: channel.index must be int, got {idx!r}")
    return idx


def _validate_operator(op: dict, op_index: int, tone_id: int) -> None:
    """tone resolve 済 operator の schema 違反 reject (= defense in depth、 ADR-0035 §決定 8)."""
    required = ("ar", "dr", "sr", "rr", "sl", "tl", "ks", "mul", "dt")
    for k in required:
        if k not in op:
            raise ValueError(
                f"toneId={tone_id} operator[{op_index}] missing required field {k!r}: {op}"
            )
    ranges = {
        "ar": (0, 31),
        "dr": (0, 31),
        "sr": (0, 31),
        "rr": (0, 15),
        "sl": (0, 15),
        "tl": (0, 127),
        "ks": (0, 3),
        "mul": (0, 15),
        "dt": (-3, 3),
    }
    for k, (lo, hi) in ranges.items():
        v = op[k]
        if type(v) is not int or not (lo <= v <= hi):
            raise ValueError(
                f"toneId={tone_id} operator[{op_index}] {k}={v!r} out of range [{lo}, {hi}]"
            )
    if "ssgEg" in op:
        v = op["ssgEg"]
        if type(v) is not int or not (0 <= v <= 15):
            raise ValueError(
                f"toneId={tone_id} operator[{op_index}] ssgEg={v!r} out of range [0, 15]"
            )
    if "am" in op and not isinstance(op["am"], bool):
        raise ValueError(
            f"toneId={tone_id} operator[{op_index}] am={op['am']!r} must be boolean"
        )


def _validate_tone(tone: dict) -> None:
    """tones[] 内 tone 1 件 schema 違反 reject."""
    for k in ("toneId", "algorithm", "feedback", "operators"):
        if k not in tone:
            raise ValueError(f"tone missing required field {k!r}: {tone}")
    tid = tone["toneId"]
    al = tone["algorithm"]
    fb = tone["feedback"]
    ops = tone["operators"]
    if type(al) is not int or not (0 <= al <= 7):
        raise ValueError(f"toneId={tid} algorithm={al!r} out of range [0, 7]")
    if type(fb) is not int or not (0 <= fb <= 7):
        raise ValueError(f"toneId={tid} feedback={fb!r} out of range [0, 7]")
    if not isinstance(ops, list) or len(ops) != 4:
        raise ValueError(f"toneId={tid} operators[] length must be 4, got {len(ops) if isinstance(ops, list) else type(ops).__name__}")
    for i, op in enumerate(ops):
        _validate_operator(op, i, tid)


def _build_tone_index(tones: list[dict] | None) -> dict[int, dict]:
    """tones[] を toneId -> tone dict に index 化。 同 toneId 重複は reject。"""
    out: dict[int, dict] = {}
    if not tones:
        return out
    for tone in tones:
        _validate_tone(tone)
        tid = tone["toneId"]
        if tid in out:
            raise ValueError(f"duplicate toneId in tones[]: {tid}")
        out[tid] = tone
    return out


class _OrderAllocator:
    """Output event の tick 内 order を 0 から連番で発行する。"""

    def __init__(self) -> None:
        self._counter: dict[int, int] = {}

    def next(self, tick: int) -> int:
        n = self._counter.get(tick, 0)
        self._counter[tick] = n + 1
        return n


def _emit_raw(
    output: list[dict],
    allocator: _OrderAllocator,
    tick: int,
    track_id: int,
    port: int,
    address: int,
    data: int,
) -> None:
    order = allocator.next(tick)
    output.append(
        {
            "tick": tick,
            "order": order,
            "trackId": track_id,
            "layer": "raw",
            "type": "RawRegisterWrite",
            "port": port,
            "address": address,
            "data": data,
        }
    )


def _emit_fmtoneload(
    output: list[dict],
    allocator: _OrderAllocator,
    tick: int,
    track_id: int,
    tone: dict,
    ch_index: int,
) -> int:
    """FMToneLoad → 25-29 RawRegisterWrite 件を emit。 emit 件数を返す。"""
    port, ch_offset, _ = _fm_ch_routing(ch_index)
    ops = tone["operators"]
    al = tone["algorithm"] & 0x07
    fb = tone["feedback"] & 0x07
    count = 0

    # DT/MUL × 4 op (base 0x30)
    for op_i, op in enumerate(ops):
        addr = REG_DT_MUL + ch_offset + OP_SLOT_OFFSETS[op_i]
        data = ((op["dt"] + 3) << 4) | (op["mul"] & 0x0F)
        _emit_raw(output, allocator, tick, track_id, port, addr, data)
        count += 1

    # TL × 4 op (base 0x40)
    for op_i, op in enumerate(ops):
        addr = REG_TL + ch_offset + OP_SLOT_OFFSETS[op_i]
        data = op["tl"] & 0x7F
        _emit_raw(output, allocator, tick, track_id, port, addr, data)
        count += 1

    # KS/AR × 4 op (base 0x50)
    for op_i, op in enumerate(ops):
        addr = REG_KS_AR + ch_offset + OP_SLOT_OFFSETS[op_i]
        data = ((op["ks"] & 0x03) << 6) | (op["ar"] & 0x1F)
        _emit_raw(output, allocator, tick, track_id, port, addr, data)
        count += 1

    # AM/DR × 4 op (base 0x60)
    for op_i, op in enumerate(ops):
        addr = REG_AM_DR + ch_offset + OP_SLOT_OFFSETS[op_i]
        am_bit = 1 if op.get("am", False) else 0
        data = (am_bit << 7) | (op["dr"] & 0x1F)
        _emit_raw(output, allocator, tick, track_id, port, addr, data)
        count += 1

    # SR × 4 op (base 0x70)
    for op_i, op in enumerate(ops):
        addr = REG_SR + ch_offset + OP_SLOT_OFFSETS[op_i]
        data = op["sr"] & 0x1F
        _emit_raw(output, allocator, tick, track_id, port, addr, data)
        count += 1

    # SL/RR × 4 op (base 0x80)
    for op_i, op in enumerate(ops):
        addr = REG_SL_RR + ch_offset + OP_SLOT_OFFSETS[op_i]
        data = ((op["sl"] & 0x0F) << 4) | (op["rr"] & 0x0F)
        _emit_raw(output, allocator, tick, track_id, port, addr, data)
        count += 1

    # SSG-EG × 0-4 op (base 0x90、 operator に field 有時のみ、 ADR-0035 §決定 8)
    for op_i, op in enumerate(ops):
        if "ssgEg" not in op:
            continue
        addr = REG_SSG_EG + ch_offset + OP_SLOT_OFFSETS[op_i]
        data = op["ssgEg"] & 0x0F
        _emit_raw(output, allocator, tick, track_id, port, addr, data)
        count += 1

    # AL/FB × 1 (0xB0 + ch_offset)
    addr = REG_AL_FB + ch_offset
    data = (fb << 3) | al
    _emit_raw(output, allocator, tick, track_id, port, addr, data)
    count += 1

    return count


def _emit_fmfrequency(
    output: list[dict],
    allocator: _OrderAllocator,
    tick: int,
    track_id: int,
    block: int,
    fnum: int,
    ch_index: int,
) -> None:
    """FMFrequency → 0xA4 high → 0xA0 low の 2 件を順序固定で emit (= ADR-0035 §決定 5)."""
    if type(block) is not int or type(fnum) is not int:
        raise ValueError(
            f"FMFrequency block/fnum must be int: block={block!r} fnum={fnum!r}"
        )
    if not (0 <= block <= 7):
        raise ValueError(f"FMFrequency block out of range (0-7): {block}")
    if not (0 <= fnum <= 2047):
        raise ValueError(f"FMFrequency fnum out of range (0-2047): {fnum}")
    port, ch_offset, _ = _fm_ch_routing(ch_index)
    # 0xA4 high 先
    data_high = ((block & 0x07) << 3) | ((fnum >> 8) & 0x07)
    _emit_raw(output, allocator, tick, track_id, port, REG_FREQ_HIGH + ch_offset, data_high)
    # 0xA0 low 後 (latch 確定)
    data_low = fnum & 0xFF
    _emit_raw(output, allocator, tick, track_id, port, REG_FREQ_LOW + ch_offset, data_low)


def _emit_keyon(
    output: list[dict],
    allocator: _OrderAllocator,
    tick: int,
    track_id: int,
    operator_mask: int,
    ch_index: int,
) -> None:
    """KeyOn → 0x28 single write (= port 0、 data = (mask << 4) | ch_code、 ADR-0035 §決定 6)."""
    if type(operator_mask) is not int:
        raise ValueError(f"KeyOn operatorMask must be int: {operator_mask!r}")
    if not (1 <= operator_mask <= 15):
        raise ValueError(f"KeyOn operatorMask out of range (1-15): {operator_mask}")
    _, _, ch_code = _fm_ch_routing(ch_index)
    data = ((operator_mask & 0x0F) << 4) | ch_code
    _emit_raw(output, allocator, tick, track_id, PORT_KEY_ONOFF, REG_KEY_ONOFF, data)


def _emit_keyoff(
    output: list[dict],
    allocator: _OrderAllocator,
    tick: int,
    track_id: int,
    ch_index: int,
) -> None:
    """KeyOff → 0x28 single write (= port 0、 上 4 bit clear で全 op release、 ADR-0035 §決定 7)。

    schema 上 KeyOff.operatorMask は minimum 1 だが、 raw 0x28 では 上 4 bit = 0 で
    「対象 channel の全 op release」 を意味するため operatorMask は無視。
    operator 別 release の意味保存は v0.3 spike の範囲外。
    """
    _, _, ch_code = _fm_ch_routing(ch_index)
    data = ch_code  # 上 4 bit clear
    _emit_raw(output, allocator, tick, track_id, PORT_KEY_ONOFF, REG_KEY_ONOFF, data)


def lower_events(
    input_events: list[dict], tone_index: dict[int, dict]
) -> tuple[list[dict], dict]:
    """v0.2 ChipEvent IR events -> v0.2 RawRegisterWrite IR events lowering。

    Returns:
        (output_events, stats) — stats は report 用 dict。

    Note: 入力 array 順は **not authoritative**。 IR の (tick, trackId, order) が真の順序。
    spike は処理前に (tick, trackId, order) で sort し直す (= ADR-0035 §決定 9、
    25th session β spike 規律踏襲)。 同一 (tick, trackId, order) 重複は Python の stable
    sort で array 順が silently authoritative 化するため、 sort 前に reject。
    """
    allocator = _OrderAllocator()
    output: list[dict] = []
    stats = {
        "input_total": len(input_events),
        "tempo_passthrough": 0,
        "fmtoneload_lowered": 0,
        "fmfrequency_lowered": 0,
        "keyon_lowered": 0,
        "keyoff_lowered": 0,
        "adpcma_passthrough": 0,
        "raw_passthrough": 0,
        "raw_writes_emitted": 0,
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

    raw_writes_before = 0

    for ev in sorted_input:
        tick = ev["tick"]
        layer = ev["layer"]
        type_ = ev["type"]
        track_id = ev.get("trackId", 0)

        if layer == "semantic" and type_ == "Tempo":
            order = allocator.next(tick)
            output.append({**ev, "order": order})
            stats["tempo_passthrough"] += 1
            continue

        if layer == "semantic" and type_ in ("Note", "Rest", "ToneSelect"):
            raise ValueError(
                f"semantic 残存 event detected: layer=semantic type={type_!r} (= ADR-0035 §決定 3、 "
                f"本 spike の入力は v0.2 ChipEvent lowered IR 想定、 前段 Semantic→Chip lowering 不徹底)"
            )

        if layer == "chip" and type_ == "FMToneLoad":
            ch_idx = _validate_fm_channel(ev.get("channel"), "FMToneLoad")
            tid = ev.get("toneId")
            if tid is None:
                raise ValueError(f"FMToneLoad missing toneId: {ev}")
            tone = tone_index.get(tid)
            if tone is None:
                raise ValueError(
                    f"FMToneLoad toneId={tid} not found in tones[] (= ADR-0035 §決定 8)"
                )
            raw_writes_before = len(output)
            _emit_fmtoneload(output, allocator, tick, track_id, tone, ch_idx)
            stats["fmtoneload_lowered"] += 1
            stats["raw_writes_emitted"] += len(output) - raw_writes_before
            continue

        if layer == "chip" and type_ == "FMFrequency":
            ch_idx = _validate_fm_channel(ev.get("channel"), "FMFrequency")
            block = ev.get("block")
            fnum = ev.get("fnum")
            if block is None or fnum is None:
                raise ValueError(f"FMFrequency missing block/fnum: {ev}")
            raw_writes_before = len(output)
            _emit_fmfrequency(output, allocator, tick, track_id, block, fnum, ch_idx)
            stats["fmfrequency_lowered"] += 1
            stats["raw_writes_emitted"] += len(output) - raw_writes_before
            continue

        if layer == "chip" and type_ == "KeyOn":
            ch_idx = _validate_fm_channel(ev.get("channel"), "KeyOn")
            mask = ev.get("operatorMask", 15)
            raw_writes_before = len(output)
            _emit_keyon(output, allocator, tick, track_id, mask, ch_idx)
            stats["keyon_lowered"] += 1
            stats["raw_writes_emitted"] += len(output) - raw_writes_before
            continue

        if layer == "chip" and type_ == "KeyOff":
            ch_idx = _validate_fm_channel(ev.get("channel"), "KeyOff")
            raw_writes_before = len(output)
            _emit_keyoff(output, allocator, tick, track_id, ch_idx)
            stats["keyoff_lowered"] += 1
            stats["raw_writes_emitted"] += len(output) - raw_writes_before
            continue

        if layer == "chip" and type_ == "ADPCMATrigger":
            order = allocator.next(tick)
            output.append({**ev, "order": order})
            stats["adpcma_passthrough"] += 1
            continue

        if layer == "raw" and type_ == "RawRegisterWrite":
            order = allocator.next(tick)
            output.append({**ev, "order": order})
            stats["raw_passthrough"] += 1
            continue

        raise ValueError(
            f"unsupported event for v0.2 raw lowering: layer={layer!r} type={type_!r} "
            f"(= ADR-0035 §決定 1、 v0.3 以降 scope)"
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
        description="PMDNEO IR -> RawRegisterWrite lowering spike (= v0.2 ChipEvent -> v0.2 RawRegisterWrite、 ADR-0035 / 26th session)",
    )
    parser.add_argument("input", type=Path, help="input IR v0.2 ChipEvent lowered JSON file path")
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
        tone_index = _build_tone_index(input_ir.get("tones"))
        lowered, stats = lower_events(input_ir["events"], tone_index)
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
