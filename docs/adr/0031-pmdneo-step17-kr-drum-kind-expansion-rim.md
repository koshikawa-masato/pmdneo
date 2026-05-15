# ADR-0031: Step 17 — K/R drum kind expansion proof (i = RIM single-kind / dispatch path 1 本化不変 / 既存 adpcma_sample_rim symbol reuse / BD+SD+CYM+HH+TOM fixture 不変 + RIM fixture 2 件新規 / 5 軸 verify (= K-RIM trigger + R-RIM trigger + KR byte-identical + BD-vs-RIM differential + TOM-vs-RIM differential) / full 6 drum completion)

- 状態: **Accepted** (= 2026-05-15 19th session δ 完了統合で移行、 元 Draft 起票 2026-05-15 18th session 冒頭、 ADR/β/γ/δ 4 commit chain 全 PASS + user audio gate OK + 全 34 script regression 128 秒 PASS で Accepted 移行 = **full 6 drum completion milestone 確定**、 注: ADR-0030 同型 sub-sprint 4 段表 (= ADR/β/γ/δ) のうち α 段は user 着手判断で ADR Draft commit に統合 = ADR-0030 §Annex A-1 で `\t → tamset → 0xEB 0x10` literal 確認済 + mc.cs L9533 `('i', rimset)` literal 確認済 + L9721 `rimset → work.al = 32` literal 確認済を ground truth として独立 α commit なしで β 進行)
- 起票日: 2026-05-15
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0030 (= step 16 K/R drum kind expansion proof — t = TOM、 §決定 8 「dispatch path は drum 種拡張で増やさない」 + §決定 2 「b+s+c+h+t proof」 + §scope-out 「i 残り 1 種」 を本 ADR で 1 軸消化 + 5 drum 段 → 6 drum 段に完成、 §Annex A-1 で `'i' → rimset` literal 確認済 + §Annex A-2 で `rimset` = `work.al = 32; return rs00();` literal 確認済 + §Annex A-5 で `adpcma_sample_rim` standalone_test.s L2899-2900 内 embed 済 literal 確認済)、 ADR-0029 (= step 15 K/R drum kind expansion proof — c = CYM、 §決定 8 「dispatch path は drum 種拡張で増やさない」)、 ADR-0028 (= step 14 K/R drum kind expansion proof — h = HH)、 ADR-0027 (= step 13 K/R drum kind expansion proof — s = SD)、 ADR-0026 (= step 12 K/R rhythm compatibility proof、 §決定 6 「dispatch path 1 本化」)、 ADR-0025 (= step 11 multi-table id=0x01 proof)、 ADR-0024 (= step 10 sample_table_id selection consumption、 explicit if/jr 流儀踏襲)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed)、 ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive → step 12 で reconnected → step 13 で b+s → step 14 で b+s+h → step 15 で b+s+c+h → step 16 で b+s+c+h+t → 本 ADR で b+s+c+h+t+i drum kind 1 軸拡張 = **full 6 drum completion**)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様、 drum 識別文字 = `b/s/c/h/t/i` 6 種 = PMDDotNET mc.cs rcomtbl L9528-9533 literal、 本 ADR §Annex A-1 で literal 引用、 manual L228 `\br\tr\tr\tr` 用例 = TOM 直接使用例で RIM 直接用例は manual 内に literal 用例なし = mc.cs rcomtbl のみが ground truth、 本 ADR §Annex A-4 で literal 整理)

## 背景

Step 16 (= ADR-0030 Accepted、 2026-05-15 17th session、 commit `b63f02f`) で K/R drum kind expansion proof — t = TOM sprint が成立した。 driver は PMD V4.8s 系 K part `\t` + melody part inline `\t` の 2 系統 MML syntax を、 PMDDotNET `0xEB 0x10` bytecode を経て driver `.MN` direct parser で normalize し、 `pmdneo_rhythm_event_trigger` (@ 0x1126) entry addr 不変を維持しつつ routine 内部の bit 4 TOM 分岐 + 独立 sub-routine `_rhythm_event_tom_trigger` (@ 0x11FC) で `adpcma_sample_tom` を ADPCM-A L ch に register write する contract chain を、 PC trace + ymfm-trace 二段 gate + byte-identical literal proof + BD/TOM sample addr literal differ + SD/CYM/HH vs TOM 推移的区別で literal 観測可能にした。 5 drum 段 (= b+s+c+h+t) で dispatch path 1 本化が literal 実装的に保証された。

ADR-0030 §決定 2 で確立した「drum kind = b + s + c + h + t proof」 と、 §決定 8 で確立した「**dispatch path は drum 種拡張で増やさない**」 という 2 つの contract に対し、 Step 17 はその **最終的な 1 軸拡張** を担う:

- 「**drum 種を b + s + c + h + t (= BD + SD + CYM + HH + TOM only) から b + s + c + h + t + i (= RIM 追加、 計 6 drum = full PMD rhythm drum set) に 1 軸拡張**」
- 「**dispatch path は不変 (= `pmdneo_rhythm_event_trigger` @ 0x1126 entry addr 継続)**」 → ADR-0030 §決定 8 が 6 drum 状況下で literal 維持されることの proof
- 「**sample pointer mapping のみ拡張**」 (= bit 0 → BD addr / bit 1 → SD addr / bit 2 → CYM addr / bit 3 → HH addr / bit 4 → TOM addr / bit 5 → RIM addr)
- 「**full 6 drum completion = PMD rhythm drum set の 6 種全て (= b/s/c/h/t/i = BD/SD/CYM/HH/TOM/RIM) を driver に embed**」 → Step 12-17 の 6-step drum 種漸進拡張 sprint chain の完成

ADR-0030 §決定 8 (= drum 種拡張で dispatch path 不変) と §決定 11 (= scope-out 35+ 項目維持) の延長で、 K/R semantics の MML 互換 surface area を **drum kind 軸最終 1 段** だけ広げる小規模 proof sprint。 「drum kind expansion proof」 という言葉自体が示すように、 simultaneous trigger semantics / channel allocation 改定 / `.PNE` rhythm bank migration / dispatch table-driven 化 / 制御 cmd 現役化軸は触らない。

ただし「6 drum 完成」 と素朴に定義すると scope が再び肥大化する (= simultaneous trigger semantics 一気 / table-driven dispatch refactor 一気 / channel allocation 改定 / `.PNE` rhythm bank migration / 制御 cmd 現役化 等を同時に触る)。 17th session 末 user 直接指示 + 18th session 冒頭壁打ち で以下の方針整理が確定:

- **drum 種拡張軸 = bit 5 RIM のみ accept** (= 全 drum 種 = b/s/c/h/t/i 6 種 accept、 bit 6-7 は reserved 維持) (= 軸 1)
- **BD+RIM / SD+RIM / CYM+RIM / HH+RIM / TOM+RIM / 3+ combo 同時打ち scope-out** (= bitmap OR semantics literal proof は future 候補温存、 full 6 drum 完成後の simultaneous trigger sprint 候補) (= 軸 4)
- **RIM sample source = existing `adpcma_sample_rim` symbol reuse as driver-embedded proof fixture** (= ADR-0027 §決定 3 SD = 既存再利用 pattern + ADR-0028 §決定 3 HH = 既存再利用 + ADR-0029 §決定 3 CYM = 既存再利用 + ADR-0030 §決定 3 TOM = 既存再利用 pattern 踏襲、 driver-embedded 4 byte sample header をそのまま再利用、 「rim」 は sample provenance 名と PMD semantics 名が **完全一致**、 alias 新設なし、 final rhythm sample ownership は未確定) (= 軸 1)
- **fixture = `k-ir-only.mml` + `r-melody-ir-only.mml` 2 件新規 + BD/SD/CYM/HH/TOM fixture 完全不変** (= 12 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM / K-RIM / R-RIM、 命名 = `\i` + `r`(= rest) pattern、 RIM 略称ではない) (= 軸 2)
- **verify gate = 5 軸** (= K-RIM trigger + R-RIM trigger + K-RIM vs R-RIM byte-identical + BD vs RIM differential + TOM vs RIM differential、 keyon count identical + PC marker hit + ymfm-trace literal register value assert、 ADR-0030 §verify gate 3 軸 pattern + full 6 drum completion sprint で RIM proof を厚めに対応) (= 軸 5)
- **dispatch 構造 = hybrid (= Step 16 sub-routine pattern 踏襲 + `_rhythm_event_rim_trigger` 独立 sub-routine 追加 + table-driven refactor は scope-out)** (= 軸 3 / 軸 5)
- **bit 5 = RIM 分岐の挿入位置 = 最後の active bit として tail-call 末尾** (= bit 4 TOM を Step 16 tail-call から call nz pattern に戻し、 bit 5 RIM が new tail-call target、 PMD bitmap bit 順序 0/1/2/3/4/5 維持、 explicit if/jr/jp branch 流儀継承) (= 軸 3)

これに基づき Step 17 を **「K/R drum kind expansion proof — i = RIM」** として定義する。 ADR-0030 dispatch path 1 本化を **6 drum 状況下で literal 維持** することの proof であり、 「dispatch path は drum 種拡張で増やさない」 が Step 17 で 6 drum 段で実装的に保証される (= 5 drum 段 → 6 drum 段 漸進拡張、 = **full 6 drum completion**)。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 Step 17 着手前に方針を ADR として独立起票する。

### 18th session 冒頭壁打ちでの 5 軸方針確定

ADR-0031 起票前に user 主導で 5 軸 (= sub-sprint 構成軸を含む meta 確認 1 軸 + 軸 1-5) の壁打ちが行われ、 Step 17 の出口像が以下に固定された (= 軸 1-5 は ADR-0030 と同 pattern、 sub-sprint は ADR-0030 と同 4 段、 verify gate 構成のみ 3 軸 → 5 軸に user judgement で厚め設定 = full 6 drum completion sprint 特性反映)。

**軸 1: RIM sample source = existing `adpcma_sample_rim` symbol reuse**

RIM trigger で使う sample (= 軸 1 / (rim_s1) 採用):

- (rim_s1) (= **採用**): existing `adpcma_sample_rim` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 + ADR-0028 §決定 3 HH = 既存再利用 + ADR-0029 §決定 3 CYM = 既存再利用 + ADR-0030 §決定 3 TOM = 既存再利用 pattern 踏襲、 melody architecture P ch (= P part) sample symbol と現段階で共有、 rhythm-dedicated symbol 分離は scope-out、 「rim」 は sample provenance 名と PMD semantics 名が完全一致 = wording 分離不要)
- (rim_s2) (= 不採用): new alias symbol 追加 (= sample source = RIM で provenance / semantics 一致につき alias 新設は冗長、 ADR-0030 で確立した「alias 新設なし」 規律と inconsistent)
- (rim_s3) (= 不採用): 別 sample (= BD / SD / HH / CYM / TOM 等) を temporarily 流用 (= 区別困難で audio gate で BD/SD/HH/CYM/TOM/RIM 6 種区別が損なわれる)
- (rim_s4) (= 不採用): 完全新規 sample data + symbol を VROM に追加 (= ADR-0027 SD / ADR-0028 HH / ADR-0029 CYM / ADR-0030 TOM pattern inconsistent + VROM 容量増 + samples.inc 拡張 + ADPCM-A converter 走らせる手間)

(rim_s1) 採用根拠: Step 17 目的は drum kind expansion proof + **full 6 drum completion** で sample source proof / symbol separation proof ではない、 既存 `adpcma_sample_rim` は ADR-0025 step5b で ADPCM-A subsystem 内に embed 済で再利用可、 ADR-0027 SD pattern + ADR-0028 HH pattern + ADR-0029 CYM pattern + ADR-0030 TOM pattern 踏襲で consistency 維持、 BD/SD/CYM/HH/TOM/RIM 6 symbol 間で literal addr differ が既に確保される (= bd / sd / hh / top / tom / rim 6 symbol それぞれ違う sample header literal addr)、 PMD/OPN rhythm では RIM = rim-shot 相当として扱うのが自然 (= asset 側 `2608_RIM.adpcma` で provenance 明確、 semantics 名と一致)、 driver サイズ / VROM / asset pipeline 不変、 final rhythm sample ownership は未確定で `.PNE` rhythm bank migration を future に温存。

ADR / handoff 記載要件:
- RIM sample source = **existing `adpcma_sample_rim` symbol reuse**
- 新規 alias symbol = **作らない** (= sample provenance 名と PMD semantics 名が完全一致で alias 不要)
- 新規 sample import = **scope-out**
- 「rim」 = **sample provenance 名 + PMD semantics 名の完全一致** (= asset 由来 = `2608_RIM.adpcma`、 L-Q melody architecture P ch sample symbol、 PMD MML 記号 `\i`、 PMD V4.8s `rimset` handler)
- PMD MML 記号は `\i` (= ADR-0030 §決定 2 で literal 言及済、 mc.cs rcomtbl L9533 = `'i' → rimset` 本 ADR §Annex A-1 で literal 確認)
- **`\r` ではない** (= `\r` は rest 専用、 ADR-0027 §Annex A-1 / memory `project_pmd_rim_drum_char_correction` literal 整合、 future contributor 向け literal 注記)
- PMDDotNET source 上の handler 名は `rimset` (= mc.cs L9721 literal、 PMD V4.8s 系の rhythm naming convention で実質 RIM = rim-shot semantics と一致、 ADR-0030 `tamset` vs TOM legacy naming のような wording 分離は不要、 PMDNEO 側 wording も RIM 統一でそのまま使える)
- `.PNE` rhythm bank migration = **future** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 / ADR-0030 §決定 3 future migration path 継続)
- Step 17 は **drum kind expansion proof = full 6 drum completion**、 sample source proof / symbol separation proof ではない
- bit 0 → `adpcma_sample_bd` / bit 1 → `adpcma_sample_sd` / bit 2 → `adpcma_sample_top` / bit 3 → `adpcma_sample_hh` / bit 4 → `adpcma_sample_tom` / bit 5 → `adpcma_sample_rim` の **6 drum 完成 mapping** を driver source 内に literal 配置
- melody sample symbol (= L-Q architecture P ch) と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

**軸 2: fixture 体制 = BD/SD/CYM/HH/TOM fixture 完全不変 + RIM fixture 2 件新規 (= 18th session 冒頭確定)**

K-RIM / R-RIM fixture 取り扱い:

- (fix1) (= **採用**): 12 fixture 体制 (= 既存 10 fixture 完全不変 + `k-ir-only.mml` + `r-melody-ir-only.mml` 新規追加)
- (fix2) (= 不採用): 10 fixture 維持 (= 既存 TOM fixture を RIM 版に置換、 TOM regression script が消失)
- (fix3) (= 不採用): BD/SD/CYM/HH/TOM/RIM 6-way 単一 fixture (= K-R differential verify がやりにくい + simultaneous trigger との境界が曖昧化)
- (fix4) (= 不採用): K-RIM のみ (= R-RIM 省略、 K-R dispatch shared invariant が RIM で verify されない)

(fix1) 採用根拠: Step 12 BD proof + Step 13 SD proof + Step 14 HH proof + Step 15 CYM proof + Step 16 TOM proof を regression として残せる、 Step 17 RIM proof を独立追加できる、 BD/SD/CYM/HH/TOM path を壊していないことを継続確認できる (= 「動いているものを壊さない」 規律遵守)、 K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM / K-RIM / R-RIM の 12 fixture 体制が読みやすい、 全 6 drum 同時打ち scope-out 前提で単一 fixture に混ぜない方が良い、 full 6 drum completion sprint なので最終 fixture 体制が安定する。

命名規則:

- `k-ir-only.mml` (= K part 内 `\i` + `r`(= rest)、 既存 `k-br-only.mml` / `k-sr-only.mml` / `k-cr-only.mml` / `k-hr-only.mml` / `k-tr-only.mml` と 1 文字違い)
- `r-melody-ir-only.mml` (= melody part L 内 inline `\i` + `r`(= rest)、 既存 `r-melody-br-only.mml` / `r-melody-sr-only.mml` / `r-melody-cr-only.mml` / `r-melody-hr-only.mml` / `r-melody-tr-only.mml` と 1 文字違い)
- `ir` の `i` = `\i` (= RIM trigger 識別文字、 mc.cs rcomtbl L9533 literal 確認済) + `r` = rest 専用文字
- `ir` は **「RIM」 略ではない** (= 既存 `br` / `sr` / `cr` / `hr` / `tr` と同 命名 pattern、 drum 略称命名 ではなく fixture pattern 命名 = `\<drum 識別文字>` + `r`(rest))
- 「rim」 は **sample provenance 名と PMD semantics 名の完全一致** (= ADR-0029 「top」 vs「CYM」 のような wording 分離は不要、 driver source / fixture / verify / doc 全てで RIM 表記統一)

ADR / handoff 記載要件:
- BD/SD/CYM/HH/TOM fixture (= `k-br-only.mml` / `r-melody-br-only.mml` / `k-sr-only.mml` / `r-melody-sr-only.mml` / `k-cr-only.mml` / `r-melody-cr-only.mml` / `k-hr-only.mml` / `r-melody-hr-only.mml` / `k-tr-only.mml` / `r-melody-tr-only.mml`) は **完全不変**
- RIM fixture 2 件 (= `k-ir-only.mml` / `r-melody-ir-only.mml`) を新規追加
- fixture 名の `ir` は **`\i` + `r`(rest) fixture pattern** であり「RIM」 略ではない (= 既存 `br` / `sr` / `cr` / `hr` / `tr` pattern と統一、 future contributor 向け literal 注記、 ADR + handoff doc 必須記載)
- verify token は **`rim` (= 3 char、 drum semantics 名)** (= fixture pattern token と区別、 verify script は人間が読む proof 名なので semantics 名優先、 既存 sd / hh / cym / tom の 2-3 char 統一は drum 名可変長として割り切る)
- α 調査で PMDDotNET が RIM を `\i` として emit することを literal 確認 (= 本 ADR §Annex A-1 で mc.cs L9533 = `('i', rimset)` literal 確認済)
- BD/SD/CYM/HH/TOM/RIM 6-way 差分は verify script で literal に確認 (= BD vs RIM differential 1 script + TOM vs RIM differential 1 script + SD vs RIM / CYM vs RIM / HH vs RIM differential は scope-out、 推移的に proof 成立)

**軸 3: bit 5 mapping = bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM + bit 5 RIM accept、 bit 6-7 reserved (= last active bit tail-call pattern 移動、 silent ignore 終了)**

軸 1 / 軸 3 回答内で確定済の bit mapping:

- bit 0 = BD trigger (= 既存 ADR-0026 維持、 call nz pattern)
- bit 1 = SD trigger (= 既存 ADR-0027 維持、 call nz pattern)
- bit 2 = CYM trigger (= 既存 ADR-0029 維持、 call nz pattern)
- bit 3 = HH trigger (= 既存 ADR-0028 = ADR-0030 で call nz pattern 戻し済、 維持)
- bit 4 = TOM trigger (= 既存 ADR-0030 まで tail-call pattern → **本 ADR で call nz pattern に戻し**、 Step 17 で bit 5 RIM 追加に伴う tail-call pattern 末尾移動)
- bit 5 = RIM trigger (= `\i`、 mc.cs `rimset` 経由) → 本 ADR で新規追加、 **new tail-call pattern target = full 6 drum completion**
- bit 6-7 = reserved (= PMD bitmap 範囲外、 silent ignore 維持)
- bitmap = 0x00 = no-op
- bitmap = 0x03 / 0x05 / 0x06 / 0x07 / ... / 0x21 / 0x22 / 0x23 / ... / 0x3F (= 6 drum 段 simultaneous trigger combo) → bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4、 動作は α 調査で literal 確認 + Annex A 反映、 Step 17 fixture では生成しない)

#### bit 5 = RIM 分岐の挿入位置 = 最後の active bit として tail-call 末尾 (= PMD bitmap bit 順序 0/1/2/3/4/5 維持、 軸 3 確定)

dispatch path 内 bit 5 = RIM 分岐挿入位置:

- (b1) (= **採用**): 最後の active bit として tail-call 末尾 (= bit 4 TOM を Step 16 tail-call から call nz pattern に戻し、 bit 5 RIM が new tail-call target、 PMD bitmap bit 順序維持)
- (b2) (= 不採用): 全 bit を uniform call nz pattern に refactor (= tail-call 廃止、 ADR-0030 hybrid pattern 踏襲 + table-driven refactor scope-out wording と inconsistent、 Step 17 で refactor を混ぜる risk)
- (b3) (= 不採用): bit 5 RIM を call nz pattern に追加 + bit 4 TOM を tail-call 維持 (= control flow が bit 5 check まで到達せず、 機能的に成立しない)

(b1) 採用根拠: Step 16 で確立した「最後の active bit = tail-call」 invariant の維持、 full 6 drum completion で bit 5 RIM が最終 active bit、 PMD bitmap bit 0/1/2/3/4/5 の natural order との整合性、 ADR-0028 / ADR-0029 / ADR-0030 で SD trigger / HH trigger / CYM trigger / TOM trigger sub-routine entry addr が literal shift observed と同 pattern で internal sub-routine entry addr の再 shift は許容 (= invariant の本質は shared dispatch entry 不変 + register write sequence 不変)、 dispatch path entry addr 0x1126 は不変、 BD/SD/CYM/HH trigger path 完全不変、 TOM trigger path 内部不変で entry addr は shift する可能性、 RIM trigger path 新規追加。

**軸 4: simultaneous trigger scope-out 維持**

軸 1 / 軸 4 回答内で確定済の simultaneous trigger:

- BD+SD / BD+CYM / SD+CYM / BD+SD+CYM / ... / BD+RIM / SD+RIM / CYM+RIM / HH+RIM / TOM+RIM / 3+ combo RIM 込み 同時打ち = **scope-out**
- 全 6 drum 同時打ち (= bitmap 0x3F) = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 18+ 候補、 simultaneous trigger semantics proof sprint として独立起票、 full 6 drum completion 後)
- Step 17 fixture は **BD 単独 / SD 単独 / CYM 単独 / HH 単独 / TOM 単独 / RIM 単独 のみ**
- driver 上で動く可能性 (= dispatch path 内で bit ごとに独立判定で combo bitmap も harmful なし) と、 仕様化 (= ADR 内で「未定義」 明記) は別軸
- combo bitmap が ADR 内で「未定義」 と明記される (= driver 動作は incidental observation、 仕様としては未定義)

**軸 5: verify gate = 5 軸 + dispatch 構造 = hybrid (sub-routine pattern 踏襲 + table-driven scope-out)**

verify 範囲 (= full 6 drum completion sprint で RIM proof を厚めに対応、 ADR-0030 3 軸 pattern + 2 軸 追加):

- (v1) (= **採用**): 5 軸 verify (= K-RIM trigger 単独 + R-RIM trigger 単独 + K-RIM vs R-RIM byte-identical + BD vs RIM differential + TOM vs RIM differential)
- (v2) (= 不採用): 3 軸 verify (= ADR-0030 同型、 RIM trigger 単独 1 script + KR-byte-identical 1 script + BD vs RIM differential 1 script、 TOM vs RIM 推移的 proof でカバー)、 Step 16 で新参 TOM と RIM の前後関係 (= bit 4 → bit 5 dispatch 順 + tail-call invariant 移動) の literal verify が欠ける
- (v3) (= 不採用): 8 軸 verify (= 5 軸 + SD vs RIM + CYM vs RIM + HH vs RIM differential、 N(N-1)/2 mutual differential 増殖、 ADR-0028 / ADR-0029 / ADR-0030 §scope-out 「N-1 pair gate 推移的区別」 precedent inconsistent)

(v1) 採用根拠: Step 17 目的は「RIM が鳴る」 だけではなく drum kind expansion proof = **full 6 drum completion**、 K と R が同じ RIM dispatch path を通ることを確認する必要がある (= dispatch path 1 本化の 6 drum 状況下での維持)、 BD と RIM が register / sample address 上で区別できる必要がある (= drum kind mapping の literal proof)、 TOM と RIM が register / sample address 上で区別できる必要がある (= Step 16 で新参 TOM と RIM の前後関係 + bit 4 → bit 5 dispatch 順 + tail-call invariant 移動の literal verify、 = full 6 drum completion sprint で RIM proof を厚めに対応)、 BD/SD/CYM/HH/TOM path regression も同時に守れる、 silent path に倒れただけではないことを確認できる、 SD vs RIM / CYM vs RIM / HH vs RIM 推移的区別は ADR-0028 / ADR-0029 / ADR-0030 §verify gate Gate 4 注記 pattern 踏襲で literal proof 成立 (= BD-vs-SD + BD-vs-HH + BD-vs-CYM + BD-vs-TOM + BD-vs-RIM から N-1 pair gate で N 軸 mutual differential を推移的に確立)、 K-RIM trigger と R-RIM trigger を別 script に分離するのは full 6 drum completion sprint で per-fixture proof を独立観測可能化する判断。

dispatch 構造:

- (d1) (= **採用**): hybrid = Step 16 sub-routine pattern 踏襲 + `_rhythm_event_rim_trigger` 独立 sub-routine 追加 + bit 5 分岐挿入位置 = 最後の active bit として tail-call 末尾 + table-driven refactor は scope-out
- (d2) (= 不採用): table-driven (= bit → sample addr lookup table に集約、 dispatch path + sub-routine も 1 本に帰結)
- (d3) (= 不採用): Step 16 sub-routine pattern 踏襲のみ、 future refactor 言及なし

(d1) 採用根拠: Step 17 目的は「i = RIM expansion proof = full 6 drum completion」、 ここで table-driven 化すると drum 種追加 proof と dispatch refactor が混ざる、 Step 16 と同型にすることで BD/SD/CYM/HH/TOM/RIM の differential proof が読みやすい、 6 drum 段到達後 (= Step 17 完了後) に table-driven 化する方が判断材料が揃う、 dispatch path 不変の本質は entry point と runtime event path が増えないことなので内部 sub-routine 追加は許容、 `pmdneo_rhythm_event_trigger` entry addr 不変が primary invariant、 `_rhythm_event_rim_trigger` は proof 用 explicit branch (= future table-driven 化対象、 Step 18+ 候補)、 full drum set 到達後 (= b/s/c/h/t/i 6 drum) に table-driven refactor を検討。

verify gate 構成:

```
K-RIM trigger:
  bit5 → RIM trigger (= ADPCM-A L ch RIM register write trace + keyon count + PC marker)

R-RIM trigger:
  bit5 → 同じ RIM trigger (= K-RIM vs R-RIM byte-identical literal proof + PC marker)

KR byte-identical:
  K-RIM と R-RIM で 6 件 reg write byte-identical

BD vs RIM:
  bit0 と bit5 で sample addr が違う (= reg 0x10 sample addr literal differ + reg 0x18 sample end addr literal differ)

TOM vs RIM:
  bit4 と bit5 で sample addr が違う (= Step 16 新参 TOM と Step 17 新参 RIM の前後関係 literal proof、 tail-call invariant 移動の literal verify)
```

加えて (= ADR-0030 §verify gate 規律踏襲):

- **keyon count identical** (= K-RIM と R-RIM で ADPCM-A L ch keyon mask 0x01 trigger count 同一)
- **PC marker hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126 PC trace hit、 K-RIM / R-RIM 両方で同 addr hit)
- **ymfm-trace literal register value assert** (= sample addr reg 値を literal 数値で assert、 visual diff ではなく数値 assert)

ADR / handoff 記載要件:
- verify gate は **5 軸 (= K-RIM trigger + R-RIM trigger + K-RIM vs R-RIM byte-identical + BD vs RIM differential + TOM vs RIM differential)**
- 5 件の verify script を新規追加
- `verify-step17-k-rim-trigger.sh` (= K-RIM fixture で RIM register write trace + keyon count + PC marker)
- `verify-step17-r-rim-trigger.sh` (= R-RIM fixture で RIM register write trace + keyon count + PC marker)
- `verify-step17-kr-rim-byte-identical.sh` (= K-RIM vs R-RIM byte-identical literal proof)
- `verify-step17-bd-vs-rim-differential.sh` (= BD vs RIM sample addr literal differ proof)
- `verify-step17-tom-vs-rim-differential.sh` (= TOM vs RIM sample addr literal differ proof、 Step 16 新参 TOM と Step 17 新参 RIM の前後関係 explicit verify)
- SD vs RIM / CYM vs RIM / HH vs RIM 推移的区別は ADR-0028 / ADR-0029 / ADR-0030 precedent 踏襲で explicit gate 不要 (= 推移的 proof 成立)
- 既存 29 script regression に 5 件追加 = 34 script 体制
- dispatch 構造 = **hybrid** (= Step 16 sub-routine pattern 踏襲 + `_rhythm_event_rim_trigger` 独立 sub-routine 追加 + table-driven refactor は future scope-out)
- mutual pairwise explosion を避ける (= BD-vs-SD / BD-vs-HH / BD-vs-CYM / BD-vs-TOM / BD-vs-RIM から推移的に drum 種差分を扱う規律、 TOM-vs-RIM のみ前後関係 explicit gate)

**軸 6 (meta): sub-sprint 構成 = ADR-0028 / ADR-0029 / ADR-0030 同型 4 段 (= ADR / β / γ / δ)**

sub-sprint 構成:

- (s1) (= **採用**): 4 sub-sprint = α (= ADR-0031 Draft 起票、 doc only commit、 ADR-0030 §Annex A-1 / §Annex A-2 引用で literal 確認済を ground truth + mc.cs L9533 `('i', rimset)` literal 確認 + L9721 `rimset → work.al = 32` literal 確認を本 commit に統合) + β (= driver bit 5 分岐 + `_rhythm_event_rim_trigger` sub-routine + bit 4 TOM call nz pattern 戻し + K-RIM fixture + `verify-step17-k-rim-trigger.sh`) + γ (= R-RIM fixture + `verify-step17-r-rim-trigger.sh` + `verify-step17-kr-rim-byte-identical.sh` + `verify-step17-bd-vs-rim-differential.sh` + `verify-step17-tom-vs-rim-differential.sh`) + δ (= 完了統合 + ADR Accepted + memory + MEMORY.md index)
- (s2) (= 不採用): 5 sub-sprint (= α/β/γ/δ/ε、 γ と δ を分割、 commit 粒度細かいが冗長)
- (s3) (= 不採用): 3 sub-sprint に圧縮 (= α/β/γ、 driver + 全 fixture + 全 verify を 1 commit に同梱、 PR レビュー粒度粗化 + 異常時の原因特定困難化)

(s1) 採用根拠: ADR-0028 / ADR-0029 / ADR-0030 と同型 4 段 = pattern 安定、 1 sub = 1 commit + 1 push 規律遵守、 audio gate は δ 前 (= γ 完了時) に user 試聴、 各 sub で全 step12 + step13 + step14 + step15 + step16 BD/SD/HH/CYM/TOM path verify script PASS が確認できる粒度。

## 決定

### 決定 1: Step 17 を「K/R drum kind expansion proof — i = RIM」 として定義 (= bit 5 RIM 1 軸拡張 = full 6 drum completion、 dispatch path 1 本化不変、 既存 adpcma_sample_rim symbol reuse、 BD/SD/CYM/HH/TOM fixture 不変 + RIM fixture 2 件新規、 5 軸 verify、 hybrid dispatch 構造、 bit 5 挿入位置 = 最後の active bit として tail-call 末尾)

