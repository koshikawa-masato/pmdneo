# SubC-1 — Codex 向け詳細設計書 (FM 1 ch 単体発音)

	位置付け: Phase 2 SubC 段階分割の 1 番目 (= FM driver の最初の音発生)
	書き手: Claude Code (= zero-trust orchestration の実装設計担当)
	読み手: Codex (= codex:codex-rescue agent 経由で Claude Code が起動)
	状態: 完了 (audio gate pass、 commit 済)

---

> **Errata 2026-05-08**: 本書は当初「FM ch 1 (= chip ch index 0、 register 末尾 +0)」 で記述したが、 audio gate で無音判明。 原因: YM2610 無印 chip では chip ch 1/4 が internal 存在のみで output 配線なし (= 既知仕様、 memory `reference_opna_opnb_chip_comparison.md`)。 訂正先: **chip ch 2 (= ch index 1、 register 末尾 +1、 keyon 0xF1)** で実装した。 PMDNEO は (C) 方針 (= Part A/D 不使用の自己規律) で chip ch 2/3/5/6 のみ運用。 nullsound 命名 `FM1_YM2610 = 1` (= chip ch 2 = 末尾 +1) と一致。 また、 ch 1 への書込で破綻なく無音だった事実は、 **PMD driver 「無効チャンネルへの出力は無音」 不変条件**が NEOGEO chip 仕様と整合していることの実証でもある。 本書本文の register address 表記 (ch 1 想定) は旁証用に保持、 実装は +1 補正済。

---

## 0. 役割分担

- **Claude Code (= 私)**: 設計書執筆、 完了基準の定義、 Codex 実装後の review
- **Codex (= codex-rescue agent)**: 本書を読んで実装、 build 通過まで持っていく
- **user (越川氏)**: judgment、 audio gate 聴感確認

---

## 1. 背景と現状

### 1-1. Phase 2 SubB 全完了 (commit 51098cd まで)

- SubA: skeleton + sdasz80 build 経路
- SubB-1〜3: SSG silent init → TIMER-B → 最初の音発生 (C3「ぶぶぶ」)
- SubB-4: 1 octave スケール (ドレミファソラシド)
- SubB-5/6: psgmain 単体検証 (cmdtblp 経路)
- SubB-7: SAMPLE.M 駆動 (= SSG 3 part 並列演奏、 audio gate Step 1 通過)

### 1-2. SubC = FM 6ch dispatch、 段階分割

SubC 全体は SubB と同等以上の規模で、 cmdtbl FM 79 entry + 音色 set + fnumset + volset + 6 ch dispatch を一気にやると debug 困難。 SubB-3 (= 最初の音発生) と同じ流儀で **SubC を段階分割**:

| sub-task | 目標 | audio gate |
|---|---|---|
| **SubC-1 (本書)** | FM 1 ch 単体発音 (= hardcoded 音色 + hardcoded note で 1 ch から音が出る) | 「ぼー」 や「ぶー」 等の FM 持続音 |
| SubC-2 (後続) | cmdtbl + commands + fmmain (= 1 ch FM MML 駆動) | hardcoded MML で 1 ch FM スケール |
| SubC-3 (後続) | FM 6 ch dispatch + 音色データ table 流し込み | FM 試料楽曲 (audio gate Step 2) |

本書 = SubC-1 のみ。 後続 SubC-2/3 は別 handoff で。

---

## 2. 作業内容

### 2-1. SubC-1 の最小目標

cmd 2 (= snd_command_02_play_song) で **SAMPLE.M 駆動の代わりに、 hardcoded 音色 + hardcoded note で FM ch 1 (= Part A、 SSG とは独立) を発音**する経路を作る。

SubB-3 で SSG ch A の C3 (= 0x0EE8) を hardcoded で鳴らしたのと同じ流儀。 ただし:
- FM では **音色 (= operator parameter 25 byte)** の事前 set が必須 (= SSG はなくても鳴る)
- FM では **keyon/keyoff** が必要 (= SSG は mixer + volume だけで鳴る)
- FM では **fnumset** が複雑 (= block 3 bit + fnum 11 bit、 SSG は 12-bit counter のみ)

### 2-2. 実装する file

- `src/driver/PMD_Z80.inc`
  - `test_play_fm_c4` routine 新規追加 (= 1 ch FM hardcoded 発音)
  - `fm_voice_data_default` data 新規追加 (= 25 byte FM 音色、 simple piano-like or square-like)
  - `fnumset_fm` routine 新規追加 (= note byte → FM block + fnum register)
