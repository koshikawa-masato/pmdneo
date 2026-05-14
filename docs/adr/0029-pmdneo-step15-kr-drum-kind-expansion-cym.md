# ADR-0029: Step 15 — K/R drum kind expansion proof (c = CYM single-kind / dispatch path 1 本化不変 / 既存 adpcma_sample_top symbol reuse / BD+SD+HH fixture 不変 + CYM fixture 2 件新規 / 3 軸 verify)

- 状態: **Accepted** (= 2026-05-14 16th session δ 完了統合で移行、 元 Draft 起票 2026-05-14 16th session 冒頭、 ADR/β/γ/δ 4 commit chain 全 PASS + user audio gate OK + 全 26 script regression PASS で Accepted 移行、 注: ADR-0028 同型 sub-sprint 5 段表 (= ADR/α/β/γ/δ) のうち α 段は user 着手判断で ADR Draft commit に統合 = ADR-0028 §Annex A-1 / §Annex A-2 で `\c → cymset → 0xEB 0x04` literal 確認済を ground truth として独立 α commit なしで β 進行)
- 起票日: 2026-05-14
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0028 (= step 14 K/R drum kind expansion proof — h = HH、 §決定 8 「dispatch path は drum 種拡張で増やさない」 + §決定 2 「b+s+h proof」 + §scope-out 「c/t/i 残り 3 種」 を本 ADR で 1 軸消化、 §Annex A-1 で `'c' → cymset` literal 確認済 + §Annex A-2 で `cymset` = `work.al = 4; return rs00();` literal 確認済 + §Annex A-5 で `adpcma_sample_top` standalone_test.s L2895-2904 内 embed 済 literal 確認済)、 ADR-0027 (= step 13 K/R drum kind expansion proof — s = SD、 §決定 8 「dispatch path は drum 種拡張で増やさない」)、 ADR-0026 (= step 12 K/R rhythm compatibility proof、 §決定 6 「dispatch path 1 本化」)、 ADR-0025 (= step 11 multi-table id=0x01 proof、 §決定 1 A2 cache scope-out 維持)、 ADR-0024 (= step 10 sample_table_id selection consumption、 explicit if/jr 流儀踏襲)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 §決定 4 sample 増加は別 sprint 接続点予約)、 ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive → step 12 で reconnected → step 13 で b+s → step 14 で b+s+h → 本 ADR で b+s+c+h drum kind 1 軸拡張)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様、 drum 識別文字 = `b/s/c/h/t/i` 6 種 = PMDDotNET mc.cs rcomtbl L9528-9533 literal、 本 ADR §Annex A-1 で literal 引用)

## 背景

Step 14 (= ADR-0028 Accepted、 2026-05-14 15th session、 commit `3b60049`) で K/R drum kind expansion proof — h = HH sprint が成立した。 driver は PMD V4.8s 系 K part `\h` + melody part inline `\h` の 2 系統 MML syntax を、 PMDDotNET `0xEB 0x08` bytecode を経て driver `.MN` direct parser で normalize し、 `pmdneo_rhythm_event_trigger` (@ 0x1126) entry addr 不変を維持しつつ routine 内部の bit 3 HH 分岐 + 独立 sub-routine `_rhythm_event_hh_trigger` (@ 0x1193) で `adpcma_sample_hh` を ADPCM-A L ch に register write する contract chain を、 PC trace + ymfm-trace 二段 gate + byte-identical literal proof + BD/HH sample addr literal differ で literal 観測可能にした。

ADR-0028 §決定 2 で確立した「drum kind = b + s + h proof」 と、 §決定 8 で確立した「**dispatch path は drum 種拡張で増やさない**」 という 2 つの contract に対し、 Step 15 はその **自然な 1 軸拡張** を担う:

- 「**drum 種を b + s + h (= BD + SD + HH only) から b + s + c + h (= CYM 追加、 計 4 drum) に 1 軸拡張**」
- 「**dispatch path は不変 (= `pmdneo_rhythm_event_trigger` @ 0x1126 entry addr 継続)**」 → ADR-0028 §決定 8 が 4 drum 状況下で literal 維持されることの proof
- 「**sample pointer mapping のみ拡張**」 (= bit 0 → BD addr / bit 1 → SD addr / bit 2 → CYM addr / bit 3 → HH addr、 bit 4/5 silent ignore 維持)

ADR-0028 §決定 8 (= drum 種拡張で dispatch path 不変) と §決定 11 (= scope-out 28+ 項目維持) の延長で、 K/R semantics の MML 互換 surface area を **drum kind 軸 1 段** だけ広げる小規模 proof sprint。 「drum kind expansion proof」 という言葉自体が示すように、 sample asset 軸 / channel 軸 / runtime parser 軸 / dispatch refactor 軸 / simultaneous trigger 軸は触らない。

ただし「drum kind expansion」 と素朴に定義すると scope が再び肥大化する (= 全 2 残 drum 一気 / 全 4 drum simultaneous trigger semantics / channel allocation 改定 / `.PNE` rhythm bank migration / 制御 cmd 現役化 / dispatch table-driven 化 等を同時に触る)。 15th session 末 user 直接指示 + 16th session 冒頭壁打ち で以下の方針整理が確定:

- **drum 種拡張軸 = bit 2 CYM のみ accept** (= 残 2 drum 一気は scope-out、 t/i 残り 2 種 future) (= 軸 1)
- **BD+SD / BD+HH / SD+HH / BD+CYM / SD+CYM / HH+CYM / 3+ combo 同時打ち scope-out** (= bitmap OR semantics literal proof は future 候補温存) (= 軸 4)
- **CYM sample source = existing `adpcma_sample_top` symbol reuse as driver-embedded proof fixture** (= ADR-0027 §決定 3 SD = 既存再利用 pattern + ADR-0028 §決定 3 HH = 既存再利用 pattern 踏襲、 L-Q melody architecture Q ch sample と同 symbol を rhythm proof で再利用、 「top」 は sample provenance 名 / 「CYM」 は PMD semantics 名 で wording 分離、 alias 新設なし、 final rhythm sample ownership は未確定) (= 軸 1)
- **fixture = `k-cr-only.mml` + `r-melody-cr-only.mml` 2 件新規 + BD/SD/HH fixture 完全不変** (= 8 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM、 命名 = `\c` + `r`(= rest) pattern、 CYM 略称ではない) (= 軸 2)
- **verify gate = 3 軸** (= CYM trigger 単独 + K-CYM vs R-CYM differential + BD vs CYM differential、 keyon count identical + PC marker hit + ymfm-trace literal register value assert、 ADR-0028 §verify gate pattern 踏襲) (= 軸 5)
- **dispatch 構造 = hybrid (= Step 14 sub-routine pattern 踏襲 + `_rhythm_event_cym_trigger` 独立 sub-routine 追加 + table-driven refactor は scope-out)** (= 軸 3 / 軸 5)
- **bit 2 = CYM 分岐の挿入位置 = bit 1 と bit 3 の間** (= PMD bitmap bit 順序維持、 future bit 4 TOM / bit 5 RIM 追加時も同 順序で挿入可能、 dispatch entry addr 0x1126 不変 + internal sub-routine entry addr は再 shift 許容) (= 軸 3)

これに基づき Step 15 を **「K/R drum kind expansion proof — c = CYM」** として定義する。 ADR-0028 dispatch path 1 本化を **4 drum 状況下で literal 維持** することの proof であり、 「dispatch path は drum 種拡張で増やさない」 が Step 15 で 4 drum 段で実装的に保証される (= 3 drum 段 → 4 drum 段 漸進拡張)。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 Step 15 着手前に方針を ADR として独立起票する。

### 16th session 冒頭壁打ちでの 6 軸方針確定

ADR-0029 起票前に user 主導で 5 軸 + 軸 6 (= sub-sprint 構成) の壁打ちが行われ、 Step 15 の出口像が以下に固定された (= 軸 1-5 は ADR-0028 と同 pattern、 軸 6 sub-sprint は ADR-0028 と同 4 段)。

**軸 1: CYM sample source = existing `adpcma_sample_top` symbol reuse**

CYM trigger で使う sample (= 軸 1 / (cym_s1) 採用):

- (cym_s1) (= **採用**): existing `adpcma_sample_top` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 + ADR-0028 §決定 3 HH = 既存再利用 pattern 踏襲、 melody architecture Q ch sample symbol と現段階で共有、 rhythm-dedicated symbol 分離は scope-out、 「top」 は sample provenance 名 / 「CYM」 は PMD semantics 名 で wording 分離)
- (cym_s2) (= 不採用): new alias symbol `adpcma_sample_cym` 追加 (= 同 VROM data に対する別名 symbol、 PMD semantics 名と sample provenance 名の明示分離効果、 ただし driver 差分が増え命名整理目的だけのための ADR 肥大化)
- (cym_s3) (= 不採用): 別 sample (= HH / SD 等) を temporarily 流用 (= 区別困難で audio gate で BD/SD/HH/CYM 区別が損なわれる)
- (cym_s4) (= 不採用): 完全新規 sample data + symbol を VROM に追加 (= ADR-0027 SD / ADR-0028 HH pattern inconsistent + VROM 容量増 + samples.inc 拡張 + ADPCM-A converter 走らせる手間)

(cym_s1) 採用根拠: Step 15 目的は drum kind expansion proof で sample source proof / symbol separation proof ではない、 既存 `adpcma_sample_top` は ADR-0025 step5b で ADPCM-A subsystem 内に embed 済で再利用可、 ADR-0027 SD pattern + ADR-0028 HH pattern 踏襲で consistency 維持、 BD/SD/HH/CYM 4 symbol 間で literal addr differ が既に確保される (= bd / sd / hh / top 4 symbol それぞれ違う sample header literal addr)、 PMD/OPN rhythm では CYM は TOP cymbal 相当として扱うのが自然 (= asset 側 `2608_TOP.adpcma` で provenance 明確)、 driver サイズ / VROM / asset pipeline 不変、 final rhythm sample ownership は未確定で `.PNE` rhythm bank migration を future に温存。

ADR / handoff 記載要件:
- CYM sample source = **existing `adpcma_sample_top` symbol reuse**
- 新規 `adpcma_sample_cym` alias = **作らない** (= 命名整理目的だけの driver 差分追加を避ける)
- 新規 sample import = **scope-out**
- 「top」 = **sample provenance 名** (= asset 由来 = `2608_TOP.adpcma`、 L-Q melody architecture Q ch sample symbol)
- 「CYM」 = **PMD semantics 名** (= PMD MML 記号 `\c`、 PMD V4.8s `cymset`)
- PMD MML 記号は `\c` (= ADR-0028 §Annex A-1 で literal 確認済、 mc.cs rcomtbl L9528-9533 = `'c' → cymset`)
- `.PNE` rhythm bank migration = **future** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 future migration path 継続)
- Step 15 は **drum kind expansion proof**、 sample source proof / symbol separation proof ではない
- bit 0 → `adpcma_sample_bd` / bit 1 → `adpcma_sample_sd` / bit 2 → `adpcma_sample_top` / bit 3 → `adpcma_sample_hh` の mapping を driver source 内に literal 配置
- melody sample symbol (= L-Q architecture Q ch) と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

**軸 2: fixture 体制 = BD/SD/HH fixture 完全不変 + CYM fixture 2 件新規 (= 16th session 冒頭確定)**

K-CYM / R-CYM fixture 取り扱い:

- (fix1) (= **採用**): 8 fixture 体制 (= 既存 6 fixture 完全不変 + `k-cr-only.mml` + `r-melody-cr-only.mml` 新規追加)
- (fix2) (= 不採用): 6 fixture 維持 (= 既存 HH fixture を CYM 版に置換、 HH regression script が消失)
- (fix3) (= 不採用): BD/SD/HH/CYM 4-way 単一 fixture (= K-R differential verify がやりにくい + simultaneous trigger との境界が曖昧化)
- (fix4) (= 不採用): K-CYM のみ (= R-CYM 省略、 K-R dispatch shared invariant が CYM で verify されない)

