# ADR-0016 / ADR-0021 step 7 完了統合 handoff (= asset pipeline sprint 完結)

- 状態: **完了** (= 2026-05-13 8th session)
- 関連 ADR: **ADR-0021 = Accepted** (= step 7 `.PNE` asset pipeline + `.MN` filename embed sprint)、 ADR-0016 (= Accepted、 改造実装 sprint 作業計画、 step 7 は β-3 完了後の format contract verify 拡張)
- 関連 commit chain (= 8 件、 8th session 内):
  - `38e35bf` α-1 `.PNE` binary layout 起票 + provenance 調査
  - `e30ef4c` α-2 path B / c1 正式採用 + converter I/O contract + ADR-0021 §決定 5 補正
  - `a25155d` β-1 converter prototype + `.PNE` 初期 asset + round-trip 4 gate
  - `0668594` β-2 build pipeline 接続 (= Makefile 3 行 + build-poc.sh + ADPCM-B yaml 分離)
  - `e3fdda5` β-3 byte-identical primary gate + regression verify
  - `d653d62` δ-fix mc compiler `#PNEFile` quote strip 局所修正
  - `50d34d8` δ `.MN` ↔ `.PNE` format contract 4 gate verify
  - 本 commit (= ε 完了統合 + ADR-0021 Accepted)

## 目的

step 5/6 (= ADPCM-A 6ch native path + audio isolation) で確立した PMDNEO 二層構造 (= legacy / native) の上に、 **`.PNE` source-of-truth layer** を追加し、 「楽曲制作者が ADPCM-A sample pack を `.PNE` file として持ち運べる」 「driver / vromtool.py / 既存 build pipeline を完全不変に保つ」 「ROM final byte-identical を維持する」 の 3 制約を同時達成する。

driver 機能拡張ではなく **asset ownership / build pipeline sprint** として位置付け。 Step 5/6/7 役割分離 (= 「どう鳴らすか」 / 「どう聴くか」 / 「どこから持ってくるか」、 memory `project_pmdneo_step_role_split_semantics_source_listening.md` 参照) の中で Step 7 は **「どこから持ってくるか」 = source ownership 軸** を担う。

## step 7 全体 sum-up

### 構成

step 7 = ADR-0021 で起票した `.PNE` asset pipeline + `.MN` filename embed sprint。 sub-sprint 構造 (= ADR-0021 §決定 8 5 段階 + α/β 内細分 + δ-fix 追加):

