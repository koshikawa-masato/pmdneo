# SubB-5/6 単体検証 — Codex 向け詳細設計書

	位置付け: Phase 2 SubB-5/6 単体検証作業の Codex 引継ぎ書
	書き手: Claude Code (= zero-trust orchestration の実装設計担当)
	読み手: Codex (実装担当)
	状態: handoff 待ち

---

## 0. 役割分担

- **Claude Code (= 私)**: 設計書執筆、 完了基準の定義、 Codex 実装後の session log + diff review
- **Codex**: 本書を読んで実装、 build 通過まで持っていく
- **user (越川氏)**: judgment、 Codex 実装後の audio gate 聴感確認

---

## 1. 背景と現状

### 1-1. 直近の到達点

PMDNEO Phase 2 SubB-4 が `commit 7f937d9` で完成済 (= ドレミファソラシド + 末尾 keyoff の audio gate 通過)。 Codex 自身が同 commit で SubB-5 (cmdtblp dispatch handler 79 entry) と SubB-6 (3 ch psgmain loop 骨格) も先取り実装済。

### 1-2. 検証していない範囲

`pmdneo_psgmain` を含む psgmain 経路は **driver_song_ready = 1 のときのみ駆動**する設計だが、 driver_song_ready を立てる経路が未実装。 つまり psgmain 経路は **実 build に組み込まれているが一度も動作確認されていない**。

SubB-7 (= SAMPLE.M 駆動) に進む前に、 hardcoded MML data で psgmain の動作を検証する必要がある。 これが本タスク = **SubB-5/6 単体検証**。

### 1-3. 検証の意義

- psgmain の per-part main loop ロジック (= length decrement / opcode 0x00-0x7F 解釈 / 0x80 part end / 0xB1-0xFF dispatch) が想定通り動くか確認
- pmdneo_part_ix_from_part / pmdneo_part_fetch_byte の IX-based access pattern が動作するか確認
- driver_song_ready flag による mode 切替が機能するか確認
- SubB-7 で SAMPLE.M を投入する前に psgmain の信頼性を担保

---

## 2. 作業内容

### 2-1. 実装する file

- `src/driver/PMD_Z80.inc`
  - `test_play_psgmain` routine を新規追加 (= test_play_scale の代替)
  - `test_mml_data` data を新規追加 (= hardcoded MML byte 列)
- `src/driver/IRQ.inc`
  - `snd_command_02_play_song` で `test_play_scale` ではなく `test_play_psgmain` を call するよう変更
  - polling loop は従来通り維持

### 2-2. 変更しない file

- `src/driver/WORKAREA.inc` — Codex 既実装の field offset / driver_state field / scale_tick 16-bit を温存
- `src/driver/REGMAP.inc` — 変更不要
- `src/driver/KR_STUB.inc` — 変更不要
- `src/driver/ADPCMA_DRV.inc` / `ADPCMB_DRV.inc` — Phase 3 / SubE で扱う
- `vendor/ngdevkit-examples/00-template/main.c` — 変更不要 (= 既存の cmd 3 → cmd 2 経路は維持)

### 2-3. test_play_psgmain の仕様

```
入力: なし
動作:
  1. SSG ch A volume を 0x0F (max) に設定 (= chip register 0x08 = 0x0F)
     (= mixer 0x07 は pmdneo_init で 0x38 set 済、 ここでは触らない)
  2. PART_SSG1 (= part 番号 6) の workarea を IX に load
     (= pmdneo_part_ix_from_part を使う)
  3. PART_OFF_ADDR(ix) = test_mml_data の address (= LE 16-bit で書込)
  4. PART_OFF_LOOP(ix) = 0 (= loop なし)
  5. PART_OFF_LEN(ix) = 0 (= 即座に最初の opcode 解釈に進む)
  6. PART_OFF_VOLUME(ix) = 0x0F (= max)
  7. driver_song_ready = 1 (= song mode に切替)
  8. ret
破壊: A、 B、 C、 D、 E、 H、 L、 IX
```

### 2-4. test_mml_data の仕様

PMD V4.8s opcode format に整合:

```
;; 8 note 順次発音 (= ドレミファソラシド)、 各 note 51 tick 持続
;; opcode format: [note byte (OCT 4 bit + ONKAI 4 bit)] [length byte]
;; 例: 0x10 0x33 = OCT 1 + ONKAI 0 (C4) を 51 (0x33) tick 持続
test_mml_data:
        .db 0x10, 0x33     ; C4 (ド)
        .db 0x12, 0x33     ; D4 (レ)
        .db 0x14, 0x33     ; E4 (ミ)
        .db 0x15, 0x33     ; F4 (ファ)
        .db 0x17, 0x33     ; G4 (ソ)
        .db 0x19, 0x33     ; A4 (ラ)
        .db 0x1B, 0x33     ; B4 (シ)
        .db 0x20, 0x33     ; C5 (1 octave 上のド)
        .db 0x80           ; part end
```

length 0x33 = 51 tick = TIMER-B 周期 488 µs × 51 ≈ 25 ms。 SubB-4 の SCALE_TICK_INITIAL = 0x0033 と同じ値だが、 SubB-4 の scale_tick は 16-bit (= 0x0033)、 こちらは 8-bit (= 51)。 Codex の psgmain 実装では `PART_OFF_LEN` が 1 byte = 8-bit decrement なので、 0x33 はそのまま 51 tick。 25 ms は短いが、 8 note 連続なら聴感で確認可能 (= 8 × 25 ms = 200 ms)。

**もし 200 ms が短すぎる聴感の場合は、 length を 0xFF (= 255 tick = 約 124 ms) に変更可能。 8 note × 124 ms = 約 1 sec で SubB-4 と同等。**

### 2-5. snd_command_02_play_song の修正

既存:
```asm
snd_command_02_play_song::
        call    pmdneo_init
        call    test_play_scale       ; ← これを変更
pmdneo_play_loop::
        ...
```

変更後:
```asm
snd_command_02_play_song::
        call    pmdneo_init
        call    test_play_psgmain     ; ← psgmain 経路に切替
pmdneo_play_loop::
        ...                           ; polling loop は従来通り維持
```

### 2-6. 既存 test_play_scale + scale_notes は残す

`test_play_scale` / `scale_notes` / SCALE_TICK_INITIAL の既存実装は **削除しない**。 SubB-5/6 単体検証で問題が出た場合の比較対象として残す。 IRQ.inc で call 先を切り替えるだけ。

---

## 3. 前提 (Codex が知っておくべき context)

### 3-1. 設計書 (= 既に確定済の仕様)

- `docs/design/mn_binary_layout.md` — `.mn` binary layout 仕様
- `docs/design/ppz_to_adpcma_mapping.md` — PPZ → ADPCM-A 翻訳 mapping
- `docs/design/phase2_driver_plan.md` — Phase 2 driver 実装計画
- `docs/design/analysis_m_data_structure.md` — `.m` バイナリ format 解析 (v3 完了)

特に重要な箇所:
- analysis §4-3 cmdtblp 完全マップ (= Codex が既実装した cmdtblp 79 entry の根拠)
- analysis §4-7-1〜13 handler 別引数 byte 数表
- analysis §5 part body opcode 列詳細 (= PSG part の opcode 解釈)

### 3-2. 既存実装 (= Codex 自身が SubB-4 で実装済)

`src/driver/PMD_Z80.inc` (953 行) と `src/driver/WORKAREA.inc` に以下が実装済:

- `pmdneo_init`: SSG silent init + TIMER-B 起動 + driver_state init + ei
- `pmd_z80_main`: driver_song_ready check で scale demo / song mode 切替
- `pmd_z80_main_scale_stop`: scale 終了時の 3 ch keyoff
- `fnumsetp` / `fnumsetp_ch`: B = channel index で SSG ch A/B/C 切替
- `psg_tune_data`: 12 半音 base counter table
- `pmdneo_song_main`: PSG 3 ch loop で psgmain 順次 call
- `pmdneo_part_ix_from_part`: A = part 番号 → IX
- `pmdneo_part_fetch_byte`: IX[ADDR] から 1 byte 読込 + ptr 進める
- `pmdneo_psg_keyon` / `pmdneo_psg_keyoff`: ch ごとの SSG volume write
- `pmdneo_psgmain`: per-part main loop 骨格
- `commandsp` + `cmdtblp`: PSG dispatch table 79 entry
- `jumpN` (jump0-jump16): 引数 byte skip
- PSG handler 群 (comq/2/3/4 / comv / comt / comtie / comd / comdd / comstloop / comedloop / comexloop / comlopset / comshift / comshift2 / comvolupp / comvolupp2 / comvoldownp / comvoldownp2 / lfoset / lfoset_delay / lfoswitch / psgenvset / extend_psgenvset / psgnoise / psgnoise_move / psgsel / 他)
- `psg_fine_regs` / `psg_coarse_regs` / `psg_volume_regs`: ch index → register table

