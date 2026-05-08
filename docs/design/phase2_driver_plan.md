# Phase 2 driver 実装計画書

	位置付け: PMDNEO Phase 2 driver 着手前 設計書 3 種の 3 番目 (= 実装計画)
	参照: [`mn_binary_layout.md`](mn_binary_layout.md) (`.mn` binary layout 仕様、 完成済)
	参照: [`ppz_to_adpcma_mapping.md`](ppz_to_adpcma_mapping.md) (PPZ → ADPCM-A 翻訳 mapping、 完成済)
	参照: [`PMDNEO_DESIGN.md`](PMDNEO_DESIGN.md) §2-3 (Phase 2 既存方針)
	状態: draft 進行中 (推奨案ベース、 user judgment 9-13 で確定)

---

## 0. 位置付け

### 0-1. Phase 2 のゴール再掲

PMDNEO driver の **ベースライン部分**(OPNA 互換相当 = FM 6ch / SSG 3ch
/ ADPCM-B 1ch) を Z80 フルスクラッチで完成させ、 既存 PMDDotNET 出力の
OPNA 用 `.m` (FM/SSG) および `.m2` (FM/SSG + ADPCM-B 1ch) を **100%
再現する Z80 driver** として動作させる。

Phase 3 で ADPCM-A 6ch 拡張 (PPZ → ADPCM-A 置換) を統合する出発点として
完成させる。

### 0-2. 設計書 1 / 2 で確定した前提

設計書 1 ([`mn_binary_layout.md`](mn_binary_layout.md)) で確定:

- `.mn` binary layout: 前 26 byte header (OPNA 互換) + 後方拡張領域
- m_start bit 2 = PMDNEO mode flag
- ADPCM-A 6 part offset table は prgdat 後ろに配置
- `.PNE` filename ptr は `.mn` 末尾に embed
- part letter A-K + L-Q (新規 ADPCM-A 6ch)

設計書 2 ([`ppz_to_adpcma_mapping.md`](ppz_to_adpcma_mapping.md)) で確定:

- 関数呼出規約: A = opcode、 DE = arg1、 BC = arg2、 HL = ptr 戻り値
- 8ch → 6ch 縮約: part10a-f を残し part10g/h 完全削除
- dispatch 拡張: 新規 cmdtbla 新設 (jump1 上書きせず)
- Loop / SrcFreq: 完全 no-op + `.PNE` 生成側で展開
- workarea: OPNA layout 後方拡張領域に直接配置 (part 番号順)

本書 (設計書 3) では、 これらを前提に **Phase 2 で何を src/driver/ 配下
に書くか**を確定する。

### 0-3. Phase 2 で扱う範囲 / 扱わない範囲

#### 扱う範囲 (Phase 2 で完成)

- driver source 全体構造の確立 (PMDNEO.ASM + PMD_Z80.ASM + 拡張 module)
- FM 6ch dispatch (cmdtbl 全 entry)
- SSG 3ch dispatch (cmdtblp 全 entry)
- **ADPCM-B 1ch dispatch** (`.m2` の OPNA ADPCM RAM 経路を YM2610/B 内蔵
  ADPCM-B 機構に対応付け)
- TIMER-B IRQ 駆動の NEOGEO 環境置換
- K/R 内蔵 rhythm の no-op stub
- mc compiler 改造なし、 既存 OPNA `.m` / `.m2` をそのまま投入

#### 扱わない範囲 (Phase 3 / 4 で扱う)

- ADPCM-A 6ch dispatch (= 設計書 2 に従って Phase 3 で実装)
- mc compiler の `.mn` 出力経路追加 (= Phase 3)
- WebApp / IPL / プレイヤー V1 (= Phase 4)
- ADPCMA_DRV.ASM の actual 実装 (= Phase 3、 Phase 2 では空 stub のみ)

---

## 1. driver source 構造

### 1-1. file 配置案

```
src/driver/
    PMDNEO.ASM        ; build top (flag 設定 + include)
    PMD_Z80.ASM       ; PMD.ASM の Z80 化 base (= 9000-10000 行を翻訳)
    ADPCMB_DRV.ASM    ; ADPCM-B 1ch driver (Phase 2 で完成)
    ADPCMA_DRV.ASM    ; ADPCM-A 6ch driver (Phase 3 で完成、 Phase 2 では空 stub)
    KR_STUB.INC       ; K/R 内蔵 rhythm no-op stub (7 個 handler)
    IRQ.INC           ; TIMER-B IRQ handler
    REGMAP.INC        ; YM2610/B register 定数定義
    WORKAREA.INC      ; per-part workarea offset 定数
```

8 個の file 構成。 PMD V4.8s の build 構造 (PMDPPZ.ASM が PMD.ASM を
include する形) を Z80 化で踏襲。

### 1-2. include 依存関係図

