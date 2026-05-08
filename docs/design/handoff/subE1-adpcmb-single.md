# SubE-1 — ADPCM-B 単発再生 capability PoC

	位置付け: Phase 2 SubE 段階分割の 1 番目 (= ADPCM-B 経路 capability 確認)
	書き手: Claude Code
	実装担当: Codex (= codex:codex-rescue agent 経由)
	状態: 完了 (audio gate pass、 commit 済)

---

> **Errata 2026-05-08**: 本書当初は GAMEROM=puzzledp 前提で記述したが、 puzzledp の MAME romset spec は **`ymsnd:adpcmb` 配線なし** (= ADPCM-A のみ) のため、 ADPCM-B 駆動 audio gate で無音判明 (user 指摘)。 訂正先: **GAMEROM=lastbld2 (= ngdevkit 15-sound-adpcmb と同 template)**、 rom.mk を 15-sound-adpcmb から copy + Makefile の VROMTEMPLATE override 削除で build artifact が `243-*` 系に切替。 詳細は memory `reference_neogeo_rom_template_adpcmb.md`。
>
> **Errata 2: cmd 順序**: 本書当初は cmd 2 (FM song) → cmd 5 (ADPCM-B) の順で発火する想定だったが、 cmd 2 が driver 内 polling loop に入ると nullsound が新 cmd 受付不可能 (= cmd 5 dispatch されず無音)。 訂正先: **cmd 5 → cmd 2 順** で発火 (= ADPCM-B chip 内部再生 → cmd 2 polling loop 開始)。
>
> **Errata 3: delta-N**: 本書当初は ngdevkit 15 流用で delta-N = 0xcb6b (= 44.1 kHz playback)、 sample 元 24 kHz native の 1.84x 速度。 user 「o5a 基準で試して」 指摘により sample native rate (= 24 kHz) で再生する **delta-N = 0x6E96** (= 24000 × 65536 / 55555) に変更。 audio gate で gngeo 上の音と afplay の音が一致確認、 「o5a (= sample native) 基準」 として成立。

---

## 0. 役割分担

- Claude Code: 設計、 review
- Codex: 実装、 build pass まで
- user: judgment、 audio gate

---

## 1. 背景

### 1-1. Phase 2 SubC 完了

- SubC-1 (commit 23f1bd4): chip ch 2 単音発音
- ADR-0001 (commit b4f45a3): (C) 方針正式化
- SubC-2 (commit 71749d1): chip ch 2 スケール
- SubC-3 (commit 5b07a09): 4 ch FM MML 駆動 (= audio gate Step 2)

### 1-2. SubE-1 = ADPCM-B 単発再生 capability PoC

phase2_driver_plan.md §4 (= ADPCM-B 1ch dispatch) の最小機能。 NEOGEO V-ROM
bank に sample (= ngdevkit 15-sound-adpcmb の beat.wav 借用) を焼き、 chip
ADPCM-B 単発再生で経路の動作を確認する。

ngdevkit nullsound に `snd_adpcm_b_play` (= IX = 8 byte struct で chip
register write) が provided されているので driver 自前実装は不要。 SubE-1
では nullsound 既存 routine を call するだけ。

ADPCMB_DRV.inc の本格実装 (= sample 番号引数化、 Part J MML driving) は
SubE-2 以降。

---

## 2. 実装内容

### 2-1. sample asset 配置 + Makefile patch

#### file 配置

- `vendor/ngdevkit-examples/00-template/assets/beat.wav` ← copy from
  `vendor/ngdevkit-examples/15-sound-adpcmb/assets/beat.wav`
- `vendor/ngdevkit-examples/00-template/assets/samples-map.yaml` ← 新規:

```yaml
- adpcm_b:
    name: beat
    uri: file://assets/beat.wav
```

#### Makefile patch

`vendor/ngdevkit-examples/00-template/Makefile` の VROM 関連セクションに
以下を追加 (= 15-sound-adpcmb/Makefile の rule 移植):

```makefile
# ADPCM-B sample (SubE-1: ngdevkit beat.wav 借用)
$(VROM1): assets/samples-map.yaml
	$(VROMTOOL) -s $(VROMSIZE) $< -o $@

CUSTOM_GENERATE_TARGETS+=$(BUILDDIR)/assets/samples.inc

$(BUILDDIR)/assets/samples.inc: assets/samples-map.yaml
	$(VROMTOOL) --asm -s $(VROMSIZE) $< -o $(VROM1) -m $@
```

#### samples.inc include path 確保

`build/assets/samples.inc` が生成される。 driver source は `samples.inc` を
include path 経由で取り込む。 既存 `-Ibuild` だけでは `build/assets/`
までは届かないので、 build.mk の Z80FLAGS or CFLAGS_Z80 等に
`-Ibuild/assets` を追加する必要があるかもしれない (= 既存 build flag を
確認して整える)。

