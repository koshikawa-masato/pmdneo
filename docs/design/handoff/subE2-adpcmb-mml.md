# SubE-2 — Part J ADPCM-B MML driving

	位置付け: Phase 2 SubE 段階分割の 2 番目 (= Part J を song 経路に統合)
	書き手: Claude Code
	実装担当: Codex (= codex:codex-rescue agent 経由)
	状態: 完了 (audio gate pass、 commit 済)

---

## 0. 役割分担

- Claude Code: 設計、 review
- Codex: 実装、 build pass まで
- user: judgment、 audio gate

---

## 1. 背景

### 1-1. SubE-1 完了 (commit 9021d2c)

ADPCM-B chip 経路の動作確認 PoC pass。 ROM template lastbld2 化、 cmd 5
直接呼出で beat sample 単発再生 OK。 delta-N = 0x6E96 (= 24 kHz native =
A5 880 Hz = o5a 基準) で sample native rate 確認済。

### 1-2. Codex independent verifier (a0d84dc) 指摘

> Part J / ADPCM-B が song 経路に統合されていない。 cmd 5 直接呼出のみ。
> ADPCMB_DRV.inc は stub。

これは phase2_driver_plan.md §2-2 の Phase 2 完成基準「ADPCM-B 1ch (J)」
と矛盾。 Phase 2 完成宣言前に Part J を pmdneo_song_main 経路に統合する
必要。

### 1-3. SubE-2 = Part J を MML 駆動

`pmdneo_song_main` から `adpcmb_main` を呼び、 Part J body の MML cmd を
解釈して ADPCM-B sample を発音する。 SubC-3 の fmmain / SubD の rhythm_main
と同じ構造で実装。

---

## 2. 実装内容

### 2-1. ADPCMB_DRV.inc 本実装

既存 stub (= 5 個 routine 全て即 ret) を実装に置換。

```asm
;;; adpcmb_keyon: ADPCM-B sample 単発再生開始
;;;   入力: なし (= SubE-2 では sample 1 個 hardcoded = beat)
;;;   動作: nullsound snd_adpcm_b_play (IX = adpcm_b_beat_struct) を call
;;;   破壊: A、 IX

adpcmb_keyon::
        ld      ix, #adpcm_b_beat_struct
        call    snd_adpcm_b_play
        ret

;;; adpcmb_keyoff: ADPCM-B 再生停止
;;;   動作: register 0x10 ← 0x01 (= reset bit、 stop)

adpcmb_keyoff::
        ld      b, #REG_ADPCM_B_START_STOP    ; = 0x10
        ld      c, #0x01                       ; reset bit
        call    ym2610_write_port_a
        ret

;;; adpcmb_volset / adpcmb_panset / adpcmb_setfreq:
;;; SubE-3 (= 後続 sprint、 sample 番号 + delta-N + volume の引数化) で実装。
;;; SubE-2 では adpcm_b_beat_struct hardcoded のため、 ここは即 ret stub のまま。

adpcmb_volset::
        ret

adpcmb_panset::
        ret

adpcmb_setfreq::
        ret
```

注意: `REG_ADPCM_B_START_STOP` symbol が nullsound `ym2610.inc` に存在しない
場合は直接 `0x10` を hardcoded で使う。 確認は `grep REG_ADPCM_B
/Users/koshikawamasato/Projects/neo-sisters/vendor/ngdevkit/nullsound/ym2610.inc`。

### 2-2. adpcmb_main 新設 (PMD_Z80.inc)

`rhythm_main` と同じ構造 (= chip touch あり、 keyon/keyoff path 完備):

```asm
;;; ----- adpcmb_main: Part J 1 step -----
;;;
;;; ADPCM-B 1 ch (= Part J = chip ADPCM-B) の MML 駆動。 note byte で
;;; adpcmb_keyon (= beat sample 再生開始)、 length 0 で adpcmb_keyoff。
;;; SubE-2 では sample 1 個 (= beat) hardcoded、 note byte は無視。

adpcmb_main::
        push    af
        call    pmdneo_part_ix_from_part
        pop     af

        ld      a, PART_OFF_ADDR(ix)
        or      PART_OFF_ADDR+1(ix)
        ret     z

        ld      a, PART_OFF_LEN(ix)
        or      a
        jr      z, adpcmb_main_parse

        dec     a
        ld      PART_OFF_LEN(ix), a
        jr      nz, adpcmb_main_done

        ;; length 0 → keyoff
        call    adpcmb_keyoff

adpcmb_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jr      z, adpcmb_main_end
        jr      c, adpcmb_main_note
        cp      #0xB1
        jr      c, adpcmb_main_clear

        call    commandsp                     ; PSG cmd handler 流用
        jr      adpcmb_main_parse

adpcmb_main_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a

        ;; SubE-2: note byte は無視、 常に beat sample 再生
        call    adpcmb_keyon
        ret

adpcmb_main_end:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jr      z, adpcmb_main_clear
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jr      adpcmb_main_parse

adpcmb_main_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a

adpcmb_main_done:
        ret
```

### 2-3. pmdneo_song_main 拡張

```asm
pmdneo_song_main::
        ;; FM 6 + PSG 3 + Rhythm 1 + ADPCM-B 1 = 11 ch dispatch
        ld      a, #PART_FM1
        call    fmmain
        ;; ... PART_FM6 まで
        ld      a, #PART_SSG1
        call    pmdneo_psgmain
        ;; ... PART_SSG3 まで
        ld      a, #PART_PCM                  ; SubE-2: ADPCM-B 1ch (Part J)
        call    adpcmb_main
        ld      a, #PART_RHYTHM
        call    rhythm_main
        ret
```