```
PMDNEO.ASM (top)
   │
   │ flag 設定 (neogeo=1, adpcmb=1, adpcma=0/1)
   │
   ├── include WORKAREA.INC (per-part workarea offset 定数)
   ├── include REGMAP.INC   (YM2610/B register 定数)
   ├── include IRQ.INC       (TIMER-B IRQ handler)
   ├── include KR_STUB.INC   (K/R no-op stub)
   ├── include PMD_Z80.ASM   (= base driver、 dispatch + per-part main loop)
   │      │
   │      └── 内部で if adpcmb / if adpcma で分岐
   │
   ├── (if adpcmb) include ADPCMB_DRV.ASM
   └── (if adpcma) include ADPCMA_DRV.ASM (Phase 3 で完成)
```

PMDNEO.ASM が flag を立てて PMD_Z80.ASM を include、 さらに必要な module
を取り込む流れ。 PMD V4.8s の `PMDPPZ.ASM (16 行) → include PMD.ASM` と
同じ構造。

### 1-3. 各 file の想定行数

| file | 想定行数 | 役割 |
|---|---|---|
| PMDNEO.ASM | 30〜50 | flag 設定 + include 列 (build top) |
| PMD_Z80.ASM | 6000〜8000 | PMD.ASM 10864 行のうち Z80 化対象部分 |
| ADPCMB_DRV.ASM | 300〜500 | ADPCM-B 1ch driver (Phase 2 完成) |
| ADPCMA_DRV.ASM | 500〜800 | ADPCM-A 6ch driver (Phase 3 で書く、 Phase 2 では空) |
| KR_STUB.INC | 50〜80 | 7 個 no-op handler |
| IRQ.INC | 100〜200 | TIMER-B IRQ handler + sound command 受付 |
| REGMAP.INC | 100〜150 | register 定数 (YM2610/B 全 register name) |
| WORKAREA.INC | 80〜120 | per-part workarea offset 定数 |
| **合計 (Phase 2 完成時)** | **約 6700〜9100** | (ADPCMA_DRV.ASM は Phase 3 で 500-800 追加) |

PMD.ASM 10864 行から:
- 削除 (PC-98 specific / DOS 環境 specific): 約 2000 行
- 翻訳不要 (commented out / dead code): 約 1000 行
- Z80 化対象: 約 7000 行 (PMD_Z80.ASM 想定行数の中央)

### 1-4. file 起こし順序

Phase 2 着手 day-1 から段階的に:

1. **REGMAP.INC** (= YM2610/B register 定数のみ、 chip 駆動の最小単位)
2. **WORKAREA.INC** (= per-part workarea 構造、 dispatch routine の前提)
3. **IRQ.INC** (= TIMER-B IRQ + sound command 受付、 起動経路)
4. **KR_STUB.INC** (= 7 個 no-op handler、 dispatch loop が壊れない最小実装)
5. **PMDNEO.ASM** (= build top、 上記 4 個 + dummy PMD_Z80 を include して silent ROM がビルド通る)
6. **PMD_Z80.ASM** (= 段階的に PMD.ASM の routine を翻訳、 SSG → FM → ADPCM-B の順で dispatch を追加)
7. **ADPCMB_DRV.ASM** (= PMD_Z80 で ADPCM-B 関連 dispatch を作りながら module 化)

Sub-phase 単位は §8 で詳細化。

---

## 2. build 構造

### 2-1. PMDNEO.ASM の flag 設定

```asm
;;;
;;; PMDNEO build top
;;;

        ;; build flag
        neogeo  = 1     ; YM2610/B chip 対応 (常に 1)
        adpcmb  = 1     ; ADPCM-B 1ch 対応 (Phase 2 から有効)
        adpcma  = 0     ; ADPCM-A 6ch 対応 (Phase 2 では 0、 Phase 3 で 1)

        ;; chip type (Phase 2 では YM2610B 想定、 YM2610 無印で audio gate)
        ;; ADR-0001 (C 方針): driver は 6 ch 実装、 楽曲 Part A/D は不使用
        ym2610b = 1     ; FM 6ch dispatch 有効 (= chip ch 1-6 全部 register write)

        .include "WORKAREA.INC"
        .include "REGMAP.INC"
        .include "IRQ.INC"
        .include "KR_STUB.INC"
        .include "PMD_Z80.ASM"

        .if adpcmb
        .include "ADPCMB_DRV.ASM"
        .endif

        .if adpcma
        .include "ADPCMA_DRV.ASM"
        .endif
```

PMD V4.8s の `PMDPPZ.ASM` 流儀 (= 16 行で flag + include) を sdasz80
syntax に翻訳。

### 2-2. Phase 2 build profile

Phase 2 では `adpcma = 0` で組み、 ADPCMA_DRV.ASM は include されない
(= 空 stub の `ADPCMA_DRV.ASM` を file 配置はしておく、 Phase 3 で内容を
書き始める)。

Phase 2 完成時の機能:
- FM 6ch dispatch (A-F、 driver 全部実装、 ADR-0001 の (C) 方針で楽曲は
  Part A/D 不使用 = chip ch 1/4 が YM2610 無印で output 配線なしのため)
