# ADR-0016 step 7 β-1 finding handoff: converter prototype + `.PNE` 初期 asset + round-trip

- 起票日: 2026-05-13 (= 8th session β-1)
- 起票者: Claude Code
- 関連: ADR-0021 §決定 5 (= path B / c1 正式採用) / §決定 8 (= sub-sprint 構造 α/β/γ/δ/ε)、 `docs/design/pne_binary_layout.md` v0.2 (= α-2、 §6 / §12 contract 固定)
- 関連 commit: α-1 `38e35bf` (= `.PNE` binary layout 起票) / α-2 `e30ef4c` (= path B / c1 正式採用 + converter I/O contract)

## 概要

**β-1 は asset + converter commit** (= driver / vendor Makefile / build-poc.sh 不変)。 `.PNE` initial asset (= `assets/pne/PMDNEO01.PNE`) を bootstrap、 production-grade converter `scripts/pne-to-ngdevkit.py` を実装、 既存 `assets/sounds/adpcma/2608_*.adpcma` 6 件との round-trip byte-identical を 4 gate verify。

β-2 (= build pipeline 接続 = vendor Makefile 改修 + build-poc.sh + ADPCM-B yaml) / β-3 (= ROM byte-identical verify) の地盤を確立。

## β-1 改修対象

| 件 | file | 種別 | 行数 |
|---|---|---|---|
| 1 | `scripts/pne-pack-prototype.py` | 新規 (= bootstrap only prototype) | 152 |
| 2 | `scripts/pne-to-ngdevkit.py` | 新規 (= production-grade converter、 unpack only) | 152 |
| 3 | `assets/pne/PMDNEO01.PNE` | 新規 (= prototype pack で生成、 binary) | 11008 byte |
| 4 | `src/test-fixtures/step7/verify-step7-b1-roundtrip.sh` | 新規 (= 4 gate verify) | 128 |
| 5 | 本 handoff doc | 新規 | (本 file) |

**触らないもの**: driver source / vendor Makefile / build-poc.sh / vromtool.py / 既存 samples-map.yaml / 既存 samples.inc / `assets/sounds/adpcma/2608_*.adpcma` の中身。

## tool 責務境界 (= user 指示明示)

### scripts/pne-pack-prototype.py = bootstrap only

`.PNE` 初期 asset bootstrap 専用の prototype tool。 冒頭 docstring に明記:

- **bootstrap only / production packer ではない**
- 責務範囲: 既存 `.adpcma` 6 件を読んで `.PNE` を組み立てる + round-trip test 入力生成
- 責務外: WAV → ADPCM-A 変換 (= WebApp Phase 4) / production-grade pack tool / format version up / 複数 `.PNE` 同時生成

### scripts/pne-to-ngdevkit.py = production-grade converter

vromtool.py の前段 layer として位置付け。 冒頭 docstring に明記:

- 責務: `.PNE` → `samples-map-adpcma.yaml` + extracted `{slot}.adpcma`
- 責務外: pack mode (= bootstrap 側か Phase 4) / VROM packing / samples.inc 生成 (= vromtool.py 責務) / ADPCM-B slot / runtime parser / 複数 `.PNE` 対応

### generated artifact は手編集禁止

生成 yaml 先頭に「DO NOT EDIT」 警告 comment + source of truth + 再生成手順を必ず付ける:

```yaml
# DO NOT EDIT — generated from PMDNEO01.PNE by scripts/pne-to-ngdevkit.py
# source of truth: assets/pne/PMDNEO01.PNE
# regenerate with: python3 scripts/pne-to-ngdevkit.py assets/pne/PMDNEO01.PNE
```

## `assets/pne/PMDNEO01.PNE` の位置付け

- **β-1 段階の canonical test asset** (= round-trip + 後続 β-2 / β-3 で primary 入力)
- **将来 production asset format の唯一例とは限らない** (= 後続 sprint で別 `.PNE` 生成可能性、 Phase 4 WebApp 由来 asset 等)
- 既存 `assets/sounds/adpcma/2608_*.adpcma` 6 件を pack して bootstrap (= source of truth 移行は β/γ 完了後判断、 path B / c1 採用時の §6-0-3 ownership table 参照)

### production asset authoring flow とは別物

本 `PMDNEO01.PNE` は **`pne-pack-prototype.py` (= bootstrap only) で作られた canonical test asset** であり、 **production asset authoring flow の確定ではない**。 future contributor は以下を混同しないこと:

- `pne-pack-prototype.py` = bootstrap 専用 prototype (= β-1 round-trip test のため)
- production asset authoring (= WAV 素材 → ADPCM-A 変換 + slot 配置 + `.PNE` 生成) = **WebApp / 正式 packer / editor workflow** で行う、 **Phase 4 以降の領域**
- 「`PMDNEO01.PNE` の作り方」 = 「production workflow」 ではない

つまり β-1 では「`.PNE` format が機能する」 ことの実証は済んだが、 「楽曲制作者がどう `.PNE` を作るか」 は Phase 4 で別途設計される。

## `.PNE` binary 内容 (= 実測値)

`docs/design/pne_binary_layout.md` §7-1 (= α-1 設計値) と完全一致:

| slot | name | raw_offset | raw_size | start_addr | stop_addr |
|---|---|---|---|---|---|
| 0 | bd | 256 | 1024 | 0x00 | 0x03 |
| 1 | sd | 1280 | 768 | 0x04 | 0x06 |
| 2 | hh | 2048 | 768 | 0x07 | 0x09 |
| 3 | rim | 2816 | 512 | 0x0a | 0x0b |
| 4 | tom | 3328 | 1536 | 0x0c | 0x11 |
| 5 | top | 4864 | 6144 | 0x12 | 0x29 |
| 合計 | - | - | 10752 | - | - |
| **file size** | - | - | **11008 (= header 16 + slot table 96 + padding 144 + raw data 10752)** | - | - |

start_addr / stop_addr は既存 `vendor/ngdevkit-examples/00-template/build/assets/samples.inc` (= vromtool.py 生成) の `BD_START_LSB / BD_STOP_LSB / ...` と完全一致 (= β-3 で ROM byte-identical primary gate PASS の前提条件)。

## verify 結果 (= 4 gate PASS、 必須 gate user 指示)

```
$ bash src/test-fixtures/step7/verify-step7-b1-roundtrip.sh

=== step 7 β-1: converter prototype round-trip verify ===

--- gate 1: pack (= 既存 6 .adpcma → PMDNEO01.PNE) ---
  [PASS] gate 1: PMDNEO01.PNE = 11008 byte (expected 11008)
--- gate 2: unpack (= PMDNEO01.PNE → temp dir 内 6 .adpcma + yaml) ---
  [PASS] gate 2: 6 .adpcma + 1 yaml generated
--- gate 3: byte-identical 検証 (= 6 sample 全件 sha256、 必須 gate) ---
  [PASS] bd: 0dd42be876987e220f5ddb1192dfa83cd032258467d592a24b0ecca86a503656
  [PASS] sd: d517d7083d40457800c5fcf489819d68f17c8112c41a26b276c5521ffc6e3e71
  [PASS] hh: 6f6353b9180276b148ccf0927e46149f7a758683198ba6cf7ed463478513c531
  [PASS] rim: 952c9200c2c2f08f75c324d8ca919d3125bcee4309e334d92a48b6e1bcefa224
  [PASS] tom: 388f7b49435f6a53417c9089d440ba4808d92b870d61382601c9d3aac1cb2cd0
  [PASS] top: f1eb2b35b7f8b8484d729eb77f9f80fa21646c79708331ef037ad1ac2173544d
  [PASS] gate 3: 6/6 byte-identical
--- gate 4: 生成 yaml 構造確認 ---
  [PASS] gate 4: DO NOT EDIT + 6 adpcm_a entry + 6 slot name 全件確認

=== step 7 β-1 round-trip verify PASS (= 4/4 gate PASS) ===
```

gate 3 (= 6 sample 全件 byte-identical sha256) は **user 指示の必須 gate**、 失敗時は β-1 不成立。

## 想定外 finding (= memory 記録対象)

### finding 1: yaml encoding は ASCII では足りない (= utf-8 必須)

初版 `pne-to-ngdevkit.py` で `yaml_path.write_text(..., encoding="ascii")` としていたが、 「DO NOT EDIT — ...」 の `—` (= EM DASH、 U+2014) が ASCII 範囲外で `UnicodeEncodeError` 発生。

**修正**: `encoding="utf-8"` に変更。

**教訓**: yaml は本来 utf-8 標準 (= YAML 1.2 spec)、 ngdevkit 既存 `samples-map.yaml` は ASCII のみ含むが、 PMDNEO 生成 yaml で comment に日本語 dash や日本語文字を含む可能性は十分あるため、 utf-8 出力が正解。

memory への記録: `feedback_record_unexpected_findings` 規律対象だが、 軽微 + 即修正 + verify PASS のため本 handoff doc 内記録のみで完結。

## β-2 着手前の整理

β-1 で確立した artifact:

- `assets/pne/PMDNEO01.PNE` (= canonical test asset)
- converter / pack tool (= round-trip verify PASS)
- verify script (= 4 gate gate)

β-2 (= build pipeline 接続) で扱う未対応事項:

1. `vendor/ngdevkit-examples/00-template/Makefile` 3 行改修 (= `$<` → `$^` + prerequisite 2 yaml 化)
2. `scripts/build-poc.sh` に `.PNE` → converter 実行 step 追加
3. `assets/pne/samples-map-adpcmb.yaml` 新規手書き (= ADPCM-B beat passthrough、 c1 採用根拠)
4. `vendor/ngdevkit-examples/00-template/assets/samples-map.yaml` の扱い (= 削除 or rename、 single yaml 経路は不要に)

β-3 (= ROM byte-identical verify) で扱う未対応事項:

1. 既存経路 ROM (= 現状 samples-map.yaml single yaml) と新経路 ROM (= .PNE → converter → multi-yaml) の byte-identical 確認
2. step 5 β-3 verify script 同等の register trace gate (= `@0/@1` sample addr 差分が新経路でも保持される)
3. step 6 silent-bcef fixture + MAME 試聴 (= audio gate regression なし)

## 関連 file

- ADR-0021 (= step 7 sprint 起票、 §決定 5 path B / c1 採用、 §決定 8 sub-sprint 構造)
- `docs/design/pne_binary_layout.md` v0.2 (= α-2、 §3-§5 layout / §6 path B / §12 I/O contract)
- `docs/design/handoff/adr-0016-step5-beta-1-sample-fixture-findings.md` (= step 5 β-1 fixture 流儀の参考)
- ADR-0016 (= 改造実装 sprint 作業計画)
