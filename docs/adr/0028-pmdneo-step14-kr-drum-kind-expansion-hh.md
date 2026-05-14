# ADR-0028: Step 14 — K/R drum kind expansion proof (h = HH single-kind / dispatch path 1 本化不変 / 既存 adpcma_sample_hh symbol reuse / BD+SD fixture 不変 + HH fixture 2 件新規 / 3 軸 verify)

- 状態: **Draft** (= 2026-05-14 15th session 冒頭起票、 α/β/γ/δ 4 commit chain で Accepted 移行予定、 δ 完了時に 14 commit chain 完成 + 全 23-25 script regression PASS + user audio gate OK 確認後 Accepted 化)
- 起票日: 2026-05-14
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0027 (= step 13 K/R drum kind expansion proof — s = SD、 §決定 8 「dispatch path は drum 種拡張で増やさない」 + §決定 2 「b+s proof」 + §scope-out 「c/h/t/i 残り 4 種」 を本 ADR で 1 軸消化、 §Annex A-1 で `'h' → hihset` literal 確認済 + §Annex A-2 で `hihset` = `work.al = 8; return rs00();` literal 確認済 + §Annex A-6 で `adpcma_sample_hh` standalone_test.s L2895-2904 内 embed 済 literal 確認済)、 ADR-0026 (= step 12 K/R rhythm compatibility proof、 §決定 6 「dispatch path 1 本化」)、 ADR-0025 (= step 11 multi-table id=0x01 proof、 §決定 1 A2 cache scope-out 維持)、 ADR-0024 (= step 10 sample_table_id selection consumption、 explicit if/jr 流儀踏襲)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 §決定 4 sample 増加は別 sprint 接続点予約)、 ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive → step 12 で reconnected → step 13 で b+s → 本 ADR で b+s+h drum kind 1 軸拡張)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様、 drum 識別文字 = `b/s/c/h/t/i` 6 種 = PMDDotNET mc.cs rcomtbl L9528-9533 literal、 manual L227 `\hr` literal 用例、 本 ADR §Annex A-4 で literal 引用)

## 背景

Step 13 (= ADR-0027 Accepted、 2026-05-14 14th session、 commit `3c64cd2`) で K/R drum kind expansion proof — s = SD sprint が成立した。 driver は PMD V4.8s 系 K part `\s` + melody part inline `\s` の 2 系統 MML syntax を、 PMDDotNET `0xEB 0x02` bytecode を経て driver `.MN` direct parser で normalize し、 `pmdneo_rhythm_event_trigger` (@ 0x1126) entry addr 不変を維持しつつ routine 内部の bit 1 SD 分岐 + 独立 sub-routine `_rhythm_event_sd_trigger` (@ 0x115F) で `adpcma_sample_sd` を ADPCM-A L ch に register write する contract chain を、 PC trace + ymfm-trace 二段 gate + byte-identical literal proof + BD/SD sample addr literal differ で literal 観測可能にした。

ADR-0027 §決定 2 で確立した「drum kind = b + s proof」 と、 §決定 8 で確立した「**dispatch path は drum 種拡張で増やさない**」 という 2 つの contract に対し、 Step 14 はその **自然な 1 軸拡張** を担う:

- 「**drum 種を b + s (= BD + SD only) から b + s + h (= HH 追加、 計 3 drum) に 1 軸拡張**」
- 「**dispatch path は不変 (= `pmdneo_rhythm_event_trigger` @ 0x1126 entry addr 継続)**」 → ADR-0027 §決定 8 が 3 drum 状況下で literal 維持されることの proof
- 「**sample pointer mapping のみ拡張**」 (= bit 0 → BD addr / bit 1 → SD addr / bit 3 → HH addr、 bit 2/4/5 silent ignore 維持)

ADR-0027 §決定 8 (= drum 種拡張で dispatch path 不変) と §決定 11 (= scope-out 27+ 項目維持) の延長で、 K/R semantics の MML 互換 surface area を **drum kind 軸 1 段** だけ広げる小規模 proof sprint。 「drum kind expansion proof」 という言葉自体が示すように、 sample asset 軸 / channel 軸 / runtime parser 軸 / dispatch refactor 軸 / simultaneous trigger 軸は触らない。

ただし「drum kind expansion」 と素朴に定義すると scope が再び肥大化する (= 全 4 残 drum 一気 / BD+SD+HH 同時打ち bitmap OR semantics / channel allocation 改定 / `.PNE` rhythm bank migration / 制御 cmd 現役化 / dispatch table-driven 化 等を同時に触る)。 14th session 末 user 直接指示 + 15th session 冒頭壁打ち で以下の方針整理が確定:

- **drum 種拡張軸 = bit 3 HH のみ accept** (= 残 3 drum 一気は scope-out、 c/t/i 残り 3 種 future) (= 軸 1)
- **BD+SD / BD+HH / BD+SD+HH 同時打ち scope-out** (= bitmap OR semantics literal proof は future 候補温存) (= 軸 4)
- **HH sample source = existing `adpcma_sample_hh` symbol reuse as driver-embedded proof fixture** (= ADR-0027 §決定 3 SD = 既存再利用 pattern 踏襲、 L-Q melody architecture N ch sample と同 symbol を rhythm proof で再利用、 final rhythm sample ownership は未確定) (= 軸 1)
- **fixture = `k-hr-only.mml` + `r-melody-hr-only.mml` 2 件新規 + BD/SD fixture 完全不変** (= 6 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH、 命名 = `\h` + `r`(= rest) pattern、 HH 略称ではない) (= 軸 2)
- **verify gate = 3 軸** (= HH trigger 単独 + K-HH vs R-HH differential + BD vs HH differential、 keyon count identical + PC marker hit + ymfm-trace literal register value assert、 ADR-0027 §verify gate pattern 踏襲) (= 軸 5)
- **dispatch 構造 = hybrid (= Step 13 sub-routine pattern 踏襲 + _rhythm_event_hh_trigger 独立 sub-routine 追加 + table-driven refactor は scope-out)** (= 軸 5)

これに基づき Step 14 を **「K/R drum kind expansion proof — h = HH」** として定義する。 ADR-0027 dispatch path 1 本化を **3 drum 状況下で literal 維持** することの proof であり、 「dispatch path は drum 種拡張で増やさない」 が Step 14 で実装的に保証される最小成立形 (= 3 drum 段) である。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 Step 14 着手前に方針を ADR として独立起票する。

### 15th session 冒頭壁打ちでの 5 軸方針確定

ADR-0028 起票前に user 主導で 5 軸 + 軸 6 (= HH symbol 取り扱い) の壁打ちが行われ、 Step 14 の出口像が以下に固定された (= 軸 1-5 は ADR-0027 と同 pattern、 軸 6 は ADR-0027 §決定 3 SD = 既存再利用 pattern との整合確認)。

**軸 1: HH 追加 = bit 3 のみ accept**

drum 種拡張方針:

- (e1) (= 不採用): 残 4 drum 一気 (= bit 2 CYM / bit 3 HH / bit 4 TOM / bit 5 RIM 同時実装)
- (e2) (= **採用**): HH 単独拡張 (= bit 3 のみ accept、 c/t/i 残り 3 種 future)
- (e3) (= 不採用): drum 種ではなく simultaneous trigger / velocity / volume 軸拡張先行

(e2) 採用根拠: ADR-0027 b+s proof と同じ proof 最小性、 dispatch path 1 本化が 3 drum 状況下で literal 維持されることの proof は **1 軸拡張で十分**、 残 4 drum 一気は fixture / verify / sample addr mapping を同時拡張で scope 肥大化、 PMD V4.8s K part 文法的に b/s/h は最頻出 (= BD+SD+HH の 3 種が pop / rock 基本 pattern)、 HH は ADR-0025 step5b で ADPCM-A subsystem 内に既に embed 済 (= `adpcma_sample_hh`、 L-Q melody N ch sample と share、 rhythm proof 用に reuse 可能)。

ADR / handoff 記載要件:
- Step 14 drum 種 = **bit 0 BD + bit 1 SD + bit 3 HH のみ accept**
- bit 2 (= CYM) / bit 4 (= TOM) / bit 5 (= RIM、 `\i` で trigger) は **silent ignore** (= ADR-0026 §決定 11 / ADR-0027 §決定 2 「未対応 cmd スルー」 思想踏襲)
- 残り 3 種拡張は **future sub-sprint** (= Step 15 候補温存)
- dispatch path は drum 種拡張で **増やさない** (= ADR-0026 §決定 6 / ADR-0027 §決定 8 維持、 本 ADR §決定 8 で 3 drum 段で再確認)

**軸 2: fixture 体制 = BD/SD fixture 完全不変 + HH fixture 2 件新規 (= 15th session 冒頭確定)**

K-HH / R-HH fixture 取り扱い:

- (fix1) (= **採用**): 6 fixture 体制 (= 既存 `k-br-only.mml` + `r-melody-br-only.mml` + `k-sr-only.mml` + `r-melody-sr-only.mml` 完全不変 + `k-hr-only.mml` + `r-melody-hr-only.mml` 新規追加)
- (fix2) (= 不採用): 4 fixture 維持 (= 既存 SD fixture を HH 版に置換、 SD regression script が消失)
- (fix3) (= 不採用): BD/SD/HH 3-way 単一 fixture (= K-R differential verify がやりにくい + simultaneous trigger との境界が曖昧化)
- (fix4) (= 不採用): K-HH のみ (= R-HH 省略、 K-R dispatch shared invariant が HH で verify されない)

(fix1) 採用根拠: Step 12 BD proof + Step 13 SD proof を regression として残せる、 Step 14 HH proof を独立追加できる、 BD/SD path を壊していないことを継続確認できる (= 「動いているものを壊さない」 規律遵守)、 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH の 6 fixture 体制が読みやすい、 BD+SD+HH 同時打ち scope-out 前提で単一 fixture に混ぜない方が良い。

命名規則:

- `k-hr-only.mml` (= K part 内 `\h` + `r`(= rest)、 既存 `k-br-only.mml` / `k-sr-only.mml` と 1 文字違い)
- `r-melody-hr-only.mml` (= melody part L 内 inline `\h` + `r`(= rest)、 既存 `r-melody-br-only.mml` / `r-melody-sr-only.mml` と 1 文字違い)
- `hr` の `h` = `\h` (= HH trigger 識別文字) + `r` = rest 専用文字 (= ADR-0027 §Annex A-1 で literal 確認、 RIM ではない)
- `hr` は **「hi-hat」 略ではない** (= 既存 `br` / `sr` と同 命名 pattern、 drum 略称命名 ではなく fixture pattern 命名 = `\<drum 識別文字>` + `r`(rest))

ADR / handoff 記載要件:
- BD/SD fixture (= `k-br-only.mml` / `r-melody-br-only.mml` / `k-sr-only.mml` / `r-melody-sr-only.mml`) は **完全不変**
- HH fixture 2 件 (= `k-hr-only.mml` / `r-melody-hr-only.mml`) を新規追加
- fixture 名の `hr` は **`\h` + `r`(rest) fixture pattern** であり「hi-hat」 略ではない (= 既存 `br` / `sr` pattern と統一、 future contributor 向け literal 注記、 ADR + handoff doc 必須記載)
- α 調査で PMDDotNET が HH を `\h` として emit することを literal 確認 (= ADR-0027 §Annex A-1 / §Annex A-2 で既に literal 確認済、 α 調査で再確認 + Annex A 反映)
- BD/SD/HH 3-way 差分は verify script で literal に確認 (= BD vs HH differential 1 script、 SD vs HH differential は scope-out)

**軸 3 (実質): bit 3 mapping = bit 0 BD + bit 1 SD + bit 3 HH accept、 bit 2/4/5 silent ignore**

軸 1 回答内で確定済の bit mapping:

- bit 0 = BD trigger (= 既存 ADR-0026 維持)
- bit 1 = SD trigger (= 既存 ADR-0027 維持)
- bit 3 = HH trigger (= 本 ADR で新規追加)
- bit 2 (= CYM、 `\c`) / bit 4 (= TOM、 `\t`) / bit 5 (= RIM、 `\i` で trigger、 `\r` ではない) → silent ignore
- bit 6-7 = reserved
- bitmap = 0x00 = no-op
- bitmap = 0x03 / 0x09 / 0x0A / 0x0B (= BD+SD / BD+HH / SD+HH / BD+SD+HH 同時打ち) → bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4、 動作は α 調査で literal 確認 + Annex A 反映、 Step 14 fixture では生成しない)

**軸 4 (実質): simultaneous trigger scope-out 維持**

軸 1 回答内で確定済の simultaneous trigger:

- BD+SD / BD+HH / SD+HH / BD+SD+HH 同時打ち = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 15+ 候補)
- Step 14 fixture は **BD 単独 / SD 単独 / HH 単独 のみ**

**軸 5: verify gate = 3 軸 + dispatch 構造 = hybrid (sub-routine pattern 踏襲 + table-driven scope-out)**

verify 範囲:

- (v1) (= **採用**): 3 軸 verify (= HH trigger 単独 + K-HH vs R-HH differential + BD vs HH differential)
- (v2) (= 不採用): ADR-0027 pattern 踏襲 2 軸 (= HH trigger 単独 + K-HH vs R-HH differential)
- (v3) (= 不採用): HH trigger 単独のみ 1 軸 minimalist
- (v4) (= 不採用): BD/SD/HH 3-way differential 1 script (= sample addr 3-way differ proof、 ただし fixture 数 5+ で audio gate 複雑化 + simultaneous trigger との境界曖昧化)

(v1) 採用根拠: Step 14 目的は「HH が鳴る」 だけではなく drum kind expansion proof、 K と R が同じ HH dispatch path を通ることを確認する必要がある (= dispatch path 1 本化の 3 drum 状況下での維持)、 BD と HH が register / sample address 上で区別できる必要がある (= drum kind mapping の literal proof)、 BD/SD path regression も同時に守れる、 silent path に倒れただけではないことを確認できる。

dispatch 構造:

- (d1) (= **採用**): hybrid = Step 13 sub-routine pattern 踏襲 + `_rhythm_event_hh_trigger` 独立 sub-routine 追加 + table-driven refactor は scope-out
- (d2) (= 不採用): table-driven (= bit → sample addr lookup table に集約、 dispatch path + sub-routine も 1 本に帰結)
- (d3) (= 不採用): Step 13 sub-routine pattern 踏襲のみ、 future refactor 言及なし

(d1) 採用根拠: Step 14 目的は「h = HH expansion proof」、 ここで table-driven 化すると drum 種追加 proof と dispatch refactor が混ざる、 Step 13 と同型にすることで BD/SD/HH の differential proof が読みやすい、 c/t/i を足し終わった後に table-driven 化する方が判断材料が揃う、 dispatch path 不変の本質は entry point と runtime event path が増えないことなので内部 sub-routine 追加は許容、 `pmdneo_rhythm_event_trigger` entry addr 不変が primary invariant、 `_rhythm_event_hh_trigger` は proof 用 explicit branch (= future table-driven 化対象)、 full drum set 到達後 (= b/s/c/h/t/i 6 drum) に table-driven refactor を検討。

verify gate 構成:

```
K-HH:
  bit3 → HH trigger (= ADPCM-A L ch HH register write trace + keyon count + PC marker)

R-HH:
  bit3 → 同じ HH trigger (= K-HH vs R-HH byte-identical literal proof + PC marker)

BD vs HH:
  bit0 と bit3 で sample addr が違う (= reg 0x10 sample addr literal differ + reg 0x18 sample end addr literal differ)
```

加えて (= ADR-0027 §verify gate 規律踏襲):

- **keyon count identical** (= K-HH と R-HH で ADPCM-A L ch keyon mask 0x01 trigger count 同一)
- **PC marker hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126 PC trace hit、 K-HH / R-HH 両方で同 addr hit)
- **ymfm-trace literal register value assert** (= sample addr reg 値を literal 数値で assert、 visual diff ではなく数値 assert)

ADR / handoff 記載要件:
- verify gate は **3 軸 (= HH trigger + K-HH vs R-HH differential + BD vs HH differential)**
- 3 件の verify script を新規追加
- `verify-step14-hh-trigger.sh` (= K-HH / R-HH 各 fixture で HH register write trace + keyon count + PC marker)
- `verify-step14-kr-hh-differential.sh` (= K-HH vs R-HH byte-identical literal proof)
- `verify-step14-bd-hh-differential.sh` (= BD vs HH sample addr literal differ proof)
- 既存 20 script regression に 3 件追加 = 23 script 体制
- dispatch 構造 = **hybrid** (= Step 13 sub-routine pattern 踏襲 + `_rhythm_event_hh_trigger` 独立 sub-routine 追加 + table-driven refactor は future scope-out)

**軸 6: HH symbol = existing `adpcma_sample_hh` symbol reuse as driver-embedded proof fixture (= 15th session 冒頭確認)**

HH trigger で使う sample symbol:

- (hh_s1) (= **採用**): existing `adpcma_sample_hh` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 pattern 踏襲、 melody architecture N ch sample symbol と現段階で共有、 rhythm-dedicated symbol 分離は scope-out)
- (hh_s2) (= 不採用): rhythm-dedicated new symbol 分離 (= `adpcma_sample_hh_rhythm` 等、 同 VROM data 共有でも symbol 分離、 rhythm vs melody semantics separation 明示化、 ただし ADR-0027 SD pattern と inconsistent で SD も遡って分離議論必要化 + scope 肥大化)
- (hh_s3) (= 不採用): 完全新規 sample data + symbol を VROM に追加 (= BD/SD/HH 音の区別最強だが VROM 容量増 + samples.inc 拡張 + ADPCM-A converter 走らせる手間 + ADR-0027 SD pattern inconsistent)

(hh_s1) 採用根拠: Step 14 目的は drum kind expansion proof で sample source proof / symbol separation proof ではない、 既存 `adpcma_sample_hh` は ADR-0025 step5b で ADPCM-A subsystem 内に embed 済で再利用可、 ADR-0027 §決定 3 SD pattern 踏襲で consistency 維持、 BD/SD/HH 3 symbol 間で literal addr differ が既に確保される (= bd / sd / hh 3 symbol それぞれ違う sample header literal addr)、 rhythm-dedicated symbol 分離は SD も遡って議論必要化で scope 肥大化、 driver サイズ / VROM / asset pipeline 不変、 melody N ch と share 状態だが rhythm 側で読まれるタイミングと collision しない限り実際響く (= L slot に rhythm trigger 経由で書込み、 N slot melody 側との同時 read は別 ch 軸)、 final rhythm sample ownership は未確定で `.PNE` rhythm bank migration を future に温存。

ADR / handoff 記載要件:
- HH sample source = **existing `adpcma_sample_hh` symbol reuse as driver-embedded proof fixture**
- 新規 rhythm-dedicated symbol 分離 = **scope-out** (= ADR-0027 SD pattern との consistency 維持)
- 新規 sample import = **scope-out**
- `.PNE` rhythm bank migration = **future** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 future migration path 継続)
- Step 14 は **drum kind expansion proof**、 sample source proof / symbol separation proof ではない
- bit 0 → `adpcma_sample_bd` / bit 1 → `adpcma_sample_sd` / bit 3 → `adpcma_sample_hh` の mapping を driver source 内に literal 配置
- melody sample symbol (= L-Q architecture N ch) と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

## 決定

### 決定 1: Step 14 を「K/R drum kind expansion proof — h = HH」 として定義 (= bit 3 HH 1 軸拡張、 dispatch path 1 本化不変、 既存 adpcma_sample_hh symbol reuse、 BD/SD fixture 不変 + HH fixture 2 件新規、 3 軸 verify、 hybrid dispatch 構造)