Step 17 の最終 deliverable boundary を **「K part `\i` + melody part inline `\i` の 2 系統 MML syntax を受取り、 driver `.MN` direct parser で normalize して、 共通 routine `pmdneo_rhythm_event_trigger` 経由で bit 5 分岐 → `_rhythm_event_rim_trigger` sub-routine → 既存 `adpcma_sample_rim` symbol reuse → ADPCM-A L ch RIM trigger に audible に dispatch する」** とする。 PMDDotNET / `.MN` format / `pmdneo_rhythm_event_trigger` routine entry / observability marker / driver-embedded fixture 規律は完全不変、 drum 種 → sample pointer mapping table のみ bit 0 → BD + bit 1 → SD + bit 2 → CYM + bit 3 → HH + bit 4 → TOM + bit 5 → RIM に 1 軸拡張 = **full 6 drum completion**、 PC trace + ymfm-trace の 5 軸 gate (= K-RIM trigger + R-RIM trigger + KR byte-identical + BD vs RIM differential + TOM vs RIM differential) で **drum kind expansion 後 (= 6 drum 段) も dispatch path が 1 本化されていること** + **drum 種で sample addr が literal 区別されること** + **Step 16 新参 TOM と Step 17 新参 RIM の前後関係も literal 区別されること** を literal 観測可能にすることを目的とする。

#### Step 16 → Step 17 拡張点

ADR-0030 で確立した contract のうち、 Step 17 で **拡張** されるのは:

- driver の K/R 受入 drum 種範囲: b + s + c + h + t (= BD + SD + CYM + HH + TOM) → b + s + c + h + t + i (= BD + SD + CYM + HH + TOM + RIM) = **full 6 drum**
- driver-embedded sample 表 entry 数: BD + SD + CYM + HH + TOM 5 種 → BD + SD + CYM + HH + TOM + RIM 6 種 (= 既存 `adpcma_sample_rim` symbol reuse、 新規 embed なし)
- drum 種 → sample pointer mapping: bit 0 + bit 1 + bit 2 + bit 3 + bit 4 → bit 0 + bit 1 + bit 2 + bit 3 + bit 4 + bit 5
- fixture 数: 10 件 (= K-BD + R-BD + K-SD + R-SD + K-CYM + R-CYM + K-HH + R-HH + K-TOM + R-TOM) → 12 件 (= + K-RIM + R-RIM)
- verify script 数: step12 系 4 件 + step13 系 3 件 + step14 系 3 件 + step15 系 3 件 + step16 系 3 件 = 16 件 → step12 系 4 件 + step13 系 3 件 + step14 系 3 件 + step15 系 3 件 + step16 系 3 件 + step17 系 5 件 = 21 件
- 全 regression script 数: 29 件 → 34 件 (= step12 / step13 / step14 / step15 / step16 既存 + step17 新規 5 件)
- driver sub-routine 数: bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM 5 sub-routine → bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM + bit 5 RIM 6 sub-routine = **full 6 drum sub-routine completion**
- dispatcher 末尾の tail-call target: `_rhythm_event_tom_trigger` (= Step 16 まで) → `_rhythm_event_rim_trigger` (= Step 17 以降、 bit 4 TOM は call nz pattern に戻し)

Step 17 で **不変** に保つもの:

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126、 ADR-0030 §決定 9 PC marker 維持) ← **invariant の primary 軸 = shared dispatch entry**
- `pmdneo_rhythm_event_trigger` routine 構造 (= bit 0 / bit 1 / bit 2 / bit 3 / bit 4 分岐既存、 bit 5 分岐を末尾に新規追加するが routine entry / 引数 / 戻り値 ABI は不変)
- `_rhythm_event_bd_trigger` sub-routine の **register write sequence** (= Step 12 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で shift 可)
- `_rhythm_event_sd_trigger` sub-routine の **register write sequence** (= Step 13 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 17 改修で再 shift observed 想定)
- `_rhythm_event_cym_trigger` sub-routine の **register write sequence** (= Step 15 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 17 改修で再 shift observed 想定)
- `_rhythm_event_hh_trigger` sub-routine の **register write sequence** (= Step 14 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 17 改修で再 shift observed 想定)
- `_rhythm_event_tom_trigger` sub-routine の **register write sequence** (= Step 16 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 17 改修で tail-call → call nz pattern 変更 + entry addr 再 shift observed 想定)

#### invariant 精密化 (= ADR-0028 / ADR-0029 / ADR-0030 §invariant 精密化引用)

**invariant の本質は「sub-routine entry addr 不変」 ではなく「shared dispatch entry 不変 + register write sequence 不変」**:

- **shared dispatch entry 不変**: `pmdneo_rhythm_event_trigger` entry addr (= 0x1126) は Step 12/Step 13/Step 14/Step 15/Step 16/Step 17 で完全同一 literal 維持 (= K/R 両 source path が同 entry に collapse)
- **register write sequence 不変**: 各 drum trigger sub-routine 内の 6 件 reg write (= reg 0x10/0x18/0x20/0x28/0x08/0x00 + literal value) は drum 種ごとに sample addr literal differ するが sequence 構造は完全不変、 既存 drum (= BD / SD / CYM / HH / TOM) の sequence は Step 17 改修後も literal で不変
- **internal sub-routine entry addr は不変保証対象ではない**: dispatcher 改修 (= bit 5 分岐追加 + bit 4 TOM tail-call → call nz pattern 戻し) で routine 内 bytecode が増加 → 後続 sub-routine (= `_rhythm_event_sd_trigger` / `_rhythm_event_cym_trigger` / `_rhythm_event_hh_trigger` / `_rhythm_event_tom_trigger`、 future `_rhythm_event_rim_trigger`) の entry addr が shift する可能性あり (= Step 16 で literal observed、 Step 17 で再 shift 想定)、 これは正常動作
- verify script 側も sub-routine entry addr literal value を hard-code assert せず、 symbol 存在 + K=R addr identical で proof 成立する設計 (= ADR-0028 / ADR-0029 / ADR-0030 §verify gate Gate 2 / Gate 3 pattern 踏襲)
- PMDDotNET (= C# compile path) は完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 維持)
- `.MN` format は完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う、 ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 維持)
- 既存 L-Q ADPCM-A melody architecture (= ADR-0019 / ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 / ADR-0025 で確立)
- selected pointer runtime state cache 不採用 (= ADR-0024 §決定 6 / ADR-0025 §決定 1 / ADR-0026 §決定 11 / ADR-0027 §決定 1 / ADR-0028 §決定 1 / ADR-0029 §決定 1 / ADR-0030 §決定 1 維持)
- `sample_table_id` resolver / selector の ABI (= Step 9-11 で確立)
- sentinel pointer 0x0000 silent semantics
- driver SRAM layout (= 0xFD20-0xFD32 既存領域、 Step 17 で新規 marker byte を追加しない)
- multi-table id=0x01 differentiation proof contract (= ADR-0025 全 §決定)
- K/R rhythm event dispatch proof contract (= ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 全 §決定、 §決定 2 「b-only proof」 → 「b + s proof」 → 「b + s + h proof」 → 「b + s + c + h proof」 → 「b + s + c + h + t proof」 → 本 ADR §決定 2 「b + s + c + h + t + i proof = full 6 drum」 に literal 更新、 dispatch path 1 本化不変原則は維持)
- `.PNE` / `.MN` asset pipeline (= ADR-0021 で確立)
- BD fixture (= `k-br-only.mml` / `r-melody-br-only.mml`) 完全不変
- SD fixture (= `k-sr-only.mml` / `r-melody-sr-only.mml`) 完全不変
- CYM fixture (= `k-cr-only.mml` / `r-melody-cr-only.mml`) 完全不変
- HH fixture (= `k-hr-only.mml` / `r-melody-hr-only.mml`) 完全不変
- TOM fixture (= `k-tr-only.mml` / `r-melody-tr-only.mml`) 完全不変
- 既存 29 script regression PASS

#### dispatch path 1 本化の drum 種拡張下での維持 (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 / ADR-0030 §決定 8 の 6 drum 段 literal 実証 = full 6 drum completion)

ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 / ADR-0030 §決定 8 で確立した「dispatch path は drum 種拡張で増やさない」 contract は、 Step 17 で **bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM + bit 5 RIM の 6 drum 状況下で `pmdneo_rhythm_event_trigger` routine entry addr が変化しない** ことで literal 実証される。 K-RIM / R-RIM fixture で PC trace を取得し、 PC hit addr が Step 12 / Step 13 / Step 14 / Step 15 / Step 16 と同一 (= 0x1126) であることを `verify-step17-k-rim-trigger.sh` + `verify-step17-r-rim-trigger.sh` で literal assert する。

Step 17 で routine 内部の implementation は拡張される (= bit 5 分岐追加 + bit 4 TOM tail-call → call nz pattern 戻し + `_rhythm_event_rim_trigger` sub-routine 新規) が、 routine entry / 引数 / 戻り値 ABI は不変。 **full 6 drum completion 後** の future sprint (= simultaneous trigger semantics / table-driven dispatch refactor / `.PNE` rhythm bank migration) でも同じ entry addr を保持することを Step 17 で literal 保証する (= 6 drum 段から先の dispatch path 不変保証の milestone)。

### 決定 2: drum 種拡張 = bit 5 RIM 単独 accept (= ADR-0030 §決定 2 b+s+c+h+t proof を b+s+c+h+t+i proof に literal 更新 = **full 6 drum completion**、 bit 6-7 reserved 維持)

K part 文法 subset (= 軸 1 採用):

- K letter = `K` 維持 (= PMD V4.8s 互換、 ADR-0026 §決定 5 / ADR-0027 §決定 2 / ADR-0028 §決定 2 / ADR-0029 §決定 2 / ADR-0030 §決定 2 維持)
- drum 識別文字 = **`b` = BD + `s` = SD + `c` = CYM + `h` = HH + `t` = TOM + `i` = RIM の 6 種** で proof = **full PMD rhythm drum set** (= ADR-0030 §決定 2 の「b + s + c + h + t」 を「b + s + c + h + t + i」 に literal 拡張、 残り 0 種 = drum 種拡張完了)
- 残り drum 種なし (= b/s/c/h/t/i 全 6 種 implementation、 = full 6 drum completion、 future drum 種拡張軸は終了 = simultaneous trigger / table-driven refactor / channel allocation 軸が future)
- K syntax 自体は PMD 互換 (= 既存 K part syntax を維持)
- `\i` ≠ `\r` (= `\i` = RIM trigger、 `\r` = rest 専用、 mc.cs `rimset` 経由、 ADR-0027 §Annex A-1 / memory `project_pmd_rim_drum_char_correction` literal 整合、 本 ADR §Annex A-1 で literal 確認)

#### bitmap accept range = full 6 drum

driver `.MN` direct parser での `0xEB <bitmap>` 受入:

- **bit 0 = 1** (= 0x01): BD trigger (= 既存 ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 維持)
- **bit 1 = 1** (= 0x02): SD trigger (= 既存 ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 維持)
- **bit 2 = 1** (= 0x04): CYM trigger (= `\c`、 既存 ADR-0029 / ADR-0030 維持)
- **bit 3 = 1** (= 0x08): HH trigger (= 既存 ADR-0028 / ADR-0029 / ADR-0030 維持)
- **bit 4 = 1** (= 0x10): TOM trigger (= `\t`、 mc.cs `tamset` 経由、 既存 ADR-0030 維持、 Step 17 で tail-call → call nz pattern 戻し)
- **bit 5 = 1** (= 0x20): RIM trigger (= `\i`、 `\r` ではない、 mc.cs `rimset` 経由) → **本 ADR で新規追加 accept、 new tail-call target = full 6 drum completion**
- **bit 6-7**: reserved (= PMD bitmap 範囲外、 silent ignore)
- **bitmap = 0x00**: no-op
- **bitmap = 0x03 / 0x05 / 0x06 / 0x07 / ... / 0x21 / 0x22 / 0x23 / ... / 0x3F 等** (= simultaneous trigger combo): bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4)、 動作は α 調査で literal 確認 + 結果 Annex A 反映、 Step 17 fixture では生成しない、 combo bitmap が driver 上で動く可能性と仕様化は別軸 (= ADR 内で「未定義」 明記)

#### 採用根拠

- ADR-0030 b+s+c+h+t proof と同じ proof 最小性
- dispatch path 1 本化が 6 drum 状況下で literal 維持されることの proof は 1 軸拡張で十分
- 残 0 drum (= drum 種拡張完了) で full 6 drum set 完成 → 次は simultaneous trigger / table-driven refactor / .PNE migration 等の別軸 sprint
- BD/SD/CYM/HH/TOM/RIM は PMD V4.8s K part 文法的に full drum set
- RIM sample (= rim-shot) は ADR-0025 step5b で ADPCM-A subsystem 内に既に embed 済 (= sample source 取得コスト 0)
- PMD V4.8s manual L228 `\br\tr\tr\tr` は TOM 直接使用例で RIM 直接用例は manual 内に literal 用例なし (= mc.cs rcomtbl L9533 のみが ground truth、 本 ADR §Annex A-4)

#### ADR / handoff 記載 contract

- Step 17 では drum kind = **b + s + c + h + t + i = full 6 drum**
- drum 種拡張軸は **完了** (= 残り drum 種なし)
- bit 6-7 は **silent ignore** (= 未対応 cmd スルー思想踏襲、 PMD bitmap 範囲外)
- dispatch path は drum 種拡張で **増やさない** (= 決定 8 と整合、 6 drum 段で literal 実装保証)
- **full 6 drum completion = Step 12-17 6-step drum 種漸進拡張 sprint chain の完成 milestone**

### 決定 3: RIM sample source = existing `adpcma_sample_rim` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 + ADR-0028 §決定 3 HH = 既存再利用 + ADR-0029 §決定 3 CYM = 既存再利用 + ADR-0030 §決定 3 TOM = 既存再利用 pattern 踏襲、 melody sample symbol と現段階で共有、 「rim」 = sample provenance 名と PMD semantics 名の完全一致、 alias 新設なし、 final rhythm sample ownership 未確定)

RIM trigger で使う sample (= 軸 1 / (rim_s1) 採用):

#### Step 17 proof 段階 = full 6 drum

- bit 0 BD → `adpcma_sample_bd` pointer (= 既存 Step 12 維持)
- bit 1 SD → `adpcma_sample_sd` pointer (= 既存 Step 13 維持)
- bit 2 CYM → `adpcma_sample_top` pointer (= 既存 Step 15 維持)
- bit 3 HH → `adpcma_sample_hh` pointer (= 既存 Step 14 維持)
- bit 4 TOM → `adpcma_sample_tom` pointer (= 既存 Step 16 維持)
- bit 5 RIM → `adpcma_sample_rim` pointer (= 本 ADR で新規 mapping 追加、 既存 symbol reuse)
- sample header / addr 値は driver source / `samples.inc` 内に literal 配置 (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 ADR-0025 step5b で既に RIM rim-shot ADPCM-A subsystem 内に embed 済)
- 新規 sample embed なし (= 既存資産再利用のみ)
- 新規 alias symbol 追加なし (= sample provenance 名と PMD semantics 名が完全一致で alias 不要)
- `.PNE` / `.MN` asset pipeline / `pne_sample_directory` / `sample_table_id` resolver / `pmdneo_select_sample_pointer` は完全不変
- L-Q melody sample / rhythm BD/SD/CYM/HH/TOM/RIM sample は driver source 内で **symbol 共有** (= L-Q melody P ch と `adpcma_sample_rim` symbol を share、 ただし read タイミング軸で collision しない)

#### 「rim」 wording の一致 (= ADR-0030 「tom」 = TOM 同型、 ADR-0029 「top」 vs「CYM」 wording 分離 pattern と違う)

