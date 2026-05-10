#!/usr/bin/env python3
"""Phase 12a-2 PMDNEO MML compiler."""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path


PART_LABELS = {
    chr(ord("A") + i): f"song_part_{chr(ord('a') + i)}" for i in range(17)
}
TARGET_PARTS = ("B", "C", "E", "F", "G", "H", "I", "J", "L", "M", "N", "O", "P", "Q")
MAX_LOOP_DEPTH = 4

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
        self._compile_sequence(mml, 0, line_no, out, 0)
        out.append(0x80)
        return out

    def _compile_sequence(
        self,
        mml: str,
        i: int,
        line_no: int,
        out: list[int],
        loop_depth: int,
    ) -> int:
        while i < len(mml):
            ch = mml[i]
            if ch.isspace():
                i += 1
                continue

            if ch == "t":
                i = self._compile_number_command(mml, i, line_no, out, 0xFC, self._tempo)
            elif ch == "v":
                if i + 1 < len(mml) and mml[i + 1] in "+-)(":
                    i = self._compile_v_modifier(mml, i, line_no, out)
                else:
                    i = self._compile_number_command(mml, i, line_no, out, 0xFD)
            elif ch == "V":
                i = self._compile_number_command(mml, i, line_no, out, 0xCC)
            elif ch == "q":
                if i + 1 < len(mml) and mml[i + 1] in "234":
                    i = self._compile_q_modifier(mml, i, line_no, out)
                else:
                    i = self._compile_number_command(mml, i, line_no, out, 0xFE)
            elif ch == "D":
                if i + 1 < len(mml) and mml[i + 1] == "D":
                    i = self._compile_signed_arg(mml, i, line_no, out, 0xD5, prefix_len=2)
                else:
                    i = self._compile_signed_arg(mml, i, line_no, out, 0xFA, prefix_len=1)
            elif ch == "L":
                out.append(0xF6)
                i += 1
            elif ch == "&":
                out.append(0xFB)
                i += 1
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
            elif ch == "(":
                i = self._compile_paren(mml, i, line_no, out, 0xF3)
            elif ch == ")":
                i = self._compile_paren(mml, i, line_no, out, 0xF4)
            elif ch == "[":
                if loop_depth >= MAX_LOOP_DEPTH:
                    self.error(line_no, i, f"loop nesting exceeds {MAX_LOOP_DEPTH} levels")
                    i += 1
                    continue
                out.append(0xF9)
                i = self._compile_sequence(mml, i + 1, line_no, out, loop_depth + 1)
            elif ch == "]":
                if loop_depth == 0:
                    self.error(line_no, i, "unmatched ']'")
                    i += 1
                    continue
                return self._compile_loop_end(mml, i, line_no, out)
            elif ch == ":":
                i = self._compile_loop_escape(mml, i, line_no, out, loop_depth)
            else:
                self.warn(line_no, i, f"unknown command {ch!r}; skipped")
                i += 1

        if loop_depth:
            self.error(line_no, len(mml), "missing ']' for loop")
        return i

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

    def _compile_v_modifier(self, mml: str, i: int, line_no: int, out: list[int]) -> int:
        command_bytes = {
            "+": 0xDE,
            "-": 0xDD,
            ")": 0xDB,
            "(": 0xDA,
        }
        modifier = mml[i + 1]
        return self._compile_required_arg(mml, i, i + 2, line_no, out, command_bytes[modifier])

    def _compile_q_modifier(self, mml: str, i: int, line_no: int, out: list[int]) -> int:
        command_bytes = {
            "2": 0xC4,
            "3": 0xB3,
            "4": 0xB1,
        }
        modifier = mml[i + 1]
        return self._compile_required_arg(mml, i, i + 2, line_no, out, command_bytes[modifier])

    def _compile_paren(
        self,
        mml: str,
        i: int,
        line_no: int,
        out: list[int],
        command_byte: int,
    ) -> int:
        value, next_i = self._read_int(mml, i + 1)
        if value is None:
            value = 1
            next_i = i + 1
        if not 0 <= value <= 0xFF:
            self.error(line_no, i, f"value {value} out of byte range")
            value &= 0xFF
        out.extend([command_byte, value])
        return next_i

    def _compile_required_arg(
        self,
        mml: str,
        command_i: int,
        arg_i: int,
        line_no: int,
        out: list[int],
        command_byte: int,
    ) -> int:
        while arg_i < len(mml) and mml[arg_i].isspace():
            arg_i += 1
        value, next_i = self._read_int(mml, arg_i)
        if value is None:
            self.error(line_no, command_i, f"missing number after {mml[command_i:arg_i]!r}")
            return arg_i
        if not 0 <= value <= 0xFF:
            self.error(line_no, command_i, f"value {value} out of byte range")
            value &= 0xFF
        out.extend([command_byte, value])
        return next_i

    def _compile_signed_arg(
        self,
        mml: str,
        i: int,
        line_no: int,
        out: list[int],
        command_byte: int,
        prefix_len: int,
    ) -> int:
        j = i + prefix_len
        while j < len(mml) and mml[j].isspace():
            j += 1
        sign = 1
        if j < len(mml) and mml[j] in "+-":
            sign = -1 if mml[j] == "-" else 1
            j += 1
        value, j = self._read_int(mml, j)
        if value is None:
            self.error(line_no, i, f"missing number after {mml[i:i + prefix_len]!r}")
            return i + prefix_len
        value *= sign
        if not -128 <= value <= 127:
            self.error(line_no, i, f"signed value {value} out of int8 range")
            value &= 0xFF
        out.extend([command_byte, value & 0xFF])
        return j

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
            count = 0
        if not 0 <= count <= 0xFF:
            self.error(line_no, start, f"loop count {count} out of byte range")
            count &= 0xFF
        out.extend([0xF8, count])
        return i

    def _compile_loop_escape(
        self,
        mml: str,
        i: int,
        line_no: int,
        out: list[int],
        loop_depth: int,
    ) -> int:
        """Emit 0xF7 <N> for ':' loop-escape. N = count from matching ']N'."""
        if loop_depth == 0:
            self.error(line_no, i, "':' outside of loop")
            return i + 1
        n_value = self._find_matching_loop_end_count(mml, i + 1)
        if n_value is None:
            self.error(line_no, i, "no matching ']' for ':'")
            return i + 1
        out.extend([0xF7, n_value & 0xFF])
        return i + 1

    def _find_matching_loop_end_count(self, mml: str, start: int) -> int | None:
        """Look-ahead from start to find the matching ']N' and return N."""
        nest = 0
        j = start
        while j < len(mml):
            ch = mml[j]
            if ch == "[":
                nest += 1
                j += 1
            elif ch == "]":
                if nest == 0:
                    count, _ = self._read_int(mml, j + 1)
                    return count if count is not None else 0
                nest -= 1
                j += 1
                _, j = self._read_int(mml, j)
            elif ch == "{":
                while j < len(mml) and mml[j] != "}":
                    j += 1
                j += 1
            else:
                j += 1
        return None

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
    macros: dict[str, str] = {}
    expanded_lines: list[tuple[int, str]] = []
    for line_no, raw_line in enumerate(source.splitlines(), 1):
        stripped = raw_line.strip()
        if stripped.startswith("!"):
            m = re.match(r"^!(\w+)[ \t]+(.*)$", stripped)
            if m:
                name, body = m.group(1), m.group(2)
                macros[name] = body
            else:
                print(f"warning: line {line_no}: malformed macro definition", file=sys.stderr)
            continue
        expanded_lines.append((line_no, raw_line))

    parts: dict[str, list[int]] = {}
    macro_pattern = None
    if macros:
        macro_names = sorted((re.escape(name) for name in macros), key=len, reverse=True)
        macro_pattern = re.compile(r"!(" + "|".join(macro_names) + r")(?!\w)")

    for line_no, raw_line in expanded_lines:
        line = re.split(r"[;#]", raw_line, maxsplit=1)[0].strip()
        if macro_pattern is not None:
            line = macro_pattern.sub(lambda m: macros[m.group(1)], line)
        for unresolved in re.findall(r"!\w+", line):
            uname = unresolved[1:]
            if uname not in macros:
                print(f"warning: line {line_no}: undefined macro {unresolved!r}", file=sys.stderr)
        if not line:
            continue
        part = line[0].upper()
        if part not in TARGET_PARTS:
            print(f"error: line {line_no}, position 1: invalid part letter {line[0]!r}", file=sys.stderr)
            continue
        compiler = MMLCompiler()
        parts[part] = compiler.compile_part(line[1:], line_no)
    return [(PART_LABELS[part], parts.get(part, [0x80])) for part in TARGET_PARTS]