Step 14 の最終 deliverable boundary を **「K part `\h` + melody part inline `\h` の 2 系統 MML syntax を受取り、 driver `.MN` direct parser で normalize して、 共通 routine `pmdneo_rhythm_event_trigger` 経由で bit 3 分岐 → `_rhythm_event_hh_trigger` sub-routine → 既存 `adpcma_sample_hh` symbol reuse → ADPCM-A L ch HH trigger に audible に dispatch する」** とする。 PMDDotNET / `.MN` format / `pmdneo_rhythm_event_trigger` routine entry / observability marker / driver-embedded fixture 規律は完全不変、 drum 種 → sample pointer mapping table のみ bit 0 → BD + bit 1 → SD + bit 3 → HH に 1 軸拡張、 PC trace + ymfm-trace の 3 軸 gate (= HH trigger + K-HH vs R-HH differential + BD vs HH differential) で **drum kind expansion 後 (= 3 drum 段) も dispatch path が 1 本化されていること** + **drum 種で sample addr が literal 区別されること** を literal 観測可能にすることを目的とする。

#### Step 13 → Step 14 拡張点

ADR-0027 で確立した contract のうち、 Step 14 で **拡張** されるのは:

- driver の K/R 受入 drum 種範囲: b + s (= BD + SD) → b + s + h (= BD + SD + HH)
- driver-embedded sample 表 entry 数: BD + SD 2 種 → BD + SD + HH 3 種 (= 既存 `adpcma_sample_hh` symbol reuse、 新規 embed なし)
- drum 種 → sample pointer mapping: bit 0 + bit 1 → bit 0 + bit 1 + bit 3
- fixture 数: K-BD + R-BD + K-SD + R-SD = 4 件 → K-BD + R-BD + K-SD + R-SD + K-HH + R-HH = 6 件
- verify script 数: step12 系 4 件 + step13 系 3 件 = 7 件 → step12 系 4 件 + step13 系 3 件 + step14 系 3 件 = 10 件
- 全 regression script 数: 20 件 → 23 件 (= step12 / step13 既存 + step14 新規 3 件)
- driver sub-routine 数: bit 0 BD + bit 1 SD 2 sub-routine → bit 0 BD + bit 1 SD + bit 3 HH 3 sub-routine

Step 14 で **不変** に保つもの:

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126、 ADR-0027 §決定 9 PC marker 維持)
- `pmdneo_rhythm_event_trigger` routine 構造 (= bit 0 / bit 1 分岐既存、 bit 3 分岐を新規追加するが routine entry / 引数 / 戻り値 ABI は不変)
- `_rhythm_event_bd_trigger` sub-routine (= Step 12 既存、 完全不変)
- `_rhythm_event_sd_trigger` sub-routine (= Step 13 既存 @ 0x115F、 完全不変)
- PMDDotNET (= C# compile path) は完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 維持)
- `.MN` format は完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う、 ADR-0026 §決定 10 / ADR-0027 §決定 10 維持)
- 既存 L-Q ADPCM-A melody architecture (= ADR-0019 / ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 / ADR-0025 で確立)
- selected pointer runtime state cache 不採用 (= ADR-0024 §決定 6 / ADR-0025 §決定 1 / ADR-0026 §決定 11 / ADR-0027 §決定 1 維持)
- `sample_table_id` resolver / selector の ABI (= Step 9-11 で確立)
- sentinel pointer 0x0000 silent semantics
- driver SRAM layout (= 0xFD20-0xFD32 既存領域、 Step 14 で新規 marker byte を追加しない)
- multi-table id=0x01 differentiation proof contract (= ADR-0025 全 §決定)
- K/R rhythm event dispatch proof contract (= ADR-0026 全 §決定、 §決定 5 「b-only proof」 は ADR-0027 §決定 2 で「b + s proof」 + 本 ADR §決定 2 で「b + s + h proof」 に literal 更新、 dispatch path 1 本化不変原則は維持)
- `.PNE` / `.MN` asset pipeline (= ADR-0021 で確立)
- BD fixture (= `k-br-only.mml` / `r-melody-br-only.mml`) 完全不変
- SD fixture (= `k-sr-only.mml` / `r-melody-sr-only.mml`) 完全不変
- 既存 20 script regression PASS

#### dispatch path 1 本化の drum 種拡張下での維持 (= ADR-0026 §決定 6 / ADR-0027 §決定 8 の 3 drum 段 literal 実証)

ADR-0026 §決定 6 / ADR-0027 §決定 8 で確立した「dispatch path は drum 種拡張で増やさない」 contract は、 Step 14 で **bit 0 BD + bit 1 SD + bit 3 HH の 3 drum 状況下で `pmdneo_rhythm_event_trigger` routine entry addr が変化しない** ことで literal 実証される。 K-HH / R-HH fixture で PC trace を取得し、 PC hit addr が Step 12 / Step 13 と同一 (= 0x1126) であることを `verify-step14-hh-trigger.sh` で literal assert する。

Step 14 で routine 内部の implementation は拡張される (= bit 3 分岐追加 + `_rhythm_event_hh_trigger` sub-routine 新規) が、 routine entry / 引数 / 戻り値 ABI は不変。 future の drum 種拡張 (= c/t/i 3 種) でも同じ entry addr を保持することを Step 14 で先取り保証する (= 3 drum 段から 6 drum 段まで dispatch path 不変保証の漸増)。

### 決定 2: drum 種拡張 = bit 3 HH 単独 accept (= ADR-0027 §決定 2 b+s proof を b+s+h proof に literal 更新、 bit 2/4/5 silent ignore 維持)

K part 文法 subset (= 軸 1 / (e2) 採用):

- K letter = `K` 維持 (= PMD V4.8s 互換、 ADR-0026 §決定 5 / ADR-0027 §決定 2 維持)
- drum 識別文字 = **`b` = BD + `s` = SD + `h` = HH の 3 種** で proof (= ADR-0027 §決定 2 の「b + s」 を「b + s + h」 に literal 拡張)
- 残り 3 種 (= `c` = CYM / `t` = TOM / `i` = RIM、 `r` は rest 専用) は future sub-sprint で段階追加 (= Step 15 候補、 ADR-0027 §Annex A-1 mc.cs rcomtbl L9528-9533 literal で確認済)
- K syntax 自体は PMD 互換 (= drum 種拡張時に既存 K part syntax を維持)

#### bitmap accept range

driver `.MN` direct parser での `0xEB <bitmap>` 受入:

- **bit 0 = 1** (= 0x01): BD trigger (= 既存 ADR-0026 / ADR-0027 維持)
- **bit 1 = 1** (= 0x02): SD trigger (= 既存 ADR-0027 維持)
- **bit 2 = 1** (= 0x04): CYM trigger (= `\c`) → **silent ignore** (= 未対応 cmd スルー思想、 ADR-0026 §決定 11 / ADR-0027 §決定 2 踏襲)
- **bit 3 = 1** (= 0x08): HH trigger (= `\h`) → **本 ADR で新規追加 accept**
- **bit 4 = 1** (= 0x10): TOM trigger (= `\t`、 mc.cs `tamset` 経由) → **silent ignore**
- **bit 5 = 1** (= 0x20): RIM trigger (= `\i`、 `\r` ではない、 mc.cs `rimset` 経由) → **silent ignore**
- **bit 6-7**: reserved (= silent ignore)
- **bitmap = 0x00**: no-op
- **bitmap = 0x03 / 0x09 / 0x0A / 0x0B 等** (= simultaneous trigger combo): bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4)、 動作は α 調査で literal 確認 + 結果 Annex A 反映、 Step 14 fixture では生成しない

#### 採用根拠

- ADR-0027 b+s proof と同じ proof 最小性
- dispatch path 1 本化が 3 drum 状況下で literal 維持されることの proof は 1 軸拡張で十分
- 残 3 drum 一気は fixture / verify / sample addr mapping を同時拡張で scope 肥大化
- BD/SD/HH は PMD V4.8s K part 文法的に最頻出 (= pop / rock 基本 pattern)
- HH sample は ADR-0025 step5b で ADPCM-A subsystem 内に既に embed 済 (= sample source 取得コスト 0)

#### ADR / handoff 記載 contract

- Step 14 では drum kind = **b + s + h only**
- future sprint で c/t/i を **段階追加**
- bit 2/4/5 は **silent ignore** (= 未対応 cmd スルー思想踏襲)
- dispatch path は drum 種拡張で **増やさない** (= 決定 8 と整合)

### 決定 3: HH sample source = existing `adpcma_sample_hh` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 pattern 踏襲、 melody sample symbol と現段階で共有、 final rhythm sample ownership 未確定)

HH trigger で使う sample (= 軸 6 / (hh_s1) 採用):

#### Step 14 proof 段階

- bit 0 BD → `adpcma_sample_bd` pointer (= 既存 Step 12 維持)
- bit 1 SD → `adpcma_sample_sd` pointer (= 既存 Step 13 維持)
- bit 3 HH → `adpcma_sample_hh` pointer (= 本 ADR で新規 mapping 追加、 既存 symbol reuse)
- sample header / addr 値は driver source / `samples.inc` 内に literal 配置 (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 ADR-0025 step5b で既に HH ADPCM-A subsystem 内に embed 済)
- 新規 sample embed なし (= 既存資産再利用のみ)
- `.PNE` / `.MN` asset pipeline / `pne_sample_directory` / `sample_table_id` resolver / `pmdneo_select_sample_pointer` は完全不変
- L-Q melody sample / rhythm BD sample / rhythm SD sample / rhythm HH sample は driver source 内で **symbol 共有** (= L-Q melody N ch と `adpcma_sample_hh` symbol を share、 ただし read タイミング軸で collision しない)

#### symbol sharing と semantics separation の現段階整理

- melody architecture (= ADR-0019 で確立した L-Q 6 ch ADPCM-A native runtime): N ch (= O part) の sample として `adpcma_sample_hh` を参照
- rhythm proof (= 本 ADR + ADR-0026 / ADR-0027): L ch (= rhythm event trigger 経由) の sample として `adpcma_sample_hh` を参照
- 両者は **同 symbol を share** するが **異なる ADPCM-A ch slot に書き込まれる** (= melody N ch slot vs rhythm L ch slot、 register bank 軸で分離)
- final rhythm sample ownership は **未確定** (= future `.PNE` rhythm bank migration で rhythm-dedicated sample bank に移行する可能性あり、 ADR-0026 §決定 3 / ADR-0027 §決定 3 future migration path 継続)

#### future migration path (= ADR-0026 §決定 3 / ADR-0027 §決定 3 継続、 literal 残置)

