# ADR-0016 step 7 β-3 finding handoff: path B / c1 byte-identical + regression verify

- 起票日: 2026-05-13 (= 8th session β-3)
- 起票者: Claude Code
- 関連: ADR-0021 §決定 5 (= path B / c1 正式採用)、 §決定 7 (= primary gate / audio gate 役割分離)
- 関連 commit: α-1 `38e35bf` / α-2 `e30ef4c` / β-1 `a25155d` / β-2 `0668594`

## 概要

**β-3 は primary gate 証明 commit**。 path B / c1 採用後の新経路 build artifact (= samples.inc + VROM) が既存経路と **完全に byte-identical** であることを直接証明 + 既存 step 5/6 verify を新経路で再実行して regression なしを確認。

driver source / vromtool.py 完全不変前提 (= β-2 で確立) と合わせて、 ROM final (= 243-m1.m1) も自動的に byte-identical (= 数学的同値性) が成立。

### 重要な境界 (= future contributor 向け明示)

**本 β-3 で直接 diff したのは samples.inc + VROM 4 件のみ**。 ROM final (= 243-m1.m1 / cart zip) の **byte-by-byte 直接比較は行っていない**。 ROM final byte-identical は以下の **論理帰結 / 数学的同値性** として成立すると主張する:

```
[β-3 で直接証明]
    samples.inc byte-identical ✓
    VROM 4 件 byte-identical ✓
+
[β-2 / 既存規律で保証]
    driver source 完全不変 (= ADR-0021 §決定 5 補正、 path B 採用)
    vromtool.py 完全不変 (= ngdevkit native、 ADR-0021 §決定 3)
    他 fixed input (= sprite ROM, prom ROM, cart 周辺) touch なし
=
[論理帰結]
    ROM final も byte-identical (= 直接 diff せず、 構成要素 + 不変性から導出)
```

ROM zip そのものを直接比較していない点に注意。 直接 diff を必須にしたい場合は別 sprint で扱う (= 本 verify は構成要素レベルで gate として十分強いという判断)。

## 検証戦略 (= (S') 採用、 (S) より安全な variant)

### 原案 (S) の問題

8th session β-3 着手前の壁打ちで提示した (S) (= verify script 内で Makefile + samples-map.yaml を temp revert で legacy 経路再現) は **trap restore に頼る流儀** で、 失敗時に Makefile が legacy 形に残る事故 risk あり。

### (S') 採用

vromtool.py を 2 種の入力で **temp dir に直接出力** + 出力 artifact を sha256 比較:

```bash
# legacy: 単一 yaml 入力
vromtool.py --asm -s 4194304 samples-map.yaml.legacy -o legacy.v1 -m legacy.inc
vromtool.py --roms -s 4194304 samples-map.yaml.legacy -o legacy.vX -n 4

# 新経路: 2 yaml 入力
vromtool.py --asm -s 4194304 samples-map-adpcma.yaml samples-map-adpcmb.yaml -o new.v1 -m new.inc
vromtool.py --roms -s 4194304 samples-map-adpcma.yaml samples-map-adpcmb.yaml -o new.vX -n 4

# diff
shasum -a 256 legacy.inc new.inc
shasum -a 256 legacy.v* new.v*
```

利点:
- Makefile / build-poc.sh / 既存 build artifact は touch しない (= temp restore 不要)
- vromtool.py 出力が同一なら、 build pipeline (= vromtool.py から下流の assembler / linker / ROM final) も同一 (= driver / 他 input 不変前提)
- verify script の trap restore 機構不要、 事故 risk 最小

### ROM final byte-identical 数学的成立根拠

ROM final = driver source + samples.inc + VROM + 他 fixed input (= sprite ROM, prom ROM 等)

β-2 / β-3 で:
- driver source = 完全不変 (= path B 採用、 ADR-0021 §決定 5 補正)
- 他 fixed input (= sprite / prom 等) = touch なし
- samples.inc + VROM = **本 β-3 で byte-identical 証明**

したがって ROM final も自動的に byte-identical。 改めて ROM final を build して比較する必要なし。

## 検証結果

### β-3 primary gate (= byte-identical verify、 4/4 PASS)

