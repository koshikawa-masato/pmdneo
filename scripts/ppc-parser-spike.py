#!/usr/bin/env python3
# scripts/ppc-parser-spike.py
#
# PMDNEO 軸 G sub-sprint β = .PPC parser / validator proof spike + minimum fixture 生成
# (= ADR-0048 §決定 1 β / Annex A-1〜A-4 spec literal + A-7 β validator reject 条件 5 件、
#    doc-only sprint = driver / runtime / vendor 完全不変、 standard library only)
#
# usage: python3 scripts/ppc-parser-spike.py
#
# 出力: emit minimum fixture → parse round-trip verify → reject 5 件 verify、 all PASS / FAIL 集計。
# 終了 code: 0 = all PASS、 非 0 = FAIL 件数。

import struct
import sys
from dataclasses import dataclass
from typing import Optional

# --- ADR-0048 Annex A spec literal 定数 ---

PPC_SIGNATURE_FULL = b"ADPCM DATA for  PMD ver.4.4-  "
PPC_MAGIC_PREFIX = b"ADPCM "
PPC_HEADER_SIZE = 30
PPC_NEXT_START_OFS = 0x1E
PPC_DIRECTORY_OFS = 0x20
PPC_DIRECTORY_ENTRIES = 256
PPC_DIRECTORY_ENTRY_SIZE = 4
PPC_DIRECTORY_SIZE = PPC_DIRECTORY_ENTRIES * PPC_DIRECTORY_ENTRY_SIZE
PPC_PCM_DATA_OFS = PPC_DIRECTORY_OFS + PPC_DIRECTORY_SIZE
PPC_PVI_MAGIC = b"PVI2"

assert PPC_HEADER_SIZE == 30
assert PPC_DIRECTORY_OFS == 0x20
assert PPC_DIRECTORY_SIZE == 1024
assert PPC_PCM_DATA_OFS == 0x420


@dataclass
class DirectoryEntry:
    start: int
    stop: int

    @property
    def is_unused(self) -> bool:
        return self.start == 0 and self.stop == 0

    @property
    def is_valid_range(self) -> bool:
        return self.start <= self.stop


@dataclass
class PpcImage:
    signature: bytes
    next_start: int
    entries: list[DirectoryEntry]
    pcm_data: bytes


# --- emitter (= ADR-0048 Annex A-7 imagined byte sequence の Python 実体化) ---

def emit_minimum_fixture(entries: list[DirectoryEntry], pcm_data: bytes,
                          next_start: Optional[int] = None) -> bytes:
    if len(entries) > PPC_DIRECTORY_ENTRIES:
        raise ValueError(f"entries count {len(entries)} > {PPC_DIRECTORY_ENTRIES}")
    if next_start is None:
        last_used = max((e.stop for e in entries if not e.is_unused), default=0)
        next_start = last_used
    buf = bytearray()
    sig = (PPC_SIGNATURE_FULL + b"\x00" * PPC_HEADER_SIZE)[:PPC_HEADER_SIZE]
    buf += sig
    buf += struct.pack("<H", next_start)
    for i in range(PPC_DIRECTORY_ENTRIES):
        if i < len(entries):
            e = entries[i]
        else:
            e = DirectoryEntry(0, 0)
        buf += struct.pack("<HH", e.start, e.stop)
    assert len(buf) == PPC_PCM_DATA_OFS, f"header size {len(buf)} != {PPC_PCM_DATA_OFS}"
    buf += pcm_data
    return bytes(buf)


# --- parser (= ADR-0048 Annex A-1〜A-4 spec literal を Python で実装) ---

class PpcRejectError(ValueError):
    pass


def parse_ppc(data: bytes) -> PpcImage:
    if len(data) < PPC_HEADER_SIZE:
        raise PpcRejectError(f"size < {PPC_HEADER_SIZE} (= header signature 未満)")
    if data[:4] == PPC_PVI_MAGIC and len(data) > 10 and data[10] == 2:
        raise PpcRejectError("PVI2 magic detected at offset 0 = scope-out 別 path (= .PVI)")
    if data[:len(PPC_MAGIC_PREFIX)] != PPC_MAGIC_PREFIX:
        raise PpcRejectError(f"magic mismatch (= 先頭 6 byte != {PPC_MAGIC_PREFIX!r})")
    if len(data) < PPC_PCM_DATA_OFS:
        raise PpcRejectError(f"size < {PPC_PCM_DATA_OFS} (= directory + signature 未満)")
    signature = data[:PPC_HEADER_SIZE]
    next_start = struct.unpack("<H", data[PPC_NEXT_START_OFS:PPC_NEXT_START_OFS + 2])[0]
    entries: list[DirectoryEntry] = []
    for i in range(PPC_DIRECTORY_ENTRIES):
        ofs = PPC_DIRECTORY_OFS + i * PPC_DIRECTORY_ENTRY_SIZE
        start, stop = struct.unpack("<HH", data[ofs:ofs + 4])
        entries.append(DirectoryEntry(start, stop))
    pcm_data = data[PPC_PCM_DATA_OFS:]
    return PpcImage(signature=signature, next_start=next_start,
                    entries=entries, pcm_data=pcm_data)


# --- validator (= ADR-0048 Annex A-7 β reject 条件 5 件 literal 検証) ---

@dataclass
class ValidationReport:
    reject_invalid_range: list[int]
    reject_stop_exceeds_next_start: list[int]
    skip_unused: list[int]
    warn_aliasing: list[tuple[int, int]]
    note_next_start_scale_pending: bool


