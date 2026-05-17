#!/usr/bin/env python3
"""
audition_pairwise.py = π15 越川氏 pairwise audition + reject 入力 + 逐次保存 helper

ADR-0033 §決定 27 (12) π15 = preference learning (= NOT metric calibration)。
preference-input.yaml の未入力 pair を順番に afplay + 入力受付 + 逐次書き戻し。
中断 (= Q) しても save 済、 再起動で残り pair から再開可能。

Usage:
    python3 scripts/audition_pairwise.py \\
        docs/design/rhythm-patches/synth/preference-input.yaml

Optional:
    --no-backup        起動時の .bak 作成を抑制
    --skip-rejected    最後の reject prompt を skip
    --sleep-between    A → B 再生間の sleep 秒 (default 0.3)

Operation per pair:
    A 再生 → B 再生 → prompt 入力
    [A] = A が好み (= winner)
    [B] = B が好み (= winner)
    [T] = tie
    [R] = A B 再生し直し
    [S] = この pair を skip (= preference 未確定で次へ)
    [Q] = save して終了 (= 残り pair は未入力のまま)

逐次保存 = 各入力後 (= A / B / T) に input.yaml を rewrite。
PyYAML round-trip で comment / key 順は失われるが、 audition 後の input.yaml は
preference-learn subcommand 入力としてのみ使うため運用上問題なし。
.bak ファイルが backup。

driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変。
"""

from __future__ import annotations

import argparse
import datetime
import shutil
import subprocess
import sys
import time
from pathlib import Path

try:
    import yaml
