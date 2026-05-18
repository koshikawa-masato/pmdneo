#!/usr/bin/env python3
"""PMDNEO MML -> IR exporter spike (ADR-0034 / v0.1).

tiny PMD-flavored MML subset を受け取り、 IR JSON v0.1 を出力する read-only spike。
compiler 本体ではなく、 「MML から IR に落ちる最小の道がある」 ことの proof。

サポート tokens:
  t<bpm>             Tempo event (= 整数 or 浮動小数)
  @<n>               ToneSelect (= 整数 toneId)
  o<n>               octave state (= 1-9、 PMD 流 default 4)
  <a-g>[+|-]?<len>?  Note event (= len 省略時は直前 length、 default 4)
  r<len>?            Rest event
  ; to EOL           comment
  whitespace / newline は token 区切り

hardcoded constants:
  targetProfile = ym2610_aes
  ticksPerBeat  = 192 (= PPQN)
  default octave = 4
  default length = 4 (= quarter note = 48 ticks)
  PMD o5 c = MIDI 60 = C4 (= memory project_pmd_voice_ml_verified)
  single channel = FM ch 2 / Part B
  single tone   = toneId 0 (= dummy FMTone、 minimal-fm-note example と同一構造)

scope-out (= ADR-0034 + 24th session user 指示遵守):
  multi channel / tone parameter parsing / volume / pan / loop / tie /
  chord / portamento / LFO / pitch envelope / octave shift / gate /
  velocity / compiler 本体 / WebApp / driver / runtime /
  .NEO / .mn / .PNE generation / CI

exit codes:
  0  = OK (= MML parse + IR build 成功)
  64 = argument error (= input file not found)
  65 = MML parse error (= unrecognized token / value out of range)
  66 = runtime error (= unexpected exception)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

EXIT_OK = 0
EXIT_ARG = 64
EXIT_PARSE = 65
EXIT_RUNTIME = 66

TARGET_PROFILE = "ym2610_aes"
TICKS_PER_BEAT = 192
DEFAULT_OCTAVE = 4
DEFAULT_LENGTH = 4
SOURCE_DIALECT = "pmd"
CREATED_BY = "mml-to-ir-spike v0.1 (= 24th session、 ADR-0034 ratify 後)"

NOTE_SEMITONE = {"c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11}

HARDCODED_CHANNEL_ID = {"kind": "fm", "index": 2}
HARDCODED_CHANNEL_NAME = "Part B FM2"

HARDCODED_TONE = {
    "toneId": 0,
    "algorithm": 4,
    "feedback": 5,
    "operators": [
        {"ar": 31, "dr": 14, "sr": 0, "rr": 7, "sl": 1, "tl": 35, "ks": 0, "mul": 1, "dt": 0, "am": False, "ssgEg": 0},
        {"ar": 25, "dr": 5,  "sr": 0, "rr": 5, "sl": 2, "tl": 20, "ks": 0, "mul": 4, "dt": 0, "am": False, "ssgEg": 0},
        {"ar": 31, "dr": 14, "sr": 0, "rr": 7, "sl": 1, "tl": 35, "ks": 0, "mul": 1, "dt": 0, "am": False, "ssgEg": 0},
        {"ar": 25, "dr": 5,  "sr": 0, "rr": 5, "sl": 2, "tl": 0,  "ks": 0, "mul": 1, "dt": 0, "am": False, "ssgEg": 0},
    ],
}

TEMPO_RE       = re.compile(r"^t(\d+(?:\.\d+)?)$")
TONE_SELECT_RE = re.compile(r"^@(\d+)$")
OCTAVE_RE      = re.compile(r"^o(\d+)$")
NOTE_RE        = re.compile(r"^([a-g])([+\-])?(\d+)?$")
REST_RE        = re.compile(r"^r(\d+)?$")


def _strip_comment(line: str) -> str:
    idx = line.find(";")
    if idx >= 0:
        line = line[:idx]
    return line.strip()


def tokenize(mml: str) -> list[str]:
    cleaned = "\n".join(_strip_comment(line) for line in mml.splitlines())
    return cleaned.split()


def length_to_ticks(length: int) -> int:
    if length <= 0:
        raise ValueError(f"length must be positive: {length}")
    if (TICKS_PER_BEAT * 4) % length != 0:
        raise ValueError(
            f"length {length} は ticksPerBeat={TICKS_PER_BEAT} で割り切れない (= 端数発生)"
        )
    return (TICKS_PER_BEAT * 4) // length


def pmd_note_to_midi(letter: str, accidental: str | None, octave: int) -> int:
    """PMD o<n> + note letter -> MIDI note number.

    PMD o5 c = MIDI 60 (= C4) より、 PMD o<n> c = MIDI n*12。
    """
    semitone = NOTE_SEMITONE[letter]
    if accidental == "+":
        semitone += 1
    elif accidental == "-":
        semitone -= 1
    midi = octave * 12 + semitone
    if not (0 <= midi <= 127):
        raise ValueError(
            f"MIDI note out of range (0-127): o{octave} {letter}{accidental or ''} -> {midi}"
        )
    return midi


def parse_mml(mml: str) -> list[dict]:
    tokens = tokenize(mml)
    events: list[dict] = []
    state_octave = DEFAULT_OCTAVE
    state_length = DEFAULT_LENGTH
    state_tick = 0
    order_by_tick: dict[int, int] = {}

    def next_order(tick: int) -> int:
        n = order_by_tick.get(tick, 0)
        order_by_tick[tick] = n + 1
        return n

    for tok in tokens:
        m = TEMPO_RE.match(tok)
        if m:
            events.append({
                "tick": state_tick,
                "order": next_order(state_tick),
                "trackId": 0,
                "layer": "semantic",
                "type": "Tempo",
                "bpm": float(m.group(1)),
            })
            continue

        m = TONE_SELECT_RE.match(tok)
        if m:
            events.append({
                "tick": state_tick,
                "order": next_order(state_tick),
                "trackId": 0,
                "layer": "semantic",
                "type": "ToneSelect",
                "channel": HARDCODED_CHANNEL_ID,
                "toneId": int(m.group(1)),
            })
            continue

        m = OCTAVE_RE.match(tok)
        if m:
            oct_val = int(m.group(1))
            if not (1 <= oct_val <= 9):
                raise ValueError(f"octave out of range (1-9): {oct_val}")
            state_octave = oct_val
            continue

        m = REST_RE.match(tok)
        if m:
            length_str = m.group(1)
            if length_str:
                state_length = int(length_str)
            duration = length_to_ticks(state_length)
            events.append({
                "tick": state_tick,
                "order": next_order(state_tick),
                "trackId": 0,
                "layer": "semantic",
                "type": "Rest",
                "channel": HARDCODED_CHANNEL_ID,
                "duration": duration,
            })
            state_tick += duration
            continue

        m = NOTE_RE.match(tok)
        if m:
            letter, accidental, length_str = m.group(1), m.group(2), m.group(3)
            if length_str:
                state_length = int(length_str)
            duration = length_to_ticks(state_length)
            midi = pmd_note_to_midi(letter, accidental, state_octave)
            events.append({
                "tick": state_tick,
                "order": next_order(state_tick),
                "trackId": 0,
                "layer": "semantic",
                "type": "Note",
                "channel": HARDCODED_CHANNEL_ID,
                "note": midi,
                "duration": duration,
            })
            state_tick += duration
            continue

        raise ValueError(f"unrecognized token: {tok!r}")

    return events


def build_ir(events: list[dict]) -> dict:
    return {
        "metadata": {
            "magic": "PMDNEO-IR",
            "version": 1,
            "sourceDialect": SOURCE_DIALECT,
            "createdBy": CREATED_BY,
        },
        "targetProfile": TARGET_PROFILE,
        "timing": {
            "ticksPerBeat": TICKS_PER_BEAT,
            "timeMode": "absolute",
            "tempoBase": 120.0,
        },
        "channels": [
            {
                "channelId": HARDCODED_CHANNEL_ID,
                "name": HARDCODED_CHANNEL_NAME,
            }
        ],
        "tones": [HARDCODED_TONE],
        "events": events,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="PMDNEO MML -> IR exporter spike (ADR-0034 / v0.1)",
    )
    parser.add_argument("input", type=Path, help="input MML file path")
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="output JSON file path (default: stdout)",
    )
    args = parser.parse_args()

    if not args.input.exists():
        print(f"[FAIL] input file not found: {args.input}", file=sys.stderr)
        return EXIT_ARG

    try:
        mml = args.input.read_text()
        events = parse_mml(mml)
    except ValueError as e:
        print(f"[FAIL] MML parse error: {e}", file=sys.stderr)
        return EXIT_PARSE

    ir = build_ir(events)
    text = json.dumps(ir, indent=2, ensure_ascii=False) + "\n"

    if args.output:
        args.output.write_text(text)
        print(
            f"[OK] wrote {len(events)} events to {args.output}",
            file=sys.stderr,
        )
    else:
        sys.stdout.write(text)
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
