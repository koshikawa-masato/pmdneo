# dispatch 共通化 refactor 設計書

**status**: draft (= 2026-05-10 起票、 Codex 実装委譲前)
**target branch**: `refactor/dispatch-unification`
**base commit**: `6c329aa` (= Phase 8d-2 BD nest LOOP audio gate pass)

## 1. 背景

### 1.1 Phase 9-prep failure 経緯

2026-05-10 Phase 9-prep として「B-J 8 part init 復活 + tempo 統一 + PAN 分離」 を実装、 14 part 並行 dispatch を試行したが以下の症状で **2 連続 failure**:

- drum (= ADPCM-A 6 ch) が高速化
- FM/SSG 全 ch silent (= ymfm trace 上 keyon は出ているが audio 出力なし)
- LOOP CYCLE 2 まで進んで自然 fade out (= 想定外動作)

切り分け試行 (= PAN 設定削除のみ) でも同症状、 **PAN 無関係を確認**。 revert で Phase 8d-2 baseline (= `6c329aa`) に working tree 戻り、 develop 上では Phase 8d-2 のまま push 不要。

### 1.2 user 根本原因指摘 (= 2026-05-10)

> FM/SSG/ADPCM-A/ADPCM-B でコマンド別ルートが複雑すぎていませんか?
> FM 音源にコマンドを送るだけなのだから、 BCEF GHI J KLMNOPQ でシーケンシャルに連続コマンド入れるのが普通なのでは

> 一つ一つは鳴るのだから、 そろそろ個別対応ではなく、 全対応で必要な処理 (l, q, v, M, D, E, W, ! など) は必要なパートだけに流れる処理のように一貫したフローにして簡単にすべきだと思います

### 1.3 既存実装の現状 (= Explore 調査結果)

| 項目 | 行番号 | 状態 |
|------|--------|------|
| pmdneo_song_main | 1326 | 5 fork dispatch (= chip type 別) |
| fmmain | 1554 | 47 行、 LEN check → parse → note/loop/cmd dispatch |
| pmdneo_psgmain | 1602 | 60 行、 fmmain と同型 |
| adpcmb_main | 1663 | 155 行、 同型 |
| adpcma_main | 1818 | 76 行、 同型 + 0x90 (= rest) 専用処理 |
| commandsp | 1531-1549 | 共通 cmd dispatch (= 0xFC/0xFD/0xF9/0xF8 のみ) |

**観察**: 4 個の per-chip 主 routine は **構造が完全に同型**、 違いは note 経路の chip 別 helper 呼出のみ:
- FM: `fnumset_fm` + `fm_keyon` + `fm_keyoff`
- SSG: `fnumsetp_ch` + `pmdneo_psg_keyon` + `ssg_keyoff`
- ADPCM-B: `adpcmb_keyon` + `adpcmb_keyoff`
- ADPCM-A: `adpcma_keyon_simple` + (keyoff なし、 sample trigger 完結)

### 1.4 「14 part 全部鳴る」 baseline 不在

git history 全 commit を調査、 過去に 14 part (= B-J 8 ch + L-Q 6 ch ADPCM-A) **全部 active で audio gate pass した commit は存在しない**。 最近接は **Phase 5a (= `72db9bc`)** の BCEFGHIJ 8 ch milestone (= TEST_MODE_CHORD = 4 hardcoded chord progression、 MML byte parser 前)。 Phase 5b 以降は B-J init を `;;` comment out した状態で進行、 ADPCM-A 6 ch のみ active で Phase 8d-2 まで到達。

つまり本 refactor 完了時に達成する **「14 part 全部鳴る」 は新規到達点**。

## 2. 現状 dispatch architecture 分析

### 2.1 制御フロー (= 現状)

```
IRQ (= TIMER-B 1 ms)
  ↓ sub-tick gating (= driver_tempo_d 加算で overflow 時 pmdneo_song_main 起動)
pmdneo_song_main
  ↓ for c = 0..16 (= 17 part)
  ├ part_workarea[c].ADDR == 0 → skip
  ├ c < 6 (FM)         → fmmain
  ├ c < 9 (SSG)        → pmdneo_psgmain
  ├ c == PCM           → adpcmb_main
  ├ c == RHYTHM        → rhythm_main (= no-op)
  └ c >= ADPCMA1       → adpcma_main
```