### 2-2. main.c cmd 5 発火追加

`vendor/ngdevkit-examples/00-template/main.c`:

```c
// 既存:
*REG_SOUND = 3;
ng_wait_vblank();
ng_wait_vblank();
*REG_SOUND = 2;     // FM song

// 追加:
ng_wait_vblank();
*REG_SOUND = 5;     // ADPCM-B beat 単発再生 (SubE-1)
```

cmd 5 は cmd 2 (FM song) と並列発火。 cmd 5 は ret する handler のため
polling loop に入らず即帰り、 FM song の polling loop は継続。 結果として
FM song 鳴りながら ADPCM-B beat が単発で重なる。

### 2-3. driver: test_play_adpcmb_beat

`src/driver/PMD_Z80.inc` 末尾に追加:

```asm
;;; ----- adpcm_b_beat_struct: ngdevkit snd_adpcm_b_play 用 8 byte 構造体 -----
;;;
;;; layout (15-sound-adpcmb/user_commands.s 参照):
;;;   .db start_lsb / start_msb (= 256 byte unit)
;;;   .db stop_lsb  / stop_msb
;;;   .dw delta-N (= 再生周波数係数、 LE)
;;;   .db l/r output (0xC0 = 両 ch on)
;;;   .db volume (0x00-0xFF)

adpcm_b_beat_struct::
        .db     BEAT_START_LSB
        .db     BEAT_START_MSB
        .db     BEAT_STOP_LSB
        .db     BEAT_STOP_MSB
        .dw     0xcb6b              ; delta-N for 44.1 kHz playback
        .db     0xC0                ; L/R both on
        .db     0xFF                ; volume max


;;; ----- test_play_adpcmb_beat: SubE-1 ADPCM-B 単発再生 -----
;;;
;;; 入力: なし
;;; 動作: nullsound snd_adpcm_b_play (IX = config struct) で beat sample 再生
;;; 破壊: A、 IX

test_play_adpcmb_beat::
        ld      ix, #adpcm_b_beat_struct
        call    snd_adpcm_b_play
        ret
```

samples.inc include は PMDNEO.s か PMD_Z80.inc 冒頭で `.include "samples.inc"`
で取り込む。 BEAT_START_LSB / MSB / STOP_LSB / MSB symbol が解決される。

### 2-4. IRQ.inc cmd 5 dispatch

`src/driver/IRQ.inc` cmd_jmptable に snd_command_05 追加:

```asm
cmd_jmptable::
        jp      snd_command_unused              ; 0
        jp      snd_command_01_prepare_for_rom_switch   ; 1
        jp      snd_command_02_play_song        ; 2
        jp      snd_command_03_reset_driver     ; 3
        jp      snd_command_unused              ; 4
        jp      snd_command_05_play_adpcmb_test ; 5  ← 追加
        init_unused_cmd_jmptable
```

(既存 cmd_jmptable の構造を確認、 init_unused_cmd_jmptable の前に cmd 5
を入れる)

```asm
;;; ----- snd_command_05_play_adpcmb_test: SubE-1 ADPCM-B 単発再生 -----
;;;
;;; cmd 2 (FM song) と並列発火。 即 ret するため polling loop に入らず、
;;; FM song 駆動を妨げない。

snd_command_05_play_adpcmb_test::
        call    test_play_adpcmb_beat
        ret
```

---

## 3. 前提

### 3-1. nullsound API

- `snd_adpcm_b_play` (`/Users/koshikawamasato/Projects/neo-sisters/vendor/ngdevkit/nullsound/adpcm.s` L308):
  - 入力: IX = 8 byte sample play config struct
  - 動作: register 0x12-0x15 (start/stop addr) + 0x19-0x1A (delta-N) + 0x1B
    (volume) + 0x11 (LR pan) + 0x10 (start bit 0x80) を書込
  - 副作用: state_adpcm_exclusive 経由で ch lock 管理 (= ongoing play 中は
    skip)
- 8 byte struct format (= 15-sound-adpcmb/user_commands.s 参照):
  - byte 0-1: start address LSB/MSB
  - byte 2-3: stop address LSB/MSB
  - byte 4-5: delta-N (LE)
  - byte 6: L/R pan (0xC0 = 両 ch)
  - byte 7: volume (0xFF = max)

### 3-2. vromtool

`vromtool` (= ngdevkit 提供) が samples-map.yaml + WAV から V-ROM bank
binary + samples.inc を生成。 既存 15-sound-adpcmb の Makefile rule を
00-template に移植する。

