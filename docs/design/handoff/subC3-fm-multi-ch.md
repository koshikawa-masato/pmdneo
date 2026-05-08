# SubC-3 — FM 4 ch MML 駆動 (chip ch 2/3/5/6 = Part B/C/E/F)

	位置付け: Phase 2 SubC 段階分割の 3 番目 (= audio gate Step 2 = FM 試料楽曲)
	書き手: Claude Code
	実装担当: Codex (= codex:codex-rescue agent 経由)
	状態: 完了 (audio gate pass、 commit 済)

---

## 0. 役割分担

- Claude Code (= 私): 設計書執筆、 完了基準定義、 Codex 実装後の review
- Codex: 本書を読んで実装、 build pass まで
- user: 判断、 audio gate

---

## 1. 背景

### 1-1. SubC-1/2 達成

- SubC-1 (commit 23f1bd4): chip ch 2 単音発音 (= test_play_fm_c4)
- SubC-2 (commit 71749d1): chip ch 2 1 oct スケール (= test_play_fm_scale_b、 scale_mode 分岐)
- ADR-0001 (commit b4f45a3): 楽曲 Part A/D 不使用の (C) 方針確定

### 1-2. SubC-3 = 4 ch FM MML 駆動

SubB-7 の SAMPLE.M 駆動 (= 既存 psgmain × 3 ch、 cmdtblp dispatch、 PART_OFF_*)
を **FM 4 ch (= chip ch 2/3/5/6 = Part B/C/E/F)** に展開する。

ADR-0001 (C) 方針: driver は 6 ch FM dispatch を実装するが、 試料 MML
楽曲は Part B/C/E/F の 4 ch のみ使用 (= Part A/D は楽曲側で空)。

---

## 2. 実装内容

### 2-1. 全体構造

既存 PSG handler (= cmdtblp の 79 entry、 commandsp dispatcher、 各 com*)
は **そのまま流用** する。 chip-specific は keyon / keyoff のみ。 新設は:

- `pmdneo_fm_keyon` / `pmdneo_fm_keyoff` (= per ch dispatch、 chip register
  address を ch index で計算)
- `fmmain` (= psgmain の FM 版、 keyon/keyoff 経路だけ差替)
- `pmdneo_song_main` 拡張 (= FM 6 ch + PSG 3 ch dispatch)
- `pmdneo_init` 拡張 (= 4 ch 全部に default voice 書込、 keyon は fmmain で)
- 試料 MML data (= 4 ch FM、 hardcoded、 各 ch 数 note)

### 2-2. pmdneo_fm_keyon / pmdneo_fm_keyoff (per ch dispatch)

```
入力:
  pmdneo_fm_keyon : A = note byte、 B = ch index (= 0..5 = PART_FM1..FM6)
  pmdneo_fm_keyoff: B = ch index

ch index → chip register address mapping:
  ch index 0 (= chip ch 1): port A、 末尾 +0、 keyon 0xF0
  ch index 1 (= chip ch 2): port A、 末尾 +1、 keyon 0xF1
  ch index 2 (= chip ch 3): port A、 末尾 +2、 keyon 0xF2
  ch index 3 (= chip ch 4): port B、 末尾 +0、 keyon 0xF4
  ch index 4 (= chip ch 5): port B、 末尾 +1、 keyon 0xF5
  ch index 5 (= chip ch 6): port B、 末尾 +2、 keyon 0xF6

  ※ register 0x28 (keyon) 自体は port A 専用。 port B FM ch でも write_port_a
     を使い、 lower nibble で port B + ch index を encode する。
     port B = bit 2 set (= 0x04)、 port A = bit 2 clear (= 0x00)。
     ex: chip ch 4 (= port B index 0) → 0x04、 chip ch 5 → 0x05、 chip ch 6 → 0x06。

動作 (keyon):
  1. ch_to_reg_offset_table[ch_index] で 末尾 offset (0/1/2/0/1/2) を取得
  2. ch_to_port_select_table[ch_index] で port A/B routine pointer を取得
  3. fnumset_fm_ch (= 既存 fnumset_fm の per-ch 版、 0xA1+offset / 0xA5+offset
     を ch index で動的に決める) で fnum 書込
  4. register 0x28 ← keyon_value_table[ch_index] (= 0xF0..0xF6 系)

動作 (keyoff):
  1. register 0x28 ← keyoff_value_table[ch_index] (= 0x00..0x06 系、 slot mask 0)
```

#### 既存 fnumset_fm の per-ch 化