各 chip routine 内:
```
LEN > 0 → LEN--、 0 になったら chip 別 keyoff、 return
LEN == 0 → parse:
  byte fetch
  byte == 0x80 → loop reset
  byte < 0x80 → note path:
    note byte → PART_OFF_NOTE 保存
    length byte fetch + scale → PART_OFF_LEN 保存
    chip 別 fnumset + chip 別 keyon
  byte >= 0x81 → commandsp dispatch
```

### 2.2 重複 + 課題

1. **47 + 60 + 155 + 76 = 338 行の構造同型な per-chip routine**、 維持コスト高
2. **新 cmd 追加 (= q/Q/v/M/D/E/W/! 等) 時、 4 routine 全部に分岐追加が必要** (= or commandsp 拡張で 1 箇所済むが、 chip 特殊化が必要な cmd は重複発生)
3. **chip 別差分の局所化が不徹底** (= adpcma_main は 0x90 rest 専用処理を独自に持つ等、 共通化の余地あり)
4. **B-J init 復活で 14 part dispatch すると drum 高速 + FM/SSG silent** (= 真因不明、 cycle budget 超過 hypothesis あり、 ただし trace 上は FM keyon 出ている = chip 制御は届いてる)

### 2.3 cycle budget 概算 (= Explore 調査結果)

- IRQ TIMER-B 周期: 1 ms (= TIMER-B counter 0xE1)
- Z80 @ 4 MHz: 4000 cycles/ms
- per-part cost (= parse + note → keyon + chip 別 fnumset): 50-200 cycles/part
- 17 part full dispatch worst-case: 850-1200 cycles
- 現状 (= L-Q 6 part のみ active): ~400 cycles、 budget 内
- **B-J 8 part 復活で +400 cycles → 余裕薄い、 ただし overrun ではない**

→ Phase 9-prep failure の真因は cycle budget 単独ではなく、 **chip register 初期化順序 or shared state 競合** の可能性が高い。 refactor で dispatch 経路を 1 本化すれば真因切り分けも容易になる。

## 3. 新 architecture 設計

### 3.1 制御フロー (= 新)

```
IRQ
  ↓ sub-tick gating (= 不変)
pmdneo_song_main (= 簡素化)
  ↓ for c = 0..16
  ├ part_workarea[c].ADDR == 0 → skip
  └ pmdneo_part_main (= 共通 entry、 part c に対する dispatch)
```

`pmdneo_part_main` の擬似コード:
```
pmdneo_part_main:
    LEN > 0 → LEN--、 0 になったら hook_keyoff 呼出 (= part 別 fn pointer)、 return
    LEN == 0 → parse:
        byte fetch
        byte == 0x80 → loop reset
        byte == 0x90 → rest path (= ADPCM-A 等で必要、 共通化)
        byte < 0x80 → note path:
            note byte → PART_OFF_NOTE 保存
            length byte fetch + scale → PART_OFF_LEN 保存
            hook_fnumset 呼出 (= part 別 fn pointer)
            hook_keyon 呼出 (= part 別 fn pointer)
        byte >= 0x81 → commandsp dispatch
```

chip 別差分は **per-part hook fn pointer** で吸収。

### 3.2 chip 別 hook table

各 part に対して 4 個の hook fn pointer を持つ:

| hook | 役割 | FM | SSG | ADPCM-B | ADPCM-A |
|------|------|----|----|---------|---------|
| `fn_keyon` | note byte → chip 鳴らす | `fm_keyon_hook` | `psg_keyon_hook` | `adpcmb_keyon_hook` | `adpcma_keyon_hook` |
| `fn_keyoff` | LEN 0 時 chip 止める | `fm_keyoff_hook` | `ssg_keyoff_hook` | `adpcmb_keyoff_hook` | `noop` |
| `fn_fnumset` | note → fnum 計算 + chip 書込 | `fnumset_fm_hook` | `fnumsetp_ch_hook` | `noop` (= note → sample mapping は keyon 内) | `noop` |
| `fn_volumeset` | v cmd 受領時 chip volume 更新 | `fm_volume_hook` | `psg_volume_hook` | `adpcmb_volume_hook` | `adpcma_volume_hook` |

