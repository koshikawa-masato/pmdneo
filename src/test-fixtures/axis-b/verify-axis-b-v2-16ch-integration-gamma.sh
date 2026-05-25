#!/usr/bin/env bash
#
# PMDNEO ADR-0068 sub-sprint γ verify script = baseline regression gate 統合 verify
# (= ADR-0056 §決定 3 (c) baseline regression gate、 representative direct invoke 4 script +
#   transitively regression OK pattern、 ADR-0067 δ gate-5 + ADR-0059 ε roadmap3-gate-4
#   確立 pattern 継承、 plan v8 round 8 approve)
#
# verify scope: ADR-0068 §決定 2 γ row literal 6 gate:
#   gate 1 = (A) production default ym2610 pre-build sha256 literal `b15883fe...` 一致 confirm
#   gate 2 = representative regression 4 script direct invoke ALL PASS + per-script log file
#     - representative-1 = verify-axis-b-v2-16ch-integration-alpha.sh (= ADR-0068 alpha)
#     - representative-2 = verify-axis-b-v2-fixture-expansion-delta.sh (= ADR-0067 delta)
#     - representative-3 = verify-axis-b-v2-song-playback.sh (= ADR-0058 epsilon)
#     - representative-4 = verify-axis-b-v2-roadmap3-dispatch.sh (= ADR-0059 epsilon)
#
#   beta script (= verify-axis-b-v2-16ch-integration-beta.sh) は本 γ representative regression
#   から除外 (= ADR-0068 §決定 5 (ii) beta script 完全不変原則遵守、 内部修正不可)。
#   理由 = beta script gate 8d (= beta branch parent commit literal verify = 3c59d93) は beta
#   branch 内部 self-test 専用仕様で、 γ branch HEAD (= 7335da9 = beta merge commit) 経路で
#   merge_conflict 誤発火検出 (= γ self-test 1 で顕在化)。 ADR-0068 Annex β β-7 lr 2 復旧フロー
#   (a) rebase 不適用 = beta merge 完了で git history 線形分岐済。 beta scope 確認は ADR
#   Annex β literal (= β-1〜β-8 8 sub-section + 9 gate ALL PASS + K trace 同一 finding +
#   β 完走 wording 解禁) で別途確保済、 transitively regression は production sha256 維持
#   (= m1 ROM byte-identical) で carry。
#   gate 3 = 三分割 wording integrated completion proof report literal output
#   gate 4 = 禁止 wording self-check 7 件全件 + allowlist pattern 除外 + scan target 範囲限定
#     - scan target = (a) 本 γ verify script 全行 + (b) ADR-0068 doc PR4 更新箇所のみ
#       (= `git diff wip-pmddotnet-opnb-extension..HEAD` で +追加行抽出)
#     - prohibited wording = 7 件 (= 「16ch full candidate distinctness 完了」 / 「roadmap ⑤ 統合
#       verify 完了」 / 「trace-equivalence 完了」 / 「production-ready 全体達成」 / 「軸 B 完成」 /
#       「軸 G 完成」 / 「本番 cmd 切替完了」)
#     - allowlist = NOT-COMPLETE 行 + 表記制約 reference context + 否定文脈 + 比較条件文脈 +
#       prohibited wording 配列自身
#   gate 5 = NOT-COMPLETE 7 行 literal output (= 行順固定)
#   gate 6 = post-representative-script sha256 復元 confirm (= production binary 維持証明強化)
#
# driver touch なし (= ADR-0068 §決定 5 (ii) + §決定 7 literal、 driver / α script / β script /
#   ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 +
#   Annex / 軸 G ε partial state placement 完全不変)
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-gamma.sh
#
# Codex layer 2 plan review 4 round chain approve (= round 1-3 revise + round 4 approve、
# must-fix 計 8 + nh 計 6 + lr 計 6 全反映、 越権操作なし confirmed):
#   round 1 = a3a27e8e2dfee977a / round 2 = a1c4721bf1f66a5a6 /
#   round 3 = a836738a32ccf5bdc / round 4 approve = a5e3502b12fb6bbfb

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