- `src/driver/IRQ.inc`
  - `snd_command_02_play_song` で `pmdneo_load_m` ではなく `test_play_fm_c4` を call するよう変更 (= 検証中は SAMPLE.M 駆動を一時停止)
  - polling loop は維持 (= TIMER-B IRQ count 動作確認用、 音は持続)

### 2-3. test_play_fm_c4 の仕様

```
入力: なし
動作:
  1. FM ch 1 (= part 番号 0、 register port A、 ch index 0) に音色 set
     (= fm_voice_data_default の 25 byte を register 0x30-0x9F + 0xB0 に書込)
  2. FM ch 1 の volume (TL = total level) を carrier 判定で適切に set
     (= ALG/FB から carrier slot を判定、 carrier の TL を 0x18 程度に)
  3. FM ch 1 の note を C4 (= block 4 + fnum) で fnumset_fm
     - block: 4 (= ONKAI 0 + OCT 4)
     - fnum: 0x269 (= analysis §5-1-1 fnum_data table の C = 0x026A)
     - register 0xA4 (block + fnum upper) + 0xA0 (fnum lower)
  4. FM ch 1 の L/R pan + AMS/PMS を register 0xB4 に書込 (= 0xC0 = L+R 両方 on)
  5. FM ch 1 の keyon (= register 0x28 に 0xF0 + ch index = 0xF0)
     (slot mask 0xF0 = OP 1-4 全 keyon、 ch index 0 = FM 1)
破壊: A、 B、 C、 D、 E、 H、 L、 IX
```

### 2-4. fm_voice_data_default の仕様

PMD V4.8s の prgdat format (= analysis §5-7-2 の 26 byte / entry の音色 25 byte 部分) で simple な FM 音色:

| .m offset | byte | 内容 (4 op) |
|---|---|---|
| 0-3 | 4 | DT / ML × 4 op |
| 4-7 | 4 | TL × 4 op |
| 8-11 | 4 | KS / AR × 4 op |
| 12-15 | 4 | AM / DR × 4 op |
| 16-19 | 4 | SR × 4 op |
| 20-23 | 4 | RR / SL × 4 op |
| 24 | 1 | ALG / FB |

格納順 = register slot 順 (= OP1, OP3, OP2, OP4)。

#### 推奨音色 (= 簡単な square-like FM 音、 SubC-1 audio gate 用)

```
;; ALG = 7 (= 4 op 全 carrier、 加算合成、 simple)
;; FB = 0
;; OP1-4 全 carrier、 各 op に同じ envelope
;; DT/ML : OP1=0x01 (DT0, ML1)、 OP3=0x01、 OP2=0x01、 OP4=0x01
;; TL    : OP1=0x18 (-24 dB)、 OP3=0x18、 OP2=0x18、 OP4=0x18 (= 4 op 平均)
;; KS/AR : OP1=0x1F (KS0 AR31 = 即 attack)、 OP3=0x1F、 OP2=0x1F、 OP4=0x1F
;; AM/DR : OP1=0x00 (AM off DR0 = decay なし)、 OP3=0x00、 OP2=0x00、 OP4=0x00
;; SR    : OP1=0x00 (SR0 = sustain rate なし)、 OP3=0x00、 OP2=0x00、 OP4=0x00
;; RR/SL : OP1=0x0F (SL0 RR15 = release 即終了)、 OP3=0x0F、 OP2=0x0F、 OP4=0x0F
;; ALG/FB: 0x07 (= ALG 7、 FB 0)

fm_voice_data_default::
        ;; DT/ML × 4
        .db 0x01, 0x01, 0x01, 0x01
        ;; TL × 4
        .db 0x18, 0x18, 0x18, 0x18
        ;; KS/AR × 4
        .db 0x1F, 0x1F, 0x1F, 0x1F
        ;; AM/DR × 4
        .db 0x00, 0x00, 0x00, 0x00
        ;; SR × 4
        .db 0x00, 0x00, 0x00, 0x00
        ;; RR/SL × 4
        .db 0x0F, 0x0F, 0x0F, 0x0F
        ;; ALG/FB
        .db 0x07
```

合計 25 byte (= prgdat の音色 25 byte 部分のみ、 番号 byte なし)。

### 2-5. fnumset_fm の仕様