except ImportError:
    print("error: PyYAML 必須 (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)


EXIT_OK = 0
EXIT_ARG_ERROR = 64
EXIT_DATA_ERROR = 65
EXIT_USER_QUIT = 0


def load_yaml(path: Path) -> dict:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def save_yaml(path: Path, data: dict) -> None:
    path.write_text(
        yaml.safe_dump(data, allow_unicode=True, sort_keys=False, width=120),
        encoding="utf-8",
    )


def find_candidate_wav(candidates: list[dict], cid: str) -> Path | None:
    for c in candidates:
        if c.get("id") == cid:
            return Path(c["wav"]).expanduser()
    return None


def play_wav(wav: Path) -> None:
    if not wav.exists():
        print(f"  [skip] wav not found: {wav}", file=sys.stderr)
        return
    try:
        subprocess.run(["afplay", str(wav)], check=False)
    except FileNotFoundError:
        print("  [error] afplay not found (macOS 専用)", file=sys.stderr)
        raise SystemExit(EXIT_DATA_ERROR)


def prompt_choice(prompt: str, valid: set[str]) -> str:
    while True:
        try:
            raw = input(prompt).strip().upper()
        except EOFError:
            return "Q"
        except KeyboardInterrupt:
            print("\n  [interrupted] = save & quit", file=sys.stderr)
            return "Q"
        if raw in valid:
            return raw
        print(f"  invalid input ({raw!r})、 {sorted(valid)} のいずれかを入力してください")


def audition_loop(
    input_path: Path,
    sleep_between: float,
) -> tuple[int, int, int]:
    """Returns (answered_count, skipped_count, quit_flag)。 quit_flag=1 means user Q。"""
    data = load_yaml(input_path)
    candidates = data.get("candidates", [])
    prefs = data.get("preferences") or {}
    pairs = prefs.get("pairs", [])

    if not pairs:
        print("error: preferences.pairs が空", file=sys.stderr)
        return (0, 0, 1)

    total = len(pairs)
    pending = [i for i, p in enumerate(pairs) if p.get("preference") not in ("A", "B", "tie")]
    already_filled = total - len(pending)

    print()
    print(f"=== Pairwise audition ===")
    print(f"  input  : {input_path}")
    print(f"  pairs  : {total} total")
    print(f"  filled : {already_filled} (skipping)")
    print(f"  todo   : {len(pending)}")
    print()
    print("操作: A=好み A / B=好み B / T=tie / R=replay / S=skip / Q=save & quit")
    print()

    answered = 0
    skipped = 0
    quit_flag = 0

    for idx in pending:
        pair = pairs[idx]
        pid = pair.get("id", f"pair_{idx + 1:02d}")
        a_id, b_id = pair["candidates"]
        a_wav = find_candidate_wav(candidates, a_id)
        b_wav = find_candidate_wav(candidates, b_id)

        if a_wav is None or b_wav is None:
            print(f"  [{pid}] {a_id} or {b_id} の wav 未登録、 skip")
            skipped += 1
            continue

        progress = f"[{answered + skipped + 1}/{len(pending)}]"
        print(f"--- {progress} {pid}: A={a_id}  vs  B={b_id} ---")

        while True:
            print(f"  A: {a_wav.name}")
            play_wav(a_wav)
            if sleep_between > 0:
                time.sleep(sleep_between)
            print(f"  B: {b_wav.name}")
            play_wav(b_wav)

            choice = prompt_choice(
                "  choice [A/B/T/R/S/Q]: ",
                {"A", "B", "T", "R", "S", "Q"},
            )

            if choice == "R":
                continue
            if choice == "S":
                print(f"  → skip {pid}")
                skipped += 1
                break
            if choice == "Q":
                quit_flag = 1
                break

            pref_label = {"A": "A", "B": "B", "T": "tie"}[choice]
            pair["preference"] = pref_label
            save_yaml(input_path, data)
            answered += 1
            print(f"  → {pid}.preference = {pref_label!r} (saved)")
            break

        if quit_flag:
            break

    return (answered, skipped, quit_flag)


def reject_prompt(input_path: Path) -> int:
    """Last reject prompt。 越川氏 が「BD として明らかに不可」 candidate id を space 区切で入力。"""
    data = load_yaml(input_path)
    candidates = data.get("candidates", [])
    prefs = data.get("preferences") or {}
    current_rejected = prefs.get("rejected") or []

    print()
    print("=== Reject input ===")
    print(f"  candidate IDs:")
    for c in candidates:
        marker = "  [REJECTED]" if c["id"] in current_rejected else ""
        print(f"    - {c['id']}{marker}")
    print()
    print('  "BD として明らかに不可" な candidate id を space 区切で入力 (例: candidate_02 candidate_07)')
    print('  既存 rejected list を保持 + 追加する場合は同じ id も再入力可。')
    print('  reject なしは Enter のみ。')
    try:
        raw = input("  rejected: ").strip()
    except (EOFError, KeyboardInterrupt):
        print("\n  [interrupted] = reject input skip")
        return 0

    if not raw:
        print("  → reject 入力なし (current rejected 維持)")
        return 0

    new_rejected = sorted(set(raw.split()))
    valid_ids = {c["id"] for c in candidates}
    unknown = [r for r in new_rejected if r not in valid_ids]
    if unknown:
        print(f"  [warn] unknown ids: {unknown}、 skip")
        new_rejected = [r for r in new_rejected if r in valid_ids]

    prefs["rejected"] = new_rejected
    data["preferences"] = prefs
    save_yaml(input_path, data)
    print(f"  → rejected = {new_rejected} (saved)")
    return len(new_rejected)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="π15 越川氏 pairwise audition + reject 入力 + 逐次保存",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="(driver / fixture / verify script 軸完全不変)",
    )
    parser.add_argument(
        "input",
        type=Path,
        help="preference-input.yaml path (= ADR-0033 §決定 27 (12) π15 deliverable 2)",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="起動時の .bak backup を作らない (= default は input.yaml.bak 作成)",
    )
    parser.add_argument(
        "--skip-rejected",
        action="store_true",
        help="最後の reject prompt を skip",
    )
    parser.add_argument(
        "--sleep-between",
        type=float,
        default=0.3,
        help="A → B 再生間の sleep 秒 (default 0.3)",
    )
    args = parser.parse_args()

    if not args.input.exists():
        print(f"error: input not found: {args.input}", file=sys.stderr)
        return EXIT_ARG_ERROR

    if not args.no_backup:
        bak = args.input.with_suffix(args.input.suffix + ".bak")
        shutil.copy2(args.input, bak)
        print(f"[backup] {bak}")

    start = datetime.datetime.now()
    answered, skipped, quit_flag = audition_loop(args.input, args.sleep_between)
    elapsed = datetime.datetime.now() - start

    rejected_added = 0
    if not args.skip_rejected and not quit_flag:
        rejected_added = reject_prompt(args.input)

    print()
    print("=== Summary ===")
    print(f"  answered : {answered}")
    print(f"  skipped  : {skipped}")
    print(f"  rejected : {rejected_added} (this session input)")
    print(f"  elapsed  : {elapsed.total_seconds():.1f} s")
    print(f"  saved    : {args.input}")
    print()
    if quit_flag:
        print("  [Q] 中断保存。 再起動で残り pair から再開可能。")
    else:
        print("  完了。 次の step:")
        print(f"    python3 scripts/feature_search.py preference-learn \\")
        print(f"        {args.input} \\")
        print(f"        --output docs/design/rhythm-patches/synth/preference-model-report.yaml")
    print()
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
