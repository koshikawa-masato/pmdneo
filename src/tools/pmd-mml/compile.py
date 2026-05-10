#!/usr/bin/env python3
"""Phase 12a-1 PMDNEO MML compiler."""

from __future__ import annotations

import argparse
import datetime as _dt
import re
import sys
from pathlib import Path


PART_LABELS = {
    chr(ord("A") + i): f"song_part_{chr(ord('a') + i)}" for i in range(17)
}

NOTE_BASE = {
    "c": 0,
    "d": 2,
    "e": 4,
    "f": 5,
    "g": 7,
    "a": 9,
    "b": 11,
}


class MMLCompiler:
    def __init__(self) -> None:
        self.default_length = 32
        self.octave = 4

    def warn(self, line_no: int, pos: int, message: str) -> None:
        print(f"warning: line {line_no}, position {pos + 1}: {message}", file=sys.stderr)

    def error(self, line_no: int, pos: int, message: str) -> None:
        print(f"error: line {line_no}, position {pos + 1}: {message}", file=sys.stderr)

    def compile_part(self, mml: str, line_no: int) -> list[int]:
        out: list[int] = []
        i = 0
        while i < len(mml):
            ch = mml[i]
            if ch.isspace():
                i += 1
                continue

            if ch == "t":
                i = self._compile_number_command(mml, i, line_no, out, 0xFC, self._tempo)
            elif ch == "v":
                i = self._compile_number_command(mml, i, line_no, out, 0xFD)
            elif ch == "V":
                i = self._compile_number_command(mml, i, line_no, out, 0xCC)
            elif ch == "q":
                i = self._compile_number_command(mml, i, line_no, out, 0xFE)
            elif ch == "l":
                i = self._set_default_length(mml, i, line_no)
            elif ch == "o":
                i = self._set_octave(mml, i, line_no)
            elif ch == ">":
                self.octave += 1
                i += 1
            elif ch == "<":
                self.octave -= 1
                i += 1
            elif ch in NOTE_BASE:
                i = self._compile_note(mml, i, line_no, out)
            elif ch == "r":
                i = self._compile_rest(mml, i, line_no, out)
            elif ch == "[":
                out.append(0xF9)
                i += 1
            elif ch == "]":
                i = self._compile_loop_end(mml, i, line_no, out)
            else:
                self.warn(line_no, i, f"unknown command {ch!r}; skipped")
                i += 1

        out.append(0x80)
        return out

    def _compile_number_command(
        self,
        mml: str,
        i: int,
        line_no: int,
        out: list[int],
        command_byte: int,
        convert=None,
    ) -> int:
        start = i
        value, i = self._read_int(mml, i + 1)
        if value is None:
            self.error(line_no, start, f"missing number after {mml[start]!r}")
            return start + 1
        if convert is not None:
            value = convert(value)
        if not 0 <= value <= 0xFF:
            self.error(line_no, start, f"value {value} out of byte range")
            value &= 0xFF
        out.extend([command_byte, value])
        return i

    def _set_default_length(self, mml: str, i: int, line_no: int) -> int:
        start = i
        denominator, i = self._read_int(mml, i + 1)
        if denominator is None:
            self.error(line_no, start, "missing number after 'l'")
            return start + 1
        dotted = i < len(mml) and mml[i] == "."
        if dotted:
            i += 1
        length = self._length_ticks(denominator, dotted, line_no, start)
        if length is not None:
            self.default_length = length
        return i

    def _set_octave(self, mml: str, i: int, line_no: int) -> int:
        start = i
        octave, i = self._read_int(mml, i + 1)
        if octave is None:
            self.error(line_no, start, "missing number after 'o'")
            return start + 1
        self.octave = octave
        return i

    def _compile_note(self, mml: str, i: int, line_no: int, out: list[int]) -> int:
        start = i
        onkai = NOTE_BASE[mml[i]]
        i += 1
        if i < len(mml) and mml[i] in "#+":
            onkai += 1
            i += 1
        elif i < len(mml) and mml[i] == "-":
            onkai -= 1
            i += 1
        onkai %= 12

        denominator, i = self._read_int(mml, i)
        dotted = i < len(mml) and mml[i] == "."
        if dotted:
            i += 1
        if denominator is None:
            length = self.default_length
        else:
            length = self._length_ticks(denominator, dotted, line_no, start)
            if length is None:
                length = self.default_length

        note_byte = (self.octave << 4) | onkai
        if not 0x40 <= note_byte <= 0x7F:
            self.error(line_no, start, f"note byte 0x{note_byte:02X} outside octave 4-7 range")
        out.extend([note_byte & 0xFF, length & 0xFF])
        return i

    def _compile_rest(self, mml: str, i: int, line_no: int, out: list[int]) -> int:
        start = i
        denominator, i = self._read_int(mml, i + 1)
        if denominator is None:
            self.error(line_no, start, "missing length after 'r'")
            return start + 1
        dotted = i < len(mml) and mml[i] == "."
        if dotted:
            i += 1
        length = self._length_ticks(denominator, dotted, line_no, start)
        if length is not None:
            out.extend([0x90, length])
        return i

    def _compile_loop_end(self, mml: str, i: int, line_no: int, out: list[int]) -> int:
        start = i
        count, i = self._read_int(mml, i + 1)
        if count is None:
            self.error(line_no, start, "missing loop count after ']'")
            return start + 1
        if not 0 <= count <= 0xFF:
            self.error(line_no, start, f"loop count {count} out of byte range")
            count &= 0xFF
        out.extend([0xF8, count])
        return i

    def _length_ticks(self, denominator: int, dotted: bool, line_no: int, pos: int) -> int | None:
        if denominator <= 0 or 128 % denominator != 0:
            self.error(line_no, pos, f"unsupported length {denominator}")
            return None
        ticks = 128 // denominator
        if dotted:
            ticks += ticks // 2
        if not 0 <= ticks <= 0xFF:
            self.error(line_no, pos, f"length {ticks} out of byte range")
            return None
        return ticks

    @staticmethod
    def _tempo(bpm: int) -> int:
        return (bpm * 13) >> 6

    @staticmethod
    def _read_int(text: str, i: int) -> tuple[int | None, int]:
        match = re.match(r"\d+", text[i:])
        if not match:
            return None, i
        return int(match.group(0)), i + len(match.group(0))