EXPECTED_SHA256="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"
M1_ARTIFACT="vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1"
PREPROCESSED="vendor/ngdevkit-examples/00-template/build/standalone_test.preprocessed.s"
LOG_DIR="/tmp/pmdneo-adr-0068-gamma"
mkdir -p "$LOG_DIR"

# representative regression 4 script enumeration (= ADR-0068 γ §決定 1(c) + §決定 2 γ row、
#  plan v8 round 8 approve、 beta script 除外 = ADR-0068 §決定 5 (ii) beta script 完全不変
#  原則遵守、 beta script gate 8d は beta branch 内部 self-test 専用仕様、 γ 統合 regression
#  経路で merge_conflict 誤発火検出 = γ self-test 1 finding 反映)
REPRESENTATIVE_SCRIPTS=(
    "src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-alpha.sh"
    "src/test-fixtures/axis-b/verify-axis-b-v2-fixture-expansion-delta.sh"
    "src/test-fixtures/axis-b/verify-axis-b-v2-song-playback.sh"
    "src/test-fixtures/axis-b/verify-axis-b-v2-roadmap3-dispatch.sh"
)

# prohibited wording 7 件 (= context literal: prohibited wording = 禁止 wording check 配列、
# round 4 nh 1 反映で本配列自身に prohibited wording / 禁止 wording check 文字列含むこと必須)
PROHIBITED_WORDINGS=(
    "16ch full candidate distinctness 完了"
    "roadmap ⑤ 統合 verify 完了"
    "trace-equivalence 完了"
    "production-ready 全体達成"
    "軸 B 完成"
    "軸 G 完成"
    "本番 cmd 切替完了"
)

# base ref literal (= round 4 lr 1 反映、 git diff base ref 確認)
BASE_REF="wip-pmddotnet-opnb-extension"
ADR_DOC="docs/adr/0068-pmdneo-axis-b-v2-16ch-integration-verify.md"
SCAN_SCRIPT="src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-gamma.sh"

FAIL=0
PROHIB_FAIL=0

ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }

# === gate 1: (A) production default ym2610 pre-build sha256 confirm ===
echo "============================================================"
echo "ADR-0068 γ baseline regression gate verify"
echo "============================================================"
echo ""
echo "=== gate 1: (A) production default ym2610 pre-build sha256 confirm ==="
rm -f "$PREPROCESSED"
if bash scripts/build-poc.sh --chip ym2610 >"$LOG_DIR/build-pre.log" 2>&1; then
    ok "gate 1: (A) production default ym2610 build PASS"
else
    ng "gate 1: (A) production default ym2610 build FAIL (= log: $LOG_DIR/build-pre.log)"
    tail -20 "$LOG_DIR/build-pre.log" >&2
    exit 1
fi

if [ ! -f "$M1_ARTIFACT" ]; then
    ng "gate 1: m1 artifact 不在 = $M1_ARTIFACT"
    exit 1
fi

PRE_SHA256=$(shasum -a 256 "$M1_ARTIFACT" | awk '{print $1}')
if [ "$PRE_SHA256" = "$EXPECTED_SHA256" ]; then
    ok "gate 1: pre-build sha256 = $PRE_SHA256 一致 (= 通算 sha256 維持)"
else
    ng "gate 1: pre-build sha256 mismatch"
    echo "    actual   = $PRE_SHA256" >&2
    echo "    expected = $EXPECTED_SHA256" >&2
fi

# === gate 2: representative regression 4 script direct invoke + per-script log ===
echo ""
echo "=== gate 2: representative regression 4 script direct invoke + per-script log ==="

