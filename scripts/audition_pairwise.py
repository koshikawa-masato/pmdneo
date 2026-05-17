#!/usr/bin/env python3
"""
audition_pairwise.py = π15 越川氏 pairwise audition + absolute acceptance gate helper

ADR-0033 §決定 27 (12) π15 = preference learning (= NOT metric calibration)。
π15.5 corrective で 3 軸独立 protocol 確立:
  axis 1 = pairwise relative ranking (= preferences.pairs、 A is better than B)
  axis 2 = individual absolute acceptance (= acceptance_status.accepted/rejected_candidates)
  axis 3 = global reject all (= acceptance_status.global_reject_all)
relative preference (= A is better than B) ≠ candidate acceptance (= A is acceptable)。
pairwise ranking is auxiliary / acceptance gate is absolute / 越川氏 gate authoritative。

preference-input.yaml の未入力 pair を順番に afplay + 入力受付 + 逐次書き戻し。
最後に absolute acceptance prompt (= 一括 reject Y/N + 個別 acceptance) で acceptance_status 確定。
中断 (= Q) しても save 済、 再起動で残り pair から再開可能。

Usage:
    python3 scripts/audition_pairwise.py \\
        docs/design/rhythm-patches/synth/preference-input.yaml

Optional:
    --no-backup           起動時の .bak 作成を抑制
    --skip-acceptance     最後の absolute acceptance prompt を skip
    --sleep-between       A → B 再生間の sleep 秒 (default 0.3)

Operation per pair (= axis 1 relative ranking):
    A 再生 → B 再生 → prompt 入力
    [A] = A が pairwise でマシ (= relative ranking、 NOT acceptance)
    [B] = B が pairwise でマシ
    [T] = tie (= pairwise で差がない)
    [R] = A B 再生し直し
    [S] = この pair を skip (= preference 未確定で次へ)
    [Q] = save して終了 (= 残り pair は未入力のまま)

Final acceptance prompt (= axis 2 + axis 3):
    Step A: 全 candidate を BD として採用不可 (= 全 reject) ですか? [Y/N/S]
        Y → global_reject_all = true
        N → Step B へ
        S → acceptance gate skip
    Step B: 各 candidate を [A=accept / R=reject / S=skip] で個別判定

逐次保存 = 各入力後に input.yaml を rewrite。 PyYAML round-trip で comment / key
順は失われるが、 audition 後の input.yaml は preference-learn subcommand 入力として
のみ使うため運用上問題なし。 .bak ファイルが backup。

global_reject_all = true の場合、 後段 preference-learn subcommand は EXIT_INVALID_STATE
(= 67) で training skip、 「新規 candidate set 生成 + audition v2」 を案内。

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


def acceptance_prompt(input_path: Path) -> dict:
    """
    Absolute acceptance gate prompt (= π15.5 corrective、 3 軸独立 protocol axis 2 + axis 3)。

    relative preference (= preferences.pairs) と absolute acceptance を別軸として記録。
    Step A = 「全 candidate を BD として reject か?」 一括 prompt (= axis 3 global reject)。
    Step B (= A=N の場合のみ) = 各 candidate 個別 acceptance prompt (= axis 2 individual gate)。

    結果は acceptance_status section に save、 preferences.pairs (= axis 1 relative ranking)
    とは独立の軸として扱う。
    """
    data = load_yaml(input_path)
    candidates = data.get("candidates", [])

    print()
    print("=== Absolute acceptance gate ===")
    print('  注意: relative preference (= 上記 pairwise A/B/tie) ≠ candidate acceptance')
    print('  「A は B よりマシ」 と「A は BD として採用可能」 は別軸です。')
    print()
    print('  Step A: 全 candidate を BD として **採用不可** ですか? (= 全 reject)')
    choice_a = prompt_choice("  全 candidate reject [Y/N/S=skip]: ", {"Y", "N", "S"})

    if choice_a == "S":
        print("  → acceptance gate skip (= acceptance_status 未更新)")
        return {"updated": False}

    accepted: list[str] = []
    rejected: list[str] = []
    global_reject_all = False

    if choice_a == "Y":
        global_reject_all = True
        rejected = [c["id"] for c in candidates]
        print(f"  → global_reject_all = true、 rejected = 全 {len(rejected)} candidate")
    else:
        # Step B: 個別 acceptance prompt
        print()
        print("  Step B: 各 candidate を個別判定 [A=accept / R=reject / S=skip]")
        for c in candidates:
            cid = c["id"]
            choice_b = prompt_choice(f"    {cid} : ", {"A", "R", "S"})
            if choice_b == "A":
                accepted.append(cid)
            elif choice_b == "R":
                rejected.append(cid)
        print(f"  → accepted = {accepted}")
        print(f"  → rejected = {rejected}")

    acceptance_status = {
        "global_reject_all": global_reject_all,
        "accepted_candidates": accepted,
        "rejected_candidates": rejected,
        "notes": (
            "acceptance gate via audition_pairwise.py acceptance_prompt (= absolute axis、 "
            "preferences.pairs の relative ranking とは独立)。 relative preference ≠ candidate "
            "acceptance / pairwise ranking is auxiliary to acceptance gate / preference model is "
            "not the accepted asset selector / 越川氏 aesthetic gate is authoritative。"
        ),
    }
    data["acceptance_status"] = acceptance_status
    save_yaml(input_path, data)
    return {
        "updated": True,
        "global_reject_all": global_reject_all,
        "accepted_count": len(accepted),
        "rejected_count": len(rejected),
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="π15 越川氏 pairwise audition + absolute acceptance gate + 逐次保存 (= 3 軸独立 protocol)",
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
        "--skip-acceptance",
        action="store_true",
        help="最後の absolute acceptance prompt を skip (= axis 2/3 未記録)",
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

    acceptance_result: dict = {"updated": False}
    if not args.skip_acceptance and not quit_flag:
        acceptance_result = acceptance_prompt(args.input)

    print()
    print("=== Summary ===")
    print(f"  answered (pairwise) : {answered}")
    print(f"  skipped  (pairwise) : {skipped}")
    if acceptance_result.get("updated"):
        gra = acceptance_result.get("global_reject_all", False)
        if gra:
            print(f"  acceptance          : global_reject_all = true")
        else:
            print(
                f"  acceptance          : accepted={acceptance_result.get('accepted_count', 0)} / "
                f"rejected={acceptance_result.get('rejected_count', 0)}"
            )
    else:
        print(f"  acceptance          : (skipped、 未記録)")
    print(f"  elapsed             : {elapsed.total_seconds():.1f} s")
    print(f"  saved               : {args.input}")
    print()
    print("  注意: relative preference (= pairwise A/B/tie) ≠ candidate acceptance")
    print("        pairwise ranking is auxiliary to acceptance gate")
    print()
    if quit_flag:
        print("  [Q] 中断保存。 再起動で残り pair から再開可能。")
    else:
        print("  完了。 次の step:")
        print(f"    python3 scripts/feature_search.py preference-learn \\")
        print(f"        {args.input} \\")
        print(f"        --output docs/design/rhythm-patches/synth/preference-model-report.yaml")
        print()
        print("  global_reject_all = true の場合は preference-learn が EXIT_INVALID_STATE")
        print("  (= exit 67) で training skip、 「新規 candidate set 生成 + audition v2」 を案内。")
    print()
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
