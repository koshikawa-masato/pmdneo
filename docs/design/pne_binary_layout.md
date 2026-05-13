# `.PNE` バイナリ layout 仕様書

    位置付け: PMDNEO Step 7 (= `.PNE` asset pipeline sprint) 起票時点の設計書
    参照: [`PMDNEO_DESIGN.md`](PMDNEO_DESIGN.md) §1-8-3 (`.PNE` 既存方針)
    参照: [`mn_binary_layout.md`](mn_binary_layout.md) §4-3-3 (`.MN` 内 filename embed)
    参照: ADR-0021 (= Step 7 sprint 起票、 α-2 で §決定 5 補正済)
    状態: draft v0.2 (= α-2 段階、 path B / c1 正式確定 + converter I/O contract 固定)
    更新履歴:
      - v0.1 (= α-1、 commit `38e35bf`): provenance 調査 + binary layout 骨格 + path 候補整理
      - v0.2 (= α-2、 本 commit): path B / c1 正式採用、 §6 / §11 補正、 §12 converter I/O contract 新規

---

## 0. 位置付け

### 0-1. なぜ `.PNE` を新たに定義するのか

PMDNEO の Step 5 で ADPCM-A 6ch native path が成立 (= ADR-0019 Accepted) し、 driver は voice index 引きで sample header table から ADPCM-A address (= start_addr / stop_addr の 16-bit ペア) を取り出して chip register に書く動作が確立した。

ただし sample 実体の **供給経路** (= sample data の出処、 ROM への embed 経路、 driver からの address 解決) は現状:

- `assets/sounds/adpcma/2608_{BD,SD,HH,RIM,TOM,TOP}.adpcma` (= 自前 ADPCM-A binary 6 件、 出処は α-1 別途記録)
- `vendor/ngdevkit-examples/00-template/assets/samples-map.yaml` (= ngdevkit native sample map、 YAML 形式、 sample name + uri 列挙)
- `vromtool.py` (= ngdevkit standard tool、 samples-map.yaml と .adpcma binary を読んで VROM 配置 + `samples.inc` を `.equ` defines として生成)
- `vendor/ngdevkit-examples/00-template/build/assets/samples.inc` (= 生成 file、 `BD_START_LSB` 等 `.equ` 定義)
- driver assembler 経由で `samples.inc` の defines が解決され、 `standalone_test.s:2829-2840` の `.db BD_START_LSB, ...` が成立

つまり「sample 1 つ追加」 「sample 入れ替え」 「複数楽曲で sample 共有 / 分離」 等の運用は **samples-map.yaml の手編集** + vromtool.py 再 build に依存している。 楽曲制作者 (= MML 書き手) と sample 制作者 (= WAV → .adpcma 変換) の作業境界が ngdevkit native の `samples-map.yaml` を介して直結し、 楽曲側で「この sample pack を使う」 と宣言する自然な方法がない。

PMDNEO はこれを **`.PNE` (PMDNEO ADPCM-A sample pack file)** という独自 format に置き換え、 sample pack を 1 つの file として持ち運べる・楽曲側から `#PNEFile "filename.PNE"` で参照できる構造へ移行する。

### 0-2. `.PZI` (PPZ8) との関係

PMDPPZ で扱われていた `.PZI` (PPZ8 sample format) の精神的継承:

- 楽曲 (`.mz`) と sample pack (`.PZI`) を分離、 楽曲側 `#PCMEF` で参照
- 1 つの楽曲は 1 つの `.PZI` を参照、 sample pack 差し替えで楽曲データ不変
- driver は `.PZI` 内 sample table を runtime parse、 voice index → sample addr

`.PNE` はこの精神を踏襲しつつ、 ADPCM-A chip 経路 (= YM2610/B 内蔵) + NEOGEO V-ROM 配置という PMDNEO 固有の制約に合わせて binary 構造を再設計する。 PPZ8 互換性は採らない (= ADR-0006 / ADR-0021 scope-out)。

### 0-3. `.MN` との接続

`.MN` 内 `pne_filename_adr` (= extended_data_adr+12..13) が `.PNE` filename string (= NUL-terminated ASCII) を指す (= mn_binary_layout.md §4-3-3 確定済)。 例:

```
.MN 末尾:  "NEOSI001.PNE\0"
```

`.PNE` 本体は ROM 内に **`.MN` とは独立した領域** に配置され、 ROM builder (= 将来 sprint で実装) が filename → ROM bank を解決する。 詳細は §6 で扱う。

---

## 1. 設計原則

### 1-1. ADPCM-A 6 slot を最小構成として収容

`.PNE` の初期 format は **既存 PMDNEO 駆動済 6 slot** (= BD/SD/HH/RIM/TOM/TOP) をそのまま収容できる構造とする。 新規 sample 追加 / slot 数拡張は Step 7 scope-out、 将来 sprint で format version up で扱う。

### 1-2. ADPCM-A address space 単位の温存

YM2610 ADPCM-A chip 仕様で `start_addr` / `stop_addr` は **VROM 内 byte address の上位 8 bit** (= 256 byte 単位 address) として表現される。 `.PNE` 内でも sample 境界は **256 byte 単位** に揃え、 chip register に直接書ける形で持つ。

これは現状の `samples.inc` 生成結果と一致 (= BD は `[0x0000..0x03ff]` で `BD_START_LSB=0x00 / BD_STOP_LSB=0x03`、 256 byte 単位の上位 8 bit のみが意味を持つ)。

