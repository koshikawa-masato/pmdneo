#!/usr/bin/env python3
"""PMDNEO IR Schema validator (ADR-0034 / v0.1-v0.3).

機械的検証 helper:
1. schema 自身が JSON Schema draft-2020-12 として正当か (= meta-validation)
2. 各 valid example が schema に適合するか (= positive validation)
3. 各 invalid fixture が schema validation で失敗するか (= negative validation、
   --invalid-examples 指定時のみ実行)

exit codes:
  0  = all pass (= positive 全 PASS + invalid 全 correctly rejected)
  64 = argument error (= command line / file not found / JSON parse error)
  65 = schema / data validation fail (= positive で reject、 または negative で通過)
  66 = runtime error (= unexpected exception or missing dependency)
"""

from __future__ import annotations

import argparse
import glob
import json
import sys
from pathlib import Path

EXIT_OK = 0
EXIT_ARG = 64
EXIT_VALIDATION = 65
EXIT_RUNTIME = 66

try:
    from jsonschema import Draft202012Validator
    from jsonschema.exceptions import SchemaError, ValidationError
except ImportError:
    print(
        "ERROR: jsonschema package is required. Install with: pip install jsonschema",
        file=sys.stderr,
    )
    sys.exit(EXIT_RUNTIME)


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SCHEMA = (
    REPO_ROOT
    / "docs/design/intermediate-register-command/ir-schema-v0.1.schema.json"
)
SCHEMA_BY_VERSION = {
    "v0.1": DEFAULT_SCHEMA,
    "v0.2": REPO_ROOT
    / "docs/design/intermediate-register-command/ir-schema-v0.2.schema.json",
    "v0.3": REPO_ROOT
    / "docs/design/intermediate-register-command/ir-schema-v0.3.schema.json",
}
DEFAULT_EXAMPLES_GLOB = str(
    REPO_ROOT / "docs/design/intermediate-register-command/examples/*.ir.json"
)


def _rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def _load_json(path: Path) -> dict:
    try:
        with path.open() as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"[FAIL] file not found: {_rel(path)}", file=sys.stderr)
        sys.exit(EXIT_ARG)
    except json.JSONDecodeError as e:
        print(f"[FAIL] JSON parse error in {_rel(path)}: {e}", file=sys.stderr)
        sys.exit(EXIT_ARG)


def _format_error_location(error: ValidationError) -> str:
    path = list(error.absolute_path)
    if not path:
        return "<root>"
    return "." + ".".join(str(p) for p in path)


def validate_schema(schema_path: Path) -> dict:
    schema = _load_json(schema_path)
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as e:
        print(f"[FAIL] schema meta-validation: {_rel(schema_path)}", file=sys.stderr)
        print(f"  {e.message}", file=sys.stderr)
        sys.exit(EXIT_VALIDATION)
    print(f"[PASS] schema meta-validation: {_rel(schema_path)}")
    return schema


def validate_examples(schema: dict, example_paths: list[Path]) -> tuple[int, int]:
    validator = Draft202012Validator(schema)
    failed = 0
    total = len(example_paths)
    for path in example_paths:
        data = _load_json(path)
        errors = list(validator.iter_errors(data))
        rel = _rel(path)
        if not errors:
            print(f"[PASS] {rel}")
            continue
        failed += 1
        print(f"[FAIL] {rel}: {len(errors)} error(s)", file=sys.stderr)
        for e in errors:
            loc = _format_error_location(e)
            print(f"  - {loc}: {e.message}", file=sys.stderr)
    return failed, total


def validate_invalid_fixtures(
    schema: dict, fixture_paths: list[Path]
) -> tuple[int, int]:
    """Invalid fixture が schema validation で失敗することを PASS とする。

    通過してしまった (= schema が緩い or fixture が壊れた) 場合は FAIL。
    """
    validator = Draft202012Validator(schema)
    failed = 0
    total = len(fixture_paths)
    for path in fixture_paths:
        data = _load_json(path)
        errors = list(validator.iter_errors(data))
        rel = _rel(path)
        if errors:
            rep = errors[0]
            loc = _format_error_location(rep)
            print(f"[PASS] invalid: {rel} (= rejected at {loc}: {rep.message})")
            continue
        failed += 1
        print(
            f"[FAIL] invalid: {rel} (= should have been rejected but passed validation)",
            file=sys.stderr,
        )
    return failed, total


def _minimal_ir_with_event(event: dict) -> dict:
    return {
        "metadata": {
            "magic": "PMDNEO-IR",
            "version": 1,
            "sourceDialect": "unknown",
            "createdBy": "validate-ir-schema inline FMTimerSet check",
        },
        "targetProfile": "ym2610_aes",
        "timing": {"ticksPerBeat": 192, "timeMode": "absolute"},
        "channels": [],
        "events": [event],
    }


