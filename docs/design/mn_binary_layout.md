# `.mn` バイナリ layout 仕様書

	位置付け: PMDNEO Phase 2 driver 着手前 設計書 3 種の 1 番目 (= ベース)
	参照: [`analysis_m_data_structure.md`](analysis_m_data_structure.md) (`.m` 解析 v3 完了、 1377 行)
	参照: [`PMDNEO_DESIGN.md`](PMDNEO_DESIGN.md) §1-8 (`.mn` / `.PNE` 既存方針)
	状態: draft 進行中 (§0-§3 完成、 §4-§11 は段階的に追記)

---

## 0. 位置付け

### 0-1. なぜ `.mn` を新たに定義するのか

PMDNEO は NEOGEO (YM2610/B) 上で動作する PMD 系統の独立 driver で、 既存
PMD ファミリ (`.m` / `.m2` / `.mz`) では扱えない 2 つの拡張を必要とする:

1. **ADPCM-A 6ch** (= YM2610/B 内蔵 PCM 音源、 K/R 内蔵リズムの代わり)
2. **`.PNE` サンプルパック参照** (= 既存 `.PZI` / `.PPC` / `.P86` とは別系統)

これらを既存 `.m` / `.m2` / `.mz` の binary に持ち込むと、 PMD V4.8s
公式 driver (PMD.COM / PMDB2.COM / PMDPPZ.COM) との互換性を破壊するため、
PMDNEO 独自の拡張子 `.mn` を新規定義する。

### 0-2. `.m` との関係

`.mn` は **`.m` の上位互換**として設計する:

- 前 26 byte header (m_start + 11 part offset table + rhythm addr offset
  + prgdat_adr) は `.m` と完全同一
- 11 part letter (A-F + G-I + J + R) の役割も同一 (FM 6ch / SSG 3ch /
  ADPCM-B 1ch / Rhythm)
- ADPCM-A 6ch は **後方拡張領域**に独立して配置 (既存 11 part に手を
  入れない)
- 結果として、 既存 OPNA `.m` を PMDNEO driver にロードしても誤動作なく
  動作する (= FM/SSG/ADPCM-B 鳴る、 K/R 内蔵 rhythm 部分は無音)

### 0-3. `.mz` との対比

PMDPPZ の `.mz` も既存拡張子の 1 つだが、 解析の結果 **実は独立 binary
format ではない**ことが判明した:

- mc compiler (PMD V4.8s 公式 / PMDDotNET) は `.m` を 1 種類しか出さない
- PPZ8 拡張は MML 上で `#PCMEF` 等の宣言で **Part J を 8ch sub-part に
  拡張**することで実現 (`ppz_extpartset` cmd 経由)
- driver 側 (PMDPPZ.COM) が Part J + sub-part 群を PPZ8 chip 駆動に振り
  分ける

つまり `.mz` の実体は「`.m` と同じ binary を PPZ8 対応 driver で解釈する」
ものであり、 拡張は **driver 側にある**。

PMDNEO の `.mn` はこれと異なり、 **binary format 自体を後方拡張**する
形を採る (= ADPCM-A 6ch を新規 letter L/M/N/O/P/Q として独立 part 化、
part offset table を後ろに 6 entry 増やす)。 PMDPPZ 流儀の「sub-part
拡張」 は採らない理由:

- PMDNEO は ADPCM-B (Part J) を既に占有しているため、 PPZ8 流儀で Part J
  を sub-part 化すると ADPCM-B との同居が複雑化
- ADPCM-A は元々 6 ch 独立 chip 機能なので「6 個独立 part」 として並べ
  る方が自然
- driver 実装が dispatch 構造として clean

「PPZ 風後方拡張」 という方針表現は **「PMD 既存資産の精神を継承しつつ
binary 拡張を独立領域として追加する」** 流儀の意味であり、 PMDPPZ
sub-part 拡張の literal 模倣ではない。

---

## 1. 設計原則

### 1-1. OPNA バイナリ互換 layout を温存

`.mn` は `.m` の前 26 byte header (= OPNA 標準) と part letter A-K の
役割を **完全に温存**する。 これにより:

- 既存 PMD V4.8s OPNA 楽曲 (.m) を PMDNEO driver にロードしても、 FM 6ch
  + SSG 3ch + ADPCM-B 1ch が鳴る (K/R 内蔵 rhythm のみ無音、 誤動作なし)
- 既存 PMD MML 文法 (V4.8s 系) との互換性が保たれる
- mc compiler の OPNA 出力経路は無改造で温存できる (= `.mn` 出力は追加
  経路として別実装)

