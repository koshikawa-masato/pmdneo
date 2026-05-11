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
# ADR-0006 §H: FM3Extend 用 X/Y/Z (= ch3 4-op individual mode の追加 voice)
PART_LABELS.update({"X": "song_part_x", "Y": "song_part_y", "Z": "song_part_z"})

# ADR-0006 §A: compile.py parser は A-Q + X/Y/Z 全 20 part 文法対応
TARGET_PARTS = (
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
    "K", "L", "M", "N", "O", "P", "Q",
    "X", "Y", "Z",
)

# ADR-0006 §B: PMDNEO_TARGET_CHIP=ym2610 (default) / ym2610b (AES+ YM2610B 想定)
TARGET_CHIP = os.environ.get("PMDNEO_TARGET_CHIP", "ym2610").lower()
if TARGET_CHIP not in ("ym2610", "ym2610b"):
    print(
        f"warning: unknown PMDNEO_TARGET_CHIP={TARGET_CHIP!r}, falling back to ym2610",
        file=sys.stderr,
    )
    TARGET_CHIP = "ym2610"

# ADR-0006 §C/§G/§H: default mode で A/D に note 書込 → warning (= ADR-0001 警告規律継承)
# K (Rhythm) と X/Y/Z (FM3Extend) は両 mode で driver 未実装のため warning
if TARGET_CHIP == "ym2610":
    WARN_PARTS_NOTE = ("A", "D", "K", "X", "Y", "Z")
else:  # ym2610b
    WARN_PARTS_NOTE = ("K", "X", "Y", "Z")

MAX_LOOP_DEPTH = 4
VOICE_HEADER_RE = re.compile(r"^@(\d{3})[ \t]+(\d+)[ \t]+(\d+)$")
VOICE_SLOT_RE = re.compile(
    r"^[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)"
    r"[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]*(?:[;#].*)?$"
)

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
            elif ch == "@":
                i = self._compile_number_command(mml, i, line_no, out, 0xFF)
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


def read_mml_source(path: Path) -> str:
    # ADR-0006 §A 拡張: PMDDotNET 既存資産は Shift_JIS、 PMDNEO 新規 MML は utf-8。 両方読める fallback
    raw = path.read_bytes()
    for encoding in ("utf-8", "cp932"):
        try:
            return raw.decode(encoding)
        except UnicodeDecodeError:
            continue
    raise UnicodeDecodeError(
        "compile.py", raw, 0, len(raw),
        f"{path}: failed to decode as utf-8 or cp932 (Shift_JIS)",
    )


def parse_voice_definitions(source: str) -> tuple[dict[int, list[int]], set[int]]:
    voices: dict[int, list[int]] = {}
    skip_lines: set[int] = set()
    lines = source.splitlines()
    i = 0
    while i < len(lines):
        stripped = re.split(r"[;#]", lines[i], maxsplit=1)[0].strip()
        header = VOICE_HEADER_RE.match(stripped)
        if header is None:
            i += 1
            continue

        voice_index = int(header.group(1)) - 1
        alg = int(header.group(2))
        fbl = int(header.group(3))
        voice_data: list[int] = []
        skip_lines.add(i + 1)

        if voice_index < 0:
            print(f"error: line {i + 1}: voice number must be 001 or greater", file=sys.stderr)
            i += 1
            continue

        # ADR-0006 §A: PMDDotNET MML は header と slot の間 / slot 間に comment 行 (`;` `#`) を許す
        # 4 slot 行を集めるまで comment / blank 行を skip
        ok = True
        slots: list[tuple[int, int, int, int, int, int]] = []
        slot_idx = 0
        j = i + 1
        last_consumed = i
        while slot_idx < 4 and j < len(lines):
            raw_slot = lines[j]
            stripped_slot = raw_slot.strip()
            if not stripped_slot or stripped_slot.startswith(";") or stripped_slot.startswith("#"):
                skip_lines.add(j + 1)
                j += 1
                continue
            line_no = j + 1
            slot_match = VOICE_SLOT_RE.match(raw_slot)
            skip_lines.add(line_no)
            if slot_match is None:
                print(f"error: line {line_no}: malformed voice slot definition", file=sys.stderr)
                ok = False
                j += 1
                slot_idx += 1
                continue
            ar, dr, sr, rr, sl, tl, ks, ml, dt, ams = (int(v) for v in slot_match.groups())
            slots.append((
                ((dt & 0x0F) << 4) | (ml & 0x0F),    # reg 0x30 (DT/ML)
                tl & 0x7F,                            # reg 0x40 (TL)
                ((ks & 0x03) << 6) | (ar & 0x1F),    # reg 0x50 (KS/AR)
                ((ams & 0x01) << 7) | (dr & 0x1F),   # reg 0x60 (AMS/DR)
                sr & 0x1F,                            # reg 0x70 (SR)
                ((sl & 0x0F) << 4) | (rr & 0x0F),    # reg 0x80 (SL/RR)
            ))
            slot_idx += 1
            last_consumed = j
            j += 1

        if slot_idx < 4:
            print(f"error: line {i + 1}: incomplete voice definition (only {slot_idx} slot found)", file=sys.stderr)
            ok = False

        if ok and len(slots) == 4:
            # register-major order (= PMDNEO fm_voice_data_default 流儀踏襲)
            # 各 register × 4 slot 連続 = 6 reg × 4 slot = 24 byte + 1 byte ALG/FBL
            for reg_idx in range(6):
                for slot_idx_emit in range(4):
                    voice_data.append(slots[slot_idx_emit][reg_idx])
            voice_data.append((alg & 0x07) | ((fbl & 0x07) << 3))
            voices[voice_index] = voice_data
        i = last_consumed + 1

    return voices, skip_lines


