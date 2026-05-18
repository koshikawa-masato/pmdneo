#!/usr/bin/env bash
# setup-main-branch-protection.sh
#
# GitHub main branch protection を設定する script (= user 手動実行用、 一人開発 public repo 想定)。
# memory `feedback_branch_strategy.md` + PMDNEO 30th session 末で user 要望「Public リポジトリなので main を保護」 受領。
#
# 設定内容:
#   - allow_force_pushes: false (= force push 禁止)
#   - allow_deletions: false (= branch 削除禁止)
#   - enforce_admins: true (= admin にも適用)
#   - required_linear_history: true (= rebase/squash 強制)
#   - required_pull_request_reviews: enable, approve count 0 (= PR 経由必須、 一人開発で approve 数 0)
#   - required_status_checks: null (= CI 必須なし、 現状 CI 未設定)
#   - restrictions: null (= push user 制限なし)
#
# 使い方:
#   ./scripts/setup-main-branch-protection.sh             # 設定実行
#   ./scripts/setup-main-branch-protection.sh --dry-run   # JSON body 表示のみ、 API 呼び出さず
#   ./scripts/setup-main-branch-protection.sh --verify    # 現在の protection 状態確認のみ
#   ./scripts/setup-main-branch-protection.sh --revert    # protection 削除 (= 注意)
#
# 前提:
#   - gh CLI 2.x 以降 + admin:repo scope 付き token で認証済
#   - repo = koshikawa-masato/pmdneo (= remote origin 自動検出)

set -euo pipefail

# --- args ---
MODE="${1:-apply}"
case "$MODE" in
  --dry-run) MODE="dry-run" ;;
  --verify|--verify-only) MODE="verify" ;;
  --revert|--delete) MODE="revert" ;;
  --help|-h)
    grep -E "^# " "$0" | sed -E 's/^# ?//'
    exit 0
    ;;
  apply|"") MODE="apply" ;;
  *)
    echo "[FAIL] unknown mode: $MODE" >&2
    echo "usage: $0 [--dry-run|--verify|--revert]" >&2
    exit 64
    ;;
esac

# --- repo 自動検出 (= origin URL から owner/repo 抽出) ---
ORIGIN_URL="$(git remote get-url origin 2>/dev/null || echo "")"
if [[ -z "$ORIGIN_URL" ]]; then
  echo "[FAIL] git remote 'origin' not found" >&2
  exit 64
fi
REPO_PATH="$(echo "$ORIGIN_URL" | sed -E 's#^.*github.com[:/]([^/]+/[^/.]+)(\.git)?$#\1#')"
if [[ -z "$REPO_PATH" || "$REPO_PATH" == "$ORIGIN_URL" ]]; then
  echo "[FAIL] could not parse owner/repo from origin URL: $ORIGIN_URL" >&2
  exit 64
fi
echo "[info] repo = $REPO_PATH" >&2

# --- gh CLI / auth 確認 ---
if ! command -v gh > /dev/null 2>&1; then
  echo "[FAIL] gh CLI not installed (= https://cli.github.com/)" >&2
  exit 64
fi
if ! gh auth status > /dev/null 2>&1; then
  echo "[FAIL] gh CLI not authenticated (= run: gh auth login)" >&2
  exit 64
fi

# --- mode 分岐 ---
case "$MODE" in
  verify)
    echo "[info] mode=verify (= 現在の protection 状態確認のみ)" >&2
    if gh api "repos/$REPO_PATH/branches/main/protection" > /tmp/main-protection-current.json 2>/dev/null; then
      echo "[OK] main branch is protected. current settings:" >&2
      jq '{
        enforce_admins: .enforce_admins.enabled,
        required_pull_request_reviews: .required_pull_request_reviews,
        allow_force_pushes: .allow_force_pushes.enabled,
        allow_deletions: .allow_deletions.enabled,
        required_linear_history: .required_linear_history.enabled,
        required_status_checks: .required_status_checks,
        restrictions: .restrictions
      }' /tmp/main-protection-current.json
    else
      echo "[info] main branch is NOT protected (= HTTP 404 expected for unprotected branch)" >&2
      exit 1
    fi
    exit 0
    ;;

  revert)
    echo "[WARN] mode=revert (= main protection 削除)" >&2
    echo "  これにより main branch への direct push / force push / 削除が再び可能になります。" >&2
    read -r -p "  続行しますか? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
      echo "[info] aborted by user" >&2
      exit 0
    fi
    if gh api -X DELETE "repos/$REPO_PATH/branches/main/protection" > /dev/null 2>&1; then
      echo "[OK] main branch protection deleted" >&2
    else
      echo "[FAIL] failed to delete protection (= 既に未保護の可能性)" >&2
      exit 1
    fi
    exit 0
    ;;
esac

# --- apply / dry-run 共通: JSON body 生成 ---
BODY_FILE="$(mktemp -t main-protection.XXXXXX.json)"
trap 'rm -f "$BODY_FILE"' EXIT

cat > "$BODY_FILE" <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo "[info] protection body:" >&2
cat "$BODY_FILE" >&2
echo "" >&2

if [[ "$MODE" == "dry-run" ]]; then
  echo "[OK] dry-run complete (= API 呼び出しなし、 JSON body 表示のみ)" >&2
  exit 0
fi

# --- apply mode: 確認 + 実行 ---
echo "[info] mode=apply (= main protection 設定実行)" >&2
echo "  target: repos/$REPO_PATH/branches/main/protection" >&2
read -r -p "  続行しますか? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "[info] aborted by user" >&2
  exit 0
fi

if gh api -X PUT "repos/$REPO_PATH/branches/main/protection" \
     -H "Accept: application/vnd.github+json" \
     --input "$BODY_FILE" > /tmp/main-protection-result.json 2>&1; then
  echo "[OK] main branch protection applied" >&2
  echo "[info] verifying..." >&2
  jq '{
    enforce_admins: .enforce_admins.enabled,
    required_pull_request_reviews: .required_pull_request_reviews,
    allow_force_pushes: .allow_force_pushes.enabled,
    allow_deletions: .allow_deletions.enabled,
    required_linear_history: .required_linear_history.enabled
  }' /tmp/main-protection-result.json
else
  echo "[FAIL] failed to apply protection. response:" >&2
  cat /tmp/main-protection-result.json >&2
  echo "" >&2
  echo "[hint] common causes:" >&2
  echo "  - token scope insufficient (= admin:repo 必要)" >&2
  echo "  - repo is private under free plan (= protection は public または paid plan のみ)" >&2
  echo "  - main branch does not exist" >&2
  exit 1
fi

echo "" >&2
echo "[next] memory feedback_branch_strategy.md の「main への直接 push が許容される例外」 (= MML reference / coverage 表 / 公開 doc) も今後は PR 経由必須になります。" >&2
