# ADR-0027: Step 13 — K/R drum kind expansion proof (s = SD single-kind / dispatch path 1 本化不変 / 既存 adpcma_sample_sd 再利用 / BD fixture 不変 + SD fixture 2 件新規 / 3 軸 verify)

- 状態: **Accepted** (= 2026-05-14 14th session δ 完了統合で移行、 元 Draft 起票 2026-05-14 14th session 冒頭、 α/β/γ/δ 4 commit chain 全 PASS + user audio gate OK + 全 20 script regression PASS で Accepted 移行)
- 起票日: 2026-05-14
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0026 (= step 12 K/R rhythm compatibility proof、 §決定 6 「dispatch path 1 本化」 + §決定 5 「b-only proof」 + §scope-out 「drum 種拡張」 を本 ADR で 1 軸消化)、 ADR-0025 (= step 11 multi-table id=0x01 proof、 §決定 1 A2 cache scope-out 維持)、 ADR-0024 (= step 10 sample_table_id selection consumption、 explicit if/jr 流儀踏襲)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 §決定 4 sample 増加は別 sprint 接続点予約)、 ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive → step 12 で reconnected → 本 ADR で drum kind 1 軸拡張)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様、 drum 識別文字 = `b/s/c/h/t/i` 6 種 = PMDDotNET mc.cs rcomtbl L9528-9533 literal、 `r` は rest 専用、 本 ADR §Annex A-1 で literal 確認)

## 背景

Step 12 (= ADR-0026 Accepted、 2026-05-14 13th session、 commit `6dc1a13`) で K/R rhythm compatibility proof sprint が成立した。 driver は PMD V4.8s 系 K part `\b` + melody part inline `\b` の 2 系統 MML syntax を、 PMDDotNET `0xEB 0x01` bytecode を経て driver `.MN` direct parser で normalize し、 独立 routine `pmdneo_rhythm_event_trigger` (@ 0x1126) で共通 dispatch して ADPCM-A L ch BD trigger に到達させる contract chain を、 PC trace + ymfm-trace 二段 gate + byte-identical literal proof で literal 観測可能にした。

ADR-0026 §決定 5 で確立した「drum kind = b only proof」 と、 §決定 6 で確立した「**dispatch path は drum 種拡張で増やさない**」 という 2 つの contract に対し、 Step 13 はその **自然な 1 軸拡張** を担う:

- 「**drum 種を b (= BD only) から s (= SD 追加、 計 2 drum) に 1 軸拡張**」
- 「**dispatch path は不変 (= `pmdneo_rhythm_event_trigger` 継続)**」 → ADR-0026 §決定 6 が drum 種拡張で literal 維持されることの proof
- 「**sample pointer mapping のみ拡張**」 (= bit 0 → BD addr / bit 1 → SD addr)

ADR-0026 §決定 8 (= source 2 系統 → runtime 1 系統 collapse) と §決定 11 (= scope-out 26 項目維持) の延長で、 K/R semantics の MML 互換 surface area を **drum kind 軸 1 段** だけ広げる小規模 proof sprint。 「drum kind expansion proof」 という言葉自体が示すように、 sample asset 軸 / channel 軸 / runtime parser 軸は触らない。

ただし「drum kind expansion」 と素朴に定義すると scope が再び肥大化する (= 全 5 drum 一気 / BD+SD 同時打ち bitmap OR semantics / channel allocation 改定 / `.PNE` rhythm bank migration / 制御 cmd 現役化 等を同時に触る)。 13th session 末 user 直接指示 + 14th session 冒頭壁打ち で以下の方針整理が確定:

- **drum 種拡張軸 = bit 1 SD のみ accept** (= 全 5 drum 一気は scope-out、 c/h/t/i 残り 4 種 future) (= 軸 1)
- **BD+SD 同時打ち scope-out** (= bitmap OR semantics literal proof は Step 14 候補温存) (= 軸 2)
- **SD sample source = 既存 `adpcma_sample_sd` 再利用** (= ADR-0026 §決定 3 driver-embedded fixture proof 規律踏襲、 ADR-0025 step5b で SD ADPCM-A subsystem 内 embed 済) (= 軸 3)
- **fixture = `k-sr-only.mml` + `r-melody-sr-only.mml` 2 件新規 + BD fixture 完全不変** (= 4 fixture 体制 K-BD / R-BD / K-SD / R-SD、 命名 = `\s` + `r`(= rest) pattern、 α 調査で PMDDotNET の SD emit 記号確認 + 食い違い時 rename) (= 軸 4)
- **verify gate = 3 軸** (= SD trigger 単独 + K-SD vs R-SD differential + BD vs SD differential、 keyon count identical + PC marker hit + ymfm-trace literal register value assert) (= 軸 5)

これに基づき Step 13 を **「K/R drum kind expansion proof — s = SD」** として定義する。 ADR-0026 dispatch path 1 本化を **drum 種拡張に対して literal 維持** することの proof であり、 「dispatch path は drum 種拡張で増やさない」 が Step 13 で実装的に保証される最小成立形である。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 Step 13 着手前に方針を ADR として独立起票する。

### 14th session 冒頭壁打ちでの 5 軸方針確定

ADR-0027 起票前に user 主導で 5 軸の壁打ちが行われ、 Step 13 の出口像が以下に固定された (= 軸 1 / 軸 2 は 13th session 末 user 推奨で既決、 軸 3 / 軸 4 / 軸 5 は 14th session 冒頭で逐次確定)。

**軸 1: SD 追加 = bit 1 のみ accept (= 13th session 末既決)**

drum 種拡張方針:

- (e1) (= 不採用): 全 5 drum 一気 (= bit 1 SD / bit 2 CYM / bit 3 HH / bit 4 TOM / bit 5 RIM 同時実装)
- (e2) (= **採用**): SD 単独拡張 (= bit 1 のみ accept、 c/h/t/i 残り 4 種 future)
- (e3) (= 不採用): drum 種ではなく velocity / volume 軸拡張先行

(e2) 採用根拠: ADR-0026 b-only proof と同じ proof 最小性、 dispatch path 1 本化が drum 種拡張で literal 維持されることの proof は **1 軸拡張で十分**、 全 5 drum 一気は fixture / verify / sample addr mapping を同時拡張で scope 肥大化、 PMD V4.8s K part 文法的に b / s は最頻出 (= BD/SD の組合せが pop / rock 基本 pattern)、 SD は ADR-0025 step5b で ADPCM-A subsystem 内に既に embed 済 (= `adpcma_sample_sd`、 sample source 取得コスト 0)。

ADR / handoff 記載要件:
- Step 13 drum 種 = **bit 0 BD + bit 1 SD のみ accept**
- bit 2-5 (= CYM / HH / TOM / RIM) は **silent ignore** (= ADR-0026 §決定 11 「未対応 cmd スルー」 思想踏襲)
- 残り 4 種拡張は **future sub-sprint** (= Step 14 候補温存)
- dispatch path は drum 種拡張で **増やさない** (= ADR-0026 §決定 6 維持、 本 ADR §決定 8 で再確認)

**軸 2: BD+SD 同時打ち = scope-out (= 13th session 末既決)**

bitmap OR semantics 対応:

- (sim1) (= 不採用): Step 13 で BD+SD bitmap OR 結合 emit 対応を含める
- (sim2) (= **採用**): Step 13 では BD 単独 / SD 単独 のみ proof、 同時打ちは Step 14 候補温存

(sim2) 採用根拠: PMDDotNET emit 軸の確認 (= 同 K part 行 `\b\s` の連続記述で bitmap OR `0x03` を emit するか 2 個の 0xEB `0x01` + `0x02` を emit するかは α 調査範囲) が drum kind 軸 1 段拡張の proof と独立、 同時打ちは bitmap decode を driver 側で実装する別軸、 BD-only / SD-only fixture で 2 軸の dispatch path 維持を proof すれば drum kind expansion proof の literal 成立は十分。

ADR / handoff 記載要件:
- BD+SD 同時打ち = **scope-out**
- bitmap OR semantics の literal proof は **future** (= Step 14 候補)
- Step 13 fixture は BD 単独 / SD 単独 のみ (= 同 K part 行 / R command 行に `\b\s` 並記は test しない)
- 「同時打ち scope-out」 を Annex A α 調査結果に軽く触れる (= PMDDotNET の bitmap OR emit 動作確認のみ literal 残置)

**軸 3: SD sample source = 既存 `adpcma_sample_sd` 再利用 (= 14th session 冒頭確定)**

SD trigger で使う sample:

- (sd_s1) (= **採用**): 既存 `adpcma_sample_sd` 再利用 (= BD と同じ pattern、 driver-embedded fixture proof 規律、 ADPCM-A subsystem 内既存資産)
- (sd_s2) (= 不採用): 新規 sample embed (= proof 用別 SD、 sample provenance 拡張)
- (sd_s3) (= 不採用): BD sample 流用 + freq shift (= sample addr mapping 軸の verify が薄まる)

(sd_s1) 採用根拠: Step 13 目的は drum kind expansion proof で sample source proof ではない、 新規 sample data embed は目的外、 既存 `adpcma_sample_sd` は ADR-0025 step5b で ADPCM-A subsystem 内に embed 済で再利用可、 ADR-0026 §決定 3 driver-embedded fixture proof 規律と整合、 BD と SD で register addr 差分が literal 確認しやすい、 ROM 容量 / asset pipeline 不変。

