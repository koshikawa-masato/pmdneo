# SubD — K/R no-op stub 接続 (= K part body の si pointer 整合)

	位置付け: Phase 2 SubD (= K cmd を含む `.m` で driver hang up なし、
	         audio gate Step 4)
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

### 1-1. PMDNEO の K/R 方針

YM2610/B には OPNA 内蔵 rhythm 機構が**存在しない** ため、 PMDNEO では K
part (= 内蔵 rhythm) を **no-op stub** として処理する。 PMD V4.8s 楽曲を
PMDNEO driver に load した際に K cmd を踏んでも:
- driver は hang up しない
- si pointer (= PART_OFF_ADDR) が引数 byte 数だけ正しく進む
- chip register への書込は一切ない
- 他 part (= FM / SSG / ADPCM-B) の駆動に影響なし

### 1-2. 既存 SubA の状態

`src/driver/KR_STUB.inc` に 7 個 stub の skeleton が既にある (= SubA で
作成):
- rhykey / rhyvs / rhyvs_sft / rpnset / rmsvs / rmsvs_sft / pdrswitch

ただし current 実装は **`inc hl` で si pointer を進める** 古い PMD V4.8s
慣習。 PMDNEO の si pointer は **PART_OFF_ADDR(IX) (= IX-base)** で管理
されているため、 `inc hl` では壊れる。 `pmdneo_part_fetch_byte` で arg
byte を消費する形に修正必要。

### 1-3. SubE-1 完了 (commit 9021d2c)

ADPCM-B 単発再生 capability PoC pass、 ROM template lastbld2 化済。

### 1-4. SubD = K/R stub 接続 + audio gate

implement:
1. KR_STUB.inc の 7 stub を `pmdneo_part_fetch_byte` ベースに修正
2. `cmdtblr` (= K part 専用 dispatch table) 新設、 K cmd を K stub に dispatch
3. `commandsr` (= K part 用 dispatcher、 cmdtblr 参照)
4. `rhythm_main` (= K part 駆動 routine、 psgmain の copy + keyon/keyoff なし
   + commandsr 呼出)
5. `pmdneo_song_main` 拡張 (= rhythm_main 追加 dispatch)
6. test 試料 MML: SubC-3 の test_fm_song_data の K part (現在 empty `0x80`)
   に K cmd sequence を配置、 driver が end まで到達 + hang up なし確認

---

## 2. 実装内容

### 2-1. KR_STUB.inc 修正: pmdneo_part_fetch_byte ベース

既存 stub の `inc hl` を `call pmdneo_part_fetch_byte` に置換。 各 stub
の引数 byte 数:

| stub | arg byte 数 | 動作 |
|---|---|---|
| rhykey | 1 | rhythm trigger bitmap |
| rhyvs | 1 | rhythm volume (per ch) |
| rhyvs_sft | 2 | rhythm vol shift (per ch + 値) |
| rpnset | 1 | rhythm pattern set (pan + ch) |
| rmsvs | 1 | rhythm master vol set |
| rmsvs_sft | 1 | rhythm master vol shift |
| pdrswitch | 1 | PDR switch (PPSDRV mode、 PMDNEO で完全 no-op) |

実装例:
```asm
rhykey::
        call    pmdneo_part_fetch_byte
        ret

rhyvs_sft::
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        ret

;; 同様に他 5 個
```

### 2-2. cmdtblr 新設

`src/driver/PMD_Z80.inc` に cmdtblr (= 79 entry × 2 byte = 158 byte) を
追加。 cmdtblp と同じ layout (= 0xFF が entry 0、 cmd byte = 0xFF - index)
だが:

- **K specific 7 entry** は K stub に dispatch:
  - 0xFF-0xEB = entry 20: rhykey
  - 0xFF-0xEA = entry 21: rhyvs
  - 0xFF-0xE9 = entry 22: rpnset
  - 0xFF-0xE8 = entry 23: rmsvs
  - 0xFF-0xE6 = entry 25: rmsvs_sft
  - 0xFF-0xE5 = entry 26: rhyvs_sft
  - 0xFF-0xF1 = entry 14: pdrswitch
- **残り 72 entry** は cmdtblp の chip-agnostic handler (= comt / comd / comtie
  / comedloop / comexloop / jumpN / etc.) を流用。 cmdtblp の同じ entry を
  そのまま reference する形で OK。

#### 簡略化 案: cmdtblp copy + 7 entry 置換

cmdtblp 全 79 entry を copy して cmdtblr とし、 7 entry のみ K stub に
置換。 これで残り 72 entry は cmdtblp と同じ handler に dispatch される。