将来的に OPNA rhythm 相当 sample set を `.PNE` 側へ寄せる可能性が高い (= ADR-0026 §決定 3 / ADR-0027 §決定 3 と同一)。 候補 path:

- `.PNE` rhythm bank entry を新設 (= `sample_table_id` id=0x02 を rhythm bank として確保、 directory entry 拡張)
- generated rhythm sample directory (= D3 migration の一部として rhythm sample を含める)
- driver の `pmdneo_rhythm_event_trigger` routine が `.PNE` rhythm bank entry を引くように変更
- rhythm-dedicated sample symbol 分離 (= `adpcma_sample_bd_rhythm` / `adpcma_sample_sd_rhythm` / `adpcma_sample_hh_rhythm` 等、 melody architecture sample symbol と分離)

ただし上記は **Step 14 scope-out**、 future sprint で必要なら別途検討。

#### ADR / handoff 記載 contract

- HH sample = **existing `adpcma_sample_hh` symbol reuse as driver-embedded proof fixture**
- 新規 sample embed = **scope-out**
- rhythm-dedicated symbol 分離 = **scope-out** (= ADR-0027 SD pattern との consistency 維持)
- driver-embedded rhythm fixture は **proof 用** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 維持)
- `.PNE` migration は **future sprint** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 future migration path 継続)
- Step 14 は **drum kind expansion proof**、 sample source proof / symbol separation proof ではない
- melody sample symbol と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

### 決定 4: dispatch path 1 本化不変 (= `pmdneo_rhythm_event_trigger` routine entry addr 不変、 routine 内部の bit 3 分岐は追加するが ABI 不変)

K と R の dispatch path (= ADR-0026 §決定 6 / ADR-0027 §決定 4 維持 + Step 14 で drum 種拡張下の literal 維持):

#### routine entry 不変

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は Step 12 / Step 13 から不変
- K-HH / R-HH fixture でも PC trace hit addr は 0x1126 (= 既存 Step 12 K-BD / R-BD + Step 13 K-SD / R-SD と同一)
- routine 引数 / 戻り値 ABI 不変
- `.MN` direct parser からの caller 接続不変

#### routine 内部の bit 3 分岐追加

routine 内部の implementation は拡張される:

- 既存 (Step 12): bit 0 = 1 → BD trigger (= `adpcma_sample_bd` register write)
- 既存 (Step 13): bit 1 = 1 → SD trigger (= `adpcma_sample_sd` register write)
- 新規 (Step 14): bit 3 = 1 → HH trigger (= `adpcma_sample_hh` register write)
- bit 2/4/5: silent ignore (= no register write)
- bit 6-7: reserved (= no register write)
- bitmap = 0x00: no-op

#### branch 実装流儀 (= explicit if/jr、 ADR-0024 / ADR-0025 / ADR-0026 / ADR-0027 §決定 4 流儀踏襲)

bit 0 / bit 1 / bit 3 の分岐は **explicit if/jr** で記述 (= jump table / dispatch macro は使わない)。 ADR-0024 step 10 / ADR-0025 step 11 / ADR-0026 step 12 / ADR-0027 step 13 全てで踏襲してきた流儀:

```asm
pmdneo_rhythm_event_trigger:
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 3 = HH / bit 2/4/5 = silent ignore
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
    push    af
    bit     3, a
    jr      z, _rhythm_event_no_hh
    call    _rhythm_event_hh_trigger
_rhythm_event_no_hh:
    pop     af
    ret

_rhythm_event_bd_trigger:
    ; adpcma_sample_bd を ADPCM-A L ch に register write (= Step 12 既存)
    ...
    ret

_rhythm_event_sd_trigger:
    ; adpcma_sample_sd を ADPCM-A L ch に register write (= Step 13 既存)
    ...
    ret

_rhythm_event_hh_trigger:
    ; adpcma_sample_hh を ADPCM-A L ch に register write (= Step 14 新規実装)
    ld      hl, #adpcma_sample_hh
    ; ... reg 0x10 / 0x18 / 0x20 / 0x28 / 0x08 / 0x00 keyon mask 0x01 write
    ret
```

実装の literal asm は β commit で確定 (= 本 ADR は契約のみ literal 固定、 implementation 詳細は β に委ねる)。

#### ADR / handoff 記載 contract

- `pmdneo_rhythm_event_trigger` routine entry addr = **不変** (= 0x1126)
- routine ABI = **不変**
- routine 内部の bit 3 分岐は **追加** (= bit 0 BD / bit 1 SD trigger の隣に bit 3 HH trigger)
- branch 流儀 = **explicit if/jr** (= ADR-0024 / 0025 / 0026 / 0027 流儀踏襲)
- dispatch path は drum 種拡張で **増やさない** (= ADR-0026 §決定 6 / ADR-0027 §決定 8 維持、 本 ADR §決定 8 で 3 drum 段で再確認)

### 決定 5: fixture 体制 = BD/SD fixture 完全不変 + HH fixture 2 件新規 (= 6 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH)

K-HH / R-HH fixture 取り扱い (= 軸 2 / (fix1) 採用):

#### 既存 BD/SD fixture 完全不変

- `compile-test-pmddotnet/k-br-only.mml` (= Step 12 β commit 309c011 で新規追加、 K part `\b` + `r`(= rest) のみ)
- `compile-test-pmddotnet/r-melody-br-only.mml` (= Step 12 γ commit 5465f08 で新規追加、 melody part L 内 inline `\b` + `r`(= rest))
- `compile-test-pmddotnet/k-sr-only.mml` (= Step 13 β commit 36588b3 で新規追加、 K part `\s` + `r`(= rest) のみ)
- `compile-test-pmddotnet/r-melody-sr-only.mml` (= Step 13 γ commit 2aad439 で新規追加、 melody part L 内 inline `\s` + `r`(= rest))

これらは **完全不変** (= byte-identical 維持、 Step 12 / Step 13 K-R differential proof script で継続使用)。

#### 新規 HH fixture 2 件

- `compile-test-pmddotnet/k-hr-only.mml` (= K part `\h` + `r`(= rest) のみ、 K-BD/K-SD fixture と 1 文字違い)
- `compile-test-pmddotnet/r-melody-hr-only.mml` (= melody part L 内 inline `\h` + `r`(= rest)、 R-BD/R-SD fixture と 1 文字違い)

#### fixture 命名規則

- `k-hr-only.mml` の `hr` は **`\h` + `r`(= rest) の fixture pattern**
- `hr` は「**hi-hat」 略ではない** (= 既存 `br` / `sr` も「BD」「SD」 略ではなく `\b` + `r` / `\s` + `r` pattern と同一)
- α 調査で PMDDotNET が HH を `\h` として emit することを literal 確認 (= ADR-0027 §Annex A-1 / §Annex A-2 で既に literal 確認済、 α 調査で再確認 + 本 ADR §Annex A 反映)
- もし α 調査で HH の MML 記号が `\h` でないと判明した場合は、 fixture 名を **実 bytecode / actual syntax に合わせて修正** (= sub-sprint 内で rename、 β 着手前に確定、 ただし ADR-0027 で `\h` 確認済のため本 sprint で rename 発生確率低)

#### 6 fixture 体制

| fixture | drum 種 | source 経路 | step12 / step13 / step14 |
|---|---|---|---|
| `k-br-only.mml` | BD | K part | step 12 既存 |
| `r-melody-br-only.mml` | BD | melody part inline | step 12 既存 |
| `k-sr-only.mml` | SD | K part | step 13 既存 |
| `r-melody-sr-only.mml` | SD | melody part inline | step 13 既存 |
| `k-hr-only.mml` | HH | K part | step 14 新規 |
| `r-melody-hr-only.mml` | HH | melody part inline | step 14 新規 |

#### ADR / handoff 記載 contract

- BD/SD fixture = **完全不変**
- HH fixture = **2 件新規追加**
- fixture 命名 pattern = `\h` + `r`(= rest) = `hr` (= 既存 `br` / `sr` pattern 踏襲、 drum 名略ではなく fixture pattern 命名)
- α 調査で命名修正可能性極めて低い (= ADR-0027 §Annex A-1 で `\h` literal 確認済)
- **`hr` は「hi-hat」 略ではない** (= future contributor 向け literal 注記)

### 決定 6: drum 種 → sample pointer mapping table を 1 軸拡張 (= bit 0 → BD addr / bit 1 → SD addr / bit 3 → HH addr)

driver source 内 mapping table 構造:

#### Step 13 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` literal addr 参照
- bit 2-7 は no-op (= silent ignore)

#### Step 14 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 + bit 3 HH 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_hh` literal addr 参照
- bit 2/4/5/6/7 は no-op (= silent ignore 維持)
- mapping table 構造は branch 流儀の延長 (= 別途 table 構造を導入せず、 explicit branch + literal addr 参照のまま)

#### branch 構造で literal addr 参照する根拠 (= 別 table 構造を導入しない理由)

- ADR-0024 / 0025 / 0026 / 0027 で確立した explicit if/jr 流儀踏襲
- 3 drum 程度なら branch 列挙の方が trace gate / register write trace で読みやすい
- 別 mapping table 構造 (= bitmap bit position → sample addr pointer の lookup table) は 4+ drum で検討 (= future sprint c/t/i 追加で 6 drum 段到達時に再評価)
- 早すぎる抽象化を避ける (= CLAUDE.md §「3 行の重複は早すぎる抽象化より良い」 規律)
- table-driven refactor は full drum set 到達後 (= 6 drum 段) に判断材料が揃う

#### ADR / handoff 記載 contract

- drum 種 → sample pointer mapping = **explicit branch + literal addr 参照**
- 別 mapping table 構造 = **scope-out** (= future sprint で 4+ drum 拡張時に再評価、 full drum set 到達後優先)
- bit 0 → `adpcma_sample_bd` literal addr
- bit 1 → `adpcma_sample_sd` literal addr
- bit 3 → `adpcma_sample_hh` literal addr

### 決定 7: BD/SD fixture 完全不変保証 (= Step 12 K-BD / R-BD path + Step 13 K-SD / R-SD path regression 維持)

Step 14 で BD/SD path を壊していないことを継続確認する規律:

#### regression 維持要件