ADR / handoff 記載要件:
- SD sample source = **既存 `adpcma_sample_sd` 再利用**
- 新規 sample embed は **scope-out**
- `.PNE` rhythm bank migration は **future** (= ADR-0026 §決定 3 future migration path 継続)
- Step 13 は **sample source proof ではなく drum kind mapping proof**
- bit 0 → `adpcma_sample_bd` / bit 1 → `adpcma_sample_sd` の mapping を driver source 内に literal 配置

**軸 4: fixture 体制 = BD fixture 不変 + SD fixture 2 件新規 (= 14th session 冒頭確定)**

K-SD / R-SD fixture 取り扱い:

- (fix1) (= **採用**): 4 fixture 体制 (= 既存 `k-br-only.mml` + `r-melody-br-only.mml` 完全不変 + `k-sr-only.mml` + `r-melody-sr-only.mml` 新規追加)
- (fix2) (= 不採用): 2 fixture 維持 (= 既存 BD fixture を SD 版に置換、 BD regression script が消失)
- (fix3) (= 不採用): BD + SD 両方を含む単一 fixture (= K-R differential verify がやりにくい)

(fix1) 採用根拠: Step 12 BD proof を regression として残せる、 Step 13 SD proof を独立追加できる、 BD path を壊していないことを継続確認できる (= 「動いているものを壊さない」 規律遵守)、 K-BD / R-BD / K-SD / R-SD の 4 fixture 体制が読みやすい、 BD+SD 同時打ち scope-out 前提で単一 fixture に混ぜない方が良い。

命名規則:

- `k-sr-only.mml` (= K part 内 `\s` + `r`(= rest)、 既存 `k-br-only.mml` (= `\b` + `r`) と 1 文字違い)
- `r-melody-sr-only.mml` (= melody part L 内 inline `\s` + `r`(= rest)、 既存 `r-melody-br-only.mml` と 1 文字違い)

ADR / handoff 記載要件:
- BD fixture (= `k-br-only.mml` / `r-melody-br-only.mml`) は **完全不変**
- SD fixture 2 件 (= `k-sr-only.mml` / `r-melody-sr-only.mml`) を新規追加
- fixture 名の `sr` は「snare drum」 略ではなく `\s` + `r`(= rest) の fixture pattern (= 既存 `br` と命名 pattern 統一)
- α 調査で PMDDotNET が SD を `\s` として emit することを literal 確認
- SD の MML 記号が `\s` でないと判明した場合は、 fixture 名を実 bytecode / actual syntax に合わせて修正
- BD/SD 差分は verify script で literal に確認

**軸 5: verify gate = 3 軸 (= 14th session 冒頭確定)**

verify 範囲:

- (v1) (= **採用**): 3 軸 verify (= SD trigger 単独 + K-SD vs R-SD differential + BD vs SD differential)
- (v2) (= 不採用): Step 12 pattern 踏襲 2 軸 (= SD trigger 単独 + K-SD vs R-SD differential)
- (v3) (= 不採用): SD trigger 単独のみ 1 軸 minimalist

(v1) 採用根拠: Step 13 目的は「SD が鳴る」 だけではなく drum kind expansion proof、 K と R が同じ SD dispatch path を通ることを確認する必要がある (= dispatch path 1 本化の drum 種拡張下での維持)、 BD と SD が register / sample address 上で区別できる必要がある (= drum kind mapping の literal proof)、 BD path regression も同時に守れる、 silent path に倒れただけではないことを確認できる。

verify gate 構成:

```
K-SD:
  bit1 → SD trigger (= ADPCM-A L ch SD register write trace + keyon count + PC marker)

R-SD:
  bit1 → 同じ SD trigger (= K-SD vs R-SD byte-identical literal proof + PC marker)

BD vs SD:
  bit0 と bit1 で sample addr が違う (= reg 0x10 sample addr literal differ + reg 0x18 sample end addr literal differ)
```

加えて (= ADR-0026 §verify gate 規律踏襲):

- **keyon count identical** (= K-SD と R-SD で ADPCM-A L ch keyon mask 0x01 trigger count 同一)
- **PC marker hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126 PC trace hit、 K-SD / R-SD 両方で同 addr hit)
- **ymfm-trace literal register value assert** (= sample addr reg 値を literal 数値で assert、 visual diff ではなく数値 assert)

ADR / handoff 記載要件:
- verify gate は **3 軸 (= SD trigger + K-SD vs R-SD differential + BD vs SD differential)**
- 3 件の verify script を新規追加
- `verify-step13-sd-trigger.sh` (= K-SD / R-SD 各 fixture で SD register write trace + keyon count + PC marker)
- `verify-step13-kr-sd-differential.sh` (= K-SD vs R-SD byte-identical literal proof)
- `verify-step13-bd-sd-differential.sh` (= BD vs SD sample addr literal differ proof)
- 既存 16 script regression に 3 件追加 = 19 script 体制

## 決定

### 決定 1: Step 13 を「K/R drum kind expansion proof — s = SD」 として定義 (= bit 1 SD 1 軸拡張、 dispatch path 1 本化不変、 既存 adpcma_sample_sd 再利用、 BD fixture 不変 + SD fixture 2 件新規、 3 軸 verify)

Step 13 の最終 deliverable boundary を **「K part `\s` + melody part inline `\s` の 2 系統 MML syntax を受取り、 driver `.MN` direct parser で normalize して、 共通 routine `pmdneo_rhythm_event_trigger` 経由で bit 1 分岐 → `adpcma_sample_sd` pointer mapping → ADPCM-A L ch SD trigger に audible に dispatch する」** とする。 PMDDotNET / `.MN` format / `pmdneo_rhythm_event_trigger` routine entry / observability marker / driver-embedded fixture 規律は完全不変、 drum 種 → sample pointer mapping table のみ bit 0 → BD + bit 1 → SD に 1 軸拡張、 PC trace + ymfm-trace の 3 軸 gate (= SD trigger + K-SD vs R-SD differential + BD vs SD differential) で **drum kind expansion 後も dispatch path が 1 本化されていること** + **drum 種で sample addr が literal 区別されること** を literal 観測可能にすることを目的とする。

#### Step 12 → Step 13 拡張点

ADR-0026 で確立した contract のうち、 Step 13 で **拡張** されるのは:

- driver の K/R 受入 drum 種範囲: b (= BD only) → b + s (= BD + SD)
- driver-embedded sample 表 entry 数: BD 1 種 → BD + SD 2 種
- drum 種 → sample pointer mapping: bit 0 only → bit 0 + bit 1
- fixture 数: K-BD + R-BD = 2 件 → K-BD + R-BD + K-SD + R-SD = 4 件
- verify script 数: step12 系 4 件 → step12 系 4 件 + step13 系 3 件 = 7 件
- 全 regression script 数: 16 件 → 19 件

Step 13 で **不変** に保つもの:

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126、 ADR-0026 §決定 8 PC marker 維持)
- `pmdneo_rhythm_event_trigger` routine 構造 (= bit 0 分岐既存、 bit 1 分岐を新規追加するが routine entry / 引数 / 戻り値 ABI は不変)
- PMDDotNET (= C# compile path) は完全不変 (= ADR-0026 §決定 10 維持)
- `.MN` format は完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う、 ADR-0026 §決定 10 維持)
- 既存 L-Q ADPCM-A melody architecture (= ADR-0019 / ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 / ADR-0025 で確立)
- selected pointer runtime state cache 不採用 (= ADR-0024 §決定 6 / ADR-0025 §決定 1 / ADR-0026 §決定 11 維持)
- `sample_table_id` resolver / selector の ABI (= Step 9-11 で確立)
- sentinel pointer 0x0000 silent semantics
- driver SRAM layout (= 0xFD20-0xFD32 既存領域、 Step 13 で新規 marker byte を追加しない)
- multi-table id=0x01 differentiation proof contract (= ADR-0025 全 §決定)
- K/R rhythm event dispatch proof contract (= ADR-0026 全 §決定、 §決定 5 「b-only proof」 は本 ADR §決定 2 で「b + s proof」 に literal 更新するが dispatch path 1 本化不変原則は維持)
- `.PNE` / `.MN` asset pipeline (= ADR-0021 で確立)
- BD fixture (= `k-br-only.mml` / `r-melody-br-only.mml`) 完全不変
- 既存 16 script regression PASS

#### dispatch path 1 本化の drum 種拡張下での維持 (= ADR-0026 §決定 6 / §決定 8 の literal 実証)

ADR-0026 §決定 6 / §決定 8 で確立した「dispatch path は drum 種拡張で増やさない」 contract は、 Step 13 で **bit 0 BD + bit 1 SD の 2 drum 状況下で `pmdneo_rhythm_event_trigger` routine entry addr が変化しない** ことで literal 実証される。 K-SD / R-SD fixture で PC trace を取得し、 PC hit addr が Step 12 と同一 (= 0x1126) であることを `verify-step13-sd-trigger.sh` で literal assert する。

Step 13 で routine 内部の implementation は拡張される (= bit 1 分岐追加) が、 routine entry / 引数 / 戻り値 ABI は不変。 future の drum 種拡張 (= c/h/t/i 4 種) でも同じ entry addr を保持することを Step 13 で先取り保証する。