### 1-1-1. Part A/D 不使用の自己規律 (ADR-0001 (C) 方針)

`.mn` の letter mapping は PMD V4.8s OPNA 慣習を温存 (= Part A-F = FM 6ch)
するが、 楽曲生成側で **Part A / Part D は不使用** とする自己規律を持つ。
理由:

- NEOGEO 標準の YM2610 無印 chip では chip ch 1/4 (= Part A/D) に output
  配線がない (= register write は通るが音が出ない)
- PMD driver の不変条件 (= 無効 ch register write は破綻せず無音) と物理仕様が
  二重整合
- 楽曲は Part B/C/E/F の 4 ch FM + Part G-I の SSG 3ch + Part J の ADPCM-B +
  Part L-Q の ADPCM-A 6ch の計 14 ch で運用

driver は YM2610B 仕様で 6 ch FM dispatch を実装する (= 楽曲が誤って Part A/D
を使っても破綻しない)。 mc compiler は Part A/D に note が書かれた場合 warning
を出す (= error にはしない)。

詳細は [`docs/adr/0001-fm-ch1-ch4-no-use-policy.md`](../adr/0001-fm-ch1-ch4-no-use-policy.md)。

### 1-2. K/R workarea / address は OPNA layout 通り確保

K/R (内蔵 rhythm) part は PMDNEO では使用しない (YM2610/B に内蔵 rhythm
機構は存在しない) が、 driver 側で workarea / アドレス指定領域は
**OPNA layout 通り確保**する:

- part 11 (R = K) の workarea は `.m` 通りの位置に置く
- `rhykey` / `rhyvs` / `rpnset` / `rmsvs` / `rmsvs_sft` / `rhyvs_sft` /
  `pdrswitch` の 7 個 handler は **no-op stub** として実装 (引数 byte
  数だけ正しく消費して ret、 chip 書込なし)

これにより、 K/R cmd を含む既存 `.m` を投入しても driver の MML
pointer (si) がずれず、 後続 cmd が壊れない。

### 1-3. ADPCM-A 6ch は独立 part として後方拡張

ADPCM-A 6ch は新規 letter **L / M / N / O / P / Q** を割当、 part
offset table を `.mn` 末尾近くに **6 entry 後方拡張**する。 既存 11
part offset table (22 byte) は touch せず、 後ろに 6 × 2 = 12 byte を
追加する形を採る。

詳細は §4 (後方拡張領域 layout) で確定する。

### 1-4. driver は単一 binary で全 chip 機能統合

PMDNEO driver は 1 個の Z80 binary で:

- FM 6ch (YM2610/B 仕様)
- SSG 3ch
- ADPCM-A 6ch
- ADPCM-B 1ch

を全て駆動する。 PMD V4.8s の build 構造 (= PMDPPZ.ASM が `include
PMD.ASM` + flag 設定で本体を統合) を Z80 化で踏襲し、 拡張 module を
include する形で 1 binary に纏める。 詳細は設計書 3 (Phase 2 driver
実装計画書) で扱う。

---

## 2. 全体 byte map

`.mn` ファイルの構造 (高位の概要、 詳細は §3-§4):

```
+--------+---------------------------------------------------------------+
| offset | 内容                                                          |
+--------+---------------------------------------------------------------+
|   0    | m_start (1 byte) — `.m` と同じ                                |
+--------+---------------------------------------------------------------+
|   1    | (m_buf 開始)                                                  |
|        |                                                               |
|        |  ※ 以下 offset は m_buf 相対 (= file byte - 1)                |
|        |                                                               |
|  +0    | part offset table 11 entry × 2 byte LE = 22 byte (`.m` 互換) |
|        |   m_buf[0..1]  : Part A (FM 1) offset                         |
|        |   m_buf[2..3]  : Part B (FM 2) offset                         |
|        |   m_buf[4..5]  : Part C (FM 3) offset                         |
|        |   m_buf[6..7]  : Part D (FM 4) offset                         |
|        |   m_buf[8..9]  : Part E (FM 5) offset                         |
|        |   m_buf[10..11]: Part F (FM 6) offset                         |
|        |   m_buf[12..13]: Part G (SSG 1) offset                        |
|        |   m_buf[14..15]: Part H (SSG 2) offset                        |
|        |   m_buf[16..17]: Part I (SSG 3) offset                        |
|        |   m_buf[18..19]: Part J (ADPCM-B / PCM) offset                |
|        |   m_buf[20..21]: Part K=R (Rhythm body) offset                |
+--------+---------------------------------------------------------------+
|  +22   | rhythm address table offset (2 byte LE) — `.m` 互換           |
+--------+---------------------------------------------------------------+
|  +24   | prgdat_adr (2 byte LE、 option) — `.m` 互換                   |
|        |   ※ Part A offset == 24 のときは存在しない                     |
+--------+---------------------------------------------------------------+
|  +26   | (各 part body / rhythm pattern body / prgdat 領域)            |
|        |   Part A〜K の MML body                                        |
|        |   rhythm pattern body                                          |
|        |   prgdat (音色データ)                                          |
+--------+---------------------------------------------------------------+
|  +X    | ★ 後方拡張領域 (PMDNEO 独自、 §4 で確定)                     |
|        |   ADPCM-A 6 part offset (Part L〜Q) × 2 byte = 12 byte         |
|        |   ADPCM-A part body × 6                                        |
|        |   .PNE filename ptr / 拡張領域有無判別 等                       |
+--------+---------------------------------------------------------------+
```