def validate_ppc(image: PpcImage) -> ValidationReport:
    invalid_range: list[int] = []
    stop_exceeds: list[int] = []
    unused: list[int] = []
    range_to_indices: dict[tuple[int, int], list[int]] = {}
    for i, e in enumerate(image.entries):
        if e.is_unused:
            unused.append(i)
            continue
        if not e.is_valid_range:
            invalid_range.append(i)
            continue
        if e.stop > image.next_start:
            stop_exceeds.append(i)
        key = (e.start, e.stop)
        range_to_indices.setdefault(key, []).append(i)
    aliasing: list[tuple[int, int]] = []
    for _key, indices in range_to_indices.items():
        if len(indices) > 1:
            for a in indices[1:]:
                aliasing.append((indices[0], a))
    return ValidationReport(
        reject_invalid_range=invalid_range,
        reject_stop_exceeds_next_start=stop_exceeds,
        skip_unused=unused,
        warn_aliasing=aliasing,
        note_next_start_scale_pending=True,
    )


# --- self-test (= round-trip + reject 5 件 verify) ---

def make_pcm_filler(size: int) -> bytes:
    return bytes((i & 0x7F) for i in range(size))


def case_minimum_fixture_round_trip() -> tuple[bool, str]:
    entries = [
        DirectoryEntry(start=0x0400, stop=0x0480),
        DirectoryEntry(start=0x0480, stop=0x0500),
    ]
    pcm = make_pcm_filler(0x100)
    data = emit_minimum_fixture(entries, pcm, next_start=0x0500)
    image = parse_ppc(data)
    if image.signature[:6] != PPC_MAGIC_PREFIX:
        return False, f"signature prefix mismatch: {image.signature[:6]!r}"
    if image.next_start != 0x0500:
        return False, f"next_start mismatch: 0x{image.next_start:04X} != 0x0500"
    if image.entries[0].start != 0x0400 or image.entries[0].stop != 0x0480:
        return False, f"entry 0 mismatch: {image.entries[0]}"
    if image.entries[1].start != 0x0480 or image.entries[1].stop != 0x0500:
        return False, f"entry 1 mismatch: {image.entries[1]}"
    if image.entries[2].start != 0 or image.entries[2].stop != 0:
        return False, "entry 2 should be unused"
    if image.pcm_data != pcm:
        return False, "pcm data round-trip mismatch"
    return True, "ok"


def case_reject_too_short() -> tuple[bool, str]:
    try:
        parse_ppc(b"ADPCM ")
        return False, "expected reject but accepted"
    except PpcRejectError:
        return True, "reject ok"


def case_reject_wrong_magic() -> tuple[bool, str]:
    bad = b"BADMAG" + bytes(PPC_PCM_DATA_OFS - 6)
    try:
        parse_ppc(bad)
        return False, "expected reject but accepted"
    except PpcRejectError:
        return True, "reject ok"


def case_reject_under_directory() -> tuple[bool, str]:
    short = (PPC_SIGNATURE_FULL[:PPC_HEADER_SIZE]
             + b"\x00\x00"
             + b"\x00" * (PPC_PCM_DATA_OFS - PPC_HEADER_SIZE - 2 - 1))
    try:
        parse_ppc(short)
        return False, "expected reject (size < 0x420) but accepted"
    except PpcRejectError:
        return True, "reject ok"


def case_reject_pvi2_scope_out() -> tuple[bool, str]:
    pvi = b"PVI2" + b"\x00" * 6 + b"\x02" + b"\x00" * (PPC_PCM_DATA_OFS - 11)
    try:
        parse_ppc(pvi)
        return False, "expected reject (PVI2 scope-out) but accepted"
    except PpcRejectError:
        return True, "reject ok"


def case_validator_invalid_range_and_aliasing() -> tuple[bool, str]:
    entries = [
        DirectoryEntry(start=0x0400, stop=0x0480),
        DirectoryEntry(start=0x0400, stop=0x0480),
        DirectoryEntry(start=0x0500, stop=0x0480),
        DirectoryEntry(start=0x0480, stop=0x0500),
        DirectoryEntry(start=0x0500, stop=0x0600),
    ]
    pcm = make_pcm_filler(0x200)
    data = emit_minimum_fixture(entries, pcm, next_start=0x0500)
    image = parse_ppc(data)
    report = validate_ppc(image)
    if report.reject_invalid_range != [2]:
        return False, f"expected invalid_range=[2] got {report.reject_invalid_range}"
    if (0, 1) not in report.warn_aliasing:
        return False, f"expected aliasing (0,1) in {report.warn_aliasing}"
    if report.reject_stop_exceeds_next_start != [4]:
        return False, f"expected stop_exceeds=[4] got {report.reject_stop_exceeds_next_start}"
    if 0 in report.skip_unused or 1 in report.skip_unused:
        return False, "used entries leaked into skip_unused"
    if not report.note_next_start_scale_pending:
        return False, "next_start_scale should be marked pending (γ で確定)"
    return True, "ok"


CASES = [
    ("minimum_fixture_round_trip", case_minimum_fixture_round_trip),
    ("reject_too_short", case_reject_too_short),
    ("reject_wrong_magic", case_reject_wrong_magic),
    ("reject_under_directory", case_reject_under_directory),
    ("reject_pvi2_scope_out", case_reject_pvi2_scope_out),
    ("validator_invalid_range_and_aliasing", case_validator_invalid_range_and_aliasing),
]


def main() -> int:
    fail_count = 0
    for name, fn in CASES:
        try:
            ok, detail = fn()
        except Exception as e:
            ok, detail = False, f"exception: {type(e).__name__}: {e}"
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {name}: {detail}")
        if not ok:
            fail_count += 1
    print(f"--- summary: {len(CASES) - fail_count}/{len(CASES)} PASS ---")
    return fail_count


if __name__ == "__main__":
    sys.exit(main())