### 決定 2: drum 種拡張 = bit 1 SD 単独 accept (= ADR-0026 §決定 5 b-only proof を b + s proof に literal 更新、 bit 2-5 silent ignore 維持)

K part 文法 subset (= 軸 1 / (e2) 採用):

- K letter = `K` 維持 (= PMD V4.8s 互換、 ADR-0026 §決定 5 維持)
- drum 識別文字 = **`b` = BD + `s` = SD の 2 種** で proof (= ADR-0026 §決定 5 の「b only」 を「b + s」 に literal 拡張)
- 残り 4 種 (= `c` = CYM / `h` = HH / `t` = TOM / `i` = RIM、 `r` は rest 専用) は future sub-sprint で段階追加 (= Step 14 候補、 α 調査で PMDDotNET mc.cs rcomtbl L9528-9533 literal 確認、 §Annex A-1 参照)
- K syntax 自体は PMD 互換 (= drum 種拡張時に既存 K part syntax を維持)

#### bitmap accept range

driver `.MN` direct parser での `0xEB <bitmap>` 受入:

- **bit 0 = 1**: BD trigger (= 既存 ADR-0026 維持)
- **bit 1 = 1**: SD trigger (= 本 ADR で新規追加)
- **bit 2 = 1**: CYM trigger (= `\c`) → **silent ignore** (= 未対応 cmd スルー思想、 ADR-0026 §決定 11 踏襲)
- **bit 3 = 1**: HH trigger (= `\h`) → **silent ignore**
- **bit 4 = 1**: TOM trigger (= `\t`、 mc.cs `tamset` 経由) → **silent ignore**
- **bit 5 = 1**: RIM trigger (= `\i`、 `\r` ではない、 mc.cs `rimset` 経由) → **silent ignore**
- **bit 6-7**: reserved (= silent ignore)
- **bitmap = 0x00**: no-op
- **bitmap = 0x03 (= BD + SD 同時)**: bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 2)、 動作は α 調査で literal 確認 + 結果 Annex A 反映、 Step 13 fixture では生成しない

#### 採用根拠

- ADR-0026 b-only proof と同じ proof 最小性
- dispatch path 1 本化が drum 種拡張で literal 維持されることの proof は 1 軸拡張で十分
- 全 5 drum 一気は fixture / verify / sample addr mapping を同時拡張で scope 肥大化
- BD/SD は PMD V4.8s K part 文法的に最頻出
- SD sample は ADR-0025 step5b で ADPCM-A subsystem 内に既に embed 済 (= sample source 取得コスト 0)

#### ADR / handoff 記載 contract

- Step 13 では drum kind = **b + s only**
- future sprint で c/h/t/i を **段階追加**
- bit 2-5 は **silent ignore** (= 未対応 cmd スルー思想踏襲)
- dispatch path は drum 種拡張で **増やさない** (= 決定 8 と整合)

### 決定 3: SD sample source = 既存 `adpcma_sample_sd` 再利用 (= driver-embedded fixture proof 規律踏襲、 ADR-0026 §決定 3 future `.PNE` migration path 継続)

SD trigger で使う sample (= 軸 3 / (sd_s1) 採用):

#### Step 13 proof 段階

- bit 0 BD → `adpcma_sample_bd` pointer (= 既存 Step 12 維持)
- bit 1 SD → `adpcma_sample_sd` pointer (= 本 ADR で新規 mapping 追加)
- sample header / addr 値は driver source / `samples.inc` 内に literal 配置 (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 ADR-0025 step5b で既に SD ADPCM-A subsystem 内に embed 済)
- 新規 sample embed なし (= 既存資産再利用のみ)
- `.PNE` / `.MN` asset pipeline / `pne_sample_directory` / `sample_table_id` resolver / `pmdneo_select_sample_pointer` は完全不変
- L-Q melody sample / rhythm BD sample / rhythm SD sample は別表 / 別 routine entry で分離

#### future migration path (= ADR-0026 §決定 3 継続、 literal 残置)

将来的に OPNA rhythm 相当 sample set を `.PNE` 側へ寄せる可能性が高い (= ADR-0026 §決定 3 と同一)。 候補 path:

- `.PNE` rhythm bank entry を新設 (= `sample_table_id` id=0x02 を rhythm bank として確保、 directory entry 拡張)
- generated rhythm sample directory (= D3 migration の一部として rhythm sample を含める)
- driver の `pmdneo_rhythm_event_trigger` routine が `.PNE` rhythm bank entry を引くように変更

ただし上記は **Step 13 scope-out**、 future sprint で必要なら別途検討。

#### ADR / handoff 記載 contract

- SD sample = **既存 `adpcma_sample_sd` 再利用**
- 新規 sample embed = **scope-out**
- driver-embedded rhythm fixture は **proof 用** (= ADR-0026 §決定 3 維持)
- `.PNE` migration は **future sprint** (= ADR-0026 §決定 3 future migration path 継続)
- Step 13 は **drum kind mapping proof**、 sample source proof ではない

### 決定 4: dispatch path 1 本化不変 (= `pmdneo_rhythm_event_trigger` routine entry addr 不変、 routine 内部の bit 1 分岐は追加するが ABI 不変)

K と R の dispatch path (= ADR-0026 §決定 6 維持 + Step 13 で drum 種拡張下の literal 維持):

#### routine entry 不変

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は Step 12 から不変
- K-SD / R-SD fixture でも PC trace hit addr は 0x1126 (= 既存 Step 12 K-BD / R-BD と同一)
- routine 引数 / 戻り値 ABI 不変
- `.MN` direct parser からの caller 接続不変

#### routine 内部の bit 1 分岐追加

routine 内部の implementation は拡張される:

- 既存: bit 0 = 1 → BD trigger (= `adpcma_sample_bd` register write)
- 新規: bit 1 = 1 → SD trigger (= `adpcma_sample_sd` register write)
- bit 2-5: silent ignore (= no register write)
- bit 6-7: reserved (= no register write)
- bitmap = 0x00: no-op

#### branch 実装流儀 (= explicit if/jr、 ADR-0024 §決定 流儀踏襲)

bit 0 / bit 1 の分岐は **explicit if/jr** で記述 (= jump table / dispatch macro は使わない)。 ADR-0024 step 10 / ADR-0025 step 11 / ADR-0026 step 12 全てで踏襲してきた流儀:

```asm
pmdneo_rhythm_event_trigger:
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 2-5 = silent ignore
    bit 0, a
    jr z, _rhythm_event_no_bd
    call _rhythm_event_bd_trigger
_rhythm_event_no_bd:
    bit 1, a
    jr z, _rhythm_event_no_sd
    call _rhythm_event_sd_trigger
_rhythm_event_no_sd:
    ret

_rhythm_event_bd_trigger:
    ; adpcma_sample_bd を ADPCM-A L ch に register write
    ...
    ret

_rhythm_event_sd_trigger:
    ; adpcma_sample_sd を ADPCM-A L ch に register write
    ...
    ret
```

実装の literal asm は β commit で確定 (= 本 ADR は契約のみ literal 固定、 implementation 詳細は β に委ねる)。

#### ADR / handoff 記載 contract

- `pmdneo_rhythm_event_trigger` routine entry addr = **不変** (= 0x1126)
- routine ABI = **不変**
- routine 内部の bit 1 分岐は **追加** (= bit 0 BD trigger の隣に bit 1 SD trigger)
- branch 流儀 = **explicit if/jr** (= ADR-0024 / 0025 / 0026 流儀踏襲)
- dispatch path は drum 種拡張で **増やさない** (= ADR-0026 §決定 6 維持、 本 ADR §決定 8 で再確認)

### 決定 5: fixture 体制 = BD fixture 完全不変 + SD fixture 2 件新規 (= 4 fixture 体制 K-BD / R-BD / K-SD / R-SD)

K-SD / R-SD fixture 取り扱い (= 軸 4 / (fix1) 採用):

#### 既存 BD fixture 完全不変

- `compile-test-pmddotnet/k-br-only.mml` (= Step 12 β commit 309c011 で新規追加、 K part `\b` + `r`(= rest) のみ)
- `compile-test-pmddotnet/r-melody-br-only.mml` (= Step 12 γ commit 5465f08 で新規追加、 melody part L 内 inline `\b` + `r`(= rest))

これらは **完全不変** (= byte-identical 維持、 Step 12 K-R differential proof script で継続使用)。

#### 新規 SD fixture 2 件

- `compile-test-pmddotnet/k-sr-only.mml` (= K part `\s` + `r`(= rest) のみ、 K-BD fixture と 1 文字違い)
- `compile-test-pmddotnet/r-melody-sr-only.mml` (= melody part L 内 inline `\s` + `r`(= rest)、 R-BD fixture と 1 文字違い)

#### fixture 命名規則

- `k-sr-only.mml` の `sr` は **`\s` + `r`(= rest) の fixture pattern**
- `sr` は「snare drum」 略 **ではない** (= 既存 `br` も「BD」 略ではなく `\b` + `r` pattern と同一)
- α 調査で PMDDotNET が SD を `\s` として emit することを literal 確認 (= mc.cs rhysel / rs00 emit 周辺)
- もし α 調査で SD の MML 記号が `\s` でないと判明した場合は、 fixture 名を **実 bytecode / actual syntax に合わせて修正** (= sub-sprint 内で rename、 β 着手前に確定)