### 1-3. raw ADPCM-A binary を直接 embed

`.PNE` 内には **既に ADPCM-A 4-bit 圧縮された raw binary** を直接 embed する。 `.PNE` 内で再エンコード / 再サンプリングは行わない。 WAV → ADPCM-A 変換は WebApp / external tool が行い、 `.PNE` 入力時点で完了している前提。

### 1-4. converter 経路は別 sprint で確定

`.PNE` から driver consumable な状態 (= `samples.inc` 生成 or VROM 配置) への変換経路は **本書では format 仕様のみ確定**し、 具体 converter は ADR-0021 step 7-β / Step 7-α-2 で扱う。

### 1-5. driver 不変原則

driver source (= `src/driver/standalone_test.s`) は `.PNE` 導入後も **register write semantics 完全不変** (= ADR-0021 §決定 2)。 driver が `.PNE` を runtime parse する経路は本書 scope-out、 後続 sprint (= Step 8 候補) で扱う。

---

## 2. 既存 sample assets の provenance 調査結果 (= α-1)

### 2-1. 自前 ADPCM-A binary 6 件の出処

`assets/sounds/adpcma/` 配下に 6 件の `.adpcma` binary + 6 件の `-roundtrip.wav` (= ADPCM-A → WAV 再合成、 確認用) が存在:

| filename | size (byte) | 256-byte block 数 | samples.inc address range |
|---|---|---|---|
| `2608_BD.adpcma` | 1024 | 4 | `[0x0000..0x03ff]` |
| `2608_SD.adpcma` | 768 | 3 | `[0x0400..0x06ff]` |
| `2608_HH.adpcma` | 768 | 3 | `[0x0700..0x09ff]` |
| `2608_RIM.adpcma` | 512 | 2 | `[0x0a00..0x0bff]` |
| `2608_TOM.adpcma` | 1536 | 6 | `[0x0c00..0x11ff]` |
| `2608_TOP.adpcma` | 6144 | 24 | `[0x1200..0x29ff]` |
| **合計** | **10752** | **42** | **0x0000..0x29ff (= 10752 byte)** |

**Provenance 推定**: filename prefix `2608_` (= YM2608 OPNA chip 識別) + sample 名 (= BD/SD/HH/RIM/TOM/TOP = PMD V4.8s 公式 rhythm sample 名と一致) から、 **PMD V4.8s 由来の rhythm sample を 2608 OPNA ADPCM-A 形式で extract したもの** と推定。 確定した出処 (= 生成 tool / 変換手順) は α-1 段階では未確認、 必要なら別 sprint で git log + 著作権元確認。

### 2-2. ngdevkit 経路の現状

`vendor/ngdevkit-examples/00-template/assets/samples-map.yaml` が ADPCM-A 6 + ADPCM-B 1 (= beat、 ngdevkit 由来) の合計 7 entry を列挙:

```yaml
- adpcm_a:
    name: bd
    uri: file:///Users/koshikawamasato/Projects/pmdneo/assets/sounds/adpcma/2608_BD.adpcma
# (sd / hh / rim / tom / top も同様)
- adpcm_b:
    name: beat
    uri: file:///Users/koshikawamasato/Projects/pmdneo/vendor/ngdevkit-examples/00-template/assets/beat.wav
```

注意点:

- **uri が絶対 path**: ユーザー固有の home dir (= `/Users/koshikawamasato/...`) を含む。 移植性の問題あり、 将来的に環境変数 or 相対 path 化を検討
- **adpcm_a と adpcm_b が同一 yaml 内に混在**: ngdevkit native の流儀 (= 1 つの VROM bank に ADPCM-A + ADPCM-B を並置)
- **ADPCM-A 6 slot は yaml 順** (= bd/sd/hh/rim/tom/top) が VROM 配置順 (= 0x0000 から連続) になる

### 2-3. samples.inc の生成内容

`vendor/ngdevkit-examples/00-template/build/assets/samples.inc` (= vromtool.py 生成) の format:

```
;;; ADPCM samples map in VROM
;;; generated by vromtool.py (ngdevkit)

;;; bd
;;; 243-v1.v1 [000000..0003ff] ADPCM-A
        .equ    BD_START_LSB, 0x00
        .equ    BD_START_MSB, 0x00
        .equ    BD_STOP_LSB, 0x03
        .equ    BD_STOP_MSB, 0x00

;;; (sd / hh / rim / tom / top も同様)

;;; beat
;;; 243-v1.v1 [002a00..00a8ff] ADPCM-B
        .equ    BEAT_START_LSB, 0x2a
        .equ    BEAT_START_MSB, 0x00
        .equ    BEAT_STOP_LSB, 0xa8
        .equ    BEAT_STOP_MSB, 0x00
```

driver (= `standalone_test.s:2829-2840`) は `.db BD_START_LSB, BD_START_MSB, BD_STOP_LSB, BD_STOP_MSB` の形で `.equ` defines を直接消費し、 assembler 解決時に sample header 4 byte (= start LSB/MSB + stop LSB/MSB) が `.db` 並びになる。

### 2-4. ADPCM-A address space の解釈

samples.inc の address range と .adpcma file size の照合から:

- ADPCM-A `start_addr` / `stop_addr` は **VROM 内 byte address の上位 8 bit** (= 256 byte 単位)
- `BD_START_LSB = 0x00, BD_START_MSB = 0x00` → byte address `0x000000`
- `BD_STOP_LSB = 0x03, BD_STOP_MSB = 0x00` → byte address `0x0003ff` (= 256 × 4 - 1)
- `start_addr` / `stop_addr` の 16-bit ペアは「LSB / MSB の連結」 で 256-byte block 番号を表現 (= driver の `.db` 並びは LSB / MSB / LSB / MSB の 4 byte)

YM2610 spec に従い、 chip register `0x10+ch` (= start LSB)、 `0x18+ch` (= start MSB)、 `0x20+ch` (= stop LSB)、 `0x28+ch` (= stop MSB) に書く。

### 2-5. 重要な気づき: 既存経路は vromtool.py 経由

ADR-0021 §決定 5 で書いた想定 「`.PNE` → 直接 `samples.inc` 生成」 は **現状の vromtool.py 経路と競合**する。 現状 `samples.inc` は vromtool.py が自動生成しており、 PMDNEO driver build は ngdevkit native 経路の中に組み込まれている。

`.PNE` 導入時の選択肢:

| path | 流儀 | driver / build 改修 | vromtool.py 使用 |
|---|---|---|---|
| A | `.PNE` → `samples.inc` 直接生成 (= vromtool.py 完全バイパス) | 大 | なし |
| B | `.PNE` → `samples-map.yaml` + `.adpcma` binary 生成 → vromtool.py 経由 | 小 (= 既存経路温存) | あり |
| C | `.PNE` 内 `.adpcma` を抽出 → 既存 `assets/sounds/adpcma/` に展開 → vromtool.py 経由 | 最小 | あり |

「動いているものを壊さない」 + 「driver 不変」 + 「ngdevkit native 経路を活かす」 規律から **path B 推奨** (= `.PNE` は self-contained sample pack format、 converter で `samples-map.yaml` + `.adpcma` binary を生成、 vromtool.py が引き続き samples.inc を生成)。 path C は中間案。

**この path 選択は ADR-0021 §決定 5 の補正対象**。 α-2 (= converter I/O contract sprint) で正式判断 + ADR-0021 修正案を提出する。 本書 (= α-1) では現状認識として記録するに留め、 §3 以降の format 仕様は path B 前提で骨格化する。

---

## 3. `.PNE` 全体 byte map

```
+--------+---------------------------------------------------------------+
| offset | 内容                                                          |
+--------+---------------------------------------------------------------+
|   0..3 | magic "PNE\0" (= 4 byte ASCII、 NUL 終端)                     |
+--------+---------------------------------------------------------------+
|   4..5 | format version (= LE 16-bit、 初期 0x0001)                    |
+--------+---------------------------------------------------------------+
|   6..7 | slot count (= LE 16-bit、 ADPCM-A slot 数、 初期は 6 固定)    |
+--------+---------------------------------------------------------------+
|   8..15| 予約 (= 8 byte = 0、 将来拡張)                                |
+--------+---------------------------------------------------------------+
|  16..  | slot table (= per-slot entry × slot count、 §4 参照)          |
|        | 各 slot entry は固定 16 byte (= §4-1)                         |
+--------+---------------------------------------------------------------+
|  +N    | raw ADPCM-A binary data 領域 (= §5 参照)                      |
|        | slot 順に連続配置、 256 byte 境界 alignment                   |
+--------+---------------------------------------------------------------+
| (末尾) |                                                               |
+--------+---------------------------------------------------------------+
```

`N` = `16 + 16 × slot_count` (= header + slot table)。 初期 6 slot の場合 `N = 16 + 96 = 112` byte。

### 3-1. file size 見積

初期 6 slot (= BD/SD/HH/RIM/TOM/TOP) の場合:

- header + slot table: 112 byte
- raw ADPCM-A data: 10752 byte (= §2-1 合計)
- 合計: **10864 byte** (= 約 10.6 KB)

NEOGEO V-ROM 容量 (= 数 MB) に対しては十分余裕。

---

## 4. slot table layout

### 4-1. 各 slot entry (= 固定 16 byte)

```
+--------+---------------------------------------------------------------+
| offset | 内容                                                          |
+--------+---------------------------------------------------------------+
|   0..7 | sample name (= ASCII、 NUL 終端、 8 byte 固定、 余白は 0 埋め) |
+--------+---------------------------------------------------------------+
|   8..9 | raw data offset (= `.PNE` 先頭からの byte offset、 LE 16-bit) |
+--------+---------------------------------------------------------------+
|  10..11| raw data size (= byte 数、 LE 16-bit)                         |
+--------+---------------------------------------------------------------+
|  12..13| ADPCM-A start_addr (= LE 16-bit、 256 byte 単位、 §4-2 参照)  |
+--------+---------------------------------------------------------------+
|  14..15| ADPCM-A stop_addr (= LE 16-bit、 256 byte 単位、 §4-2 参照)   |
+--------+---------------------------------------------------------------+
```

### 4-2. start_addr / stop_addr の意味

`.PNE` 内 slot entry の `start_addr` / `stop_addr` は **VROM 配置後の ADPCM-A 256 byte 単位 address** を意味する。 ただし `.PNE` 単独では VROM 内最終配置位置を知らないため、 **`.PNE` 内 slot は VROM 内 offset 0 として相対表現** する:

- slot 0 (= 最初の sample): start_addr = 0
- slot 1: start_addr = slot 0 size / 256 (= 256 byte 単位)
- ...