(fix1) 採用根拠: Step 12 BD proof + Step 13 SD proof + Step 14 HH proof を regression として残せる、 Step 15 CYM proof を独立追加できる、 BD/SD/HH path を壊していないことを継続確認できる (= 「動いているものを壊さない」 規律遵守)、 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM の 8 fixture 体制が読みやすい、 全 4 drum 同時打ち scope-out 前提で単一 fixture に混ぜない方が良い。

命名規則:

- `k-cr-only.mml` (= K part 内 `\c` + `r`(= rest)、 既存 `k-br-only.mml` / `k-sr-only.mml` / `k-hr-only.mml` と 1 文字違い)
- `r-melody-cr-only.mml` (= melody part L 内 inline `\c` + `r`(= rest)、 既存 `r-melody-br-only.mml` / `r-melody-sr-only.mml` / `r-melody-hr-only.mml` と 1 文字違い)
- `cr` の `c` = `\c` (= CYM trigger 識別文字、 ADR-0028 §Annex A-1 mc.cs rcomtbl L9528-9533 literal 確認済) + `r` = rest 専用文字
- `cr` は **「CYM」 略ではない** (= 既存 `br` / `sr` / `hr` と同 命名 pattern、 drum 略称命名 ではなく fixture pattern 命名 = `\<drum 識別文字>` + `r`(rest))

ADR / handoff 記載要件:
- BD/SD/HH fixture (= `k-br-only.mml` / `r-melody-br-only.mml` / `k-sr-only.mml` / `r-melody-sr-only.mml` / `k-hr-only.mml` / `r-melody-hr-only.mml`) は **完全不変**
- CYM fixture 2 件 (= `k-cr-only.mml` / `r-melody-cr-only.mml`) を新規追加
- fixture 名の `cr` は **`\c` + `r`(rest) fixture pattern** であり「CYM」 略ではない (= 既存 `br` / `sr` / `hr` pattern と統一、 future contributor 向け literal 注記、 ADR + handoff doc 必須記載)
- verify token は **`cym` (= 3 char、 drum semantics 名)** (= fixture pattern token と区別、 verify script は人間が読む proof 名なので semantics 名優先、 既存 sd / hh の 2 char 統一は drum 名可変長として割り切る)
- α 調査で PMDDotNET が CYM を `\c` として emit することを literal 確認 (= ADR-0028 §Annex A-1 で既に literal 確認済、 α 調査で再確認 + Annex A 反映)
- BD/SD/HH/CYM 4-way 差分は verify script で literal に確認 (= BD vs CYM differential 1 script、 SD vs CYM / HH vs CYM differential は scope-out、 推移的に proof 成立)

**軸 3: bit 2 mapping = bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH accept、 bit 4/5 silent ignore**

軸 1 / 軸 3 回答内で確定済の bit mapping:

- bit 0 = BD trigger (= 既存 ADR-0026 維持)
- bit 1 = SD trigger (= 既存 ADR-0027 維持)
- bit 2 = CYM trigger (= 本 ADR で新規追加)
- bit 3 = HH trigger (= 既存 ADR-0028 維持)
- bit 4 (= TOM、 `\t`) / bit 5 (= RIM、 `\i` で trigger、 `\r` ではない) → silent ignore
- bit 6-7 = reserved
- bitmap = 0x00 = no-op
- bitmap = 0x03 / 0x05 / 0x06 / 0x07 / 0x09 / 0x0A / 0x0B / 0x0C / 0x0D / 0x0E / 0x0F (= BD+SD / BD+CYM / SD+CYM / BD+SD+CYM / BD+HH / SD+HH / BD+SD+HH / CYM+HH / BD+CYM+HH / SD+CYM+HH / BD+SD+CYM+HH 同時打ち) → bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4、 動作は α 調査で literal 確認 + Annex A 反映、 Step 15 fixture では生成しない)

#### bit 2 = CYM 分岐の挿入位置 = bit 1 と bit 3 の間 (= PMD bitmap bit 順序維持、 軸 3 確定)

dispatch path 内 bit 2 = CYM 分岐挿入位置:

- (b1) (= **採用**): bit 1 と bit 3 の間 (= PMD bitmap bit 順序 0/1/2/3 維持)
- (b2) (= 不採用): bit 3 の後 (= 追加順序、 bit 3 HH を call nz に変更 + bit 2 を tail jr 末尾化、 instruction 数最小だが bit 順序混乱の risk)
- (b3) (= 不採用): 全 bit を uniform pattern に refactor (= tail jr 廃止、 ADR-0028 hybrid pattern 踏襲 + table-driven refactor scope-out wording と inconsistent)

(b1) 採用根拠: future bit 4 TOM / bit 5 RIM 追加時も同 順序で挿入可能、 PMD bitmap bit 0/1/2/3/4/5 の natural order との整合性、 ADR-0028 で SD trigger sub-routine entry addr が 0x115F → 0x1166 literal shift observed と同 pattern で internal sub-routine entry addr の再 shift は許容 (= invariant の本質は shared dispatch entry 不変 + register write sequence 不変)、 dispatch path entry addr 0x1126 は不変、 BD/SD trigger path 完全不変、 HH trigger path 内部不変で entry addr のみ shift。

**軸 4: simultaneous trigger scope-out 維持**

軸 1 / 軸 4 回答内で確定済の simultaneous trigger:

- BD+SD / BD+CYM / SD+CYM / BD+SD+CYM / BD+HH / SD+HH / CYM+HH / BD+SD+HH / BD+CYM+HH / SD+CYM+HH / BD+SD+CYM+HH 同時打ち = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 16+ 候補、 simultaneous trigger semantics proof sprint として独立起票)
- Step 15 fixture は **BD 単独 / SD 単独 / HH 単独 / CYM 単独 のみ**
- driver 上で動く可能性 (= dispatch path 内で bit ごとに独立判定で combo bitmap も harmful なし) と、 仕様化 (= ADR 内で「未定義」 明記) は別軸
- combo bitmap が ADR 内で「未定義」 と明記される (= driver 動作は incidental observation、 仕様としては未定義)

**軸 5: verify gate = 3 軸 + dispatch 構造 = hybrid (sub-routine pattern 踏襲 + table-driven scope-out)**

verify 範囲:

- (v1) (= **採用**): 3 軸 verify (= CYM trigger 単独 + K-CYM vs R-CYM differential + BD vs CYM differential)
- (v2) (= 不採用): 4 軸 verify (= 3 軸 + SD vs CYM differential、 N drum ごとに verify script 増殖)
- (v3) (= 不採用): 5 軸 verify (= 3 軸 + SD vs CYM + HH vs CYM、 N(N-1)/2 mutual differential 増殖、 ADR-0028 §scope-out 「SD vs HH は推移的区別」 precedent inconsistent)

(v1) 採用根拠: Step 15 目的は「CYM が鳴る」 だけではなく drum kind expansion proof、 K と R が同じ CYM dispatch path を通ることを確認する必要がある (= dispatch path 1 本化の 4 drum 状況下での維持)、 BD と CYM が register / sample address 上で区別できる必要がある (= drum kind mapping の literal proof)、 BD/SD/HH path regression も同時に守れる、 silent path に倒れただけではないことを確認できる、 SD vs CYM / HH vs CYM 推移的区別は ADR-0028 §verify gate Gate 4 注記 pattern 踏襲で literal proof 成立 (= BD-vs-SD + BD-vs-HH + BD-vs-CYM から N-1 pair gate で N 軸 mutual differential を推移的に確立)。

dispatch 構造:

- (d1) (= **採用**): hybrid = Step 14 sub-routine pattern 踏襲 + `_rhythm_event_cym_trigger` 独立 sub-routine 追加 + bit 2 分岐挿入位置 = bit 1 と bit 3 の間 + table-driven refactor は scope-out
- (d2) (= 不採用): table-driven (= bit → sample addr lookup table に集約、 dispatch path + sub-routine も 1 本に帰結)
- (d3) (= 不採用): Step 14 sub-routine pattern 踏襲のみ、 future refactor 言及なし

(d1) 採用根拠: Step 15 目的は「c = CYM expansion proof」、 ここで table-driven 化すると drum 種追加 proof と dispatch refactor が混ざる、 Step 14 と同型にすることで BD/SD/HH/CYM の differential proof が読みやすい、 t/i を足し終わった後 (= 6 drum 段到達後) に table-driven 化する方が判断材料が揃う、 dispatch path 不変の本質は entry point と runtime event path が増えないことなので内部 sub-routine 追加は許容、 `pmdneo_rhythm_event_trigger` entry addr 不変が primary invariant、 `_rhythm_event_cym_trigger` は proof 用 explicit branch (= future table-driven 化対象)、 full drum set 到達後 (= b/s/c/h/t/i 6 drum) に table-driven refactor を検討。

verify gate 構成:

```
K-CYM:
  bit2 → CYM trigger (= ADPCM-A L ch CYM register write trace + keyon count + PC marker)

R-CYM:
  bit2 → 同じ CYM trigger (= K-CYM vs R-CYM byte-identical literal proof + PC marker)

BD vs CYM:
  bit0 と bit2 で sample addr が違う (= reg 0x10 sample addr literal differ + reg 0x18 sample end addr literal differ)
```

加えて (= ADR-0028 §verify gate 規律踏襲):

- **keyon count identical** (= K-CYM と R-CYM で ADPCM-A L ch keyon mask 0x01 trigger count 同一)
- **PC marker hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126 PC trace hit、 K-CYM / R-CYM 両方で同 addr hit)
- **ymfm-trace literal register value assert** (= sample addr reg 値を literal 数値で assert、 visual diff ではなく数値 assert)

ADR / handoff 記載要件:
- verify gate は **3 軸 (= CYM trigger + K-CYM vs R-CYM differential + BD vs CYM differential)**
- 3 件の verify script を新規追加
- `verify-step15-cym-trigger.sh` (= K-CYM / R-CYM 各 fixture で CYM register write trace + keyon count + PC marker)
- `verify-step15-kr-cym-differential.sh` (= K-CYM vs R-CYM byte-identical literal proof)
- `verify-step15-bd-cym-differential.sh` (= BD vs CYM sample addr literal differ proof)
- SD vs CYM / HH vs CYM 推移的区別は ADR-0028 precedent 踏襲で explicit gate 不要 (= 推移的 proof 成立)
- 既存 23 script regression に 3 件追加 = 26 script 体制
- dispatch 構造 = **hybrid** (= Step 14 sub-routine pattern 踏襲 + `_rhythm_event_cym_trigger` 独立 sub-routine 追加 + table-driven refactor は future scope-out)
- mutual pairwise explosion を避ける (= BD-vs-SD / BD-vs-HH / BD-vs-CYM から推移的に drum 種差分を扱う規律)

**軸 6: sub-sprint 構成 = ADR-0028 同型 4 段 (= ADR / β / γ / δ)**

sub-sprint 構成:

- (s1) (= **採用**): 4 sub-sprint = α (= ADR-0029 Draft 起票、 doc only commit) + β (= driver bit 2 分岐 + `_rhythm_event_cym_trigger` sub-routine + K-CYM fixture + `verify-step15-cym-trigger.sh`) + γ (= R-CYM fixture + `verify-step15-kr-cym-differential.sh` + `verify-step15-bd-cym-differential.sh`) + δ (= 完了統合 + ADR Accepted + memory + MEMORY.md index)
- (s2) (= 不採用): 5 sub-sprint (= α/β/γ/δ/ε、 γ と δ を分割、 commit 粒度細かいが冗長)
- (s3) (= 不採用): 3 sub-sprint に圧縮 (= α/β/γ、 driver + 全 fixture + 全 verify を 1 commit に同梱、 PR レビュー粒度粗化 + 異常時の原因特定困難化)

(s1) 採用根拠: ADR-0028 / ADR-0027 と同型 4 段 = pattern 安定、 1 sub = 1 commit + 1 push 規律遵守、 audio gate は δ 前 (= γ 完了時) に user 試聴、 各 sub で全 step12 + step13 + step14 BD/SD/HH path verify script PASS が確認できる粒度。