ADR-0030 では `adpcma_sample_tom` 自体が「tom」 名で、 PMD semantics 名 (= `\t` = TOM = tom-tom) と完全一致するため wording 分離不要だった。 ADR-0031 でも `adpcma_sample_rim` 自体が「rim」 名で、 PMD semantics 名 (= `\i` = RIM = rim-shot) と完全一致するため:

- **「rim」**: sample provenance 名 (= asset 由来 = `assets/sounds/adpcma/2608_RIM.adpcma`、 L-Q melody architecture P ch sample symbol = `adpcma_sample_rim`、 ADR-0025 step5b で ADPCM-A subsystem 内に embed 済)
- **「RIM」**: PMD semantics 名 (= PMD MML 記号 `\i`、 PMD V4.8s `rimset` handler、 bitmap bit 5 = 0x20、 mc.cs rcomtbl L9533 literal `'i' → rimset` 確認済)
- 両者が完全一致 → driver source 内 `adpcma_sample_rim` symbol を「RIM bit 5 → RIM rim-shot sample」 mapping として使用、 wording 分離不要
- 新規 alias symbol 追加なし → driver 差分最小化
- 「PMD rhythm の RIM は rim-shot 相当として扱うのが自然」 (= PMD/OPN rhythm 慣習) という user judgement と完全 align

#### 用語対応表 (= ADR-0030 §決定 3 「用語対応表」 pattern 踏襲、 PMDDotNET 側 ground truth 引用と PMDNEO 側 wording 統一の境界固定)

PMDDotNET 側 source 上の handler 名 (= `rimset`、 RIM semantics と一致) と PMDNEO 側 wording (= RIM 統一) の境界を future contributor 向けに literal 固定する:

| layer | 識別子 | 出典 / 用途 |
|---|---|---|
| PMD rhythm semantics | `\i` = RIM | mc.cs rcomtbl L9533 literal、 PMDDotNET `\i` MML 記号、 `\r` は rest 専用で混同しない |
| PMDDotNET implementation | `i` → `rimset` | mc.cs L9533 = `('i', rimset)` literal、 mc.cs L9721 = `rimset → work.al = 32` literal (= ground truth、 RIM semantics と handler 名が実質一致でこちらは ADR-0030 `tamset` のような legacy naming はなし) |
| bitmap | bit 5 = 0x20 | mc.cs L9721 + driver `.MN` direct parser bitmap accept range |
| PMDNEO sample symbol | `adpcma_sample_rim` | standalone_test.s L2899-2900 既存 embed (= L-Q architecture P ch 共有) |
| PMDNEO fixture naming | `k-ir-only.mml` / `r-melody-ir-only.mml` | ir = `\i` + `r`(rest) fixture pattern |
| PMDNEO verify naming | `rim` (= drum semantics 名) | verify-step17-k-rim-trigger.sh / verify-step17-r-rim-trigger.sh / verify-step17-kr-rim-byte-identical.sh / verify-step17-bd-vs-rim-differential.sh / verify-step17-tom-vs-rim-differential.sh |

**境界規律 (= ADR-0030 用語対応表 pattern 踏襲、 本 ADR + handoff doc + memory + future commit message で統一適用)**:

- **PMDDotNET 内部名 `rimset` と PMDNEO 側 wording RIM は実質一致** (= ADR-0030 `tamset` (TAM legacy) vs TOM のような wording 分離はなく、 rimset = RIM そのまま使える)
- PMDDotNET 側 source 引用時は `rimset` を使用 (= mc.cs literal 引用、 ground truth 記録目的、 ADR §Annex A-1 / A-2)
- PMDNEO 側 wording = **RIM 統一** (= driver source / ADR §決定 / fixture filename / verify script / handoff doc / memory / commit message 全てで RIM 表記)
- future contributor が PMDDotNET source を読んだ際に「`rimset` = RIM」 として直接 mapping できる (= ADR / handoff doc / memory に統一表記、 ADR-0029 「top vs CYM」 wording 分離 pattern + ADR-0030 「tamset vs TOM」 legacy naming pattern と違い、 本 ADR では「rimset = RIM」 完全一致 + 用語負債なし)
- `\r = RIM` は **誤り** (= `\r` は rest 専用、 ADR-0027 §Annex A-1 で literal 訂正済、 memory `project_pmd_rim_drum_char_correction` 整合)

#### symbol sharing と semantics separation の現段階整理

- melody architecture (= ADR-0019 で確立した L-Q 6 ch ADPCM-A native runtime): P ch (= P part) の sample として `adpcma_sample_rim` を参照
- rhythm proof (= 本 ADR + ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030): L ch (= rhythm event trigger 経由) の sample として `adpcma_sample_rim` を参照
- 両者は **同 symbol を share** するが **異なる ADPCM-A ch slot に書き込まれる** (= melody P ch slot vs rhythm L ch slot、 register bank 軸で分離)
- final rhythm sample ownership は **未確定** (= future `.PNE` rhythm bank migration で rhythm-dedicated sample bank に移行する可能性あり、 ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 / ADR-0030 §決定 3 future migration path 継続)

#### future migration path (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 / ADR-0030 §決定 3 継続、 literal 残置)

将来的に OPNA rhythm 相当 sample set を `.PNE` 側へ寄せる可能性が高い (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 / ADR-0030 §決定 3 と同一)。 候補 path:

- `.PNE` rhythm bank entry を新設 (= `sample_table_id` id=0x02 を rhythm bank として確保、 directory entry 拡張)
- generated rhythm sample directory (= D3 migration の一部として rhythm sample を含める)
- driver の `pmdneo_rhythm_event_trigger` routine が `.PNE` rhythm bank entry を引くように変更
- rhythm-dedicated sample symbol 分離 (= `adpcma_sample_bd_rhythm` / `adpcma_sample_sd_rhythm` / `adpcma_sample_cym_rhythm` / `adpcma_sample_hh_rhythm` / `adpcma_sample_tom_rhythm` / `adpcma_sample_rim_rhythm` 等、 melody architecture sample symbol と分離)

ただし上記は **Step 17 scope-out**、 future sprint で必要なら別途検討。 **full 6 drum completion 後の最有力 future candidate**。

#### ADR / handoff 記載 contract

- RIM sample = **existing `adpcma_sample_rim` symbol reuse as driver-embedded proof fixture**
- 新規 sample embed = **scope-out**
- 新規 alias symbol 追加 = **scope-out** (= sample provenance 名と PMD semantics 名が完全一致で alias 不要)
- rhythm-dedicated symbol 分離 = **scope-out** (= ADR-0027 SD pattern / ADR-0028 HH pattern / ADR-0029 CYM pattern / ADR-0030 TOM pattern との consistency 維持)
- driver-embedded rhythm fixture は **proof 用** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 / ADR-0030 §決定 3 維持)
- `.PNE` migration は **future sprint** (= full 6 drum completion 後の最有力 candidate)
- Step 17 は **drum kind expansion proof = full 6 drum completion**、 sample source proof / symbol separation proof ではない
- melody sample symbol と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

### 決定 4: dispatch path 1 本化不変 (= `pmdneo_rhythm_event_trigger` routine entry addr 不変、 routine 内部の bit 5 分岐は最後の active bit として tail-call 末尾に挿入するが ABI 不変)

K と R の dispatch path (= ADR-0026 §決定 6 / ADR-0027 §決定 4 / ADR-0028 §決定 4 / ADR-0029 §決定 4 / ADR-0030 §決定 4 維持 + Step 17 で 6 drum 段の literal 維持 = full 6 drum completion):

#### routine entry 不変

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は Step 12 / Step 13 / Step 14 / Step 15 / Step 16 から不変
- K-RIM / R-RIM fixture でも PC trace hit addr は 0x1126 (= 既存 Step 12 K-BD / R-BD + Step 13 K-SD / R-SD + Step 14 K-HH / R-HH + Step 15 K-CYM / R-CYM + Step 16 K-TOM / R-TOM と同一)
- routine 引数 / 戻り値 ABI 不変
- `.MN` direct parser からの caller 接続不変

#### routine 内部の bit 5 分岐挿入位置 = 最後の active bit として tail-call 末尾 (= PMD bitmap bit 順序維持 = full 6 drum)

routine 内部の implementation は拡張される:

- 既存 (Step 12): bit 0 = 1 → BD trigger (= `adpcma_sample_bd` register write、 call nz pattern)
- 既存 (Step 13): bit 1 = 1 → SD trigger (= `adpcma_sample_sd` register write、 call nz pattern)
- 既存 (Step 15): bit 2 = 1 → CYM trigger (= `adpcma_sample_top` register write、 call nz pattern)
- 既存 (Step 14 = ADR-0030 で call nz pattern 戻し済): bit 3 = 1 → HH trigger (= `adpcma_sample_hh` register write、 call nz pattern)
- 変更 (Step 16 → Step 17): bit 4 = 1 → TOM trigger (= `adpcma_sample_tom` register write、 ADR-0030 まで tail-call pattern → **本 ADR で call nz pattern に戻し**)
- 新規 (Step 17): bit 5 = 1 → RIM trigger (= `adpcma_sample_rim` register write、 末尾に挿入、 **new tail-call pattern target = full 6 drum completion**)
- bit 6-7: reserved (= no register write、 PMD bitmap 範囲外)
- bitmap = 0x00: no-op

#### branch 実装流儀 (= explicit if/jr/jp、 ADR-0024 / 0025 / 0026 / 0027 / 0028 / 0029 / 0030 §決定 4 流儀踏襲)

bit 0 / bit 1 / bit 2 / bit 3 / bit 4 / bit 5 の分岐は **explicit if/jr/jp** で記述 (= jump table / dispatch macro は使わない、 distance に応じて jr または jp を選択する Z80 標準対応)。 ADR-0030 で確立した「最後の active bit = tail-call (jp)」 invariant を Step 17 で bit 5 RIM に移動 (= bit 4 TOM は call nz pattern に戻し、 dispatch macro/jump table を使わない explicit branch 精神は完全維持):

```asm
pmdneo_rhythm_event_trigger::
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 2 = CYM / bit 3 = HH / bit 4 = TOM / bit 5 = RIM / bit 6-7 = reserved
    push    af
    bit     0, a
    call    nz, _rhythm_event_bd_trigger
    pop     af
    push    af
    bit     1, a
    call    nz, _rhythm_event_sd_trigger
    pop     af
    push    af
    bit     2, a
    call    nz, _rhythm_event_cym_trigger
    pop     af
    push    af
    bit     3, a
    call    nz, _rhythm_event_hh_trigger
    pop     af
    push    af                              ; ← Step 17 で追加 (= bit 4 check 用 A 保持、 ADR-0030 では tail-call で push なし)
    bit     4, a
    call    nz, _rhythm_event_tom_trigger   ; ← Step 17 で call nz pattern に戻し (= ADR-0030 までは tail jp pattern)
    pop     af
    bit     5, a
    ret     z                               ; bit 5 不立 → ret (= silent ignore for bit 6-7)
    jp      _rhythm_event_rim_trigger       ; bit 5 RIM tail jump (= Step 17 new tail-call target、 explicit branch 精神維持、 full 6 drum completion)

_rhythm_event_bd_trigger:
    ; adpcma_sample_bd を ADPCM-A L ch に register write (= Step 12 既存、 完全不変)
    ...
    ret

_rhythm_event_sd_trigger:
    ; adpcma_sample_sd を ADPCM-A L ch に register write (= Step 13 既存、 内部完全不変、 entry addr は再 shift 想定)
    ...
    ret

_rhythm_event_cym_trigger:
    ; adpcma_sample_top を ADPCM-A L ch に register write (= Step 15 既存、 内部完全不変、 entry addr は再 shift 想定)
    ...
    ret

_rhythm_event_hh_trigger:
    ; adpcma_sample_hh を ADPCM-A L ch に register write (= Step 14 既存、 内部完全不変、 entry addr は再 shift 想定)
    ...
    ret

_rhythm_event_tom_trigger:
    ; adpcma_sample_tom を ADPCM-A L ch に register write (= Step 16 既存、 内部完全不変、 entry addr は再 shift 想定、 tail-call → call nz pattern 戻しで invariant 内部 sequence は同一 literal)
    ...
    ret

_rhythm_event_rim_trigger:
    ; adpcma_sample_rim を ADPCM-A L ch に register write (= Step 17 新規実装、 full 6 drum completion)
    ld      hl, #adpcma_sample_rim
    ; ... reg 0x10 / 0x18 / 0x20 / 0x28 / 0x08 / 0x00 keyon mask 0x01 write
    ret
```

実装の literal asm は β commit で確定 (= 本 ADR は契約のみ literal 固定、 implementation 詳細は β に委ねる)。

#### ADR / handoff 記載 contract

- `pmdneo_rhythm_event_trigger` routine entry addr = **不変** (= 0x1126) ← **invariant の primary 軸**
- routine ABI = **不変**
- routine 内部の bit 5 分岐は **最後の active bit として tail-call 末尾に挿入 = full 6 drum completion** (= PMD bitmap bit 順序維持、 bit 6-7 reserved 維持)
- bit 4 TOM = ADR-0030 までは tail-call pattern → **本 ADR で call nz pattern に戻し** (= Step 17 で bit 5 RIM が new tail-call target、 「最後の active bit = tail-call」 invariant 維持)
- branch 流儀 = **explicit if/jr/jp** (= ADR-0024 / 0025 / 0026 / 0027 / 0028 / 0029 / 0030 流儀踏襲、 dispatch macro/jump table は使わない explicit branch 精神維持)
- dispatch path は drum 種拡張で **増やさない** (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 / ADR-0030 §決定 8 維持、 本 ADR §決定 8 で 6 drum 段 = full PMD drum set で literal 実装的に保証)
- **internal sub-routine entry addr は不変保証対象ではない** (= ADR-0028 / ADR-0029 / ADR-0030 §決定 8 wording 踏襲、 Step 17 で再 shift 想定 = SD trigger / CYM trigger / HH trigger / TOM trigger の entry addr が dispatcher 改修で再 shift)。 invariant の本質は **shared dispatch entry 不変 + register write sequence 不変** の 2 軸。

### 決定 5: fixture 体制 = BD/SD/CYM/HH/TOM fixture 完全不変 + RIM fixture 2 件新規 (= 12 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM / K-RIM / R-RIM = full 6 drum completion)

K-RIM / R-RIM fixture 取り扱い (= 軸 2 / (fix1) 採用):

#### 既存 BD/SD/CYM/HH/TOM fixture 完全不変

- `compile-test-pmddotnet/k-br-only.mml` (= Step 12 既存)
- `compile-test-pmddotnet/r-melody-br-only.mml` (= Step 12 既存)
- `compile-test-pmddotnet/k-sr-only.mml` (= Step 13 既存)
- `compile-test-pmddotnet/r-melody-sr-only.mml` (= Step 13 既存)
- `compile-test-pmddotnet/k-cr-only.mml` (= Step 15 既存)
- `compile-test-pmddotnet/r-melody-cr-only.mml` (= Step 15 既存)
- `compile-test-pmddotnet/k-hr-only.mml` (= Step 14 既存)
- `compile-test-pmddotnet/r-melody-hr-only.mml` (= Step 14 既存)
- `compile-test-pmddotnet/k-tr-only.mml` (= Step 16 既存)
- `compile-test-pmddotnet/r-melody-tr-only.mml` (= Step 16 既存)

これらは **完全不変** (= byte-identical 維持、 Step 12 / Step 13 / Step 14 / Step 15 / Step 16 K-R differential proof script で継続使用)。

#### 新規 RIM fixture 2 件

- `compile-test-pmddotnet/k-ir-only.mml` (= K part `\i` + `r`(= rest) のみ、 K-BD/K-SD/K-CYM/K-HH/K-TOM fixture と 1 文字違い)
- `compile-test-pmddotnet/r-melody-ir-only.mml` (= melody part L 内 inline `\i` + `r`(= rest)、 R-BD/R-SD/R-CYM/R-HH/R-TOM fixture と 1 文字違い)