VROM 内最終 address は `.PNE` 配置時に **converter (= step 7-β で実装) が base_addr を加算** して確定する。 path B 経由なら `.PNE` 内 start_addr = `samples-map.yaml` の slot 順を表現するだけで、 vromtool.py が VROM 配置時に最終 address を計算する。

### 4-3. sample name 規約

- ASCII 7 byte + NUL 1 byte (= 合計 8 byte 固定)
- 小文字英数字推奨 (= ngdevkit samples-map.yaml 慣習踏襲、 例 `bd`, `sd`, `hh`, `rim`, `tom`, `top`)
- 大文字小文字は区別する (= future contributor が小文字統一を守る)
- `samples.inc` 生成時は大文字化される (= `BD_START_LSB` 等、 既存 vromtool.py 流儀)

### 4-4. raw data offset / size の意味

- `raw data offset` = `.PNE` file 先頭からの byte offset (= header + slot table を超えた位置)
- `raw data size` = この slot の raw ADPCM-A binary の byte 数 (= 256 byte の倍数を期待、 256 alignment は §5-1 参照)
- converter は offset + size で raw binary を抽出し、 path B 経路で `.adpcma` file を生成する

---

## 5. raw ADPCM-A binary data 領域

### 5-1. 配置順 + alignment

- slot 順 (= slot table の出現順) に連続配置
- 各 slot の raw data 開始位置は **256 byte 境界に揃える** (= chip address space と一致、 VROM 配置時の不整合を防ぐ)
- 256 byte 境界に満たない slot 末尾は **0 padding**

例: 初期 6 slot の場合:

```
slot 0 (bd):  offset 112..1135  (size 1024、 padding 0、 終端 1136)
slot 1 (sd):  offset 1136..1903 (size 768、 padding 0、 終端 1904)
slot 2 (hh):  offset 1904..2671 (size 768、 padding 0、 終端 2672)
slot 3 (rim): offset 2672..3183 (size 512、 padding 0、 終端 3184)
slot 4 (tom): offset 3184..4719 (size 1536、 padding 0、 終端 4720)
slot 5 (top): offset 4720..10863 (size 6144、 padding 0、 終端 10864)
```

注意: header + slot table が 112 byte で、 raw data 開始 offset は 112。 これは 256 byte 境界には乗らないため、 §5-2 で alignment 案を扱う。

### 5-2. header + slot table の 256 byte 境界対策

選択肢:

| 案 | header padding | raw data 開始 |
|---|---|---|
| (i) | 112 → 256 byte に padding (= 144 byte 余白) | 256 |
| (ii) | header + slot table をそのまま、 raw data 直前まで | 112 |
| (iii) | slot count を 16 まで先回り確保 (= 16 entry × 16 byte = 256 byte slot table、 header 16 byte と合わせて 272 byte) | 272 → 256 alignment は 256 → padding 必要 |

**(i) 推奨**: header + 6 slot table = 112 byte の後 144 byte padding で raw data 開始を 256 byte 境界に乗せる。 将来 slot 数を増やす時 (= 16 slot, 32 slot 等) に header + slot table 領域を 256 byte 単位で拡張しやすい。

### 5-3. raw data format

各 slot の raw data は **YM2610 ADPCM-A 4-bit 圧縮 binary** (= 1 byte = 2 sample、 sample rate 18.5 kHz 想定)。 これは既存 `.adpcma` binary と同 format。 `.PNE` 内で再エンコードしない (= §1-3)。

---

## 6. 既存 ngdevkit 経路との接続 (= path B + c1 正式採用)

### 6-0. 本章の位置付け (= α-2 で正式確定)

α-1 (= 本書 v0.1) では path B が「他の候補 (= path A / C) より整合性が高い」 ことを示すに留めていた。 α-2 (= 本書 v0.2) で **vromtool.py 実仕様調査 + ADPCM-B 同居問題の対処案 (= c1)** を確定し、 path B / c1 を正式採用する。 ADR-0021 §決定 5 も同時に補正 (= path A → path B)。

### 6-0-1. vromtool.py 実仕様調査結果 (= α-2 確定事項)

`/opt/homebrew/bin/vromtool.py` を一次資料として実調査:

1. **複数 yaml 受付仕様**: usage `FILE [FILE ...]` (= 1 個以上の yaml file)、 実装 `load_sample_map_file(filenames)` で `for filename in filenames` loop により全 entry を merge した list として処理
2. **入力 type**: `furnace` / `adpcm_a` / `adpcm_b` の 3 種、 同一 yaml 内混在 + file 跨ぎ merge 両方可
3. **配置順保証**: vromtool.py の `allocate_samples` は smp list を順次 VROM 配置するため、 引数で渡す yaml file の順序が VROM 内 byte 配置順を決める

つまり **複数 yaml 渡しは vromtool.py 自体は無改造で実現可**。 ngdevkit native の機構として既に成立している (= 設計者が想定済の運用)。

### 6-0-2. 現状 Makefile (= 単一 yaml 渡し)

`vendor/ngdevkit-examples/00-template/Makefile` 内 vromtool 呼出:

```makefile
L116: $(VROM1): assets/samples-map.yaml
L141: $(BUILDDIR)/assets/samples.inc: assets/samples-map.yaml
L142:   $(VROMTOOL) --asm -s $(VROMSIZE) $< -o $(VROM1) -m $@
```

`$<` は最初の prerequisite のみを渡すため、 現状は **単一 yaml 経路** に固定。 c1 採用には Makefile を **複数 yaml 渡し** に書き換える必要あり (= §6-3 で詳述)。