`X` は `.mn` の prgdat 領域末尾の次の位置 (具体値は楽曲ごとに変動、
mc compiler が確定して header に offset を埋め込む)。

### 2-1. 既存 OPNA `.m` との byte 互換性

`.mn` の前半 (= file byte 0 〜 prgdat 領域末尾) は `.m` と **byte 単位
で完全同一**になる。 つまり同じ MML を PMDDotNET の OPNA 出力経路と
PMDNEO 出力経路の両方で compile すると、 前半は bit-by-bit 一致した
binary が出る。

この設計によって:

- 既存 OPNA mc compiler が出した `.m` を `.mn` に「拡張領域なし」 として
  扱える (= driver は後方拡張領域の有無を file size or sentinel で判定、
  なければ ADPCM-A part を空として処理)
- PMDNEO driver は `.m` と `.mn` を区別なくロード可能

### 2-2. file size の見積

- 前半部分 (`.m` 互換): 数 KB 〜 数十 KB (楽曲規模次第)
- 後方拡張領域: ADPCM-A 6 part × 数百 byte 〜 数 KB + .PNE filename
  string 数十 byte = 計 数 KB
- 合計: 楽曲規模が中規模なら 10〜30 KB 程度を想定

NEOGEO ROM 容量制約 (V-ROM 数 MB) に対しては余裕がある。

---

## 3. 前 26 byte header の詳細

`.m` 解析 v3 で確定済の構造をそのまま採用する。 ここでは `.mn` 視点で
再記述する。

### 3-1. m_start (file byte 0)

ファイル先頭の 1 byte。 `.m` 解析 v3 §2-1 / §2-2 参照。

```
bit 7 6 5 4 3 2 1 0
+-------------------+
| 0 0 0 0 0 0 X Y   |
+-------------------+
                  └─ x68_flg (X68000 mode flag)
                └─── opl_flg (OPL mode flag、 PMD V3.9 系で使用)
```

PMDNEO の場合:

- x68_flg = 0 (常に PC-98 / NEOGEO 系)
- opl_flg = 0 (PMD V3.9 系互換不要、 V4.8s 系のみサポート)
- bit 2-7: 予約 (常に 0)

つまり `.mn` の m_start は **常に 0x00**。

### 3-2. part offset table (m_buf[0..21])

11 part 分の offset を LE 16-bit で並べる。 各 offset は m_buf からの
相対アドレス (= file byte 1 を 0 とする offset)。

| m_buf offset | letter | 音源 | PMDNEO 動作 |
|---|---|---|---|
| 0..1 | A | FM 1 | 駆動 (YM2610B では生、 YM2610 では mute) |
| 2..3 | B | FM 2 | 駆動 |
| 4..5 | C | FM 3 | 駆動 |
| 6..7 | D | FM 4 | 駆動 (YM2610B では生、 YM2610 では mute) |
| 8..9 | E | FM 5 | 駆動 |
| 10..11 | F | FM 6 | 駆動 |
| 12..13 | G | SSG 1 | 駆動 |
| 14..15 | H | SSG 2 | 駆動 |
| 16..17 | I | SSG 3 | 駆動 |
| 18..19 | J | ADPCM-B / PCM | 駆動 (YM2610/B 内蔵 ADPCM-B 経路) |
| 20..21 | R (= K) | Rhythm body | no-op (workarea のみ確保) |

### 3-2-1. empty part の表現

ある part が MML 上で使われていないとき、 該当 part offset は **共通
の empty marker (= byte `0x80`) を指す**。 これは `.m` 標準の手法。