## 決定

### 決定 1: Step 15 を「K/R drum kind expansion proof — c = CYM」 として定義 (= bit 2 CYM 1 軸拡張、 dispatch path 1 本化不変、 既存 adpcma_sample_top symbol reuse、 BD/SD/HH fixture 不変 + CYM fixture 2 件新規、 3 軸 verify、 hybrid dispatch 構造、 bit 2 挿入位置 = bit 1 と bit 3 の間)

Step 15 の最終 deliverable boundary を **「K part `\c` + melody part inline `\c` の 2 系統 MML syntax を受取り、 driver `.MN` direct parser で normalize して、 共通 routine `pmdneo_rhythm_event_trigger` 経由で bit 2 分岐 → `_rhythm_event_cym_trigger` sub-routine → 既存 `adpcma_sample_top` symbol reuse → ADPCM-A L ch CYM trigger に audible に dispatch する」** とする。 PMDDotNET / `.MN` format / `pmdneo_rhythm_event_trigger` routine entry / observability marker / driver-embedded fixture 規律は完全不変、 drum 種 → sample pointer mapping table のみ bit 0 → BD + bit 1 → SD + bit 2 → CYM + bit 3 → HH に 1 軸拡張、 PC trace + ymfm-trace の 3 軸 gate (= CYM trigger + K-CYM vs R-CYM differential + BD vs CYM differential) で **drum kind expansion 後 (= 4 drum 段) も dispatch path が 1 本化されていること** + **drum 種で sample addr が literal 区別されること** を literal 観測可能にすることを目的とする。

#### Step 14 → Step 15 拡張点

ADR-0028 で確立した contract のうち、 Step 15 で **拡張** されるのは:

- driver の K/R 受入 drum 種範囲: b + s + h (= BD + SD + HH) → b + s + c + h (= BD + SD + CYM + HH)
- driver-embedded sample 表 entry 数: BD + SD + HH 3 種 → BD + SD + CYM + HH 4 種 (= 既存 `adpcma_sample_top` symbol reuse、 新規 embed なし)
- drum 種 → sample pointer mapping: bit 0 + bit 1 + bit 3 → bit 0 + bit 1 + bit 2 + bit 3
- fixture 数: 6 件 (= K-BD + R-BD + K-SD + R-SD + K-HH + R-HH) → 8 件 (= + K-CYM + R-CYM)
- verify script 数: step12 系 4 件 + step13 系 3 件 + step14 系 3 件 = 10 件 → step12 系 4 件 + step13 系 3 件 + step14 系 3 件 + step15 系 3 件 = 13 件
- 全 regression script 数: 23 件 → 26 件 (= step12 / step13 / step14 既存 + step15 新規 3 件)
- driver sub-routine 数: bit 0 BD + bit 1 SD + bit 3 HH 3 sub-routine → bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH 4 sub-routine

Step 15 で **不変** に保つもの:

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126、 ADR-0028 §決定 9 PC marker 維持) ← **invariant の primary 軸 = shared dispatch entry**
- `pmdneo_rhythm_event_trigger` routine 構造 (= bit 0 / bit 1 / bit 3 分岐既存、 bit 2 分岐を bit 1 と bit 3 の間に新規追加するが routine entry / 引数 / 戻り値 ABI は不変)
- `_rhythm_event_bd_trigger` sub-routine の **register write sequence** (= Step 12 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で shift 可)
- `_rhythm_event_sd_trigger` sub-routine の **register write sequence** (= Step 13 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 15 改修で再 shift observed 想定)
- `_rhythm_event_hh_trigger` sub-routine の **register write sequence** (= Step 14 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 15 改修で再 shift observed 想定)

#### invariant 精密化 (= ADR-0028 §invariant 精密化引用)

**invariant の本質は「sub-routine entry addr 不変」 ではなく「shared dispatch entry 不変 + register write sequence 不変」**:

- **shared dispatch entry 不変**: `pmdneo_rhythm_event_trigger` entry addr (= 0x1126) は Step 12/Step 13/Step 14/Step 15 で完全同一 literal 維持 (= K/R 両 source path が同 entry に collapse)
- **register write sequence 不変**: 各 drum trigger sub-routine 内の 6 件 reg write (= reg 0x10/0x18/0x20/0x28/0x08/0x00 + literal value) は drum 種ごとに sample addr literal differ するが sequence 構造は完全不変、 既存 drum (= BD / SD / HH) の sequence は Step 15 改修後も literal で不変
- **internal sub-routine entry addr は不変保証対象ではない**: dispatcher 改修 (= bit 2 分岐追加 + bit 1 SD call nz 後の pop af 追加 + bit 3 HH 既存 pattern 維持) で routine 内 bytecode が増加 → 後続 sub-routine (= `_rhythm_event_sd_trigger` / `_rhythm_event_hh_trigger`、 future `_rhythm_event_cym_trigger`) の entry addr が shift する可能性あり (= Step 14 で literal observed、 Step 15 で再 shift 想定)、 これは正常動作
- verify script 側も sub-routine entry addr literal value を hard-code assert せず、 symbol 存在 + K=R addr identical で proof 成立する設計 (= ADR-0028 §verify gate Gate 2 / Gate 3 pattern 踏襲)
- PMDDotNET (= C# compile path) は完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 維持)
- `.MN` format は完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う、 ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 維持)
- 既存 L-Q ADPCM-A melody architecture (= ADR-0019 / ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 / ADR-0025 で確立)
- selected pointer runtime state cache 不採用 (= ADR-0024 §決定 6 / ADR-0025 §決定 1 / ADR-0026 §決定 11 / ADR-0027 §決定 1 / ADR-0028 §決定 1 維持)
- `sample_table_id` resolver / selector の ABI (= Step 9-11 で確立)
- sentinel pointer 0x0000 silent semantics
- driver SRAM layout (= 0xFD20-0xFD32 既存領域、 Step 15 で新規 marker byte を追加しない)
- multi-table id=0x01 differentiation proof contract (= ADR-0025 全 §決定)
- K/R rhythm event dispatch proof contract (= ADR-0026 / ADR-0027 / ADR-0028 全 §決定、 §決定 2 「b-only proof」 → 「b + s proof」 → 「b + s + h proof」 → 本 ADR §決定 2 「b + s + c + h proof」 に literal 更新、 dispatch path 1 本化不変原則は維持)
- `.PNE` / `.MN` asset pipeline (= ADR-0021 で確立)
- BD fixture (= `k-br-only.mml` / `r-melody-br-only.mml`) 完全不変
- SD fixture (= `k-sr-only.mml` / `r-melody-sr-only.mml`) 完全不変
- HH fixture (= `k-hr-only.mml` / `r-melody-hr-only.mml`) 完全不変
- 既存 23 script regression PASS

#### dispatch path 1 本化の drum 種拡張下での維持 (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 の 4 drum 段 literal 実証)

ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 で確立した「dispatch path は drum 種拡張で増やさない」 contract は、 Step 15 で **bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH の 4 drum 状況下で `pmdneo_rhythm_event_trigger` routine entry addr が変化しない** ことで literal 実証される。 K-CYM / R-CYM fixture で PC trace を取得し、 PC hit addr が Step 12 / Step 13 / Step 14 と同一 (= 0x1126) であることを `verify-step15-cym-trigger.sh` で literal assert する。

Step 15 で routine 内部の implementation は拡張される (= bit 2 分岐追加 + `_rhythm_event_cym_trigger` sub-routine 新規) が、 routine entry / 引数 / 戻り値 ABI は不変。 future の drum 種拡張 (= t/i 2 種) でも同じ entry addr を保持することを Step 15 で先取り保証する (= 4 drum 段から 6 drum 段まで dispatch path 不変保証の漸増)。

### 決定 2: drum 種拡張 = bit 2 CYM 単独 accept (= ADR-0028 §決定 2 b+s+h proof を b+s+c+h proof に literal 更新、 bit 4/5 silent ignore 維持)

K part 文法 subset (= 軸 1 採用):

- K letter = `K` 維持 (= PMD V4.8s 互換、 ADR-0026 §決定 5 / ADR-0027 §決定 2 / ADR-0028 §決定 2 維持)
- drum 識別文字 = **`b` = BD + `s` = SD + `c` = CYM + `h` = HH の 4 種** で proof (= ADR-0028 §決定 2 の「b + s + h」 を「b + s + c + h」 に literal 拡張)
- 残り 2 種 (= `t` = TOM / `i` = RIM、 `r` は rest 専用) は future sub-sprint で段階追加 (= Step 16 候補、 ADR-0028 §Annex A-1 mc.cs rcomtbl L9528-9533 literal で確認済)
- K syntax 自体は PMD 互換 (= drum 種拡張時に既存 K part syntax を維持)

#### bitmap accept range

driver `.MN` direct parser での `0xEB <bitmap>` 受入:

- **bit 0 = 1** (= 0x01): BD trigger (= 既存 ADR-0026 / ADR-0027 / ADR-0028 維持)
- **bit 1 = 1** (= 0x02): SD trigger (= 既存 ADR-0027 / ADR-0028 維持)
- **bit 2 = 1** (= 0x04): CYM trigger (= `\c`) → **本 ADR で新規追加 accept**
- **bit 3 = 1** (= 0x08): HH trigger (= 既存 ADR-0028 維持)
- **bit 4 = 1** (= 0x10): TOM trigger (= `\t`、 mc.cs `tamset` 経由) → **silent ignore**
- **bit 5 = 1** (= 0x20): RIM trigger (= `\i`、 `\r` ではない、 mc.cs `rimset` 経由) → **silent ignore**
- **bit 6-7**: reserved (= silent ignore)
- **bitmap = 0x00**: no-op
- **bitmap = 0x03 / 0x05 / 0x06 / 0x07 / 0x09 / 0x0A / 0x0B / 0x0C / 0x0D / 0x0E / 0x0F 等** (= simultaneous trigger combo): bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4)、 動作は α 調査で literal 確認 + 結果 Annex A 反映、 Step 15 fixture では生成しない、 combo bitmap が driver 上で動く可能性と仕様化は別軸 (= ADR 内で「未定義」 明記)

#### 採用根拠

- ADR-0028 b+s+h proof と同じ proof 最小性
- dispatch path 1 本化が 4 drum 状況下で literal 維持されることの proof は 1 軸拡張で十分
- 残 2 drum 一気は fixture / verify / sample addr mapping を同時拡張で scope 肥大化
- BD/SD/HH/CYM は PMD V4.8s K part 文法的に最頻出 (= pop / rock 基本 pattern + crash cymbal accent)
- CYM sample (= TOP cymbal) は ADR-0025 step5b で ADPCM-A subsystem 内に既に embed 済 (= sample source 取得コスト 0)

#### ADR / handoff 記載 contract

- Step 15 では drum kind = **b + s + c + h only**
- future sprint で t/i を **段階追加**
- bit 4/5 は **silent ignore** (= 未対応 cmd スルー思想踏襲)
- dispatch path は drum 種拡張で **増やさない** (= 決定 8 と整合)

### 決定 3: CYM sample source = existing `adpcma_sample_top` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 + ADR-0028 §決定 3 HH = 既存再利用 pattern 踏襲、 melody sample symbol と現段階で共有、 「top」 = sample provenance 名 / 「CYM」 = PMD semantics 名 で wording 分離、 alias 新設なし、 final rhythm sample ownership 未確定)

CYM trigger で使う sample (= 軸 1 / (cym_s1) 採用):

#### Step 15 proof 段階