### 6-0-3. c1 採用判定 + 構造案

`.PNE` は ADPCM-A 専用 (= ADR-0021 scope-out)、 現状の `samples-map.yaml` は ADPCM-A + ADPCM-B 同居 (= §2-2)。 vromtool.py が複数 yaml を受け付ける事実から、 **c1 (= yaml 分離)** を正式採用:

| 配置 | 種別 | ownership | source of truth |
|---|---|---|---|
| `assets/pne/PMDNEO01.PNE` | ADPCM-A sample pack (= 新規) | 手書き / 編集対象 | yes (= ADPCM-A 軸) |
| `assets/pne/samples-map-adpcmb.yaml` | ADPCM-B yaml (= 新規、 1 entry = beat) | 手書き / 編集対象 | yes (= ADPCM-B 軸) |
| `vendor/ngdevkit-examples/00-template/assets/samples-map-adpcma.yaml` | converter 生成 | 編集禁止 (= generated artifact) | no |
| `vendor/ngdevkit-examples/00-template/assets/{bd,sd,hh,rim,tom,top}.adpcma` | converter 抽出 | 編集禁止 (= generated artifact) | no |
| `vendor/ngdevkit-examples/00-template/build/assets/samples.inc` | vromtool.py 生成 (= 既存と同形式) | 編集禁止 (= 既存規約と同じ) | no |
| `assets/sounds/adpcma/2608_*.adpcma` 6 件 | legacy retain (= source of truth でなくなる) | cold storage、 source of truth は `.PNE` へ移行 | no |

scope-out 維持: **d1 (= ADPCM-B も `.PNE` 化)** は採らない (= Step 7 scope 拡大、 ADR-0021 §scope-out 違反)。 `.PNE` は ADPCM-A 専用 format として固定。

### 6-1. path B 経路図 (= 正式確定)

```
[source of truth]
assets/pne/PMDNEO01.PNE              assets/pne/samples-map-adpcmb.yaml
(ADPCM-A 6 slot、 手書き)             (ADPCM-B 1 entry = beat、 手書き)
       |                                       |
       ↓ converter (= step 7-β で実装)         ↓ cp / symlink (= β で経路確定)
       |                                       |
[generated artifact / 編集禁止]                [retained / source of truth]
vendor/ngdevkit-examples/00-template/assets/samples-map-adpcma.yaml
vendor/ngdevkit-examples/00-template/assets/{bd,sd,hh,rim,tom,top}.adpcma
                                              + samples-map-adpcmb.yaml
                                              |
                                              ↓ vromtool.py (= ngdevkit native、 完全不変)
                                                + 引数順序: adpcma yaml 先 / adpcmb yaml 後
                                              |
                                              ↓
                              vendor/ngdevkit-examples/00-template/build/assets/samples.inc
                              (= 既存と byte-identical な .equ defines)
                                              |
                                              ↓ assembler
                              driver build (= standalone_test.s 完全不変)
```

### 6-2. converter responsibility (= α-2 で正式確定)

`.PNE` → ngdevkit 入力 への converter の責務 (= 詳細仕様は §12 で固定):

1. `.PNE` magic / version 検証 (= error 時 exit 1)
2. slot table parse、 各 slot の name / raw data offset / size 抽出
3. raw ADPCM-A binary を slot 名で `{slot_name}.adpcma` file に書き出す
4. `samples-map-adpcma.yaml` を slot 順で生成 (= 先頭に「DO NOT EDIT」 警告 comment)
5. ADPCM-B (= beat 等) は **converter scope-out**、 別系統で `samples-map-adpcmb.yaml` を vromtool.py に渡す (= c1 採用)

### 6-3. Makefile 改修方針 (= 案 1 採用、 vendor 直接編集)

`vendor/ngdevkit-examples/00-template/Makefile` の 3 行を以下のように書き換える (= 実改修は β で converter 実装と同時に実施、 本 α-2 commit では仕様化のみ):

```makefile
# 改修前
L116: $(VROM1): assets/samples-map.yaml
L141: $(BUILDDIR)/assets/samples.inc: assets/samples-map.yaml
L142:   $(VROMTOOL) --asm -s $(VROMSIZE) $< -o $(VROM1) -m $@

# 改修後 (= 複数 yaml 渡し化)
L116: $(VROM1): assets/samples-map-adpcma.yaml assets/samples-map-adpcmb.yaml
L141: $(BUILDDIR)/assets/samples.inc: assets/samples-map-adpcma.yaml assets/samples-map-adpcmb.yaml
L142:   $(VROMTOOL) --asm -s $(VROMSIZE) $^ -o $(VROM1) -m $@
```

要点:

- `$<` → `$^` 変更で全 prerequisites を vromtool.py に渡す
- prerequisite 列挙順 (= `adpcma` 先 / `adpcmb` 後) が VROM 内 byte 配置順を保証 (= 既存と同順)
- vromtool.py 自体は無改造

**選定理由 (= 案 1 採用、 案 2 / 案 3 不採用)**:

| 案 | 流儀 | PMDNEO 整合性 |
|---|---|---|
| **案 1 (採用)** | vendor Makefile 直接編集 (= 3 行) | ◯ PMDNEO は既に vendor/ngdevkit-examples/00-template を実質 project build dir として扱う実績 (= config.mk symlink / build-poc.sh symlink 等)、 3 行明示改修は許容 |
| 案 2 | build-poc.sh で sed pre-process | × build pipeline 見通しが悪化 (= sed 経由の build artifact 改変は debug 困難) |
| 案 3 | build-poc.sh で override Makefile rule | × make 構造が複雑化、 override target の理解負荷 |