```
入力: A = note byte (OCT 4 bit + ONKAI 4 bit)
動作:
  1. ONKAI を取り出して fnum_data[ONKAI × 2] (= OCT 0 base FM fnum 値、 11-bit)
  2. OCT 値を取り出して block を計算
     (= PMD V4.8s では block = OCT で 0-7)
  3. register 0xA4 (= ch 1 block + fnum upper 3 bit) に書込
     - bit 5-3: block (3 bit)
     - bit 2-0: fnum upper 3 bit
  4. register 0xA0 (= ch 1 fnum lower 8 bit) に書込
     - 注意: 0xA4 → 0xA0 の順で書く必要 (= chip 仕様、 0xA4 で block latch、
       0xA0 書込で実際に反映)
出力: なし (= chip register に書き込み)
破壊: A、 B、 C、 D、 E、 H、 L
```

#### fnum_data table (FM 用、 analysis §5-1-1)

```
fnum_data:
        .dw     0x026A          ; ONKAI 0 = C
        .dw     0x028F          ; ONKAI 1 = C#
        .dw     0x02B6          ; ONKAI 2 = D
        .dw     0x02DF          ; ONKAI 3 = D#
        .dw     0x030B          ; ONKAI 4 = E
        .dw     0x0339          ; ONKAI 5 = F
        .dw     0x036A          ; ONKAI 6 = F#
        .dw     0x039E          ; ONKAI 7 = G
        .dw     0x03D5          ; ONKAI 8 = G#
        .dw     0x0410          ; ONKAI 9 = A
        .dw     0x044E          ; ONKAI 10 = A#
        .dw     0x048F          ; ONKAI 11 = B
```

### 2-6. snd_command_02_play_song の修正

```asm
;; 変更前 (SubB-7):
snd_command_02_play_song::
        call    pmdneo_init
        call    pmdneo_load_m
pmdneo_play_loop::
        ...

;; 変更後 (SubC-1):
snd_command_02_play_song::
        call    pmdneo_init
        call    test_play_fm_c4
pmdneo_play_loop::
        ...                           ; polling loop は維持 (TIMER-B 継続)
```

`pmdneo_load_m` 関連は **削除しない**(= SubC-3 で SAMPLE2.M 駆動するときに復帰)。 既存 `test_play_psgmain` / `test_play_scale` も残す。

### 2-7. 変更しない部分

- 既存 `pmdneo_init` (= SSG mixer + TIMER-B 起動 + ei + driver state init)
- 既存 SSG 関連実装 (= scale demo + psgmain + cmdtblp + PSG handler 群)
- 既存 ADPCM-A/B / KR_STUB
- vendor/ngdevkit-examples/00-template/main.c
- scripts/build-poc.sh (= bin2db.py + sample_m.s 経路は維持)

---

## 3. 前提 (Codex が知っておくべき context)

### 3-1. 設計書

- `docs/design/analysis_m_data_structure.md` §5-1-1 (= 音程 + 音長解釈、 fnum_data table)
- `docs/design/analysis_m_data_structure.md` §5-7 (= 音色データ format、 prgdat 26 byte)
- `docs/design/analysis_m_data_structure.md` §5-7-3 (= operator 順序 = OP1, OP3, OP2, OP4 register slot 順)
- `docs/design/phase2_driver_plan.md` §7-2 (= audio gate Step 2 = FM 6ch 試料楽曲、 SubC 全体の達成 target)

### 3-2. YM2610 FM register layout (= nullsound `ym2610.inc` 参照)

#### Common
- `REG_FM_LFO_CONTROL` (0x22) — LFO 全体制御
- `REG_FM_KEY_ON_OFF_OPS` (0x28) — keyon/keyoff (= bit 4-7 slot mask + bit 0-2 ch index)

#### FM channel 1 (= ch index 0、 port A 経由)
- `REG_FM1_OP1_DETUNE_MULTIPLY` (0x31)
- `REG_FM1_OP3_DETUNE_MULTIPLY` (0x35)
- `REG_FM1_OP2_DETUNE_MULTIPLY` (0x39)
- `REG_FM1_OP4_DETUNE_MULTIPLY` (0x3D)
- `REG_FM1_OP1_TOTAL_LEVEL` (0x41)
- ... (op2/3/4 同様、 +4 ずつ)
- `REG_FM1_OP1_KEY_SCALE_ATTACK_RATE` (0x51)
- `REG_FM1_OP1_AM_ON_DECAY_RATE` (0x61)
- `REG_FM1_OP1_SUSTAIN_RATE` (0x71)
- `REG_FM1_OP1_SUSTAIN_LEVEL_RELEASE_RATE` (0x81)
- `REG_FM1_OP1_SSG_EG` (0x91)
- `REG_FM1_FNUM_1` (0xA1) — fnum lower 8 bit
- `REG_FM1_BLOCK_FNUM_2` (0xA5) — block + fnum upper 3 bit
- `REG_FM1_FEEDBACK_ALGORITHM` (0xB1)
- `REG_FM1_L_R_AMSENSE_PMSENSE` (0xB5)