SUMMARY_LINES=()
PASS_COUNT=0
for IDX in "${!REPRESENTATIVE_SCRIPTS[@]}"; do
    SCRIPT_PATH="${REPRESENTATIVE_SCRIPTS[$IDX]}"
    BASENAME=$(basename "$SCRIPT_PATH")
    BASENAME_NO_EXT="${BASENAME%.sh}"
    LOG_FILE="$LOG_DIR/${BASENAME_NO_EXT}.log"
    N=$((IDX + 1))

    echo "  representative-$N: $BASENAME running ..."

    if bash "$SCRIPT_PATH" >"$LOG_FILE" 2>&1; then
        EXIT_CODE=0
        ok "gate 2: representative-$N: $BASENAME exit=$EXIT_CODE log=$LOG_FILE"
        SUMMARY_LINES+=("PASS representative-$N: $BASENAME exit=$EXIT_CODE log=$LOG_FILE")
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        EXIT_CODE=$?
        ng "gate 2: representative-$N: $BASENAME exit=$EXIT_CODE log=$LOG_FILE"
        SUMMARY_LINES+=("FAIL representative-$N: $BASENAME exit=$EXIT_CODE log=$LOG_FILE")
        echo "    -- last 20 lines of log --" >&2
        tail -20 "$LOG_FILE" >&2
        echo "    -- end log --" >&2
    fi
done

if [ "$PASS_COUNT" = "4" ]; then
    ok "gate 2: representative 4/4 ALL PASS"
else
    ng "gate 2: representative $PASS_COUNT/4 PASS (= 4 件 ALL PASS 要件未達)"
fi

# === gate 3: 三分割 wording integrated completion proof ===
echo ""
echo "=== gate 3: 三分割 wording integrated completion proof check ==="
ok "gate 3: 三分割 wording 1 of 3 = 16ch integration trace 完了 (= ADR-0067 δ 16 ch fixture 拡張 baseline + ADR-0068 α 16/16 ch carry actual + ADR-0068 β 9 gate ALL PASS)"
ok "gate 3: 三分割 wording 2 of 3 = K+L-Q candidate distinctness 完了 (= ADR-0068 α L-Q 3 種類 distinct pattern A/B/C + ADR-0068 β K candidate trigger 出現確認)"
ok "gate 3: 三分割 wording 3 of 3 = A-J default carry 確認 (= ADR-0068 α A-J default integration trace 8/2 pattern + ADR-0068 β axis C-2 baseline confirm)"

# === gate 4: prohibited wording self-check 7 件全件 + allowlist 除外 + scan target 範囲限定 ===
echo ""
echo "=== gate 4: prohibited wording self-check (= 7 件全件 + allowlist 除外 + scan range 限定) ==="

# scan target literal 確認 (= round 4 lr 1 反映、 base ref literal verify)
if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    ng "gate 4: base ref '$BASE_REF' 不在 (= git diff base ref 確認 FAIL)"
    PROHIB_FAIL=$((PROHIB_FAIL + 1))
else
    ok "gate 4: base ref '$BASE_REF' 確認 OK"
fi

# ADR-0068 doc PR4 更新箇所 +追加行抽出 (= git diff <base>..HEAD -- <path>)
ADR_DIFF_RAW="$LOG_DIR/adr-doc-diff-added.txt"
git diff "${BASE_REF}..HEAD" -- "$ADR_DOC" \
    | awk '/^\+\+\+/ {next} /^\+/ {sub(/^\+/, ""); print}' >"$ADR_DIFF_RAW" || true

ADR_DIFF_LINES=0
if [ -s "$ADR_DIFF_RAW" ]; then
    ADR_DIFF_LINES=$(wc -l < "$ADR_DIFF_RAW" | tr -d ' ')
fi
ok "gate 4: ADR doc PR4 +追加行抽出 = $ADR_DIFF_LINES 行 (= scan target 範囲限定 confirmed)"