git diff 上で改修意図が透明であることが、 PMDNEO の vendor 改変方針 (= ADR-0006 / step 1 / step 5 で改造 PMDDotNET 等の大幅 vendor 改修を実施した実績) と整合する。

### 6-4. ADPCM-B yaml 配置 / ownership

`samples-map-adpcmb.yaml` の配置と内容 (= β で実体化、 α-2 では仕様化):

- **配置**: `assets/pne/samples-map-adpcmb.yaml` (= PMDNEO project 内、 vendor 配下ではない)
- **build 時の経路**: `build-poc.sh` が `assets/pne/samples-map-adpcmb.yaml` を `vendor/ngdevkit-examples/00-template/assets/` 配下へ cp or symlink (= 詳細経路は β で確定)
- **内容 (= 初期)**: 現状 `vendor/ngdevkit-examples/00-template/assets/samples-map.yaml` の ADPCM-B entry (= `beat`) をそのまま分離

```yaml
- adpcm_b:
    name: beat
    uri: file:///Users/koshikawamasato/Projects/pmdneo/vendor/ngdevkit-examples/00-template/assets/beat.wav
```

- **ownership**: PMDNEO 開発者が手書き、 source of truth
- **後続 sprint**: WebApp 経由 ADPCM-B 管理 UI を作る場合、 この yaml を生成する converter を別途設計 (= Phase 4 領域)

注意: 現状の絶対 path (= `/Users/koshikawamasato/...`) は移植性の問題あり (= §2-2 で既出)、 相対 path 化は別 sprint で扱う。 α-2 では既存 path 形式を踏襲。

---

## 7. 初期 `.PNE` asset の具体構成

### 7-1. 既存 6 slot を `.PNE` 化する例

filename: `PMDNEO01.PNE` (= 初期 sample pack 名)

```
offset  内容
+0..3   "PNE\0"
+4..5   0x0001 (version)
+6..7   0x0006 (slot count = 6)
+8..15  0x00 × 8 (予約)
+16..31 slot 0: name="bd\0\0\0\0\0\0", raw_offset=256, raw_size=1024, start_addr=0, stop_addr=3
+32..47 slot 1: name="sd\0\0\0\0\0\0", raw_offset=1280, raw_size=768, start_addr=4, stop_addr=6
+48..63 slot 2: name="hh\0\0\0\0\0\0", raw_offset=2048, raw_size=768, start_addr=7, stop_addr=9
+64..79 slot 3: name="rim\0\0\0\0\0", raw_offset=2816, raw_size=512, start_addr=10, stop_addr=11
+80..95 slot 4: name="tom\0\0\0\0\0", raw_offset=3328, raw_size=1536, start_addr=12, stop_addr=17
+96..111 slot 5: name="top\0\0\0\0\0", raw_offset=4864, raw_size=6144, start_addr=18, stop_addr=41
+112..255 0x00 × 144 (header padding to 256 boundary)
+256..1279 raw data slot 0 (bd: 1024 byte)
+1280..2047 raw data slot 1 (sd: 768 byte)
+2048..2815 raw data slot 2 (hh: 768 byte)
+2816..3327 raw data slot 3 (rim: 512 byte)
+3328..4863 raw data slot 4 (tom: 1536 byte)
+4864..11007 raw data slot 5 (top: 6144 byte)
```

合計 file size: **11008 byte** (= 約 10.75 KB、 header padding 込み)。

### 7-2. slot 順は ADPCM-A chip ch (= L=0..Q=5) と一致

driver の `adpcma_ch_sample_ptr_table` (= standalone_test.s:2825) は voice index 0..5 で sample header pointer を引く。 `.PNE` slot 順は **L=0 / M=1 / N=2 / O=3 / P=4 / Q=5** と一致させる:

| `.PNE` slot 番号 | sample name | PMD part letter | ADPCM-A chip ch |
|---|---|---|---|
| 0 | bd | L | 0 |
| 1 | sd | M | 1 |
| 2 | hh | N | 2 |
| 3 | rim | O | 3 |
| 4 | tom | P | 4 |
| 5 | top | Q | 5 |

これにより `.PNE` 内 slot 順がそのまま driver voice index になり、 mapping table が不要。

---

## 8. mc compiler / WebApp 側の利用想定

### 8-1. mc compiler 側 (= `#PNEFile` 宣言)

mc compiler `/B` mode で MML 内 `#PNEFile "PMDNEO01.PNE"` 宣言を読み取り、 `.MN` 内 `pne_filename_adr` 経由で filename string を embed する (= 既に実装済、 ADR-0021 §決定 3 verify 範囲)。

mc compiler は `.PNE` の中身を解釈しない (= filename を embed するだけ)。 sample 解決は build pipeline (= converter + vromtool.py) と driver build に委ねる。

### 8-2. WebApp 側 (= WAV → `.PNE` 変換 UI、 Phase 4 領域)

将来 WebApp で:

1. WAV file を upload
2. ADPCM-A 4-bit に圧縮 (= 既存 tool 流用)
3. 複数 sample を slot に配置
4. `.PNE` file として出力

この UI は本書 scope-out (= Phase 4)、 ただし `.PNE` format は WebApp 出力を前提として設計しているため、 format 拡張 (= version up) で互換性を保つ。

---