#### 注意: 上記は **FM ch 1** (= port A、 ch index 0) の register

ch index 0/1/2 は port A、 ch index 3/4/5 (= YM2610B FM 5-6) は port B。 SubC-1 では **ch 1 のみ** (= 0x31 / 0x41 / 0x51 / ... / 0xA1 / 0xA5 / 0xB1 / 0xB5、 全て port A、 ch index 0 想定で末尾 +0)。

ただし nullsound `ym2610.inc` の REG_FM1_* は **+1 がついている**(= 0x31, 0x41, ...)。 これは **ch index 0 + 末尾 +1** という命名。 register address としては 0x30+0=0x30 が ch 1、 +1=0x31 が ch 2... という別 chip 命名。

PMD V4.8s では FM 1 = ch index 0、 register 0x30 (= +0)。 nullsound `REG_FM1_OP1_DETUNE_MULTIPLY = 0x31` は YM2610 spec で「FM channel 1 の OP1 DT/ML」 = 実際には ch index 0 = address 0x30 のはず。 命名の確認が必要。

**Codex が build 中に実 register address を確認**(= 既存 nullsound source `/Users/koshikawamasato/Projects/neo-sisters/vendor/ngdevkit/nullsound/ym2610.s` の `ym2610_reset` で FM keyon-off に何を書いているか参照)。

### 3-3. PMD V4.8s の neiroset routine (= 音色 set 参考実装)

`/Users/koshikawamasato/Projects/neo-sisters/vendor/pmd48s/source/pmd48s/PMD.ASM` L5159 `neiroset_main` を参照:

```asm
neiroset_main:
    ;; ALG/FB 設定
    mov  dh, 0b0h - 1
    add  dh, [partb]            ; dh = 0xB0 + partb = ALG/FB register
    mov  dl, 24[bx]             ; ALG/FB 値 (= prgdat の byte 24)
    ...
    call opnset                  ; chip register write

    ;; DT/ML × 4
    mov  dh, 30h - 1
    add  dh, [partb]
    mov  cx, 4
ns01:
    mov  dl, [bx]; inc bx        ; .m 内 1 byte 読込
    rol  al, 1
    jnc  ns_ns
    call opnset                  ; chip register write
ns_ns:
    add  dh, 4                   ; +4 register (= 次 slot)
    loop ns01

    ;; TL × 4 (同様)
    ;; KS/AR × 4 (同様)
    ;; AM/DR × 4 (同様)
    ;; SR × 4 (同様)
    ;; RR/SL × 4 (同様)
```

### 3-4. 既存実装 (= Codex が SubB で実装済)

- `pmdneo_init` (= driver init)
- `ym2610_write_port_a` / `ym2610_write_port_b` (= nullsound 提供)
- `pmdneo_part_ix_from_part` (= part 番号 → IX)
- `pmdneo_part_fetch_byte` (= IX[ADDR] から 1 byte 読込)
- `pmdneo_psg_keyon` / `pmdneo_psg_keyoff` (= SSG ch volume write)
- 各 SSG handler (= comq / comv / 等)
- `psg_tune_data` (= 12 半音 SSG counter table)

これらは触らず、 FM 用の routine を **並列に追加**する形で実装。

### 3-5. 規約 / 罠

- **sdasz80 syntax**: `.area CODE` / `.area DATA` / `.db` / `.dw` / `.equ name, value`
- **重複定義禁止 symbol** (nullsound.lib 提供):
  - `snd_command_unused / 01_prepare_for_rom_switch / 03_reset_driver`
  - `ym2610_write_port_a / port_b`
  - `init_*_state_tracker / update_*_state_tracker`
- **ym2610_write_port_a の calling convention**: B = register、 C = data
- **FM register write の順序**: `REG_FM*_BLOCK_FNUM_2` (= 0xA4 系) → `REG_FM*_FNUM_1` (= 0xA0 系) の順 (= chip 内部で block latch 機構あり)
- **SubB-5/6 で発見した B reg 保存問題**: ym2610_write_port_a 呼出後に B が破壊されている可能性、 keyoff 系では push/pop bc が必要 (= pmdneo_psg_keyoff で実装済)。 fm 系でも同じ pattern。

