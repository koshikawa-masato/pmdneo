# ADR-0036: FM/SSG 軸を ADPCM-A 軸と並走する方針 — source 触接面 / verify infra / branch 境界 / IR 接続の設計固定

- 状態: **Draft** (= 2026-05-18 26th session、 ADR-0035 Draft 継続 session で新規起票。 driver 実装なし、 docs-only ADR。 Accepted 移行は FM/SSG Step 1 着手前の user 最終確認時)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR: ADR-0001 (= YM2610 無印では Part A/D 不使用、 driver は 6ch 実装)、 ADR-0013 (= 同 `.M` 2 経路比較へ切替)、 ADR-0014 (= `standalone_test.s` 本線 / `PMDNEO.s` legacy 境界)、 ADR-0015 (= PMDDotNET 改造技術調査)、 ADR-0016 (= Step sprint plan)、 ADR-0017 (= develop driver snapshot、 FM/SSG 実装履歴)、 ADR-0019 (= ADPCM-A Step 5 設計判断)、 ADR-0020 (= audio isolation 戦略)、 ADR-0021-0033 (= ADPCM-A / K/R rhythm / sample provenance 軸)、 ADR-0034 (= IR 3 層 hybrid)、 ADR-0035 (= IR ChipEvent → RawRegisterWrite lowering)
- 入力資料: `docs/design/handoff/fm-ssg-parallel-axis-talking-points.md` (= 26th session 起票、 既存制約 11 件 + 開く論点 7 件 + 接続 ADR table)

## 背景

PMDNEO は ADR-0016 で Phase 2 完了を Step 5 完了と定義したが、 実際に Step 5-18 で進んだ主軸は ADPCM-A / `.PNE` / K/R rhythm であり、 FM/SSG の本線 driver proof は別軸として残っている。 ADR-0017 には develop driver 側で FM/SSG が進んだ履歴が記録されている一方、 ADR-0014 補正後の本線は `src/driver/standalone_test.s` であり、 legacy / develop 資産をそのまま本線完了扱いにはできない。

26th session で user 判断として「FM/SSG 軸を後回しにせず ADPCM-A 軸と同時並行で進める」方針が確定した。 並走可能性は、 source 触接面、 branch 境界、 verify infra 共有範囲、 audio gate solo isolation、 IR 軸 ADR-0035 との接続点を先に固定できるかに依存する。

本 ADR は driver 実装に入らず、 FM/SSG 軸の並走方針を ADR layer で固定する。 実装 commit は別 sprint / 別 branch で行う。

## 決定

### 決定 1: source 触接面は独立 inc file 主体 + 最小 hook で分離する

FM/SSG 実装は `standalone_test.s` に大きく直書きせず、 将来の実装では FM / SSG の routine を独立 inc file 主体に分離する。 `standalone_test.s` 側の変更は include、初期化呼び出し、part dispatch hook、trace fixture 接続などの最小触接面に限定する。

選択肢:

- **A. 同一 file 内 routine 分離**: ADR-0016 / ADR-0019 以降の Step pattern と近い。 ただし ADPCM-A 軸も同じ `standalone_test.s` を編集するため、 並走時に同 file conflict が増える。
- **B. 独立 inc file 化 + 最小 hook**: FM / SSG の register routine と state を物理的に分けられる。 hook 行だけは本線 file に必要だが、 競合面を小さくできる。
- **C. 別 branch だけで分離し、 file 境界は決めない**: 初動は速いが、 merge 時に判断が後ろ倒しになる。

**採用: B**。 FM/SSG 軸の source 所有範囲は、 将来候補として `FM_DRV.inc` / `SSG_DRV.inc` 相当の独立 file とし、 ADPCM-A 軸の `.PNE` / L-Q / K/R routine とは file ownership を分ける。 既存 file 名は実装時に現物に合わせて決めるが、 方針は「大きな driver 本線 file へ直書きしない」で固定する。

### 決定 2: verify infra は既存 scripts を再利用し、期待値 fixture は軸別に分ける

FM/SSG 軸の verify infra は、 既存の build / MAME / trace / audio gate scripts を可能な範囲で再利用する。 ただし期待 register trace、mute fixture、audio audition log は ADPCM-A 軸と混ぜず、 FM/SSG 軸専用に分ける。

選択肢:

- **A. 既存 scripts をそのまま全面共有**: tool 重複は避けられるが、 ADPCM-A 同居音や fixture 名の混線が起きやすい。
- **B. runner は共有、 expected fixture と mute fixture は軸別**: build / MAME / trace capture の再利用性を保ちつつ、 判定対象を分けられる。
- **C. FM/SSG 専用 verify script を全部新設**: 独立性は最大だが、 同じ MAME / trace 起動処理を重複実装する。

**採用: B**。 `scripts/build-poc.sh`、MAME 起動経路、ymfm register trace capture、`scripts/audio-gate.sh` のような runner は共有候補とする。 一方で expected trace は `fm-ssg` 系 fixture として分け、 ADPCM-A / rhythm sample provenance の fixture と同じ file に混ぜない。 audio gate は FM/SSG 対象 part を solo 化し、 聴感判定は **user gate 必要**として機械判断から除外する。

### 決定 3: FM/SSG Step 1 は Part B の FM 単音 raw trace proof にする

FM/SSG 軸の最小 proof は、 Part B (= YM2610 無印で発音する chip ch 2) の FM 単音で、 Tone load → Frequency → KeyOn → KeyOff の ymfm register trace を観測する Step とする。 Part A / D は ADR-0001 により楽曲側不使用であり、 最初の audible proof には使わない。

選択肢:

- **A. FM ch1 / Part A 単音**: register write は最小だが、 YM2610 無印では無音 channel であり audio gate に不向き。
- **B. Part B / chip ch 2 単音**: ADR-0001 と整合し、 register trace と audio gate の両方に使える。
- **C. FM 4 ch または 6 ch 同時 proof**: 実用範囲に近いが、 Step 1 としては原因切り分けが難しい。

**採用: B**。 Step 1 の機械 gate は register trace を主とし、 期待 register 列は ADR-0035 の RawRegisterWrite 仕様を oracle として参照する。 audio gate は solo fixture で実施し、 聴感 OK は user gate 必要。

### 決定 4: PMDDotNET Z80 化遺産は read-only reference とし、本線二重化はしない

ADR-0017 に記録された develop driver 資産は read-only reference として扱う。 FM/SSG 軸の完了判定は、 現在の本線 driver / target branch 上の trace と fixture で行い、 legacy path を二重 runtime として復活させない。

選択肢:

- **A. 遺産無視 + 本線で新規実装**: 二重化は避けられるが、 既に分かっている FM/SSG register routine の知見を捨てる。
- **B. 遺産を read-only reference とし、必要な小片だけ本線方針に合わせて再実装する**: 知見を活用しつつ、 runtime path は一本に保てる。
- **C. 遺産を別 file で活用し、本線から call する**: 初期移植は速いが、 legacy / current の二系統問題を意図的に増やす。

**採用: B**。 `PMD_Z80.inc` / `REGMAP.inc` / `WORKAREA.inc` 等の既存知見は確認対象にするが、 「develop で過去に鳴った」ことを FM/SSG Step 完了とはみなさない。 future commit では移植範囲を小さくし、 trace で本線到達を証明する。

### 決定 5: Step 粒度は FM 先行、SSG は次段階で独立 proof にする

FM/SSG 軸は一括実装しない。 FM と SSG を同じ ADR 軸に置くが、 Step は分ける。

選択肢:

- **A. FM/SSG 一括 proof**: Phase 2 の残りを一気に閉じられるが、 trace / audio / source conflict の原因切り分けが難しい。
- **B. FM Part B 単音 → FM 4 audible part → SSG G 単音 → SSG H/I / noise / envelope の順に分ける**: Step 数は増えるが、 ADPCM-A Step 12-17 の「1 軸 1 proof」流儀に合う。
- **C. SSG 先行**: SSG は register が単純で初動が軽いが、 ADR-0035 の FM RawRegisterWrite 仕様との接続 proof が遅れる。

**採用: B**。 Step 1 は FM Part B 単音。 後続候補は、 FM B/C/E/F audible 4 part、 FM volume / pan / tone parameter regression、 SSG G 単音、 SSG H/I、 SSG noise / envelope、 FM3Mode の順で別 sprint 化する。 FM3Mode は ADR-0034 §決定 4 の future event であり、 Step 1 に含めない。

### 決定 6: branch 戦略は FM/SSG 実装専用 `wip-` branch を切る