def parse_mml(source: str) -> list[tuple[str, list[int]]]:
    parts: list[tuple[str, list[int]]] = []
    for line_no, raw_line in enumerate(source.splitlines(), 1):
        line = raw_line.split(";", 1)[0].strip()
        if not line:
            continue
        part = line[0].upper()
        if part not in PART_LABELS:
            print(f"error: line {line_no}, position 1: invalid part letter {line[0]!r}", file=sys.stderr)
            continue
        compiler = MMLCompiler()
        parts.append((PART_LABELS[part], compiler.compile_part(line[1:], line_no)))
    return parts


def format_inc(parts: list[tuple[str, list[int]]], input_path: Path) -> str:
    today = _dt.date.today().isoformat()
    lines = [f";;; PMDNEO compile.py output ({today} from {input_path.name})"]
    for label, data in parts:
        lines.append(f"{label}:")
        body = data[:-1] if data and data[-1] == 0x80 else data
        for i in range(0, len(body), 8):
            chunk = body[i : i + 8]
            bytes_text = ", ".join(f"0x{byte:02X}" for byte in chunk)
            lines.append(f"        .db     {bytes_text}")
        if data and data[-1] == 0x80:
            lines.append("        .db     0x80")
    lines.append("")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compile PMDNEO Phase 12a-1 MML to .inc bytes")
    parser.add_argument("input_mml", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args(argv)

    source = args.input_mml.read_text(encoding="utf-8")
    rendered = format_inc(parse_mml(source), args.input_mml)
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