- SSG 3ch (G-I)
- ADPCM-B 1ch (J)
- K/R no-op stub (R = K)

ADPCM-A 6ch (L-Q) は **silent**(= driver は MML body を解釈しない、
そもそも `.m`/`.m2` には L-Q part が存在しない)。

#### Part A/D 不使用の自己規律 (ADR-0001 (C) 方針)

driver は 6 ch FM dispatch を YM2610B 仕様で実装するが、 楽曲 (`.m` / `.mn`)
は Part B/C/E/F の 4 ch FM のみ運用する。 これは:

- YM2610 無印 chip (= NEOGEO 標準) で chip ch 1/4 の output 配線がないため、
  Part A/D を楽曲で使うと無音になる
- PMD driver の不変条件 (= 無効 ch register write は破綻せず無音) が物理仕様と
  整合し、 楽曲が誤って Part A/D を使っても破綻しない
- audio gate は YM2610 無印基準で行い、 Part B/C/E/F のみで FM 音色を確認する

詳細は [`docs/adr/0001-fm-ch1-ch4-no-use-policy.md`](../adr/0001-fm-ch1-ch4-no-use-policy.md)。

### 2-3. assembler 選定 — sdasz80 (推奨、 user judgment 9)

ngdevkit Z80 環境では **`sdasz80`** (= sdcc 同梱の Z80 assembler) が
慣習。 ngdevkit-examples/06-sound-adpcma/user_commands.s 等で実証済の
syntax:

- `.area CODE` / `.area DATA` で segment 定義
- `.include "file.inc"` で include
- `.equ name, value` で 定数定義
- `::` で global label、 `:` で local label
- `ld`, `jp`, `call`, `ret` 等の Z80 命令
- `#imm` で immediate value (例: `ld a, #0x80`)
- `(memref)` で memory reference
- `.if` / `.endif` で conditional assembly

#### 候補比較

| assembler | ngdevkit 互換 | syntax | 採用判断 |
|---|---|---|---|
| **sdasz80** (推奨) | ◎ (公式) | SDCC 系 | Phase 2 採用 |
| sjasm / sjasmplus | × | Pasmo 系 | 互換 layer 必要、 採用しない |
| pasmo | × | Pasmo 系 | 同上、 採用しない |
| z88dk-z80asm | × | z88dk 系 | 同上、 採用しない |

PMD V4.8s の MASM (Microsoft Macro Assembler) syntax から sdasz80 syntax
への変換が Phase 2 driver 翻訳の中核作業の 1 つになる。

### 2-4. ngdevkit との結合点 — nullsound 系統 sound command framework (user judgment 13)

ngdevkit の慣習では Z80 driver は **nullsound** という公式 sound driver
framework に統合される。 nullsound は M68K (= main CPU) からの sound
command を Z80 が受けて再生する仕組み:

```
M68K (game logic)
   │
   │ REG_SOUND port write (8-bit command)
   │
   ▼
Z80 IRQ handler (nullsound)
   │
   │ command jump table 経由
   │
   ▼
sound effect routine (= 1 command = 1 sound 再生)
```

PMDNEO の場合、 PMD V4.8s の構造は「driver = TIMER-B IRQ で seq drive」
で、 sound command framework とは設計思想が違う。 統合方針:

#### 案 A (推奨): nullsound 系統の sound command framework 流用 + driver core 独自実装

- M68K → Z80 sound command の受付経路は nullsound の慣習通り
- command 体系:
  - `0x00`: no-op
  - `0x01`: prepare for ROM switch (= ngdevkit 必須 reserved command)
  - `0x02`: 楽曲再生開始 (= MML data ptr を Z80 RAM に渡す)
  - `0x03`: 楽曲再生停止 (= TIMER-B 停止 + chip silence)
  - `0x04`: fade out
  - `0x05`-`0x0F`: 予約 (V2 で楽曲選択切替等)
- driver core (= MML 解釈 + chip 駆動 + TIMER-B IRQ) は PMDNEO 独自実装、
  PMD V4.8s から翻訳

#### 案 B: PMDNEO driver を独立 Z80 binary として組む

- nullsound の框組みを使わず、 完全独立の Z80 binary を作る
- ngdevkit の M68K-Z80 通信経路だけ最小限使う

利点なし、 ngdevkit 慣習から外れて nullsound の resource (= ROM bank
切替等の reserved command) を再発明することになる。 採用しない。

#### 案 C: nullsound に PMDNEO 機能を組み込む

- nullsound 内に PMD MML 解釈 routine を追加
- 利点: ngdevkit 公式に近い
- 欠点: nullsound は別作品 (Damien Ciabrini氏作、 GPL-3.0) で、 PMDNEO
  独自実装と library 構造が異なる、 統合は複雑

案 A が最もバランス取れた選択。

---

## 3. K/R 内蔵 rhythm no-op stub の具体実装

### 3-1. K/R workarea サイズ確保方針 (user judgment 11)