例: SAMPLE.M (`.m` 解析 v3 §3-3) では Part A〜F が全て使われていない
ため、 m_buf[0..1] = m_buf[2..3] = ... = m_buf[10..11] のいずれも同じ
位置 (= 0x80 が並ぶ領域) を指す。

PMDNEO driver は part body を読み込み始めて先頭 byte が `0x80` の場合、
その part を駆動せず idle 状態に保つ (= `.m` driver と同じ動作)。

### 3-3. rhythm address table offset (m_buf[22..23])

rhythm pattern address table の m_buf 相対 offset (LE 16-bit)。 K/R part
が R 番号 (R0, R1, ...) を踏んだとき、 各番号に対応する rhythm pattern
body の開始位置を引くためのテーブル。

PMDNEO では K/R を駆動しないため、 driver はこの offset 値を **読むが
解釈しない**。 ただし mc compiler が出力する `.mn` には `.m` と同じ
位置にこの 2 byte を含める (= OPNA 互換性のため)。

### 3-4. prgdat_adr (m_buf[24..25]、 option)

音色データ (prgdat) 領域の m_buf 相対 offset。 `.m` 解析 v3 §2-4 参照。

存在条件: **Part A offset (m_buf[0..1]) ≠ 24 のとき**に存在する。 つまり:

- Part A offset = 24 → prgdat_adr なし、 m_buf[24..25] からは Part A の
  body が始まる
- Part A offset = 26 → prgdat_adr あり、 m_buf[24..25] が prgdat 領域
  への offset、 m_buf[26..] から各 part body 開始

PMDNEO の `.mn` では音色データを内蔵する想定なので、 **ほぼ常に
prgdat_adr が存在する** (Part A offset = 26)。

---

## 4. 後方拡張領域の layout

`.mn` 独自の後方拡張領域は **prgdat 領域の末尾以降**に配置する。 `.m`
互換の前 28 byte header (m_start + m_buf[0..27]) を一切壊さず、 既存
PMD V4.8s OPNA mc compiler が出した `.m` を PMDNEO driver で再生する
場合の互換性を最大化する設計。

### 4-1. 拡張領域有無の判別 — m_start bit 2 = PMDNEO mode flag

file byte 0 (m_start) の bit 2 を **PMDNEO mode flag** として新規定義
する:

```
file byte 0: m_start
  bit 0: x68_flg     (X68000 mode、 `.m` 互換、 PMDNEO では常に 0)
  bit 1: opl_flg     (OPL mode、 PMD V3.9 系、 PMDNEO では常に 0)
  bit 2: PMDNEO mode (1 = 後方拡張領域あり、 0 = `.m` 互換 mode)
  bit 3-7: 予約 (常に 0)
```

driver の判定動作:

| m_start | 解釈 |
|---|---|
| 0x00 | 既存 `.m` 互換 mode、 後方拡張領域なし、 ADPCM-A 全 part 無音 |
| 0x04 | PMDNEO `.mn` mode、 後方拡張領域あり、 ADPCM-A 6 part を駆動 |
| 0x01 | (X68 mode、 PMDNEO では非対応 → エラー or `.m` 互換扱い) |
| 0x02 | (OPL mode、 PMDNEO では非対応 → エラー or `.m` 互換扱い) |

**選定理由**: m_start は元々 `.m` で OPL/X68 flag 用の予約 byte で、
PMDNEO は OPL/X68 を使わないため bit 2 が空いている。 byte 追加せずに
拡張 mode を表現でき、 既存 `.m` (m_start = 0x00) と driver 側で明確に
区別できる。

### 4-2. m_buf header 拡張 — extended_data_adr (m_buf[26..27])

PMDNEO mode flag = 1 のとき、 m_buf header を 26 byte → 28 byte に
拡張し、 m_buf[26..27] に **extended_data_adr** (LE 16-bit) を置く:

```
m_buf[24..25]: prgdat_adr        (`.m` 互換、 .mn では常に存在)
m_buf[26..27]: extended_data_adr (PMDNEO 専用、 .mn のみ存在)
                ← ADPCM-A 6 part offset table の m_buf 相対 offset
m_buf[28..]:   各 part body / rhythm pattern body / prgdat 領域
```

`.mn` では Part A offset (m_buf[0..1]) は **28** になる (= 28 byte
header の直後から Part A body が始まる)。

#### 4-2-1. 仕様の固定値は header byte 数 28 (= shift 量ではない)

「26 byte → 28 byte」 という文言は既存 `.m` の `prg_flg = 1` (= `#FF`
あり) base での例示。 既存 `.m` header は `prg_flg` に依存して 2 通り
あるため、 `.mn` への shift 量も baseline によって変動する:

| `prg_flg` | 既存 `.m` header | `.mn` header | part offset shift |
|---|---|---|---|
| 0 (`#FF` なし) | 24 byte (= 22 part offset + 2 rhythm addr) | 28 byte | **+4** |
| 1 (`#FF` あり) | 26 byte (= 上記 + 2 prgdat_adr) | 28 byte | **+2** |

つまり PMDNEO mode では `prg_flg = 0` のときも prgdat_adr 領域 (= 値 = 0
で「音色データなし」 を表現) を強制確保し、 **header byte 数を `prg_flg`
に無依存に 28 byte で固定化**する。 driver 側は m_start bit 2 = 1 を
読み取り次第「header は常に 28 byte」 と解釈してよい (m_buf[24..25] =
prgdat_adr / m_buf[26..27] = extended_data_adr が常に成立)。

**仕様の固定値は header byte 数 28**。 shift 量 (+2 / +4) は基準とする
既存 `.m` の `prg_flg` に応じた **観測値**であり、 仕様としては固定化
しない。

ADPCM-A 6 part offset table の **実体**は prgdat 領域末尾以降に置く
(user judgment 分岐 1 で確定)。 extended_data_adr はその開始位置を
指すだけ。 driver は extended_data_adr を辿ることで ADPCM-A 領域に
直接到達できる。

### 4-3. 後方拡張領域の構造

extended_data_adr が指す位置から:

```
extended_data_adr +0..1:    ADPCM-A Part L offset (m_buf 相対、 LE 16-bit)
extended_data_adr +2..3:    ADPCM-A Part M offset
extended_data_adr +4..5:    ADPCM-A Part N offset
extended_data_adr +6..7:    ADPCM-A Part O offset
extended_data_adr +8..9:    ADPCM-A Part P offset
extended_data_adr +10..11:  ADPCM-A Part Q offset
extended_data_adr +12..13:  pne_filename_adr (= `.PNE` filename string への
                            m_buf 相対 offset、 LE 16-bit)
extended_data_adr +14..15:  予約 (将来拡張用、 常に 0)

extended_data_adr +16..:    ADPCM-A 6 part body (Part L〜Q の MML body)
                            ※ 各 part body の開始位置は ADPCM-A part offset
                              table が指す

(末尾近く)
pne_filename_adr +0..:      `.PNE` filename string (ASCII、 NUL-terminated)
```

#### 4-3-1. ADPCM-A 6 part offset table

ADPCM-A 6ch (Part L/M/N/O/P/Q) の MML body 開始位置を m_buf 相対 offset
で並べたテーブル。 各 entry は 2 byte LE。

empty part の表現は既存 `.m` と同じ流儀: 該当 part が MML 上で使われ
ていないとき、 共通の empty marker (= byte `0x80`) を指す。

#### 4-3-2. ADPCM-A part body

各 part body の opcode 体系は **基本的に既存 `.m` と同じ** (= dispatch
table cmdtbl の流儀):

- 0x00-0x7F: 音程 (OCT 4 bit + ONKAI 4 bit) + 音長 (1 byte)
- 0x80: part end / loop
- 0x81-0xB0: out_of_commands (終了)
- 0xB1-0xFF: 制御コマンド (dispatch table 経由)

ただし **dispatch table は ADPCM-A 専用の `cmdtbla` を新設**する案
(設計書 2 で確定予定)。 新規 letter 用なので既存 cmdtbl/cmdtblp/cmdtblr
の opcode 体系と被らない設計が可能。

#### 4-3-3. `.PNE` filename string

ASCII 文字列 (8.3 形式想定)、 NUL terminator (`0x00`) で終端。 例:

```
"NEOSI001.PNE\0"
```

driver は pne_filename_adr が指す位置から `0x00` まで読み取り、 ROM
内の対応する `.PNE` 領域を解決する (= ROM 配置時に mc compiler /
ROM builder が確定、 詳細は設計書 3 で)。

**選定理由**: PMDPPZ の `.PZI` 参照流儀 (= mc compiler が `.mz` 末尾に
filename を embed) を踏襲。 `.mn` 単独で参照解決可能、 sample pack の
差し替えは ROM 再 build なしで `.PNE` ファイル交換のみで可能。

### 4-4. 後方拡張領域 全体図