```
$ bash src/test-fixtures/step7/verify-step7-b3-byte-identical.sh

=== step 7 β-3: path B / c1 ROM byte-identical verify ===

--- gate 1: legacy 経路 (= 単一 samples-map.yaml.legacy) で vromtool.py 実行 ---
  [PASS] gate 1: legacy artifact 生成成功 (= samples.inc + VROM 4 件)
--- gate 2: 新経路 (= 2 yaml 渡し) で vromtool.py 実行 ---
  [PASS] gate 2: 新経路 artifact 生成成功 (= samples.inc + VROM 4 件)
--- gate 3: samples.inc byte-identical (= legacy vs 新) ---
  [PASS] samples.inc: 74f2aec8f8859e062dd835470813788d889288d17c6716a5a46c2ddac0393ae4
--- gate 4: VROM 4 件 byte-identical (= 243-v1.v1 ... 243-v4.v4) ---
  [PASS] VROM 1 (4194304 byte): c77f0888949aae30a1c67109a067dc0c08b915519de2593fbb128148ad6bc060
  [PASS] VROM 2 (4194304 byte): bb9f8df61474d25e71fa00722318cd387396ca1736605e1248821cc0de3d3af8
  [PASS] VROM 3 (4194304 byte): bb9f8df61474d25e71fa00722318cd387396ca1736605e1248821cc0de3d3af8
  [PASS] VROM 4 (4194304 byte): bb9f8df61474d25e71fa00722318cd387396ca1736605e1248821cc0de3d3af8

=== step 7 β-3 byte-identical verify PASS (= 4/4 gate PASS) ===
```

samples.inc byte-identical = `74f2aec8...` (= legacy / 新 完全一致)
VROM 1 = `c77f0888...`、 VROM 2/3/4 = `bb9f8df6...` (= 各 4 件 完全一致、 2/3/4 は空 VROM で同 hash)

### step 5 β-3 sample lookup regression verify (= 新経路で PASS)

```
$ bash src/test-fixtures/step5/verify-l-part-beta-sample-lookup.sh

🎉 ADR-0016 step 5 β-2 sample lookup verify PASS
   - gate 1: sample A build + trace ✅
   - gate 2: sample B build + trace ✅
   - gate 3: PART_OFF_INSTRUMENT 差分 (= 0x00 vs 0x01)
   - gate 4: reg 0x10 start LSB 差分 (= 0x00 vs 0x04)
   - gate 5: reg 0x20 stop LSB 差分 (= 0x03 vs 0x06)
   - gate 6: reg 0x18/0x28/0x08/0x00 同一性 ✅
```

意味: 新経路で sample A (= @0 = bd、 start 0x00 / stop 0x03) と sample B (= @1 = sd、 start 0x04 / stop 0x06) の register write 差分が正しく反映されている。 driver / sample lookup chain は完全に regression なし。

### step 6 silent-bcef audio isolation verify (= 新経路で PASS)

```
$ bash src/test-fixtures/step6/verify-silent-bcef-audio-isolation.sh

🎉 ADR-0020 step 6-a verify PASS
   - gate 1: silent-bcef + l-q-rhythm-song build + trace ✅
   - gate F: FM keyon (= reg 0x28) = 0 件 (= audio isolation 成立) ✅
   - gate 2: workarea independence ✅
   - gate 3: ch overlap (= 6 ch sample addr 全 unique) ✅
   - gate 4: volume/pan (= 6 ch v cmd 由来 reg 0x08+ch) ✅
   - gate 5: simultaneous + rhythm keyon (= 39 件) ✅
   - gate 6: register isolation (= 5 reg group × 6 ch) ✅
```

意味: 新経路でも step 6 で確立した audio isolation + ADPCM-A 6 ch 全 register write + sample addr unique が全て regression なし。

### 重要な finding: 既存 step 5/6 verify が自動 regression test として機能

β-2 で `bash scripts/build-poc.sh` が新経路 (= path B / c1) に切り替わっているため、 既存 step 5 β-3 / step 6 silent-bcef verify script は **何も改修せずに新経路で再実行できる**。 PASS した結果は「新経路でも driver / sample / audio isolation 全部 regression なし」 を直接示す。

これは β-2 で確立した「driver / build pipeline 経路の不変保証」 と path B / c1 採用の整合性が、 既存 verify script で **自動的に検証される** 強い regression test 設計になっている。

## ADR-0021 §決定 7 (= primary gate / audio gate 役割分離) 整合性