PMD V4.8s では K/R part の workarea は OPNA 内蔵 rhythm 駆動用に full
size で確保 (= 他 part と同じ N byte)。 PMDNEO では workarea を **OPNA
完全互換でフルサイズ確保**するか、 アドレス計算のみ整合させて実体サイズ
を縮めるか。

#### 案 A (推奨): OPNA 完全互換でフルサイズ確保

- N byte (= 他 part と同じ size) を K/R part workarea として確保
- driver の per-part dispatch loop で `partb` (= part 番号) を見て一様に
  処理可能、 special case なし
- 利点: dispatch routine が clean、 PMD ファミリ「未対応 cmd スルー」
  思想を完全に守る (= K/R cmd を踏んでも si pointer ずれず、 workarea
  read/write も問題なし)
- 欠点: NEOGEO Z80 RAM (約 2 KB) のうち K/R 用に N byte 取られる、 他
  workarea を圧迫する可能性

#### 案 B: K/R workarea 縮小 (アドレス計算のみ整合)

- K/R part の workarea base アドレスは `.m`/`.m2` の MML 解釈時に正しく
  計算される必要があるが、 実体は最小限 (= 数 byte) に縮める
- chip 駆動 routine が呼ばれない前提で、 read/write される workarea の
  field のみ確保
- 利点: NEOGEO Z80 RAM の節約
- 欠点: dispatch routine が K/R 用に special case 分岐、 maintenance
  cost 増、 「未対応 cmd スルー」 思想の literal 実装から外れる

PMDNEO の設計思想 (= 「driver は知らない opcode を踏んでも si pointer
を正しく進めて引数 byte を消費」) を **literal に守る**には案 A が
clean。 NEOGEO Z80 RAM 圧迫は per-part workarea sizing で別途調整する
余地がある (= 設計書 3 §1-3 で workarea 計 800-1200 byte 想定、 K/R 1
part 分 N=64 byte 程度なら他 part 圧迫なし)。

### 3-2. 7 個 handler の Z80 source skeleton

`KR_STUB.INC` の中身案:

```asm
;;;
;;; KR_STUB.INC
;;; K/R 内蔵 rhythm no-op stub (PMD ファミリ「未対応 cmd スルー」 思想)
;;;
;;; 各 handler は引数 byte を si pointer から消費するだけで chip 書込
;;; なし。 driver dispatch routine から呼ばれた後 ret で帰る。
;;;
;;; 引数 byte 数は analysis_m_data_structure.md §4-7-8 で確定済。
;;;

        .area CODE

;;; rhykey (引数 1 byte): rhythm trigger bitmap
rhykey::
        inc     hl              ; si pointer (HL とする) を 1 byte 進める
        ret

;;; rhyvs (引数 1 byte): rhythm volume (per ch)
rhyvs::
        inc     hl
        ret

;;; rhyvs_sft (引数 2 byte): rhythm vol shift
rhyvs_sft::
        inc     hl
        inc     hl
        ret

;;; rpnset (引数 1 byte): rhythm pattern set (pan + ch)
rpnset::
        inc     hl
        ret

;;; rmsvs (引数 1 byte): \V rhythm master vol set
rmsvs::
        inc     hl
        ret

;;; rmsvs_sft (引数 1 byte): rhythm master vol shift
rmsvs_sft::
        inc     hl
        ret

;;; pdrswitch (引数 1 byte): PDR switch (PPSDRV mode)
pdrswitch::
        inc     hl
        ret
```

各 handler は **引数 byte を消費 + ret** のみ。 chip 書込なし、
workarea 書込なし。

`HL` を si pointer として使うのは driver 全体の register 規約に準拠 (=
PMD V4.8s の `si` register は Z80 では `HL` が自然な対応、 `(HL)` で
direct memory access、 `inc hl` で +1)。 詳細な register 規約は §1
冒頭 + WORKAREA.INC で。

### 3-3. dispatch table への登録

cmdtbl (FM 用)、 cmdtblp (PSG 用)、 cmdtblr (Rhythm 用) のうち、 K/R
part の dispatch は **cmdtblr** を使う (analysis_m_data_structure.md
§4-4 参照)。 cmdtblr の 7 個 entry を上記 stub に向ける:

| opcode | cmdtblr handler | stub 関数 |
|---|---|---|
| 0xEB | rhykey | `rhykey` |
| 0xEA | rhyvs | `rhyvs` |
| 0xE9 | rpnset | `rpnset` |
| 0xE8 | rmsvs | `rmsvs` |
| 0xE6 | rmsvs_sft | `rmsvs_sft` |
| 0xE5 | rhyvs_sft | `rhyvs_sft` |
| 0xF1 | pdrswitch | `pdrswitch` |

(これらは cmdtblr の実装時に jump table として並べる)

---

## 4. ADPCM-B 1ch dispatch の YM2610/B register mapping

### 4-1. OPNA ADPCM RAM ↔ YM2610/B ADPCM-B の対応