#### 4 fixture 体制

| fixture | drum 種 | source 経路 | step12 / step13 |
|---|---|---|---|
| `k-br-only.mml` | BD | K part | step 12 既存 |
| `r-melody-br-only.mml` | BD | melody part inline | step 12 既存 |
| `k-sr-only.mml` | SD | K part | step 13 新規 |
| `r-melody-sr-only.mml` | SD | melody part inline | step 13 新規 |

#### ADR / handoff 記載 contract

- BD fixture = **完全不変**
- SD fixture = **2 件新規追加**
- fixture 命名 pattern = `\s` + `r`(= rest) = `sr` (= 既存 `br` pattern 踏襲、 drum 名略ではない)
- α 調査で命名修正可能性あり (= PMDDotNET SD emit 記号が `\s` でない場合)

### 決定 6: drum 種 → sample pointer mapping table を 1 軸拡張 (= bit 0 → BD addr / bit 1 → SD addr)

driver source 内 mapping table 構造:

#### Step 12 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 hardcoded、 `adpcma_sample_bd` literal addr 参照
- bit 1-7 は no-op (= silent ignore)

#### Step 13 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` literal addr 参照
- bit 2-7 は no-op (= silent ignore 維持)
- mapping table 構造は branch 流儀の延長 (= 別途 table 構造を導入せず、 explicit branch + literal addr 参照のまま)

#### branch 構造で literal addr 参照する根拠 (= 別 table 構造を導入しない理由)

- ADR-0024 / 0025 / 0026 で確立した explicit if/jr 流儀踏襲
- 2-3 drum 程度なら branch 列挙の方が trace gate / register write trace で読みやすい
- 別 mapping table 構造 (= bitmap bit position → sample addr pointer の lookup table) は 4+ drum で検討 (= future sprint c/h/t/i 追加時に再評価)
- 早すぎる抽象化を避ける (= CLAUDE.md §「3 行の重複は早すぎる抽象化より良い」 規律)

#### ADR / handoff 記載 contract

- drum 種 → sample pointer mapping = **explicit branch + literal addr 参照**
- 別 mapping table 構造 = **scope-out** (= future sprint で 4+ drum 拡張時に再評価)
- bit 0 → `adpcma_sample_bd` literal addr
- bit 1 → `adpcma_sample_sd` literal addr

### 決定 7: BD fixture 完全不変保証 (= Step 12 K-BD / R-BD path regression 維持)

Step 13 で BD path を壊していないことを継続確認する規律:

#### regression 維持要件

- Step 12 で確立した K-BD / R-BD path の verify script 4 件 (= `verify-step12-k-rhythm-trigger.sh` / `verify-step12-kr-differential.sh` 等) は **完全不変**
- Step 12 K-BD / R-BD fixture file (= `k-br-only.mml` / `r-melody-br-only.mml`) は **byte-identical** 維持
- Step 12 BD register write trace (= reg 0x10 / 0x18 / 0x20 / 0x28 + 0x08 vol|pan 0xDF + 0x00 keyon mask 0x01) は **同 sequence 維持**
- Step 13 commit chain (= α/β/γ/δ) の各 commit で全 step12 BD path verify script PASS が確認できる

#### ADR / handoff 記載 contract

- BD path **regression 維持**
- Step 12 fixture / verify script 完全不変
- Step 13 各 commit で BD path verify が **PASS 確認できる**
- 「動いているものを壊さない」 規律遵守 (= Step 5/6/7/8/9/10/11/12 で確立)

### 決定 8: dispatch path は drum 種拡張で増やさない (= ADR-0026 §決定 6 維持、 Step 13 で literal 実装保証)

ADR-0026 §決定 6 で確立した contract:

> dispatch path は drum 種拡張で増やさない

を Step 13 で **literal 実装的に保証** する:

#### 実装的保証 内容

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は不変
- K-SD / R-SD fixture で PC trace hit addr が Step 12 K-BD / R-BD と同一 (= 0x1126)
- routine ABI 不変
- routine 内部の bit 1 分岐追加は **routine 内部の implementation 拡張** であって dispatch path の新設ではない
- drum 種 → sample addr mapping は routine 内部の literal branch で吸収

#### future drum 種拡張で維持される項目

c/h/t/i 4 種追加時にも:

- routine entry addr 不変 (= 0x1126)
- routine ABI 不変
- 新規 dispatch routine を追加しない (= routine 内部の bit position 分岐を追加するのみ)
- future drum 種拡張で 4+ drum 状況になった時点で別 mapping table 構造への refactor を再評価 (= 決定 6 と整合)

#### ADR / handoff 記載 contract

- dispatch path = **1 本化維持**
- routine entry addr / ABI = **不変**
- drum 種拡張は **routine 内部 implementation 拡張で吸収**

### 決定 9: observability marker = `pmdneo_rhythm_event_trigger` PC hit 継続 (= ADR-0026 §決定 8 維持、 SRAM layout 不変)

Step 13 での observability marker 軸 (= ADR-0026 §決定 8 / 軸 7 維持):

- rhythm event observability marker = **routine PC hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126)
- memory marker byte は **持たない** (= SRAM 増設なし)
- SRAM layout は Step 13 でも **増やさない** (= 0xFD20-0xFD32 既存領域維持)
- PC trace + ymfm-trace の **二段 gate** で K-SD / R-SD proof
- K-SD / R-SD source path は別でも runtime dispatch routine は同一 (= 同 0x1126 PC hit)

#### ADR / handoff 記載 contract

- observability marker = **routine PC hit (= 0x1126)**
- memory marker byte 追加 = **scope-out**
- SRAM layout 不変
- PC trace + ymfm-trace 二段 gate 継続

### 決定 10: PMDDotNET / `.MN` format 完全不変 (= ADR-0026 §決定 10 維持)

Step 13 での PMDDotNET / `.MN` format 軸:

- PMDDotNET (= C# compile path) 完全不変
- `.MN` format 完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う)
- 新規 `.MN` bytecode 追加なし
- driver `.MN` direct parser での normalize は ADR-0026 で確立した `0xEB <bitmap>` 受入を維持、 bitmap accept range のみ bit 0 → bit 0+1 に拡張

#### ADR / handoff 記載 contract

- PMDDotNET-side normalize は **scope-out** (= ADR-0026 §決定 10 維持)
- new `.MN` rhythm event bytecode 追加は **scope-out** (= ADR-0026 §決定 10 維持)
- driver `.MN` direct parser での bitmap accept range 拡張のみ (= bit 0 → bit 0+1)

### 決定 11: BD+SD 同時打ち scope-out + bitmap OR semantics future investigation (= Step 14 候補温存、 Annex A 軽く触れる)

bitmap OR semantics 対応 (= 軸 2 / (sim2) 採用):

#### Step 13 scope-out

- BD+SD 同時打ち (= bitmap = 0x03) の literal proof は **Step 13 scope-out**
- Step 13 fixture は **BD 単独 / SD 単独 のみ** (= K-BD / R-BD / K-SD / R-SD 4 件、 BD+SD 並記 fixture なし)
- driver の bitmap accept range は bit 0 + bit 1 個別 accept (= bit 0=1 single / bit 1=1 single / bit 0=1 bit 1=1 同時打ちは α 調査で literal 動作確認のみ、 fixture proof scope-out)

#### bitmap OR semantics future investigation

- PMDDotNET が同 K part 行 `\b\s` の連続記述で **bitmap OR `0x03`** を emit するか、 **2 個の `0xEB` + `0x01` + `0xEB` + `0x02`** を emit するかは α 調査範囲
- α 調査結果を Annex A に literal 反映
- Step 14 候補 (= bitmap OR semantics literal proof sprint) として温存

#### ADR / handoff 記載 contract

- BD+SD 同時打ち = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 14 候補)
- Step 13 fixture は **BD 単独 / SD 単独 のみ**
- α 調査で PMDDotNET の bitmap OR emit 動作を literal 確認 + Annex A 反映

## scope-in / scope-out

### scope-in (= Step 13 で literal 実装する範囲)

1. driver `pmdneo_rhythm_event_trigger` routine に bit 1 分岐追加 (= SD trigger)
2. SD sample pointer mapping (= bit 1 → `adpcma_sample_sd` literal addr)
3. `k-sr-only.mml` fixture 新規追加
4. `r-melody-sr-only.mml` fixture 新規追加
5. `verify-step13-sd-trigger.sh` 新規追加 (= K-SD / R-SD register write trace + keyon count + PC marker)
6. `verify-step13-kr-sd-differential.sh` 新規追加 (= K-SD vs R-SD byte-identical literal proof)
7. `verify-step13-bd-sd-differential.sh` 新規追加 (= BD vs SD sample addr literal differ proof)
8. PMDDotNET SD emit literal 確認 (= mc.cs rhysel / rs00 周辺 + manual)
9. PMDDotNET bitmap OR emit 動作確認 (= 同 K part 行 `\b\s` 連続記述時の emit byte 列、 Annex A literal 反映)
10. ADR-0027 Annex A 反映 (= α 調査結果)
11. ADR-0027 Accepted 移行 (= δ で実施)
12. handoff doc 起票 (= δ で実施)
13. memory `project-pmdneo-step13-complete` 起票 (= δ で実施)
14. MEMORY.md index 更新 (= δ で実施)