SubC-2 までの `fnumset_fm` は chip ch 2 hardcoded (= 0xA5/0xA1)。 SubC-3 で
**ch index 引数を受けて per-ch で書く**形に拡張する:

```
fnumset_fm:
        ;; A = note byte、 B = ch index (= 0..5)
        push    bc                      ; ch index 保存
        ;; 既存 ONKAI/OCT 計算 (= block と fnum upper の OR)
        ...
        ;; ch index → port (A/B) と reg 末尾 offset を計算
        pop     bc                      ; ch index 復元
        ld      a, b
        cp      #3
        jr      c, fnumset_fm_porta     ; ch 0/1/2 = port A
        sub     #3                      ; ch 3/4/5 → port B、 ch index 0/1/2
        ;; port B 経路: ym2610_write_port_b、 reg 末尾 0/1/2
        ...
fnumset_fm_porta:
        ;; port A 経路: ym2610_write_port_a、 reg 末尾 0/1/2
        ...
```

実装は per-ch register offset を `add a, #0xA4` / `add a, #0xA0` で動的計算。
port 切替は dispatch table or 直接 if 分岐。

### 2-3. fmmain (= psgmain の FM 版)

既存 `pmdneo_psgmain` を **copy + paste** して以下のみ差替:

- `pmdneo_psg_keyon` → `pmdneo_fm_keyon`
- `pmdneo_psg_keyoff` → `pmdneo_fm_keyoff`
- `sub #PART_SSG1` → `sub #PART_FM1` で ch index 計算 (= 0..5)

`commandsp` / `cmdtblp` / 各 PSG handler (= comq / comv / comt / etc.) は
**全部流用**。 PART_OFF_VOLUME / PART_OFF_NOTE / PART_OFF_LEN 等の field は
chip-agnostic で FM でも同じ意味。

### 2-4. pmdneo_init 拡張: 4 ch 音色 set

既存 `pmdneo_init` 末尾に 4 ch (= chip ch 2/3/5/6) への default voice 書込
を追加。 keyon は **しない** (= fmmain が note 駆動で keyon)。

```
        ;; SubC-3: 4 ch FM 音色 + PAN 設定 (default voice)
        ld      b, #1                   ; ch index 1 (= chip ch 2 = Part B)
        call    pmdneo_fm_voice_set_default
        ld      b, #2                   ; ch index 2 (= chip ch 3 = Part C)
        call    pmdneo_fm_voice_set_default
        ld      b, #4                   ; ch index 4 (= chip ch 5 = Part E)
        call    pmdneo_fm_voice_set_default
        ld      b, #5                   ; ch index 5 (= chip ch 6 = Part F)
        call    pmdneo_fm_voice_set_default
```

`pmdneo_fm_voice_set_default` は SubC-1 の音色 set + PAN 経路を per-ch 化
した routine (= ch index 0..5 で chip register address を動的計算)。

### 2-5. pmdneo_song_main 拡張

```
pmdneo_song_main::
        ld      a, #PART_FM1
        call    fmmain
        ld      a, #PART_FM2
        call    fmmain
        ld      a, #PART_FM3
        call    fmmain
        ld      a, #PART_FM4
        call    fmmain
        ld      a, #PART_FM5
        call    fmmain
        ld      a, #PART_FM6
        call    fmmain
        ld      a, #PART_SSG1
        call    pmdneo_psgmain
        ld      a, #PART_SSG2
        call    pmdneo_psgmain
        ld      a, #PART_SSG3
        call    pmdneo_psgmain
        ret
```

driver は 6 ch FM 全部 dispatch (= ADR-0001 (C) 方針: driver は中立、
楽曲側で Part A/D 不使用)。 楽曲 MML が Part A/D に note 書いても driver
は破綻せず無音。

### 2-6. 試料 MML data (= 4 ch FM、 hardcoded)

SubB-7 の SAMPLE.M (= OPNA SSG 楽曲) は使えない (= FM 用 fnum_data table と
note byte semantics が違う)。 hardcoded で 4 ch FM 楽曲を assemble に
embed する:

```
test_fm_song_data::
        ;; OPNA layout 互換 header (= 11 part offset + rhythm addr + prgdat_adr)
        ;; offset 計算は build 時に label 引き算で算出
        .dw     test_fm_song_part_a
        .dw     test_fm_song_part_b
        .dw     test_fm_song_part_c
        .dw     test_fm_song_part_d
        .dw     test_fm_song_part_e
        .dw     test_fm_song_part_f
        .dw     test_fm_song_empty      ; G (SSG)
        .dw     test_fm_song_empty      ; H
        .dw     test_fm_song_empty      ; I
        .dw     test_fm_song_empty      ; J (ADPCM-B)
        .dw     test_fm_song_empty      ; K (Rhythm)
        .dw     test_fm_song_empty      ; rhythm addr
        .dw     test_fm_song_empty      ; prgdat_adr
        ;; -- part body --
test_fm_song_part_a:
        .db     0x80                    ; (C) 方針: Part A 空
test_fm_song_part_b:
        ;; chip ch 2 で C-D-E-F-G-A-B-C# のような 8 note arpeggio
        .db     0x40, 0x10              ; C4 length 0x10
        .db     0x42, 0x10              ; D4
        .db     0x44, 0x10              ; E4
        .db     0x45, 0x10              ; F4
        .db     0x47, 0x10              ; G4
        .db     0x49, 0x10              ; A4
        .db     0x4B, 0x10              ; B4
        .db     0x50, 0x40              ; C5 long
        .db     0x80                    ; end
test_fm_song_part_c:
        ;; chip ch 3 で 5 度上 (= G4 から始まる arpeggio)
        .db     0x47, 0x40              ; G4 ペダル
        ...
        .db     0x80
test_fm_song_part_d:
        .db     0x80                    ; (C) 方針: Part D 空
test_fm_song_part_e:
        ;; chip ch 5 で bass line (= 1 oct 下)
        .db     0x30, 0x40              ; C3 ペダル
        ...
        .db     0x80
test_fm_song_part_f:
        ;; chip ch 6 で 別声部
        ...
        .db     0x80
test_fm_song_empty:
        .db     0x80                    ; 即 end
```

note byte 仕様 (= PMD V4.8s `.m` format):
- bit 7-4: OCT (0..7)
- bit 3-0: ONKAI (0..11)
- 0x80 = end marker (PSG handler 既存仕様)

length byte: 1 tick 単位 (= TIMER-B IRQ で 1 ずつ decrement)、 SubB-7 では
pmdneo_scale_mml_length で 8 倍に scale して使用。

### 2-7. snd_command_02_play_song dispatch 変更

```
snd_command_02_play_song::
        call    pmdneo_init
        call    test_play_fm_song       ; 新設: 試料 MML を part_workarea に load して driver_song_ready 立てる
pmdneo_play_loop::
        ...
```

`test_play_fm_song` は SubB-7 の `pmdneo_load_m` の FM 版 (= part_workarea
に test_fm_song_data の 4 part offset を絶対 address で書込)。

---

## 3. 前提

### 3-1. 既存実装

- `src/driver/PMD_Z80.inc`:
  - SubC-1: test_play_fm_c4、 fnumset_fm (chip ch 2 hardcoded)、 fnum_data、
    fm_voice_data_default、 pmdneo_fm_write_voice_group、 pmdneo_fm_clear_ssg_eg
  - SubC-2: test_play_fm_scale_b、 scale_notes_fm
  - SubB-5/6/7: pmdneo_psgmain、 cmdtblp、 commandsp、 各 com* handler、
    pmdneo_part_ix_from_part、 pmdneo_part_fetch_byte、 pmdneo_psg_keyon/keyoff

- `src/driver/WORKAREA.inc`:
  - PART_FM1..FM6 (= 0..5)、 PART_SSG1..SSG3 (= 6..8)
  - PART_OFF_ADDR / LEN / VOLUME / NOTE / etc.
  - part_workarea (= PART_WORKAREA_SIZE × PART_COUNT)

- `src/driver/IRQ.inc`:
  - snd_command_02_play_song (= 現在 test_play_fm_scale_b dispatch)

### 3-2. ADR-0001 (C) 方針

- driver は YM2610B 仕様で 6 ch FM dispatch を実装
- 楽曲は Part B/C/E/F の 4 ch FM のみ使用
- mc compiler は Part A/D に note 書込で warning (= error にしない)
- driver は無効 ch register write で破綻せず無音

### 3-3. SubC-1/2 で確立した chip ch 2 register address

- 末尾 +1 (= 0x31, 0x41, 0x51, 0x61, 0x71, 0x81, 0x91, 0xA1, 0xA5, 0xB1, 0xB5)
- keyon = 0xF1
- keyoff = 0x01

これを ch index 0/1/2/3/4/5 → 末尾 +0/+1/+2 + port A/B + keyon 0xF0..0xF6 に
拡張。

### 3-4. fnumset_fm の per-ch 化

既存 SubC-1/2 の fnumset_fm は chip ch 2 hardcoded。 SubC-3 で per-ch 引数
を受ける形に変更する:

- 入力に B = ch index 追加
- 内部で port A/B 切替 + register address 動的計算
- 既存呼出 (= test_play_fm_c4、 test_play_fm_scale_b、 pmd_z80_main_scale_step
  の FM mode) を `B = 1` (= chip ch 2) で互換維持

### 3-5. 規約

- sdasz80 syntax
- ym2610_write_port_a / port_b: B = register、 C = data
- nullsound 重複定義禁止 (snd_command_unused / 01 / 03、 ym2610_write_*、
  init/update_*_state_tracker)
- B reg 保存問題 (= ym2610_write_port_a で B 破壊): per-ch dispatch routine で
  push/pop bc 必要

### 3-6. ビルド経路

`bash scripts/build-poc.sh` (cwd = pmdneo root)。

---

## 4. 完了基準

### 4-1. build pass

`bash scripts/build-poc.sh` exit 0。

### 4-2. audio gate (= user 聴感確認、 audio gate Step 2)

期待動作:
- chip ch 2/3/5/6 (= Part B/C/E/F) の 4 ch FM が並列演奏
- chip ch 1/4 (= Part A/D) は無音 (= driver dispatch するが無効 ch)
- SSG 側は無音 (= 試料 MML に SSG part 空)
- 4 part の音色は default voice (= ALG=7 + 4 op carrier 持続音)

合格基準:
- 4 ch が同時に発音 (= 和音 / counterpoint が聞こえる)
- 各 ch の note 切替が tempo 通りに進む
- 終端で 4 ch 全部 keyoff、 静音

不合格 case:
- 1 ch のみ発音 → fmmain dispatch 失敗 / per-ch register address 計算ミス
- 全 ch 無音 → 音色 set 失敗 / part_workarea 未 init / driver_song_ready 未立て
- ノイズ / hang up → register 上書き / 無限 loop

### 4-3. user 報告

- build 結果 (exit code、 PMDNEO.rel size、 pmdneo_driver.ihx size)
- Codex は **commit せず diff のまま終了**
- Claude Code が session log + diff を review、 user に総合判断 report
- user 聴感確認後に commit + push

---

## 5. 注意点

### 5-1. fnumset_fm 既存呼出との互換維持

SubC-1/2 で `fnumset_fm` は ch hardcoded (= chip ch 2)。 SubC-3 で per-ch 化する
際、 既存呼出 (= test_play_fm_c4、 test_play_fm_scale_b、
pmd_z80_main_scale_step の FM mode) で `B = 1` (= chip ch 2) を渡す形に修正。

### 5-2. driver_song_ready 経路

既存 SubB-7 で `driver_song_ready` flag が立つと `pmd_z80_main` は
`pmdneo_song_main` を call する経路。 SubC-3 で `pmdneo_song_main` は
FM 6 + PSG 3 = 9 ch dispatch する。

### 5-3. test_play_fm_song の役割

`pmdneo_load_m` を copy + 改造 (= header parse は同じ、 part offset を
絶対 address に変換する経路)。 試料 MML data は ROM 内 (= `.area DATA`
不可、 `.area CODE` の data として配置)。

### 5-4. 規模と段階

実装規模 ~300 行 + 試料 data ~100 byte。 内部 milestone:
1. fnumset_fm per-ch 化 (= 既存呼出を B=1 で更新)
2. pmdneo_fm_keyon / pmdneo_fm_keyoff per-ch
3. pmdneo_fm_voice_set_default per-ch
4. fmmain (= psgmain copy)
5. pmdneo_song_main 拡張
6. pmdneo_init 拡張 (= 4 ch voice set)
7. test_play_fm_song + test_fm_song_data
8. snd_command_02_play_song dispatch を test_play_fm_song に
9. build + sanity

### 5-5. audio gate 義務

driver/runtime 層 touch なので、 commit 前に user 聴感確認必須。 Codex は
build 通過まで、 commit + push は user 確認後に Claude Code 担当。

---

## 6. 参照

- `src/driver/PMD_Z80.inc` (= 拡張対象)
- `src/driver/IRQ.inc` (= dispatch 変更)
- `docs/adr/0001-fm-ch1-ch4-no-use-policy.md` (= (C) 方針)
- `docs/design/handoff/subC1-fm-single-note.md` (= chip ch 2 register 詳細)
- `docs/design/handoff/subC2-fm-scale.md` (= scale_mode 機構)

---

[本書は handoff 待ち。 user OK で Claude Code が codex:codex-rescue agent を Agent tool で起動]
