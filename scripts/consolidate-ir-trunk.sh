#!/usr/bin/env bash
# consolidate-ir-trunk.sh
#
# IR 軸 (= ADR-0034 ~ ADR-0040、 27-30 session 8 PR + 11 wip-ir-* branch) を独立 branch wip-ir-trunk に集約する script。
# 30th session 末 user 判断 = 案 2 採用 (= IR 軸専用 branch に集約、 開発本拠地 wip-pmddotnet-opnb-extension は touch なし)。
#
# 処理:
#   1. wip-ir-fm3mode-raw-lowering-impl (= 30 δ 最終 branch、 14 commit 全部含む) の現状 verify
#   2. wip-ir-trunk を 30 δ branch から新規作成 + push
#   3. PR #6-#13 を close (= comment 付き、 branch 維持)
#   4. 現在 branch を wip-ir-trunk に移動 (= 削除前 safe 化)
#   5. 旧 wip-ir-* branch 11 個を削除 (= local + remote、 --keep-old-branches 指定時は skip)
#   6. 最終 verify
#
# 使い方:
#   ./scripts/consolidate-ir-trunk.sh                        # 本番実行 (= 確認 prompt 付き)
#   ./scripts/consolidate-ir-trunk.sh --dry-run              # 何が起きるか出力のみ
#   ./scripts/consolidate-ir-trunk.sh --branch-only          # wip-ir-trunk 作成のみ、 PR close + 旧 branch 削除 skip
#   ./scripts/consolidate-ir-trunk.sh --keep-old-branches    # 旧 wip-ir-* branch を削除せず残す
#   ./scripts/consolidate-ir-trunk.sh --help                 # この help を表示
#
# 前提:
#   - gh CLI 2.x 以降 + admin:repo scope 認証済
#   - git remote origin = koshikawa-masato/pmdneo
#   - 現在 branch が wip-ir-fm3mode-raw-lowering-impl (= 30 δ 最終) であること

set -euo pipefail

# --- mode parsing ---
MODE="apply"
KEEP_OLD_BRANCHES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --branch-only) MODE="branch-only"; shift ;;
    --keep-old-branches) KEEP_OLD_BRANCHES=true; shift ;;
    --help|-h)
      grep -E "^# " "$0" | sed -E 's/^# ?//'
      exit 0
      ;;
    *)
      echo "[FAIL] unknown arg: $1" >&2
      echo "usage: $0 [--dry-run|--branch-only|--keep-old-branches]" >&2
      exit 64
      ;;
  esac
done

# --- 定数 ---
SOURCE_BRANCH="wip-ir-fm3mode-raw-lowering-impl"
TRUNK_BRANCH="wip-ir-trunk"

OPEN_PRS=(6 7 8 9 10 11 12 13)

OLD_BRANCHES=(
  "wip-intermediate-register-command"
  "wip-ir-chipevent-lowering"
  "wip-ir-raw-register-lowering"
  "wip-ir-v0.3-fmtimerset-tempo-lowering"
  "wip-ir-v0.3-fmtimerset-tempo-lowering-impl"
  "wip-ir-v0.4-fm3mode-lowering"
  "wip-ir-v0.4-fm3mode-lowering-impl"
  "wip-ir-v0.5-rmw-mask-event"
  "wip-ir-v0.5-rmw-mask-event-impl"
  "wip-ir-fm3mode-raw-lowering"
  "wip-ir-fm3mode-raw-lowering-impl"
)

PR_CLOSE_COMMENT="案 2 採用 (= 30th session 末 user 判断): IR 軸を独立 branch wip-ir-trunk に集約。 本 PR の commit は全て wip-ir-trunk に含まれます。 review 経緯 (= Codex 自律壁打ち round 記録 / Approve 履歴) は close 後も本 PR ページに保存。 開発本拠地 wip-pmddotnet-opnb-extension は touch しません。 将来 .NEO コンテナ軸着手時に wip-ir-trunk から取り出して使う想定。"

# --- repo 自動検出 ---
ORIGIN_URL="$(git remote get-url origin 2>/dev/null || echo "")"
if [[ -z "$ORIGIN_URL" ]]; then
  echo "[FAIL] git remote 'origin' not found" >&2
  exit 64
fi
REPO_PATH="$(echo "$ORIGIN_URL" | sed -E 's#^.*github.com[:/]([^/]+/[^/.]+)(\.git)?$#\1#')"
echo "[info] repo = $REPO_PATH" >&2

# --- gh CLI / auth 確認 ---
if ! command -v gh > /dev/null 2>&1; then
  echo "[FAIL] gh CLI not installed" >&2
  exit 64
fi
if ! gh auth status > /dev/null 2>&1; then
  echo "[FAIL] gh CLI not authenticated (= run: gh auth login)" >&2
  exit 64
fi

# --- 現状 verify ---
CURRENT_BRANCH="$(git branch --show-current)"
echo "[info] current branch = $CURRENT_BRANCH" >&2

if ! git rev-parse --verify "$SOURCE_BRANCH" > /dev/null 2>&1; then
  echo "[FAIL] source branch '$SOURCE_BRANCH' not found locally" >&2
  exit 64
fi

SOURCE_HEAD="$(git rev-parse "$SOURCE_BRANCH")"
SOURCE_COMMIT_COUNT="$(git rev-list --count wip-pmddotnet-opnb-extension..$SOURCE_BRANCH 2>/dev/null || echo "?")"
echo "[info] source branch = $SOURCE_BRANCH ($SOURCE_HEAD)" >&2
echo "[info] commits since wip-pmddotnet-opnb-extension = $SOURCE_COMMIT_COUNT" >&2