PMD V4.8s の `.m2` (= PMDB2.COM 用) は OPNA + ADPCM RAM 構成を前提と
している。 ADPCM RAM は OPNA に外付けの DRAM で、 driver が DRAM への
sample data 転送 + 再生制御を行う。

YM2610/B の ADPCM-B は **chip 内蔵**で、 sample data は NEOGEO V-ROM
から直接読み出す (ADPCM-A と同じ仕組み)。 driver は register 操作のみ
で chip が ROM から sample data を取得して再生する。

つまり PMDNEO では「ADPCM RAM への sample 転送」 routine は不要、 「chip
register への sample 開始位置 + 終了位置 + 駆動制御の書込」 のみ実装
すれば良い。

### 4-2. YM2610/B ADPCM-B register layout

ADPCM-B は **port A** (= 第 1 register set、 address `0x000`-`0x0FF` 帯)
で操作する:

| address | bit 配置 | 役割 |
|---|---|---|
| **0x10** | bit 7 = Start、 bit 6 = Repeat、 bit 4 = Reset | Start/Repeat/Reset 制御 |
| **0x11** | bit 7-6 = LR pan | Left/Right ch on/off |
| **0x12** | bit 7-0 (LSB) | Start address LSB (256 byte unit) |
| **0x13** | bit 7-0 (MSB) | Start address MSB |
| **0x14** | bit 7-0 (LSB) | End address LSB |
| **0x15** | bit 7-0 (MSB) | End address MSB |
| **0x19** | bit 7-0 (LSB) | Delta-N LSB (= 再生周波数係数) |
| **0x1A** | bit 7-0 (MSB) | Delta-N MSB |
| **0x1B** | bit 7-0 (0-255) | Volume (Total Level) |

(ADPCM-A と異なり、 ADPCM-B は **delta-N で任意周波数**を出せる、
loop も可能)

### 4-3. ADPCM-B sample data の格納場所 (user judgment 10、 確定済)

#### 確定方針: `.PPC` format 流用 (PMD V4.8s 既存資産踏襲)

ADPCM-B sample data の取扱い:

- **sample pack format**: PMD V4.8s 既存の **`.PPC`** (PMDB2 用 ADPCM
  RAM sample pack) を流用。 PMDNEO 専用拡張子は新規定義しない。
- **`.P86` の取込**: PMD86 用 8 bit PCM format `.P86` は YM2610/B
  ADPCM-B には直接使えない (= bit 数 + format 違い)。 PMDNEO で取り込む
  場合は WebApp / 変換ツール側で **`.PPC` 形式に変換**してから使用。
- **ROM 配置**: `.PNE` (ADPCM-A 用、 設計書 1 §4-3-3) と `.PPC`
  (ADPCM-B 用) を **同じ NEOGEO V-ROM bank に並べて焼き込み**。 V-ROM
  は ADPCM-A / ADPCM-B 共通 (= chip 内部で振り分け、 物理的には 1 つの
  ROM チップ)。
- **driver 動作**: chip register 経由で ADPCM-A 用 6ch (port B
  0x10-0x2D) と ADPCM-B 用 1ch (port A 0x10-0x1B) に sample を振り分け。
  V-ROM 上の sample data 開始/終了 address は driver が `.PPC` の sample
  header (start/end addr) から読み取って chip register に書き込む。

#### 採用理由

- PMD V4.8s 既存資産との互換性を最大化 (= `.PPC` で配布されている既存
  sample pack をそのまま使える)
- 単一 sample format `.PPC` で ADPCM-B 全用途を扱えて、 PMDNEO 拡張子
  乱立を避けられる
- ROM 配置経路を ADPCM-A / ADPCM-B で共通化 (= V-ROM 1 bank で完結)、
  WebApp の build 流れも単純化
- `.P86` 入力は変換経路を 1 段挟むだけで取り込める (= 楽曲資産の取込
  範囲を広げる)

#### WebApp の責務 (Phase 4 で実装)

- 入力 WAV → 18.5 kHz 4bit ADPCM-A 化 → `.PNE` 生成
- 入力 WAV → 任意 sample rate 4bit ADPCM-B 化 → `.PPC` 生成 (PMDB2 互換 format)
- 入力 `.P86` → `.PPC` 変換経路を提供 (8bit PCM → 4bit ADPCM-B 変換)
- ROM build 時に `.PNE` + `.PPC` を同じ V-ROM bank に並べて焼き込み

詳細な ROM build 経路 + sample 番号 ↔ V-ROM byte offset の lookup table
生成は Phase 4 (= WebApp 完成) で確定する。 Phase 2 driver 段階では:

- driver が `.m2` の prgdat 領域から sample 番号を取得
- WebApp が事前に焼き込んだ V-ROM 上の sample header を sample 番号で
  index 引き
- start/end addr を chip register (port A 0x12-0x15) に書き込んで再生

の経路を実装する。

### 4-4. ADPCM-B 駆動 routine 概要