FM/SSG 実装は ADPCM-A 軸や IR 軸の実装 commit の上に直接 stack しない。 将来の driver 実装は、最新の合意済 base から `wip-fm-ssg-step1-keyon` 相当の専用 branch を切って進める。

選択肢:

- **A. 完全独立 `wip-` branch**: 並走軸の ownership が明確。 merge / rebase の判断は必要だが、 認知負荷が小さい。
- **B. ADPCM-A branch に stack**: runtime fixture を共有しやすいが、 ADPCM-A の未完差分に FM/SSG が依存しやすい。
- **C. IR branch に stack**: ADR-0035 との仕様接続は近いが、 IR は docs + script + fixture 軸であり driver 実装 branch と責務が違う。

**採用: A**。 本 ADR-0036 Draft 自体は ADR-0035 session で起票するが、 driver 実装は別 branch。 1 commit = 1 push、 commit 前の平易日本語 6 構造報告、 push 後の branch / 改修 / GitHub URL 報告を維持する。

### 決定 7: IR 軸とは並走し、ADR-0035 RawRegisterWrite を期待 trace 候補として接続する

FM/SSG 軸は ADR-0035 Accepted 完了を待って停止しない。 ただし FM register 仕様は ADR-0035 の §決定を重複定義せず、 RawRegisterWrite 出力を expected trace 候補として接続する。

選択肢:

- **A. ADR-0035 Accepted 後に FM/SSG 軸へ着手**: 仕様同期は強いが、 user が確定した並走方針と合わない。
- **B. 並走し、ADR-0035 の raw 出力を driver trace fixture の oracle として使う**: 並走速度と仕様整合の両方を取れる。
- **C. 完全独立に進める**: branch conflict は少ないが、 YM2610 register 仕様を二重管理する。

**採用: B**。 ADR-0035 は compiler / WebApp intermediate 側の register 仕様 oracle、 ADR-0036 は driver 並走方針の ADR として分ける。 driver trace が ADR-0035 raw 出力と異なる場合は、 どちらが正かを新 ADR または該当 Step ADR で literal に判定する。

## scope-out

- 本 ADR では driver 実装をしない。
- 本 ADR では `src/` / `scripts/` / `vendor/` を変更しない。
- 本 ADR では MAME 実行、audio gate、聴感 audition を実施しない。
- 本 ADR では ADR-0016 の Phase / Step 定義を全面改定しない。
- 本 ADR では `PMDNEO.s` legacy path を復活させない。
- 本 ADR では SSG / FM3Mode / ADPCM-B / K/R rhythm の詳細実装仕様を決め切らない。

## verify 方針

本 ADR は docs-only Draft であるため、 commit 時の verify は markdown 内容確認と git diff 確認に限定する。 driver / runtime に触れないため MAME 動作確認と audio gate は不要。

将来の FM/SSG Step 1 実装時 verify gate:

1. build 成功
2. MAME 起動成功
3. ymfm register trace で Part B / chip ch 2 の tone load、frequency、keyon、keyoff を確認
4. ADR-0035 RawRegisterWrite oracle との比較
5. FM solo audio gate (= user gate 必要)
6. ADPCM-A / K/R rhythm regression に不要な差分がないこと

## 後続 sprint 候補

1. `wip-fm-ssg-step1-keyon` branch 起票
2. FM Step 1 ADR 起票 (= Part B single-note trace proof)
3. source ownership の実ファイル名確定
4. expected trace fixture の置き場確定
5. MAME / ymfm trace runner の既存 scripts 再利用範囲確認
6. audio gate solo fixture 設計 (= user gate 必要)

## Annex A: talking points 対応表

| handoff 論点 | 本 ADR の決定 |
|---|---|
| 論点 1 source 触接面の独立性 verify | 決定 1 |
| verify infra 共有範囲 (= user task で論点 2 として指定) | 決定 2 |
| 論点 2 FM/SSG 軸 Step 1 の最小 proof scope | 決定 3 |
| 論点 3 PMDDotNET Z80 化遺産との関係 | 決定 4 |
| 論点 4 Step 単位粒度 | 決定 5 |
| 論点 5 並走時の commit chain / branch 戦略 | 決定 6 |
| 論点 6 検証 infra の共存 + 論点 7 IR 軸との接続点 | 決定 2 + 決定 7 |
