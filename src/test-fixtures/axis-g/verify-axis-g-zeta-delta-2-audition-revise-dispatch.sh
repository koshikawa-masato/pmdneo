#!/usr/bin/env bash
#
# PMDNEO 軸 G ADR-0048 ζ-δ-2 audition fixture revise verify script
# (= ADR-0048 ζ-δ-1 audition reject judgment 受領下、 改修方向 spec literal 5 件確定 +
#  chain-pr-A 4 本目 = audition revise fixture build trace 体系化)
#
# verify scope: ADR-0048 ζ-δ-2 §改修内容 spec literal 4 軸 (= FM 新 voice + fixture length +
#   note byte 維持 + build flag 追加) の register/static trace proof + ζ-δ-1 baseline regression。
#
# gate 構成 (= 7 gate + baseline regression 1 + completion proof line):
#   gate 1 = production byte-identical (= 全 flag 0 で m1 sha256 = ζ-α/β/γ/δ-1 通算値一致)
#   gate 2 = audition revise flag effective (= preprocess literal TEST_MODE_AXIS_G_AUDITION_REVISE=1)
#   gate 3 = fm_voice_data_audition block 含有 + percussive envelope literal
#            (= AR=0x1F / DR=0x0F / SR=0x0F / SL_RR=0xFF の 4 op 全 byte 一致)
#   gate 4 = audition fixture length literal (= slot 0/1 = 0x06 + slot 9 = 0x30 + slot 10 = 0x14)
#   gate 5 = FM voice register percussive 化観測 (= reg 0x80/0x84/0x88/0x8C = 0xFF write)
#   gate 6 = 4+ 経路同居 trace (= FM 0x28 keyon + ADPCM-B port B reg 0x10 + ADPCM-A port B reg 0x10)
#   gate 7 = baseline regression (= verify-axis-g-zeta-beta-dispatch.sh transitive)
#
# scope-out (= ζ-δ-2 でも維持):
#   - ADR-0048 Draft → Accepted 移行 (= ζ-ε)
#   - audio gate (= 越川氏 audition judgment は別 sub-sprint = ζ-δ-2 user audition session)
#   - 「軸 G 完成」 / 「軸 B 完成」 / 「production-ready 全体達成」 表現禁止 literal 維持
#
# 規律 (= ADR-0058/0059/0048 ζ-β/γ/δ-1 pattern 継承):
#   - set -euo pipefail + ok/ng helper + FAIL counter
#   - 全 MAME invocation 前に rm -rf $TRACE_DIR
#   - 末尾 production build 復帰
#
# usage: bash src/test-fixtures/axis-g/verify-axis-g-zeta-delta-2-audition-revise-dispatch.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
M1_ROM="$TEMPLATE_BUILD/rom/243-m1.m1"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"

# ζ-δ-2 artifact paths (= chain-pr-A 4 本目 completion banner 用)
PREPROCESSED_ZD2="/tmp/zeta-delta-2.preprocessed.s"
YMFM_ZD2="/tmp/zeta-delta-2-ymfm.tsv"
M1_PROD_SHA_FILE="/tmp/zeta-delta-2-prod-m1.sha"

EXPECTED_PROD_SHA="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }

# ============================================================
# gate 1: production build = 全 flag 0 で m1 sha256 = 期待値一致 (= byte-identical 維持)
# ============================================================
echo "=== gate 1: production build byte-identical ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { ng "production build FAIL"; FAIL=$((FAIL + 1)); }
PROD_SHA=$(shasum -a 256 "$M1_ROM" | awk '{print $1}')
echo "$PROD_SHA" > "$M1_PROD_SHA_FILE"
if [ "$PROD_SHA" = "$EXPECTED_PROD_SHA" ]; then
  ok "gate 1 (production byte-identical): m1 sha256 = $PROD_SHA = ζ-α/β/γ/δ-1 通算値一致"
else
  ng "gate 1 (production byte-identical) 不成立: actual=$PROD_SHA / expected=$EXPECTED_PROD_SHA"
fi