各 hook = 数行の wrapper (= 既存 fnumset_fm / fm_keyon 等を呼ぶ)。

### 3.3 hook table 配置案

**案 A: per-part workarea 内に fn pointer 4 個 (= 8 byte) 確保**:
- PART_OFF_HOOK_KEYON / KEYOFF / FNUMSET / VOLUMESET (= 各 2 byte)
- per-part init 時に chip 別 default hook を copy
- 利点: dispatch は `ld hl, PART_OFF_HOOK_KEYON(ix)` + `jp (hl)` の 2 命令、 高速
- 欠点: SRAM 8 byte/part × 17 part = 136 byte 増加

**案 B: chip type 別 hook table (= 1 個)、 per-part PART_OFF_CHIP_TYPE で参照**:
- chip type (= FM/SSG/PCM/ADPCMA) を per-part 1 byte 保存 (= 既存 PART_OFF_CH_IDX 流用検討)
- dispatch 時 chip type で hook table index、 indirect jump
- 利点: SRAM 増加最小
- 欠点: dispatch 命令数が案 A より多い (= ~5 命令)

**案 C 推奨**: **case A** (= per-part hook、 dispatch 高速化重視)。 SRAM 136 byte 増加は許容範囲 (= 現状 part_workarea 1088 byte → 1224 byte、 SRAM 2048 byte 内余裕 824 byte)。

### 3.4 SRAM layout 拡張 (= 案 A)

既存 PART_OFF_* の最大 offset = 24 (= PART_OFF_CH_IDX)、 per-part 32 byte align (= 既存)、 LOOPSTACK 32-47、 LOOPDEPTH 48 で **per-part 64 byte 使用済**。 hook 8 byte 追加で 49-56 を使うか or per-part を 96 byte に拡張するか:

**推奨**: **per-part 64 byte 維持 + 49-56 を hook 領域に確保** (= LOOPDEPTH 48 の直後)。 LOOPSTACK が 4 entry × 4 byte = 16 byte (= 32-47) で固定済、 LOOPDEPTH 48 直後 49-56 が空き、 ここに hook 8 byte。

修正提案:
```asm
.equ PART_OFF_HOOK_KEYON,     49
.equ PART_OFF_HOOK_KEYOFF,    51
.equ PART_OFF_HOOK_FNUMSET,   53
.equ PART_OFF_HOOK_VOLUMESET, 55
```

(= 各 2 byte、 49-56 の 8 byte 占有、 per-part 64 byte 内に収まる)

### 3.5 cmd dispatch 拡張表

現状 commandsp = 0xFC / 0xFD / 0xF9 / 0xF8 のみ。 拡張対象:

| cmd | byte | 役割 | 共通 / chip 別 |
|-----|------|------|---------------|
| t (tempo) | 0xFC | tempo 設定 | 共通 (= 既存) |
| v (volume) | 0xFD | volume 設定 → hook_volumeset 呼出 | 共通 + chip 別 hook |
| `[` (loop start) | 0xF9 | LOOP 開始 | 共通 (= 既存) |
| `]` (loop end) | 0xF8 | LOOP 終了 | 共通 (= 既存) |
| q (gate) | 0xFE | gate 設定 (= QDATA) | 共通 (= QDATA 既に確保済) |
| Q (gate big) | 0xC4 | gate 設定 (= QDATB) | 共通 |
| q2 | 0xB3 | gate 設定 (= QDATB) | 共通 |
| q3 | 0xB1 | gate 設定 (= QDAT2) | 共通 |
| q4 | 0xB2 | gate 設定 (= QDAT3) | 共通 |
| l (default length) | 0xC1 | default 音長 | 共通 (= PART_OFF_DEFAULT_LEN 新規 必要なら追加) |
| M (LFO) | 0xCC | LFO 設定 | 後 phase (= effect 系) |
| D (detune) | 0xCB | detune 設定 | 後 phase |
| E (envelope) | 0xC9 | envelope 設定 | chip 別 hook |
| W (echo) | 0xC8 | 擬似 echo | 後 phase |
| ! (?) | 不明 | 確認必要 | 不明 |