def validate_inline_v03_fmtimerset(schema: dict) -> tuple[int, int]:
    """v0.3 FMTimerSet の最小 positive / negative を fixture file なしで検証する。"""

    validator = Draft202012Validator(schema)
    positive_event = {
        "tick": 0,
        "order": 0,
        "trackId": 0,
        "layer": "chip",
        "type": "FMTimerSet",
        "counter": 10,
        "bpm": 120,
    }

    failed = 0
    total = 0

    total += 1
    positive_errors = list(
        validator.iter_errors(_minimal_ir_with_event(positive_event))
    )
    if positive_errors:
        failed += 1
        print(
            "[FAIL] inline v0.3 FMTimerSet positive "
            "(counter=10, bpm=120)",
            file=sys.stderr,
        )
        for e in positive_errors:
            print(f"  - {_format_error_location(e)}: {e.message}", file=sys.stderr)
    else:
        print("[PASS] inline v0.3 FMTimerSet positive (counter=10, bpm=120)")

    negative_cases = [
        ("counter=-1", {**positive_event, "counter": -1}),
        ("counter=256", {**positive_event, "counter": 256}),
        (
            "counter missing",
            {k: v for k, v in positive_event.items() if k != "counter"},
        ),
        ("type violation", {**positive_event, "type": "FMTimerSetX"}),
        ("layer violation", {**positive_event, "layer": "semantic"}),
    ]
    for label, event in negative_cases:
        total += 1
        errors = list(validator.iter_errors(_minimal_ir_with_event(event)))
        if errors:
            rep = errors[0]
            print(
                f"[PASS] inline v0.3 FMTimerSet negative: {label} "
                f"(= rejected at {_format_error_location(rep)}: {rep.message})"
            )
            continue
        failed += 1
        print(
            f"[FAIL] inline v0.3 FMTimerSet negative: {label} "
            "(= should have been rejected but passed validation)",
            file=sys.stderr,
        )

    return failed, total


def main() -> int:
    parser = argparse.ArgumentParser(
        description="PMDNEO IR Schema validator (ADR-0034 / v0.1-v0.3)",
    )
    parser.add_argument(
        "--schema-version",
        choices=sorted(SCHEMA_BY_VERSION),
        default="v0.1",
        help="known schema version shortcut (default: v0.1、 --schema 指定時は --schema が優先)",
    )
    parser.add_argument(
        "--schema",
        type=Path,
        default=None,
        help=(
            "schema file path "
            f"(default: --schema-version に対応する schema、 v0.1={_rel(DEFAULT_SCHEMA)})"
        ),
    )
    parser.add_argument(
        "--examples",
        default=DEFAULT_EXAMPLES_GLOB,
        help="valid examples glob pattern (default: examples/*.ir.json)",
    )
    parser.add_argument(
        "--invalid-examples",
        default=None,
        help="invalid fixtures glob pattern (= 全件が schema validation で失敗することが PASS 条件、 default は実行しない)",
    )
    parser.add_argument(
        "--inline-v0.3-fmtimerset-check",
        dest="inline_v03_fmtimerset_check",
        action="store_true",
        help=(
            "fixture file を作らず、 FMTimerSet positive 1 件 + negative 5 件 "
            "(counter=-1/256/欠落、 type/layer 違反) を inline 検証する"
        ),
    )
    args = parser.parse_args()

    schema_path = args.schema or SCHEMA_BY_VERSION[args.schema_version]
    if not schema_path.exists():
        print(f"[FAIL] schema file not found: {_rel(schema_path)}", file=sys.stderr)
        return EXIT_ARG

    schema = validate_schema(schema_path)

    total_failed = 0

    example_paths = sorted(Path(p) for p in glob.glob(args.examples))
    if not example_paths:
        print(
            f"[FAIL] no valid examples matched pattern: {args.examples} "
            f"(= 0-match は silent pass を防ぐため EXIT_ARG として扱う)",
            file=sys.stderr,
        )
        return EXIT_ARG
    failed, total = validate_examples(schema, example_paths)
    total_failed += failed
    print(f"\nValid examples: {total - failed}/{total} passed")

    if args.invalid_examples:
        invalid_paths = sorted(Path(p) for p in glob.glob(args.invalid_examples))
        if not invalid_paths:
            print(
                f"[FAIL] no invalid fixtures matched pattern: {args.invalid_examples} "
                f"(= 0-match は silent pass を防ぐため EXIT_ARG として扱う)",
                file=sys.stderr,
            )
            return EXIT_ARG
        failed, total = validate_invalid_fixtures(schema, invalid_paths)
        total_failed += failed
        print(
            f"Invalid fixtures: {total - failed}/{total} correctly rejected"
        )

    if args.inline_v03_fmtimerset_check:
        failed, total = validate_inline_v03_fmtimerset(schema)
        total_failed += failed
        print(f"Inline FMTimerSet checks: {total - failed}/{total} passed")

    return EXIT_OK if total_failed == 0 else EXIT_VALIDATION


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
