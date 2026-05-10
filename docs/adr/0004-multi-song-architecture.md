# ADR-0004: 複数楽曲 lookup table + cmd 9-15 直接 song select 規約

- 状態: Accepted
- 起票日: 2026-05-10
- 起票者: 越川将人 (M.Koshikawa)
- 関連: Phase 12b-1 (= 10446e2)、 Phase 12b-2 (= 59040f8)、 ADR-0003 (= cmd byte code 規約)

## 背景

Phase 12a-4 までは 1 ROM 内 1 楽曲固定 (= `song_data.inc` が `song_part_b..q` 14 label を直接 `.incbin` 配置)、 driver 側 14 個の `ld hl, #song_part_X` でアセンブル時固定参照。

ROM 内に複数楽曲 (= title BGM + stage BGM 等) を embed して driver 側で動的切替する architecture が必要 (= 楽曲制作 phase 12c 以降の前提条件)。

選択肢検討:
- **案 A**: modal flag 経路 (= cmd N + arg byte 形式) — Phase 8b commit `244fd1e` で **drum 1 step stop bug** により abandon 済 (= NEOGEO 1-byte REG_SOUND port + NMI 同期問題が真因)、 復活 risk 高
- **案 B**: cmd 9-15 直接 dispatch (= 7 song まで対応) — 既存 cmd 2/5/6/7 と同パターン (= cp #N / jp z dispatch)、 安全
- **案 C**: cmd byte 上下 4-bit 分離 (= 上位 cmd id + 下位 song_id) — 16 song まで対応、 ただし既存 cp #N pattern と異なる解釈経路で複雑化

**案 B 採用** (= 安全 + シンプル + 当面 7 song で十分)。 16+ song 拡張は将来別 protocol で対応 (= 12b-3+ phase)。

## 規約

### 規約 1: ROM 内 song_table format

`compile.py` が wrapper `.inc` に下記 format で embed:

```asm
;;; PMDNEO compile.py generated wrapper
song0_part_b: .incbin "songs/{basename0}/song_part_b.mn"
song0_part_c: .incbin "songs/{basename0}/song_part_c.mn"
... (14 part: b/c/e/f/g/h/i/j/l/m/n/o/p/q)
song1_part_b: .incbin "songs/{basename1}/song_part_b.mn"
...

song_table:
        .dw song0_part_b, song0_part_c, song0_part_e, song0_part_f
        .dw song0_part_g, song0_part_h, song0_part_i, song0_part_j
        .dw song0_part_l, song0_part_m, song0_part_n, song0_part_o
        .dw song0_part_p, song0_part_q
        .dw song1_part_b, song1_part_c, ... (14 word × N song)
```

- 各 song: 14 word (= 28 byte stride)
- part 順序: b, c, e, f, g, h, i, j, l, m, n, o, p, q (= driver 側 part_idx 0..13 と一致)
- song 順序: `compile.py input1.mml input2.mml ...` の入力順 (= song_id 0..N-1)

### 規約 2: SRAM `driver_song_id` 配置

`driver_song_id` (= SRAM 0xF81F、 1 byte) が active song を保持。 cold clear で 0 default (= `nmi_clear_driver_state` の 0x0F byte clear 範囲内)。

### 規約 3: lookup helper `load_song_part_addr`

```asm
;;; A=part table index (0..13)
;;; Return HL=song data address selected by driver_song_id. AF preserved.
load_song_part_addr:
    push    af
    ld      c, a                ; C = part_idx
    ld      hl, #driver_song_id
    ld      a, (hl)
    ld      h, #0
    ld      l, a                ; HL = song_id
    ; HL = song_id × 28 (= × 32 - × 4)
    add     hl, hl              ; × 2
    add     hl, hl              ; × 4
    ld      d, h
    ld      e, l                ; DE = × 4
    add     hl, hl              ; × 8
    add     hl, hl              ; × 16
    add     hl, hl              ; × 32
    ld      b, h
    ld      a, l
    sub     e
    ld      l, a
    ld      a, b
    sbc     a, d
    ld      h, a                ; HL = song_id × 28
    ; HL = HL + part_idx × 2 (= 8-bit + 16-bit 加算)
    ld      a, c
    add     a, a                ; A = part_idx × 2
    add     a, l
    ld      l, a
    adc     a, h
    sub     l
    ld      h, a
    ld      de, #song_table
    add     hl, de
    ld      a, (hl)
    inc     hl
    ld      h, (hl)
    ld      l, a                ; HL = song_part_X address (= word load)
    pop     af
    ret
```

`nmi_cmd_5_init_mml_song` 内 14 part init は helper 経由で song_table 引く。

### 規約 4: cmd 9-15 直接 song select

driver `nmi_dispatch` で cmd 9-15 を `song_id 0..6` に対応させる:

```asm
nmi_dispatch:
    in      a, (0x00)
    cp      #2 / jp z, ...
    ...
    cp      #9
    jp      c, nmi_done         ; A < 9 = unknown
    cp      #16
    jp      nc, nmi_done        ; A >= 16 = unknown
    jp      nmi_cmd_select_song ; 9..15 → song_id 0..6

nmi_cmd_select_song:
    sub     #9
    ld      (driver_song_id), a
    jp      nmi_done
```

**使用順序** (= main.c から):
1. `*REG_SOUND = 9 + song_id` (= driver_song_id update)
2. `ng_wait_vblank()`
3. `*REG_SOUND = 5` (= MML song start、 nmi_cmd_5 が新 song_id 経由で song_table 引く)

### 規約 5: 拡張余地 (= Phase 12b-3+)

16+ song 必要時は本 ADR を supersede or 拡張 (= 例 cmd 8 を modal trigger 専用として復活 + 即直後 byte で song_id 任意指定、 ただし modal 経路再設計が前提)。 当面 7 song で十分のため 12b-3+ は **必要時に判断**。

## modal flag 経路非採用の経緯 (= Phase 8b retrospective)

Phase 8b 当初 `案 B` (= cmd 7 + arg byte + cmd 6 形式) で fade speed 任意指定を試行、 **drum 1 step stop bug** 発生:

- `nmi_dispatch` 冒頭で modal flag check (= driver_pending_arg_target 非0なら次 byte を arg として解釈) 実装
- audio gate で drum 1 step だけ鳴って停止する症状
- 切り分けで modal check が真因と特定 (= NEOGEO 1-byte REG_SOUND port + NMI 同期問題、 68k 側の write timing と Z80 側 NMI 受信 timing の競合で arg byte が cmd byte として再解釈される race condition)

詳細: commit `244fd1e` body + WIP branch `wip-phase8b-stuck-bug @ 7dd886d` (= local only、 ground truth 保存)。

**結論**: modal 経路は本 architecture では不採用。 すべての cmd は **1 byte 完結 dispatch** で設計。

## dead code 状態の記録

`nmi_cmd_7_set_fade_speed` (= line 318-320) は実装は残存するが、 modal 経路 disable のため effect なし (= `driver_pending_arg_target` への書込のみ、 後段で参照されない)。 cleanup は別 sprint で実施。

## 影響範囲

### 修正済 file (= Phase 12b sprint)
- `src/driver/standalone_test.s`: SRAM driver_song_id 追加、 load_song_part_addr 新規、 nmi_cmd_5 内 14 個 hardcoded → helper call、 nmi_dispatch に cmd 9-15 範囲 check + nmi_cmd_select_song 追加
- `src/tools/pmd-mml/compile.py`: nargs='+' 多 song 対応、 wrapper format 拡張 (= songN_part_X label + song_table emit)
- `scripts/build-poc.sh`: MML_INPUTS (= comma separated) 拡張、 後方互換維持
- `vendor/ngdevkit-examples/00-template/main.c`: PMDNEO_SONG selector + cmd 9+SONG 発行
- `vendor/ngdevkit-examples/00-template/Makefile`: PMDNEO_SONG ?= 0 + CFLAGS embed

### 関連 ADR / 設計書
- ADR-0002 (= dispatch unification refactor、 12b の前提)
- ADR-0003 (= cmd byte code 規約、 cmd 9-15 範囲は本 ADR で予約済)
- `docs/design/pmdneo_self_contained_driver.md` (= driver architecture 全体、 12b 反映の章追記候補は別 task)

### 関連 memory
- `feedback_runtime_audio_verify_required` (= 12b commit はそれぞれ audio gate pass 経由)
- `project_pmdneo_soft_reset_residual` (= driver_song_id も F3 soft reset で残留する想定、 hardening は別 phase)

## 採決

**Accepted** (= 2026-05-10、 Phase 12b-1 + 12b-2 完了 + audio gate user 聴感 OK 双方確認後)。