### 3-3. WORKAREA.inc の field offset 定数

```
PART_OFF_ADDR    = 0   ; 2 byte stream pointer
PART_OFF_LOOP    = 2   ; 2 byte loop start
PART_OFF_LEN     = 4   ; 1 byte length counter
PART_OFF_QDATA   = 5   ; 1 byte q
PART_OFF_QDATB   = 6   ; 1 byte Q
PART_OFF_QDAT2/3 = 7/8
PART_OFF_VOLUME  = 9   ; 1 byte volume
PART_OFF_SHIFT   = 10  ; 1 byte transposition
PART_OFF_NOTE    = 11
PART_OFF_LOOPCNT = 12
PART_OFF_LFOSWI  = 13
PART_OFF_PSGPAT  = 14
PART_OFF_TIEFLAG = 15
PART_OFF_ENVF/PAT/PV2/PR1/PR2/ENVVOL = 16-21
PART_OFF_FLAGS   = 22

PART_SSG1 = 6   ; G part
PART_SSG2 = 7   ; H part
PART_SSG3 = 8   ; I part
```

### 3-4. 規約 / 罠

- **sdasz80 syntax**: `.area CODE` / `.db` / `.dw` / `.equ name, value` / `name = value`、 immediate value は `#imm`、 `::` で global label
- **calling convention** (chip 駆動): nullsound 公式の `ym2610_write_port_a` / `_b` を使用、 B = register、 C = data
- **重複定義禁止 symbol** (nullsound.lib 提供):
  - `snd_command_unused` / `snd_command_01_prepare_for_rom_switch` / `snd_command_03_reset_driver`
  - `ym2610_write_port_a` / `ym2610_write_port_b`
  - `init_*_state_tracker` / `update_*_state_tracker`
  - `state_timer_*` の一部
- **driver_song_ready のサイズ**: WORKAREA.inc で `.ds 1` (= 1 byte) として宣言済 (= driver_state の field 化部分)

### 3-5. build 経路

- `cd /Users/koshikawamasato/Projects/pmdneo`
- `bash scripts/build-poc.sh` で sdasz80 build + nullsound.lib link + ROM 焼込
- `cd vendor/ngdevkit-examples/00-template && make gngeo` で起動確認
- ngdevkit 関連 file path は ngdevkit が brew install 済なら自動解決

### 3-6. user main.c の sound command 経路

`vendor/ngdevkit-examples/00-template/main.c` で:
```c
*REG_SOUND = 3;
ng_wait_vblank();
ng_wait_vblank();
*REG_SOUND = 2;
```

つまり cmd 3 (= nullsound default reset) → 2 frame VBlank wait → cmd 2 (= snd_command_02_play_song)。 この経路は **変更しない**。

---

## 4. 完了基準

### 4-1. build 通過

`bash scripts/build-poc.sh` が exit 0 で完了 (= sdasz80 + sdldz80 + ROM 焼込全て成功)。

### 4-2. audio gate (= 聴感確認、 user 担当)

期待動作:
1. 「PMDNEO Phase 1 PoC」 表示
2. **ドレミファソラシド** (= 8 note up scale) が短い間隔で順次発音
3. 8 note 完了後は無音 (= part end の 0x80 で psgmain が PART_OFF_ADDR を 0 に clear、 next iteration で early return)
4. 異音 / クラックル / hang up なし

length = 0x33 (= 51 tick) で 8 note × 25 ms ≈ 200 ms の素早いスケール。 もし聴感で確認しづらいなら length を 0xFF に変えて 8 note × 124 ms ≈ 1 sec にする調整も許可。

### 4-3. SubB-4 と SubB-5/6 の比較で確認できること

- SubB-4 (= scale demo モード、 driver_song_ready = 0) は test_play_scale + scale_notes + pmd_z80_main_scale ロジックで動作
- SubB-5/6 (= song mode、 driver_song_ready = 1) は test_play_psgmain + test_mml_data + pmdneo_psgmain (= cmdtblp dispatch 経由) で動作
- どちらも同じ 8 note ドレミファソラシドが鳴れば、 psgmain 経路は scale demo と同等の動作可能性が確認される

### 4-4. user 報告内容 (= Codex から user に渡す)

- build 結果 (exit code、 PMDNEO.rel size、 pmdneo_driver.ihx size)
- 聴感確認は user 担当のため、 Codex は **commit せず diff のまま終了**して Claude Code に handoff
- Claude Code が session log + diff を review して user report、 user 判断で commit + push