| gate 軸 | β-3 結果 | ADR-0021 §決定 7 整合 |
|---|---|---|
| primary gate (= ROM byte-identical) | ✅ samples.inc + VROM 4 件 byte-identical | ✅ 完全整合 |
| register trace (= step 5 β-3) | ✅ 6 gate PASS、 sample addr 差分 + 同一性 | ✅ 完全整合 |
| audio gate (= step 6 silent-bcef) | ✅ 7 gate PASS、 audio isolation 成立 | ✅ 完全整合 |
| human listening (= MAME 試聴 reference) | β-2 build success + 既存 step 6 試聴経路 retain | (β-3 では人間試聴 trigger なし、 必要なら `bash scripts/run-mame.sh` で確認可能) |

`feedback_refactor_gate_register_trace_not_wav` 規律 (= primary gate = register trace + byte-identical) と完全整合。

## human listening 確認 (= 別軸、 任意)

verify script は自動 PASS 判定で完結 (= human listening を gate に含めない)。 任意確認手順 (= step 6 完了 commit `a168896` で確立):

```bash
# 既存 step 6 audio gate と同等経路 (= silent-bcef fixture + l-q-rhythm-song)
MML_INPUTS=silent-bcef.mml PMDDOTNET_MML=src/test-fixtures/step5/l-q-rhythm-song.mml \
    PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh

# MAME 起動 (= 試聴 reference、 ADPCM-A L-Q 6 音 audible)
cd vendor/ngdevkit-examples/00-template && make gngeo
```

期待動作: FM 音なし + ADPCM-A L-Q 6 音シーケンス。 path B / c1 採用後も step 6 完了時と同じ audio reference。

## step 7 全体進捗 (= β 段階完了)

| sub-sprint | commit | 状態 | 主要成果 |
|---|---|---|---|
| α-1 | `38e35bf` | ✅ 完了 | `.PNE` binary layout 起票 + provenance 調査 |
| α-2 | `e30ef4c` | ✅ 完了 | path B / c1 正式採用 + converter I/O contract + ADR-0021 §決定 5 補正 |
| β-1 | `a25155d` | ✅ 完了 | converter prototype + `.PNE` 初期 asset + round-trip 4 gate |
| β-2 | `0668594` | ✅ 完了 | build pipeline 接続 (= Makefile 3 行 + build-poc.sh + ADPCM-B yaml 分離) |
| β-3 | 本 commit | ✅ 完了 | byte-identical + regression verify、 path B / c1 数学的同値性証明 |
| γ | (skip) | — | path B 採用で不要 (= driver data 部移行も発生せず、 ADR-0021 §決定 5 補正で撤回) |
| δ | 次 sprint | 未着手 | mc compiler `/B` path の `pne_filename_adr` embed verify (= 既存実装の hex dump 確認) |
| ε | 次 sprint | 未着手 | step 7 完了統合 + ADR-0021 Accepted 移行 |

## β-3 改修対象

| 件 | file | 種別 | 行数 |
|---|---|---|---|
| 1 | `src/test-fixtures/step7/verify-step7-b3-byte-identical.sh` | 新規 (= 4 gate primary verify) | 121 |
| 2 | 本 handoff doc | 新規 | (本 file) |

**触らなかったもの**: driver source / vendor Makefile / build-poc.sh / vromtool.py / 既存 yaml 群 / 既存 sample asset。 完全に検証のみ commit。

## δ / ε 着手前の整理

δ で扱う未対応事項:
- mc compiler `/B` path の `#PNEFile` 受け取り + `pne_filename_adr` embed の verify
- 改造 PMDDotNET で `.MN` 出力時の hex dump 確認
- 既に実装済 (= ADR-0016 step 1 commit `45eebaf` 遺産、 mc.cs:1491-1565) なので verify only

ε で扱う未対応事項:
- step 7 完了統合 handoff doc
- ADR-0021 Proposed → Accepted 移行
- 関連 memory 更新 (= `project_pmdneo_step7_complete.md` 起票候補)

## 関連 file

- ADR-0021 (= step 7 sprint 起票 + §決定 5 path B / c1 + §決定 8 sub-sprint 構造)
- `docs/design/pne_binary_layout.md` v0.2 (= α-2、 §6 path B / §12 converter I/O contract)
- `docs/design/handoff/adr-0016-step7-b-1-converter-prototype.md` (= β-1 finding)
- `src/test-fixtures/step5/verify-l-part-beta-sample-lookup.sh` (= step 5 β-3 regression test、 新経路でも PASS)
- `src/test-fixtures/step6/verify-silent-bcef-audio-isolation.sh` (= step 6 audio isolation、 新経路でも PASS)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate 規律、 整合確認済)