if git rev-parse --verify "$TRUNK_BRANCH" > /dev/null 2>&1; then
  echo "[FAIL] trunk branch '$TRUNK_BRANCH' already exists locally — abort to avoid overwrite" >&2
  echo "  既存 trunk branch を削除する場合: git branch -D $TRUNK_BRANCH && git push origin --delete $TRUNK_BRANCH" >&2
  exit 1
fi

# --- 実行内容の事前表示 ---
echo "" >&2
echo "=== 実行計画 ===" >&2
echo "  mode: $MODE" >&2
echo "  keep_old_branches: $KEEP_OLD_BRANCHES" >&2
echo "  source: $SOURCE_BRANCH ($SOURCE_HEAD, $SOURCE_COMMIT_COUNT commits)" >&2
echo "  trunk: $TRUNK_BRANCH (新規作成)" >&2
echo "" >&2
echo "  Step 1: $TRUNK_BRANCH を $SOURCE_BRANCH から新規作成 + push" >&2
if [[ "$MODE" != "branch-only" ]]; then
  echo "  Step 2: 以下 8 PR を close (= comment 付き、 branch 維持):" >&2
  for pr in "${OPEN_PRS[@]}"; do
    echo "    - PR #$pr" >&2
  done
  if [[ "$KEEP_OLD_BRANCHES" == "false" ]]; then
    echo "  Step 3: 以下 ${#OLD_BRANCHES[@]} branch を削除 (= local + remote):" >&2
    for br in "${OLD_BRANCHES[@]}"; do
      echo "    - $br" >&2
    done
  else
    echo "  Step 3: skip (= --keep-old-branches 指定)" >&2
  fi
else
  echo "  Step 2-3: skip (= --branch-only 指定)" >&2
fi
echo "" >&2

if [[ "$MODE" == "dry-run" ]]; then
  echo "[OK] dry-run 完了 (= 実行なし)" >&2
  exit 0
fi

# --- 全体確認 prompt ---
read -r -p "上記計画で実行しますか? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "[info] aborted by user" >&2
  exit 0
fi

# --- Step 1: wip-ir-trunk 新規作成 + push ---
echo "" >&2
echo "=== Step 1: $TRUNK_BRANCH 新規作成 ===" >&2
git checkout -b "$TRUNK_BRANCH" "$SOURCE_BRANCH"
git push -u origin "$TRUNK_BRANCH"
echo "[OK] $TRUNK_BRANCH created and pushed" >&2

if [[ "$MODE" == "branch-only" ]]; then
  echo "" >&2
  echo "[OK] --branch-only mode 完了 (= PR close + 旧 branch 削除 skip)" >&2
  echo "[info] 次の step: ./scripts/consolidate-ir-trunk.sh (= 本番実行)" >&2
  exit 0
fi

# --- Step 2: PR #6-#13 を close ---
echo "" >&2
echo "=== Step 2: PR #6-#13 を close ===" >&2
for pr in "${OPEN_PRS[@]}"; do
  echo "[info] closing PR #$pr..." >&2
  if gh pr close "$pr" --comment "$PR_CLOSE_COMMENT" 2>&1; then
    echo "[OK] PR #$pr closed" >&2
  else
    echo "[WARN] PR #$pr close failed (= 既に close 済 or 権限不足の可能性、 継続)" >&2
  fi
done

# --- Step 3: 旧 branch 削除 ---
if [[ "$KEEP_OLD_BRANCHES" == "true" ]]; then
  echo "" >&2
  echo "=== Step 3: skip (= --keep-old-branches 指定) ===" >&2
else
  echo "" >&2
  echo "=== Step 3: 旧 wip-ir-* branch 削除 (= local + remote) ===" >&2
  for br in "${OLD_BRANCHES[@]}"; do
    # local 削除
    if git rev-parse --verify "$br" > /dev/null 2>&1; then
      git branch -D "$br" 2>&1 && echo "[OK] local branch deleted: $br" >&2 || echo "[WARN] local delete failed: $br" >&2
    else
      echo "[info] local branch not found (= 既に削除済 or 存在しない): $br" >&2
    fi
    # remote 削除
    if git ls-remote --heads origin "$br" | grep -q "$br"; then
      git push origin --delete "$br" 2>&1 && echo "[OK] remote branch deleted: $br" >&2 || echo "[WARN] remote delete failed: $br" >&2
    else
      echo "[info] remote branch not found: $br" >&2
    fi
  done
fi

# --- 最終 verify ---
echo "" >&2
echo "=== 最終 verify ===" >&2
echo "[info] current branch:" >&2
git branch --show-current
echo "" >&2
echo "[info] $TRUNK_BRANCH HEAD:" >&2
git log -1 --format="%h %s" "$TRUNK_BRANCH"
echo "" >&2
echo "[info] 残存 wip-ir-* branch (= 削除されなかったもの):" >&2
git branch --list 'wip-ir-*' || echo "  (none)"
git branch -r --list 'origin/wip-ir-*' 2>/dev/null || echo "  (none in remote)"
echo "" >&2
echo "[info] OPEN PR 一覧:" >&2
gh pr list --state open --json number,title,headRefName 2>/dev/null | jq -r '.[] | "  PR #\(.number): \(.title) (= head: \(.headRefName))"' || echo "  (gh pr list failed)"

echo "" >&2
echo "[OK] consolidation complete" >&2
echo "[next] 開発本拠地 wip-pmddotnet-opnb-extension は触っていません。 IR 軸の成果は wip-ir-trunk に保存されました。 将来 .NEO コンテナ軸着手時に wip-ir-trunk から取り出してください。" >&2