- bit 0 BD → `adpcma_sample_bd` pointer (= 既存 Step 12 維持)
- bit 1 SD → `adpcma_sample_sd` pointer (= 既存 Step 13 維持)
- bit 2 CYM → `adpcma_sample_top` pointer (= 本 ADR で新規 mapping 追加、 既存 symbol reuse)
- bit 3 HH → `adpcma_sample_hh` pointer (= 既存 Step 14 維持)
- sample header / addr 値は driver source / `samples.inc` 内に literal 配置 (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 ADR-0025 step5b で既に TOP cymbal ADPCM-A subsystem 内に embed 済)
- 新規 sample embed なし (= 既存資産再利用のみ)
- 新規 alias symbol `adpcma_sample_cym` 追加なし (= 命名整理目的だけの driver 差分追加を避ける、 「top」 と「CYM」 の wording 分離は ADR + handoff doc 上で明記)
- `.PNE` / `.MN` asset pipeline / `pne_sample_directory` / `sample_table_id` resolver / `pmdneo_select_sample_pointer` は完全不変
- L-Q melody sample / rhythm BD sample / rhythm SD sample / rhythm CYM sample / rhythm HH sample は driver source 内で **symbol 共有** (= L-Q melody Q ch と `adpcma_sample_top` symbol を share、 ただし read タイミング軸で collision しない)

#### 「top」 と「CYM」 の wording 分離

ADR-0029 で両者を明示分離する:

- **「top」**: sample provenance 名 (= asset 由来 = `assets/sounds/adpcma/2608_TOP.adpcma`、 L-Q melody architecture Q ch sample symbol = `adpcma_sample_top`、 ADR-0025 step5b で ADPCM-A subsystem 内に embed 済)
- **「CYM」**: PMD semantics 名 (= PMD MML 記号 `\c`、 PMD V4.8s `cymset`、 bitmap bit 2 = 0x04、 ADR-0028 §Annex A-1 mc.cs rcomtbl L9528-9533 literal `'c' → cymset` 確認済)
- driver source 内では `adpcma_sample_top` symbol を「CYM bit 2 → top cymbal sample」 mapping として使用
- 新規 alias symbol (= `adpcma_sample_cym`) 追加なし → driver 差分最小化
- 「PMD rhythm の CYM は TOP cymbal 相当として扱うのが自然」 (= PMD/OPN rhythm 慣習) という user judgement に基づく

#### symbol sharing と semantics separation の現段階整理

- melody architecture (= ADR-0019 で確立した L-Q 6 ch ADPCM-A native runtime): Q ch (= Q part) の sample として `adpcma_sample_top` を参照
- rhythm proof (= 本 ADR + ADR-0026 / ADR-0027 / ADR-0028): L ch (= rhythm event trigger 経由) の sample として `adpcma_sample_top` を参照
- 両者は **同 symbol を share** するが **異なる ADPCM-A ch slot に書き込まれる** (= melody Q ch slot vs rhythm L ch slot、 register bank 軸で分離)
- final rhythm sample ownership は **未確定** (= future `.PNE` rhythm bank migration で rhythm-dedicated sample bank に移行する可能性あり、 ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 future migration path 継続)

#### future migration path (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 継続、 literal 残置)

将来的に OPNA rhythm 相当 sample set を `.PNE` 側へ寄せる可能性が高い (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 と同一)。 候補 path:

- `.PNE` rhythm bank entry を新設 (= `sample_table_id` id=0x02 を rhythm bank として確保、 directory entry 拡張)
- generated rhythm sample directory (= D3 migration の一部として rhythm sample を含める)
- driver の `pmdneo_rhythm_event_trigger` routine が `.PNE` rhythm bank entry を引くように変更
- rhythm-dedicated sample symbol 分離 (= `adpcma_sample_bd_rhythm` / `adpcma_sample_sd_rhythm` / `adpcma_sample_cym_rhythm` / `adpcma_sample_hh_rhythm` 等、 melody architecture sample symbol と分離)

ただし上記は **Step 15 scope-out**、 future sprint で必要なら別途検討。

#### ADR / handoff 記載 contract

- CYM sample = **existing `adpcma_sample_top` symbol reuse as driver-embedded proof fixture**
- 新規 sample embed = **scope-out**
- 新規 alias symbol `adpcma_sample_cym` 追加 = **scope-out** (= 命名整理目的だけの driver 差分を避ける、 wording 分離は ADR + handoff doc 上で明記)
- rhythm-dedicated symbol 分離 = **scope-out** (= ADR-0027 SD pattern / ADR-0028 HH pattern との consistency 維持)
- driver-embedded rhythm fixture は **proof 用** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 維持)
- `.PNE` migration は **future sprint** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 future migration path 継続)
- Step 15 は **drum kind expansion proof**、 sample source proof / symbol separation proof ではない
- melody sample symbol と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

### 決定 4: dispatch path 1 本化不変 (= `pmdneo_rhythm_event_trigger` routine entry addr 不変、 routine 内部の bit 2 分岐は bit 1 と bit 3 の間に挿入するが ABI 不変)

K と R の dispatch path (= ADR-0026 §決定 6 / ADR-0027 §決定 4 / ADR-0028 §決定 4 維持 + Step 15 で 4 drum 段の literal 維持):

#### routine entry 不変

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は Step 12 / Step 13 / Step 14 から不変
- K-CYM / R-CYM fixture でも PC trace hit addr は 0x1126 (= 既存 Step 12 K-BD / R-BD + Step 13 K-SD / R-SD + Step 14 K-HH / R-HH と同一)
- routine 引数 / 戻り値 ABI 不変
- `.MN` direct parser からの caller 接続不変

#### routine 内部の bit 2 分岐挿入位置 = bit 1 と bit 3 の間 (= PMD bitmap bit 順序維持)

routine 内部の implementation は拡張される:

- 既存 (Step 12): bit 0 = 1 → BD trigger (= `adpcma_sample_bd` register write)
- 既存 (Step 13): bit 1 = 1 → SD trigger (= `adpcma_sample_sd` register write)
- 新規 (Step 15): bit 2 = 1 → CYM trigger (= `adpcma_sample_top` register write、 bit 1 と bit 3 の間に挿入)
- 既存 (Step 14): bit 3 = 1 → HH trigger (= `adpcma_sample_hh` register write)
- bit 4/5: silent ignore (= no register write)
- bit 6-7: reserved (= no register write)
- bitmap = 0x00: no-op

#### branch 実装流儀 (= explicit if/jr/jp、 ADR-0024 / 0025 / 0026 / 0027 / 0028 §決定 4 流儀踏襲 + Step 15 β で jr → jp 1 行精密化)

bit 0 / bit 1 / bit 2 / bit 3 の分岐は **explicit if/jr/jp** で記述 (= jump table / dispatch macro は使わない、 distance に応じて jr または jp を選択する Z80 標準対応)。 ADR-0024 step 10 / ADR-0025 step 11 / ADR-0026 step 12 / ADR-0027 step 13 / ADR-0028 step 14 全てで踏襲してきた流儀の精密化 (= ADR-0028 までは「explicit if/jr」 wording、 ADR-0029 で `_rhythm_event_cym_trigger` sub-routine 挿入により dispatch path 末尾 `jr _rhythm_event_hh_trigger` が jr 範囲 ±128 byte を超過したため `jp _rhythm_event_hh_trigger` に 1 行精密化、 explicit branch の精神 (= dispatch macro/jump table を使わない) は完全維持):

```asm
pmdneo_rhythm_event_trigger::
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 2 = CYM / bit 3 = HH / bit 4/5 = silent ignore
    push    af
    bit     0, a
    call    nz, _rhythm_event_bd_trigger
    pop     af
    push    af
    bit     1, a
    call    nz, _rhythm_event_sd_trigger
    pop     af
    push    af                              ; ← Step 15 で追加 (= bit 2 check 用 A 保持)
    bit     2, a
    call    nz, _rhythm_event_cym_trigger   ; ← Step 15 で追加
    pop     af
    bit     3, a
    ret     z
    jp      _rhythm_event_hh_trigger        ; bit 3 HH tail jump (= ADR-0028 まで jr / ADR-0029 で jp に精密化、 cym sub-routine 挿入で jr 範囲超過対応、 explicit branch 精神維持)

_rhythm_event_bd_trigger:
    ; adpcma_sample_bd を ADPCM-A L ch に register write (= Step 12 既存、 完全不変)
    ...
    ret

_rhythm_event_sd_trigger:
    ; adpcma_sample_sd を ADPCM-A L ch に register write (= Step 13 既存、 内部完全不変、 entry addr は再 shift 想定)
    ...
    ret

_rhythm_event_cym_trigger:
    ; adpcma_sample_top を ADPCM-A L ch に register write (= Step 15 新規実装)
    ld      hl, #adpcma_sample_top
    ; ... reg 0x10 / 0x18 / 0x20 / 0x28 / 0x08 / 0x00 keyon mask 0x01 write
    ret

_rhythm_event_hh_trigger:
    ; adpcma_sample_hh を ADPCM-A L ch に register write (= Step 14 既存、 内部完全不変、 entry addr は再 shift 想定)
    ...
    ret
```

実装の literal asm は β commit で確定 (= 本 ADR は契約のみ literal 固定、 implementation 詳細は β に委ねる)。

#### ADR / handoff 記載 contract

- `pmdneo_rhythm_event_trigger` routine entry addr = **不変** (= 0x1126) ← **invariant の primary 軸**
- routine ABI = **不変**
- routine 内部の bit 2 分岐は **bit 1 と bit 3 の間に挿入** (= PMD bitmap bit 順序維持、 future bit 4/5 追加時も同 順序維持で挿入可能)
- branch 流儀 = **explicit if/jr/jp** (= ADR-0024 / 0025 / 0026 / 0027 / 0028 流儀踏襲 + Step 15 β で jr → jp 1 行精密化、 distance 適応で jr/jp 選択、 dispatch macro/jump table は使わない explicit branch 精神維持)
- dispatch path は drum 種拡張で **増やさない** (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 維持、 本 ADR §決定 8 で 4 drum 段で再確認)
- **internal sub-routine entry addr は不変保証対象ではない** (= dispatcher 改修で再 shift 可、 Step 14 で `_rhythm_event_sd_trigger` 0x115F → 0x1166 literal shift observed、 Step 15 で再 shift observed = β verify で `_rhythm_event_cym_trigger @ 0x119B` 新規、 SD/HH trigger entry addr も再 shift)。 invariant の本質は **shared dispatch entry 不変 + register write sequence 不変** の 2 軸。

### 決定 5: fixture 体制 = BD/SD/HH fixture 完全不変 + CYM fixture 2 件新規 (= 8 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM)

K-CYM / R-CYM fixture 取り扱い (= 軸 2 / (fix1) 採用):

#### 既存 BD/SD/HH fixture 完全不変

- `compile-test-pmddotnet/k-br-only.mml` (= Step 12 既存)
- `compile-test-pmddotnet/r-melody-br-only.mml` (= Step 12 既存)
- `compile-test-pmddotnet/k-sr-only.mml` (= Step 13 既存)
- `compile-test-pmddotnet/r-melody-sr-only.mml` (= Step 13 既存)
- `compile-test-pmddotnet/k-hr-only.mml` (= Step 14 既存)
- `compile-test-pmddotnet/r-melody-hr-only.mml` (= Step 14 既存)

これらは **完全不変** (= byte-identical 維持、 Step 12 / Step 13 / Step 14 K-R differential proof script で継続使用)。

#### 新規 CYM fixture 2 件

- `compile-test-pmddotnet/k-cr-only.mml` (= K part `\c` + `r`(= rest) のみ、 K-BD/K-SD/K-HH fixture と 1 文字違い)
- `compile-test-pmddotnet/r-melody-cr-only.mml` (= melody part L 内 inline `\c` + `r`(= rest)、 R-BD/R-SD/R-HH fixture と 1 文字違い)

#### fixture 命名規則

- `k-cr-only.mml` の `cr` は **`\c` + `r`(= rest) の fixture pattern**
- `cr` は「**CYM」 略ではない** (= 既存 `br` / `sr` / `hr` も「BD」「SD」「HH」 略ではなく `\b` + `r` / `\s` + `r` / `\h` + `r` pattern と同一)
- α 調査で PMDDotNET が CYM を `\c` として emit することを literal 確認 (= ADR-0028 §Annex A-1 mc.cs rcomtbl L9528-9533 で既に literal 確認済、 α 着手で再確認 + 本 ADR §Annex A 反映)
- もし α 調査で CYM の MML 記号が `\c` でないと判明した場合は、 fixture 名を **実 bytecode / actual syntax に合わせて修正** (= sub-sprint 内で rename、 β 着手前に確定、 ただし ADR-0028 で `\c` 確認済のため本 sprint で rename 発生確率低)