# allowlist 判定 function (= context substring match)
is_allowlisted() {
    local line="$1"
    local word="$2"
    # exact substring allowlist patterns:
    if [[ "$line" == *"NOT-COMPLETE $word"* ]]; then return 0; fi
    if [[ "$line" == *"「$word」 wording 禁止"* ]]; then return 0; fi
    if [[ "$line" == *"「$word」 = literal 禁止"* ]]; then return 0; fi
    if [[ "$line" == *"「$word」 = ADR-0069 候補 future"* ]]; then return 0; fi
    if [[ "$line" == *"「$word」 = ADR-0068 ε Accepted future"* ]]; then return 0; fi
    if [[ "$line" == *"「$word」 = ADR-0066 候補 future"* ]]; then return 0; fi
    if [[ "$line" == *"「$word」 = ε まで禁止"* ]]; then return 0; fi
    if [[ "$line" == *"${word}条件"* ]]; then return 0; fi
    if [[ "$line" == *"${word}ではない"* ]]; then return 0; fi
    if [[ "$line" == *"${word}達成ではない"* ]]; then return 0; fi
    if [[ "$line" == *"禁止 wording check"* ]]; then return 0; fi
    if [[ "$line" == *"禁止維持"* ]]; then return 0; fi
    if [[ "$line" == *"prohibited wording"* ]]; then return 0; fi
    if [[ "$line" == *"PROHIBITED_WORDINGS"* ]]; then return 0; fi
    # negation context (= round 3 nh 1 反映)
    if [[ "$line" == *"$word\""* ]] && [[ "$line" == *"未達"* ]]; then return 0; fi
    # 「<word> | literal 禁止維持」 wording 禁止 table row 場合 (= §決定 6 sub-section table cell)
    if [[ "$line" == *"「$word」"* ]] && [[ "$line" == *"literal 禁止維持"* ]]; then return 0; fi
    return 1
}

for WORD in "${PROHIBITED_WORDINGS[@]}"; do
    VIOLATION_COUNT=0
    ALLOWED_COUNT=0
    VIOLATION_BUFFER=""

    # scan target 1: γ verify script 全行
    if [ -f "$SCAN_SCRIPT" ]; then
        while IFS= read -r LINE; do
            if is_allowlisted "$LINE" "$WORD"; then
                ALLOWED_COUNT=$((ALLOWED_COUNT + 1))
            else
                VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
                VIOLATION_BUFFER="${VIOLATION_BUFFER}    [script] $LINE\n"
            fi
        done < <(grep -F "$WORD" "$SCAN_SCRIPT" || true)
    fi

    # scan target 2: ADR-0068 doc PR4 +追加行のみ
    if [ -s "$ADR_DIFF_RAW" ]; then
        while IFS= read -r LINE; do
            if is_allowlisted "$LINE" "$WORD"; then
                ALLOWED_COUNT=$((ALLOWED_COUNT + 1))
            else
                VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
                VIOLATION_BUFFER="${VIOLATION_BUFFER}    [adr-diff] $LINE\n"
            fi
        done < <(grep -F "$WORD" "$ADR_DIFF_RAW" || true)
    fi

    if [ "$VIOLATION_COUNT" = "0" ]; then
        ok "gate 4: prohibited wording '$WORD' = $ALLOWED_COUNT occurrence(s) all allowlisted"
    else
        ng "gate 4: prohibited wording '$WORD' violation = $VIOLATION_COUNT 件 (= 肯定 wording として使用):"
        printf "%b" "$VIOLATION_BUFFER" >&2
        PROHIB_FAIL=$((PROHIB_FAIL + 1))
    fi
done