def parse_mml(source: str) -> tuple[list[tuple[str, list[int]]], dict[int, list[int]]]:
    voices, voice_lines = parse_voice_definitions(source)
    macros: dict[str, str] = {}
    expanded_lines: list[tuple[int, str]] = []
    for line_no, raw_line in enumerate(source.splitlines(), 1):
        if line_no in voice_lines:
            continue
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
        # ADR-0006 §C/§G/§H: A/D/K/X/Y/Z に note 書込 → warning (= mode 別 WARN_PARTS_NOTE 参照)
        if part in WARN_PARTS_NOTE:
            body = line[1:].strip()
            if body and re.search(r"[a-grcdefgab]", body):
                if part == "K":
                    print(
                        f"warning: line {line_no}: part {part!r} (Rhythm = ADPCM-A drum) "
                        f"is not yet implemented in driver, will be muted (ADR-0006 §G)",
                        file=sys.stderr,
                    )
                elif part in ("X", "Y", "Z"):
                    print(
                        f"warning: line {line_no}: part {part!r} (FM3Extend = ch3 4-op individual "
                        f"mode の追加 voice) is not yet implemented in driver, will be muted "
                        f"(ADR-0006 §H、 driver 実装は将来 ADR-0008 想定)",
                        file=sys.stderr,
                    )
                else:
                    fm_ch = ord(part) - ord("A") + 1
                    print(
                        f"warning: line {line_no}: part {part!r} (FM ch{fm_ch}) requires "
                        f"PMDNEO_TARGET_CHIP=ym2610b (AES+), will be muted in default ym2610 "
                        f"mode (ADR-0001 / ADR-0006 §C)",
                        file=sys.stderr,
                    )
        compiler = MMLCompiler()
        parts[part] = compiler.compile_part(line[1:], line_no)
    return [(PART_LABELS[part], parts.get(part, [0x80])) for part in TARGET_PARTS], voices


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
    songs: list[tuple[str, list[tuple[str, list[int]]], dict[int, list[int]]]],
    out_dir: Path,
    wrapper_path: Path,
) -> str:
    lines = [";;; PMDNEO compile.py generated wrapper"]
    voices: dict[int, list[int]] = {}
    song_labels: list[list[str]] = []
    for song_index, (basename, parts, song_voices) in enumerate(songs):
        voices.update(song_voices)
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
    if voices:
        max_voice = max(voices)
        for voice_index in range(max_voice + 1):
            data = voices.get(voice_index)
            if data is None:
                continue
            lines.append(f"voice{voice_index}_data:")
            for slot in range(4):
                slot_data = data[slot * 6 : slot * 6 + 6]
                bytes_text = ", ".join(f"0x{value:02X}" for value in slot_data)
                lines.append(f"        .db {bytes_text}   ; slot{slot + 1}")
            lines.append(f"        .db 0x{data[24]:02X}                                   ; ALG/FBL")
        lines.append("voice_table:")
        for voice_index in range(max_voice + 1):
            if voice_index in voices:
                lines.append(f"        .dw voice{voice_index}_data")
            else:
                lines.append("        .dw fm_voice_data_default")
        lines.append("")
    else:
        lines.append("voice_table:")
        lines.append("")
    return "\n".join(lines)


def write_outputs(
    songs: list[tuple[str, list[tuple[str, list[int]]], dict[int, list[int]]]],
    out_dir: Path,
    wrapper_path: Path,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    wrapper_path.parent.mkdir(parents=True, exist_ok=True)
    for basename, parts, _voices in songs:
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
    songs: list[tuple[str, list[tuple[str, list[int]]], dict[int, list[int]]]] = []
    for input_mml in args.input_mml:
        source = read_mml_source(input_mml)
        parts, voices = parse_mml(source)
        songs.append((input_mml.stem, parts, voices))
    write_outputs(songs, out_dir, wrapper_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