- Step 12 で確立した K-BD / R-BD path の verify script 4 件 (= `verify-step12-k-rhythm-trigger.sh` / `verify-step12-kr-differential.sh` 等) は **完全不変**
- Step 13 で確立した K-SD / R-SD path の verify script 3 件 (= `verify-step13-sd-trigger.sh` / `verify-step13-kr-sd-differential.sh` / `verify-step13-bd-sd-differential.sh`) は **完全不変**
- Step 12 / Step 13 K-BD / R-BD / K-SD / R-SD fixture file (= `k-br-only.mml` / `r-melody-br-only.mml` / `k-sr-only.mml` / `r-melody-sr-only.mml`) は **byte-identical** 維持
- Step 12 BD register write trace + Step 13 SD register write trace は **同 sequence 維持**
- Step 14 commit chain (= α/β/γ/δ) の各 commit で全 step12 + step13 path verify script PASS が確認できる

#### ADR / handoff 記載 contract

- BD path **regression 維持**
- SD path **regression 維持**
- Step 12 / Step 13 fixture / verify script 完全不変
- Step 14 各 commit で BD/SD path verify が **PASS 確認できる**
- 「動いているものを壊さない」 規律遵守 (= Step 5/6/7/8/9/10/11/12/13 で確立)

### 決定 8: dispatch path は drum 種拡張で増やさない (= ADR-0026 §決定 6 / ADR-0027 §決定 8 維持、 Step 14 で 3 drum 段 literal 実装保証)

ADR-0026 §決定 6 / ADR-0027 §決定 8 で確立した contract:

> dispatch path は drum 種拡張で増やさない

を Step 14 で **3 drum 段で literal 実装的に保証** する:

#### 実装的保証 内容

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は不変
- K-HH / R-HH fixture で PC trace hit addr が Step 12 K-BD / R-BD + Step 13 K-SD / R-SD と同一 (= 0x1126)
- routine ABI 不変
- routine 内部の bit 3 分岐追加 + `_rhythm_event_hh_trigger` sub-routine 新規は **routine 内部の implementation 拡張** であって dispatch path の新設ではない
- drum 種 → sample addr mapping は routine 内部の literal branch で吸収

#### future drum 種拡張で維持される項目

c/t/i 3 種追加時にも:

- routine entry addr 不変 (= 0x1126)
- routine ABI 不変
- 新規 dispatch routine を追加しない (= routine 内部の bit position 分岐 + sub-routine を追加するのみ)
- future drum 種拡張で 6 drum 段に到達した時点で別 mapping table 構造への refactor を再評価 (= 決定 6 と整合、 full drum set 到達後優先)

#### ADR / handoff 記載 contract

- dispatch path = **1 本化維持**
- routine entry addr / ABI = **不変**
- drum 種拡張は **routine 内部 implementation 拡張 (= bit 分岐 + sub-routine 追加) で吸収**
- table-driven refactor = **future sprint** (= full drum set = 6 drum 段到達後に再評価)

### 決定 9: observability marker = `pmdneo_rhythm_event_trigger` PC hit 継続 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 維持、 SRAM layout 不変)

Step 14 での observability marker 軸 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / 軸 7 維持):

- rhythm event observability marker = **routine PC hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126)
- memory marker byte は **持たない** (= SRAM 増設なし)
- SRAM layout は Step 14 でも **増やさない** (= 0xFD20-0xFD32 既存領域維持)
- PC trace + ymfm-trace の **二段 gate** で K-HH / R-HH proof
- K-HH / R-HH source path は別でも runtime dispatch routine は同一 (= 同 0x1126 PC hit)

#### ADR / handoff 記載 contract

- observability marker = **routine PC hit (= 0x1126)**
- memory marker byte 追加 = **scope-out**
- SRAM layout 不変
- PC trace + ymfm-trace 二段 gate 継続

### 決定 10: PMDDotNET / `.MN` format 完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 維持)

Step 14 での PMDDotNET / `.MN` format 軸:

- PMDDotNET (= C# compile path) 完全不変
- `.MN` format 完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う)
- 新規 `.MN` bytecode 追加なし
- driver `.MN` direct parser での normalize は ADR-0026 で確立した `0xEB <bitmap>` 受入を維持、 bitmap accept range のみ bit 0 + bit 1 → bit 0 + bit 1 + bit 3 に拡張

#### ADR / handoff 記載 contract

- PMDDotNET-side normalize は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 維持)
- new `.MN` rhythm event bytecode 追加は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 維持)
- driver `.MN` direct parser での bitmap accept range 拡張のみ (= bit 0 + bit 1 → bit 0 + bit 1 + bit 3)

### 決定 11: simultaneous trigger scope-out + bitmap OR semantics future investigation (= future 候補温存、 Annex A 軽く触れる)

simultaneous trigger semantics 対応 (= 軸 4 / scope-out 採用):

#### Step 14 scope-out

- BD+SD / BD+HH / SD+HH / BD+SD+HH 同時打ち (= bitmap = 0x03 / 0x09 / 0x0A / 0x0B 等) の literal proof は **Step 14 scope-out**
- Step 14 fixture は **BD 単独 / SD 単独 / HH 単独 のみ** (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH 6 件、 simultaneous combo 並記 fixture なし)
- driver の bitmap accept range は bit 0 + bit 1 + bit 3 個別 accept (= bit 0=1 single / bit 1=1 single / bit 3=1 single、 simultaneous combo は α 調査で literal 動作確認のみ、 fixture proof scope-out)

#### bitmap OR semantics future investigation

- PMDDotNET が同 K part 行 `\b\h` / `\s\h` / `\b\s\h` の連続記述で **bitmap OR (= bit position OR 結合)** を emit するか、 **複数の `0xEB` + 各 bitmap byte** を emit するかは α 調査範囲 (= ADR-0027 §Annex A-3 で `\b\s` → `0xEB 0x03` bitmap OR 圧縮 emit literal 確認済、 同 pattern で `\b\h` → `0xEB 0x09` / `\s\h` → `0xEB 0x0A` / `\b\s\h` → `0xEB 0x0B` 想定)
- α 調査結果を Annex A に literal 反映
- future sprint 候補 (= simultaneous trigger semantics literal proof sprint) として温存

#### ADR / handoff 記載 contract

- simultaneous trigger = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 15+ 候補)
- Step 14 fixture は **BD 単独 / SD 単独 / HH 単独 のみ**
- α 調査で PMDDotNET の bitmap OR emit 動作を literal 確認 + Annex A 反映 (= ADR-0027 で BD+SD 確認済、 本 ADR で HH 込み combo の追加確認)

## scope-in / scope-out

### scope-in (= Step 14 で literal 実装する範囲)

1. driver `pmdneo_rhythm_event_trigger` routine に bit 3 分岐追加 (= HH trigger)
2. driver `_rhythm_event_hh_trigger` sub-routine 新規追加 (= adpcma_sample_hh を L ch register write)
3. HH sample pointer mapping (= bit 3 → `adpcma_sample_hh` literal addr、 既存 symbol reuse)
4. `k-hr-only.mml` fixture 新規追加
5. `r-melody-hr-only.mml` fixture 新規追加
6. `verify-step14-hh-trigger.sh` 新規追加 (= K-HH / R-HH register write trace + keyon count + PC marker)
7. `verify-step14-kr-hh-differential.sh` 新規追加 (= K-HH vs R-HH byte-identical literal proof)
8. `verify-step14-bd-hh-differential.sh` 新規追加 (= BD vs HH sample addr literal differ proof)
9. PMDDotNET HH emit literal 再確認 (= mc.cs hihset / rs00 周辺、 ADR-0027 §Annex A-1 / §Annex A-2 で literal 確認済を本 ADR §Annex A で再引用)
10. PMDDotNET HH 込み bitmap OR emit 動作確認 (= 同 K part 行 `\b\h` / `\s\h` / `\b\s\h` 連続記述時の emit byte 列、 Annex A literal 反映)
11. ADR-0028 Annex A 反映 (= α 調査結果)
12. ADR-0028 Accepted 移行 (= δ で実施)
13. handoff doc 起票 (= δ で実施)
14. memory `project-pmdneo-step14-complete` 起票 (= δ で実施)
15. MEMORY.md index 更新 (= δ で実施)

### scope-out (= Step 14 で literal 触らない範囲)

#### Step 14 固有 scope-out (= 5 項目)

1. BD+SD / BD+HH / SD+HH / BD+SD+HH simultaneous trigger literal proof (= bitmap = 0x03 / 0x09 / 0x0A / 0x0B fixture / verify) → Step 15+ 候補
2. c/t/i 残り 3 drum 種拡張 → future sub-sprint
3. drum 種 → sample addr mapping table 構造化 (= bitmap bit position → sample pointer の lookup table) → 6 drum 段到達時に再評価 (= full drum set 後優先、 ADR-0027 §scope-out 維持)
4. HH sample provenance 拡張 (= 新規 sample embed / rhythm-dedicated symbol 分離 / `.PNE` rhythm bank migration) → future
5. table-driven dispatch refactor (= dispatch path + sub-routine を 1 本に集約) → future sprint (= full drum set 到達後優先)

#### ADR-0026 / ADR-0027 から継続する scope-out (= 27+ 項目維持)