def resolve_output_paths(args: argparse.Namespace, parser: argparse.ArgumentParser) -> tuple[Path, Path]:
    if args.output and (args.out_dir or args.wrapper):
        parser.error("-o/--output cannot be combined with --out-dir or --wrapper")

    if args.output:
        output = args.output
        if output.suffix.lower() == ".inc":
            return output.parent, output
        return output, output / "song_data.inc"

    if args.out_dir is None or args.wrapper is None:
        parser.error("output destination required: use --out-dir and --wrapper, or -o")

    return args.out_dir, args.wrapper


def incbin_path(mn_path: Path, wrapper_path: Path) -> str:
    build_cwd = wrapper_path.parent
    rel_path = os.path.relpath(mn_path, build_cwd)
    return Path(rel_path).as_posix()


def format_wrapper(
    songs: list[tuple[str, list[tuple[str, list[int]]]]],
    out_dir: Path,
    wrapper_path: Path,
) -> str:
    lines = [";;; PMDNEO compile.py generated wrapper"]
    song_labels: list[list[str]] = []
    for song_index, (basename, parts) in enumerate(songs):
        labels: list[str] = []
        for label, _data in parts:
            song_label = label.replace("song_part_", f"song{song_index}_part_")
            labels.append(song_label)
            mn_path = out_dir / basename / f"{label}.mn"
            lines.append(f'{song_label}: .incbin "{incbin_path(mn_path, wrapper_path)}"')
        song_labels.append(labels)

    lines.append("")
    lines.append("song_table:")
    for labels in song_labels:
        for start in range(0, len(labels), 4):
            lines.append(f"        .dw {', '.join(labels[start:start + 4])}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(
    songs: list[tuple[str, list[tuple[str, list[int]]]]],
    out_dir: Path,
    wrapper_path: Path,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    wrapper_path.parent.mkdir(parents=True, exist_ok=True)
    for basename, parts in songs:
        song_dir = out_dir / basename
        song_dir.mkdir(parents=True, exist_ok=True)
        for label, data in parts:
            (song_dir / f"{label}.mn").write_bytes(bytes(data))
    wrapper_path.write_text(format_wrapper(songs, out_dir, wrapper_path), encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compile PMDNEO Phase 12a-2 MML to .mn part binaries")
    parser.add_argument("input_mml", type=Path, nargs="+")
    parser.add_argument("-o", "--output", type=Path, help="compat: output dir, or wrapper .inc path")
    parser.add_argument("--out-dir", type=Path, help="directory for generated .mn part binaries")
    parser.add_argument("--wrapper", type=Path, help="generated wrapper .inc path")
    args = parser.parse_args(argv)

    out_dir, wrapper_path = resolve_output_paths(args, parser)
    songs: list[tuple[str, list[tuple[str, list[int]]]]] = []
    for input_mml in args.input_mml:
        source = input_mml.read_text(encoding="utf-8")
        songs.append((input_mml.stem, parse_mml(source)))
    write_outputs(songs, out_dir, wrapper_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