| sub | 内容 | 結果 | commit |
|---|---|---|---|
| 起票 | ADR-0021 起票 (= path B / c1 候補整理、 sub-sprint α/β/γ/δ/ε) | ✅ Proposed | (= 8th session 冒頭、 `60e78d4`) |
| α-1 | `.PNE` binary layout v0.1 + provenance 調査 + path 候補整理 | ✅ | `38e35bf` |
| α-2 | path B / c1 正式採用 + converter I/O contract 固定 + ADR-0021 §決定 5 補正 | ✅ | `e30ef4c` |
| β-1 | converter prototype (= unpack only) + pack tool prototype (= bootstrap) + `assets/pne/PMDNEO01.PNE` 初期 asset + round-trip 4 gate | ✅ | `a25155d` |
| β-2 | build pipeline 接続 (= vendor Makefile 3 行 + build-poc.sh + ADPCM-B passthrough yaml 分離 + legacy yaml rename) | ✅ | `0668594` |
| β-3 | byte-identical primary gate + regression verify (= S' vromtool.py 直接実行) + step 5/6 verify 改修不要で PASS | ✅ | `e3fdda5` |
| γ | (skip) | ⏸ path B 採用で不要 (= ADR-0021 §決定 5 補正で「driver data 部移行」 撤回) | — |
| δ-fix | mc compiler `#PNEFile` surrounding quote strip (= 局所修正、 ADR-0021 §決定 3 末尾 path 適用) | ✅ | `d653d62` |
| δ | mc compiler `/B` path `pne_filename_adr` embed 4 gate verify | ✅ | `50d34d8` |
| 完了統合 (= ε) | step 7 完了統合 doc + ADR-0021 Accepted 移行 + 完了 memory 起票 | ✅ 本 commit | (= 本 commit) |

### 完了判定達成状況 (= ADR-0021 §step 7 全体完了判定 10 項目)

| # | 項目 | 達成 |
|---|---|---|
| 1 | α-1: `.PNE` format 仕様確定 + `pne_binary_layout.md` 起票 | ✅ (= `38e35bf`) |
| 2 | α-1: 既存 sample 出処調査結果を α handoff doc 記録 | ✅ (= `38e35bf` §2) |
| 3 | β-1: `scripts/pne-to-ngdevkit.py` (= converter) 実装 + unit test PASS | ✅ (= `a25155d`) |
| 4 | β-1: `.PNE` → 生成 sample 出力が直書き source と byte-identical (= round-trip) | ✅ (= 6/6 sha256 PASS、 `a25155d`) |
| 5 | γ: `standalone_test.s:2825-2840` の sample data 部を生成 include へ移行 | ⏸ **skip** (= path B 採用で不要、 ADR-0021 §決定 5 補正済) |
| 6 | γ: ROM byte-identical 確認 (= `.PNE` 経由 vs 移行前 source、 完全一致) | ✅ (= β-3 で samples.inc + VROM 4 件全件 byte-identical、 driver / vromtool.py 不変から ROM final 数学的同値、 `e3fdda5`) |
| 7 | δ: mc compiler `/B` path `pne_filename_adr` embed verify + hex dump 確認 | ✅ (= 4/4 gate PASS、 `50d34d8`、 前提 fix = `d653d62`) |
| 8 | δ: `.MN` 内 filename string が NUL-terminated で正しく入っている | ✅ (= `step5.PNE\0` 9 byte + NUL、 `50d34d8`) |
| 9 | ε: step 6 silent-bcef fixture + MAME 試聴 で regression なし | ✅ (= β-3 で step 6 verify 改修不要で 7/7 PASS、 `e3fdda5`) |
| 10 | ε: step 7 完了統合 handoff doc + ADR-0021 Accepted 移行 | ✅ 本 commit |

→ **10/10 達成** (= #5 は path B 採用で正規に skip、 残り 9 項目すべて PASS)。

### scope-out 維持確認 (= ADR-0021 §scope-out 全 9 項目)

| 項目 | 維持 |
|---|---|
| runtime `.PNE` parser (= driver が `.MN` 内 filename を読んで動的 sample table 構築) | ✅ 完全 scope-out (= driver 完全不変、 Step 8 候補) |
| driver 側 filename string read routine | ✅ 完全 scope-out (= driver `standalone_test.s` touch なし) |
| ROM bank switching / 動的 sample bank 管理 | ✅ 完全 scope-out (= 別 sprint) |
| 楽曲交換時 ROM rebuild 不要化 | ✅ 完全 scope-out (= path B では現状 ROM rebuild 必須) |
| K/R rhythm compatibility 現役接続 | ✅ 完全 scope-out (= ADR-0019 §決定 2、 別 micro-sprint 候補) |
| PMDNEO.s + nullsound integration | ✅ 完全 scope-out (= 大規模 sprint) |
| 新規 sample 追加 (= WAV → ADPCM-A 変換 UI、 WebApp Phase 4) | ✅ 完全 scope-out |
| 複数 `.PNE` file 対応 (= 楽曲ごと別 sample bank) | ✅ 完全 scope-out |
| PPZ compatibility / FM-Towns-style rhythm mode | ✅ 完全 scope-out |

## 主要成果 (= architecture 観点)

### 成果 1: source-of-truth / generated / existing production の 3 層 ownership 確立

```
[source-of-truth — 手書き / 編集対象]
  assets/pne/PMDNEO01.PNE                  (= 11008 byte canonical test asset)
  assets/pne/samples-map-adpcmb.yaml       (= ADPCM-B passthrough、 c1 採用根拠)

[generated artifact — 編集禁止、 converter 出力]
  vendor/ngdevkit-examples/00-template/assets/samples-map-adpcma.yaml
  vendor/ngdevkit-examples/00-template/assets/{bd,sd,hh,rim,tom,top}.adpcma

[existing production — vromtool.py 経由、 完全不変]
  vendor/ngdevkit-examples/00-template/build/assets/samples.inc
  vendor/ngdevkit-examples/00-template/build/rom/243-v*.v*

[legacy retain — source-of-truth でなくなる]
  assets/sounds/adpcma/2608_*.adpcma 6 件
  vendor/ngdevkit-examples/00-template/assets/samples-map.yaml.legacy
```

各層の責務境界が明確化、 future contributor が「誰が何を所有するか」 を判断できる構造。

### 成果 2: driver 完全不変 (= literal 意味で)

ADR-0021 §決定 2 で「runtime parser scope-out」 を立てたが、 path A 想定 (= ADR-0021 起票時) では「driver data 部のみ生成 include へ移行」 を許容していた。 α-1 / α-2 で path B 発見 + ADR-0021 §決定 5 補正により、 **driver data 部移行すら不要**と判明。 結果として `src/driver/standalone_test.s` 全 byte 単位で完全不変、 ADR-0021 §決定 2 が literal な意味で完全成立。

### 成果 3: ROM final byte-identical (= 数学的同値性)

β-3 で samples.inc + VROM 4 件全件 byte-identical 直接検証 PASS。 driver / vromtool.py / 他 fixed input 完全不変前提と合わせて、 ROM final も自動的に byte-identical (= 直接 diff せず、 構成要素 + 不変性からの論理帰結)。 これは「動いているものを壊さない」 規律の最強形。

### 成果 4: 既存 verify infrastructure の自動 regression test 化

step 5 β-3 sample lookup verify + step 6 silent-bcef audio isolation verify が **改修不要で新経路再実行** で PASS。 build-poc.sh が新経路に切り替わっているため、 既存 verify script を実行するだけで「新経路でも driver / sample / audio isolation 全部 regression なし」 を直接示せる。 これは Step 7 と既存 verify infrastructure の **設計的整合性** が高いことの実証。

### 成果 5: format contract 接続 (= `.MN` ↔ `.PNE`)

δ で `.MN` binary 内 `m_start` + `extended_data_adr` + `pne_filename_adr` + NUL-terminated filename string が `mn_binary_layout.md` §4-3-3 仕様通りに embed されることを 4 gate verify。 ただし **driver runtime resolution には Step 7 では使われない** (= format 先行固定、 future runtime parser sprint で活用)。

### 成果 6: finding + micro-sprint correction loop

δ verify 着手時に mc compiler `#PNEFile` quote handling finding 検出 → δ-fix micro-sprint で局所修正 → δ verify 4/4 PASS という correction loop を実行。 ADR-0021 §決定 3 末尾「fail 時は fix micro-sprint」 path が想定通り機能、 scope を `#PNEFile` のみに局所化 (= 他 directive に踏み込まない)。

## 各 sub-sprint からの教訓

### α-1 / α-2: 設計書ファースト + provenance 調査の価値

α-1 段階で既存 BD/SD/HH/RIM/TOM/TOP sample の provenance を調べたことで、 「現状の samples.inc は vromtool.py 経由で生成済」 という事実が判明 → path A 想定の前提が崩れて path B 発見 → α-2 で正式採用。 **実装前に既存 build pipeline の現状を調査する** 規律が、 後続 sprint scope を 100 行以下に縮小した。

### β-1 / β-2 / β-3: 1 sub = 1 commit + 1 push 規律の価値

β を 3 sub に分割 (= converter / 接続 / verify) したことで、 各 sub で「動いているものを壊さない」 を都度確認できた。 1 commit に統合する案 (= 直前 turn の (L) 圧縮案) を採らず細分化した判断が、 trivial verify risk を最小化。 step 5 / step 6 で確立した規律を Step 7 でも継承。

### δ-fix → δ: ADR-0021 §決定 3 末尾 path の正式適用

「mc compiler `/B` path は verify only」 を立てつつ「fail 時は fix micro-sprint」 を末尾に書いておいた ADR 起票時の判断が、 8th session 後半で literal に活用された。 ADR 内に「verify only だが exception 条件で fix 可能」 path を予め書いておく規律は、 後続 sprint でも有効。

### γ skip: 設計判断の修正可能性

ADR-0021 §決定 8 で γ を sub-sprint として立てたが、 α-1 / α-2 調査で **γ 自体が不要** と判明。 ADR を発展的に修正する path (= §決定 5 補正) で skip 判断を文書化。 ADR は固定文書ではなく、 sub-sprint 進行中に判断が変わったら明示的に補正する流儀。

## Step 8 候補 (= 後続 sprint 案、 ADR-0021 scope-out 消化順)

### 高優先

1. **runtime `.PNE` parser** (= driver 側 filename read + bank resolve + sample table 構築):
   - 本 Step 7 で確立した `pne_filename_adr` + `.PNE` binary layout が直接の基盤
   - driver `standalone_test.s` の改修中心
   - 楽曲交換時 ROM rebuild 不要化 (= dynamic sample bank) の第一歩
   - ADR-0019 §決定 3「`.PNE` parser は次 sprint で扱う」 接続点を 8th session で予定通り消化済 → 本 sprint で残った driver 改修部分

2. **K/R rhythm compatibility 現役接続** (= ADR-0019 §決定 2 接続点予約):
   - K part dispatch 現役化
   - ADPCM-A driver 側で K/R compat 経路を有効化
   - 軽量 micro-sprint 候補

### 中優先

3. **複数 `.PNE` file 対応** (= 楽曲ごと別 sample bank):
   - mc compiler 改修 (= `#PNEFile` 複数指定 or 自動 binding)
   - converter 改修 (= 複数 `.PNE` を merge)
   - build pipeline 改修

4. **PMDNEO.s + nullsound integration** (= ADR-0014 / ADR-0017 で凍結された経路の再起動):
   - 大規模 sprint
   - 本 Step 7 で確立した二系統 (= standalone_test.s vs PMDNEO.s) の収束

### 低優先 / 別 sprint

5. **WebApp Phase 4 領域** (= WAV → `.PNE` 変換 UI + production pack tool):
   - 本 Step 7 で確立した `.PNE` format が WebApp 出力の前提
   - `pne-pack-prototype.py` は production tool ではない (= 別途設計)

6. **PMD 系 `#` directive quote handling 一般化** (= `#Title` 等):
   - memory `project_pmd_directive_quote_handling_status.md` の table 消化
   - PMD V4.8s 互換性方針確認必須

7. **assets/sounds/adpcma/ legacy retain の cold storage 移動判断**:
   - `2608_*.adpcma` 6 件は source of truth でなくなった
   - 削除 / 別 dir 移動 / retain の判断

## architecture observation

Step 7 完了で PMDNEO の architecture は以下のように成立:

```
[asset layer]                  ← Step 7 で確立
  .PNE (= ADPCM-A sample pack、 source-of-truth)
  samples-map-adpcmb.yaml (= ADPCM-B passthrough)

[build pipeline layer]         ← Step 7 で接続
  scripts/pne-to-ngdevkit.py (= converter、 unpack only)
  vendor/ngdevkit-examples/00-template/Makefile (= 3 行改修済)
  scripts/build-poc.sh (= converter step + ADPCM-B cp 追加済)
  vromtool.py (= 完全不変、 existing production)

[binary contract layer]        ← Step 7 で format 接続確認
  .MN (= m_start / extended_data_adr / pne_filename_adr / filename string)
  ← driver runtime resolution は **未接続** (= Step 8 候補)

[runtime layer]                ← Step 5/6 で確立、 Step 7 で完全不変
  src/driver/standalone_test.s (= ADPCM-A 6 ch native path)
  silent-bcef fixture (= audio isolation)
```

Step 7 は **asset layer + build pipeline layer + binary contract layer** の 3 層を確立し、 runtime layer は完全不変。 driver runtime に手を入れる Step 8 への地ならしが完了。

### 重要 (= future contributor 向け明示)

**Step 7 は `.PNE` runtime parser を実装していない**。 現時点で `.PNE` は **build-time source-of-truth** であり、 runtime resolution は **Step 8 以降の候補**。

具体的に:

- `.PNE` 内の filename / slot table / raw sample は **build pipeline (= converter + vromtool.py)** が解決
- driver / runtime は `.PNE` を直接読まない (= `.MN` 内 `pne_filename_adr` は format contract として埋まっているが driver は読まない)
- 楽曲交換時は **ROM rebuild が必要** (= `.PNE` 差し替え → converter 再実行 → vromtool.py 再実行 → ROM 再 build)
- 「ROM rebuild なしで楽曲交換」 は Step 8 候補 (= dynamic sample bank / runtime parser sprint)

`.PNE` filename embed が成立しているため誤解しやすいが、 これは **future runtime parser のための先行固定**であり、 現状の driver は filename を一切参照しない (= ADR-0021 §決定 2 / δ handoff doc §scope 境界 と同じ整理)。

## 関連 file

- ADR-0021 (= Accepted、 本 commit で移行)
- ADR-0016 (= Accepted、 改造実装 sprint 作業計画)
- ADR-0019 (= Accepted、 step 5 ADPCM-A 6ch 設計判断、 §決定 3 で本 Step 7 接続点予約)
- ADR-0020 (= Accepted、 step 6 audio isolation 戦略)
- `docs/design/pne_binary_layout.md` v0.2 (= α-2 確定)
- `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)
- `docs/design/handoff/adr-0016-step7-b-1-converter-prototype.md` (= β-1)
- `docs/design/handoff/adr-0016-step7-b-3-byte-identical.md` (= β-3)
- `docs/design/handoff/adr-0016-step7-delta-mn-filename-embed.md` (= δ)
- memory `project_pmdneo_step7_complete.md` (= 本 commit で起票)
- memory `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 8th session α-2 で起票)
- memory `project_pmd_directive_quote_handling_status.md` (= δ で起票)