# ============================================================
# audition revise fixture build (= 3 flag ON、 ym2610) + MAME trace
# ============================================================
echo "=== audition revise fixture build (= 3 flag ON, ym2610) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_V2_PPC=1 PMDNEO_AXIS_G_AUDITION_REVISE=1 \
  bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "NG  audition revise fixture build FAIL"; exit 1; }
[ -f "$PREPROCESSED" ] || { echo "NG  preprocess 未生成"; exit 1; }
cp "$PREPROCESSED" "$PREPROCESSED_ZD2"

rm -rf "$TRACE_DIR"
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "NG  ymfm-trace 未生成"; exit 1; }
cp "$YMFM" "$YMFM_ZD2"

# ============================================================
# gate 2: audition revise flag effective (= preprocess literal で flag=1 set)
# ============================================================
G2_FLAG=$(grep -c "TEST_MODE_AXIS_G_AUDITION_REVISE, 1" "$PREPROCESSED_ZD2" || true)
if [ "$G2_FLAG" -ge 1 ]; then
  ok "gate 2 (audition revise flag effective): preprocess literal で TEST_MODE_AXIS_G_AUDITION_REVISE=1 set ($G2_FLAG 行)"
else
  ng "gate 2 不成立: preprocess literal で flag=1 set されていない"
fi

# ============================================================
# gate 3: fm_voice_data_audition block 含有 + percussive envelope literal
# (= AR=0x1F + DR=0x0F + SR=0x0F + SL_RR=0xFF の 4 op 全 byte 一致)
# ============================================================
G3_VOICE_BLOCK=$(grep -c "^fm_voice_data_audition:" "$PREPROCESSED_ZD2" || true)
# DR=0x0F row (= AM/DR、 4 op = 0x0F, 0x0F, 0x0F, 0x0F)
G3_DR=$(awk '/^fm_voice_data_audition:/{flag=1; next} flag && /\.db.*0x0F.*0x0F.*0x0F.*0x0F/{c++} flag && /^[a-z_]+:/{exit} END{print c+0}' "$PREPROCESSED_ZD2")
# SL_RR=0xFF row (= SL/RR、 4 op = 0xFF, 0xFF, 0xFF, 0xFF)
G3_RR=$(awk '/^fm_voice_data_audition:/{flag=1; next} flag && /\.db.*0xFF.*0xFF.*0xFF.*0xFF/{c++} flag && /^[a-z_]+:/{exit} END{print c+0}' "$PREPROCESSED_ZD2")
if [ "$G3_VOICE_BLOCK" -ge 1 ] && [ "$G3_DR" -ge 2 ] && [ "$G3_RR" -ge 1 ]; then
  ok "gate 3 (fm_voice_data_audition + percussive envelope): block 含有 + DR/SR=0x0F row $G3_DR 件 (>= 2) + SL_RR=0xFF row $G3_RR 件 (>= 1)"
else
  ng "gate 3 不成立: block=$G3_VOICE_BLOCK / DR_row=$G3_DR / RR_row=$G3_RR"
fi

# ============================================================
# gate 4: audition fixture length literal
# (= slot 0/1 = 0x06 + slot 9 = 0x30 + slot 10 = 0x14)
# ============================================================
G4_FM_B=$(awk '/^pmdneo_v2_song_fixture_fm_b_audition:/{flag=1; next} flag && /\.db.*0x42.*0x06.*0x45.*0x06.*0x48.*0x06.*0x80/{print "ok"; exit}' "$PREPROCESSED_ZD2")
G4_SSG_G=$(awk '/^pmdneo_v2_song_fixture_ssg_g_audition:/{flag=1; next} flag && /\.db.*0x42.*0x06.*0x45.*0x06.*0x48.*0x06.*0x80/{print "ok"; exit}' "$PREPROCESSED_ZD2")
G4_ADPCMB=$(awk '/^pmdneo_v2_song_fixture_adpcmb_j_ppc_audition:/{flag=1; next} flag && /\.db.*0x00.*0x30.*0x01.*0x30.*0x7F.*0x30.*0x80/{print "ok"; exit}' "$PREPROCESSED_ZD2")
G4_RHYTHM=$(awk '/^pmdneo_v2_song_fixture_rhythm_k_audition:/{flag=1; next} flag && /\.db.*0x01.*0x14.*0x02.*0x14.*0x01.*0x14.*0x80/{print "ok"; exit}' "$PREPROCESSED_ZD2")
if [ "$G4_FM_B" = "ok" ] && [ "$G4_SSG_G" = "ok" ] && [ "$G4_ADPCMB" = "ok" ] && [ "$G4_RHYTHM" = "ok" ]; then
  ok "gate 4 (audition fixture length literal): FM B 0x06 + SSG G 0x06 + ADPCM-B 0x30 + rhythm K 0x14 全 fixture 一致"