```asm
;;;
;;; ADPCMB_DRV.ASM (Phase 2 完成)
;;;
;;; PMD V4.8s の ADPCM RAM 駆動 routine を YM2610/B 内蔵 ADPCM-B に翻訳
;;;

        .area CODE

;;; adpcmb_keyon: sample 番号 + 周波数 + volume を指定して再生開始
;;;   入力: A = sample 番号、 BC = delta-N、 D = pan/volume
adpcmb_keyon::
        ;; sample header lookup (.m2 prgdat 内 / または ROM bank table)
        ;; start_addr / end_addr を取得して register 0x12-0x15 に書込
        ;; delta-N を register 0x19/0x1A に書込
        ;; volume を register 0x1B に書込
        ;; pan を register 0x11 に書込
        ;; register 0x10 に start bit (= 0x80) を書込
        ;; ...
        ret

;;; adpcmb_keyoff
adpcmb_keyoff::
        ;; register 0x10 = 0x01 (= reset、 = stop)
        ld      de, #0x1001
        call    ym_write_a
        ret

;;; adpcmb_volset, adpcmb_panset, adpcmb_setfreq, etc.
```

詳細実装は Phase 2 sub-phase で段階的に作成 (= §8 SubE)。

---

## 5. TIMER-B IRQ 駆動の NEOGEO 環境置換

### 5-1. PMD V4.8s の IRQ 駆動構造

PC-98 環境では PMD driver は YM2608/YM2610 の TIMER-B 周期割込で seq
drive を行う。 driver 内部での処理:

```
TIMER-B IRQ 発生 (約 60 Hz、 BPM 連動)
  │
  ├── tempo / fade / mask 系の global flag 更新
  │
  ├── per-part main loop:
  │     for ch in 0..16:
  │         driver が partb に ch を set
  │         該当 part の dispatch を call (fmmain / psgmain / ppzmain / etc.)
  │         dispatch 内で MML opcode を 1 つ消費 + chip 書込
  │
  └── IRQ 終了 (= 次の TIMER-B trigger を待つ)
```

NEOGEO Z80 環境では TIMER-B IRQ を Z80 IRQ vector (= RST 0x38h) に hook
する。

### 5-2. NEOGEO Z80 IRQ 慣習

ngdevkit + nullsound の慣習では Z80 IRQ は:

- YM2610 TIMER-A / TIMER-B が Z80 IRQ を発火
- Z80 IRQ vector = 単一 entry (RST 0x38h、 = `0x38` 番地)
- IRQ handler 内で TIMER status を polling して TIMER-A / TIMER-B を判別

PMDNEO の場合、 TIMER-B のみ使う (= TIMER-A は予約 / 不使用):

```asm
;;;
;;; IRQ.INC
;;;

        .area CODE

;;; Z80 IRQ vector (RST 0x38h で単一 entry)
        .org 0x38
irq_entry::
        push    af
        push    bc
        push    de
        push    hl
        push    ix
        ;; YM2610 TIMER status read
        ld      a, #YM2610_STATUS_PORT
        in      a, (#0x04)      ; port A status read
        bit     1, a            ; TIMER-B flag check
        jr      z, irq_not_timerb
        ;; TIMER-B 処理: PMDNEO main driver 呼出
        call    pmd_main
        ;; TIMER-B reset
        ld      de, #0x2700
        ld      e, #0x2A        ; TIMER-B reset
        call    ym_write_a
irq_not_timerb:
        pop     ix
        pop     hl
        pop     de
        pop     bc
        pop     af
        ei
        reti
```

### 5-3. sound command framework との連携

§2-4 の案 A (= nullsound 系統 sound command framework 流用) を採るので、
sound command 受付経路は別途実装:

```asm
;;;
;;; M68K → Z80 sound command 受付
;;;

cmd_jmptable::
        jp      snd_command_unused                  ; 0x00
        jp      snd_command_01_prepare_for_rom_switch ; 0x01 (= ngdevkit reserved)
        jp      snd_command_02_play_song            ; 0x02 楽曲再生開始
        jp      snd_command_03_stop_song            ; 0x03 楽曲再生停止
        jp      snd_command_04_fade_out             ; 0x04 fade out
        ;; ...
        init_unused_cmd_jmptable

snd_command_02_play_song:
        ;; M68K から渡された sound number で楽曲データの開始位置を取得
        ;; mmlbuf = 楽曲データ位置 を設定
        ;; play_init を call
        ;; TIMER-B start
        ret
```

### 5-4. ngdevkit Z80 binary 配置慣習との結合 (user judgment 13、 §2-4 で確定済)

§2-4 で確定した「nullsound 系統 sound command framework 流用 + driver
core 独自実装」 の結果:

- Z80 binary 配置: ngdevkit 標準の Z80 ROM 領域 (= M1 ROM)
- sound command 受付: nullsound の cmd_jmptable 慣習踏襲
- driver core: 独自 file (PMDNEO.ASM 以下)
- M68K 側: ngdevkit framework の `REG_SOUND` port 経由で command 発行