6. OPNA rhythm sound source register (= 0x10-0x18) fake API (= PMDNEO は YM2610(B)、 emulation 方針外、 ADR-0026 §決定 2 / ADR-0027 §scope-out 維持)
7. 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation (= channel allocation 最終仕様は future、 ADR-0026 §決定 4 / ADR-0027 §scope-out 維持)
8. OPNA native rhythm timing fidelity (= ADR-0026 / ADR-0027 §scope-out 追加項目維持)
9. K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch の 6 件、 silent fallback 継続、 ADR-0026 §決定 11 / ADR-0027 §scope-out 維持)
10. PMDDotNET 改造 / `.MN` format new bytecode (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / 本 ADR §決定 10 維持)
11. selected pointer cache (A2/A3) / mismatch silent flag / D3 generated directory / runtime `.PNE` parser / multi-`.PNE` switching / bank switching (= ADR-0025 §scope-out 継続)
12. `.PPC` / `.P86` / ADPCM-B subsystem 起票 (= 別 subsystem、 `project_pmdneo_adpcma_subsystem_boundary` 維持)
13. `.PNE` rhythm bank migration (= ADR-0026 §決定 3 / ADR-0027 §決定 3 future migration path 継続、 ADPCM-A subsystem 内だが Step 14 scope-out)
14. driver-embedded fixture 以外の sample provenance (= ADR-0026 §決定 3 / ADR-0027 §決定 3 維持)
15. multi-table cache / runtime parser (= ADR-0025 / ADR-0026 §決定 11 / ADR-0027 §scope-out 継続)
16. new bytecode (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / 本 ADR §決定 10 維持)
17. PMDDotNET 改造 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / 本 ADR §決定 10 維持)
18. observability marker 拡張 (= memory marker byte / SRAM 増設、 ADR-0026 §決定 8 / ADR-0027 §決定 9 / 本 ADR §決定 9 維持)
19. K letter 以外の rhythm part letter (= ADR-0026 §決定 5 / ADR-0027 §scope-out 維持)
20. PMDNEO 独自 drum 識別文字 (= PMD 互換維持、 ADR-0026 §決定 5 / ADR-0027 §scope-out 維持)
21. velocity / volume / pan / loop / pattern 軸拡張 (= ADR-0026 §決定 1 / ADR-0027 §決定 2 / 本 ADR §決定 2 b+s+h proof minimum 範囲限定)
22. K part / R command 以外の rhythm 系 cmd (= ADR-0026 §決定 11 / ADR-0027 §scope-out 維持)
23. ADPCM-B subsystem への rhythm extension (= `project_pmdneo_adpcma_subsystem_boundary` 維持、 別 subsystem)
24. WebApp UI 関連 (= Phase 4 範囲、 別 sprint)
25. WAV import / 新規 sample 追加 UI (= Phase 4 範囲)
26. AES+ 実機検証 (= 別 sprint、 verify は MAME headless 経由継続)
27. fmgen 比較 (= 別 sprint)
28. PMDNEO.s + nullsound integration (= `project_pmdneo_driver_two_paths_discovery` 維持、 別 path)

## verify gate

### 5 段 gate (= ADR-0026 / ADR-0027 §verify gate 形式踏襲)

#### Gate 1: build PASS

- α: 全 20 既存 script regression PASS (= step12 系 + step13 系 + step5-11 系)
- β: 全 20 既存 + step14 hh-trigger 新規 = 20+1 = 21 script PASS
- γ: 全 20 既存 + step14 hh-trigger + step14 kr-hh-differential + step14 bd-hh-differential = 20+3 = 23 script PASS
- δ: 全 23 script 最終 regression PASS

#### Gate 2: K-HH trigger 単独 verify

`verify-step14-hh-trigger.sh` PASS 内容:

1. `k-hr-only.mml` build → `.MN` byte literal 確認 (= `0xEB 0x08 0x80` 期待 or PMDDotNET 実 emit byte literal、 α 調査結果で確定、 ADR-0027 §Annex A 推定で bitmap 0x08)
2. ymfm-trace で ADPCM-A L ch HH register write 確認 (= reg 0x10 sample addr literal = `adpcma_sample_hh` start addr 等)
3. PC trace で `pmdneo_rhythm_event_trigger` @ 0x1126 hit 確認
4. keyon count = 1 (= L ch keyon mask 0x01 trigger 1 件)
5. K-HH fixture / R-HH fixture 両方で同 sequence PASS

#### Gate 3: K-HH vs R-HH differential proof

`verify-step14-kr-hh-differential.sh` PASS 内容:

1. K-HH fixture (= `k-hr-only.mml`) と R-HH fixture (= `r-melody-hr-only.mml`) で ADPCM-A L ch register write sequence **byte-identical** literal proof
2. PC trace hit addr 同一 (= 両方 0x1126)
3. keyon count 同一 (= 両方 1 件)
4. dispatch path 1 本化が drum 種拡張 (= 3 drum 状況) 下でも literal 維持されることの proof

#### Gate 4: BD vs HH differential proof

`verify-step14-bd-hh-differential.sh` PASS 内容:

1. K-BD fixture (= `k-br-only.mml`) と K-HH fixture (= `k-hr-only.mml`) で:
   - reg 0x10 sample start addr **literal differ** (= `adpcma_sample_bd` start addr ≠ `adpcma_sample_hh` start addr)
   - reg 0x18 sample end addr **literal differ**
   - reg 0x20 volume / reg 0x28 pan は **identical** (= 同 L ch、 同 fixture pattern なら同値)
   - reg 0x08 vol|pan / reg 0x00 keyon mask は **identical**
2. R-BD fixture と R-HH fixture でも同様の差分 literal proof
3. drum 種 → sample addr mapping が literal 区別されていることの proof (= 3 drum 段で BD vs HH literal differ)

#### Gate 5: 既存 regression 不破壊

- 既存 20 script regression PASS 維持 (= ADR-0027 完了時の 20 script、 BD path / SD path / multi-table / melody / asset pipeline 全て)
- 各 commit (= α/β/γ/δ) で全 step12 + step13 BD/SD path verify script PASS が確認できる
- 「動いているものを壊さない」 規律遵守

### audio gate

- ✅ user 試聴 OK 確認予定 (= δ commit 前 15th session δ で user 試聴依頼、 6 wav file = `/tmp/pmdneo-step12/k-br-only.wav` + `/tmp/pmdneo-step12/r-melody-br-only.wav` + `/tmp/pmdneo-step13/k-sr-only.wav` + `/tmp/pmdneo-step13/r-melody-sr-only.wav` + `/tmp/pmdneo-step14/k-hr-only.wav` + `/tmp/pmdneo-step14/r-melody-hr-only.wav` で確認)
- ✅ user judgement: 「k-br-only = r-melody-br-only」 「k-sr-only = r-melody-sr-only」 「k-hr-only = r-melody-hr-only」 = K/R で同音、 BD vs SD vs HH で違う音色、 FM 同居許容 (= Step 12 / Step 13 audio gate 規律踏襲)
- ✅ BD 単独 / SD 単独 / HH 単独 各 fixture で音が鳴る + BD/SD/HH 3 種で聴感的に区別可能 を user judgement で確認

## 完了判定

Step 14 完了判定 (= 10 項目、 15th session δ で全 ✅ 達成予定):

1. ADR-0028 Accepted 移行 (= δ commit で literal 達成)
2. `pmdneo_rhythm_event_trigger` routine に bit 3 HH 分岐追加 (= β commit、 既存 bit 0 / bit 1 分岐の隣に追加)
3. HH sample pointer mapping (= bit 3 → `adpcma_sample_hh` 既存 symbol reuse) 実装 (= β commit、 `_rhythm_event_hh_trigger:` label で literal addr 参照)
4. `k-hr-only.mml` fixture 新規追加 (= K-HH path、 β commit、 UTF-8 + CRLF)
5. `r-melody-hr-only.mml` fixture 新規追加 (= R-HH path、 γ commit、 UTF-8 + CRLF)
6. `verify-step14-hh-trigger.sh` 新規追加 + PASS (= β commit、 5 gate PASS)
7. `verify-step14-kr-hh-differential.sh` 新規追加 + PASS (= γ commit、 7 gate PASS、 K-HH vs R-HH byte-identical)
8. `verify-step14-bd-hh-differential.sh` 新規追加 + PASS (= γ commit、 6 gate PASS、 BD vs HH sample addr literal differ)
9. 既存 全 script regression PASS 維持 (= δ で 23 script serial 実行、 全 PASS = step 4/5/6/7/8/9/10/11/12/13 系 17 script + step 14 新規 3 件 = 20+3 = 23 script、 BD/SD path 不変保証 + driver 改修副作用なし)
10. user 試聴 OK 確認 (= 15th session δ user 試聴依頼で「k-br-only = r-melody-br-only」 「k-sr-only = r-melody-sr-only」 「k-hr-only = r-melody-hr-only」 K/R 同音確認、 BD/SD/HH 区別可能、 FM 同居許容方針 ADR-0026 / ADR-0027 audio gate 規律踏襲)

## 本質再確認

### layering 図 (= future contributor 向け literal 固定、 Step 13 layering の drum 種 1 軸拡張)

```
source layer:           K part                       R command
                        \b / \s / \h                 \b inline / \s inline / \h inline
                            \                            /
                             \                          /
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
                                  +-- bit 3 = 1 --> _rhythm_event_hh_trigger --> adpcma_sample_hh --> ADPCM-A L ch
                                  |
                                  +-- bit 2/4/5 --> silent ignore (= future drum 種拡張で literal branch 追加)
                                  |
                                  +-- bit 6-7 ---> reserved
                                  |
                                  +-- bitmap = 0x00 --> no-op
                                  |
                                  +-- bitmap = 0x03 / 0x09 / 0x0A / 0x0B 等 --> Step 14 scope-out (= simultaneous trigger semantics future)
```

### Step 12 / Step 13 path 維持原則

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) **不変**
- routine ABI **不変**
- routine 内部の bit 3 分岐は **追加** だが routine entry / 引数 / 戻り値 ABI は **不変**
- K-BD / R-BD / K-SD / R-SD path **完全不変** (= Step 12 / Step 13 fixture / verify / register write sequence 全て不変)
- `_rhythm_event_bd_trigger` sub-routine **完全不変**
- `_rhythm_event_sd_trigger` sub-routine (@ 0x115F) **完全不変**
- PC trace + ymfm-trace 二段 gate 規律 **継続**
- PMDDotNET / `.MN` format **完全不変**
- driver-embedded fixture proof 規律 **継続**
- `.PNE` rhythm bank migration **future 維持**

### ADR-0026 §決定 6 / ADR-0027 §決定 8 の 3 drum 段 literal 実装保証

「dispatch path は drum 種拡張で増やさない」 contract が Step 14 で **bit 0 BD + bit 1 SD + bit 3 HH の 3 drum 状況下で routine entry addr が変化しない** ことで literal 実装的に保証される。 future drum 種拡張 (= c/t/i) でも同じ entry addr を保持することを Step 14 で先取り保証する (= 3 drum 段から 6 drum 段までの dispatch path 不変保証の漸増)。