### scope-out (= Step 13 で literal 触らない範囲)

#### Step 13 固有 scope-out (= 4 項目)

1. BD+SD 同時打ち literal proof (= bitmap = 0x03 fixture / verify) → Step 14 候補
2. c/h/t/i 残り 4 drum 種拡張 → future sub-sprint
3. drum 種 → sample addr mapping table 構造化 (= bitmap bit position → sample pointer の lookup table) → 4+ drum 拡張時に再評価
4. SD sample provenance 拡張 (= 新規 sample embed / `.PNE` rhythm bank migration) → future

#### ADR-0026 から継続する scope-out (= 26+ 項目維持)

5. OPNA rhythm sound source register (= 0x10-0x18) fake API (= PMDNEO は YM2610(B)、 emulation 方針外、 ADR-0026 §決定 2 維持)
6. 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation (= channel allocation 最終仕様は future、 ADR-0026 §決定 4 維持)
7. OPNA native rhythm timing fidelity (= ADR-0026 scope-out 追加項目維持)
8. K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch の 6 件、 silent fallback 継続、 ADR-0026 §決定 11 維持)
9. PMDDotNET 改造 / `.MN` format new bytecode (= ADR-0026 §決定 10 / 本 ADR §決定 10 維持)
10. selected pointer cache (A2/A3) / mismatch silent flag / D3 generated directory / runtime `.PNE` parser / multi-`.PNE` switching / bank switching (= ADR-0025 §scope-out 継続)
11. `.PPC` / `.P86` / ADPCM-B subsystem 起票 (= 別 subsystem、 `project_pmdneo_adpcma_subsystem_boundary` 維持)
12. `.PNE` rhythm bank migration (= ADR-0026 §決定 3 future migration path 継続、 ADPCM-A subsystem 内だが Step 13 scope-out)
13. driver-embedded fixture 以外の sample provenance (= ADR-0026 §決定 3 維持)
14. multi-table cache / runtime parser (= ADR-0025 / ADR-0026 §決定 11 継続)
15. new bytecode (= ADR-0026 §決定 10 / 本 ADR §決定 10 維持)
16. PMDDotNET 改造 (= ADR-0026 §決定 10 / 本 ADR §決定 10 維持)
17. observability marker 拡張 (= memory marker byte / SRAM 増設、 ADR-0026 §決定 8 / 本 ADR §決定 9 維持)
18. K letter 以外の rhythm part letter (= ADR-0026 §決定 5 維持)
19. PMDNEO 独自 drum 識別文字 (= PMD 互換維持、 ADR-0026 §決定 5 維持)
20. velocity / volume / pan / loop / pattern 軸拡張 (= ADR-0026 §決定 1 b-only proof + 本 ADR §決定 2 b+s proof minimum 範囲限定)
21. K part / R command 以外の rhythm 系 cmd (= ADR-0026 §決定 11 維持)
22. ADPCM-B subsystem への rhythm extension (= `project_pmdneo_adpcma_subsystem_boundary` 維持、 別 subsystem)
23. WebApp UI 関連 (= Phase 4 範囲、 別 sprint)
24. WAV import / 新規 sample 追加 UI (= Phase 4 範囲)
25. AES+ 実機検証 (= 別 sprint、 verify は MAME headless 経由継続)
26. fmgen 比較 (= 別 sprint)
27. PMDNEO.s + nullsound integration (= `project_pmdneo_driver_two_paths_discovery` 維持、 別 path)

## verify gate

### 5 段 gate (= ADR-0026 §verify gate 形式踏襲)

#### Gate 1: build PASS

- α: 全 17 既存 script regression PASS (= 16 step12 系 + 1 step13 sd-trigger 着手前 placeholder か未追加)
- β: 全 17 既存 + step13 sd-trigger 新規 = 17+1 = 18 script PASS
- γ: 全 17 既存 + step13 sd-trigger + step13 kr-sd-differential + step13 bd-sd-differential = 17+3 = 20 script PASS (= 既存 16 + step13 step12 拡張系 1 + step13 新規 3、 詳細は β/γ 着手時確定)
- δ: 全 script 最終 regression PASS

#### Gate 2: K-SD trigger 単独 verify

`verify-step13-sd-trigger.sh` PASS 内容:

1. `k-sr-only.mml` build → `.MN` byte literal 確認 (= `0xEB 0x02 0x80` 期待 or PMDDotNET 実 emit byte literal、 α 調査結果で確定)
2. ymfm-trace で ADPCM-A L ch SD register write 確認 (= reg 0x10 sample addr literal = `adpcma_sample_sd` start addr 等)
3. PC trace で `pmdneo_rhythm_event_trigger` @ 0x1126 hit 確認
4. keyon count = 1 (= L ch keyon mask 0x01 trigger 1 件)
5. K-SD fixture / R-SD fixture 両方で同 sequence PASS

#### Gate 3: K-SD vs R-SD differential proof

`verify-step13-kr-sd-differential.sh` PASS 内容:

1. K-SD fixture (= `k-sr-only.mml`) と R-SD fixture (= `r-melody-sr-only.mml`) で ADPCM-A L ch register write sequence **byte-identical** literal proof
2. PC trace hit addr 同一 (= 両方 0x1126)
3. keyon count 同一 (= 両方 1 件)
4. dispatch path 1 本化が drum 種拡張 (= SD) 下でも literal 維持されることの proof

#### Gate 4: BD vs SD differential proof

`verify-step13-bd-sd-differential.sh` PASS 内容:

1. K-BD fixture (= `k-br-only.mml`) と K-SD fixture (= `k-sr-only.mml`) で:
   - reg 0x10 sample start addr **literal differ** (= `adpcma_sample_bd` start addr ≠ `adpcma_sample_sd` start addr)
   - reg 0x18 sample end addr **literal differ**
   - reg 0x20 volume / reg 0x28 pan は **identical** (= 同 L ch、 同 fixture pattern なら同値)
   - reg 0x08 vol|pan / reg 0x00 keyon mask は **identical**
2. R-BD fixture と R-SD fixture でも同様の差分 literal proof
3. drum 種 → sample addr mapping が literal 区別されていることの proof

#### Gate 5: 既存 regression 不破壊

- 既存 16 script regression PASS 維持 (= ADR-0026 完了時の 16 script、 BD path / multi-table / melody / asset pipeline 全て)
- 各 commit (= α/β/γ/δ) で全 step12 BD path verify script PASS が確認できる
- 「動いているものを壊さない」 規律遵守

### audio gate

- ✅ user 試聴 OK 確認 (= δ commit 前 14th session δ で user 試聴依頼、 4 wav file = `/tmp/pmdneo-step12/k-br-only.wav` + `/tmp/pmdneo-step12/r-melody-br-only.wav` + `/tmp/pmdneo-step13/k-sr-only.wav` + `/tmp/pmdneo-step13/r-melody-sr-only.wav` で確認)
- ✅ user judgement: 「k-br-only = r-melody-br-only」 「k-sr-only = r-melody-sr-only」 = K/R で同音、 BD vs SD で違う音色、 FM 同居許容 (= Step 12 audio gate 規律踏襲)
- ✅ BD 単独 / SD 単独 各 fixture で音が鳴る + BD と SD で聴感的に区別可能 を user judgement で確認

## 完了判定

Step 13 完了判定 (= 10 項目、 14th session δ で全 ✅ 達成):

1. ✅ ADR-0027 Accepted 移行 (= 本 δ commit で literal 達成)
2. ✅ `pmdneo_rhythm_event_trigger` routine に bit 1 SD 分岐追加 (= β commit `36588b3`、 push af / bit 0 / call nz / pop af / bit 1 / ret z / jr SD trigger 構造)
3. ✅ SD sample pointer mapping (= bit 1 → `adpcma_sample_sd`) 実装 (= β commit `36588b3`、 `_rhythm_event_sd_trigger:` label で literal addr 参照)
4. ✅ `k-sr-only.mml` fixture 新規追加 (= K-SD path、 β commit `36588b3`、 UTF-8 + CRLF)
5. ✅ `r-melody-sr-only.mml` fixture 新規追加 (= R-SD path、 γ commit `2aad439`、 UTF-8 + CRLF)
6. ✅ `verify-step13-sd-trigger.sh` 新規追加 + PASS (= β commit `36588b3`、 5 gate PASS)
7. ✅ `verify-step13-kr-sd-differential.sh` 新規追加 + PASS (= γ commit `2aad439`、 7 gate PASS、 K-SD vs R-SD byte-identical)
8. ✅ `verify-step13-bd-sd-differential.sh` 新規追加 + PASS (= γ commit `2aad439`、 6 gate PASS、 BD vs SD sample addr literal differ)
9. ✅ 既存 全 script regression PASS 維持 (= δ で 20 script serial 実行、 全 PASS = step 4/5/6/7/8/9/10/11/12 系 14 script + step 12 新規 2 件 + step 13 新規 3 件 = 20 script、 BD path 不変保証 + driver 改修副作用なし)
10. ✅ user 試聴 OK 確認 (= 14th session δ user 試聴依頼で「k-br-only = r-melody-br-only」 「k-sr-only = r-melody-sr-only」 K/R 同音確認、 BD/SD 区別可能、 FM 同居許容方針 ADR-0026 audio gate 規律踏襲)