---

## 5. 注意点

### 5-1. PSG part 番号と SSG ch index の対応

| part 番号 | letter | SSG ch | psg_*_regs index |
|---|---|---|---|
| 6 (PART_SSG1) | G | A | 0 |
| 7 (PART_SSG2) | H | B | 1 |
| 8 (PART_SSG3) | I | C | 2 |

`pmdneo_psgmain` は `sub #PART_SSG1` で channel index (0-2) を計算しているので、 PART_SSG1 の workarea に MML data を流せば自動的に SSG ch A (= channel index 0) で再生される。

### 5-2. PART_OFF_LEN が 0 のとき

Codex の psgmain 実装で `length == 0` のときは即座に次 opcode 解釈に進む (= jr z, pmdneo_psgmain_parse)。 つまり test_play_psgmain で初期値 0 にすれば、 cmd 2 で songmain が呼ばれた直後に最初の note が発音される。

### 5-3. driver_song_ready の効果

- 0 (= scale demo モード): pmd_z80_main → pmd_z80_main_scale で scale_notes 経由で発音
- 1 (= song mode): pmd_z80_main → pmdneo_song_main → pmdneo_psgmain (× 3 ch) で MML 解釈

test_play_psgmain で `driver_song_ready = 1` にすれば、 polling loop の中の TIMER-B tick ごとに pmdneo_psgmain が呼ばれて MML 解釈が進む。

### 5-4. PART_SSG2 / PART_SSG3 の workarea

PART_SSG2 / PART_SSG3 の workarea は **PART_OFF_ADDR = 0 のまま**で OK。 Codex の psgmain 実装で:
```asm
ld      a, PART_OFF_ADDR(ix)
or      PART_OFF_ADDR+1(ix)
ret     z
```
で early return する。 つまり 1 ch だけ MML data を渡しても問題なく単体検証できる。

### 5-5. audio gate 義務

driver/runtime 層 touch なので、 commit 前に user 聴感確認が **必須**。 Codex は build 通過まで、 commit + push は user 確認後に Claude Code が担当。

---

## 6. 参照

### 6-1. 既存 file

- `src/driver/PMD_Z80.inc` (= Codex 既実装の psgmain 経路を読み解いてから実装)
- `src/driver/WORKAREA.inc` (= field offset 定数 + driver_song_ready 定義)
- `src/driver/IRQ.inc` (= snd_command_02_play_song を変更)

### 6-2. 設計書

- `docs/design/analysis_m_data_structure.md` §4-3 / §5 (= cmdtblp + opcode 解釈)
- `docs/design/phase2_driver_plan.md` §3 / §6 (= driver source 構造、 sub-phase 計画)

### 6-3. nullsound 公式 source (= 参考実装)

- `/Users/koshikawamasato/Projects/neo-sisters/vendor/ngdevkit/nullsound/entrypoint.s` (= cmd dispatch 経路)
- `/Users/koshikawamasato/Projects/neo-sisters/vendor/ngdevkit/nullsound/timer.s` (= update_timer_state_tracker)

---

## 7. 想定 commit message (= Claude Code review 後)

```
feat(driver): SubB-5/6 単体検証 — hardcoded MML data で psgmain 駆動

Codex 既実装の pmdneo_psgmain (= per-part main loop 骨格) を hardcoded
MML data で駆動して動作検証。 driver_song_ready = 1 set + Part SSG1
workarea の ADDR に test_mml_data ptr 格納で SSG ch A の 1 part が再生
される。

実装内容:
- PMD_Z80.inc: test_play_psgmain routine + test_mml_data 追加
- IRQ.inc: snd_command_02_play_song で test_play_scale ではなく
  test_play_psgmain を call するよう変更

audio gate (= memory rule):
- ドレミファソラシド (8 note up scale) が psgmain 経路で発音 (user 聴感確認済)
- length = 0x33 (= 51 tick) で 8 note × 25 ms ≈ 200 ms の素早いスケール
- 異音 / クラックル / hang up なし

これで SubB-5/6 (= cmdtblp dispatch + psgmain 3 ch loop 骨格) の動作検証
完了。 SubB-7 (= SAMPLE.M 駆動) に進める準備完成。

Co-Authored-By: Codex (codex-rescue) <noreply@openai.com>
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

---

[本書は handoff 待ち。 user OK で Codex に渡す]