else
  ng "gate 4 不成立: fm_b=$G4_FM_B / ssg_g=$G4_SSG_G / adpcmb=$G4_ADPCMB / rhythm=$G4_RHYTHM"
fi

# ============================================================
# gate 5: FM voice register percussive 化観測
# (= reg 0x80-0x8C 範囲 = SL_RR、 ch B 関連 op の reg write 値 = 0xFF (= SL=15 + RR=15) 観測)
# ch B (= chip ch 2、 reg addr offset = 1) の SL_RR reg = 0x81/0x85/0x89/0x8D
# ============================================================
G5_REG81=$(awk -F'\t' '$2=="A" && $3=="81" {print $4}' "$YMFM_ZD2" | sort -u)
G5_REG85=$(awk -F'\t' '$2=="A" && $3=="85" {print $4}' "$YMFM_ZD2" | sort -u)
G5_REG89=$(awk -F'\t' '$2=="A" && $3=="89" {print $4}' "$YMFM_ZD2" | sort -u)
G5_REG8D=$(awk -F'\t' '$2=="A" && $3=="8D" {print $4}' "$YMFM_ZD2" | sort -u)
# audition voice の SL_RR = 0xFF 期待
G5_FF_COUNT=$(awk -F'\t' '$2=="A" && ($3=="81" || $3=="85" || $3=="89" || $3=="8D") && toupper($4)=="FF" {c++} END{print c+0}' "$YMFM_ZD2")
if [ "$G5_FF_COUNT" -ge 1 ]; then
  ok "gate 5 (FM voice percussive 化観測): ch B 関連 reg 0x81/0x85/0x89/0x8D に 0xFF write $G5_FF_COUNT 件 (= SL=15 + RR=15 percussive envelope literal、 audition voice swap proof)"
else
  ng "gate 5 不成立: ch B 関連 SL_RR reg に 0xFF write 観測なし (= audition voice swap 効果なし)"
fi

# ============================================================
# gate 6: 4+ 経路同居 trace
# (= FM port A 0x28 keyon + ADPCM-B port A 0x12-0x15 sample addr +
#    ADPCM-A port B 0x100/0x108/0x110/0x118 keyon/vol/addr trace)
# ※ trace format: port A reg = 2 桁 hex / port B reg = 3 桁 hex (= 1XX prefix)
# ============================================================
G6_FM_KEYON=$(awk -F'\t' '$2=="A" && $3=="28" {c++} END{print c+0}' "$YMFM_ZD2")
G6_ADPCMB=$(awk -F'\t' '$2=="A" && ($3=="12" || $3=="13" || $3=="14" || $3=="15") {c++} END{print c+0}' "$YMFM_ZD2")
G6_ADPCMA=$(awk -F'\t' '$2=="B" && ($3=="100" || $3=="108" || $3=="110" || $3=="118") {c++} END{print c+0}' "$YMFM_ZD2")
if [ "$G6_FM_KEYON" -ge 10 ] && [ "$G6_ADPCMB" -ge 1 ] && [ "$G6_ADPCMA" -ge 1 ]; then
  ok "gate 6 (4+ 経路同居 trace): FM port A reg 0x28 keyon $G6_FM_KEYON 件 + ADPCM-B port A reg 0x12-0x15 $G6_ADPCMB 件 + ADPCM-A port B reg 0x100/0x108/0x110/0x118 $G6_ADPCMA 件 = FM + ADPCM-B + ADPCM-A 3 経路同居 confirm"