### 3-6. build 経路

- `bash scripts/build-poc.sh` (= cwd は pmdneo root)
- 既存の bin2db.py + sample_m.s 経路は維持 (= SAMPLE.M data は引き続き組込)

### 3-7. 参考実装の場所

- `/Users/koshikawamasato/Projects/pmdneo/vendor/ngdevkit-examples/06-sound-adpcma/user_commands.s` (= sound command 流儀の参考)
- `/Users/koshikawamasato/Projects/neo-sisters/vendor/ngdevkit/nullsound/ym2610.s` (= ym2610_reset の FM keyoff pattern)
- `/Users/koshikawamasato/Projects/neo-sisters/vendor/pmd48s/source/pmd48s/PMD.ASM` L5159 (= neiroset_main の x86 実装、 Z80 化の参考)

---

## 4. 完了基準

### 4-1. build 通過

`bash scripts/build-poc.sh` が exit 0 で完了。

### 4-2. audio gate (= 聴感確認、 user 担当)

期待動作:
1. 「PMDNEO Phase 1 PoC」 表示
2. **FM ch 1 から C4 相当の音が出る** (= 「ぼー」「ブー」「ピー」 等の持続音、 SSG とは違う FM 特有の音色)
3. 持続音 (= keyoff しない、 ずっと鳴り続ける)
4. 異音 / クラックル / hang up なし
5. SSG 側は無音 (= test_play_fm_c4 で SSG を触らないため、 mixer は 0x38 のままだが volume は 0x00)

不合格 case:
- **完全無音**: 音色 set 失敗、 keyon 失敗、 fnumset 失敗、 register address 間違い
- **異音 / クラックル**: 音色 register 設定が壊れている、 register write 順序ミス
- **hang up**: 無限 loop 等の bug

### 4-3. user 報告内容

- build 結果 (exit code、 PMDNEO.rel size、 pmdneo_driver.ihx size)
- Codex は **commit せず diff のまま終了**
- Claude Code が session log + diff を review、 user に総合判断 report
- user 聴感確認後に commit + push

---

## 5. 注意点

### 5-1. FM の音色 set 順序

PMD V4.8s `neiroset_main` の順序:
1. ALG/FB (= 0xB0)
2. DT/ML × 4 op (= 0x30/0x34/0x38/0x3C)
3. TL × 4 op (= 0x40/0x44/0x48/0x4C)
4. KS/AR × 4 op (= 0x50/0x54/0x58/0x5C)
5. AM/DR × 4 op (= 0x60/0x64/0x68/0x6C)
6. SR × 4 op (= 0x70/0x74/0x78/0x7C)
7. RR/SL × 4 op (= 0x80/0x84/0x88/0x8C)
8. (SSG-EG は SubC-1 では使わない、 0x90-0x9C は触らない or 0 書込)

### 5-2. fnumset の FM 用 fnum_data

SSG 用 `psg_tune_data` (= 12-bit counter) と FM 用 `fnum_data` (= 11-bit fnum) は **別 table**。 値も異なる (= analysis §5-1-1 で fnum_data の値を確認)。

PMDNEO では **両方の table を持つ**(= psg_tune_data 既存、 fnum_data 新規追加)。 命名:
- `psg_tune_data` = SSG 用 (既存)
- `fnum_data` = FM 用 (新規、 SubC-1 で追加)

### 5-3. register 0xA4 → 0xA0 の順序

YM2610 FM block + fnum 設定は:
- 0xA4 (= block + fnum upper 3 bit) を書く
- chip 内部で latch
- 0xA0 (= fnum lower 8 bit) を書く
- 両方揃って実効

逆順 (= 0xA0 → 0xA4) だと latch が壊れて音程ずれる。

### 5-4. carrier 判定 (= TL volume 用)

ALG = 7 では **全 op が carrier**(= 加算合成)。 全 op の TL を volume として set。

ALG = 0-6 では一部 op が modulator、 modulator の TL は固定 (= 音色 byte の値)、 carrier のみ volume に応じて TL 変化。 これは SubC-1 では考慮不要 (= ALG = 7 hardcoded)。

### 5-5. keyon の register 0x28

format:
- bit 7-4: slot mask (op4, op3, op2, op1) = 0xF (= 全 op keyon) or 0x0 (= 全 op keyoff)
- bit 3: 0 = port A (= ch 1-3)、 1 = port B (= ch 4-6)
- bit 2-0: ch index (0-2 = ch 1-3 within port、 ch 4-6 は port B + ch index 0-2)