**Phase 9R refactor 範囲**: t/v/[/]/q/Q/q2/q3/q4/l (= 共通 cmd) を commandsp 内 1 dispatch table に統合。 M/D/E/W/! は後 phase。

### 3.6 chip 別 hook 一覧 + 既存実装との対応

| hook | 既存 routine 行 | 新 hook 名 | wrapping |
|------|----------------|------------|----------|
| FM keyon | line 806 fm_keyon | fm_keyon_hook | `call fnumset_fm` + `call fm_keyon` |
| FM keyoff | line 792 fm_keyoff | fm_keyoff_hook | `call fm_keyoff` |
| FM fnumset | line 578 fnumset_fm | fnumset_fm_hook | `call fnumset_fm` |
| FM volume | (= 未実装) | fm_volume_hook | TL 計算 + 0x40-0x46 register write |
| SSG keyon | line 1647 pmdneo_psg_keyon | psg_keyon_hook | `call pmdneo_psg_keyon` |
| SSG keyoff | line 723 ssg_keyoff | ssg_keyoff_hook | `call ssg_keyoff` |
| SSG fnumset | line 1551 fnumsetp_ch | fnumsetp_ch_hook | `call fnumsetp_ch` |
| SSG volume | (= 既 pmdneo_psg_keyon 内で処理) | psg_volume_hook | volume reg 直書き or keyon 内呼出 |
| ADPCM-B keyon | line 1707 adpcmb_keyon | adpcmb_keyon_hook | sample trigger |
| ADPCM-B keyoff | (= 既 adpcmb_main 内で adpcmb_keyoff 呼出) | adpcmb_keyoff_hook | wrapping |
| ADPCM-A keyon | line 1730 adpcma_keyon_simple | adpcma_keyon_hook | sample trigger |
| ADPCM-A keyoff | noop | adpcma_keyoff_hook | noop (= sample 終了 自然) |

### 3.7 既存 audio gate pass 維持 (= 不変条件)

Phase 8d-2 BD nest LOOP (= L part 単独動作) の聴感が refactor 後も同一。 byte-identical 不要、 ただし以下を verify:
- BD 8 strikes per cycle (= inner1 2 + inner2 4 + extra 3)
- 1 cycle ≈ 3.5 sec
- 永久 LOOP、 LOOP CYCLE counter inc
- nest visualization (= analyze-loop-trace.py) で depth 1 → 2 遷移確認

## 4. 移行手順 (= 段階置換)

refactor 完了までの 1 commit = 1 sub-step:

### Sub-step R-1: 設計書 commit
- docs/design/dispatch_unification.md (= 本書)
- 1 commit: `docs(design): dispatch 共通化 refactor 設計書 起票`

### Sub-step R-2: hook table SRAM layout + chip 別 hook routine 追加
- standalone_test.s に PART_OFF_HOOK_* 定数追加 (= 4 個)
- 12 個の chip 別 hook wrapper routine 追加 (= 既存 helper を call するだけ)
- 既存 fmmain / pmdneo_psgmain / adpcmb_main / adpcma_main は **未削除** (= 並行存在、 dispatch 切替まで保持)
- pmdneo5_init_part 拡張: chip 別 hook を per-part に書込
- 1 commit: `feat(driver): hook table + chip 別 wrapper routine 追加 (= refactor 準備)`

### Sub-step R-3: pmdneo_part_main 共通 routine 追加
- standalone_test.s に pmdneo_part_main 新規追加 (= 共通 dispatch)
- pmdneo_song_main の 5 fork dispatch を pmdneo_part_main 1 fork に置換
- 既存 fmmain / pmdneo_psgmain / adpcmb_main / adpcma_main は **未削除** (= 動作確認後削除)
- audio gate verify: Phase 8d-2 baseline (= L 単独) 同等動作
- 1 commit: `feat(driver): pmdneo_part_main 共通 routine 追加 + dispatch 切替 (= L part audio gate pass)`