#### 8 fixture 体制

| fixture | drum 種 | source 経路 | step12 / step13 / step14 / step15 |
|---|---|---|---|
| `k-br-only.mml` | BD | K part | step 12 既存 |
| `r-melody-br-only.mml` | BD | melody part inline | step 12 既存 |
| `k-sr-only.mml` | SD | K part | step 13 既存 |
| `r-melody-sr-only.mml` | SD | melody part inline | step 13 既存 |
| `k-hr-only.mml` | HH | K part | step 14 既存 |
| `r-melody-hr-only.mml` | HH | melody part inline | step 14 既存 |
| `k-cr-only.mml` | CYM | K part | step 15 新規 |
| `r-melody-cr-only.mml` | CYM | melody part inline | step 15 新規 |

#### ADR / handoff 記載 contract

- BD/SD/HH fixture = **完全不変**
- CYM fixture = **2 件新規追加**
- fixture 命名 pattern = `\c` + `r`(= rest) = `cr` (= 既存 `br` / `sr` / `hr` pattern 踏襲、 drum 名略ではなく fixture pattern 命名)
- verify token = `cym` (= drum semantics 名、 fixture pattern token と区別)
- α 調査で命名修正可能性極めて低い (= ADR-0028 §Annex A-1 で `\c` literal 確認済)
- **`cr` は「CYM」 略ではない** (= future contributor 向け literal 注記)

### 決定 6: drum 種 → sample pointer mapping table を 1 軸拡張 (= bit 0 → BD addr / bit 1 → SD addr / bit 2 → CYM addr / bit 3 → HH addr)

driver source 内 mapping table 構造:

#### Step 14 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 + bit 3 HH 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_hh` literal addr 参照
- bit 2/4/5 は no-op (= silent ignore)

#### Step 15 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 + bit 2 CYM 分岐 + bit 3 HH 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_top` / `adpcma_sample_hh` literal addr 参照
- bit 4/5/6/7 は no-op (= silent ignore 維持)
- mapping table 構造は branch 流儀の延長 (= 別途 table 構造を導入せず、 explicit branch + literal addr 参照のまま)

#### branch 構造で literal addr 参照する根拠 (= 別 table 構造を導入しない理由)

- ADR-0024 / 0025 / 0026 / 0027 / 0028 で確立した explicit if/jr 流儀踏襲
- 4 drum 程度なら branch 列挙の方が trace gate / register write trace で読みやすい
- 別 mapping table 構造 (= bitmap bit position → sample addr pointer の lookup table) は 5+ drum で検討 (= future sprint t/i 追加で 6 drum 段到達時に再評価)
- 早すぎる抽象化を避ける (= CLAUDE.md §「3 行の重複は早すぎる抽象化より良い」 規律)
- table-driven refactor は full drum set 到達後 (= 6 drum 段) に判断材料が揃う

#### ADR / handoff 記載 contract

- drum 種 → sample pointer mapping = **explicit branch + literal addr 参照**
- 別 mapping table 構造 = **scope-out** (= future sprint で 5+ drum 拡張時に再評価、 full drum set 到達後優先)
- bit 0 → `adpcma_sample_bd` literal addr
- bit 1 → `adpcma_sample_sd` literal addr
- bit 2 → `adpcma_sample_top` literal addr (= 「CYM」 semantics 名 / 「top」 provenance 名)
- bit 3 → `adpcma_sample_hh` literal addr

### 決定 7: BD/SD/HH fixture 完全不変保証 (= Step 12 K-BD / R-BD path + Step 13 K-SD / R-SD path + Step 14 K-HH / R-HH path regression 維持)

Step 15 で BD/SD/HH path を壊していないことを継続確認する規律:

#### regression 維持要件

- Step 12 で確立した K-BD / R-BD path の verify script 4 件 (= `verify-step12-k-rhythm-trigger.sh` / `verify-step12-kr-differential.sh` 等) は **完全不変**
- Step 13 で確立した K-SD / R-SD path の verify script 3 件 (= `verify-step13-sd-trigger.sh` / `verify-step13-kr-sd-differential.sh` / `verify-step13-bd-sd-differential.sh`) は **完全不変**
- Step 14 で確立した K-HH / R-HH path の verify script 3 件 (= `verify-step14-hh-trigger.sh` / `verify-step14-kr-hh-differential.sh` / `verify-step14-bd-hh-differential.sh`) は **完全不変**
- Step 12 / Step 13 / Step 14 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH fixture file (= `k-br-only.mml` / `r-melody-br-only.mml` / `k-sr-only.mml` / `r-melody-sr-only.mml` / `k-hr-only.mml` / `r-melody-hr-only.mml`) は **byte-identical** 維持
- Step 12 BD register write trace + Step 13 SD register write trace + Step 14 HH register write trace は **同 sequence 維持**
- Step 15 commit chain (= α/β/γ/δ) の各 commit で全 step12 + step13 + step14 path verify script PASS が確認できる

#### ADR / handoff 記載 contract

- BD path **regression 維持**
- SD path **regression 維持**
- HH path **regression 維持**
- Step 12 / Step 13 / Step 14 fixture / verify script 完全不変
- Step 15 各 commit で BD/SD/HH path verify が **PASS 確認できる**
- 「動いているものを壊さない」 規律遵守 (= Step 5/6/7/8/9/10/11/12/13/14 で確立)

### 決定 8: dispatch path は drum 種拡張で増やさない (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 維持、 Step 15 で 4 drum 段 literal 実装保証)

ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 で確立した contract:

> dispatch path は drum 種拡張で増やさない

を Step 15 で **4 drum 段で literal 実装的に保証** する:

#### 実装的保証 内容

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は不変
- K-CYM / R-CYM fixture で PC trace hit addr が Step 12 K-BD / R-BD + Step 13 K-SD / R-SD + Step 14 K-HH / R-HH と同一 (= 0x1126)
- routine ABI 不変
- routine 内部の bit 2 分岐追加 + `_rhythm_event_cym_trigger` sub-routine 新規は **routine 内部の implementation 拡張** であって dispatch path の新設ではない
- drum 種 → sample addr mapping は routine 内部の literal branch で吸収

#### future drum 種拡張で維持される項目

t/i 2 種追加時にも:

- routine entry addr 不変 (= 0x1126)
- routine ABI 不変
- 新規 dispatch routine を追加しない (= routine 内部の bit position 分岐 + sub-routine を追加するのみ)
- future drum 種拡張で 6 drum 段に到達した時点で別 mapping table 構造への refactor を再評価 (= 決定 6 と整合、 full drum set 到達後優先)

#### ADR / handoff 記載 contract

- dispatch path = **1 本化維持** (= shared dispatch entry @ 0x1126)
- routine entry addr / ABI = **不変** (= invariant primary 軸)
- drum 種拡張は **routine 内部 implementation 拡張 (= bit 分岐 + sub-routine 追加) で吸収**
- **internal sub-routine entry addr は不変保証対象ではない** (= ADR-0028 §決定 8 wording 踏襲、 Step 15 で再 shift 想定 = SD trigger / HH trigger の entry addr が dispatcher 改修で再 shift)
- **invariant の本質** = shared dispatch entry 不変 + register write sequence 不変 の 2 軸 (= sub-routine entry addr は secondary observation、 verify script 側も literal value hard-code 不在)
- table-driven refactor = **future sprint** (= full drum set = 6 drum 段到達後に再評価)

### 決定 9: observability marker = `pmdneo_rhythm_event_trigger` PC hit 継続 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 維持、 SRAM layout 不変)

Step 15 での observability marker 軸 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 維持):

- rhythm event observability marker = **routine PC hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126)
- memory marker byte は **持たない** (= SRAM 増設なし)
- SRAM layout は Step 15 でも **増やさない** (= 0xFD20-0xFD32 既存領域維持)
- PC trace + ymfm-trace の **二段 gate** で K-CYM / R-CYM proof
- K-CYM / R-CYM source path は別でも runtime dispatch routine は同一 (= 同 0x1126 PC hit)

#### ADR / handoff 記載 contract

- observability marker = **routine PC hit (= 0x1126)**
- memory marker byte 追加 = **scope-out**
- SRAM layout 不変
- PC trace + ymfm-trace 二段 gate 継続

### 決定 10: PMDDotNET / `.MN` format 完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 維持)

Step 15 での PMDDotNET / `.MN` format 軸:

- PMDDotNET (= C# compile path) 完全不変
- `.MN` format 完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う)
- 新規 `.MN` bytecode 追加なし
- driver `.MN` direct parser での normalize は ADR-0026 で確立した `0xEB <bitmap>` 受入を維持、 bitmap accept range のみ bit 0 + bit 1 + bit 3 → bit 0 + bit 1 + bit 2 + bit 3 に拡張

#### ADR / handoff 記載 contract

- PMDDotNET-side normalize は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 維持)
- new `.MN` rhythm event bytecode 追加は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 維持)
- driver `.MN` direct parser での bitmap accept range 拡張のみ (= bit 0 + bit 1 + bit 3 → bit 0 + bit 1 + bit 2 + bit 3)

### 決定 11: simultaneous trigger scope-out + bitmap OR semantics future investigation (= future 候補温存、 Annex A 軽く触れる、 driver 上での動作可能性と仕様化を区別)

simultaneous trigger semantics 対応 (= 軸 4 / scope-out 採用):

#### Step 15 scope-out

- BD+SD / BD+CYM / SD+CYM / BD+SD+CYM / BD+HH / SD+HH / CYM+HH / BD+SD+HH / BD+CYM+HH / SD+CYM+HH / BD+SD+CYM+HH 同時打ち (= bitmap = 0x03 / 0x05 / 0x06 / 0x07 / 0x09 / 0x0A / 0x0B / 0x0C / 0x0D / 0x0E / 0x0F 等) の literal proof は **Step 15 scope-out**
- Step 15 fixture は **BD 単独 / SD 単独 / HH 単独 / CYM 単独 のみ** (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM 8 件、 simultaneous combo 並記 fixture なし)
- driver の bitmap accept range は bit 0 + bit 1 + bit 2 + bit 3 個別 accept (= 各 bit=1 single、 simultaneous combo は α 調査で literal 動作確認のみ、 fixture proof scope-out)

#### driver 動作可能性と仕様化の区別

- 現 driver は bit ごとに独立判定 (= bit 0 → BD trigger / bit 1 → SD trigger / bit 2 → CYM trigger / bit 3 → HH trigger)、 各 bit 立で対応 sub-routine が call される
- bitmap = 0x03 (= BD+SD) が来ると BD sub-routine + SD sub-routine が連続 call される (= driver 動作上 harmful なし)
- ただし **仕様としては未定義** = Step 15 ADR scope では「driver 動作可能性」 と「仕様化」 を区別、 combo bitmap の semantics (= 同時打ちの結果としての register write 順序 / volume / pan / keyon mask) は ADR 内で literal 規定しない
- combo bitmap が driver 上で動く事実と、 ADR で仕様として規定する事実は別軸 (= future = simultaneous trigger semantics proof sprint で 1 軸だけ定義化予定)

#### bitmap OR semantics future investigation

- PMDDotNET が同 K part 行 `\b\c` / `\s\c` / `\b\s\c` / `\c\h` / `\b\c\h` / `\s\c\h` / `\b\s\c\h` の連続記述で **bitmap OR (= bit position OR 結合)** を emit するか、 **複数の `0xEB` + 各 bitmap byte** を emit するかは α 調査範囲 (= ADR-0027 §Annex A-3 / ADR-0028 §Annex A-3 で bitmap OR 圧縮 emit literal 確認済、 同 pattern で 4 drum combo 想定)
- α 調査結果を Annex A に literal 反映
- future sprint 候補 (= simultaneous trigger semantics literal proof sprint) として温存