#### fixture 命名規則

- `k-ir-only.mml` の `ir` は **`\i` + `r`(= rest) の fixture pattern**
- `ir` は「**RIM」 略ではない** (= 既存 `br` / `sr` / `cr` / `hr` / `tr` も「BD」「SD」「CYM」「HH」「TOM」 略ではなく `\b` + `r` / `\s` + `r` / `\c` + `r` / `\h` + `r` / `\t` + `r` pattern と同一)
- α 調査で PMDDotNET が RIM を `\i` として emit することを literal 確認 (= 本 ADR §Annex A-1 mc.cs rcomtbl L9533 で literal 確認済、 α 着手で `'i' → rimset` 確認 + 本 ADR §Annex A 反映)
- もし α 調査で RIM の MML 記号が `\i` でないと判明した場合は、 fixture 名を **実 bytecode / actual syntax に合わせて修正** (= sub-sprint 内で rename、 β 着手前に確定、 ただし mc.cs L9533 で `\i` 確認済 + memory `project_pmd_rim_drum_char_correction` で `\r ≠ RIM` literal 整合のため本 sprint で rename 発生確率極めて低)

#### 12 fixture 体制 = full 6 drum × K/R 2 系統 completion

| fixture | drum 種 | source 経路 | step12 / step13 / step14 / step15 / step16 / step17 |
|---|---|---|---|
| `k-br-only.mml` | BD | K part | step 12 既存 |
| `r-melody-br-only.mml` | BD | melody part inline | step 12 既存 |
| `k-sr-only.mml` | SD | K part | step 13 既存 |
| `r-melody-sr-only.mml` | SD | melody part inline | step 13 既存 |
| `k-hr-only.mml` | HH | K part | step 14 既存 |
| `r-melody-hr-only.mml` | HH | melody part inline | step 14 既存 |
| `k-cr-only.mml` | CYM | K part | step 15 既存 |
| `r-melody-cr-only.mml` | CYM | melody part inline | step 15 既存 |
| `k-tr-only.mml` | TOM | K part | step 16 既存 |
| `r-melody-tr-only.mml` | TOM | melody part inline | step 16 既存 |
| `k-ir-only.mml` | RIM | K part | step 17 新規 |
| `r-melody-ir-only.mml` | RIM | melody part inline | step 17 新規 |

#### ADR / handoff 記載 contract

- BD/SD/CYM/HH/TOM fixture = **完全不変**
- RIM fixture = **2 件新規追加**
- fixture 命名 pattern = `\i` + `r`(= rest) = `ir` (= 既存 `br` / `sr` / `cr` / `hr` / `tr` pattern 踏襲、 drum 名略ではなく fixture pattern 命名)
- verify token = `rim` (= drum semantics 名、 fixture pattern token と区別)
- α 調査で命名修正可能性極めて低い (= 本 ADR §Annex A-1 で `\i` literal 確認済)
- **`ir` は「RIM」 略ではない** (= future contributor 向け literal 注記)
- **`\r` ≠ RIM** (= `\r` は rest 専用、 ADR-0027 §Annex A-1 / memory `project_pmd_rim_drum_char_correction` literal 整合)

### 決定 6: drum 種 → sample pointer mapping table を 1 軸拡張 = full 6 drum (= bit 0 → BD addr / bit 1 → SD addr / bit 2 → CYM addr / bit 3 → HH addr / bit 4 → TOM addr / bit 5 → RIM addr)

driver source 内 mapping table 構造:

#### Step 16 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 + bit 2 CYM 分岐 + bit 3 HH 分岐 + bit 4 TOM 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_top` / `adpcma_sample_hh` / `adpcma_sample_tom` literal addr 参照
- bit 5 は no-op (= silent ignore)