```
+---------+----------------------------------------------------+
| offset  | 内容                                               |
+---------+----------------------------------------------------+
| file 0  | m_start = 0x04 (PMDNEO mode flag = 1)              |
+---------+----------------------------------------------------+
| m_buf 0 | (m_buf 開始)                                       |
|   0..21 | 11 part offset (A〜K=R) — `.m` 互換                |
|  22..23 | rhythm address table offset                        |
|  24..25 | prgdat_adr                                         |
|  26..27 | extended_data_adr (PMDNEO 専用)                    |
|  28..   | 各 part body / rhythm pattern / prgdat 領域        |
|     :   |                                                    |
|     :   | (prgdat 領域末尾)                                  |
|     :   |                                                    |
| EXT +0  | ← extended_data_adr が指す位置                     |
|     +0..1   : ADPCM-A Part L offset                          |
|     +2..3   : ADPCM-A Part M offset                          |
|     +4..5   : ADPCM-A Part N offset                          |
|     +6..7   : ADPCM-A Part O offset                          |
|     +8..9   : ADPCM-A Part P offset                          |
|     +10..11 : ADPCM-A Part Q offset                          |
|     +12..13 : pne_filename_adr                               |
|     +14..15 : 予約 (= 0)                                     |
|     +16..   : ADPCM-A 6 part body (Part L〜Q)                |
| PNE +0  | ← pne_filename_adr が指す位置                      |
|         | `.PNE` filename string (NUL-terminated)            |
+---------+----------------------------------------------------+
```

### 4-5. mc compiler 出力時の手順 (擬似コード)

PMDNEO mode (= `.mn` 出力) の場合:

```
1. m_start = 0x04 を file byte 0 に書く
2. m_buf header 28 byte の領域を確保 (= 11 part offset + rhythm addr +
   prgdat_adr + extended_data_adr)
3. 各 part body / rhythm pattern body / prgdat 領域を順次出力 (.m 互換)
4. prgdat 領域末尾位置を記録 (= 後方拡張領域開始位置)
5. extended_data_adr を m_buf[26..27] に書き戻す (= step 4 の位置)
6. 後方拡張領域に:
   a. ADPCM-A 6 part offset table 領域 (12 byte) を確保
   b. pne_filename_adr 領域 (2 byte) を確保
   c. 予約 領域 (2 byte = 0) を確保
   d. ADPCM-A 6 part body を順次出力、 各 offset を 6a に書き戻す
   e. .PNE filename string を出力、 開始位置を 6b に書き戻す
7. file size を確定して保存
```

OPNA `.m` 互換 mode (= `.m` 出力) の場合は既存 PMDDotNET の `.m` 出力
経路をそのまま使う (m_start = 0x00、 m_buf[26..27] なし、 後方拡張領域
なし)。

---

## 5. part letter 割当

### 5-1. A〜K の役割 (`.m` 互換、 OPNA layout 通り)

| letter | 番号 | 音源 | PMDNEO 動作 |
|---|---|---|---|
| A | 0 | FM 1 | 駆動 (YM2610B 互換、 YM2610 では mute) |
| B | 1 | FM 2 | 駆動 |
| C | 2 | FM 3 | 駆動 |
| D | 3 | FM 4 | 駆動 (YM2610B 互換、 YM2610 では mute) |
| E | 4 | FM 5 | 駆動 |
| F | 5 | FM 6 | 駆動 |
| G | 6 | SSG 1 | 駆動 |
| H | 7 | SSG 2 | 駆動 |
| I | 8 | SSG 3 | 駆動 |
| J | 9 | ADPCM-B / PCM | 駆動 (YM2610/B 内蔵 ADPCM-B 経路) |
| R (= K) | 10 | Rhythm body | no-op (workarea のみ確保) |

### 5-2. L〜Q (PMDNEO 新規割当、 ADPCM-A 6ch)

| letter | 番号 | 音源 | PMDNEO 動作 |
|---|---|---|---|
| L | 11 | ADPCM-A 1 | 駆動 |
| M | 12 | ADPCM-A 2 | 駆動 |
| N | 13 | ADPCM-A 3 | 駆動 |
| O | 14 | ADPCM-A 4 | 駆動 |
| P | 15 | ADPCM-A 5 | 駆動 |
| Q | 16 | ADPCM-A 6 | 駆動 |

PMDPPZ の sub-part 拡張流儀 (= Part J を 8ch に sub-part 化) は採らず、
**独立した part letter として並べる**設計。 既存 PMD MML 文法 (V4.8s
系) との衝突なし (= L-Q は V4.8s 標準では未使用)。

### 5-3. driver から見た part 番号 → workarea offset 対応

PMDNEO driver の workarea (Z80 上の memory layout) では、 各 part を
固定 offset で配置する:

| 番号 | letter | workarea offset | size |
|---|---|---|---|
| 0 | A | base + 0×N | N byte |
| 1 | B | base + 1×N | N byte |
| ... | | | |
| 9 | J | base + 9×N | N byte |
| 10 | R (= K) | base + 10×N | N byte (no-op stub のため最小 size 検討) |
| 11 | L | base + 11×N | N byte |
| ... | | | |
| 16 | Q | base + 16×N | N byte |

`N` (= per-part workarea サイズ) は設計書 3 で確定する。 K/R workarea
は **OPNA 完全互換でフルサイズ確保するか、 アドレス計算のみ整合させて
実体サイズを縮めるか**は user judgment 11 で決定。

---

## 6. driver の memory layout

PMDNEO driver は `.mn` を Z80 SRAM (NEOGEO Z80 領域) にロードして解釈
する。 memory 配置の概要:

```
Z80 SRAM (推定 2 KB):
+----------------+--------------------------------+
| Z80 code area  | PMDNEO driver code (本体)      |
| ROM-banked     |                                |
+----------------+--------------------------------+
| RAM area       | mmlbuf (= `.mn` ロード位置)     |
|                | part workarea × 17 part         |
|                | dispatch state / IRQ stack      |
|                | tempo / fade / etc.             |
+----------------+--------------------------------+
```

詳細 layout は設計書 3 で確定する。

### 6-1. mmlbuf の配置

`.mn` 全体を Z80 SRAM の連続領域にロードする。 file byte 0 (m_start)
は `mmlbuf - 1` の位置に置き、 file byte 1 以降が `mmlbuf` から始まる
(`.m` driver の慣習に従う)。

driver は m_buf を起点に header (前 28 byte) を解析し、 各 part offset
を絶対アドレス化して per-part workarea に格納する。

### 6-2. K/R workarea の no-op 化方針

K/R part (Part R = 番号 10) の workarea は **OPNA layout 通りのサイズ
で確保**する (= 既存 PMD `.m` の K/R cmd を投入しても si pointer が
ずれないようにするため、 アドレス計算は OPNA 互換が必要)。 ただし
chip 駆動 routine は no-op stub で、 chip register への書込は発生
しない。

詳細な stub 実装は設計書 3 §3 で扱う。

---

## 7. mc compiler 出力時の byte 順序 (詳細)

### 7-1. PMDDotNET の `.m` 出力経路の何を改修するか

PMDDotNET の mc compiler は現状 OPNA 用 `.m` (拡張子 `.M`) を 1 種類
出力する。 PMDNEO 用に新たに **`.mn` 出力経路を追加**する形で改修
する (既存 OPNA 出力経路は無改造で温存)。

具体的な改修対象 file (Phase 3 mc compiler 改良時に着手):

- `PMDDotNETCompiler/mc.cs` (= main compile loop): `.mn` mode 切替
- `PMDDotNETCompiler/m_seg.cs` (= binary buffer): 後方拡張領域の出力
- `PMDDotNETCompiler/mml_seg.cs` (= MML parse): L-Q letter の認識、
  `#PNEFile` 等の新 # コマンド対応

### 7-2. ADPCM-A part が空の楽曲 / 一部 part のみ使用時の出力規則

- ADPCM-A 全 6 part が空 → `.mn` ではなく `.m` で出力 (PMDNEO mode flag
  を立てる必要なし)
- ADPCM-A 一部 part のみ使用 → 該当 part のみ MML body を出力、 残り
  は empty marker (= 0x80 を共通領域として共有) を指す
- `#PNEFile` 宣言なし → `.mn` 出力不可、 mc compiler エラー

### 7-3. `.PNE` 参照を持たない楽曲の扱い

PMDNEO の `.mn` は **常に `.PNE` を 1 つ参照する**前提とする (ADPCM-A
を一切使わない場合は `.m` で出力すれば良いため)。 `.mn` で `.PNE` 参照
なしは設計上想定外。

---

## 8. 既存 OPNA `.m` を PMDNEO driver で再生する場合の動作

### 8-1. driver から見た「拡張領域なし」 の判定

driver は `.mn` を読み込み、 file byte 0 (m_start) を確認:

- m_start = 0x00 → `.m` 互換 mode、 m_buf[26..27] は読まない、 後方拡張
  領域なしと判定、 ADPCM-A 6 part は全て idle
- m_start = 0x04 → PMDNEO mode、 m_buf[26..27] = extended_data_adr を
  読み、 後方拡張領域を解析