#### ADR / handoff 記載 contract

- simultaneous trigger = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 16+ 候補)
- Step 15 fixture は **BD 単独 / SD 単独 / HH 単独 / CYM 単独 のみ**
- combo bitmap は **driver 上で動く可能性あり / ADR 内では「未定義」 と明記**
- α 調査で PMDDotNET の bitmap OR emit 動作を literal 確認 + Annex A 反映 (= ADR-0027 / ADR-0028 で BD+SD / HH 込み確認済、 本 ADR で CYM 込み combo の追加確認)

## scope-in / scope-out

### scope-in (= Step 15 で literal 実装する範囲)

1. driver `pmdneo_rhythm_event_trigger` routine に bit 2 分岐追加 (= CYM trigger、 bit 1 と bit 3 の間に挿入、 PMD bitmap bit 順序維持)
2. driver `_rhythm_event_cym_trigger` sub-routine 新規追加 (= adpcma_sample_top を L ch register write)
3. CYM sample pointer mapping (= bit 2 → `adpcma_sample_top` literal addr、 既存 symbol reuse、 alias 新設なし)
4. `k-cr-only.mml` fixture 新規追加
5. `r-melody-cr-only.mml` fixture 新規追加
6. `verify-step15-cym-trigger.sh` 新規追加 (= K-CYM / R-CYM register write trace + keyon count + PC marker)
7. `verify-step15-kr-cym-differential.sh` 新規追加 (= K-CYM vs R-CYM byte-identical literal proof)
8. `verify-step15-bd-cym-differential.sh` 新規追加 (= BD vs CYM sample addr literal differ proof)
9. PMDDotNET CYM emit literal 再確認 (= mc.cs cymset / rs00 周辺、 ADR-0028 §Annex A-1 / §Annex A-2 で literal 確認済を本 ADR §Annex A で再引用)
10. PMDDotNET CYM 込み bitmap OR emit 動作確認 (= 同 K part 行 `\b\c` / `\s\c` / `\b\s\c` / `\c\h` / `\b\c\h` / `\s\c\h` / `\b\s\c\h` 連続記述時の emit byte 列、 Annex A literal 反映)
11. ADR-0029 Annex A 反映 (= α 調査結果)
12. ADR-0029 Accepted 移行 (= δ で実施)
13. handoff doc 起票 (= δ で実施)
14. memory `project_pmdneo_step15_complete` 起票 (= δ で実施)
15. MEMORY.md index 更新 (= δ で実施)

### scope-out (= Step 15 で literal 触らない範囲)

#### Step 15 固有 scope-out (= 5 項目)

1. BD+SD / BD+CYM / SD+CYM / BD+SD+CYM / BD+HH / SD+HH / CYM+HH / BD+SD+HH / BD+CYM+HH / SD+CYM+HH / BD+SD+CYM+HH simultaneous trigger literal proof (= bitmap = 0x03 / 0x05 / 0x06 / 0x07 / 0x09 / 0x0A / 0x0B / 0x0C / 0x0D / 0x0E / 0x0F fixture / verify) → Step 16+ 候補
2. t/i 残り 2 drum 種拡張 → future sub-sprint (= Step 16 候補 = t = TOM、 Step 17 候補 = i = RIM)
3. drum 種 → sample addr mapping table 構造化 (= bitmap bit position → sample pointer の lookup table) → 6 drum 段到達時に再評価 (= full drum set 後優先、 ADR-0028 §scope-out 維持)
4. CYM sample provenance 拡張 (= 新規 sample embed / 新規 alias symbol `adpcma_sample_cym` / rhythm-dedicated symbol 分離 / `.PNE` rhythm bank migration) → future
5. table-driven dispatch refactor (= dispatch path + sub-routine を 1 本に集約) → future sprint (= full drum set 到達後優先)
6. SD vs CYM / HH vs CYM explicit differential verify script → 推移的 proof 成立で scope-out (= BD-vs-SD + BD-vs-HH + BD-vs-CYM から N-1 pair gate で N 軸 mutual differential を推移的に確立)

#### ADR-0026 / ADR-0027 / ADR-0028 から継続する scope-out (= 28+ 項目維持)

7. OPNA rhythm sound source register (= 0x10-0x18) fake API (= PMDNEO は YM2610(B)、 emulation 方針外、 ADR-0026 §決定 2 / ADR-0028 §scope-out 維持)
8. 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation (= channel allocation 最終仕様は future、 ADR-0026 §決定 4 / ADR-0028 §scope-out 維持)
9. OPNA native rhythm timing fidelity (= ADR-0026 / ADR-0027 / ADR-0028 §scope-out 追加項目維持)
10. K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch の 6 件、 silent fallback 継続、 ADR-0026 §決定 11 / ADR-0028 §scope-out 維持)
11. PMDDotNET 改造 / `.MN` format new bytecode (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / 本 ADR §決定 10 維持)
12. selected pointer cache (A2/A3) / mismatch silent flag / D3 generated directory / runtime `.PNE` parser / multi-`.PNE` switching / bank switching (= ADR-0025 §scope-out 継続)
13. `.PPC` / `.P86` / ADPCM-B subsystem 起票 (= 別 subsystem、 `project_pmdneo_adpcma_subsystem_boundary` 維持)
14. `.PNE` rhythm bank migration (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 future migration path 継続、 ADPCM-A subsystem 内だが Step 15 scope-out)
15. driver-embedded fixture 以外の sample provenance (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 維持)
16. multi-table cache / runtime parser (= ADR-0025 / ADR-0026 §決定 11 / ADR-0028 §scope-out 継続)
17. new bytecode (= ADR-0026 §決定 10 / ADR-0028 §決定 10 / 本 ADR §決定 10 維持)
18. PMDDotNET 改造 (= ADR-0026 §決定 10 / ADR-0028 §決定 10 / 本 ADR §決定 10 維持)
19. observability marker 拡張 (= memory marker byte / SRAM 増設、 ADR-0026 §決定 8 / ADR-0028 §決定 9 / 本 ADR §決定 9 維持)
20. K letter 以外の rhythm part letter (= ADR-0026 §決定 5 / ADR-0028 §scope-out 維持)
21. PMDNEO 独自 drum 識別文字 (= PMD 互換維持、 ADR-0026 §決定 5 / ADR-0028 §scope-out 維持)
22. velocity / volume / pan / loop / pattern 軸拡張 (= ADR-0026 §決定 1 / ADR-0028 §決定 2 / 本 ADR §決定 2 b+s+c+h proof minimum 範囲限定)
23. K part / R command 以外の rhythm 系 cmd (= ADR-0026 §決定 11 / ADR-0028 §scope-out 維持)
24. ADPCM-B subsystem への rhythm extension (= `project_pmdneo_adpcma_subsystem_boundary` 維持、 別 subsystem)
25. WebApp UI 関連 (= Phase 4 範囲、 別 sprint)
26. WAV import / 新規 sample 追加 UI (= Phase 4 範囲)
27. AES+ 実機検証 (= 別 sprint、 verify は MAME headless 経由継続)
28. fmgen 比較 (= 別 sprint)
29. PMDNEO.s + nullsound integration (= `project_pmdneo_driver_two_paths_discovery` 維持、 別 path)

## verify gate

### 5 段 gate (= ADR-0026 / ADR-0027 / ADR-0028 §verify gate 形式踏襲)

#### Gate 1: build PASS

- α: 全 23 既存 script regression PASS (= step12 系 + step13 系 + step14 系 + step5-11 系)
- β: 全 23 既存 + step15 cym-trigger 新規 = 23+1 = 24 script PASS
- γ: 全 23 既存 + step15 cym-trigger + step15 kr-cym-differential + step15 bd-cym-differential = 23+3 = 26 script PASS
- δ: 全 26 script 最終 regression PASS

#### Gate 2: K-CYM trigger 単独 verify

`verify-step15-cym-trigger.sh` PASS 内容:

1. `k-cr-only.mml` build → `.MN` byte literal 確認 (= `0xEB 0x04 0x80` 期待 or PMDDotNET 実 emit byte literal、 α 調査結果で確定、 ADR-0028 §Annex A 推定で bitmap 0x04)
2. ymfm-trace で ADPCM-A L ch CYM register write 確認 (= reg 0x10 sample addr literal = `adpcma_sample_top` start addr 等)
3. PC trace で `pmdneo_rhythm_event_trigger` @ 0x1126 hit 確認
4. keyon count = 1 (= L ch keyon mask 0x01 trigger 1 件)
5. K-CYM fixture / R-CYM fixture 両方で同 sequence PASS

#### Gate 3: K-CYM vs R-CYM differential proof

`verify-step15-kr-cym-differential.sh` PASS 内容:

1. K-CYM fixture (= `k-cr-only.mml`) と R-CYM fixture (= `r-melody-cr-only.mml`) で ADPCM-A L ch register write sequence **byte-identical** literal proof
2. PC trace hit addr 同一 (= 両方 0x1126)
3. keyon count 同一 (= 両方 1 件)
4. dispatch path 1 本化が drum 種拡張 (= 4 drum 状況) 下でも literal 維持されることの proof

#### Gate 4: BD vs CYM differential proof

`verify-step15-bd-cym-differential.sh` PASS 内容:

1. K-BD fixture (= `k-br-only.mml`) と K-CYM fixture (= `k-cr-only.mml`) で:
   - reg 0x10 sample start addr **literal differ** (= `adpcma_sample_bd` start addr ≠ `adpcma_sample_top` start addr)
   - reg 0x18 sample end addr **literal differ**
   - reg 0x20 / reg 0x28 は **identical** (= 同 L ch、 同 fixture pattern なら同値)
   - reg 0x08 vol|pan / reg 0x00 keyon mask は **identical**
2. R-BD fixture と R-CYM fixture でも同様の差分 literal proof
3. drum 種 → sample addr mapping が literal 区別されていることの proof (= 4 drum 段で BD vs CYM literal differ)

#### SD vs CYM / HH vs CYM 推移的区別 (= ADR-0028 §verify gate Gate 4 注記 pattern 踏襲、 explicit gate scope-out)

**SD vs CYM / HH vs CYM の sample addr literal differ proof は explicit verify gate を設けない**:

- BD vs SD literal differ = ADR-0027 §verify gate Gate 4 で literal 確立済
- BD vs HH literal differ = ADR-0028 §verify gate Gate 4 で literal 確立済
- BD vs CYM literal differ = 本 ADR §verify gate Gate 4 で literal 確立 (= `verify-step15-bd-cym-differential.sh`)
- → SD vs CYM / HH vs CYM literal differ は **推移的に proof 成立** (= 4 sample addr literal value が全て異なれば全 pair で literal differ、 explicit gate 不要)
- explicit SD vs CYM / HH vs CYM differential script は scope-out (= 早すぎる verify expansion を避ける、 ADR-0028 §scope-out 5 pattern 踏襲)
- future drum 種拡張 (= t/i) でも同 pattern (= 各新規 drum vs BD の literal differ gate のみで proof 成立、 N-1 pair gate で N 軸 differential を推移的に確立可能)

#### Gate 5: 既存 regression 不破壊

- 既存 23 script regression PASS 維持 (= ADR-0028 完了時の 23 script、 BD path / SD path / HH path / multi-table / melody / asset pipeline 全て)
- 各 commit (= α/β/γ/δ) で全 step12 + step13 + step14 BD/SD/HH path verify script PASS が確認できる
- 「動いているものを壊さない」 規律遵守

### audio gate