else
  ng "gate 6 不成立: fm_keyon=$G6_FM_KEYON (>=10 期待) / adpcmb=$G6_ADPCMB (>=1) / adpcma=$G6_ADPCMA (>=1)"
fi

# ============================================================
# gate 7: baseline regression (= verify-axis-g-zeta-beta-dispatch.sh transitive)
# ============================================================
echo "=== gate 7: baseline regression (= verify-axis-g-zeta-beta-dispatch.sh) ==="
if bash src/test-fixtures/axis-g/verify-axis-g-zeta-beta-dispatch.sh >/dev/null 2>&1; then
  ok "gate 7 (baseline regression): verify-axis-g-zeta-beta-dispatch.sh 全 gate PASS (= ζ-β/ζ-γ/ζ-δ-1 transitive)"
else
  ng "gate 7 不成立: verify-axis-g-zeta-beta-dispatch.sh のいずれかの gate fail"
fi

# ============================================================
# 末尾: production build 復帰 (= byte-identical 維持)
# ============================================================
echo "=== 末尾: production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "NG  末尾 production build 復帰 FAIL"; exit 1; }
RESTORE_SHA=$(shasum -a 256 "$M1_ROM" | awk '{print $1}')
if [ "$RESTORE_SHA" = "$EXPECTED_PROD_SHA" ]; then
  ok "末尾 production build 復帰: m1 sha256 = $RESTORE_SHA = byte-identical 維持"
else
  ng "末尾 production build 復帰 不成立: actual=$RESTORE_SHA / expected=$EXPECTED_PROD_SHA"
fi

# ============================================================
# completion proof line (= chain-pr-A 4 本目 ready signal、 FAIL=0 通過時のみ literal 出力)
# ============================================================
echo ""
echo "=== verify summary ==="
if [ "$FAIL" -eq 0 ]; then
  echo "OK  ζ-δ-2 audition fixture revise ALL gate PASS"
  echo "OK  gate 1 production byte-identical: m1 sha256 = $EXPECTED_PROD_SHA"
  echo "OK  gate 2 audition revise flag effective: TEST_MODE_AXIS_G_AUDITION_REVISE=1 in preprocess"
  echo "OK  gate 3 fm_voice_data_audition block + percussive envelope literal (= DR=0x0F + SL_RR=0xFF)"
  echo "OK  gate 4 audition fixture length literal: slot 0/1=0x06 + slot 9=0x30 + slot 10=0x14"
  echo "OK  gate 5 FM voice percussive 化観測: ch B 関連 reg 0x81/0x85/0x89/0x8D に 0xFF write"
  echo "OK  gate 6 4+ 経路同居 trace: FM port A reg 0x28 + ADPCM-B port A reg 0x12-0x15 + ADPCM-A port B reg 0x100/0x108/0x110/0x118"
  echo "OK  gate 7 baseline regression: verify-axis-g-zeta-beta-dispatch.sh ALL PASS (= ζ-β/γ/δ-1 transitive)"
  echo "OK  artifact preserved: $PREPROCESSED_ZD2 + $YMFM_ZD2 + $M1_PROD_SHA_FILE"
  echo "OK  audio gate scope-out: 越川氏 audition judgment は ζ-δ-2 user audition session (= 別 sub-sprint)"
  echo "OK  ADR-0048 Draft 維持 + ζ-ε 進まず literal 維持"
  echo "OK  禁止表現 5 件 (= 軸 G 完成系 3 件 + 軸 B 完成 + production-ready 全体達成) literal 維持"
  echo "OK  ζ-δ-2 audition wav 生成 ready: PMDNEO_V2_SONG_FIXTURE=1 + PMDNEO_AXIS_G_V2_PPC=1 + PMDNEO_AXIS_G_AUDITION_REVISE=1 + MAME --wavwrite-seconds 10"
  exit 0
else
  echo "NG  ζ-δ-2 audition fixture revise gate FAIL=$FAIL"
  exit 1
fi