### 2-3. commandsr 新設

`commandsp` の copy で cmdtblr を参照する版:

```asm
commandsr::
        cp      #0xB1
        ret     c
        cpl
        add     a, a
        ld      l, a
        ld      h, #0
        ld      de, #cmdtblr
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        ret
```

### 2-4. rhythm_main 新設

`pmdneo_psgmain` の copy。 違い:
- chip-specific keyon/keyoff は **不要** (= K stub が chip 触らない)、
  関連経路を全て削除
- `commandsp` → `commandsr` に置換
- length tick / part_state advance は psgmain と同じ

note 経路 (= 0x00-0x7F) も chip 触らない:
- 既存 psgmain の note 経路は keyon を call する、 これを **無効化** (= note byte を
  PART_OFF_NOTE に store するだけ + length set + ret、 keyon 不要)

```asm
rhythm_main::
        push    af
        call    pmdneo_part_ix_from_part
        pop     af
        ;; ch index は不要 (= K part = part 10、 single ch)

        ld      a, PART_OFF_ADDR(ix)
        or      PART_OFF_ADDR+1(ix)
        ret     z

        ld      a, PART_OFF_LEN(ix)
        or      a
        jr      z, rhythm_main_parse
        dec     a
        ld      PART_OFF_LEN(ix), a
        jr      nz, rhythm_main_done
        ;; length 0 になったが keyoff 不要 (= K part chip touch なし)

rhythm_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jr      z, rhythm_main_end
        jr      c, rhythm_main_note
        cp      #0xB1
        jr      c, rhythm_main_clear
        call    commandsr
        jr      rhythm_main_parse

rhythm_main_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ;; keyon 不要 (= chip touch なし)
        ret

rhythm_main_end:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jr      z, rhythm_main_clear
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jr      rhythm_main_parse

rhythm_main_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a

rhythm_main_done:
        ret
```

### 2-5. pmdneo_song_main 拡張

```asm
pmdneo_song_main::
        ;; FM 6 + PSG 3 (= SubC-3 既存)
        ld      a, #PART_FM1
        call    fmmain
        ;; ... PART_FM6 まで
        ld      a, #PART_SSG1
        call    pmdneo_psgmain
        ;; ... PART_SSG3 まで

        ;; SubD: K part 駆動追加
        ld      a, #PART_RHYTHM
        call    rhythm_main

        ret
```

### 2-6. test_fm_song_data の K part 拡張

現在 `test_fm_song_part_k` は存在せず、 K part offset は `test_fm_song_empty`
を指している。 SubD audio gate のために K cmd sequence を含む K part body
を新設し、 test_fm_song_data の K offset を切替:

```asm
test_fm_song_data::
        .dw     test_fm_song_part_a - test_fm_song_data
        ;; ... B-J 既存 ...
        .dw     test_fm_song_part_k - test_fm_song_data      ; K (Rhythm)、 SubD
        ;; ... rhythm addr / prgdat_adr 既存 ...

;; SubD: K part の K cmd 一通りを順に踏む試料
test_fm_song_part_k:
        .db     0xEB, 0x01              ; rhykey arg=0x01
        .db     0xEA, 0x10              ; rhyvs arg=0x10
        .db     0xE9, 0x80              ; rpnset arg=0x80
        .db     0xE8, 0x10              ; rmsvs arg=0x10
        .db     0xE6, 0x01              ; rmsvs_sft arg=0x01
        .db     0xE5, 0x10, 0x01        ; rhyvs_sft arg=0x10, 0x01 (2 byte)
        .db     0xF1, 0x00              ; pdrswitch arg=0x00
        .db     0x80                    ; end
```

K part offset table entry を `test_fm_song_part_k` に切替えるだけ。 audio
gate での確認: K cmd 8 個踏んでも driver hang up なし、 FM song 4 ch +
ADPCM-B beat の通常再生に影響なし。

---

## 3. 前提

### 3-1. 既存実装

- `src/driver/KR_STUB.inc`: 7 個 stub skeleton (= SubA、 inc hl 流儀、 修正対象)
- `src/driver/PMD_Z80.inc`:
  - `pmdneo_psgmain` (= L868、 rhythm_main の copy 元)
  - `commandsp` / `cmdtblp` (= L965 / L987、 commandsr / cmdtblr の copy 元)
  - `pmdneo_part_fetch_byte` (= L819、 stub で使う routine)
  - `pmdneo_part_ix_from_part` (= L799、 part index → IX)
  - `pmdneo_scale_mml_length` (= L939、 length tick scale)
  - `pmdneo_song_main` (= L1075、 拡張対象)
  - `test_fm_song_data` (= L1009、 K part offset 切替対象)