- ✅ user 試聴 OK 確認 (= 16th session δ で user 試聴依頼、 8 wav file = `/tmp/pmdneo-step12/k-br-only.wav` + `/tmp/pmdneo-step12/r-melody-br-only.wav` + `/tmp/pmdneo-step13/k-sr-only.wav` + `/tmp/pmdneo-step13/r-melody-sr-only.wav` + `/tmp/pmdneo-step14/k-hr-only.wav` + `/tmp/pmdneo-step14/r-melody-hr-only.wav` + `/tmp/pmdneo-step15/k-cr-only.wav` + `/tmp/pmdneo-step15/r-melody-cr-only.wav` で確認、 試聴 helper script = `scripts/listen-step15.sh` (= 8 wav + sleep 3 interval + 無限繰り返し + Ctrl+C 停止)、 全 wav は γ commit `4c4c55c` driver state で生成)
- ✅ user judgement: 「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「K-CYM と R-CYM は同一」 = K/R で同音、 BD vs SD vs HH vs CYM で違う音色 (= 4 drum 種で聴感的に区別可能)、 FM 同居許容 (= Step 12 / Step 13 / Step 14 audio gate 規律踏襲)
- ✅ BD 単独 / SD 単独 / HH 単独 / CYM 単独 各 fixture で音が鳴る + BD/SD/HH/CYM 4 種で聴感的に区別可能 を user judgement で確認
- ✅ Step 15 audio gate = **OK** 判定 (= 16th session δ user 直接判定)

#### audio gate と trace gate の二段 verify

- **trace gate (= register write literal)**: K-CYM と R-CYM で CYM register write byte-identical (= γ commit gate 6) + BD/SD/HH/CYM sample addr literal differ (= γ commit gate 4 + 推移的) で literal proof
- **audio gate (= 聴感判定)**: 同 dispatch path を通る K-CYM と R-CYM で耳でも同音、 BD/SD/HH/CYM で耳でも区別可能を user judgement で確認

両 axis で Step 15 contract 達成。

## 完了判定

Step 15 完了判定 (= 10 項目、 16th session δ で **全 10/10 ✅ 達成**):

1. ✅ ADR-0029 Accepted 移行 (= 本 δ commit で literal 達成)
2. ✅ `pmdneo_rhythm_event_trigger` routine に bit 2 CYM 分岐追加 (= β commit `b83778f`、 既存 bit 0 / bit 1 分岐と bit 3 分岐の間に挿入、 entry addr @ 0x001126 完全不変、 PMD bitmap bit 順序維持)
3. ✅ CYM sample pointer mapping (= bit 2 → `adpcma_sample_top` 既存 symbol reuse) 実装 (= β commit `b83778f`、 `_rhythm_event_cym_trigger:` @ 0x00119B label で literal addr 参照、 既存 L-Q architecture Q ch sample symbol を rhythm proof 用に reuse、 ADR-0029 §決定 3 / 軸 1 整合、 alias 新設なし、 「top」 = sample provenance 名 / 「CYM」 = PMD semantics 名 wording 分離)
4. ✅ `k-cr-only.mml` fixture 新規追加 (= K-CYM path、 β commit `b83778f`、 UTF-8 + CRLF、 `cr = \c + r(rest) fixture pattern` 注記)
5. ✅ `r-melody-cr-only.mml` fixture 新規追加 (= R-CYM path、 γ commit `4c4c55c`、 UTF-8 + CRLF、 `cr = \c + r(rest)` 注記)
6. ✅ `verify-step15-cym-trigger.sh` 新規追加 + PASS (= β commit `b83778f`、 5 gate PASS、 pmdneo_rhythm_event_trigger @ 0x001126 + `_rhythm_event_cym_trigger` @ 0x00119B literal 確認、 CYM register write literal value PASS = 0x12 / 0x00 / 0x29 / 0x00 = TOP_START_LSB / MSB / TOP_STOP_LSB / MSB)
7. ✅ `verify-step15-kr-cym-differential.sh` 新規追加 + PASS (= γ commit `4c4c55c`、 7 gate PASS、 K-CYM vs R-CYM CYM register write byte-identical (= 6 件) + K-CYM=R-CYM hook addr identical = 0x001126 + K-CYM=R-CYM cym_trigger addr identical = 0x00119B)
8. ✅ `verify-step15-bd-cym-differential.sh` 新規追加 + PASS (= γ commit `4c4c55c`、 6 gate PASS、 BD start/stop LSB (0x00/0x03) ≠ CYM start/stop LSB (0x12/0x29) literal differ、 SD vs CYM / HH vs CYM は推移的に区別可能)
9. ✅ 既存 全 script regression PASS 維持 (= δ で 26 script serial 実行、 全 26 PASS = step 4/5/6/7/8/9/10/11/12/13/14 系 23 script + step 15 新規 3 件 = 23+3 = 26 script、 BD/SD/HH path 不変保証 + driver 改修副作用なし)
10. ✅ user 試聴 OK 確認 (= 16th session δ user 試聴依頼で「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「K-CYM と R-CYM は同一」 K/R 同音確認、 BD/SD/HH/CYM 区別可能、 FM 同居許容方針 ADR-0026 / ADR-0027 / ADR-0028 audio gate 規律踏襲、 Step 15 audio gate = OK 直接判定)

## 本質再確認

### layering 図 (= future contributor 向け literal 固定、 Step 14 layering の drum 種 1 軸拡張)

```
source layer:           K part                                R command
                        \b / \s / \c / \h                     \b inline / \s inline / \c inline / \h inline
                            \                                     /
                             \                                   /
                              normalize  (= driver .MN direct parser)
                                  |
                                  V
                          0xEB <bitmap>
                                  |
                                  V
                    pmdneo_rhythm_event_trigger  (@ 0x1126、 routine entry 不変)
                                  |
                                  +-- bit 0 = 1 --> _rhythm_event_bd_trigger  --> adpcma_sample_bd  --> ADPCM-A L ch
                                  |
                                  +-- bit 1 = 1 --> _rhythm_event_sd_trigger  --> adpcma_sample_sd  --> ADPCM-A L ch
                                  |
                                  +-- bit 2 = 1 --> _rhythm_event_cym_trigger --> adpcma_sample_top --> ADPCM-A L ch (= 「CYM」 semantics / 「top」 provenance)
                                  |
                                  +-- bit 3 = 1 --> _rhythm_event_hh_trigger  --> adpcma_sample_hh  --> ADPCM-A L ch
                                  |
                                  +-- bit 4/5 ---> silent ignore (= future drum 種拡張で literal branch 追加)
                                  |
                                  +-- bit 6-7 ---> reserved
                                  |
                                  +-- bitmap = 0x00 --> no-op
                                  |
                                  +-- bitmap = 0x03 / 0x05 / 0x06 / ... --> Step 15 scope-out (= simultaneous trigger semantics future)
```

### Step 12 / Step 13 / Step 14 path 維持原則

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) **不変**
- routine ABI **不変**
- routine 内部の bit 2 分岐は **bit 1 と bit 3 の間に挿入** だが routine entry / 引数 / 戻り値 ABI は **不変**
- K-BD / R-BD / K-SD / R-SD / K-HH / R-HH path **完全不変** (= Step 12 / Step 13 / Step 14 fixture / verify / register write sequence 全て不変)
- `_rhythm_event_bd_trigger` sub-routine **完全不変**
- `_rhythm_event_sd_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift)
- `_rhythm_event_hh_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift)
- PC trace + ymfm-trace 二段 gate 規律 **継続**
- PMDDotNET / `.MN` format **完全不変**
- driver-embedded fixture proof 規律 **継続**
- `.PNE` rhythm bank migration **future 維持**

### ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 の 4 drum 段 literal 実装保証

「dispatch path は drum 種拡張で増やさない」 contract が Step 15 で **bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH の 4 drum 状況下で routine entry addr が変化しない** ことで literal 実装的に保証される。 future drum 種拡張 (= t/i) でも同じ entry addr を保持することを Step 15 で先取り保証する (= 4 drum 段から 6 drum 段までの dispatch path 不変保証の漸増)。

## sub-sprint 構造

ADR-0026 / ADR-0027 / ADR-0028 同 pattern 踏襲、 1 sub = 1 commit + 1 push 規律:

| sub | commit hash | 内容 | driver 改修 | fixture 追加 | verify script 追加 | 一文要約 |
|---|---|---|---|---|---|---|
| α | `a8355f4` | 本 ADR 起票 Draft + Annex A placeholder | なし (= 完全不変) | なし | なし | ADR-0029 Draft 起票 (= 11 決定 + scope-out 29+ 項目 + 5 段 gate + 完了判定 10 項目 + layering 図 + Annex A 着手、 PMDDotNET CYM emit 再確認は ADR-0028 §Annex A-1 / §Annex A-2 引用で literal 確認済を ground truth とする、 driver 完全不変純 doc commit) |
| β | `b83778f` | CYM trigger 接続 + K-CYM fixture + verify | bit 2 分岐追加 (= bit 1 と bit 3 の間に挿入) + `_rhythm_event_cym_trigger` sub-routine 新規 + CYM sample pointer mapping + jr → jp 1 行精密化 (= cym sub-routine 挿入で jr 範囲超過対応) | `k-cr-only.mml` | `verify-step15-cym-trigger.sh` | pmdneo_rhythm_event_trigger に bit 2 CYM 分岐 + `_rhythm_event_cym_trigger @ 0x00119B` 新規 + adpcma_sample_top pointer mapping + K-CYM fixture + cym-trigger verify、 全 step12 + step13 + step14 BD/SD/HH regression PASS、 entry addr @ 0x001126 不変、 全 24 script PASS = 96 秒 |
| γ | `4c4c55c` | R-CYM fixture + differential verify 2 件 | なし (= 既に β で対応済) | `r-melody-cr-only.mml` | `verify-step15-kr-cym-differential.sh` + `verify-step15-bd-cym-differential.sh` | R-CYM fixture + K-CYM=R-CYM=0x001126 entry + K-CYM=R-CYM=0x00119B cym_trigger + BD vs CYM literal differ (0x00-0x03 vs 0x12-0x29) + SD vs CYM / HH vs CYM 推移的 proof、 全 26 script PASS = 108 秒 |
| δ | `(本 commit)` | 完了統合 + ADR Accepted + handoff + memory | なし | なし | なし | ADR-0029 Accepted 移行 + 完了判定 10/10 ✅ literal 反映 + 全 26 script 最終 regression PASS + user 試聴 audio gate OK + handoff doc + memory 3 件 + MEMORY.md index 更新 + transient step7-b3 finding = verify B 系統 (= build / asset pipeline) I/O 一時 issue 記録 (= driver runtime regression = verify A 系統 と独立) |

## Annex A: PMDDotNET CYM emit 再確認 + bitmap OR (CYM 込み combo) 動作調査 (= 16th session α 着手で literal 反映予定、 driver / fixture / verify script 完全不変純調査)

(本 ADR は Draft 起票時点。 α 着手で literal 反映予定。 ADR-0028 §Annex A-1 / §Annex A-2 で既に literal 確認済を本 ADR §Annex A で再引用 + bitmap OR CYM 込み combo 動作の追加 literal 確認。)

### A-1: PMDDotNET `\c` CYM emit literal 再確認 (= ADR-0028 §Annex A-1 引用、 mc.cs rcomtbl L9528-9533)

ADR-0028 §Annex A-1 で literal 確認済 (= `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` の `rcomtbl` L9528-9533):

```csharp
,new Tuple<char, Func<enmPass2JumpTable>>('b', bdset)    // \b → BD   (= bit 0 = 0x01)
,new Tuple<char, Func<enmPass2JumpTable>>('s', snrset)   // \s → SD   (= bit 1 = 0x02)
,new Tuple<char, Func<enmPass2JumpTable>>('c', cymset)   // \c → CYM  (= bit 2 = 0x04、 Step 15 対象)
,new Tuple<char, Func<enmPass2JumpTable>>('h', hihset)   // \h → HH   (= bit 3 = 0x08)
,new Tuple<char, Func<enmPass2JumpTable>>('t', tamset)   // \t → TOM  (= bit 4 = 0x10)
,new Tuple<char, Func<enmPass2JumpTable>>('i', rimset)   // \i → RIM  (= bit 5 = 0x20、 `\r` ではない)
```

#### Step 15 CYM 関連の確定