## sub-sprint 構造

ADR-0026 / ADR-0027 同 pattern 踏襲、 1 sub = 1 commit + 1 push 規律:

| sub | 内容 | driver 改修 | fixture 追加 | verify script 追加 | 一文要約 |
|---|---|---|---|---|---|
| ADR | 本 ADR 起票 Draft | なし | なし | なし | ADR-0028 Draft 起票 (= 11 決定 + scope-out 28+ 項目 + 5 段 gate + 完了判定 10 項目 + layering 図 + Annex A 着手) |
| α | PMDDotNET HH emit 再確認 + bitmap OR emit (HH 込み) 動作調査 + ADR Annex A literal 反映 | なし (= 完全不変) | なし | なし | mc.cs hihset / rs00 周辺の HH emit 記号 + bitmap OR emit (HH 込み combo) 動作 literal 確認、 fixture 命名修正可能性判断 (= 既に低、 ADR-0027 §Annex A-1 で `\h` 確認済)、 driver 完全不変純調査 |
| β | HH trigger 接続 + K-HH fixture + verify | bit 3 分岐追加 + `_rhythm_event_hh_trigger` sub-routine 新規 + HH sample pointer mapping | `k-hr-only.mml` | `verify-step14-hh-trigger.sh` | pmdneo_rhythm_event_trigger に bit 3 HH 分岐 + `_rhythm_event_hh_trigger` 新規 + adpcma_sample_hh pointer mapping + K-HH fixture + hh-trigger verify、 全 step12 + step13 BD/SD regression PASS |
| γ | R-HH fixture + differential verify 2 件 | なし (= commandsp 0xEB 既存接続を bit 3 でも通す、 既に β で対応済) | `r-melody-hr-only.mml` | `verify-step14-kr-hh-differential.sh` + `verify-step14-bd-hh-differential.sh` | R-HH fixture + K-HH vs R-HH differential + BD vs HH differential 2 script、 全 22-23 script regression PASS |
| δ | 完了統合 + ADR Accepted + handoff + memory | なし | なし | なし | ADR-0028 Accepted 移行 + 完了判定 literal 反映 + 全 23 script 最終 regression PASS + user 試聴 OK + handoff doc + memory + MEMORY.md index 更新 |

## Annex A: PMDDotNET HH emit 再確認 + bitmap OR (HH 込み combo) 動作調査 (= 15th session α 調査予定、 driver / fixture / verify script 完全不変純調査)

(本 ADR は Draft 起票時点。 α 着手で literal 反映予定。 ADR-0027 §Annex A-1 / §Annex A-2 で既に literal 確認済を本 ADR §Annex A で再引用 + bitmap OR HH 込み combo 動作の追加 literal 確認。)

### A-1: PMDDotNET `\h` HH emit literal 再確認 (= ADR-0027 §Annex A-1 引用、 mc.cs rcomtbl L9528-9533)

ADR-0027 §Annex A-1 で literal 確認済 (= `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` の `rcomtbl` L9528-9533):

```csharp
,new Tuple<char, Func<enmPass2JumpTable>>('b', bdset)    // \b → BD   (= bit 0 = 0x01)
,new Tuple<char, Func<enmPass2JumpTable>>('s', snrset)   // \s → SD   (= bit 1 = 0x02)
,new Tuple<char, Func<enmPass2JumpTable>>('c', cymset)   // \c → CYM  (= bit 2 = 0x04)
,new Tuple<char, Func<enmPass2JumpTable>>('h', hihset)   // \h → HH   (= bit 3 = 0x08、 Step 14 対象)
,new Tuple<char, Func<enmPass2JumpTable>>('t', tamset)   // \t → TOM  (= bit 4 = 0x10)
,new Tuple<char, Func<enmPass2JumpTable>>('i', rimset)   // \i → RIM  (= bit 5 = 0x20、 `\r` ではない)
```

#### Step 14 HH 関連の確定

- **`\h` → hihset** (= mc.cs L9530 literal)
- hihset は `work.al = 8` を set して rs00 を呼ぶ (= ADR-0027 §Annex A-2 引用、 mc.cs L9697-9701 周辺)
- rs00 が `0xEB <al>` を emit (= ADR-0027 §Annex A-2 引用、 L9727-9750)
- 結果 `\h` 単独で `0xEB 0x08` emit (= bitmap bit 3 = HH)
- **fixture 命名 `k-hr-only.mml` / `r-melody-hr-only.mml` の `hr` = `\h` + `r`(= rest) pattern は妥当**、 rename 不要 (= ADR-0027 §Annex A-1 で `\h` 確認済 + 本 ADR で再確認)

### A-2: PMDDotNET hihset emit core path literal 再確認 (= ADR-0027 §Annex A-2 引用、 mc.cs L9691-9725)

drum 6 種 set 関数 → rs00 → `0xEB <bitmap>` emit:

```csharp
// mc.cs L9691-9725 (= ADR-0027 §Annex A-2 引用)
private enmPass2JumpTable bdset()  { work.al = 1;  return rs00(); }  // BD  = bitmap 0x01
private enmPass2JumpTable snrset() { work.al = 2;  return rs00(); }  // SD  = bitmap 0x02
private enmPass2JumpTable cymset() { work.al = 4;  return rs00(); }  // CYM = bitmap 0x04
private enmPass2JumpTable hihset() { work.al = 8;  return rs00(); }  // HH  = bitmap 0x08 (= Step 14 対象)
private enmPass2JumpTable tamset() { work.al = 16; return rs00(); }  // TOM = bitmap 0x10
private enmPass2JumpTable rimset() { work.al = 32; return rs00(); }  // RIM = bitmap 0x20
```

#### HH 単独 emit (= Step 14 fixture 期待 bytecode)

- `\h` + `r`(= rest) → `\h` (= hihset) → al = 8 → rs00 → rs02 path (= 新規 emit) → `0xEB 0x08`
- 続く `r` (= rest) は別 opcode 経路で処理 (= note rest length emit)
- fixture `k-hr-only.mml` の K part body 期待 bytecode = `0xEB 0x08 <rest length> ... 0x80` (= part end)
- 同様に `r-melody-hr-only.mml` の melody part body = `... 0xEB 0x08 <rest length> ... 0x80`

#### Step 14 driver 側 bitmap accept range 設計確認

ADR-0027 §Annex A-2 で確認済 + 本 ADR §決定 2 bitmap accept range と完全整合:

- bit 0 (= 0x01) = BD trigger (= 既存 Step 12 維持)
- bit 1 (= 0x02) = SD trigger (= 既存 Step 13 維持)
- bit 2 (= 0x04) = CYM trigger → silent ignore
- bit 3 (= 0x08) = HH trigger (= **本 ADR で新規追加**)
- bit 4 (= 0x10) = TOM trigger → silent ignore
- bit 5 (= 0x20) = RIM trigger (= `\i`) → silent ignore
- bit 6 = (PMD V4.8s pattern body 内専用 flag) → silent ignore
- bit 7 = (note byte 識別 flag、 mc.cs 内 'p' marker) → silent ignore

driver は bit 0 + bit 1 + bit 3 のみ accept、 残り bit は silent ignore (= ADR-0026 §決定 11 / ADR-0027 §決定 2 「未対応 cmd スルー」 思想踏襲)。

### A-3: PMDDotNET bitmap OR 圧縮 emit 動作 (HH 込み combo) literal 確認予定 (= α 着手で literal 反映、 ADR-0027 §Annex A-3 引用 + HH 込み追加調査)

#### ADR-0027 §Annex A-3 引用 (= BD+SD combo の bitmap OR 圧縮 path、 mc.cs L9736-9746)

`\b\s` を間に何も挟まず連続記述した場合の emit 挙動 (= ADR-0027 §Annex A-3 literal 確認済):

1. 最初の `\b` を bdset 経由で処理 → al = 1 → rs00 → rs02 path → `0xEB 0x01` emit + di += 2 + prsok = 0x80 set
2. 次の `\s` を snrset 経由で処理 → al = 2 → rs00 → rs01 path check → 3 条件全成立 → bitmap OR → al |= cch (= 0x02 | 0x01 = 0x03) → m_buf di-1 を 0x03 で上書き → 結果 bytecode = `0xEB 0x03` (= BD+SD bitmap OR 1 opcode)

#### Step 14 で追加調査する HH 込み combo 動作 (= α 着手で literal 反映予定)

- `\b\h` の連続記述 → 期待 emit = `0xEB 0x09` (= bit 0 | bit 3 = 0x01 | 0x08)
- `\s\h` の連続記述 → 期待 emit = `0xEB 0x0A` (= bit 1 | bit 3 = 0x02 | 0x08)
- `\b\s\h` の連続記述 → 期待 emit = `0xEB 0x0B` (= bit 0 | bit 1 | bit 3 = 0x01 | 0x02 | 0x08)
- 期待動作は ADR-0027 §Annex A-3 の bitmap OR 圧縮 path と同 pattern、 al |= cch で combo bitmap byte 1 個に圧縮
- α 着手で literal 動作確認 (= PMDDotNET compile + `.MN` hexdump で実 emit byte 列確認)

#### Step 14 fixture 設計への影響

Step 14 では simultaneous trigger combo scope-out (= ADR-0028 §決定 11 / 軸 4):

- `k-hr-only.mml` K part body = `\h r` 単独パターンのみ (= `\b\h` / `\s\h` / `\b\s\h` 並記なし)
- `r-melody-hr-only.mml` melody part body = `\h r` 単独パターンのみ
- bitmap 0x09 / 0x0A / 0x0B (= HH 込み combo) が emit される fixture は **生成しない**
- driver の bitmap accept range は bit 0 / bit 1 / bit 3 個別 accept (= 0x09 が来た場合、 仮に Step 14 driver が複数 bit を見れば BD + HH 両方 trigger される可能性あり、 ただし Step 14 fixture では combo emit 経路を踏まない)
- bitmap OR semantics の literal proof (= simultaneous trigger) は future 候補温存 (= ADR-0028 §決定 11 維持)

### A-4: PMD V4.8s manual literal 用例 (= `docs/manual/PMDMML_MAN_V48s_utf8.txt`、 ADR-0027 §Annex A-4 引用)