### 8-2. 鳴る part / 無音の part 一覧 (m_start = 0x00 の場合)

| part | 動作 |
|---|---|
| A〜F (FM 1-6) | 鳴る (YM2610B 互換、 YM2610 では A/D 無音) |
| G〜I (SSG 1-3) | 鳴る |
| J (ADPCM-B / PCM) | 鳴る (PMD V4.8s `.m2` の場合のみ、 `.m` では使用なし) |
| R (= K、 内蔵 rhythm) | **無音** (PMDNEO で no-op stub) |
| L〜Q (ADPCM-A) | **無音** (拡張領域なしのため idle) |

### 8-3. 誤動作なし保証の根拠

- K/R no-op stub が引数 byte 数を正しく消費するため、 si pointer がずれ
  ない (= 後続 cmd が壊れない)
- ADPCM-A 6 part は m_start bit 2 = 0 のとき driver が一切 access しない
  ため、 chip register に書込なし
- file byte 0 = 0x00 で「`.m` 互換 mode」 と driver 側が判定するため、
  m_buf[26..27] を誤って extended_data_adr として解釈することはない

---

## 9. 既存 `.mz` (PMDPPZ) との非互換性

`.mn` と既存 `.mz` (PMDPPZ) は **binary format が異なる**:

- `.mz` は実際は `.m` 同一 format、 PPZ8 拡張は MML 上の `#PCMEF` で
  Part J を sub-part 化することで実現
- `.mn` は header に extended_data_adr を新設し、 後方拡張領域を独自
  layout で持つ

つまり:

- `.mz` を PMDNEO driver にロードしても、 m_start = 0x00 で `.m` 互換
  mode と判定され、 PPZ8 拡張部分 (= Part J の sub-part) は **解釈
  されず無音**
- `.mn` を PMDPPZ.COM にロードすると、 m_start = 0x04 が想定外の値
  なので driver が誤動作する可能性 (= 互換性なし)

`.mz` ↔ `.mn` 相互運用は想定せず、 PMDPPZ ユーザーは MML を PMDNEO
向けに書き直して `.mn` を生成する必要がある。

---

## 10. 検証計画

### 10-1. mc compiler 試作時のチェックポイント

`.mn` 出力経路を mc compiler に追加した後:

- [ ] m_start = 0x04 が file byte 0 に書かれている
- [ ] m_buf[26..27] = extended_data_adr が prgdat 領域末尾を正しく指す
- [ ] extended_data_adr +0..11 に ADPCM-A 6 part offset が正しく並ぶ
- [ ] extended_data_adr +12..13 = pne_filename_adr が `.PNE` filename
      string の開始を指す
- [ ] pne_filename_adr 位置に NUL-terminated `.PNE` filename string がある
- [ ] file 末尾は filename の `0x00` で終わる (= 余分 byte なし)
- [ ] 同一 MML を OPNA `.m` mode で compile すると、 前 26 byte header
      + part body + prgdat が `.mn` の前半と完全一致する

### 10-2. driver 試作時のチェックポイント

PMDNEO driver の `.mn` ロード routine ができた後:

- [ ] m_start = 0x00 の `.m` を投入して FM/SSG/ADPCM-B が鳴る
- [ ] m_start = 0x00 の `.m` で K/R cmd を含むものを投入し、 chip 書込
      なし + si pointer ずれなし
- [ ] m_start = 0x04 の `.mn` を投入して L-Q (ADPCM-A 6ch) が駆動される
- [ ] `.mn` の `.PNE` filename を `.PNE` 領域と紐付けて sample 再生

---

## 11. 残課題 (Phase 2 着手で解消すべき具体検証項目)

1. `.mn` の Part A offset = 28 が driver の play_init routine で正しく
   絶対アドレス化されるか (= mmlbuf + 28 が Part A body 開始)
2. extended_data_adr のロード後、 ADPCM-A 6 part offset を per-part
   workarea にどう配置するか (= 6-3 の対応表に従って絶対アドレス化)
3. `.PNE` filename string を解析して ROM bank と紐付ける具体経路
   (= 設計書 3 で扱う ROM 配置と統合)
4. mc compiler 実装での `.mn` 出力時 byte 順序の最適化 (= prgdat と
   ADPCM-A part body のどちらを先に出力するかの最適解)

これらは設計書 2 / 設計書 3 で順次解決される。

---

[draft v0.2 — §0-§11 完成。 §4 で user judgment 分岐 1-3 解決済 (PMDNEO mode flag = m_start bit 2、 拡張領域 = prgdat 後ろ、 .PNE = `.mn` 末尾 embed)]