- **`\c` → cymset** (= mc.cs L9529 literal、 ADR-0028 §Annex A-1 と同行)
- cymset は `work.al = 4` を set して rs00 を呼ぶ (= ADR-0028 §Annex A-2 引用、 mc.cs L9691-9725 周辺)
- rs00 が `0xEB <al>` を emit (= ADR-0028 §Annex A-2 引用、 L9727-9750)
- 結果 `\c` 単独で `0xEB 0x04` emit (= bitmap bit 2 = CYM)
- **fixture 命名 `k-cr-only.mml` / `r-melody-cr-only.mml` の `cr` = `\c` + `r`(= rest) pattern は妥当**、 rename 不要 (= ADR-0028 §Annex A-1 で `\c` 確認済 + 本 ADR で再確認)

### A-2: PMDDotNET cymset emit core path literal 再確認 (= ADR-0028 §Annex A-2 引用、 mc.cs L9691-9725)

drum 6 種 set 関数 → rs00 → `0xEB <bitmap>` emit:

```csharp
// mc.cs L9691-9725 (= ADR-0028 §Annex A-2 引用)
private enmPass2JumpTable bdset()  { work.al = 1;  return rs00(); }  // BD  = bitmap 0x01
private enmPass2JumpTable snrset() { work.al = 2;  return rs00(); }  // SD  = bitmap 0x02
private enmPass2JumpTable cymset() { work.al = 4;  return rs00(); }  // CYM = bitmap 0x04 (= Step 15 対象)
private enmPass2JumpTable hihset() { work.al = 8;  return rs00(); }  // HH  = bitmap 0x08
private enmPass2JumpTable tamset() { work.al = 16; return rs00(); }  // TOM = bitmap 0x10
private enmPass2JumpTable rimset() { work.al = 32; return rs00(); }  // RIM = bitmap 0x20
```

#### CYM 単独 emit (= Step 15 fixture 期待 bytecode)

- `\c` + `r`(= rest) → `\c` (= cymset) → al = 4 → rs00 → rs02 path (= 新規 emit) → `0xEB 0x04`
- 続く `r` (= rest) は別 opcode 経路で処理 (= note rest length emit)
- fixture `k-cr-only.mml` の K part body 期待 bytecode = `0xEB 0x04 <rest length> ... 0x80` (= part end)
- 同様に `r-melody-cr-only.mml` の melody part body = `... 0xEB 0x04 <rest length> ... 0x80`

#### Step 15 driver 側 bitmap accept range 設計確認

ADR-0028 §Annex A-2 で確認済 + 本 ADR §決定 2 bitmap accept range と完全整合:

- bit 0 (= 0x01) = BD trigger (= 既存 Step 12 維持)
- bit 1 (= 0x02) = SD trigger (= 既存 Step 13 維持)
- bit 2 (= 0x04) = CYM trigger (= `\c`) → **本 ADR で新規追加**
- bit 3 (= 0x08) = HH trigger (= 既存 Step 14 維持)
- bit 4 (= 0x10) = TOM trigger → silent ignore
- bit 5 (= 0x20) = RIM trigger (= `\i`) → silent ignore
- bit 6 = (PMD V4.8s pattern body 内専用 flag) → silent ignore
- bit 7 = (note byte 識別 flag、 mc.cs 内 'p' marker) → silent ignore

driver は bit 0 + bit 1 + bit 2 + bit 3 のみ accept、 残り bit は silent ignore (= ADR-0026 §決定 11 / ADR-0028 §決定 2 「未対応 cmd スルー」 思想踏襲)。

### A-3: PMDDotNET bitmap OR 圧縮 emit 動作 (CYM 込み combo) literal 確認予定 (= α 着手で literal 反映、 ADR-0027 §Annex A-3 / ADR-0028 §Annex A-3 引用 + CYM 込み追加調査)

#### ADR-0027 / ADR-0028 §Annex A-3 引用 (= BD+SD combo の bitmap OR 圧縮 path、 mc.cs L9736-9746)

`\b\s` を間に何も挟まず連続記述した場合の emit 挙動 (= ADR-0027 §Annex A-3 literal 確認済):

1. 最初の `\b` を bdset 経由で処理 → al = 1 → rs00 → rs02 path → `0xEB 0x01` emit + di += 2 + prsok = 0x80 set
2. 次の `\s` を snrset 経由で処理 → al = 2 → rs00 → rs01 path check → 3 条件全成立 → bitmap OR → al |= cch (= 0x02 | 0x01 = 0x03) → m_buf di-1 を 0x03 で上書き → 結果 bytecode = `0xEB 0x03` (= BD+SD bitmap OR 1 opcode)

#### Step 15 で追加調査する CYM 込み combo 動作 (= α 着手で literal 反映予定)

- `\b\c` の連続記述 → 期待 emit = `0xEB 0x05` (= bit 0 | bit 2 = 0x01 | 0x04)
- `\s\c` の連続記述 → 期待 emit = `0xEB 0x06` (= bit 1 | bit 2 = 0x02 | 0x04)
- `\c\h` の連続記述 → 期待 emit = `0xEB 0x0C` (= bit 2 | bit 3 = 0x04 | 0x08)
- `\b\s\c` の連続記述 → 期待 emit = `0xEB 0x07` (= bit 0 | bit 1 | bit 2 = 0x01 | 0x02 | 0x04)
- `\b\c\h` の連続記述 → 期待 emit = `0xEB 0x0D` (= bit 0 | bit 2 | bit 3 = 0x01 | 0x04 | 0x08)
- `\s\c\h` の連続記述 → 期待 emit = `0xEB 0x0E` (= bit 1 | bit 2 | bit 3 = 0x02 | 0x04 | 0x08)
- `\b\s\c\h` の連続記述 → 期待 emit = `0xEB 0x0F` (= bit 0 | bit 1 | bit 2 | bit 3 = 0x01 | 0x02 | 0x04 | 0x08)
- 期待動作は ADR-0027 / ADR-0028 §Annex A-3 の bitmap OR 圧縮 path と同 pattern、 al |= cch で combo bitmap byte 1 個に圧縮
- α 着手で literal 動作確認 (= PMDDotNET compile + `.MN` hexdump で実 emit byte 列確認)

#### Step 15 fixture 設計への影響

Step 15 では simultaneous trigger combo scope-out (= ADR-0029 §決定 11 / 軸 4):

- `k-cr-only.mml` K part body = `\c r` 単独パターンのみ (= `\b\c` / `\s\c` / `\c\h` / `\b\s\c` 等並記なし)
- `r-melody-cr-only.mml` melody part body = `\c r` 単独パターンのみ
- bitmap 0x05 / 0x06 / 0x07 / 0x0C / 0x0D / 0x0E / 0x0F (= CYM 込み combo) が emit される fixture は **生成しない**
- driver の bitmap accept range は bit 0 / bit 1 / bit 2 / bit 3 個別 accept (= 例えば 0x05 が来た場合、 Step 15 driver が複数 bit を見れば BD + CYM 両方 trigger される可能性あり、 ただし Step 15 fixture では combo emit 経路を踏まない)
- bitmap OR semantics の literal proof (= simultaneous trigger) は future 候補温存 (= ADR-0029 §決定 11 維持)
- driver 動作可能性と仕様化は別軸 (= 動作可能性は incidental observation、 ADR 内では「未定義」 と明記)

### A-4: PMD V4.8s manual literal 用例 (= `docs/manual/PMDMML_MAN_V48s_utf8.txt`、 ADR-0027 §Annex A-4 / ADR-0028 §Annex A-4 引用)

#### drum trigger 用例 (= L226-228、 ADR-0028 §Annex A-4 引用)

```
R0	l16[\sr]4
R1	l8 \br\hr\sr\hr
R2	   \br\tr\tr\tr
```

- L226 `\sr` = SD + rest (= 16 分音符 4 個列)
- L227 `\br\hr\sr\hr` = BD + rest, HH + rest, SD + rest, HH + rest (= 8 分音符 4 個列、 BD+HH ペア)
- L228 `\br\tr\tr\tr` = BD + rest, TOM + rest, TOM + rest, TOM + rest

#### Step 15 CYM 関連の literal 確認 (= manual 内 `\cr` 用例調査予定)

- `\cr` (= CYM + rest) の manual 内 literal 用例は α 調査で確認予定 (= 完全 hit がない場合は ADR-0028 §Annex A-1 mc.cs rcomtbl L9528-9533 literal `'c' → cymset` を ground truth として採用、 manual 用例なしでも `\c` 記号自体は PMDDotNET ground truth で確定)
- CYM は manual / pop / rock 楽曲で BD+SD+HH+CYM 4 種 drum 標準セットの最後の構成要素
- fixture `k-cr-only.mml` / `r-melody-cr-only.mml` の `\cr` pattern は **PMD V4.8s 文法に整合**

### A-5: `adpcma_sample_top` driver-embedded 状況 literal 再確認 (= ADR-0028 §Annex A-5 引用、 standalone_test.s)

#### sample pointer table 内 reference (= ADR-0028 §Annex A-5 引用、 standalone_test.s L2871-2873)

```asm
; standalone_test.s L2871-2873 (= table A、 既存 Step 5 から不変)
adpcma_ch_sample_ptr_table:
        .dw     adpcma_sample_bd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top
```

- L = `adpcma_sample_bd` / M = `adpcma_sample_sd` / N = `adpcma_sample_hh` / O = `adpcma_sample_tom` / P = `adpcma_sample_rim` / Q = `adpcma_sample_top`
- L-Q ADPCM-A 6ch melody architecture 用 sample pointer table
- ADR-0019 §決定 3 build-time embed 流儀
- Q ch = `adpcma_sample_top` (= TOP cymbal sample symbol) ← **Step 15 で CYM trigger 用 reuse**

#### `adpcma_sample_top` literal embed (= ADR-0028 §Annex A-5 引用、 standalone_test.s L2893-2904)

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

- `adpcma_sample_top` は driver source `standalone_test.s` 内に既に embed 済 (= L2903-2904)
- `TOP_START_LSB / TOP_START_MSB / TOP_STOP_LSB / TOP_STOP_MSB` は `assets/samples.inc` 由来 const (= build 時 .include で展開、 asset 由来 = `assets/sounds/adpcma/2608_TOP.adpcma`)
- Step 15 で `_rhythm_event_cym_trigger` sub-routine が `ld hl, #adpcma_sample_top` で参照
- ADR-0027 §Annex A-6 (SD reuse) / ADR-0028 §Annex A-5 (HH reuse) pattern と完全同型

### A-6: Step 12 / Step 13 / Step 14 / Step 15 比較表

| 軸 | Step 12 (BD only) | Step 13 (BD+SD) | Step 14 (BD+SD+HH) | Step 15 (BD+SD+CYM+HH) |
|---|---|---|---|---|
| drum 種 | 1 (= b) | 2 (= b+s) | 3 (= b+s+h) | 4 (= b+s+c+h) |
| dispatch entry addr | 0x1126 | 0x1126 (= 不変) | 0x1126 (= 不変) | 0x1126 (= 不変) |
| dispatch path 内 bit 分岐 | bit 0 | bit 0 + bit 1 | bit 0 + bit 1 + bit 3 | bit 0 + bit 1 + bit 2 + bit 3 (= bit 2 を bit 1 と bit 3 の間に挿入) |
| sample symbol | adpcma_sample_bd | + adpcma_sample_sd | + adpcma_sample_hh | + adpcma_sample_top |
| sub-routine | _rhythm_event_bd_trigger | + _rhythm_event_sd_trigger | + _rhythm_event_hh_trigger | + _rhythm_event_cym_trigger |
| fixture 数 | 2 | 4 (= +K-SD/R-SD) | 6 (= +K-HH/R-HH) | 8 (= +K-CYM/R-CYM) |
| verify script 数 | 4 | 7 | 10 | 13 |
| 全 regression script 数 | 17 | 20 | 23 | 26 |
| simultaneous trigger | scope-out | scope-out | scope-out | scope-out (= 維持) |
| bit 4/5 ignore | yes | yes | yes | yes (= 維持) |