#### drum trigger 用例 (= L226-228、 ADR-0027 §Annex A-4 引用)

```
R0	l16[\sr]4
R1	l8 \br\hr\sr\hr
R2	   \br\tr\tr\tr
```

- L226 `\sr` = SD + rest (= 16 分音符 4 個列)
- **L227 `\br\hr\sr\hr` = BD + rest, HH + rest, SD + rest, HH + rest (= 8 分音符 4 個列、 BD+HH ペア)** ← **Step 14 で `\hr` が literal 用例として確認可能**
- L228 `\br\tr\tr\tr` = BD + rest, TOM + rest, TOM + rest, TOM + rest

#### Step 14 HH 関連の literal 確認

- **`\hr` (= HH + rest) は manual 内に literal 用例として記載** (= L227)
- HH は manual 内で BD+HH ペアとして頻出 (= pop / rock 基本 pattern と整合)
- fixture `k-hr-only.mml` / `r-melody-hr-only.mml` の `\hr` pattern は **manual 用例と integration 整合**

### A-5: `adpcma_sample_hh` driver-embedded 状況 literal 再確認 (= ADR-0027 §Annex A-6 引用、 standalone_test.s)

#### sample pointer table 内 reference (= ADR-0027 §Annex A-6 引用、 standalone_test.s L2871-2873)

```asm
; standalone_test.s L2871-2873 (= table A、 既存 Step 5 から不変)
adpcma_ch_sample_ptr_table:
        .dw     adpcma_sample_bd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top
```

- L = `adpcma_sample_bd` / M = `adpcma_sample_sd` / N = `adpcma_sample_hh` / O = `adpcma_sample_tom` / P = `adpcma_sample_rim` / Q = `adpcma_sample_top`
- L-Q ADPCM-A 6ch melody architecture 用 sample pointer table
- ADR-0019 §決定 3 build-time embed 流儀

#### `adpcma_sample_hh` literal embed (= ADR-0027 §Annex A-6 引用、 standalone_test.s L2893-2904)

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

- `adpcma_sample_hh` = 4 byte sample header (= start LSB/MSB + stop LSB/MSB)
- VROM 内 HH sample 実 data の addr 値は `HH_START_LSB` / `HH_START_MSB` / `HH_STOP_LSB` / `HH_STOP_MSB` macro で literal 定義 (= samples.inc 等の上位 include で確定、 ADR-0019 §決定 3 build-time embed)
- ADPCM-A subsystem 内既存 sample、 Step 14 で再利用可能 (= L-Q melody N ch sample と symbol 共有、 final rhythm sample ownership は未確定)

#### melody architecture sample symbol との sharing 状況

- L-Q melody N ch (= O part) sample 参照経路: `adpcma_ch_sample_ptr_table` 経由で `adpcma_sample_hh` literal addr load → N ch keyon 時に register write
- rhythm proof L ch (= 本 ADR + ADR-0026 / ADR-0027) sample 参照経路: `_rhythm_event_hh_trigger` 内で直接 `adpcma_sample_hh` literal addr load → L ch keyon 時に register write
- 同 symbol 共有 + 異 ch slot 書込み (= register bank 軸で分離)
- read タイミング軸で collision しない限り実際響く (= melody O part が音符を出していない瞬間に rhythm K part が `\h` を出す等の使用 pattern では問題なし)

### A-6: bit 3 HH 分岐追加の literal asm 候補 (= β 着手前、 explicit if/jr 流儀、 ADR-0027 §Annex A-7 同 pattern)

#### Step 13 完成時 `pmdneo_rhythm_event_trigger` routine 構造 (= ADR-0027 §決定 4 / commit `36588b3`)

```asm
; standalone_test.s 内 想定 既存 (= Step 13 β/γ 確立後)
pmdneo_rhythm_event_trigger:
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 2-5 = silent ignore (= Step 13 b+s proof)
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
```

(= 実 literal asm は β commit 着手時に Read で確認、 ADR-0028 Annex A は概念図のみ)

#### Step 14 β で追加する bit 3 分岐 (= explicit if/jr 流儀踏襲)

```asm
; standalone_test.s β commit で導入予定
pmdneo_rhythm_event_trigger:
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 3 = HH / bit 2/4/5 = silent ignore
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
    push    af
    bit     3, a
    jr      z, _rhythm_event_no_hh
    call    _rhythm_event_hh_trigger
_rhythm_event_no_hh:
    pop     af
    ret

_rhythm_event_bd_trigger:
    ; adpcma_sample_bd を ADPCM-A L ch に register write (= Step 12 既存実装)
    ...
    ret

_rhythm_event_sd_trigger:
    ; adpcma_sample_sd を ADPCM-A L ch に register write (= Step 13 既存実装)
    ...
    ret

_rhythm_event_hh_trigger:
    ; adpcma_sample_hh を ADPCM-A L ch に register write (= Step 14 新規実装、 既存 symbol reuse)
    ld      hl, #adpcma_sample_hh
    ; ... reg 0x10 / 0x18 / 0x20 / 0x28 / 0x08 / 0x00 keyon mask 0x01 write
    ret
```

#### Step 14 β commit 実装方針

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は **不変保持** (= ADR-0028 §決定 9 維持)
- routine 内部の bit 0 BD 分岐 + bit 1 SD 分岐は **完全不変** (= Step 12 / Step 13 既存 BD/SD path regression 維持、 ADR-0028 §決定 7)
- bit 3 HH 分岐は bit 1 分岐の **直後** に追加 (= explicit if/jr 流儀踏襲、 ADR-0024 / 0025 / 0026 / 0027 同 pattern)
- `_rhythm_event_hh_trigger` label 新規追加 (= BD/SD trigger と同 register write sequence で sample addr のみ `adpcma_sample_hh` 参照)
- ABI 不変 (= 引数 = a レジスタ bitmap、 戻り値 = なし、 caller 不変)

#### dispatch path 1 本化の literal 維持確認

- K-BD / R-BD / K-SD / R-SD / K-HH / R-HH 全 fixture で PC trace hit addr = 0x1126 (= entry 不変、 ADR-0028 §決定 1 / §決定 4 / §決定 9 維持)
- routine 内部の bit 3 分岐追加 + `_rhythm_event_hh_trigger` sub-routine 新規は **internal implementation 拡張** であって dispatch path 新設ではない (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 維持)

### A-7: fail-safe 条件 evaluate (= β 進行可判定、 α 着手で literal 反映予定)

#### 条件 1: 「PMDDotNET HH emit 記号が `\h` でない」

α 調査結果予定: **`\h` で確定** (= ADR-0027 §Annex A-1 で literal 確認済、 mc.cs L9530 literal `'h' → hihset`、 §Annex A-1 / §Annex A-2 参照)。

- 条件不成立 (= fail-safe 該当せず)
- fixture 命名 `k-hr-only.mml` / `r-melody-hr-only.mml` の `hr` = `\h` + `r`(rest) pattern は妥当
- rename 不要

#### 条件 2: 「`adpcma_sample_hh` が ADPCM-A subsystem 内に embed されていない」

α 調査結果予定: **embed 済** (= ADR-0027 §Annex A-6 で literal 確認済、 standalone_test.s L2895 周辺、 §Annex A-5 参照)。

- 条件不成立 (= fail-safe 該当せず)
- ADR-0025 step 11 で L-Q architecture N ch sample として embed 済、 Step 14 で新規 embed 不要 (= rhythm proof 用に symbol reuse)

#### 条件 3 (= 本 ADR α で追加調査軸): 「HH 込み bitmap OR combo emit が想定外動作する」

α 調査結果予定: **想定通り bitmap OR 圧縮** (= ADR-0027 §Annex A-3 BD+SD combo pattern と同 path、 al |= cch で combo byte 1 個圧縮)。

- 条件不成立 (= fail-safe 該当せず)
- Step 14 fixture では combo emit 経路を踏まない (= simultaneous trigger scope-out、 ADR-0028 §決定 11)

#### β 進行判定 (= α 完了後 literal 確認)

3 条件いずれにも該当せず予定、 **β 進行可** (= α 完了時に literal 確認 + 本 Annex A 反映完了で確定)。

β commit 内容 (= ADR-0028 §sub-sprint 構造表):

- `pmdneo_rhythm_event_trigger` routine に bit 3 HH 分岐追加 (= §Annex A-6 asm 候補)
- `_rhythm_event_hh_trigger` label 新規 (= `adpcma_sample_hh` literal addr 参照、 既存 symbol reuse)
- `k-hr-only.mml` fixture 新規追加 (= K part `\h` + `r` pattern)
- `verify-step14-hh-trigger.sh` 新規追加 (= K-HH register write trace + keyon count + PC marker @ 0x1126)
- 全 step12 + step13 BD/SD path regression PASS 維持 (= ADR-0028 §決定 7)

α 完了 (= driver / fixture / verify script 完全不変純調査、 ADR-0028 §Annex A 7 sub-section literal 反映、 1 commit + 1 push)。

## 関連

- ADR-0027 (= step 13 K/R drum kind expansion proof — s = SD)
- ADR-0026 (= step 12 K/R rhythm compatibility proof)
- ADR-0025 (= step 11 multi-table id=0x01 proof)
- ADR-0024 (= step 10 sample_table_id selection consumption)
- ADR-0019 (= step 5 §決定 3 sample addr build-time embed)
- ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive)
- `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax、 L227 `\hr` literal 用例)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- memory `project-pmdneo-step13-complete`
- memory `project-pmdneo-step14-direction-hh-expansion` (= 本 ADR 起票で literal 反映予定、 δ で起票)
- memory `project-pmdneo-adpcma-subsystem-boundary`
- memory `project-pmd-rim-drum-char-correction` (= ADR-0027 §Annex A-1 RIM 文字訂正、 本 ADR で literal 再確認)
- memory `feedback-audio-gate-solo-isolation`
- memory `feedback-verify-script-serial-execution`
- memory `feedback-refactor-gate-register-trace-not-wav`
- memory `feedback-push-per-commit`
- memory `feedback-post-commit-push-report-format`
- memory `feedback-explain-in-plain-japanese-before-commit`