---

## 6. src/driver/ ディレクトリ構造 (再掲 + 起こし順序)

### 6-1. ディレクトリ配置

```
src/driver/
    PMDNEO.ASM        ; build top
    PMD_Z80.ASM       ; PMD.ASM の Z80 化 base
    ADPCMB_DRV.ASM    ; ADPCM-B driver
    ADPCMA_DRV.ASM    ; ADPCM-A driver (Phase 3 用 stub)
    KR_STUB.INC       ; K/R no-op stub
    IRQ.INC           ; TIMER-B IRQ handler
    REGMAP.INC        ; register 定数
    WORKAREA.INC      ; workarea offset 定数
```

### 6-2. file 起こし順序 (再掲)

§1-4 で記述した順序を Phase 2 sub-phase に展開:

```
SubA (skelton): REGMAP.INC + WORKAREA.INC + IRQ.INC + KR_STUB.INC + PMDNEO.ASM
                + 空 PMD_Z80.ASM / ADPCMB_DRV.ASM / ADPCMA_DRV.ASM
                → silent ROM がビルド通る (audio gate Step 1 前段)

SubB (SSG dispatch): PMD_Z80.ASM 内に commandsp + cmdtblp + per-part main
                を翻訳、 SSG 3ch dispatch のみ動作
                → SAMPLE.M を投入して G/H/I (SSG) のみ鳴る (Step 1 通過)

SubC (FM dispatch): PMD_Z80.ASM 内に commands + cmdtbl + FM 6ch を追加
                → FM 試料楽曲で FM 6ch dispatch 動作 (Step 2 通過)

SubD (K/R no-op): KR_STUB.INC を完全動作させ、 K/R cmd を含む `.m` を
                投入し si pointer ずれず (Step 4 通過)

SubE (ADPCM-B): ADPCMB_DRV.ASM を完成させ、 J part 駆動で .m2 投入
                → ADPCM-B 1ch 鳴る (Step 3 通過)

SubF (統合): SAMPLE2.M 等の長尺楽曲を投入し、 FM/SSG/ADPCM-B 統合動作
                → Phase 2 完了宣言
```

各 sub-phase 完了時に audio gate test を行う (= §7)。

---

## 7. 段階的 audio gate test 計画

### 7-1. Step 1: SAMPLE.M で SSG 3 part のみ鳴らす

- 対象: `vendor/pmd48s/SAMPLE.M` (1142 byte、 SSG 1-3 使用)
- 期待: G/H/I の MML body が解釈され、 NEOGEO 上で SSG 3 part が鳴る
- 合格基準:
  - MAME を起動して「再生開始」 sound command を発行 → audio 出力に SSG
    波形が現れる
  - user 聴感確認で SSG 3 part 全てが鳴っている (volume / pitch 正しい)
  - MAME ログで SSG register (0x06-0x0E 帯) の write が観測される
- 不合格時: cmdtblp の dispatch / fnumset PSG / volset PSG の routine
  を見直す

### 7-2. Step 2: FM 4 part 試料楽曲 (ADR-0001 (C) 方針)

- 対象: 簡単な FM 楽曲 (= 試料 .m を 1 つ作成、 PMDDotNET で compile、
  Part B/C/E/F の 4 ch のみ使用)
- 期待: chip ch 2/3/5/6 (= Part B/C/E/F) が正しい音色で鳴る
  (音色データ format = analysis §5-7 通りに解釈される)
- 合格基準:
  - 4 ch の FM 音色が全て発音 (= chip ch 2/3/5/6)
  - Part A/D に note を書いた場合は無音 (= ADR-0001 で許容、 driver 破綻なし)
  - operator 順序 (slot 1, 2, 3, 4 = OP1, OP3, OP2, OP4) が正しく
    register に書かれている (MAME ログ確認)
  - ALG/FB が正しく設定される

### 7-3. Step 3: SAMPLE2.M で ADPCM-B 1 part

- 対象: `vendor/pmd48s/SAMPLE2.M` (4872 byte、 J part 使用想定)
  ※ ただし SAMPLE2.M は実は J part empty (analysis §5-6-4-2)、 別の
  ADPCM-B 試料 .m2 を作成する必要
- 期待: J part の sample 再生が NEOGEO で鳴る
- 合格基準:
  - ADPCM-B sample が NEOGEO V-ROM bank から読み出される
  - register 0x10 (Start) / 0x12-0x15 (start/end addr) / 0x19-0x1A
    (delta-N) / 0x1B (volume) が正しく書かれている

### 7-4. Step 4: K/R cmd を含む `.m` で si pointer 整合 (user judgment 12)

K/R cmd を含む既存 `.m` を投入し、 driver が si pointer を正しく進めて
chip 書込なしで処理することを検証。

#### user judgment 12: 確認手段の選択

##### 案 A (推奨): MAME ログで chip register write を観測 + driver 内部 si trace 出力