#### Step 17 段階 = full 6 drum completion

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 + bit 2 CYM 分岐 + bit 3 HH 分岐 + bit 4 TOM 分岐 + bit 5 RIM 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_top` / `adpcma_sample_hh` / `adpcma_sample_tom` / `adpcma_sample_rim` literal addr 参照
- bit 6-7 は no-op (= silent ignore、 PMD bitmap 範囲外)
- mapping table 構造は branch 流儀の延長 (= 別途 table 構造を導入せず、 explicit branch + literal addr 参照のまま、 full 6 drum completion で全 bit が explicit branch で処理)

#### branch 構造で literal addr 参照する根拠 (= 別 table 構造を導入しない理由 = full 6 drum でも explicit branch 維持)

- ADR-0024 / 0025 / 0026 / 0027 / 0028 / 0029 / 0030 で確立した explicit if/jr 流儀踏襲
- 6 drum 程度なら branch 列挙の方が trace gate / register write trace で読みやすい
- 別 mapping table 構造 (= bitmap bit position → sample addr pointer の lookup table) は **full 6 drum completion 後** の future sprint で再評価 (= 判断材料が full set で揃う)
- 早すぎる抽象化を避ける (= CLAUDE.md §「3 行の重複は早すぎる抽象化より良い」 規律)
- table-driven refactor は full drum set 到達後 (= 本 ADR Accepted 後) に判断材料が揃う、 Step 18+ 候補

#### ADR / handoff 記載 contract

- drum 種 → sample pointer mapping = **explicit branch + literal addr 参照** (= full 6 drum 全て explicit branch)
- 別 mapping table 構造 = **scope-out** (= future sprint で再評価、 full drum set 到達後優先 = 本 ADR 後)
- bit 0 → `adpcma_sample_bd` literal addr
- bit 1 → `adpcma_sample_sd` literal addr
- bit 2 → `adpcma_sample_top` literal addr (= 「CYM」 semantics 名 / 「top」 provenance 名)
- bit 3 → `adpcma_sample_hh` literal addr
- bit 4 → `adpcma_sample_tom` literal addr (= 「TOM」 semantics 名と「tom」 provenance 名が完全一致)
- bit 5 → `adpcma_sample_rim` literal addr (= 「RIM」 semantics 名と「rim」 provenance 名が完全一致)

### 決定 7: BD/SD/CYM/HH/TOM fixture 完全不変保証 (= Step 12 K-BD / R-BD path + Step 13 K-SD / R-SD path + Step 14 K-HH / R-HH path + Step 15 K-CYM / R-CYM path + Step 16 K-TOM / R-TOM path regression 維持)

Step 17 で BD/SD/CYM/HH/TOM path を壊していないことを継続確認する規律:

#### regression 維持要件

- Step 12 で確立した K-BD / R-BD path の verify script 4 件 (= `verify-step12-k-rhythm-trigger.sh` / `verify-step12-kr-differential.sh` 等) は **完全不変**
- Step 13 で確立した K-SD / R-SD path の verify script 3 件 (= `verify-step13-sd-trigger.sh` / `verify-step13-kr-sd-differential.sh` / `verify-step13-bd-sd-differential.sh`) は **完全不変**
- Step 14 で確立した K-HH / R-HH path の verify script 3 件 (= `verify-step14-hh-trigger.sh` / `verify-step14-kr-hh-differential.sh` / `verify-step14-bd-hh-differential.sh`) は **完全不変**
- Step 15 で確立した K-CYM / R-CYM path の verify script 3 件 (= `verify-step15-cym-trigger.sh` / `verify-step15-kr-cym-differential.sh` / `verify-step15-bd-cym-differential.sh`) は **完全不変**
- Step 16 で確立した K-TOM / R-TOM path の verify script 3 件 (= `verify-step16-tom-trigger.sh` / `verify-step16-kr-tom-differential.sh` / `verify-step16-bd-tom-differential.sh`) は **完全不変**
- Step 12 / Step 13 / Step 14 / Step 15 / Step 16 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM / K-TOM / R-TOM fixture file は **byte-identical** 維持
- Step 12 BD register write trace + Step 13 SD register write trace + Step 14 HH register write trace + Step 15 CYM register write trace + Step 16 TOM register write trace は **同 sequence 維持**
- Step 17 commit chain (= α/β/γ/δ) の各 commit で全 step12 + step13 + step14 + step15 + step16 path verify script PASS が確認できる

#### ADR / handoff 記載 contract

- BD path **regression 維持**
- SD path **regression 維持**
- CYM path **regression 維持**
- HH path **regression 維持**
- TOM path **regression 維持**
- Step 12 / Step 13 / Step 14 / Step 15 / Step 16 fixture / verify script 完全不変
- Step 17 各 commit で BD/SD/CYM/HH/TOM path verify が **PASS 確認できる**
- 「動いているものを壊さない」 規律遵守 (= Step 5/6/7/8/9/10/11/12/13/14/15/16 で確立)

### 決定 8: dispatch path は drum 種拡張で増やさない (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 / ADR-0030 §決定 8 維持、 Step 17 で 6 drum 段 = full PMD drum set literal 実装保証)

ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 / ADR-0030 §決定 8 で確立した contract:

> dispatch path は drum 種拡張で増やさない

を Step 17 で **6 drum 段 = full PMD drum set で literal 実装的に保証** する:

#### 実装的保証 内容

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は不変
- K-RIM / R-RIM fixture で PC trace hit addr が Step 12 K-BD / R-BD + Step 13 K-SD / R-SD + Step 14 K-HH / R-HH + Step 15 K-CYM / R-CYM + Step 16 K-TOM / R-TOM と同一 (= 0x1126)
- routine ABI 不変
- routine 内部の bit 5 分岐追加 + bit 4 TOM tail-call → call nz pattern 戻し + `_rhythm_event_rim_trigger` sub-routine 新規は **routine 内部の implementation 拡張** であって dispatch path の新設ではない
- drum 種 → sample addr mapping は routine 内部の literal branch で吸収

#### full 6 drum completion で確立される milestone

- routine entry addr 不変 (= 0x1126) を **6 drum 段で literal 実装保証**
- routine ABI 不変
- 新規 dispatch routine を追加していない (= routine 内部の bit position 分岐 + sub-routine のみ追加)
- **drum 種拡張軸が完了** (= 残り drum 種なし、 PMD V4.8s rcomtbl 6 種全部 implementation)
- 別 mapping table 構造への refactor を再評価する判断材料が full set で揃う (= Step 18+ 候補、 table-driven dispatch refactor sprint 起票可能)

#### ADR / handoff 記載 contract

- dispatch path = **1 本化維持** (= shared dispatch entry @ 0x1126、 full 6 drum 段で literal 保証)
- routine entry addr / ABI = **不変** (= invariant primary 軸、 6 drum 完成後も不変)
- drum 種拡張は **routine 内部 implementation 拡張 (= bit 分岐 + sub-routine 追加) で吸収**
- **internal sub-routine entry addr は不変保証対象ではない** (= ADR-0028 / ADR-0029 / ADR-0030 §決定 8 wording 踏襲、 Step 17 で再 shift 想定 = SD trigger / CYM trigger / HH trigger / TOM trigger の entry addr が dispatcher 改修で再 shift、 + TOM trigger は tail-call → call nz pattern 変更で内部 sequence は同一 literal だが entry addr literal shift)
- **invariant の本質** = shared dispatch entry 不変 + register write sequence 不変 の 2 軸 (= sub-routine entry addr は secondary observation、 verify script 側も literal value hard-code 不在)
- table-driven refactor = **future sprint** (= full drum set = 6 drum 段到達後の最有力 candidate、 Step 18+ table-driven dispatch refactor sprint)

### 決定 9: observability marker = `pmdneo_rhythm_event_trigger` PC hit 継続 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 / ADR-0029 §決定 9 / ADR-0030 §決定 9 維持、 SRAM layout 不変)

Step 17 での observability marker 軸 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 / ADR-0029 §決定 9 / ADR-0030 §決定 9 維持):

- rhythm event observability marker = **routine PC hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126)
- memory marker byte は **持たない** (= SRAM 増設なし)
- SRAM layout は Step 17 でも **増やさない** (= 0xFD20-0xFD32 既存領域維持)
- PC trace + ymfm-trace の **二段 gate** で K-RIM / R-RIM proof
- K-RIM / R-RIM source path は別でも runtime dispatch routine は同一 (= 同 0x1126 PC hit)

#### ADR / handoff 記載 contract

- observability marker = **routine PC hit (= 0x1126)**
- memory marker byte 追加 = **scope-out**
- SRAM layout 不変
- PC trace + ymfm-trace 二段 gate 継続

### 決定 10: PMDDotNET / `.MN` format 完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 維持)

Step 17 での PMDDotNET / `.MN` format 軸:

- PMDDotNET (= C# compile path) 完全不変
- `.MN` format 完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う)
- 新規 `.MN` bytecode 追加なし
- driver `.MN` direct parser での normalize は ADR-0026 で確立した `0xEB <bitmap>` 受入を維持、 bitmap accept range のみ bit 0 + bit 1 + bit 2 + bit 3 + bit 4 → bit 0 + bit 1 + bit 2 + bit 3 + bit 4 + bit 5 に拡張 = **full 6 drum**

#### ADR / handoff 記載 contract

- PMDDotNET-side normalize は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 維持)
- new `.MN` rhythm event bytecode 追加は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 維持)
- driver `.MN` direct parser での bitmap accept range 拡張のみ (= bit 0-4 → bit 0-5 = full 6 drum)

### 決定 11: simultaneous trigger scope-out + bitmap OR semantics future investigation (= future 候補温存、 Annex A 軽く触れる、 driver 上での動作可能性と仕様化を区別)

simultaneous trigger semantics 対応 (= 軸 4 / scope-out 採用):

#### Step 17 scope-out

- BD+RIM / SD+RIM / CYM+RIM / HH+RIM / TOM+RIM / BD+SD+RIM / BD+CYM+RIM / BD+HH+RIM / BD+TOM+RIM / SD+CYM+RIM / SD+HH+RIM / SD+TOM+RIM / CYM+HH+RIM / CYM+TOM+RIM / HH+TOM+RIM / 3+ combo RIM 込み 同時打ち + 全 6 drum 同時打ち = 0x3F (= bitmap = 0x21 / 0x22 / 0x24 / 0x28 / 0x30 / 0x23 / 0x25 / 0x29 / 0x31 / 0x26 / 0x2A / 0x32 / 0x2C / 0x34 / 0x38 / 0x3F 等) の literal proof は **Step 17 scope-out**
- Step 17 fixture は **BD 単独 / SD 単独 / CYM 単独 / HH 単独 / TOM 単独 / RIM 単独 のみ** (= K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM / K-RIM / R-RIM 12 件、 simultaneous combo 並記 fixture なし)
- driver の bitmap accept range は bit 0 + bit 1 + bit 2 + bit 3 + bit 4 + bit 5 個別 accept (= 各 bit=1 single、 simultaneous combo は α 調査で literal 動作確認のみ、 fixture proof scope-out)

#### driver 動作可能性と仕様化の区別

- 現 driver は bit ごとに独立判定 (= bit 0 → BD trigger / bit 1 → SD trigger / bit 2 → CYM trigger / bit 3 → HH trigger / bit 4 → TOM trigger / bit 5 → RIM trigger)、 各 bit 立で対応 sub-routine が call される
- bitmap = 0x21 (= BD+RIM) が来ると BD sub-routine + RIM sub-routine が連続 call される (= driver 動作上 harmful なし)
- ただし **仕様としては未定義** = Step 17 ADR scope では「driver 動作可能性」 と「仕様化」 を区別、 combo bitmap の semantics (= 同時打ちの結果としての register write 順序 / volume / pan / keyon mask) は ADR 内で literal 規定しない
- combo bitmap が driver 上で動く事実と、 ADR で仕様として規定する事実は別軸 (= future = simultaneous trigger semantics proof sprint で 1 軸だけ定義化予定、 = full 6 drum completion 後の最有力 candidate sprint)

#### bitmap OR semantics future investigation

- PMDDotNET が同 K part 行 `\b\i` / `\s\i` / `\c\i` / `\h\i` / `\t\i` / `\b\s\i` / `\b\c\i` 等の連続記述で **bitmap OR (= bit position OR 結合)** を emit するか、 **複数の `0xEB` + 各 bitmap byte** を emit するかは α 調査範囲 (= ADR-0027 §Annex A-3 / ADR-0028 §Annex A-3 / ADR-0029 §Annex A-3 / ADR-0030 §Annex A-3 で bitmap OR 圧縮 emit literal 確認済、 同 pattern で 6 drum combo 想定)
- α 調査結果を Annex A に literal 反映
- future sprint 候補 (= simultaneous trigger semantics literal proof sprint) として温存 = full 6 drum completion 後の最有力 candidate

#### ADR / handoff 記載 contract

- simultaneous trigger = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 18+ 候補、 full 6 drum completion 後の最有力 candidate)
- Step 17 fixture は **BD 単独 / SD 単独 / CYM 単独 / HH 単独 / TOM 単独 / RIM 単独 のみ**
- combo bitmap は **driver 上で動く可能性あり / ADR 内では「未定義」 と明記**
- α 調査で PMDDotNET の bitmap OR emit 動作を literal 確認 + Annex A 反映 (= ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 で BD+SD / HH 込み / CYM 込み / TOM 込み確認済、 本 ADR で RIM 込み combo の追加確認)

## scope-in / scope-out

### scope-in (= Step 17 で literal 実装する範囲)

1. driver `pmdneo_rhythm_event_trigger` routine に bit 5 分岐追加 (= RIM trigger、 最後の active bit として tail-call 末尾に挿入、 PMD bitmap bit 順序維持、 full 6 drum completion)
2. driver bit 4 TOM 分岐を tail-call pattern → call nz pattern に戻し (= Step 17 で bit 5 RIM が new tail-call target、 「最後の active bit = tail-call」 invariant 維持)
3. driver `_rhythm_event_rim_trigger` sub-routine 新規追加 (= adpcma_sample_rim を L ch register write)
4. RIM sample pointer mapping (= bit 5 → `adpcma_sample_rim` literal addr、 既存 symbol reuse、 alias 新設なし)
5. `k-ir-only.mml` fixture 新規追加
6. `r-melody-ir-only.mml` fixture 新規追加
7. `verify-step17-k-rim-trigger.sh` 新規追加 (= K-RIM register write trace + keyon count + PC marker)
8. `verify-step17-r-rim-trigger.sh` 新規追加 (= R-RIM register write trace + keyon count + PC marker)
9. `verify-step17-kr-rim-byte-identical.sh` 新規追加 (= K-RIM vs R-RIM byte-identical literal proof)
10. `verify-step17-bd-vs-rim-differential.sh` 新規追加 (= BD vs RIM sample addr literal differ proof)
11. `verify-step17-tom-vs-rim-differential.sh` 新規追加 (= TOM vs RIM sample addr literal differ proof、 Step 16 新参 TOM と Step 17 新参 RIM の前後関係 explicit verify)
12. `scripts/listen-step17.sh` 新規追加 (= 12 wav + sleep 3 + 無限繰り返し + Ctrl+C 停止、 audio gate helper)
13. PMDDotNET RIM emit literal 確認 (= mc.cs rimset / rs00 周辺、 本 ADR §Annex A-1 で literal 確認済を再引用、 α 着手で再確認)
14. PMDDotNET RIM 込み bitmap OR emit 動作確認 (= 同 K part 行 `\b\i` / `\s\i` / `\c\i` / `\h\i` / `\t\i` / `\b\s\i` 等連続記述時の emit byte 列、 Annex A literal 反映)
15. ADR-0031 Annex A 反映 (= α 調査結果)
16. ADR-0031 Accepted 移行 (= δ で実施)
17. handoff doc 起票 (= δ で実施)
18. memory `project_pmdneo_step17_complete` 起票 (= δ で実施、 full 6 drum completion milestone 明記)
19. MEMORY.md index 更新 (= δ で実施)

### scope-out (= Step 17 で literal 触らない範囲)

#### Step 17 固有 scope-out (= 7 項目)

1. BD+RIM / SD+RIM / CYM+RIM / HH+RIM / TOM+RIM / 3+ combo RIM 込み simultaneous trigger literal proof + 全 6 drum 同時打ち (= bitmap = 0x21 / 0x22 / 0x24 / 0x28 / 0x30 / 0x23 / 0x25 / ... / 0x3F 等 fixture / verify) → Step 18+ 候補
2. drum 種拡張軸の追加 → **drum 種拡張完了** (= full 6 drum、 残り drum 種なし)
3. drum 種 → sample addr mapping table 構造化 (= bitmap bit position → sample pointer の lookup table) → **full 6 drum completion 後の最有力 future candidate** = Step 18+ table-driven dispatch refactor sprint
4. RIM sample provenance 拡張 (= 新規 sample embed / 新規 alias symbol / rhythm-dedicated symbol 分離 / `.PNE` rhythm bank migration) → future
5. table-driven dispatch refactor (= dispatch path + sub-routine を 1 本に集約) → **full 6 drum completion 後の最有力 future candidate** = Step 18+ sprint
6. SD vs RIM / CYM vs RIM / HH vs RIM explicit differential verify script → 推移的 proof 成立で scope-out (= BD-vs-SD + BD-vs-HH + BD-vs-CYM + BD-vs-TOM + BD-vs-RIM から N-1 pair gate で N 軸 mutual differential を推移的に確立)
7. K-RIM vs R-RIM 以外の K/R cross-drum verify (= K-BD vs R-RIM 等) → 推移的 proof 成立で scope-out (= K=R byte-identical per-drum gate で K と R の dispatch path 完全一致が成立)

#### ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 から継続する scope-out (= 29+ 項目維持)

8. OPNA rhythm sound source register (= 0x10-0x18) fake API (= PMDNEO は YM2610(B)、 emulation 方針外、 ADR-0026 §決定 2 / ADR-0028 §scope-out / ADR-0029 §scope-out / ADR-0030 §scope-out 維持)
9. 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation (= channel allocation 最終仕様は future、 ADR-0026 §決定 4 / ADR-0028 §scope-out / ADR-0029 §scope-out / ADR-0030 §scope-out 維持)
10. OPNA native rhythm timing fidelity (= ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 §scope-out 追加項目維持)
11. K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch の 6 件、 silent fallback 継続、 ADR-0026 §決定 11 / ADR-0028 §scope-out / ADR-0029 §scope-out / ADR-0030 §scope-out 維持)
12. PMDDotNET 改造 / `.MN` format new bytecode (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 / 本 ADR §決定 10 維持)
13. selected pointer cache (A2/A3) / mismatch silent flag / D3 generated directory / runtime `.PNE` parser / multi-`.PNE` switching / bank switching (= ADR-0025 §scope-out 継続)
14. `.PPC` / `.P86` / ADPCM-B subsystem 起票 (= 別 subsystem、 `project_pmdneo_adpcma_subsystem_boundary` 維持)
15. `.PNE` rhythm bank migration (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 / ADR-0030 §決定 3 future migration path 継続、 ADPCM-A subsystem 内だが Step 17 scope-out、 **full 6 drum completion 後の最有力 future candidate**)
16. driver-embedded fixture 以外の sample provenance (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 / ADR-0030 §決定 3 維持)
17. multi-table cache / runtime parser (= ADR-0025 / ADR-0026 §決定 11 / ADR-0028 §scope-out / ADR-0029 §scope-out / ADR-0030 §scope-out 継続)
18. new bytecode (= ADR-0026 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 / 本 ADR §決定 10 維持)
19. PMDDotNET 改造 (= ADR-0026 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / ADR-0030 §決定 10 / 本 ADR §決定 10 維持)
20. observability marker 拡張 (= memory marker byte / SRAM 増設、 ADR-0026 §決定 8 / ADR-0028 §決定 9 / ADR-0029 §決定 9 / ADR-0030 §決定 9 / 本 ADR §決定 9 維持)
21. K letter 以外の rhythm part letter (= ADR-0026 §決定 5 / ADR-0028 §scope-out / ADR-0029 §scope-out / ADR-0030 §scope-out 維持)
22. PMDNEO 独自 drum 識別文字 (= PMD 互換維持、 ADR-0026 §決定 5 / ADR-0028 §scope-out / ADR-0029 §scope-out / ADR-0030 §scope-out 維持)
23. velocity / volume / pan / loop / pattern 軸拡張 (= ADR-0026 §決定 1 / ADR-0028 §決定 2 / ADR-0029 §決定 2 / ADR-0030 §決定 2 / 本 ADR §決定 2 b+s+c+h+t+i proof minimum 範囲限定)
24. K part / R command 以外の rhythm 系 cmd (= ADR-0026 §決定 11 / ADR-0028 §scope-out / ADR-0029 §scope-out / ADR-0030 §scope-out 維持)
25. ADPCM-B subsystem への rhythm extension (= `project_pmdneo_adpcma_subsystem_boundary` 維持、 別 subsystem)
26. WebApp UI 関連 (= Phase 4 範囲、 別 sprint)
27. WAV import / 新規 sample 追加 UI (= Phase 4 範囲)
28. AES+ 実機検証 (= 別 sprint、 verify は MAME headless 経由継続)
29. fmgen 比較 (= 別 sprint)
30. PMDNEO.s + nullsound integration (= `project_pmdneo_driver_two_paths_discovery` 維持、 別 path)

## verify gate

### 5 段 gate (= ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 §verify gate 形式踏襲)

#### Gate 1: build PASS

- α: 全 29 既存 script regression PASS (= step12 系 + step13 系 + step14 系 + step15 系 + step16 系 + step5-11 系)
- β: 全 29 既存 + step17 k-rim-trigger 新規 = 29+1 = 30 script PASS
- γ: 全 29 既存 + step17 k-rim-trigger + step17 r-rim-trigger + step17 kr-rim-byte-identical + step17 bd-vs-rim-differential + step17 tom-vs-rim-differential = 29+5 = 34 script PASS
- δ: 全 34 script 最終 regression PASS

#### Gate 2: K-RIM trigger 単独 verify

`verify-step17-k-rim-trigger.sh` PASS 内容:

1. `k-ir-only.mml` build → `.MN` byte literal 確認 (= `0xEB 0x20 0x80` 期待 or PMDDotNET 実 emit byte literal、 α 調査結果で確定、 本 ADR §Annex A 推定で bitmap 0x20)
2. ymfm-trace で ADPCM-A L ch RIM register write 確認 (= reg 0x10 sample addr literal = `adpcma_sample_rim` start addr 等)
3. PC trace で `pmdneo_rhythm_event_trigger` @ 0x1126 hit 確認
4. keyon count = 1 (= L ch keyon mask 0x01 trigger 1 件)
5. K-RIM fixture で同 sequence PASS

#### Gate 3: R-RIM trigger 単独 verify

`verify-step17-r-rim-trigger.sh` PASS 内容:

1. `r-melody-ir-only.mml` build → `.MN` byte literal 確認 (= `0xEB 0x20` 期待、 melody part L 内 inline 経由)
2. ymfm-trace で ADPCM-A L ch RIM register write 確認 (= reg 0x10 sample addr literal = `adpcma_sample_rim` start addr 等)
3. PC trace で `pmdneo_rhythm_event_trigger` @ 0x1126 hit 確認
4. keyon count = 1 (= L ch keyon mask 0x01 trigger 1 件)
5. R-RIM fixture で同 sequence PASS
6. K-RIM trigger と同 register write sequence (= Gate 4 byte-identical で literal proof)

#### Gate 4: K-RIM vs R-RIM byte-identical proof

`verify-step17-kr-rim-byte-identical.sh` PASS 内容:

1. K-RIM fixture (= `k-ir-only.mml`) と R-RIM fixture (= `r-melody-ir-only.mml`) で ADPCM-A L ch register write sequence **byte-identical** literal proof
2. PC trace hit addr 同一 (= 両方 0x1126)
3. keyon count 同一 (= 両方 1 件)
4. dispatch path 1 本化が drum 種拡張 (= 6 drum 状況) 下でも literal 維持されることの proof = **full 6 drum completion で literal 保証**

#### Gate 5: BD vs RIM differential proof

`verify-step17-bd-vs-rim-differential.sh` PASS 内容:

1. K-BD fixture (= `k-br-only.mml`) と K-RIM fixture (= `k-ir-only.mml`) で:
   - reg 0x10 sample start addr **literal differ** (= `adpcma_sample_bd` start addr ≠ `adpcma_sample_rim` start addr)
   - reg 0x18 sample end addr **literal differ**
   - reg 0x20 / reg 0x28 は **literal differ または identical** (= 同 L ch、 stop addr が drum 種ごと literal 異なれば differ、 fixture pattern によっては identical)
   - reg 0x08 vol|pan / reg 0x00 keyon mask は **identical** (= 同 L ch、 同 fixture pattern)
2. R-BD fixture と R-RIM fixture でも同様の差分 literal proof
3. drum 種 → sample addr mapping が literal 区別されていることの proof (= 6 drum 段で BD vs RIM literal differ)

#### Gate 6: TOM vs RIM differential proof

`verify-step17-tom-vs-rim-differential.sh` PASS 内容:

1. K-TOM fixture (= `k-tr-only.mml`) と K-RIM fixture (= `k-ir-only.mml`) で:
   - reg 0x10 sample start addr **literal differ** (= `adpcma_sample_tom` start addr ≠ `adpcma_sample_rim` start addr)
   - reg 0x18 sample end addr **literal differ**
   - reg 0x20 / reg 0x28 は **literal differ または identical**
   - reg 0x08 vol|pan / reg 0x00 keyon mask は **identical**
2. R-TOM fixture と R-RIM fixture でも同様の差分 literal proof
3. **Step 16 新参 TOM と Step 17 新参 RIM の前後関係 literal proof** (= bit 4 → bit 5 dispatch 順 + tail-call invariant 移動 = bit 4 TOM call nz pattern + bit 5 RIM tail-call jp pattern の literal verify)
4. drum 種 → sample addr mapping が 6 drum 段 (= bit 0 - bit 5 全て) で literal 区別されていることの proof = **full 6 drum completion で literal 保証**

#### SD vs RIM / CYM vs RIM / HH vs RIM 推移的区別 (= ADR-0028 / ADR-0029 / ADR-0030 §verify gate Gate 4 注記 pattern 踏襲、 explicit gate scope-out)

**SD vs RIM / CYM vs RIM / HH vs RIM の sample addr literal differ proof は explicit verify gate を設けない**:

- BD vs SD literal differ = ADR-0027 §verify gate Gate 4 で literal 確立済
- BD vs HH literal differ = ADR-0028 §verify gate Gate 4 で literal 確立済
- BD vs CYM literal differ = ADR-0029 §verify gate Gate 4 で literal 確立済
- BD vs TOM literal differ = ADR-0030 §verify gate Gate 4 で literal 確立済
- BD vs RIM literal differ = 本 ADR §verify gate Gate 5 で literal 確立 (= `verify-step17-bd-vs-rim-differential.sh`)
- TOM vs RIM literal differ = 本 ADR §verify gate Gate 6 で literal 確立 (= `verify-step17-tom-vs-rim-differential.sh`、 Step 16 新参 TOM と Step 17 新参 RIM の前後関係 explicit proof)
- → SD vs RIM / CYM vs RIM / HH vs RIM literal differ は **推移的に proof 成立** (= 6 sample addr literal value が全て異なれば全 pair で literal differ、 explicit gate 不要)
- explicit SD vs RIM / CYM vs RIM / HH vs RIM differential script は scope-out (= 早すぎる verify expansion を避ける、 ADR-0028 / ADR-0029 / ADR-0030 §scope-out pattern 踏襲)
- **drum 種拡張軸が完了** (= 残り drum 種なし)、 future drum 種拡張は発生しない (= future sprint は simultaneous trigger / table-driven refactor / .PNE migration 等)

#### Gate 7: 既存 regression 不破壊

- 既存 29 script regression PASS 維持 (= ADR-0030 完了時の 29 script、 BD path / SD path / CYM path / HH path / TOM path / multi-table / melody / asset pipeline 全て)
- 各 commit (= α/β/γ/δ) で全 step12 + step13 + step14 + step15 + step16 BD/SD/HH/CYM/TOM path verify script PASS が確認できる
- 「動いているものを壊さない」 規律遵守

### audio gate

- ✅ user 試聴 OK 確認 (= 19th session δ で user 試聴、 12 wav file = `/tmp/pmdneo-step12/k-br-only.wav` + `/tmp/pmdneo-step12/r-melody-br-only.wav` + `/tmp/pmdneo-step13/k-sr-only.wav` + `/tmp/pmdneo-step13/r-melody-sr-only.wav` + `/tmp/pmdneo-step14/k-hr-only.wav` + `/tmp/pmdneo-step14/r-melody-hr-only.wav` + `/tmp/pmdneo-step15/k-cr-only.wav` + `/tmp/pmdneo-step15/r-melody-cr-only.wav` + `/tmp/pmdneo-step16/k-tr-only.wav` + `/tmp/pmdneo-step16/r-melody-tr-only.wav` + `/tmp/pmdneo-step17/k-ir-only.wav` + `/tmp/pmdneo-step17/r-melody-ir-only.wav` で確認、 試聴 helper script = `scripts/listen-step17.sh` (= 12 wav + sleep 3 interval + 無限繰り返し + Ctrl+C 停止、 Step 15 / Step 16 convention 踏襲)、 全 wav は γ commit driver state で生成)
- ✅ user judgement: 「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「K-CYM と R-CYM は同一」 「K-TOM と R-TOM は同一」 「K-RIM と R-RIM は同一」 = K/R で同音、 BD vs SD vs HH vs CYM vs TOM vs RIM で違う音色 (= 6 drum 種 = full PMD drum set で聴感的に区別可能)、 FM 同居許容 (= Step 12 / Step 13 / Step 14 / Step 15 / Step 16 audio gate 規律踏襲)
- ✅ BD 単独 / SD 単独 / HH 単独 / CYM 単独 / TOM 単独 / RIM 単独 各 fixture で音が鳴る + BD/SD/HH/CYM/TOM/RIM 6 種で聴感的に区別可能 を user judgement で確認
- ✅ Step 17 audio gate = **OK** 判定 (= 19th session δ user 直接判定 OK)
- ✅ **full 6 drum completion = audio gate でも 6 drum 全て区別可能を確認** (= sprint 完成 milestone の literal verify)

#### audio gate と trace gate の二段 verify

- **trace gate (= register write literal)**: K-RIM と R-RIM で RIM register write byte-identical (= γ commit gate 4) + BD/SD/HH/CYM/TOM/RIM sample addr literal differ (= γ commit gate 5 + gate 6 + 推移的) で literal proof
- **audio gate (= 聴感判定)**: 同 dispatch path を通る K-RIM と R-RIM で耳でも同音、 BD/SD/HH/CYM/TOM/RIM 6 種で耳でも区別可能を user judgement で確認

両 axis で Step 17 contract 達成 = **full 6 drum completion**。

## 完了判定

Step 17 完了判定 (= 10 項目、 19th session δ で **全 10/10 ✅ 達成** = **full 6 drum completion milestone 確定**):

1. ✅ ADR-0031 Accepted 移行 (= δ commit で literal 達成)
2. ✅ `pmdneo_rhythm_event_trigger` routine に bit 5 RIM 分岐追加 (= β commit、 既存 bit 0 / bit 1 / bit 2 / bit 3 / bit 4 分岐の末尾に挿入、 entry addr @ 0x001126 完全不変、 PMD bitmap bit 順序維持、 **full 6 drum completion**)
3. ✅ RIM sample pointer mapping (= bit 5 → `adpcma_sample_rim` 既存 symbol reuse) 実装 (= β commit、 `_rhythm_event_rim_trigger:` 新規 label で literal addr 参照、 既存 L-Q architecture P ch sample symbol を rhythm proof 用に reuse、 ADR-0031 §決定 3 / 軸 1 整合、 alias 新設なし、 「rim」 = sample provenance 名と PMD semantics 名の完全一致)
4. ✅ `k-ir-only.mml` fixture 新規追加 (= K-RIM path、 β commit、 UTF-8 + CRLF、 `ir = \i + r(rest) fixture pattern` 注記)
5. ✅ `r-melody-ir-only.mml` fixture 新規追加 (= R-RIM path、 γ commit、 UTF-8 + CRLF、 `ir = \i + r(rest)` 注記)
6. ✅ `verify-step17-k-rim-trigger.sh` + `verify-step17-r-rim-trigger.sh` 新規追加 + PASS (= β + γ commit、 5 gate PASS、 pmdneo_rhythm_event_trigger @ 0x001126 + `_rhythm_event_rim_trigger` 新規 label literal 確認、 RIM register write literal value PASS)
7. ✅ `verify-step17-kr-rim-byte-identical.sh` 新規追加 + PASS (= γ commit、 K-RIM vs R-RIM RIM register write byte-identical (= 6 件) + K-RIM=R-RIM hook addr identical = 0x001126 + K-RIM=R-RIM rim_trigger addr identical)
8. ✅ `verify-step17-bd-vs-rim-differential.sh` + `verify-step17-tom-vs-rim-differential.sh` 新規追加 + PASS (= γ commit、 BD start/stop LSB ≠ RIM start/stop LSB literal differ + TOM start/stop LSB ≠ RIM start/stop LSB literal differ、 SD vs RIM / CYM vs RIM / HH vs RIM は推移的に区別可能)
9. ✅ 既存 全 script regression PASS 維持 (= δ で 34 script serial 実行、 全 34 PASS = step 4/5/6/7/8/9/10/11/12/13/14/15/16 系 29 script + step 17 新規 5 件 = 29+5 = 34 script、 BD/SD/CYM/HH/TOM path 不変保証 + driver 改修副作用なし)
10. ✅ user 試聴 OK 確認 (= 19th session δ user 試聴で「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「K-CYM と R-CYM は同一」 「K-TOM と R-TOM は同一」 「K-RIM と R-RIM は同一」 K/R 同音確認、 BD/SD/HH/CYM/TOM/RIM 6 種区別可能、 FM 同居許容方針 ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 audio gate 規律踏襲、 Step 17 audio gate = OK 直接判定 = **full 6 drum completion milestone**)

## 本質再確認

### layering 図 (= future contributor 向け literal 固定、 Step 16 layering の drum 種 1 軸拡張 = full 6 drum completion)

```
source layer:           K part                                          R command
                        \b / \s / \c / \h / \t / \i                     \b inline / \s inline / \c inline / \h inline / \t inline / \i inline
                            \                                              /
                             \                                            /
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
                                  +-- bit 4 = 1 --> _rhythm_event_tom_trigger --> adpcma_sample_tom --> ADPCM-A L ch (= Step 17 で tail-call → call nz pattern 戻し、 「TOM」 semantics / 「tom」 provenance 完全一致)
                                  |
                                  +-- bit 5 = 1 --> _rhythm_event_rim_trigger --> adpcma_sample_rim --> ADPCM-A L ch (= Step 17 new tail-call target、 「RIM」 semantics / 「rim」 provenance 完全一致、 full 6 drum completion)
                                  |
                                  +-- bit 6-7 ---> reserved (= PMD bitmap 範囲外)
                                  |
                                  +-- bitmap = 0x00 --> no-op
                                  |
                                  +-- bitmap = 0x03 / 0x05 / 0x06 / ... / 0x21 / 0x22 / 0x3F --> Step 17 scope-out (= simultaneous trigger semantics future)