ch 1 の全 op keyon = `0xF0 | 0x00 = 0xF0` (port A + ch 0 + slot 全)
ch 4 の全 op keyon = `0xF0 | 0x04 = 0xF4` (port B + ch 0 + slot 全)

注意: register 0x28 自体は **port A**で書く (= write_port_a で B = 0x28、 C = 0xF0)。 ch 4-6 を keyon するときも write_port_a。 register 0x28 自体は port A 専用 register (= 全 ch 共通の keyon controller)。

### 5-6. audio gate 義務

driver/runtime 層 touch なので、 commit 前に user 聴感確認が **必須**。 Codex は build 通過まで、 commit + push は user 確認後に Claude Code が担当。

### 5-7. 「ぼー」 / 「ブー」 の意味

FM ALG=7 + 4 op carrier + DT0/ML1 + TL=0x18 + AR=31 + DR=0 + SR=0 + RR=15 = simple な持続音 (= sustain phase で固定 volume、 release は keyoff 後)。 SubC-1 では keyoff しないので持続音が鳴り続ける。

聴感は SSG (= square wave、 「ぶ」 系) とは違って FM の合成音 (= 「ぼ」 「ブ」 系の柔らかい音、 ただし simple FM なので芯はある)。

---

## 6. 参照

### 6-1. 既存 file

- `src/driver/PMD_Z80.inc` (= 拡張対象、 既存 PSG 系 routine の後ろに FM 系を追加)
- `src/driver/IRQ.inc` (= snd_command_02_play_song の call 先変更)
- `src/driver/REGMAP.inc` (= nullsound REG_* 定数を include 済、 FM 系 register 名は使える)

### 6-2. 設計書

- `docs/design/analysis_m_data_structure.md` §5-1-1 (= fnum_data 12 半音 table)
- `docs/design/analysis_m_data_structure.md` §5-7 (= 音色データ format)
- `docs/design/phase2_driver_plan.md` §7-2 (= audio gate Step 2)

### 6-3. 参考実装

- `vendor/ngdevkit/nullsound/ym2610.s` (= ym2610_reset の FM keyoff pattern)
- `vendor/pmd48s/source/pmd48s/PMD.ASM` L5159 (= neiroset_main x86)

---

## 7. 想定 commit message (= Claude Code review 後)

```
feat(driver): SubC-1 — FM 1 ch 単体発音 (audio gate Step 2 前段)

Phase 2 SubC 段階分割の 1 番目。 FM ch 1 (= Part A) で hardcoded 音色 +
hardcoded note (= C4) の持続音を発音。 SubB-3 (= 最初の音発生) と同じ
最小目標で、 FM driver 経路の最小実証。

実装内容 (Codex 担当、 Claude Code 設計):
- PMD_Z80.inc:
  - test_play_fm_c4 routine 新設 (= FM ch 1 に音色 set + fnumset + keyon)
  - fm_voice_data_default data 新設 (= 25 byte simple FM 音色、 ALG=7 + 4 op carrier)
  - fnumset_fm routine 新設 (= note byte → register 0xA4 + 0xA0 書込)
  - fnum_data table 新設 (= FM 用 12 半音 fnum、 PMD V4.8s 流用)
- IRQ.inc: snd_command_02_play_song の call 先を pmdneo_load_m → test_play_fm_c4
  に変更 (= SubC-1 検証中は SAMPLE.M 駆動を一時停止、 SubC-3 で復帰)

audio gate (= memory rule):
- FM ch 1 から C4 相当の持続音 (= user 聴感確認、 「ぼー」 「ブー」 系)
- SSG 側は無音 (= test_play_fm_c4 で SSG 触らない、 volume 0 のまま)
- 異音 / クラックル / hang up なし

これで SubC-1 完了。 SubC-2 (= cmdtbl FM + commands + fmmain で FM 1 ch
MML 駆動) に進む準備完成。

Codex zero-trust review (Claude Code):
- session log: ~/.codex/sessions/2026/05/08/...
- 指示書: docs/design/handoff/subC1-fm-single-note.md
- 範囲外修正がある場合は事前申告 + comment 記述、 zero-trust 透明性

Co-Authored-By: Codex (codex-rescue) <noreply@openai.com>
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

---

[本書は handoff 待ち。 user OK で Claude Code が codex:codex-rescue agent を Agent tool で起動]