- MAME -log オプションで全 register write を log 出力
- driver に debug build flag を追加し、 si pointer の値を Z80 RAM の
  特定 addr に dump
- 期待: K/R 関連 chip register (= ADPCM-A port B 0x00-0x2D) への write
  が **発生しない**、 si pointer が opcode 数 + 引数 byte 数の合計と
  一致

##### 案 B: 楽曲全体を聴感で「無音区間が想定通り」 と確認

- K/R cmd は無音化されるはず → 楽曲を聴いて「rhythm 部分が無音になっ
  ている」 ことを確認
- 欠点: 主観評価、 si pointer ずれによる微妙な暴走を見落とす risk

##### 案 C: driver が si pointer ずれを検出して halt

- driver に sanity check を追加し、 想定外の opcode を踏んだら halt
- 利点: 自動検出
- 欠点: 開発中の driver 実装に check code が混入、 リリース時に削除する
  作業が増える

案 A は客観的 + 開発体験良。

### 7-5. Step 5: 統合 audio gate (FM/SSG/ADPCM-B 長尺楽曲)

- 対象: FM 6 + SSG 3 + ADPCM-B 1 を全部使った試料楽曲
- 期待: 全 ch 同時駆動、 tempo / volume / fade / loop 正常動作
- 合格基準:
  - 楽曲全体が想定通りの聴感
  - tempo 変更 (T cmd / t cmd) が正しく反映
  - 楽曲 loop が正しく動作
  - fade out が正しく動作
- 不合格時: per-part main loop / IRQ 駆動 / TIMER-B 周期 を見直す

### 7-6. Step 5 通過 = Phase 2 完了宣言

Step 1-5 全通過で Phase 2 完了。 Phase 3 着手 (= ADPCM-A 6ch 拡張)。

---

## 8. 実装順序 (Phase 2 内 sub-phase)

### 8-1. Sub-phase 一覧 (再掲 + 想定期間)

| sub-phase | 作業内容 | 想定期間 | audio gate |
|---|---|---|---|
| SubA | skelton (REGMAP / WORKAREA / IRQ / KR_STUB / PMDNEO 空) | 3-5 日 | (ビルド通過のみ、 silent ROM) |
| SubB | SSG 3ch dispatch (commandsp / cmdtblp / fnumset PSG / volset PSG) | 1-2 週 | Step 1 通過 |
| SubC | FM 6ch dispatch (commands / cmdtbl / fnumset / volset / 音色 set) | 2-3 週 | Step 2 通過 |
| SubD | K/R no-op stub 完全動作確認 (cmdtblr の jump table set up) | 数日 | Step 4 通過 |
| SubE | ADPCM-B 1ch dispatch (ADPCMB_DRV.ASM 完成) | 1-2 週 | Step 3 通過 |
| SubF | 統合 audio gate (長尺楽曲、 tempo / fade / loop) | 1-2 週 | Step 5 通過 → Phase 2 完了 |

合計想定期間: **6-10 週 (= 約 1.5-2.5 ヶ月)**。 PMDNEO_DESIGN.md §2-3-4
の「数ヶ月レベル」 と整合。

### 8-2. 各 sub-phase 完了時の commit 慣習

各 sub-phase 完了時に:

1. audio gate test を実施 (= 本書 §7)
2. user 聴感確認 + MAME ログ確認
3. commit に sub-phase 名 + audio gate 結果を明記
4. push (origin/main)
5. 次 sub-phase 着手

memory `feedback_runtime_audio_verify_required.md` に従い、 driver
touch commit は **必ず** audio gate を経て push。 silent baseline 上の
偽完了を防ぐ。

---

## 9. 残課題 (Phase 3 着手前に閉じるべき項目)

1. cmdtbla (新規 ADPCM-A 用 dispatch table) の具体 entry 一覧 (= ADPCM-A
   用 cmd の opcode 番号割当) — Phase 3 着手前に設計書 4 として別書出
   or 設計書 2 §6 の更新
2. `.PNE` 内 sample header format の詳細 — Phase 3 着手前に確定 (= mc
   compiler / WebApp WAV→ADPCM-A 変換 と一体)
3. ADPCM-B sample pack の format 詳細 — Phase 2 SubE で必要、 §4-3 案 A
   を具体化
4. YM2610 register write の wait routine cycle 数 — Phase 2 SubA で実機
   検証して確定 (data sheet の 17 / 83 master cycles を Z80 cycle に
   換算)
5. NEOGEO Z80 RAM 全体 layout (= driver code + workarea + dispatch
   state + sound command queue) の確定 — Phase 2 SubA で確定

---

[draft v0.2 — §0-§9 完成、 user judgment 9-13 全件確定済。
 9: sdasz80、 10: `.PPC` 流用 + `.P86` は変換、 V-ROM 共有、
 11: OPNA 完全互換でフルサイズ確保、 12: MAME ログ + driver debug si trace、
 13: nullsound 系統 sound command framework 流用 + driver core 独自実装]