```

### Step 12 / Step 13 / Step 14 / Step 15 / Step 16 path 維持原則

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) **不変**
- routine ABI **不変**
- routine 内部の bit 5 分岐は **最後の active bit として tail-call 末尾に挿入** だが routine entry / 引数 / 戻り値 ABI は **不変**
- K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM path **完全不変** (= Step 12 / Step 13 / Step 14 / Step 15 / Step 16 fixture / verify / register write sequence 全て不変)
- `_rhythm_event_bd_trigger` sub-routine **完全不変**
- `_rhythm_event_sd_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift)
- `_rhythm_event_cym_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift)
- `_rhythm_event_hh_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift)
- `_rhythm_event_tom_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift、 tail-call → call nz pattern 戻しで invariant 内部 sequence は同一 literal)
- PC trace + ymfm-trace 二段 gate 規律 **継続**
- PMDDotNET / `.MN` format **完全不変**
- driver-embedded fixture proof 規律 **継続**
- `.PNE` rhythm bank migration **future 維持** (= full 6 drum completion 後の最有力 candidate)

### ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 / ADR-0030 §決定 8 の 6 drum 段 = full PMD drum set literal 実装保証

「dispatch path は drum 種拡張で増やさない」 contract が Step 17 で **bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM + bit 5 RIM の 6 drum 状況下で routine entry addr が変化しない** ことで literal 実装的に保証される。 **full 6 drum completion = Step 12-17 6-step drum 種漸進拡張 sprint chain の完成 milestone**、 drum 種拡張軸は本 ADR で完了、 future sprint は simultaneous trigger / table-driven refactor / `.PNE` rhythm bank migration / 制御 cmd 現役化 等の別軸で進行。

## sub-sprint 構造

ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 同 pattern 踏襲、 1 sub = 1 commit + 1 push 規律:

| sub | commit hash | 内容 | driver 改修 | fixture 追加 | verify script 追加 | 一文要約 |
|---|---|---|---|---|---|---|
| α | `cb2d05e` | 本 ADR 起票 Draft + Annex A literal 反映 | なし (= 完全不変) | なし | なし | ADR-0031 Draft 起票 (= 11 決定 + scope-out 36 項目 + 7 段 gate + 完了判定 10 項目 + layering 図 + Annex A 着手、 mc.cs L9533 `('i', rimset)` + L9721 `rimset → work.al = 32` literal 確認済を本 commit に統合 + 用語対応表 (= PMDDotNET 内部名 rimset と PMDNEO 側 wording RIM は実質一致 = TOM の tamset legacy naming と違って wording 分離なし) も同梱、 driver 完全不変純 doc commit、 full 6 drum completion milestone 起票) |
| β | `d48b7b2` | RIM trigger 接続 + K-RIM fixture + verify | bit 5 分岐追加 (= 末尾 tail-call 挿入) + bit 4 TOM tail-call → call nz pattern 戻し + `_rhythm_event_rim_trigger` sub-routine 新規 + RIM sample pointer mapping | `k-ir-only.mml` | `verify-step17-k-rim-trigger.sh` | pmdneo_rhythm_event_trigger に bit 5 RIM 分岐 + `_rhythm_event_rim_trigger` @ 0x001230 新規 + adpcma_sample_rim pointer mapping + K-RIM fixture + k-rim-trigger verify 5 gate 全 PASS、 全 step12 + step13 + step14 + step15 + step16 BD/SD/HH/CYM/TOM regression PASS、 entry addr @ 0x001126 不変、 全 30 script serial regression PASS (= 107 秒) |
| γ | `be4b919` | R-RIM fixture + differential verify 4 件 | なし (= 既に β で対応済) | `r-melody-ir-only.mml` | `verify-step17-r-rim-trigger.sh` + `verify-step17-kr-rim-byte-identical.sh` + `verify-step17-bd-vs-rim-differential.sh` + `verify-step17-tom-vs-rim-differential.sh` | R-RIM fixture + K-RIM=R-RIM=0x001126 entry + K-RIM=R-RIM=0x001230 rim_trigger byte-identical + BD vs RIM literal differ (= BD 0x00-0x03 vs RIM 0x0A-0x0B) + TOM vs RIM literal differ (= TOM 0x0C-0x11 vs RIM 0x0A-0x0B = Step 16 新参 TOM と Step 17 新参 RIM の前後関係 explicit proof) + SD vs RIM / CYM vs RIM / HH vs RIM 推移的 proof、 全 34 script serial regression PASS (= 127 秒)、 driver 完全不変 |
| δ | `(本 commit)` | 完了統合 + ADR Accepted + handoff + memory | なし (= 完全不変) | なし | なし | ADR-0031 Accepted 移行 + 完了判定 10/10 ✅ literal 達成 + 全 34 script 最終 regression PASS (= 128 秒、 19th session δ fresh state) + user 試聴 audio gate OK (= 6 drum × K/R = 12 wav 全判定軸達成 = **full 6 drum completion milestone 確定**) + handoff doc `adr-0031-step17-completion.md` 起票 + memory `project_pmdneo_step17_complete` 起票 + MEMORY.md index 更新 + listen-step17.sh 同梱 (= 12 wav + sleep 3 + 無限繰り返し + Ctrl+C 停止、 Step 15 / Step 16 convention 踏襲) |

## Annex A: PMDDotNET RIM emit 確認 + bitmap OR (RIM 込み combo) 動作調査 (= 18th session α 着手で literal 反映、 driver / fixture / verify script 完全不変純調査)

### A-1: PMDDotNET `\i` RIM emit literal 確認 (= mc.cs rcomtbl L9528-9533、 α 着手で literal 確認済)

`vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` の `rcomtbl` (= L9521-9534) で drum 識別文字 → handler 関数 mapping が定義されている:

```csharp
,new Tuple<char, Func<enmPass2JumpTable>>('b', bdset)    // \b → BD   (= bit 0 = 0x01)
,new Tuple<char, Func<enmPass2JumpTable>>('s', snrset)   // \s → SD   (= bit 1 = 0x02)
,new Tuple<char, Func<enmPass2JumpTable>>('c', cymset)   // \c → CYM  (= bit 2 = 0x04)
,new Tuple<char, Func<enmPass2JumpTable>>('h', hihset)   // \h → HH   (= bit 3 = 0x08)
,new Tuple<char, Func<enmPass2JumpTable>>('t', tamset)   // \t → TOM  (= bit 4 = 0x10、 handler 名は TAM legacy naming)
,new Tuple<char, Func<enmPass2JumpTable>>('i', rimset)   // \i → RIM  (= bit 5 = 0x20、 Step 17 対象、 `\r` ではない = `\r` は rest 専用)
```

#### Step 17 RIM 関連の確定

- **`\i` → rimset** (= mc.cs L9533 literal、 α 着手で literal 確認済、 handler 名は `rimset` で RIM semantics と一致 = ADR-0030 `tamset` (TAM legacy naming) のような wording 分離はない、 PMDNEO 側 wording も RIM 統一でそのまま使える)
- rimset は `work.al = 32` を set して rs00 を呼ぶ (= mc.cs L9721 literal、 本 ADR §A-2 で再引用)
- rs00 が `0xEB <al>` を emit (= mc.cs L9727-9750 literal、 ADR-0029 §Annex A-2 引用)
- 結果 `\i` 単独で `0xEB 0x20` emit (= bitmap bit 5 = RIM)
- **fixture 命名 `k-ir-only.mml` / `r-melody-ir-only.mml` の `ir` = `\i` + `r`(= rest) pattern は妥当**、 rename 不要 (= 本 ADR §Annex A-1 で `\i` literal 確認済 + memory `project_pmd_rim_drum_char_correction` で `\r ≠ RIM` literal 整合)
- **PMDDotNET 内部名 `rimset` と PMDNEO 側 wording RIM は実質一致** (= 18th session α 着手で literal 明記、 本 ADR §決定 3 「用語対応表」 と完全整合、 ground truth として `rimset` を記録しつつ PMDNEO 側 wording は RIM 統一、 ADR-0030 `tamset` legacy naming のような wording 分離はない)
- **PMDNEO 側 wording = RIM 統一** (= driver source / ADR §決定 / fixture filename / verify script / handoff doc / memory / commit message 全てで RIM 表記、 user judgement = PMD/OPN rhythm では RIM = rim-shot)
- **`\r` は rest 専用、 `\r = RIM` は誤り** (= ADR-0027 §Annex A-1 で literal 訂正済、 memory `project_pmd_rim_drum_char_correction` 整合、 future contributor 向け literal 注記)

### A-2: PMDDotNET rimset emit core path literal 確認 (= mc.cs L9703-9725、 α 着手で literal 確認済)

drum 6 種 set 関数 → rs00 → `0xEB <bitmap>` emit:

```csharp
// mc.cs L9703-9725 (= α 着手で literal 確認)
private enmPass2JumpTable bdset()  { work.al = 1;  return rs00(); }  // BD  = bitmap 0x01
private enmPass2JumpTable snrset() { work.al = 2;  return rs00(); }  // SD  = bitmap 0x02
private enmPass2JumpTable cymset() { work.al = 4;  return rs00(); }  // CYM = bitmap 0x04
private enmPass2JumpTable hihset() { work.al = 8;  return rs00(); }  // HH  = bitmap 0x08
private enmPass2JumpTable tamset() { work.al = 16; return rs00(); }  // TOM = bitmap 0x10
private enmPass2JumpTable rimset() { work.al = 32; return rs00(); }  // RIM = bitmap 0x20 (= Step 17 対象、 handler 名は rimset で RIM semantics と一致)
```

#### RIM 単独 emit (= Step 17 fixture 期待 bytecode)

- `\i` + `r`(= rest) → `\i` (= rimset) → al = 32 → rs00 → rs02 path (= 新規 emit) → `0xEB 0x20`
- 続く `r` (= rest) は別 opcode 経路で処理 (= note rest length emit)
- fixture `k-ir-only.mml` の K part body 期待 bytecode = `0xEB 0x20 <rest length> ... 0x80` (= part end)
- 同様に `r-melody-ir-only.mml` の melody part body = `... 0xEB 0x20 <rest length> ... 0x80`

#### Step 17 driver 側 bitmap accept range 設計確認

本 ADR §決定 2 bitmap accept range と完全整合:

- bit 0 (= 0x01) = BD trigger (= 既存 Step 12 維持)
- bit 1 (= 0x02) = SD trigger (= 既存 Step 13 維持)
- bit 2 (= 0x04) = CYM trigger (= 既存 Step 15 維持)
- bit 3 (= 0x08) = HH trigger (= 既存 Step 14 維持)
- bit 4 (= 0x10) = TOM trigger (= 既存 Step 16 維持、 Step 17 で tail-call → call nz pattern 戻し)
- bit 5 (= 0x20) = RIM trigger (= `\i`) → **本 ADR で新規追加、 new tail-call target = full 6 drum completion**
- bit 6 = (PMD V4.8s pattern body 内専用 flag) → silent ignore
- bit 7 = (note byte 識別 flag、 mc.cs 内 'p' marker) → silent ignore

driver は bit 0 + bit 1 + bit 2 + bit 3 + bit 4 + bit 5 のみ accept、 残り bit は silent ignore (= ADR-0026 §決定 11 / ADR-0028 §決定 2 / ADR-0029 §決定 2 / ADR-0030 §決定 2 「未対応 cmd スルー」 思想踏襲)。

### A-3: PMDDotNET bitmap OR 圧縮 emit 動作 (RIM 込み combo) reference (= α 着手で literal 反映、 ADR-0027 §Annex A-3 / ADR-0028 §Annex A-3 / ADR-0029 §Annex A-3 / ADR-0030 §Annex A-3 引用 + RIM 込み combo 期待 bitmap 整理、 PMDDotNET 実 emit literal 動作確認は §決定 11 simultaneous trigger scope-out で Step 18 候補 simultaneous trigger semantics proof sprint へ譲)

#### ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 §Annex A-3 引用 (= BD+SD combo の bitmap OR 圧縮 path、 mc.cs L9736-9746)

`\b\s` を間に何も挟まず連続記述した場合の emit 挙動 (= ADR-0027 §Annex A-3 literal 確認済):

1. 最初の `\b` を bdset 経由で処理 → al = 1 → rs00 → rs02 path → `0xEB 0x01` emit + di += 2 + prsok = 0x80 set
2. 次の `\s` を snrset 経由で処理 → al = 2 → rs00 → rs01 path check → 3 条件全成立 → bitmap OR → al |= cch (= 0x02 | 0x01 = 0x03) → m_buf di-1 を 0x03 で上書き → 結果 bytecode = `0xEB 0x03` (= BD+SD bitmap OR 1 opcode)

#### Step 17 で reference 整理する RIM 込み combo 動作 (= α 着手で expected emit byte 列を ADR-0027/0028/0029/0030 §Annex A-3 pattern 踏襲で literal 反映、 PMDDotNET 実 emit 動作確認は Step 18 候補 scope)

- `\b\i` の連続記述 → 期待 emit = `0xEB 0x21` (= bit 0 | bit 5 = 0x01 | 0x20)
- `\s\i` の連続記述 → 期待 emit = `0xEB 0x22` (= bit 1 | bit 5 = 0x02 | 0x20)
- `\c\i` の連続記述 → 期待 emit = `0xEB 0x24` (= bit 2 | bit 5 = 0x04 | 0x20)
- `\h\i` の連続記述 → 期待 emit = `0xEB 0x28` (= bit 3 | bit 5 = 0x08 | 0x20)
- `\t\i` の連続記述 → 期待 emit = `0xEB 0x30` (= bit 4 | bit 5 = 0x10 | 0x20)
- `\b\s\i` の連続記述 → 期待 emit = `0xEB 0x23` (= bit 0 | bit 1 | bit 5 = 0x01 | 0x02 | 0x20)
- `\b\c\i` の連続記述 → 期待 emit = `0xEB 0x25` (= bit 0 | bit 2 | bit 5)
- `\b\h\i` の連続記述 → 期待 emit = `0xEB 0x29` (= bit 0 | bit 3 | bit 5)
- `\b\t\i` の連続記述 → 期待 emit = `0xEB 0x31` (= bit 0 | bit 4 | bit 5)
- `\s\c\i` / `\s\h\i` / `\s\t\i` / `\c\h\i` / `\c\t\i` / `\h\t\i` 等 3-drum combo → 期待 emit = `0xEB <bit OR>`
- `\b\s\c\h\t\i` の連続記述 → 期待 emit = `0xEB 0x3F` (= bit 0 | bit 1 | bit 2 | bit 3 | bit 4 | bit 5 = 0x01 | 0x02 | 0x04 | 0x08 | 0x10 | 0x20 = **full 6 drum simultaneous combo**)
- 期待動作は ADR-0027 / ADR-0028 / ADR-0029 / ADR-0030 §Annex A-3 の bitmap OR 圧縮 path と同 pattern、 al |= cch で combo bitmap byte 1 個に圧縮
- PMDDotNET compile + `.MN` hexdump での実 emit byte 列 literal 動作確認は Step 18 候補 simultaneous trigger semantics proof sprint scope (= 本 ADR §決定 11 simultaneous trigger scope-out 整合)

#### Step 17 fixture 設計への影響

Step 17 では simultaneous trigger combo scope-out (= 本 ADR §決定 11 / 軸 4):

- `k-ir-only.mml` K part body = `\i r` 単独パターンのみ (= `\b\i` / `\s\i` / `\c\i` / `\h\i` / `\t\i` 等並記なし)
- `r-melody-ir-only.mml` melody part body = `\i r` 単独パターンのみ
- bitmap 0x21 / 0x22 / 0x24 / 0x28 / 0x30 / 0x23 / 0x25 / 0x29 / 0x31 / 0x26 / 0x2A / 0x32 / 0x2C / 0x34 / 0x38 / 0x3F (= RIM 込み combo + full 6 drum combo) が emit される fixture は **生成しない**
- driver の bitmap accept range は bit 0 / bit 1 / bit 2 / bit 3 / bit 4 / bit 5 個別 accept (= 例えば 0x21 が来た場合、 Step 17 driver が複数 bit を見れば BD + RIM 両方 trigger される可能性あり、 ただし Step 17 fixture では combo emit 経路を踏まない)
- bitmap OR semantics の literal proof (= simultaneous trigger) は future 候補温存 (= 本 ADR §決定 11 維持、 full 6 drum completion 後の最有力 candidate)
- driver 動作可能性と仕様化は別軸 (= 動作可能性は incidental observation、 ADR 内では「未定義」 と明記)

### A-4: PMD V4.8s manual literal 用例 (= `docs/manual/PMDMML_MAN_V48s_utf8.txt`、 ADR-0027 §Annex A-4 / ADR-0028 §Annex A-4 / ADR-0029 §Annex A-4 / ADR-0030 §Annex A-4 引用 + RIM 用例 literal 整理)

#### drum trigger 用例 (= L226-228、 ADR-0030 §Annex A-4 引用)

```
R0	l16[\sr]4
R1	l8 \br\hr\sr\hr
R2	   \br\tr\tr\tr
```

- L226 `\sr` = SD + rest (= 16 分音符 4 個列)
- L227 `\br\hr\sr\hr` = BD + rest, HH + rest, SD + rest, HH + rest (= 8 分音符 4 個列、 BD+HH ペア)
- L228 `\br\tr\tr\tr` = BD + rest, TOM + rest, TOM + rest, TOM + rest (= Step 16 対象 TOM 直接使用例 literal)

#### Step 17 RIM 関連の literal 整理

- **RIM 直接用例は PMD V4.8s manual 内に literal なし** (= `\i` / `\ir` 用例は manual 内 grep でヒットなし、 mc.cs rcomtbl L9533 のみが ground truth)
- ただし PMD V4.8s rcomtbl で `('i', rimset)` が定義 → `\i` syntax は PMD V4.8s 文法 valid (= manual 用例不在は単に用例選択の問題、 syntax は valid)
- fixture `k-ir-only.mml` / `r-melody-ir-only.mml` の `\ir` pattern は **PMD V4.8s 文法に integral 整合** (= rcomtbl ground truth と同 pattern、 manual 直接用例不在は問題ではない)
- RIM = rim-shot は pop / rock 楽曲で BD+SD+HH+CYM+TOM+RIM 6 種 drum 標準セットの accent 構成要素 (= jazz pattern の cross stick / latin pattern の rim shot accent 等)
- PMD/OPN rhythm 6 種は historically BD/SD/CYM/HH/TOM/RIM (= TR-808 系の standard rhythm machine drum set inspired) と整合

### A-5: `adpcma_sample_rim` driver-embedded 状況 literal 確認 (= ADR-0030 §Annex A-5 引用、 standalone_test.s)

#### sample pointer table 内 reference (= ADR-0030 §Annex A-5 引用、 standalone_test.s L2871-2873 / L2889-2891)

```asm
; standalone_test.s L2871-2873 (= table A、 既存 Step 5 から不変)
adpcma_ch_sample_ptr_table:
        .dw     adpcma_sample_bd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top