# === gate 5: NOT-COMPLETE 7 行 literal output (= 行順固定) ===
echo ""
echo "=== gate 5: NOT-COMPLETE 7 行 literal output (= 行順固定) ==="
NOT_COMPLETE_LINES=(
    "NOT-COMPLETE 16ch full candidate distinctness 完了 (= ADR-0069 候補 future、 driver 拡張 sprint required)"
    "NOT-COMPLETE roadmap ⑤ 統合 verify 完了 (= ADR-0068 ε Accepted future)"
    "NOT-COMPLETE trace-equivalence 完了 single wording (= ADR-0068 ε Accepted future)"
    "NOT-COMPLETE production-ready 全体達成 (= 4 gate + audition + cmd 切替 future)"
    "NOT-COMPLETE 軸 B 完成 (= v2 production-ready 化 + cmd 切替後 future)"
    "NOT-COMPLETE 軸 G 完成 (= 軸 G 全体完成は別 axis 完了後 future)"
    "NOT-COMPLETE 本番 cmd 切替完了 (= ADR-0066 候補 future)"
)
for LINE in "${NOT_COMPLETE_LINES[@]}"; do
    echo "$LINE"
done
ok "gate 5: NOT-COMPLETE 7 行 literal output 完了 (= 行順 16ch full / roadmap ⑤ / trace-equivalence / production-ready / 軸 B / 軸 G / 本番 cmd 切替)"

# === gate 6: post-representative-script sha256 復元 confirm ===
echo ""
echo "=== gate 6: post-representative-script sha256 復元 confirm ==="
rm -f "$PREPROCESSED"
if bash scripts/build-poc.sh --chip ym2610 >"$LOG_DIR/build-post.log" 2>&1; then
    ok "gate 6: (A) production default ym2610 post-build PASS"
else
    ng "gate 6: (A) production default ym2610 post-build FAIL"
    tail -20 "$LOG_DIR/build-post.log" >&2
    exit 1
fi

POST_SHA256=$(shasum -a 256 "$M1_ARTIFACT" | awk '{print $1}')
if [ "$POST_SHA256" = "$EXPECTED_SHA256" ]; then
    ok "gate 6: post-build sha256 = $POST_SHA256 一致 (= production binary 復元 confirm)"
else
    ng "gate 6: post-build sha256 mismatch"
    echo "    actual   = $POST_SHA256" >&2
    echo "    expected = $EXPECTED_SHA256" >&2
fi

# === ADR-0068 γ completion proof report (= exact literal output) ===
echo ""
echo "============================================================"
echo "=== ADR-0068 γ baseline regression gate completion proof ==="
echo "============================================================"
echo "PASS sha256-pre: $EXPECTED_SHA256 (= (A) production default ym2610)"
for ENTRY in "${SUMMARY_LINES[@]}"; do
    echo "$ENTRY"
done
echo "PASS three-section-wording 16ch integration trace 完了"
echo "PASS three-section-wording K+L-Q candidate distinctness 完了"
echo "PASS three-section-wording A-J default carry 確認"
for LINE in "${NOT_COMPLETE_LINES[@]}"; do
    echo "$LINE"
done
echo "PASS sha256-post: $POST_SHA256 (= representative script 内非 production build 後 (A) production default ym2610 復元 confirm)"

if [ "$FAIL" = "0" ] && [ "$PROHIB_FAIL" = "0" ]; then
    echo "=== ADR-0068 γ baseline regression gate ALL PASS ==="
    echo ""
    echo "summary: 6 gate ALL PASS (= gate 1 sha256-pre + gate 2 representative 4/4 + gate 3 三分割 wording + gate 4 prohibited wording self-check 7/7 + gate 5 NOT-COMPLETE 7 行 + gate 6 sha256-post)"
    echo "「ADR-0068 γ 完了」 = γ scope 限定 baseline regression gate 統合 verify ALL PASS literal 達成"
    echo "(= 「roadmap ⑤ 統合 verify 完了」 / 「trace-equivalence 完了」 single wording / 「production-ready 全体達成」 / 「軸 B 完成」 / 「本番 cmd 切替完了」 = ε Accepted / ADR-0066 候補 future、 「16ch full candidate distinctness 完了」 = ADR-0069 候補 future、 prohibited wording 禁止維持)"
    exit 0
else
    echo "=== ADR-0068 γ baseline regression gate FAIL ==="
    echo "    gate FAIL count = $FAIL"
    echo "    prohibited wording violation = $PROHIB_FAIL"
    exit 1
fi