### 3-3. cmd 2 dispatch は維持

cmd 2 (= snd_command_02_play_song) は SubC-3 の test_play_fm_song を継続
call。 SubE-1 では cmd 5 を別 dispatch として追加するだけ、 cmd 2 経路は
触らない。

### 3-4. ADR-0001 維持

(C) 方針 (= chip ch 2/3/5/6 のみ FM 楽曲使用) は SubE-1 範囲外。 ADPCM-B
は ch 1 専用なので影響なし。

### 3-5. 既存 vendor 状態

- `vendor/ngdevkit-examples/00-template/main.c` は既に PMDNEO 用カスタマイズ
  済 (= git tracked)、 直接編集 OK
- `vendor/ngdevkit-examples/00-template/Makefile` も同様、 直接編集 OK
- `vendor/ngdevkit-examples/00-template/assets/` 配下は新規追加領域

### 3-6. 規約

- sdasz80 syntax
- ADPCMB_DRV.inc は touch しない (= SubE-2 以降で本実装、 SubE-1 では薄い
  test routine だけ)
- 既存 SubC-3 (= test_play_fm_song / fmmain / etc.) を破壊しない

---

## 4. 完了基準

### 4-1. build pass

`bash scripts/build-poc.sh` exit 0。 vromtool 経由で V-ROM bank に beat.wav
が焼き込まれ、 samples.inc が生成される。

### 4-2. audio gate (= user 聴感確認)

期待動作:
- 起動後即時に **FM song (= SubC-3 の 4 ch FM スケール) が鳴り始める**
- 起動直後に **ADPCM-B の beat sample (= drum 系 short sound) が 1 回鳴る**
  (cmd 5 発火タイミングで 1 発)
- FM song と ADPCM-B が並列に聞こえる (= 同時音 + 単発打楽器の重なり)
- ADPCM-B 終了後は FM song のみ継続

合格基準:
- ADPCM-B beat が 1 回確実に発音
- FM song が ADPCM-B の影響で乱れない
- hang up / クラックル なし

不合格 case:
- ADPCM-B 無音: V-ROM 焼き失敗 / register write 失敗 / cmd 5 dispatch 失敗
- FM song が止まる: cmd 5 が polling loop に入って block
- 音割れ / hang up: register 設定ミス

### 4-3. user 報告

- build 結果 (exit code、 PMDNEO.rel size、 pmdneo_driver.ihx size、
  202-v1.v1 size)
- Codex は **commit せず diff のまま終了**
- Claude Code が session log + diff を review、 user に総合判断 report
- user 聴感確認後に commit + push

---

## 5. 注意点

### 5-1. samples.inc include path

build/assets/samples.inc が生成される。 sdasz80 で include 解決する path
を build.mk / Makefile で確保。 既存 `-Ibuild` で届かない場合は
`-Ibuild/assets` を追加する必要あり。 build pass しないなら最初に確認。

### 5-2. cmd 5 発火タイミング

main.c の cmd 5 発火位置は cmd 2 の直後 (= ng_wait_vblank() 1 回挟む)。
cmd 5 は即 ret するため、 cmd 2 の polling loop が cmd 5 受付後に再開
する。 FM song が 1-2 frame 程度の遅延で再開しても聴感的には問題ない。

ただし、 nullsound の cmd dispatch は polling loop で受付なので、 cmd 2
が polling 中に cmd 5 を受け付けるかは要検証。 もし cmd 5 が受け付け
られなければ、 cmd 2 を後回しにして cmd 5 → cmd 2 の順で発火する形に
変更。

### 5-3. delta-N 値

beat.wav は 44.1 kHz playback として `delta-N = 0xcb6b` (= 15-sound-adpcmb
で確認済)。 これをそのまま使う。

### 5-4. audio gate 義務

driver/runtime 層 touch なので、 commit 前に user 聴感確認必須。 Codex は
build 通過まで、 commit + push は user 確認後。

---

## 6. 参照

- `vendor/ngdevkit-examples/15-sound-adpcmb/user_commands.s` (= calling
  convention 参考)
- `vendor/ngdevkit-examples/15-sound-adpcmb/Makefile` (= VROM 焼き rule)
- `vendor/ngdevkit-examples/build.mk` L106, L131-132 (= VROMTOOL rule)
- `vendor/ngdevkit/nullsound/adpcm.s` L308 (= snd_adpcm_b_play 本体)
- `docs/design/phase2_driver_plan.md` §4 (= ADPCM-B register layout)
- `docs/design/handoff/subC3-fm-multi-ch.md` (= 直前 sprint の構造)

---

[本書は handoff 待ち。 user OK で Claude Code が codex:codex-rescue agent を Agent tool で起動]