### 2-4. test_fm_song_data の Part J 拡張

現状 Part J (= test_fm_song_part_j) は `test_fm_song_empty` を指す。 SubE-2
で beat sample MML を含む試料に切替:

```asm
test_fm_song_data::
        ;; ... A-I 既存 ...
        .dw     test_fm_song_part_j - test_fm_song_data       ; J (ADPCM-B)、 SubE-2
        .dw     test_fm_song_part_k - test_fm_song_data       ; K (Rhythm) (SubD 既存)
        ;; ... 残り 既存 ...

test_fm_song_part_j:
        ;; 試料: 約 1.6 秒間隔で beat sample を 5 回 trigger (= drum loop 風)
        ;; note byte (任意、 常に beat) + length 0x40 (= ~ 1.6 秒) × 5 回
        .db     0x40, 0x40              ; (note 0x40 + length 0x40)
        .db     0x40, 0x40
        .db     0x40, 0x40
        .db     0x40, 0x40
        .db     0x40, 0x40
        .db     0x80                    ; end
```

note byte は無視されるが、 0x40 (= OCT 4 + ONKAI 0) を任意に置く。 length
0x40 = ~ 1.6 秒 (= TIMER-B tick × 8 倍 scale)。 5 回繰返で全 part 同時終了
近辺。

---

## 3. 前提

### 3-1. 既存実装

- SubE-1: `adpcm_b_beat_struct` (= 8 byte sample play config)、
  `test_play_adpcmb_beat` (= cmd 5 経由)、 `samples.inc` include 済
- SubD: rhythm_main (= adpcmb_main の copy 元、 chip touch なし version)
- SubC-3: fmmain (= per-ch dispatch、 chip touch あり version)
- nullsound `snd_adpcm_b_play` (= IX = config struct で chip register write)

### 3-2. cmd 5 直接呼出は維持 OR 削除

現状 cmd 5 (= snd_command_05_play_adpcmb_test) は test_play_adpcmb_beat
を call。 SubE-2 で Part J 経路ができたら cmd 5 は冗長 (= cmd 2 = song
内で Part J が同 sample 鳴らす)。

判断: **cmd 5 は維持** (= debug 用 + capability 確認 PoC として残す、 後で
SubE-3 で削除)。 main.c も維持。

### 3-3. sample 番号 lookup は SubE-3 で

PMD V4.8s では prgdat に sample header (= start/stop/delta-N/volume/pan)
を持ち、 MML 内 sample 番号 (= @N cmd) で switch する。 SubE-2 では sample
1 個 hardcoded (= beat)、 sample 番号機構は SubE-3 / Phase 4 で。

### 3-4. ADPCM-B busy 排他

nullsound `snd_adpcm_b_play` は `state_adpcm_exclusive` で「ongoing play
中は新 trigger 無視」 制御。 SubE-2 試料は 1.6 秒間隔で trigger するが、
beat sample が 2.7 秒なので overlap 発生 (= 後 trigger は無視される)。
これは一時的に許容、 audio gate で「2-3 個鳴ればいい、 5 回全部は不要」
と判定。

### 3-5. 規約

- sdasz80 syntax
- chip touch (= adpcmb_keyon/keyoff) は ym2610_write_port_a 経由
- 既存 SubA-SubD routine を破壊しない
- IRQ.inc / main.c / Makefile / rom.mk は touch しない

---

## 4. 完了基準

### 4-1. build pass

`bash scripts/build-poc.sh` exit 0。

### 4-2. audio gate

期待動作:
- ADPCM-B beat が **約 1.6 秒間隔で複数回 trigger** (= cmd 5 1 発 + Part J
  経由で 2-5 発)
- FM song 4 ch + K stub は SubE-1/SubD と同じ動作
- hang up / 異音 なし

合格基準:
- ADPCM-B beat が song 中に複数回鳴る (= Part J が song 経路に統合)
- 既存 SubD audio gate と同質 + ADPCM-B 反復

### 4-3. user 報告

- build 結果 (= exit code、 .rel size、 .ihx size)
- Codex は **commit せず diff のまま終了**
- Claude Code review → user 聴感確認 → commit + push

---

## 5. 注意点

### 5-1. cmd 5 と Part J 同時 trigger

main.c で cmd 5 → cmd 2 順なので、 起動時 cmd 5 で beat 1 発、 cmd 2 song
が start → driver_song_ready set → pmd_z80_main → pmdneo_song_main →
adpcmb_main で Part J が beat 5 回 trigger を試みる。 cmd 5 の最初 1 発が
未終了なら nullsound exclusive で skip、 終了後の trigger が鳴る。

### 5-2. note byte = 0x80 の扱い

Part J body 内で note byte 0x80 は end marker。 0x40 等の通常 note byte
が常に beat trigger として扱われる。

### 5-3. audio gate 義務

driver/runtime 層 touch なので commit 前に user 聴感確認必須。

---

## 6. 参照

- `src/driver/ADPCMB_DRV.inc` (= 修正対象)
- `src/driver/PMD_Z80.inc` (= adpcmb_main 追加、 pmdneo_song_main 拡張、
  test_fm_song_part_j 新設)
- `docs/design/phase2_driver_plan.md` §4 (= ADPCM-B register layout)
- `docs/design/handoff/subE1-adpcmb-single.md` (= adpcm_b_beat_struct、
  delta-N)
- `docs/design/handoff/subD-kr-stub.md` (= rhythm_main = adpcmb_main の
  copy 元)

---

[本書は handoff 待ち。 Auto Mode 継続中、 Claude Code が codex:codex-rescue
agent を Agent tool で起動]