## 9. 検証計画 (= α-2 / β / γ で着手)

### 9-1. α-2 で確定する converter I/O contract

- input: `.PNE` file path
- output 1: `samples-map.yaml` (= ngdevkit 入力)
- output 2: `.adpcma` binary 群 (= 出力 dir 内)
- output 3: 検証用 metadata (= slot 一覧 / size / address)

### 9-2. β で実装する converter unit test

- `assets/sounds/adpcma/2608_*.adpcma` + 手書き `samples-map.yaml` を入力として `.PNE` 形式に round-trip
- 生成された `.PNE` を converter に通して `samples-map.yaml` + `.adpcma` binary 群を逆生成
- 元 `.adpcma` と byte-identical を確認 (= round-trip 検証)

### 9-3. γ で実施する ROM byte-identical 検証

- 既存経路: `samples-map.yaml` (= 手書き) → vromtool.py → samples.inc → driver build → ROM
- 新経路: `PMDNEO01.PNE` → converter → samples-map.yaml + .adpcma → vromtool.py → samples.inc → driver build → ROM
- 2 経路の ROM が byte-identical (= 完全一致) で primary gate PASS

---

## 10. 残課題 (= Step 7 内で順次解消)

1. `assets/sounds/adpcma/2608_*.adpcma` の確定した出処 (= 生成 tool / 変換手順) を git log + 著作権元確認で記録 (= α-2 or 別 sprint)
2. converter I/O contract の正式仕様 (= input / output 形式、 error handling、 path 規約) (= α-2)
3. `.PNE` slot 数を将来拡張する時の format version up 規約 (= 別 sprint)
4. ADPCM-B sample (= `.PNE` scope-out) の管理 mechanism (= 別 sprint)
5. WebApp 側 `.PNE` 生成 UI (= Phase 4)
6. driver 側 runtime `.PNE` parser (= Step 8 候補)

---

## 11. ADR-0021 §決定 5 補正 (= α-2 で正式確定)

α-1 調査で発見した「現状の `samples.inc` は vromtool.py 経由で生成済」 + α-2 調査で確認した「vromtool.py は複数 yaml file を正式に受け付ける (= `FILE [FILE ...]`)」 という 2 件の事実から、 ADR-0021 §決定 5 は以下のように **正式補正**する (= 本 α-2 commit で ADR-0021 同時 update)。

### 11-1. 補正対比

**補正前 (= ADR-0021 起票時の path A 想定)**:
> `.PNE` → 直接 `samples.inc` 生成 + driver source の sample data 部を生成 include へ移行

**補正後 (= path B / c1、 α-2 確定)**:
> `.PNE` → converter で `samples-map-adpcma.yaml` + `.adpcma` binary 群を生成 → ngdevkit vromtool.py が引き続き `samples.inc` を生成 (= 既存経路、 完全不変) → driver build へ。
>
> ADPCM-B (= beat 等) は `assets/pne/samples-map-adpcmb.yaml` (= 手書き、 source of truth retained) として別系統で管理、 vromtool.py に第 2 引数として渡す。
>
> driver source / vromtool.py / build pipeline 主要骨格はすべて完全不変。 改修対象は (a) converter (= 新規、 β で実装)、 (b) `vendor/ngdevkit-examples/00-template/Makefile` 3 行 (= β で実施)、 (c) `build-poc.sh` (= β/γ で ADPCM-B yaml 配置経路を追加) の 3 件のみ。

### 11-2. 補正のインパクト

この補正により ADR-0021 の規律がより強化される:

1. **driver 不変保証**: 元 ADR-0021 では「driver の data 部のみ生成 include へ移行」 という limited な改修を許容していた。 path B 採用により **driver は本当に完全不変** (= `standalone_test.s:2825-2840` を含む全 byte 単位で変更なし)
2. **ROM byte-identical primary gate 強化**: 既存経路と新経路で vromtool.py の input set が同一になるよう yaml 順序を制御するため、 生成 `samples.inc` も VROM byte 配置も既存と完全一致 (= byte-identical primary gate の難易度が下がる)
3. **converter scope 縮小**: 元 ADR-0021 では converter は「`.PNE` → `samples.inc` 生成 + driver source 改修支援」 だったが、 path B では「`.PNE` → ADPCM-A yaml + .adpcma 抽出」 だけで済む (= 100 行以下の python script で実装可能見込み)

### 11-3. ADR-0021 §決定 5 改定後 本文 (= ADR 側 update 内容、 参考)

ADR-0021 §決定 5 は本 commit で「**決定 5: build-time converter + ngdevkit vromtool.py 経路温存 (= path B、 α-2 で正式確定)**」 に書き換え、 本書 §6 を参照する形へ簡素化する。 詳細は ADR-0021 同 commit を参照。

---

## 12. converter I/O contract (= α-2 で正式確定)

`.PNE` → ngdevkit 入力 への converter (= 仮称 `scripts/pne-to-ngdevkit.py`、 β で実装) の I/O contract を仕様化する。 本節は converter 実装の準拠仕様であり、 β 着手時に script signature をここに合わせる。

### 12-1. Input

- **positional argument 1**: `.PNE` file path (= 例: `assets/pne/PMDNEO01.PNE`)
- **option `--output-dir`**: 出力先 dir (= optional、 default: `vendor/ngdevkit-examples/00-template/assets/`)
- **option `-v` / `--verbose`**: 詳細 log 出力 (= optional)

### 12-2. Output