; standalone_test.s L2889-2891 (= table B、 ADR-0025 step 11 multi-table id=0x01 proof)
adpcma_ch_sample_ptr_table_b:
        .dw     adpcma_sample_bd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top
```

- L = `adpcma_sample_bd` / M = `adpcma_sample_sd` / N = `adpcma_sample_hh` / O = `adpcma_sample_tom` / **P = `adpcma_sample_rim`** / Q = `adpcma_sample_top`
- L-Q ADPCM-A 6ch melody architecture 用 sample pointer table
- ADR-0019 §決定 3 build-time embed 流儀
- **P ch = `adpcma_sample_rim` (= RIM rim-shot sample symbol) ← Step 17 で RIM trigger 用 reuse**

#### `adpcma_sample_rim` literal embed (= ADR-0030 §Annex A-5 引用、 standalone_test.s L2893-2904)

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

- `adpcma_sample_rim` は driver source `standalone_test.s` 内に既に embed 済 (= L2899-2900)
- `RIM_START_LSB / RIM_START_MSB / RIM_STOP_LSB / RIM_STOP_MSB` は `assets/samples.inc` 由来 const (= build 時 .include で展開、 asset 由来 = `assets/sounds/adpcma/2608_RIM.adpcma`)
- Step 17 で `_rhythm_event_rim_trigger` sub-routine が `ld hl, #adpcma_sample_rim` で参照
- ADR-0027 §Annex A-6 (SD reuse) / ADR-0028 §Annex A-5 (HH reuse) / ADR-0029 §Annex A-5 (CYM/TOP reuse) / ADR-0030 §Annex A-5 (TOM reuse) pattern と完全同型

### A-6: Step 12 / Step 13 / Step 14 / Step 15 / Step 16 / Step 17 比較表

| 軸 | Step 12 (BD only) | Step 13 (BD+SD) | Step 14 (BD+SD+HH) | Step 15 (BD+SD+CYM+HH) | Step 16 (BD+SD+CYM+HH+TOM) | Step 17 (full 6 drum) |
|---|---|---|---|---|---|---|
| drum 種 | 1 (= b) | 2 (= b+s) | 3 (= b+s+h) | 4 (= b+s+c+h) | 5 (= b+s+c+h+t) | **6 (= b+s+c+h+t+i)** |
| dispatch entry addr | 0x1126 | 0x1126 (= 不変) | 0x1126 (= 不変) | 0x1126 (= 不変) | 0x1126 (= 不変) | 0x1126 (= 不変) |
| dispatch path 内 bit 分岐 | bit 0 | bit 0 + bit 1 | bit 0 + bit 1 + bit 3 | bit 0 + bit 1 + bit 2 + bit 3 | bit 0 + bit 1 + bit 2 + bit 3 + bit 4 | **bit 0 + bit 1 + bit 2 + bit 3 + bit 4 + bit 5** |
| tail-call target | bit 0 BD (tail) | bit 1 SD (tail) | bit 3 HH (tail) | bit 3 HH (tail jp) | bit 4 TOM (tail jp) | **bit 5 RIM (tail jp)、 bit 4 TOM は call nz pattern に戻し** |
| sample symbol | adpcma_sample_bd | + adpcma_sample_sd | + adpcma_sample_hh | + adpcma_sample_top | + adpcma_sample_tom | **+ adpcma_sample_rim** |
| sub-routine | _rhythm_event_bd_trigger | + _rhythm_event_sd_trigger | + _rhythm_event_hh_trigger | + _rhythm_event_cym_trigger | + _rhythm_event_tom_trigger | **+ _rhythm_event_rim_trigger** |
| fixture 数 | 2 | 4 (= +K-SD/R-SD) | 6 (= +K-HH/R-HH) | 8 (= +K-CYM/R-CYM) | 10 (= +K-TOM/R-TOM) | **12 (= +K-RIM/R-RIM)** |
| verify script 数 | 4 | 7 | 10 | 13 | 16 | **21 (= +5)** |
| 全 regression script 数 | 17 | 20 | 23 | 26 | 29 | **34** |
| simultaneous trigger | scope-out | scope-out | scope-out | scope-out | scope-out | scope-out (= 維持、 future 最有力 candidate) |
| bit silent ignore | bit 1-5 | bit 2-5 | bit 2/4/5 | bit 4/5 | bit 5 | **bit 6-7 (= PMD bitmap 範囲外、 silent ignore 完了)** |
| wording 分離 | なし | なし | なし | あり (= top vs CYM) | なし (= tom = TOM 完全一致) | **なし (= rim = RIM 完全一致、 rimset legacy naming なし)** |
| milestone | drum kind expansion proof 起点 | b+s | b+s+h | b+s+c+h | b+s+c+h+t | **full 6 drum completion = drum 種拡張軸の sprint chain 完成** |