### Sub-step R-4: 旧 per-chip routine 削除
- fmmain / pmdneo_psgmain / adpcmb_main / adpcma_main 削除 (= ~338 行)
- audio gate verify: Phase 8d-2 baseline 不変
- 1 commit: `refactor(driver): 旧 per-chip routine 削除 (= dispatch 統合完了)`

### Sub-step R-5: B-J init 段階復活
- B → C → E → F → G → H → I → J 順に init 復活、 1 part 復活ごとに audio gate
- 失敗 part 検出時は 該当 part の MML / chip 設定 / hook 経路を切り分け
- 8 commit: `feat(driver): part X init 復活 (= N part audio gate pass)` × 8

### Sub-step R-6: 14 part 完成宣言
- 全 14 part dispatch + audio gate pass
- 1 commit: `feat(driver): Phase 9R 完成 — 14 part dispatch 統合 (= 共通 part_main 経由)`

### Sub-step R-7: develop merge
- PR / merge develop
- 元 Phase 9 (= gate cmd / fade in / compile.py / multi-tempo) 着手準備

## 5. 検証経路

### 5.1 各 sub-step 共通 verification

```bash
# 1. build
cd /Users/koshikawamasato/Projects/pmdneo
bash scripts/build-poc.sh

# 2. emulator 起動 + 録音 + trace
bash scripts/run-mame.sh --gamerom lastbld2 --loop-viz --wavwrite --wavwrite-seconds 22

# 3. trace 解析
wc -l /tmp/pmdneo-trace/z80-mem-trace.tsv
python3 scripts/analyze-loop-trace.py /tmp/pmdneo-trace/z80-mem-trace.tsv --filter-changes

# 4. wav peak / non-zero ratio
python3 -c "
import wave, struct
with wave.open('/tmp/pmdneo-trace/audio.wav', 'rb') as w:
    n = w.getnframes(); raw = w.readframes(n)
samples = struct.unpack(f'<{len(raw)//2}h', raw)
left = samples[0::2]; right = samples[1::2]
print(f'L peak: {max(abs(s) for s in left)/32768*100:.2f}%, R peak: {max(abs(s) for s in right)/32768*100:.2f}%')
"

# 5. ymfm trace で chip 動作確認
awk -F'\t' 'NR>1 && $2=="A" && $3=="28" {print $4}' /tmp/pmdneo-trace/ymfm-trace.tsv | sort | uniq -c  # FM keyon
awk -F'\t' 'NR>1 && $2=="B" && $3=="100" {print $4}' /tmp/pmdneo-trace/ymfm-trace.tsv | sort | uniq -c  # ADPCM-A keyon

# 6. user 聴感確認
afplay /tmp/pmdneo-trace/audio.wav
```

### 5.2 sub-step 別期待結果

| step | 期待 | 退行検出時 |
|------|------|-----------|
| R-2 | build pass、 動作 baseline 不変 | hook routine bug、 全 commit revert |
| R-3 | L 単独 audio gate pass、 nest LOOP visualization 動作 | dispatch 経路 bug、 commit revert |
| R-4 | L 単独 audio gate pass 維持 | 旧 routine 削除 漏れ、 commit revert |
| R-5 | 1 part 復活ごとに audio gate pass | 該当 part 切り分け、 hook bug 修正 or revert |
| R-6 | 14 part 全部鳴る、 LOOP CYCLE inc、 wav peak 高値 | 1 part づつ無効化で原因切り分け |

### 5.3 audio gate workflow (= memory feedback_mame_launch_template 準拠)

各 audio gate で:
1. **Phase 名 + sub step 名**: 例「Phase 9R Sub-step R-3」
2. **何をするか**: 例「L part 単独動作の refactor 後 audio gate (= dispatch 切替確認)」
3. **期待動作**: MML 表記 + tempo + channel + 期待聴感
4. **ROM 画面 Phase 番号反映**: main.c の `ng_center_text` を該当 sub-step 番号に update
5. **準備 OK 確認**: user 「OK」 取得まで起動禁止