- `src/driver/WORKAREA.inc`: PART_RHYTHM = 10 (= part index)、 PART_OFF_*
  既存

### 3-2. 規約

- sdasz80 syntax
- chip touch 一切なし (= ym2610_write_port_a/b call 禁止)
- pmdneo_part_fetch_byte calling convention: IX = part workarea、 戻り値
  A = byte、 PART_OFF_ADDR を 1 byte 進める
- 既存 SubA-SubE-1 routine を破壊しない (= test_play_fm_c4 / test_play_fm_scale_b
  / test_play_fm_song / test_play_adpcmb_beat / fmmain / etc.)

### 3-3. 越境禁止

- IRQ.inc は touch しない (= cmd 5 / cmd 2 dispatch は SubE-1 で確定済)
- ADPCMB_DRV.inc は touch しない
- main.c は touch しない
- ROM template (= rom.mk) は touch しない

---

## 4. 完了基準

### 4-1. build pass

`bash scripts/build-poc.sh` exit 0。

### 4-2. audio gate (= user 聴感確認)

期待動作:
- SubE-1 と同じ: ADPCM-B beat (= 起動直後 1 発) + FM song 4 ch (= SubC-3
  scale) が並列再生
- **K part が cmd sequence を踏むが driver は hang up なし、 chip 書込なし
  で進行 → 聴感には現れない (= K part 無音)**
- 他 part の音乱れ なし

合格基準:
- gngeo 起動から FM song 終了まで、 過去 SubC-3 + SubE-1 と同じ聴感
- hang up / 異音 / 楽曲乱れ なし
- (= K part が静かに無視される)

不合格 case:
- driver hang up (= rhythm_main の si pointer 計算ミス)
- 他 part の音乱れ (= rhythm_main で chip register 触ってしまった)
- audio gate timing がずれる (= K part の length tick が他 part 同期を
  乱している)

### 4-3. user 報告

- build 結果 (= exit code、 PMDNEO.rel size、 pmdneo_driver.ihx size)
- Codex は **commit せず diff のまま終了**
- Claude Code が session log + diff を review、 user に総合判断 report
- user 聴感確認後に commit + push

---

## 5. 注意点

### 5-1. cmdtblr の規模感

cmdtblp の copy が 158 byte (= 79 entry × 2 byte)。 7 entry のみ K stub
に置換、 残りは cmdtblp と同じ handler reference。 つまり cmdtblr の値
は **基本的に cmdtblp と一緒**で、 7 個の値のみ K stub アドレスに変更。

### 5-2. note 経路 (= 0x00-0x7F) の扱い

K part body 内に **note byte (= 0x00-0x7F)** がある場合、 PMD V4.8s では
rhythm trigger を発火するが、 PMDNEO の K stub では chip touch なし。
rhythm_main の note 経路は PART_OFF_NOTE store + length set のみ、 keyon
は call しない。

ただし試料 K part (= test_fm_song_part_k) には note byte を含めない (= K
cmd 7 種類のみ + end)、 SubD audio gate を簡素化。

### 5-3. K cmd 7 種類だけで十分か

PMD V4.8s spec で K cmd は他にも存在する可能性 (= clock cmd 等)。 ただし
PMDNEO scope では「`.m` 互換 + 内蔵 rhythm 機能 unsupport」 で十分、 既知
7 種類の stub で hang up しないことを確認できれば pass。 不明 cmd で hang
up が出たら都度追加。

### 5-4. audio gate 義務

driver/runtime 層 touch なので commit 前に user 聴感確認必須。 Codex は
build 通過まで、 commit + push は user 確認後に Claude Code 担当。

---

## 6. 参照

- `src/driver/KR_STUB.inc` (= 修正対象)
- `src/driver/PMD_Z80.inc` (= cmdtblr / commandsr / rhythm_main 追加)
- `docs/design/phase2_driver_plan.md` §3 (= K/R 方針詳細)
- `docs/design/handoff/subC3-fm-multi-ch.md` (= fmmain 直前 sprint、 構造
  copy 元)
- `docs/design/handoff/subE1-adpcmb-single.md` (= SubE-1 完了、 ADPCM-B
  経路)

---

[本書は handoff 待ち。 Auto Mode 継続中、 Claude Code が codex:codex-rescue
agent を Agent tool で起動]