## 本質再確認

### layering 図 (= future contributor 向け literal 固定、 Step 12 layering の drum 種 1 軸拡張)

```
source layer:           K part             R command
                        \b / \s            \b inline / \s inline
                            \              /
                             \            /
                              normalize  (= driver .MN direct parser)
                                  |
                                  V
                          0xEB <bitmap>
                                  |
                                  V
                    pmdneo_rhythm_event_trigger  (@ 0x1126、 routine entry 不変)
                                  |
                                  +-- bit 0 = 1 --> _rhythm_event_bd_trigger --> adpcma_sample_bd --> ADPCM-A L ch
                                  |
                                  +-- bit 1 = 1 --> _rhythm_event_sd_trigger --> adpcma_sample_sd --> ADPCM-A L ch
                                  |
                                  +-- bit 2-5 ---> silent ignore (= future drum 種拡張で literal branch 追加)
                                  |
                                  +-- bit 6-7 ---> reserved
                                  |
                                  +-- bitmap = 0x00 --> no-op
                                  |
                                  +-- bitmap = 0x03 (= BD+SD 同時) --> Step 13 scope-out (= bitmap OR semantics future)
```

### Step 12 path 維持原則

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) **不変**
- routine ABI **不変**
- routine 内部の bit 1 分岐は **追加** だが routine entry / 引数 / 戻り値 ABI は **不変**
- K-BD / R-BD path **完全不変** (= Step 12 fixture / verify / register write sequence 全て不変)
- PC trace + ymfm-trace 二段 gate 規律 **継続**
- PMDDotNET / `.MN` format **完全不変**
- driver-embedded fixture proof 規律 **継続**
- `.PNE` rhythm bank migration **future 維持**

### ADR-0026 §決定 6 / §決定 8 の literal 実装保証

「dispatch path は drum 種拡張で増やさない」 contract が Step 13 で **bit 0 BD + bit 1 SD の 2 drum 状況下で routine entry addr が変化しない** ことで literal 実装的に保証される。 future drum 種拡張 (= c/h/t/i) でも同じ entry addr を保持することを Step 13 で先取り保証する。

## sub-sprint 構造

ADR-0026 / ADR-0025 / ADR-0024 同 pattern 踏襲、 1 sub = 1 commit + 1 push 規律:

| sub | 内容 | driver 改修 | fixture 追加 | verify script 追加 | 一文要約 |
|---|---|---|---|---|---|
| ADR | 本 ADR 起票 Draft | なし | なし | なし | ADR-0027 Draft 起票 (= 11 決定 + scope-out 26+ 項目 + 5 段 gate + 完了判定 10 項目 + layering 図) |
| α | PMDDotNET SD emit 調査 + ADR Annex A literal 反映 | なし (= 完全不変) | なし | なし | mc.cs rhysel / rs00 周辺の SD emit 記号 + bitmap OR emit 動作 literal 確認、 fixture 命名修正可能性判断、 driver 完全不変純調査 |
| β | SD trigger 接続 + K-SD fixture + verify | bit 1 分岐追加 + SD sample pointer mapping | `k-sr-only.mml` | `verify-step13-sd-trigger.sh` | pmdneo_rhythm_event_trigger に bit 1 SD 分岐 + adpcma_sample_sd pointer mapping + K-SD fixture + sd-trigger verify、 全 step12 BD regression PASS |
| γ | R-SD fixture + differential verify 2 件 | なし (= commandsp 0xEB 既存接続を bit 1 でも通す、 既に β で対応済) | `r-melody-sr-only.mml` | `verify-step13-kr-sd-differential.sh` + `verify-step13-bd-sd-differential.sh` | R-SD fixture + K-SD vs R-SD differential + BD vs SD differential 2 script、 全 18-19 script regression PASS |
| δ | 完了統合 + ADR Accepted + handoff + memory | なし | なし | なし | ADR-0027 Accepted 移行 + 完了判定 literal 反映 + 全 script 最終 regression PASS + user 試聴 OK + handoff doc + memory + MEMORY.md index 更新 |

## Annex A: PMDDotNET SD emit 調査結果 (= 14th session α 調査、 driver / fixture / verify script 完全不変純調査)

### A-1: PMDDotNET `\` escape dispatch table literal 確認 (= mc.cs rcomtbl L9520-9546)

`vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` の `rcomtbl` (= `\` escape 命令 dispatch table) を直接確認:

```csharp
// mc.cs L9528-9533 (= rcomtbl 抜粋、 drum trigger 6 種)
,new Tuple<char, Func<enmPass2JumpTable>>('b', bdset)    // \b → BD
,new Tuple<char, Func<enmPass2JumpTable>>('s', snrset)   // \s → SD (= Step 13 対象)
,new Tuple<char, Func<enmPass2JumpTable>>('c', cymset)   // \c → CYM
,new Tuple<char, Func<enmPass2JumpTable>>('h', hihset)   // \h → HH
,new Tuple<char, Func<enmPass2JumpTable>>('t', tamset)   // \t → TOM (= TAM)
,new Tuple<char, Func<enmPass2JumpTable>>('i', rimset)   // \i → RIM (= `\r` ではない!)
```

#### 重要 finding (= ADR-0027 §決定 2 訂正項目)

PMDDotNET source の `rcomtbl` 6 文字目は **`i` → rimset** であり、 ADR-0026 Annex A L789 / ADR-0027 起票時に書いた「`r` = RIM」 は **誤記**。 正解は:

- **`r` は rest 専用** (= `\sr` の `r` は SD + rest の rest 部分、 RIM ではない)
- **`i` = RIM** (= `\i` で RIM trigger、 mc.cs L9533 literal)

ADR-0027 §決定 2 / §scope-out / §sub-sprint 構造表 の「c/h/t/r」 を「c/h/t/i」 に literal 訂正、 §決定 2 bitmap accept range の bit 5 注釈に「`\i`、 `\r` ではない」 を明記。 ADR-0026 Annex A の `\rr` (= RIM 表記) は Accepted 後の改訂対象外として本 ADR §Annex A-8 で literal 訂正記録のみ残置。

#### Step 13 SD 関連の確定

- **`\s` → snrset** (= mc.cs L9529 literal)
- snrset は `work.al = 2` を set して rs00 を呼ぶ (= L9697-9701)
- rs00 が `0xEB <al>` を emit (= L9727-9750)
- 結果 `\s` 単独で `0xEB 0x02` emit (= bitmap bit 1 = SD)
- **fixture 命名 `k-sr-only.mml` / `r-melody-sr-only.mml` の `sr` = `\s` + `r`(= rest) pattern は妥当**、 rename 不要

### A-2: PMDDotNET rs00 emit core path literal 確認 (= mc.cs L9691-9761)

drum 6 種 set 関数 → rs00 → `0xEB <bitmap>` emit:

```csharp
// mc.cs L9691-9725
private enmPass2JumpTable bdset()  { work.al = 1;  return rs00(); }  // BD  = bitmap 0x01
private enmPass2JumpTable snrset() { work.al = 2;  return rs00(); }  // SD  = bitmap 0x02
private enmPass2JumpTable cymset() { work.al = 4;  return rs00(); }  // CYM = bitmap 0x04
private enmPass2JumpTable hihset() { work.al = 8;  return rs00(); }  // HH  = bitmap 0x08
private enmPass2JumpTable tamset() { work.al = 16; return rs00(); }  // TOM = bitmap 0x10
private enmPass2JumpTable rimset() { work.al = 32; return rs00(); }  // RIM = bitmap 0x20
```

#### emit semantics literal (= mc.cs L9727-9755)

```csharp
// mc.cs rs00 抜粋 (= 簡略化)
private enmPass2JumpTable rs00() {
    if (mml_seg.skip_flag != 0) goto rs_skip;

    char ch = work.si < mml_seg.mml_buf.Length ? mml_seg.mml_buf[work.si] : (char)0x1a;
    if (ch != 'p') goto rs01;
    work.si++;
    work.al |= 0x80;  // bit 7 = 'p' (= note rest length flag)
    goto rs02;

rs01:
    // 直前 2 byte が 0xEB <bitmap> + bit 7 = 0 + prsok = 0x80 なら bitmap OR 圧縮
    var o = m_seg.m_buf.Get(work.di - 2);
    if (o == null) goto rs02;
    byte cch = (byte)m_seg.m_buf.Get(work.di - 2).dat;
    if (cch != 0xeb) goto rs02;
    cch = (byte)m_seg.m_buf.Get(work.di - 1).dat;
    if ((cch & 0x80) != 0) goto rs02;
    if (mml_seg.prsok != 0x80) goto rs02;  // 直前byte = リズム?
    work.al |= cch;                          // bitmap OR で結合
    m_seg.m_buf.Set(work.di - 1, new MmlDatum(work.al));  // di-1 上書き
    goto rsexit;

rs02:
    // 新規 rhykey opcode + bitmap byte を emit
    m_seg.m_buf.Set(work.di, new MmlDatum(0xeb));      // emit 0xEB
    m_seg.m_buf.Set(work.di + 1, new MmlDatum(work.al)); // emit bitmap
    work.di += 2;
    if ((work.al & 0x80) == 0) goto rsexit;
    return enmPass2JumpTable.olc0;

rsexit:
    mml_seg.prsok = 0x80;  // 直前byte = リズム marker set
    return enmPass2JumpTable.olc02;
}
```

#### SD 単独 emit (= Step 13 fixture 期待 bytecode)

- `\s` + `r`(= rest) → `\s` (= snrset) → al = 2 → rs00 → rs02 path (= 新規 emit) → `0xEB 0x02`
- 続く `r` (= rest) は別 opcode 経路で処理 (= note rest length emit)
- fixture `k-sr-only.mml` の K part body 期待 bytecode = `0xEB 0x02 <rest length> ... 0x80` (= part end)
- 同様に `r-melody-sr-only.mml` の melody part body = `... 0xEB 0x02 <rest length> ... 0x80`

#### Step 13 driver 側 bitmap accept range 設計確認

α 調査結果と ADR-0027 §決定 2 bitmap accept range が完全整合:

- bit 0 (= 0x01) = BD trigger (= 既存 Step 12 維持)
- bit 1 (= 0x02) = SD trigger (= 本 ADR で新規追加)
- bit 2 (= 0x04) = CYM trigger → silent ignore
- bit 3 (= 0x08) = HH trigger → silent ignore
- bit 4 (= 0x10) = TOM trigger → silent ignore
- bit 5 (= 0x20) = RIM trigger (= `\i`) → silent ignore
- bit 6 = (PMD V4.8s pattern body 内専用 flag) → silent ignore
- bit 7 = (note byte 識別 flag、 mc.cs 内 'p' marker) → silent ignore

driver は bit 0 + bit 1 のみ accept、 残り bit は silent ignore (= ADR-0026 §決定 11 「未対応 cmd スルー」 思想踏襲)。

### A-3: PMDDotNET bitmap OR 圧縮 emit 動作 literal 確認 (= mc.cs L9736-9746)

#### 連続 trigger の bitmap OR 圧縮 path (= rs01 path)

`\b\s` を間に何も挟まず連続記述した場合の emit 挙動:

1. 最初の `\b` を bdset 経由で処理 → al = 1 → rs00 → rs02 path → `0xEB 0x01` emit + di += 2 + prsok = 0x80 set
2. 次の `\s` を snrset 経由で処理 → al = 2 → rs00 → rs01 path check:
   - 直前 2 byte (= di-2) = `0xEB` ? → YES
   - di-1 byte = `0x01`、 bit 7 = 0 ? → YES
   - prsok = 0x80 (= 直前 byte = リズム) ? → YES
   - **3 条件全成立 → bitmap OR**
   - al |= cch (= 0x02 | 0x01 = 0x03)
   - m_seg.m_buf.Set(work.di - 1, new MmlDatum(0x03))  // di-1 を 0x03 で上書き
   - di は **増えない** (= 1 opcode に圧縮)
   - 結果 bytecode = `0xEB 0x03` (= BD+SD bitmap OR 1 opcode)

#### 連続 trigger 不成立 (= 別 opcode emit) の条件

以下のいずれかで rs01 → rs02 path (= 新規 0xEB <bitmap> emit) に分岐:

- 直前 2 byte が `0xEB <bitmap>` でない (= 間に note / 制御 cmd / その他 byte 挟まる)
- 直前 bitmap bit 7 = 1 (= 'p' marker、 note rest length 用)
- prsok != 0x80 (= 「直前 byte = リズム」 marker が消えている、 PMDDotNET 内 state 管理)

#### `\b c4 \s` 等で間が空く場合

- `\b` → `0xEB 0x01` emit + prsok = 0x80
- `c4` (= note) → 別経路で note emit、 **prsok が `c4` 処理中に clear される**
- `\s` → rs01 path で prsok != 0x80 → rs02 → `0xEB 0x02` 新規 emit
- 結果 bytecode = `0xEB 0x01 <note c4 bytes> 0xEB 0x02` (= 2 separate opcodes)

#### Step 13 fixture 設計への影響

Step 13 では BD+SD 同時打ち scope-out (= ADR-0027 §決定 11 / 軸 2):

- `k-sr-only.mml` K part body = `\s r` 単独パターンのみ (= `\b\s` 並記なし)
- `r-melody-sr-only.mml` melody part body = `\s r` 単独パターンのみ
- bitmap 0x03 (= BD+SD 同時) が emit される fixture は **生成しない**
- driver の bitmap accept range は bit 0 / bit 1 個別 accept (= 0x03 が来た場合、 仮に Step 13 driver が両 bit を見れば BD + SD 両方 trigger される可能性あり、 ただし Step 13 fixture では 0x03 emit 経路を踏まない)
- bitmap OR semantics の literal proof は Step 14 候補温存 (= ADR-0027 §決定 11 維持)

### A-4: PMD V4.8s manual literal 用例 (= `docs/manual/PMDMML_MAN_V48s_utf8.txt`)

#### drum trigger 用例 (= L226-228)

```
R0	l16[\sr]4
R1	l8 \br\hr\sr\hr
R2	   \br\tr\tr\tr
```

- L226 `\sr` = SD + rest (= 16 分音符 4 個列)
- L227 `\br\hr\sr\hr` = BD + rest, HH + rest, SD + rest, HH + rest (= 8 分音符 4 個列、 BD+HH ペア)
- L228 `\br\tr\tr\tr` = BD + rest, TOM + rest, TOM + rest, TOM + rest

#### RIM 表記の manual 内不在確認

manual 全文 grep で `\r` を drum trigger として使う用例は **不在** (= `\sr` / `\br` / `\hr` / `\tr` のみ確認)。 manual L2071 `@32 Rim Shot` は OPNA rhythm bank instrument 名 (= rs00 emit 経路と無関係) であり、 RIM trigger の MML 記号としての `\i` 表記は manual 例には出てこないが、 PMDDotNET mc.cs L9533 literal で「`'i' → rimset`」 が確定。

manual と PMDDotNET source の整合性 = manual 例に `\i` が不在で source に `\i` が存在することは、 manual が drum trigger 6 種全例を網羅していない (= 例題が `\br/\sr/\hr/\tr` の頻出 4 種のみで `\cr/\ir` 例が省略) ことを示すと解釈。 ADR-0027 §決定 2 / §Annex A-1 で PMDDotNET source literal を基準とする。

### A-5: rhysel と rs00 の dispatch 分離 (= 別 cmd 経路)

mc.cs L9668 `rhysel()` と L9727 `rs00()` は **別の cmd 経路** であることを literal 確認。 ADR-0026 Annex A で混同された可能性を本 ADR で整理:

#### `rhysel` (= L9668-9689) の正体

- 呼出元: `rpanset` (= L9661、 0xe9 opcode emit)
- 入力: drum 識別文字 (= `b/s/c/h/t/i` 6 文字判定)
- 出力: bx / al の bit pattern 加工 (= 5 bit shift)
- 用途: `0xe9` (= rpanset / panrig / panset 経由、 OPNA rhythm pan 設定 cmd) の drum 種選択
- PMDDotNET MML 表記: `R p<drum><value>` 等 (= panset / panrig 経由、 user 用 inline pan 設定)
- **Step 13 関係なし** (= rpanset = OPNA rhythm pan 設定は Step 13 scope-out)

#### `rs00` (= L9727-9761) の正体

- 呼出元: bdset / snrset / cymset / hihset / tamset / rimset (= L9691-9725 6 関数)
- 入力: al (= bitmap bit position pre-set = 1/2/4/8/16/32)
- 出力: `0xEB <bitmap>` 2-byte emit (= rs02 path) or bitmap OR 圧縮 (= rs01 path)
- 用途: drum trigger 6 種共通 emit core
- PMDDotNET MML 表記: `\b / \s / \c / \h / \t / \i` (+ optional `r`(rest) 続き)
- **Step 13 関係あり** (= `\s` SD trigger の emit path)

#### Step 13 driver normalize 入口

driver `.MN` direct parser での bitmap accept range 拡張 (= ADR-0027 §決定 4) は **rs00 emit 経路の 0xEB <bitmap>** に対する driver 側 dispatch のみ。 rhysel 経路 (= 0xe9 rpanset) は **silent ignore** (= ADR-0026 §決定 11 / 本 ADR §決定 11 「未対応 cmd スルー」 思想踏襲)。

### A-6: `adpcma_sample_sd` driver-embedded 状況 literal 確認 (= standalone_test.s)

#### sample pointer table 内 reference

```asm
; standalone_test.s L2871-2873 (= table A、 既存 Step 5 から不変)
adpcma_ch_sample_ptr_table:
        .dw     adpcma_sample_bd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top
```

- L = `adpcma_sample_bd` / M = `adpcma_sample_sd` / N = `adpcma_sample_hh` / O = `adpcma_sample_tom` / P = `adpcma_sample_rim` / Q = `adpcma_sample_top`
- L-Q ADPCM-A 6ch melody architecture 用 sample pointer table
- ADR-0019 §決定 3 build-time embed 流儀

#### `adpcma_sample_sd` literal embed (= L2895-2896)

```asm
; standalone_test.s L2893-2904
adpcma_sample_bd:
        .db     BD_START_LSB, BD_START_MSB, BD_STOP_LSB, BD_STOP_MSB
adpcma_sample_sd:
        .db     SD_START_LSB, SD_START_MSB, SD_STOP_LSB, SD_STOP_MSB
adpcma_sample_hh:
        .db     HH_START_LSB, HH_START_MSB, HH_STOP_LSB, HH_STOP_MSB
adpcma_sample_rim:
        .db     RIM_START_LSB, RIM_START_MSB, RIM_STOP_LSB, RIM_STOP_MSB
adpcma_sample_tom:
        .db     TOM_START_LSB, TOM_START_MSB, TOM_STOP_LSB, TOM_STOP_MSB
adpcma_sample_top:
        .db     TOP_START_LSB, TOP_START_MSB, TOP_STOP_LSB, TOP_STOP_MSB
```

- `adpcma_sample_sd` = 4 byte sample header (= start LSB/MSB + stop LSB/MSB)
- VROM 内 SD sample 実 data の addr 値は `SD_START_LSB` / `SD_START_MSB` / `SD_STOP_LSB` / `SD_STOP_MSB` macro で literal 定義 (= samples.inc 等の上位 include で確定、 ADR-0019 §決定 3 build-time embed)
- ADPCM-A subsystem 内既存 sample、 Step 13 で再利用可能

#### ADR-0025 step 11 multi-table B 内 reference (= L2889-2891)

```asm
adpcma_ch_sample_ptr_table_b:
        .dw     adpcma_sample_sd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top
```

- table B の L slot に `adpcma_sample_sd` を swap (= ADR-0025 step 11 multi-table id=0x01 proof で L ch BD → SD 差替)
- 既に SD sample が multi-table proof 経路で literal reuse 済
- Step 13 で新規 embed 不要、 既存 symbol 参照のみで bit 1 → `adpcma_sample_sd` mapping 成立

### A-7: bit 1 SD 分岐追加の literal asm 候補 (= β 着手前、 explicit if/jr 流儀)

#### 既存 `pmdneo_rhythm_event_trigger` routine 構造 (= Step 12 β commit 309c011)

```asm
; standalone_test.s 内 想定 既存 (= Step 12 β/γ 確立後)
pmdneo_rhythm_event_trigger:
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD のみ accept (= Step 12 b-only proof)
    bit 0, a
    ret z
    ; BD trigger 処理 (= adpcma_sample_bd を L ch に register write)
    ...
    ret
```

(= 実 literal asm は β commit 着手時に Read で確認、 ADR-0027 Annex A は概念図のみ)

#### Step 13 β で追加する bit 1 分岐 (= explicit if/jr 流儀踏襲)

```asm
; standalone_test.s β commit で導入予定
pmdneo_rhythm_event_trigger:
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 2-5 = silent ignore
    push    af
    bit     0, a
    jr      z, _rhythm_event_no_bd
    call    _rhythm_event_bd_trigger
_rhythm_event_no_bd:
    pop     af
    push    af
    bit     1, a
    jr      z, _rhythm_event_no_sd
    call    _rhythm_event_sd_trigger
_rhythm_event_no_sd:
    pop     af
    ret

_rhythm_event_bd_trigger:
    ; adpcma_sample_bd を ADPCM-A L ch に register write (= Step 12 既存実装)
    ...
    ret

_rhythm_event_sd_trigger:
    ; adpcma_sample_sd を ADPCM-A L ch に register write (= Step 13 新規実装)
    ld      hl, #adpcma_sample_sd
    ; ... reg 0x10 / 0x18 / 0x20 / 0x28 / 0x08 / 0x00 keyon mask 0x01 write
    ret
```

#### Step 13 β commit 実装方針

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は **不変保持** (= ADR-0027 §決定 9 維持)
- routine 内部の bit 0 BD 分岐は **完全不変** (= Step 12 既存 BD path regression 維持、 ADR-0027 §決定 7)
- bit 1 SD 分岐は bit 0 分岐の **直後** に追加 (= explicit if/jr 流儀踏襲、 ADR-0024 / 0025 / 0026 同 pattern)
- `_rhythm_event_sd_trigger` label 新規追加 (= BD trigger と同 register write sequence で sample addr のみ `adpcma_sample_sd` 参照)
- ABI 不変 (= 引数 = a レジスタ bitmap、 戻り値 = なし、 caller 不変)

#### dispatch path 1 本化の literal 維持確認

- K-BD / R-BD / K-SD / R-SD 全 fixture で PC trace hit addr = 0x1126 (= entry 不変、 ADR-0027 §決定 1 / §決定 4 / §決定 9 維持)
- routine 内部の bit 1 分岐追加は **internal implementation 拡張** であって dispatch path 新設ではない (= ADR-0026 §決定 6 / ADR-0027 §決定 8 維持)

### A-8: ADR-0026 Annex A 誤記訂正 (= literal 訂正記録、 ADR-0026 file は改訂しない)

#### ADR-0026 Annex A L789 の `\rr` 表記

ADR-0026 Annex A A-2 「PMDDotNET bitmap bit field」 table 内に literal 記述:

```
| 5 | RIM (リム) | `\rr` | 0x1D / KEYON 0x20 | future sub-sprint |
```

#### 訂正内容 (= ADR-0027 §Annex A-1 で literal 確認)

- PMDDotNET mc.cs L9533 literal: `'i' → rimset` (= 6 文字目は `i`、 `r` ではない)
- manual L226-228 で `\r` 表記の RIM 用例は不在
- 正しい表記は **`\ir`** (= `\i` + `r`(rest)) or **`\i`** 単独 (= rest 不要時)
- ADR-0026 Annex A の `\rr` は誤記

#### ADR-0026 file への対応

ADR-0026 は既に Accepted 状態 (= 2026-05-14 13th session δ で migrate 済) であり、 Accepted 後の literal 訂正範囲外。 本 ADR §Annex A-8 で訂正記録のみ残置:

- ADR-0026 §決定 5 「drum kind = b only」 自体は誤りなし (= b 識別文字は確定)
- ADR-0026 Annex A A-2 table の `\rr` 表記のみ誤記
- future contributor 向け参照軸として本 ADR §Annex A-1 / §Annex A-8 を参照
- ADR-0026 file 本体は **改訂しない** (= ADR 改訂規律踏襲、 ADR-0027 で literal 訂正記録)

### A-9: fail-safe 条件 evaluate (= β 進行可判定)

#### 条件 1: 「PMDDotNET SD emit 記号が `\s` でない」

α 調査結果: **`\s` で確定** (= mc.cs L9529 literal `'s' → snrset`、 §Annex A-1 参照)。

- 条件不成立 (= fail-safe 該当せず)
- fixture 命名 `k-sr-only.mml` / `r-melody-sr-only.mml` の `sr` = `\s` + `r`(rest) pattern は妥当
- rename 不要

#### 条件 2: 「`adpcma_sample_sd` が ADPCM-A subsystem 内に embed されていない」

α 調査結果: **embed 済** (= standalone_test.s L2895 literal、 §Annex A-6 参照)。

- 条件不成立 (= fail-safe 該当せず)
- ADR-0025 step 11 で multi-table B 内に再利用済、 Step 13 で新規 embed 不要

#### 条件 3 (= 本 ADR α で発見された追加軸): 「`r` = RIM 誤記が driver 実装に影響するか」

α 調査結果: **影響なし** (= ADR-0026 / ADR-0027 起票時の文書誤記であり、 driver 実装の bit 5 silent ignore 規律は不変)。

- ADR-0027 §決定 2 訂正 (= `c/h/t/r` → `c/h/t/i`、 bit 5 注釈に `\i` 明記) で文書 literal を実装と一致させた
- driver は bit 0 + bit 1 のみ accept、 bit 2-5 silent ignore で contract 維持
- fail-safe 該当せず

#### β 進行判定

3 条件いずれにも該当せず、 **β 進行可**。

β commit 内容 (= ADR-0027 §sub-sprint 構造表):

- `pmdneo_rhythm_event_trigger` routine に bit 1 SD 分岐追加 (= §Annex A-7 asm 候補)
- `_rhythm_event_sd_trigger` label 新規 (= `adpcma_sample_sd` literal addr 参照)
- `k-sr-only.mml` fixture 新規追加 (= K part `\s` + `r` pattern)
- `verify-step13-sd-trigger.sh` 新規追加 (= K-SD register write trace + keyon count + PC marker @ 0x1126)
- 全 step12 BD path regression PASS 維持 (= ADR-0027 §決定 7)

α 完了 (= driver / fixture / verify script 完全不変純調査、 ADR-0027 §Annex A 9 sub-section literal 反映、 1 commit + 1 push)。

## 関連

- ADR-0026 (= step 12 K/R rhythm compatibility proof)
- ADR-0025 (= step 11 multi-table id=0x01 proof)
- ADR-0024 (= step 10 sample_table_id selection consumption)
- ADR-0019 (= step 5 §決定 3 sample addr build-time embed)
- ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive)
- `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- memory `project-pmdneo-step12-complete`
- memory `project-pmdneo-step13-direction-sd-expansion`
- memory `project-pmdneo-adpcma-subsystem-boundary`
- memory `feedback-audio-gate-solo-isolation`
- memory `feedback-verify-script-serial-execution`
- memory `feedback-refactor-gate-register-trace-not-wav`
- memory `feedback-push-per-commit`
- memory `feedback-post-commit-push-report-format`
- memory `feedback-explain-in-plain-japanese-before-commit`