## 6. Codex 委譲計画

### 6.1 Codex agent 起動条件

- **agent**: codex-rescue (= claude-code-guide 経由 or Agent tool 直)
- **prompt**: 設計書 path + 既存 source path + 完成条件 + 検証経路
- **memory 適用**: feedback_claude_code_orchestrator_only / feedback_codex_implementation_review / feedback_codex_full_log_analysis

### 6.2 Codex への委譲範囲

**Codex 担当**:
- Sub-step R-2 〜 R-4 の実装 (= hook table + 共通 part_main + 旧 routine 削除)
- 各 sub-step build pass verify
- session log + diff の Claude Code 報告

**Codex 範囲外** (= Claude Code 担当):
- Sub-step R-1 (= 設計書執筆、 本書)
- 各 sub-step 後の audio gate 起動 (= user 立ち会い必須)
- commit / push (= Claude Code が review 後実施)
- Sub-step R-5 (= B-J init 段階復活、 user 聴感判定が中心)

### 6.3 Codex prompt 雛形

```
PMDNEO の自作 Z80 driver の dispatch 共通化 refactor を実装してください。

設計書: /Users/koshikawamasato/Projects/pmdneo/docs/design/dispatch_unification.md
現状 source: /Users/koshikawamasato/Projects/pmdneo/src/driver/standalone_test.s

実装範囲: Sub-step R-2 〜 R-4 (= hook table 追加 + 共通 part_main 追加 + 旧 routine 削除)
各 sub-step 完了で build pass + git diff を保存、 Claude Code に報告。

検証経路:
- build: bash scripts/build-poc.sh (= make poc 経路)
- audio gate: 別途 Claude Code が user 立ち会いで実施 (= Codex は実装まで)

完成条件:
1. build pass
2. 既存 Phase 8d-2 audio gate baseline (= L part BD nest LOOP) 同等動作 (= refactor 直後 step R-3 で verify)
3. 14 part dispatch 可能 (= R-5 で B-J init 復活した時に動作する設計)
4. cycle budget 問題なし (= IRQ 1 ms 内)

範囲外: commit / push (= Claude Code が review 後実施)

完了後、 git diff + 各 sub-step の build log を report。
```

## 7. リスク + 緩和策

| risk | 緩和策 |
|------|--------|
| refactor で既存 Phase 8d-2 audio 退行 | Sub-step R-3 で baseline 比較必須、 退行検出で revert |
| hook table SRAM 拡張で既存 layout 衝突 | PART_OFF_HOOK_* offset 49-56 確認、 LOOPSTACK 32-47 + LOOPDEPTH 48 と衝突なし |
| Codex 設計書誤読 で別 architecture 実装 | Sub-step ごとの zero-trust review、 不一致は Codex に再委譲 |
| B-J 復活で cycle budget 超過 | per-part cost 概算済 (= worst 1200 cycles < 4000 cycles budget)、 R-5 段階復活で切り分け |
| Phase 9-prep 真因 が refactor で解決しない (= chip register 競合等別原因) | R-5 で 1 part づつ復活で切り分け、 trace 全数解析で原因特定 |

## 8. 参考

### 8.1 既存 design doc

- `/Users/koshikawamasato/Projects/pmdneo/docs/design/pmdneo_self_contained_driver.md` (= 13 章 設計書、 8 章 chip access protocol が本書と関連)

### 8.2 PMD V4.8s 本家との比較

PMD V4.8s 本家 (= vendor/pmd48s/source/pmp48r/PMP.ASM) は **hardcoded sequential dispatch** (= per-part inline)、 ADPCM-A サポートなし。 本 refactor は本家を超える「generic per-part dispatch + chip hook」 の設計、 ただし control flow は本家の sequential 流儀を踏襲。

### 8.3 commit / branch 戦略

- **branch**: `refactor/dispatch-unification` (= base = `6c329aa` Phase 8d-2)
- **commit 規律**: 1 sub-step = 1 commit、 Conventional Commits + 日本語 body + Co-Authored-By
- **完了後**: develop に PR / merge、 main 解凍は Phase 11 で別判定