| file | 配置 | 内容 |
|---|---|---|
| `samples-map-adpcma.yaml` | output-dir 直下 (= fixed name) | ADPCM-A slot 列を YAML 形式で列挙、 各 entry は `name` + `uri`、 uri は出力 .adpcma file の **絶対 path** |
| `{slot_name}.adpcma` | output-dir 直下 (= slot 数分) | `.PNE` 内 raw data section を slot 名で抽出した binary。 例: `bd.adpcma`, `sd.adpcma`, `hh.adpcma`, `rim.adpcma`, `tom.adpcma`, `top.adpcma` |

### 12-3. Output yaml の header convention

生成 `samples-map-adpcma.yaml` の先頭に以下の警告 comment を必ず付ける (= §11 補正後 ADR-0021 + §6-0-3 ownership table 整合):

```yaml
# DO NOT EDIT — generated from {input .PNE filename} by scripts/pne-to-ngdevkit.py
# source of truth: assets/pne/{input .PNE filename}
# regenerate with: python3 scripts/pne-to-ngdevkit.py assets/pne/{input .PNE filename}
```

### 12-4. Side effects

- 既存 file の上書き = **許可** (= generated artifact なので、 converter 再実行で常に最新化)
- 出力 dir 不在 = **自動作成** (= `mkdir -p` 相当、 path traversal 防止のため安全 path check 必須)
- 既存 `samples-map.yaml` (= 元 single yaml) との関係: converter は **touch しない** (= 別 file 名で生成、 既存 file は手動で remove or rename を別 sprint で扱う)

### 12-5. Error handling (= 全 case exit 1 with error message to stderr)

| condition | error message 形式 |
|---|---|
| magic mismatch (= `PNE\0` 以外) | `error: invalid magic in {path}: expected 'PNE\0', got '{actual}'` |
| format version unsupported (= 0x0001 以外、 α-2 段階) | `error: unsupported .PNE version: {version}` |
| slot count != 6 (= 初期固定、 将来拡張で許容範囲拡大) | `error: slot count must be 6 (got {count})` |
| output dir 書込権限なし | `error: cannot write to output dir: {dir}` |
| raw data offset + size が file size 超過 | `error: corrupted .PNE: slot {n} raw data range {offset}+{size} exceeds file size {fsize}` |
| slot name に invalid character (= ASCII printable + lowercase 推奨範囲外) | `error: invalid slot name '{name}' at slot {n}` |
| `.PNE` file が読めない | `error: cannot read .PNE file: {path}: {reason}` |

### 12-6. File naming convention

- **生成 yaml**: `samples-map-adpcma.yaml` 固定 (= source of truth の `samples-map.yaml` と命名衝突を避けつつ ADPCM-A 専用を明示)
- **生成 .adpcma**: slot name lowercase + `.adpcma` 拡張子 (= 例: `bd.adpcma`)
- **既存 legacy 命名**: `assets/sounds/adpcma/2608_BD.adpcma` 等は **β/γ 完了後に cold storage へ移動** を検討 (= 本 α-2 では retain、 source of truth でなくなる事実だけ §6-0-3 で明示)

### 12-7. unit test 方針 (= β で着手)

#### 12-7-1. round-trip test

1. 既存 `assets/sounds/adpcma/2608_*.adpcma` 6 件 + 手書き ADPCM-A 部分 yaml から `.PNE` 形式へ pack (= pack tool は β で実装、 別 script or converter の reverse mode)
2. 生成された `.PNE` を converter に通して `samples-map-adpcma.yaml` + `{bd,sd,hh,rim,tom,top}.adpcma` を逆生成
3. 元 `2608_*.adpcma` と生成 `{slot}.adpcma` の中身 byte-identical を確認 (= filename 差は許容、 binary 内容一致が gate)

#### 12-7-2. ROM byte-identical test (= primary gate、 γ で実施)

1. **既存経路**: 手書き `samples-map.yaml` (= 7 entry 同居) → vromtool.py → `samples.inc` → driver build → `ROM`
2. **新経路**: `PMDNEO01.PNE` → converter → `samples-map-adpcma.yaml` + 6 件 `.adpcma` + `samples-map-adpcmb.yaml` (= 別 file) → vromtool.py (= 複数 yaml 引数) → `samples.inc` → driver build → `ROM`
3. **gate**: 2 経路の ROM が **完全一致** (= byte-identical)

#### 12-7-3. register trace gate (= step 5/6 規律踏襲)

- step 5 β-3 verify script 同等経路で ADPCM-A register write を trace (= `@0/@1` sample addr 差分が新経路でも保持される)
- silent-bcef fixture (= step 6) + MAME 試聴で audio gate (= human listening reference)

### 12-8. converter 実装 scope-out (= 後続 sprint で扱う)

- `.PNE` pack tool (= WAV → `.PNE`、 WebApp 領域 = Phase 4)
- 複数 `.PNE` file 対応 (= 楽曲ごと別 sample bank、 別 sprint)
- ADPCM-B も `.PNE` 化 (= d1 不採用、 別 sprint で検討)
- 相対 path 形式 (= 現状の uri 絶対 path 移植性問題、 別 sprint)

---

[draft v0.2 — α-2 完成。 §6 path B / c1 正式採用 + §6-3 Makefile 改修方針 + §6-4 ADPCM-B yaml 配置 / §11 ADR-0021 §決定 5 補正正式確定 / §12 converter I/O contract 固定。 次は β = converter 実装 + Makefile 改修 + ROM byte-identical 検証]
