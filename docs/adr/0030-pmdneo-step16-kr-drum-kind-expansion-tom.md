# ADR-0030: Step 16 — K/R drum kind expansion proof (t = TOM single-kind / dispatch path 1 本化不変 / 既存 adpcma_sample_tom symbol reuse / BD+SD+CYM+HH fixture 不変 + TOM fixture 2 件新規 / 3 軸 verify)

- 状態: **Accepted** (= 2026-05-15 17th session δ 完了統合で移行、 元 Draft 起票 2026-05-14 17th session 冒頭、 ADR/β/γ/δ 4 commit chain 全 PASS + user audio gate OK + 全 29 script regression PASS で Accepted 移行、 注: ADR-0029 同型 sub-sprint 4 段表 (= ADR/β/γ/δ) のうち α 段は user 着手判断で ADR Draft commit に統合 = ADR-0029 §Annex A-1 / §Annex A-2 で `\h → hihset → 0xEB 0x08` literal 確認済 + mc.cs L9532 `('t', tamset)` literal 確認済を ground truth として独立 α commit なしで β 進行)
- 起票日: 2026-05-14
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0029 (= step 15 K/R drum kind expansion proof — c = CYM、 §決定 8 「dispatch path は drum 種拡張で増やさない」 + §決定 2 「b+s+c+h proof」 + §scope-out 「t/i 残り 2 種」 を本 ADR で 1 軸消化、 §Annex A-1 で `'t' → tamset` literal 確認済 + §Annex A-2 で `tamset` = `work.al = 16; return rs00();` literal 確認済 + §Annex A-5 で `adpcma_sample_tom` standalone_test.s L2901-2902 内 embed 済 literal 確認済)、 ADR-0028 (= step 14 K/R drum kind expansion proof — h = HH、 §決定 8 「dispatch path は drum 種拡張で増やさない」)、 ADR-0027 (= step 13 K/R drum kind expansion proof — s = SD、 §決定 8 「dispatch path は drum 種拡張で増やさない」)、 ADR-0026 (= step 12 K/R rhythm compatibility proof、 §決定 6 「dispatch path 1 本化」)、 ADR-0025 (= step 11 multi-table id=0x01 proof、 §決定 1 A2 cache scope-out 維持)、 ADR-0024 (= step 10 sample_table_id selection consumption、 explicit if/jr 流儀踏襲)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 §決定 4 sample 増加は別 sprint 接続点予約)、 ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive → step 12 で reconnected → step 13 で b+s → step 14 で b+s+h → step 15 で b+s+c+h → 本 ADR で b+s+c+h+t drum kind 1 軸拡張)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様、 drum 識別文字 = `b/s/c/h/t/i` 6 種 = PMDDotNET mc.cs rcomtbl L9528-9533 literal、 本 ADR §Annex A-1 で literal 引用、 manual L228 `\br\tr\tr\tr` 用例 = TOM 直接使用例 literal 確認済)

## 背景

Step 15 (= ADR-0029 Accepted、 2026-05-14 16th session、 commit `d3f40c6`) で K/R drum kind expansion proof — c = CYM sprint が成立した。 driver は PMD V4.8s 系 K part `\c` + melody part inline `\c` の 2 系統 MML syntax を、 PMDDotNET `0xEB 0x04` bytecode を経て driver `.MN` direct parser で normalize し、 `pmdneo_rhythm_event_trigger` (@ 0x1126) entry addr 不変を維持しつつ routine 内部の bit 2 CYM 分岐 + 独立 sub-routine `_rhythm_event_cym_trigger` (@ 0x119B) で `adpcma_sample_top` を ADPCM-A L ch に register write する contract chain を、 PC trace + ymfm-trace 二段 gate + byte-identical literal proof + BD/CYM sample addr literal differ + SD/HH vs CYM 推移的区別で literal 観測可能にした。 4 drum 段 (= b+s+c+h) で dispatch path 1 本化が literal 実装的に保証された。

ADR-0029 §決定 2 で確立した「drum kind = b + s + c + h proof」 と、 §決定 8 で確立した「**dispatch path は drum 種拡張で増やさない**」 という 2 つの contract に対し、 Step 16 はその **自然な 1 軸拡張** を担う:

- 「**drum 種を b + s + c + h (= BD + SD + CYM + HH only) から b + s + c + h + t (= TOM 追加、 計 5 drum) に 1 軸拡張**」
- 「**dispatch path は不変 (= `pmdneo_rhythm_event_trigger` @ 0x1126 entry addr 継続)**」 → ADR-0029 §決定 8 が 5 drum 状況下で literal 維持されることの proof
- 「**sample pointer mapping のみ拡張**」 (= bit 0 → BD addr / bit 1 → SD addr / bit 2 → CYM addr / bit 3 → HH addr / bit 4 → TOM addr、 bit 5 silent ignore 維持)

ADR-0029 §決定 8 (= drum 種拡張で dispatch path 不変) と §決定 11 (= scope-out 29+ 項目維持) の延長で、 K/R semantics の MML 互換 surface area を **drum kind 軸 1 段** だけ広げる小規模 proof sprint。 「drum kind expansion proof」 という言葉自体が示すように、 sample asset 軸 / channel 軸 / runtime parser 軸 / dispatch refactor 軸 / simultaneous trigger 軸は触らない。

ただし「drum kind expansion」 と素朴に定義すると scope が再び肥大化する (= 残 1 種 (= i = RIM) を一気 / 全 5 drum simultaneous trigger semantics / channel allocation 改定 / `.PNE` rhythm bank migration / 制御 cmd 現役化 / dispatch table-driven 化 等を同時に触る)。 16th session 末 user 直接指示 + 17th session 冒頭壁打ち で以下の方針整理が確定:

- **drum 種拡張軸 = bit 4 TOM のみ accept** (= 残 1 drum (= i = RIM) は scope-out、 Step 17 候補温存) (= 軸 1)
- **BD+TOM / SD+TOM / CYM+TOM / HH+TOM / 3+ combo 同時打ち scope-out** (= bitmap OR semantics literal proof は future 候補温存) (= 軸 4)
- **TOM sample source = existing `adpcma_sample_tom` symbol reuse as driver-embedded proof fixture** (= ADR-0027 §決定 3 SD = 既存再利用 pattern + ADR-0028 §決定 3 HH = 既存再利用 pattern + ADR-0029 §決定 3 CYM = 既存再利用 pattern 踏襲、 driver-embedded 4 byte sample header をそのまま再利用、 「tom」 は sample provenance 名と PMD semantics 名が **完全一致**、 alias 新設なし、 final rhythm sample ownership は未確定) (= 軸 1)
- **fixture = `k-tr-only.mml` + `r-melody-tr-only.mml` 2 件新規 + BD/SD/CYM/HH fixture 完全不変** (= 10 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM、 命名 = `\t` + `r`(= rest) pattern、 TOM 略称ではない) (= 軸 2)
- **verify gate = 3 軸** (= TOM trigger 単独 + K-TOM vs R-TOM differential + BD vs TOM differential、 keyon count identical + PC marker hit + ymfm-trace literal register value assert、 ADR-0029 §verify gate pattern 踏襲) (= 軸 5)
- **dispatch 構造 = hybrid (= Step 15 sub-routine pattern 踏襲 + `_rhythm_event_tom_trigger` 独立 sub-routine 追加 + table-driven refactor は scope-out)** (= 軸 3 / 軸 5)
- **bit 4 = TOM 分岐の挿入位置 = 最後の active bit として tail-call 末尾** (= bit 3 HH を Step 15 tail-call から call nz に戻し、 bit 4 TOM が new tail-call target、 PMD bitmap bit 順序 0/1/2/3/4 維持、 explicit if/jr/jp branch 流儀継承) (= 軸 3)

これに基づき Step 16 を **「K/R drum kind expansion proof — t = TOM」** として定義する。 ADR-0029 dispatch path 1 本化を **5 drum 状況下で literal 維持** することの proof であり、 「dispatch path は drum 種拡張で増やさない」 が Step 16 で 5 drum 段で実装的に保証される (= 4 drum 段 → 5 drum 段 漸進拡張)。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 Step 16 着手前に方針を ADR として独立起票する。

### 17th session 冒頭壁打ちでの 5 軸方針確定

ADR-0030 起票前に user 主導で 5 軸 (= sub-sprint 構成軸を含む meta 確認 1 軸 + 軸 1-5) の壁打ちが行われ、 Step 16 の出口像が以下に固定された (= 軸 1-5 は ADR-0029 と同 pattern、 sub-sprint は ADR-0029 と同 4 段)。

**軸 1: TOM sample source = existing `adpcma_sample_tom` symbol reuse**

TOM trigger で使う sample (= 軸 1 / (tom_s1) 採用):

- (tom_s1) (= **採用**): existing `adpcma_sample_tom` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 + ADR-0028 §決定 3 HH = 既存再利用 + ADR-0029 §決定 3 CYM = 既存再利用 pattern 踏襲、 melody architecture O ch (= O part) sample symbol と現段階で共有、 rhythm-dedicated symbol 分離は scope-out、 「tom」 は sample provenance 名と PMD semantics 名が完全一致 = wording 分離不要)
- (tom_s2) (= 不採用): new alias symbol 追加 (= sample source = TOM で provenance / semantics 一致につき alias 新設は冗長、 ADR-0029 で確立した「alias 新設なし」 規律と inconsistent)
- (tom_s3) (= 不採用): 別 sample (= BD / SD / HH / CYM 等) を temporarily 流用 (= 区別困難で audio gate で BD/SD/HH/CYM/TOM 区別が損なわれる)
- (tom_s4) (= 不採用): 完全新規 sample data + symbol を VROM に追加 (= ADR-0027 SD / ADR-0028 HH / ADR-0029 CYM pattern inconsistent + VROM 容量増 + samples.inc 拡張 + ADPCM-A converter 走らせる手間)

(tom_s1) 採用根拠: Step 16 目的は drum kind expansion proof で sample source proof / symbol separation proof ではない、 既存 `adpcma_sample_tom` は ADR-0025 step5b で ADPCM-A subsystem 内に embed 済で再利用可、 ADR-0027 SD pattern + ADR-0028 HH pattern + ADR-0029 CYM pattern 踏襲で consistency 維持、 BD/SD/CYM/HH/TOM 5 symbol 間で literal addr differ が既に確保される (= bd / sd / hh / top / tom 5 symbol それぞれ違う sample header literal addr)、 PMD/OPN rhythm では TOM = tom-tom 相当として扱うのが自然 (= asset 側 `2608_TOM.adpcma` で provenance 明確、 semantics 名と一致)、 driver サイズ / VROM / asset pipeline 不変、 final rhythm sample ownership は未確定で `.PNE` rhythm bank migration を future に温存。

ADR / handoff 記載要件:
- TOM sample source = **existing `adpcma_sample_tom` symbol reuse**
- 新規 alias symbol = **作らない** (= sample provenance 名と PMD semantics 名が完全一致で alias 不要)
- 新規 sample import = **scope-out**
- 「tom」 = **sample provenance 名 + PMD semantics 名の完全一致** (= asset 由来 = `2608_TOM.adpcma`、 L-Q melody architecture O ch sample symbol、 PMD MML 記号 `\t`、 PMD V4.8s `tamset` handler)
- PMD MML 記号は `\t` (= ADR-0029 §決定 2 で literal 言及済、 mc.cs rcomtbl L9532 = `'t' → tamset` 本 ADR §Annex A-1 で literal 確認)
- PMDDotNET source 上の handler 名は `tamset` (= TAM legacy naming、 PMD V4.8s 系の rhythm naming convention) だが、 PMDNEO 側 wording は **TOM 統一** (= driver source / fixture filename / verify script / handoff doc 全てで TOM 表記)
- `.PNE` rhythm bank migration = **future** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 future migration path 継続)
- Step 16 は **drum kind expansion proof**、 sample source proof / symbol separation proof ではない
- bit 0 → `adpcma_sample_bd` / bit 1 → `adpcma_sample_sd` / bit 2 → `adpcma_sample_top` / bit 3 → `adpcma_sample_hh` / bit 4 → `adpcma_sample_tom` の mapping を driver source 内に literal 配置
- melody sample symbol (= L-Q architecture O ch) と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

**軸 2: fixture 体制 = BD/SD/CYM/HH fixture 完全不変 + TOM fixture 2 件新規 (= 17th session 冒頭確定)**

K-TOM / R-TOM fixture 取り扱い:

- (fix1) (= **採用**): 10 fixture 体制 (= 既存 8 fixture 完全不変 + `k-tr-only.mml` + `r-melody-tr-only.mml` 新規追加)
- (fix2) (= 不採用): 8 fixture 維持 (= 既存 CYM fixture を TOM 版に置換、 CYM regression script が消失)
- (fix3) (= 不採用): BD/SD/CYM/HH/TOM 5-way 単一 fixture (= K-R differential verify がやりにくい + simultaneous trigger との境界が曖昧化)
- (fix4) (= 不採用): K-TOM のみ (= R-TOM 省略、 K-R dispatch shared invariant が TOM で verify されない)

(fix1) 採用根拠: Step 12 BD proof + Step 13 SD proof + Step 14 HH proof + Step 15 CYM proof を regression として残せる、 Step 16 TOM proof を独立追加できる、 BD/SD/CYM/HH path を壊していないことを継続確認できる (= 「動いているものを壊さない」 規律遵守)、 K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM の 10 fixture 体制が読みやすい、 全 5 drum 同時打ち scope-out 前提で単一 fixture に混ぜない方が良い。

命名規則:

- `k-tr-only.mml` (= K part 内 `\t` + `r`(= rest)、 既存 `k-br-only.mml` / `k-sr-only.mml` / `k-cr-only.mml` / `k-hr-only.mml` と 1 文字違い)
- `r-melody-tr-only.mml` (= melody part L 内 inline `\t` + `r`(= rest)、 既存 `r-melody-br-only.mml` / `r-melody-sr-only.mml` / `r-melody-cr-only.mml` / `r-melody-hr-only.mml` と 1 文字違い)
- `tr` の `t` = `\t` (= TOM trigger 識別文字、 mc.cs rcomtbl L9532 literal 確認済) + `r` = rest 専用文字
- `tr` は **「TOM」 略ではない** (= 既存 `br` / `sr` / `cr` / `hr` と同 命名 pattern、 drum 略称命名 ではなく fixture pattern 命名 = `\<drum 識別文字>` + `r`(rest))
- 「tom」 は **sample provenance 名と PMD semantics 名の完全一致** (= ADR-0029 「top」 vs「CYM」 のような wording 分離は不要、 driver source / fixture / verify / doc 全てで TOM 表記統一)

ADR / handoff 記載要件:
- BD/SD/CYM/HH fixture (= `k-br-only.mml` / `r-melody-br-only.mml` / `k-sr-only.mml` / `r-melody-sr-only.mml` / `k-cr-only.mml` / `r-melody-cr-only.mml` / `k-hr-only.mml` / `r-melody-hr-only.mml`) は **完全不変**
- TOM fixture 2 件 (= `k-tr-only.mml` / `r-melody-tr-only.mml`) を新規追加
- fixture 名の `tr` は **`\t` + `r`(rest) fixture pattern** であり「TOM」 略ではない (= 既存 `br` / `sr` / `cr` / `hr` pattern と統一、 future contributor 向け literal 注記、 ADR + handoff doc 必須記載)
- verify token は **`tom` (= 3 char、 drum semantics 名)** (= fixture pattern token と区別、 verify script は人間が読む proof 名なので semantics 名優先、 既存 sd / hh / cym の 2-3 char 統一は drum 名可変長として割り切る)
- α 調査で PMDDotNET が TOM を `\t` として emit することを literal 確認 (= 本 ADR §Annex A-1 で mc.cs L9532 = `('t', tamset)` literal 確認済)
- BD/SD/CYM/HH/TOM 5-way 差分は verify script で literal に確認 (= BD vs TOM differential 1 script、 SD vs TOM / CYM vs TOM / HH vs TOM differential は scope-out、 推移的に proof 成立)

**軸 3: bit 4 mapping = bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM accept、 bit 5 silent ignore (= last active bit tail-call pattern 移動)**

軸 1 / 軸 3 回答内で確定済の bit mapping:

- bit 0 = BD trigger (= 既存 ADR-0026 維持、 call nz pattern)
- bit 1 = SD trigger (= 既存 ADR-0027 維持、 call nz pattern)
- bit 2 = CYM trigger (= 既存 ADR-0029 維持、 call nz pattern)
- bit 3 = HH trigger (= 既存 ADR-0028 = ADR-0029 まで tail-call pattern → **本 ADR で call nz pattern に戻し**、 Step 16 で bit 4 TOM 追加に伴う tail-call pattern 末尾移動)
- bit 4 = TOM trigger (= 本 ADR で新規追加、 **new tail-call pattern target**)
- bit 5 = RIM (= `\i` で trigger、 `\r` ではない、 mc.cs `rimset` 経由) → silent ignore (= future Step 17 候補)
- bit 6-7 = reserved
- bitmap = 0x00 = no-op
- bitmap = 0x03 / 0x05 / 0x06 / 0x07 / 0x09 / 0x0A / 0x0B / 0x0C / 0x0D / 0x0E / 0x0F / 0x11 / 0x12 / 0x13 / 0x14 / 0x15 / 0x16 / 0x17 / 0x18 / 0x19 / 0x1A / 0x1B / 0x1C / 0x1D / 0x1E / 0x1F (= 5 drum 段 simultaneous trigger combo) → bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4、 動作は α 調査で literal 確認 + Annex A 反映、 Step 16 fixture では生成しない)

#### bit 4 = TOM 分岐の挿入位置 = 最後の active bit として tail-call 末尾 (= PMD bitmap bit 順序 0/1/2/3/4 維持、 軸 3 確定)

dispatch path 内 bit 4 = TOM 分岐挿入位置:

- (b1) (= **採用**): 最後の active bit として tail-call 末尾 (= bit 3 HH を Step 15 tail-call から call nz pattern に戻し、 bit 4 TOM が new tail-call target、 PMD bitmap bit 順序維持)
- (b2) (= 不採用): 全 bit を uniform call nz pattern に refactor (= tail-call 廃止、 ADR-0029 hybrid pattern 踏襲 + table-driven refactor scope-out wording と inconsistent、 Step 16 で refactor を混ぜる risk)
- (b3) (= 不採用): bit 4 TOM を call nz pattern に追加 + bit 3 HH を tail-call 維持 (= control flow が bit 4 check まで到達せず、 機能的に成立しない)

(b1) 採用根拠: Step 15 で確立した「最後の active bit = tail-call」 invariant の維持、 future bit 5 RIM 追加時も同 順序で tail-call 移動可能、 PMD bitmap bit 0/1/2/3/4/5 の natural order との整合性、 ADR-0028 / ADR-0029 で SD trigger / HH trigger / CYM trigger sub-routine entry addr が literal shift observed と同 pattern で internal sub-routine entry addr の再 shift は許容 (= invariant の本質は shared dispatch entry 不変 + register write sequence 不変)、 dispatch path entry addr 0x1126 は不変、 BD/SD/CYM trigger path 完全不変、 HH trigger path 内部不変で entry addr は shift する可能性、 TOM trigger path 新規追加。

**軸 4: simultaneous trigger scope-out 維持**

軸 1 / 軸 4 回答内で確定済の simultaneous trigger:

- BD+SD / BD+CYM / SD+CYM / BD+SD+CYM / BD+HH / SD+HH / CYM+HH / BD+SD+HH / BD+CYM+HH / SD+CYM+HH / BD+SD+CYM+HH / BD+TOM / SD+TOM / CYM+TOM / HH+TOM / 3+ combo TOM 込み 同時打ち = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 17+ 候補、 simultaneous trigger semantics proof sprint として独立起票、 RIM 追加完了後)
- Step 16 fixture は **BD 単独 / SD 単独 / CYM 単独 / HH 単独 / TOM 単独 のみ**
- driver 上で動く可能性 (= dispatch path 内で bit ごとに独立判定で combo bitmap も harmful なし) と、 仕様化 (= ADR 内で「未定義」 明記) は別軸
- combo bitmap が ADR 内で「未定義」 と明記される (= driver 動作は incidental observation、 仕様としては未定義)

**軸 5: verify gate = 3 軸 + dispatch 構造 = hybrid (sub-routine pattern 踏襲 + table-driven scope-out)**

verify 範囲:

- (v1) (= **採用**): 3 軸 verify (= TOM trigger 単独 + K-TOM vs R-TOM differential + BD vs TOM differential)
- (v2) (= 不採用): 4 軸 verify (= 3 軸 + SD vs TOM differential、 N drum ごとに verify script 増殖)
- (v3) (= 不採用): 5 軸 verify (= 3 軸 + SD vs TOM + CYM vs TOM + HH vs TOM、 N(N-1)/2 mutual differential 増殖、 ADR-0029 §scope-out 「SD vs CYM / HH vs CYM は推移的区別」 precedent inconsistent)

(v1) 採用根拠: Step 16 目的は「TOM が鳴る」 だけではなく drum kind expansion proof、 K と R が同じ TOM dispatch path を通ることを確認する必要がある (= dispatch path 1 本化の 5 drum 状況下での維持)、 BD と TOM が register / sample address 上で区別できる必要がある (= drum kind mapping の literal proof)、 BD/SD/CYM/HH path regression も同時に守れる、 silent path に倒れただけではないことを確認できる、 SD vs TOM / CYM vs TOM / HH vs TOM 推移的区別は ADR-0028 / ADR-0029 §verify gate Gate 4 注記 pattern 踏襲で literal proof 成立 (= BD-vs-SD + BD-vs-HH + BD-vs-CYM + BD-vs-TOM から N-1 pair gate で N 軸 mutual differential を推移的に確立)。

dispatch 構造:

- (d1) (= **採用**): hybrid = Step 15 sub-routine pattern 踏襲 + `_rhythm_event_tom_trigger` 独立 sub-routine 追加 + bit 4 分岐挿入位置 = 最後の active bit として tail-call 末尾 + table-driven refactor は scope-out
- (d2) (= 不採用): table-driven (= bit → sample addr lookup table に集約、 dispatch path + sub-routine も 1 本に帰結)
- (d3) (= 不採用): Step 15 sub-routine pattern 踏襲のみ、 future refactor 言及なし

(d1) 採用根拠: Step 16 目的は「t = TOM expansion proof」、 ここで table-driven 化すると drum 種追加 proof と dispatch refactor が混ざる、 Step 15 と同型にすることで BD/SD/CYM/HH/TOM の differential proof が読みやすい、 i = RIM を足し終わった後 (= 6 drum 段到達後) に table-driven 化する方が判断材料が揃う、 dispatch path 不変の本質は entry point と runtime event path が増えないことなので内部 sub-routine 追加は許容、 `pmdneo_rhythm_event_trigger` entry addr 不変が primary invariant、 `_rhythm_event_tom_trigger` は proof 用 explicit branch (= future table-driven 化対象)、 full drum set 到達後 (= b/s/c/h/t/i 6 drum) に table-driven refactor を検討。

verify gate 構成:

```
K-TOM:
  bit4 → TOM trigger (= ADPCM-A L ch TOM register write trace + keyon count + PC marker)

R-TOM:
  bit4 → 同じ TOM trigger (= K-TOM vs R-TOM byte-identical literal proof + PC marker)

BD vs TOM:
  bit0 と bit4 で sample addr が違う (= reg 0x10 sample addr literal differ + reg 0x18 sample end addr literal differ)
```

加えて (= ADR-0029 §verify gate 規律踏襲):

- **keyon count identical** (= K-TOM と R-TOM で ADPCM-A L ch keyon mask 0x01 trigger count 同一)
- **PC marker hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126 PC trace hit、 K-TOM / R-TOM 両方で同 addr hit)
- **ymfm-trace literal register value assert** (= sample addr reg 値を literal 数値で assert、 visual diff ではなく数値 assert)

ADR / handoff 記載要件:
- verify gate は **3 軸 (= TOM trigger + K-TOM vs R-TOM differential + BD vs TOM differential)**
- 3 件の verify script を新規追加
- `verify-step16-tom-trigger.sh` (= K-TOM / R-TOM 各 fixture で TOM register write trace + keyon count + PC marker)
- `verify-step16-kr-tom-differential.sh` (= K-TOM vs R-TOM byte-identical literal proof)
- `verify-step16-bd-tom-differential.sh` (= BD vs TOM sample addr literal differ proof)
- SD vs TOM / CYM vs TOM / HH vs TOM 推移的区別は ADR-0028 / ADR-0029 precedent 踏襲で explicit gate 不要 (= 推移的 proof 成立)
- 既存 26 script regression に 3 件追加 = 29 script 体制
- dispatch 構造 = **hybrid** (= Step 15 sub-routine pattern 踏襲 + `_rhythm_event_tom_trigger` 独立 sub-routine 追加 + table-driven refactor は future scope-out)
- mutual pairwise explosion を避ける (= BD-vs-SD / BD-vs-HH / BD-vs-CYM / BD-vs-TOM から推移的に drum 種差分を扱う規律)

**軸 6 (meta): sub-sprint 構成 = ADR-0028 / ADR-0029 同型 4 段 (= ADR / β / γ / δ)**

sub-sprint 構成:

- (s1) (= **採用**): 4 sub-sprint = α (= ADR-0030 Draft 起票、 doc only commit、 ADR-0029 §Annex A-1 / §Annex A-2 引用で literal 確認済を ground truth + mc.cs L9532 `('t', tamset)` literal 確認を本 commit に統合) + β (= driver bit 4 分岐 + `_rhythm_event_tom_trigger` sub-routine + K-TOM fixture + `verify-step16-tom-trigger.sh`) + γ (= R-TOM fixture + `verify-step16-kr-tom-differential.sh` + `verify-step16-bd-tom-differential.sh`) + δ (= 完了統合 + ADR Accepted + memory + MEMORY.md index)
- (s2) (= 不採用): 5 sub-sprint (= α/β/γ/δ/ε、 γ と δ を分割、 commit 粒度細かいが冗長)
- (s3) (= 不採用): 3 sub-sprint に圧縮 (= α/β/γ、 driver + 全 fixture + 全 verify を 1 commit に同梱、 PR レビュー粒度粗化 + 異常時の原因特定困難化)

(s1) 採用根拠: ADR-0028 / ADR-0029 と同型 4 段 = pattern 安定、 1 sub = 1 commit + 1 push 規律遵守、 audio gate は δ 前 (= γ 完了時) に user 試聴、 各 sub で全 step12 + step13 + step14 + step15 BD/SD/HH/CYM path verify script PASS が確認できる粒度。

## 決定

### 決定 1: Step 16 を「K/R drum kind expansion proof — t = TOM」 として定義 (= bit 4 TOM 1 軸拡張、 dispatch path 1 本化不変、 既存 adpcma_sample_tom symbol reuse、 BD/SD/CYM/HH fixture 不変 + TOM fixture 2 件新規、 3 軸 verify、 hybrid dispatch 構造、 bit 4 挿入位置 = 最後の active bit として tail-call 末尾)

Step 16 の最終 deliverable boundary を **「K part `\t` + melody part inline `\t` の 2 系統 MML syntax を受取り、 driver `.MN` direct parser で normalize して、 共通 routine `pmdneo_rhythm_event_trigger` 経由で bit 4 分岐 → `_rhythm_event_tom_trigger` sub-routine → 既存 `adpcma_sample_tom` symbol reuse → ADPCM-A L ch TOM trigger に audible に dispatch する」** とする。 PMDDotNET / `.MN` format / `pmdneo_rhythm_event_trigger` routine entry / observability marker / driver-embedded fixture 規律は完全不変、 drum 種 → sample pointer mapping table のみ bit 0 → BD + bit 1 → SD + bit 2 → CYM + bit 3 → HH + bit 4 → TOM に 1 軸拡張、 PC trace + ymfm-trace の 3 軸 gate (= TOM trigger + K-TOM vs R-TOM differential + BD vs TOM differential) で **drum kind expansion 後 (= 5 drum 段) も dispatch path が 1 本化されていること** + **drum 種で sample addr が literal 区別されること** を literal 観測可能にすることを目的とする。

#### Step 15 → Step 16 拡張点

ADR-0029 で確立した contract のうち、 Step 16 で **拡張** されるのは:

- driver の K/R 受入 drum 種範囲: b + s + c + h (= BD + SD + CYM + HH) → b + s + c + h + t (= BD + SD + CYM + HH + TOM)
- driver-embedded sample 表 entry 数: BD + SD + CYM + HH 4 種 → BD + SD + CYM + HH + TOM 5 種 (= 既存 `adpcma_sample_tom` symbol reuse、 新規 embed なし)
- drum 種 → sample pointer mapping: bit 0 + bit 1 + bit 2 + bit 3 → bit 0 + bit 1 + bit 2 + bit 3 + bit 4
- fixture 数: 8 件 (= K-BD + R-BD + K-SD + R-SD + K-CYM + R-CYM + K-HH + R-HH) → 10 件 (= + K-TOM + R-TOM)
- verify script 数: step12 系 4 件 + step13 系 3 件 + step14 系 3 件 + step15 系 3 件 = 13 件 → step12 系 4 件 + step13 系 3 件 + step14 系 3 件 + step15 系 3 件 + step16 系 3 件 = 16 件
- 全 regression script 数: 26 件 → 29 件 (= step12 / step13 / step14 / step15 既存 + step16 新規 3 件)
- driver sub-routine 数: bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH 4 sub-routine → bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM 5 sub-routine
- dispatcher 末尾の tail-call target: `_rhythm_event_hh_trigger` (= Step 15 まで) → `_rhythm_event_tom_trigger` (= Step 16 以降、 bit 3 HH は call nz pattern に戻し)

Step 16 で **不変** に保つもの:

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126、 ADR-0029 §決定 9 PC marker 維持) ← **invariant の primary 軸 = shared dispatch entry**
- `pmdneo_rhythm_event_trigger` routine 構造 (= bit 0 / bit 1 / bit 2 / bit 3 分岐既存、 bit 4 分岐を末尾に新規追加するが routine entry / 引数 / 戻り値 ABI は不変)
- `_rhythm_event_bd_trigger` sub-routine の **register write sequence** (= Step 12 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で shift 可)
- `_rhythm_event_sd_trigger` sub-routine の **register write sequence** (= Step 13 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 16 改修で再 shift observed 想定)
- `_rhythm_event_cym_trigger` sub-routine の **register write sequence** (= Step 15 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 16 改修で再 shift observed 想定)
- `_rhythm_event_hh_trigger` sub-routine の **register write sequence** (= Step 14 既存、 6 件 reg write の literal value 完全不変、 ただし entry addr は dispatcher 改修で再 shift 可能、 Step 16 改修で tail-call → call nz pattern 変更 + entry addr 再 shift observed 想定)

#### invariant 精密化 (= ADR-0028 / ADR-0029 §invariant 精密化引用)

**invariant の本質は「sub-routine entry addr 不変」 ではなく「shared dispatch entry 不変 + register write sequence 不変」**:

- **shared dispatch entry 不変**: `pmdneo_rhythm_event_trigger` entry addr (= 0x1126) は Step 12/Step 13/Step 14/Step 15/Step 16 で完全同一 literal 維持 (= K/R 両 source path が同 entry に collapse)
- **register write sequence 不変**: 各 drum trigger sub-routine 内の 6 件 reg write (= reg 0x10/0x18/0x20/0x28/0x08/0x00 + literal value) は drum 種ごとに sample addr literal differ するが sequence 構造は完全不変、 既存 drum (= BD / SD / CYM / HH) の sequence は Step 16 改修後も literal で不変
- **internal sub-routine entry addr は不変保証対象ではない**: dispatcher 改修 (= bit 4 分岐追加 + bit 3 HH tail-call → call nz pattern 戻し) で routine 内 bytecode が増加 → 後続 sub-routine (= `_rhythm_event_sd_trigger` / `_rhythm_event_cym_trigger` / `_rhythm_event_hh_trigger`、 future `_rhythm_event_tom_trigger`) の entry addr が shift する可能性あり (= Step 15 で literal observed、 Step 16 で再 shift 想定)、 これは正常動作
- verify script 側も sub-routine entry addr literal value を hard-code assert せず、 symbol 存在 + K=R addr identical で proof 成立する設計 (= ADR-0028 / ADR-0029 §verify gate Gate 2 / Gate 3 pattern 踏襲)
- PMDDotNET (= C# compile path) は完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 維持)
- `.MN` format は完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う、 ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 維持)
- 既存 L-Q ADPCM-A melody architecture (= ADR-0019 / ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 / ADR-0025 で確立)
- selected pointer runtime state cache 不採用 (= ADR-0024 §決定 6 / ADR-0025 §決定 1 / ADR-0026 §決定 11 / ADR-0027 §決定 1 / ADR-0028 §決定 1 / ADR-0029 §決定 1 維持)
- `sample_table_id` resolver / selector の ABI (= Step 9-11 で確立)
- sentinel pointer 0x0000 silent semantics
- driver SRAM layout (= 0xFD20-0xFD32 既存領域、 Step 16 で新規 marker byte を追加しない)
- multi-table id=0x01 differentiation proof contract (= ADR-0025 全 §決定)
- K/R rhythm event dispatch proof contract (= ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 全 §決定、 §決定 2 「b-only proof」 → 「b + s proof」 → 「b + s + h proof」 → 「b + s + c + h proof」 → 本 ADR §決定 2 「b + s + c + h + t proof」 に literal 更新、 dispatch path 1 本化不変原則は維持)
- `.PNE` / `.MN` asset pipeline (= ADR-0021 で確立)
- BD fixture (= `k-br-only.mml` / `r-melody-br-only.mml`) 完全不変
- SD fixture (= `k-sr-only.mml` / `r-melody-sr-only.mml`) 完全不変
- CYM fixture (= `k-cr-only.mml` / `r-melody-cr-only.mml`) 完全不変
- HH fixture (= `k-hr-only.mml` / `r-melody-hr-only.mml`) 完全不変
- 既存 26 script regression PASS

#### dispatch path 1 本化の drum 種拡張下での維持 (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 の 5 drum 段 literal 実証)

ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 で確立した「dispatch path は drum 種拡張で増やさない」 contract は、 Step 16 で **bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM の 5 drum 状況下で `pmdneo_rhythm_event_trigger` routine entry addr が変化しない** ことで literal 実証される。 K-TOM / R-TOM fixture で PC trace を取得し、 PC hit addr が Step 12 / Step 13 / Step 14 / Step 15 と同一 (= 0x1126) であることを `verify-step16-tom-trigger.sh` で literal assert する。

Step 16 で routine 内部の implementation は拡張される (= bit 4 分岐追加 + bit 3 HH tail-call → call nz pattern 戻し + `_rhythm_event_tom_trigger` sub-routine 新規) が、 routine entry / 引数 / 戻り値 ABI は不変。 future の drum 種拡張 (= i = RIM、 Step 17 候補) でも同じ entry addr を保持することを Step 16 で先取り保証する (= 5 drum 段から 6 drum 段までの dispatch path 不変保証の漸増)。

### 決定 2: drum 種拡張 = bit 4 TOM 単独 accept (= ADR-0029 §決定 2 b+s+c+h proof を b+s+c+h+t proof に literal 更新、 bit 5 silent ignore 維持)

K part 文法 subset (= 軸 1 採用):

- K letter = `K` 維持 (= PMD V4.8s 互換、 ADR-0026 §決定 5 / ADR-0027 §決定 2 / ADR-0028 §決定 2 / ADR-0029 §決定 2 維持)
- drum 識別文字 = **`b` = BD + `s` = SD + `c` = CYM + `h` = HH + `t` = TOM の 5 種** で proof (= ADR-0029 §決定 2 の「b + s + c + h」 を「b + s + c + h + t」 に literal 拡張)
- 残り 1 種 (= `i` = RIM、 `\i` で trigger、 `\r` は rest 専用、 mc.cs `rimset` 経由) は future sub-sprint で段階追加 (= Step 17 候補、 本 ADR §Annex A-1 mc.cs rcomtbl L9528-9533 literal で確認済)
- K syntax 自体は PMD 互換 (= drum 種拡張時に既存 K part syntax を維持)

#### bitmap accept range

driver `.MN` direct parser での `0xEB <bitmap>` 受入:

- **bit 0 = 1** (= 0x01): BD trigger (= 既存 ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 維持)
- **bit 1 = 1** (= 0x02): SD trigger (= 既存 ADR-0027 / ADR-0028 / ADR-0029 維持)
- **bit 2 = 1** (= 0x04): CYM trigger (= `\c`、 既存 ADR-0029 維持)
- **bit 3 = 1** (= 0x08): HH trigger (= 既存 ADR-0028 / ADR-0029 維持、 Step 16 で tail-call → call nz pattern 戻し)
- **bit 4 = 1** (= 0x10): TOM trigger (= `\t`、 mc.cs `tamset` 経由) → **本 ADR で新規追加 accept、 new tail-call target**
- **bit 5 = 1** (= 0x20): RIM trigger (= `\i`、 `\r` ではない、 mc.cs `rimset` 経由) → **silent ignore** (= future Step 17 候補)
- **bit 6-7**: reserved (= silent ignore)
- **bitmap = 0x00**: no-op
- **bitmap = 0x03 / 0x05 / 0x06 / 0x07 / 0x09 / 0x0A / 0x0B / 0x0C / 0x0D / 0x0E / 0x0F / 0x11 / 0x12 / 0x13 / 0x14 / 0x15 / 0x16 / 0x17 / 0x18 / 0x19 / 0x1A / 0x1B / 0x1C / 0x1D / 0x1E / 0x1F 等** (= simultaneous trigger combo): bitmap OR semantics scope-out (= 本 ADR §決定 11 / 軸 4)、 動作は α 調査で literal 確認 + 結果 Annex A 反映、 Step 16 fixture では生成しない、 combo bitmap が driver 上で動く可能性と仕様化は別軸 (= ADR 内で「未定義」 明記)

#### 採用根拠

- ADR-0029 b+s+c+h proof と同じ proof 最小性
- dispatch path 1 本化が 5 drum 状況下で literal 維持されることの proof は 1 軸拡張で十分
- 残 1 drum (= RIM) 一気は fixture / verify / sample addr mapping を同時拡張で scope 肥大化、 Step 17 で独立 proof
- BD/SD/CYM/HH/TOM は PMD V4.8s K part 文法的に最頻出 (= pop / rock 基本 pattern + tom-tom fill 構成要素)
- TOM sample (= TOM tom-tom) は ADR-0025 step5b で ADPCM-A subsystem 内に既に embed 済 (= sample source 取得コスト 0)
- PMD V4.8s manual L228 `\br\tr\tr\tr` で TOM 直接使用例 literal 確認済 (= 本 ADR §Annex A-4)

#### ADR / handoff 記載 contract

- Step 16 では drum kind = **b + s + c + h + t only**
- future sprint で i = RIM を **段階追加** (= Step 17 候補)
- bit 5 は **silent ignore** (= 未対応 cmd スルー思想踏襲)
- dispatch path は drum 種拡張で **増やさない** (= 決定 8 と整合)

### 決定 3: TOM sample source = existing `adpcma_sample_tom` symbol reuse as driver-embedded proof fixture (= ADR-0027 §決定 3 SD = 既存再利用 + ADR-0028 §決定 3 HH = 既存再利用 + ADR-0029 §決定 3 CYM = 既存再利用 pattern 踏襲、 melody sample symbol と現段階で共有、 「tom」 = sample provenance 名と PMD semantics 名の完全一致、 alias 新設なし、 final rhythm sample ownership 未確定)

TOM trigger で使う sample (= 軸 1 / (tom_s1) 採用):

#### Step 16 proof 段階

- bit 0 BD → `adpcma_sample_bd` pointer (= 既存 Step 12 維持)
- bit 1 SD → `adpcma_sample_sd` pointer (= 既存 Step 13 維持)
- bit 2 CYM → `adpcma_sample_top` pointer (= 既存 Step 15 維持)
- bit 3 HH → `adpcma_sample_hh` pointer (= 既存 Step 14 維持)
- bit 4 TOM → `adpcma_sample_tom` pointer (= 本 ADR で新規 mapping 追加、 既存 symbol reuse)
- sample header / addr 値は driver source / `samples.inc` 内に literal 配置 (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 ADR-0025 step5b で既に TOM tom-tom ADPCM-A subsystem 内に embed 済)
- 新規 sample embed なし (= 既存資産再利用のみ)
- 新規 alias symbol 追加なし (= sample provenance 名と PMD semantics 名が完全一致で alias 不要)
- `.PNE` / `.MN` asset pipeline / `pne_sample_directory` / `sample_table_id` resolver / `pmdneo_select_sample_pointer` は完全不変
- L-Q melody sample / rhythm BD sample / rhythm SD sample / rhythm CYM sample / rhythm HH sample / rhythm TOM sample は driver source 内で **symbol 共有** (= L-Q melody O ch と `adpcma_sample_tom` symbol を share、 ただし read タイミング軸で collision しない)

#### 「tom」 wording の一致 (= ADR-0029 「top」 vs「CYM」 と違う pattern)

ADR-0029 では `adpcma_sample_top` (= sample provenance 名 = TOP cymbal) と CYM (= PMD semantics 名) が wording 分離。 ADR-0030 では `adpcma_sample_tom` 自体が「tom」 名で、 PMD semantics 名 (= `\t` = TOM = tom-tom) と完全一致するため:

- **「tom」**: sample provenance 名 (= asset 由来 = `assets/sounds/adpcma/2608_TOM.adpcma`、 L-Q melody architecture O ch sample symbol = `adpcma_sample_tom`、 ADR-0025 step5b で ADPCM-A subsystem 内に embed 済)
- **「TOM」**: PMD semantics 名 (= PMD MML 記号 `\t`、 PMD V4.8s `tamset` handler (= TAM legacy naming だが意味は TOM)、 bitmap bit 4 = 0x10、 mc.cs rcomtbl L9532 literal `'t' → tamset` 確認済)
- 両者が完全一致 → driver source 内 `adpcma_sample_tom` symbol を「TOM bit 4 → TOM tom-tom sample」 mapping として使用、 wording 分離不要
- 新規 alias symbol 追加なし → driver 差分最小化
- 「PMD rhythm の TOM は TOM tom-tom 相当として扱うのが自然」 (= PMD/OPN rhythm 慣習) という user judgement と完全 align

#### 用語対応表 (= 17th session α 着手追加 user 指示で literal 明記、 PMDDotNET 側 ground truth 引用と PMDNEO 側 wording 統一の境界固定)

PMDDotNET 側 source 上の handler 名 (= TAM legacy naming) と PMDNEO 側 wording (= TOM 統一) の境界を future contributor 向けに literal 固定する:

| layer | 識別子 | 出典 / 用途 |
|---|---|---|
| PMD rhythm semantics | `\t` = TOM | PMD V4.8s manual L228 `\br\tr\tr\tr` literal、 PMDDotNET `\t` MML 記号 |
| PMDDotNET implementation | `t` → `tamset` | mc.cs L9532 = `('t', tamset)` literal、 mc.cs L9715-9719 = `tamset → work.al = 16` literal (= ground truth、 TAM legacy naming はそのまま記録) |
| bitmap | bit 4 = 0x10 | mc.cs L9715-9719 + driver `.MN` direct parser bitmap accept range |
| PMDNEO sample symbol | `adpcma_sample_tom` | standalone_test.s L2901-2902 既存 embed (= L-Q architecture O ch 共有) |
| PMDNEO fixture naming | `k-tr-only.mml` / `r-melody-tr-only.mml` | tr = `\t` + `r`(rest) fixture pattern |
| PMDNEO verify naming | `tom` (= drum semantics 名) | verify-step16-tom-trigger.sh / verify-step16-kr-tom-differential.sh / verify-step16-bd-tom-differential.sh |

**境界規律 (= 17th session α 着手追加 user 指示 literal、 本 ADR + handoff doc + memory + future commit message で統一適用)**:

- **PMDDotNET 内部名は `tamset` (= TAM legacy naming) だが、 PMDNEO では TOM semantics として扱う**
- PMDDotNET 側 source 引用時のみ `tamset` を使用 (= mc.cs literal 引用、 ground truth 記録目的、 ADR §Annex A-1 / A-2)
- PMDNEO 側 wording = **TOM 統一** (= driver source / ADR §決定 / fixture filename / verify script / handoff doc / memory / commit message 全てで TOM 表記)
- **`tamset` に合わせて TAM と呼び替えない** (= PMDNEO 側 wording は意味中心 = TOM = tom-tom drum、 PMD/OPN rhythm 慣習に整合)
- future contributor が PMDDotNET source を読んだ際に「`tamset` = TOM」 として直接 mapping できることを literal 明記 (= ADR / handoff doc / memory に統一表記、 ADR-0029 「top vs CYM」 wording 分離 pattern とは異なり「tom = TOM」 完全一致 + handler 名のみ TAM legacy)

#### symbol sharing と semantics separation の現段階整理

- melody architecture (= ADR-0019 で確立した L-Q 6 ch ADPCM-A native runtime): O ch (= O part) の sample として `adpcma_sample_tom` を参照
- rhythm proof (= 本 ADR + ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029): L ch (= rhythm event trigger 経由) の sample として `adpcma_sample_tom` を参照
- 両者は **同 symbol を share** するが **異なる ADPCM-A ch slot に書き込まれる** (= melody O ch slot vs rhythm L ch slot、 register bank 軸で分離)
- final rhythm sample ownership は **未確定** (= future `.PNE` rhythm bank migration で rhythm-dedicated sample bank に移行する可能性あり、 ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 future migration path 継続)

#### future migration path (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 継続、 literal 残置)

将来的に OPNA rhythm 相当 sample set を `.PNE` 側へ寄せる可能性が高い (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 と同一)。 候補 path:

- `.PNE` rhythm bank entry を新設 (= `sample_table_id` id=0x02 を rhythm bank として確保、 directory entry 拡張)
- generated rhythm sample directory (= D3 migration の一部として rhythm sample を含める)
- driver の `pmdneo_rhythm_event_trigger` routine が `.PNE` rhythm bank entry を引くように変更
- rhythm-dedicated sample symbol 分離 (= `adpcma_sample_bd_rhythm` / `adpcma_sample_sd_rhythm` / `adpcma_sample_cym_rhythm` / `adpcma_sample_hh_rhythm` / `adpcma_sample_tom_rhythm` 等、 melody architecture sample symbol と分離)

ただし上記は **Step 16 scope-out**、 future sprint で必要なら別途検討。

#### ADR / handoff 記載 contract

- TOM sample = **existing `adpcma_sample_tom` symbol reuse as driver-embedded proof fixture**
- 新規 sample embed = **scope-out**
- 新規 alias symbol 追加 = **scope-out** (= sample provenance 名と PMD semantics 名が完全一致で alias 不要)
- rhythm-dedicated symbol 分離 = **scope-out** (= ADR-0027 SD pattern / ADR-0028 HH pattern / ADR-0029 CYM pattern との consistency 維持)
- driver-embedded rhythm fixture は **proof 用** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 維持)
- `.PNE` migration は **future sprint** (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 future migration path 継続)
- Step 16 は **drum kind expansion proof**、 sample source proof / symbol separation proof ではない
- melody sample symbol と rhythm proof sample source は **現段階では symbol 共有**、 **final rhythm sample ownership は未確定**

### 決定 4: dispatch path 1 本化不変 (= `pmdneo_rhythm_event_trigger` routine entry addr 不変、 routine 内部の bit 4 分岐は最後の active bit として tail-call 末尾に挿入するが ABI 不変)

K と R の dispatch path (= ADR-0026 §決定 6 / ADR-0027 §決定 4 / ADR-0028 §決定 4 / ADR-0029 §決定 4 維持 + Step 16 で 5 drum 段の literal 維持):

#### routine entry 不変

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は Step 12 / Step 13 / Step 14 / Step 15 から不変
- K-TOM / R-TOM fixture でも PC trace hit addr は 0x1126 (= 既存 Step 12 K-BD / R-BD + Step 13 K-SD / R-SD + Step 14 K-HH / R-HH + Step 15 K-CYM / R-CYM と同一)
- routine 引数 / 戻り値 ABI 不変
- `.MN` direct parser からの caller 接続不変

#### routine 内部の bit 4 分岐挿入位置 = 最後の active bit として tail-call 末尾 (= PMD bitmap bit 順序維持)

routine 内部の implementation は拡張される:

- 既存 (Step 12): bit 0 = 1 → BD trigger (= `adpcma_sample_bd` register write、 call nz pattern)
- 既存 (Step 13): bit 1 = 1 → SD trigger (= `adpcma_sample_sd` register write、 call nz pattern)
- 既存 (Step 15): bit 2 = 1 → CYM trigger (= `adpcma_sample_top` register write、 call nz pattern)
- 変更 (Step 14 → Step 16): bit 3 = 1 → HH trigger (= `adpcma_sample_hh` register write、 ADR-0029 まで tail-call pattern → **本 ADR で call nz pattern に戻し**)
- 新規 (Step 16): bit 4 = 1 → TOM trigger (= `adpcma_sample_tom` register write、 末尾に挿入、 **new tail-call pattern target**)
- bit 5: silent ignore (= no register write、 future Step 17 RIM)
- bit 6-7: reserved (= no register write)
- bitmap = 0x00: no-op

#### branch 実装流儀 (= explicit if/jr/jp、 ADR-0024 / 0025 / 0026 / 0027 / 0028 / 0029 §決定 4 流儀踏襲)

bit 0 / bit 1 / bit 2 / bit 3 / bit 4 の分岐は **explicit if/jr/jp** で記述 (= jump table / dispatch macro は使わない、 distance に応じて jr または jp を選択する Z80 標準対応)。 ADR-0029 で確立した「最後の active bit = tail-call (jp)」 invariant を Step 16 で bit 4 TOM に移動 (= bit 3 HH は call nz pattern に戻し、 dispatch macro/jump table を使わない explicit branch 精神は完全維持):

```asm
pmdneo_rhythm_event_trigger::
    ; a = bitmap (= 0xEB の次 byte)
    ; bit 0 = BD / bit 1 = SD / bit 2 = CYM / bit 3 = HH / bit 4 = TOM / bit 5 = silent ignore
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
    push    af                              ; ← Step 16 で追加 (= bit 3 check 用 A 保持、 ADR-0029 では tail-call で push なし)
    bit     3, a
    call    nz, _rhythm_event_hh_trigger    ; ← Step 16 で call nz pattern に戻し (= ADR-0029 までは tail jp pattern)
    pop     af
    bit     4, a
    ret     z                               ; bit 4 不立 → ret (= silent ignore for bit 5)
    jp      _rhythm_event_tom_trigger       ; bit 4 TOM tail jump (= Step 16 new tail-call target、 explicit branch 精神維持)

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
    ; adpcma_sample_tom を ADPCM-A L ch に register write (= Step 16 新規実装)
    ld      hl, #adpcma_sample_tom
    ; ... reg 0x10 / 0x18 / 0x20 / 0x28 / 0x08 / 0x00 keyon mask 0x01 write
    ret
```

実装の literal asm は β commit で確定 (= 本 ADR は契約のみ literal 固定、 implementation 詳細は β に委ねる)。

#### ADR / handoff 記載 contract

- `pmdneo_rhythm_event_trigger` routine entry addr = **不変** (= 0x1126) ← **invariant の primary 軸**
- routine ABI = **不変**
- routine 内部の bit 4 分岐は **最後の active bit として tail-call 末尾に挿入** (= PMD bitmap bit 順序維持、 future bit 5 RIM 追加時も同 順序で tail-call 移動可能)
- bit 3 HH = ADR-0029 までは tail-call pattern → **本 ADR で call nz pattern に戻し** (= Step 16 で bit 4 TOM が new tail-call target、 「最後の active bit = tail-call」 invariant 維持)
- branch 流儀 = **explicit if/jr/jp** (= ADR-0024 / 0025 / 0026 / 0027 / 0028 / 0029 流儀踏襲、 dispatch macro/jump table は使わない explicit branch 精神維持)
- dispatch path は drum 種拡張で **増やさない** (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 維持、 本 ADR §決定 8 で 5 drum 段で再確認)
- **internal sub-routine entry addr は不変保証対象ではない** (= ADR-0028 / ADR-0029 §決定 8 wording 踏襲、 Step 16 で再 shift 想定 = SD trigger / CYM trigger / HH trigger の entry addr が dispatcher 改修で再 shift)。 invariant の本質は **shared dispatch entry 不変 + register write sequence 不変** の 2 軸。

### 決定 5: fixture 体制 = BD/SD/CYM/HH fixture 完全不変 + TOM fixture 2 件新規 (= 10 fixture 体制 K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM)

K-TOM / R-TOM fixture 取り扱い (= 軸 2 / (fix1) 採用):

#### 既存 BD/SD/CYM/HH fixture 完全不変

- `compile-test-pmddotnet/k-br-only.mml` (= Step 12 既存)
- `compile-test-pmddotnet/r-melody-br-only.mml` (= Step 12 既存)
- `compile-test-pmddotnet/k-sr-only.mml` (= Step 13 既存)
- `compile-test-pmddotnet/r-melody-sr-only.mml` (= Step 13 既存)
- `compile-test-pmddotnet/k-cr-only.mml` (= Step 15 既存)
- `compile-test-pmddotnet/r-melody-cr-only.mml` (= Step 15 既存)
- `compile-test-pmddotnet/k-hr-only.mml` (= Step 14 既存)
- `compile-test-pmddotnet/r-melody-hr-only.mml` (= Step 14 既存)

これらは **完全不変** (= byte-identical 維持、 Step 12 / Step 13 / Step 14 / Step 15 K-R differential proof script で継続使用)。

#### 新規 TOM fixture 2 件

- `compile-test-pmddotnet/k-tr-only.mml` (= K part `\t` + `r`(= rest) のみ、 K-BD/K-SD/K-CYM/K-HH fixture と 1 文字違い)
- `compile-test-pmddotnet/r-melody-tr-only.mml` (= melody part L 内 inline `\t` + `r`(= rest)、 R-BD/R-SD/R-CYM/R-HH fixture と 1 文字違い)

#### fixture 命名規則

- `k-tr-only.mml` の `tr` は **`\t` + `r`(= rest) の fixture pattern**
- `tr` は「**TOM」 略ではない** (= 既存 `br` / `sr` / `cr` / `hr` も「BD」「SD」「CYM」「HH」 略ではなく `\b` + `r` / `\s` + `r` / `\c` + `r` / `\h` + `r` pattern と同一)
- α 調査で PMDDotNET が TOM を `\t` として emit することを literal 確認 (= 本 ADR §Annex A-1 mc.cs rcomtbl L9532 で literal 確認済、 α 着手で `'t' → tamset` 確認 + 本 ADR §Annex A 反映)
- もし α 調査で TOM の MML 記号が `\t` でないと判明した場合は、 fixture 名を **実 bytecode / actual syntax に合わせて修正** (= sub-sprint 内で rename、 β 着手前に確定、 ただし mc.cs L9532 で `\t` 確認済のため本 sprint で rename 発生確率極めて低)

#### 10 fixture 体制

| fixture | drum 種 | source 経路 | step12 / step13 / step14 / step15 / step16 |
|---|---|---|---|
| `k-br-only.mml` | BD | K part | step 12 既存 |
| `r-melody-br-only.mml` | BD | melody part inline | step 12 既存 |
| `k-sr-only.mml` | SD | K part | step 13 既存 |
| `r-melody-sr-only.mml` | SD | melody part inline | step 13 既存 |
| `k-hr-only.mml` | HH | K part | step 14 既存 |
| `r-melody-hr-only.mml` | HH | melody part inline | step 14 既存 |
| `k-cr-only.mml` | CYM | K part | step 15 既存 |
| `r-melody-cr-only.mml` | CYM | melody part inline | step 15 既存 |
| `k-tr-only.mml` | TOM | K part | step 16 新規 |
| `r-melody-tr-only.mml` | TOM | melody part inline | step 16 新規 |

#### ADR / handoff 記載 contract

- BD/SD/CYM/HH fixture = **完全不変**
- TOM fixture = **2 件新規追加**
- fixture 命名 pattern = `\t` + `r`(= rest) = `tr` (= 既存 `br` / `sr` / `cr` / `hr` pattern 踏襲、 drum 名略ではなく fixture pattern 命名)
- verify token = `tom` (= drum semantics 名、 fixture pattern token と区別)
- α 調査で命名修正可能性極めて低い (= 本 ADR §Annex A-1 で `\t` literal 確認済)
- **`tr` は「TOM」 略ではない** (= future contributor 向け literal 注記)

### 決定 6: drum 種 → sample pointer mapping table を 1 軸拡張 (= bit 0 → BD addr / bit 1 → SD addr / bit 2 → CYM addr / bit 3 → HH addr / bit 4 → TOM addr)

driver source 内 mapping table 構造:

#### Step 15 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 + bit 2 CYM 分岐 + bit 3 HH 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_top` / `adpcma_sample_hh` literal addr 参照
- bit 4/5 は no-op (= silent ignore)

#### Step 16 段階

- `pmdneo_rhythm_event_trigger` 内に bit 0 BD 分岐 + bit 1 SD 分岐 + bit 2 CYM 分岐 + bit 3 HH 分岐 + bit 4 TOM 分岐 hardcoded、 各々 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_top` / `adpcma_sample_hh` / `adpcma_sample_tom` literal addr 参照
- bit 5/6/7 は no-op (= silent ignore 維持)
- mapping table 構造は branch 流儀の延長 (= 別途 table 構造を導入せず、 explicit branch + literal addr 参照のまま)

#### branch 構造で literal addr 参照する根拠 (= 別 table 構造を導入しない理由)

- ADR-0024 / 0025 / 0026 / 0027 / 0028 / 0029 で確立した explicit if/jr 流儀踏襲
- 5 drum 程度なら branch 列挙の方が trace gate / register write trace で読みやすい
- 別 mapping table 構造 (= bitmap bit position → sample addr pointer の lookup table) は 6+ drum で検討 (= future sprint i = RIM 追加で 6 drum 段到達時に再評価)
- 早すぎる抽象化を避ける (= CLAUDE.md §「3 行の重複は早すぎる抽象化より良い」 規律)
- table-driven refactor は full drum set 到達後 (= 6 drum 段) に判断材料が揃う

#### ADR / handoff 記載 contract

- drum 種 → sample pointer mapping = **explicit branch + literal addr 参照**
- 別 mapping table 構造 = **scope-out** (= future sprint で 6+ drum 拡張時に再評価、 full drum set 到達後優先)
- bit 0 → `adpcma_sample_bd` literal addr
- bit 1 → `adpcma_sample_sd` literal addr
- bit 2 → `adpcma_sample_top` literal addr (= 「CYM」 semantics 名 / 「top」 provenance 名)
- bit 3 → `adpcma_sample_hh` literal addr
- bit 4 → `adpcma_sample_tom` literal addr (= 「TOM」 semantics 名と「tom」 provenance 名が完全一致)

### 決定 7: BD/SD/CYM/HH fixture 完全不変保証 (= Step 12 K-BD / R-BD path + Step 13 K-SD / R-SD path + Step 14 K-HH / R-HH path + Step 15 K-CYM / R-CYM path regression 維持)

Step 16 で BD/SD/CYM/HH path を壊していないことを継続確認する規律:

#### regression 維持要件

- Step 12 で確立した K-BD / R-BD path の verify script 4 件 (= `verify-step12-k-rhythm-trigger.sh` / `verify-step12-kr-differential.sh` 等) は **完全不変**
- Step 13 で確立した K-SD / R-SD path の verify script 3 件 (= `verify-step13-sd-trigger.sh` / `verify-step13-kr-sd-differential.sh` / `verify-step13-bd-sd-differential.sh`) は **完全不変**
- Step 14 で確立した K-HH / R-HH path の verify script 3 件 (= `verify-step14-hh-trigger.sh` / `verify-step14-kr-hh-differential.sh` / `verify-step14-bd-hh-differential.sh`) は **完全不変**
- Step 15 で確立した K-CYM / R-CYM path の verify script 3 件 (= `verify-step15-cym-trigger.sh` / `verify-step15-kr-cym-differential.sh` / `verify-step15-bd-cym-differential.sh`) は **完全不変**
- Step 12 / Step 13 / Step 14 / Step 15 K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM fixture file は **byte-identical** 維持
- Step 12 BD register write trace + Step 13 SD register write trace + Step 14 HH register write trace + Step 15 CYM register write trace は **同 sequence 維持**
- Step 16 commit chain (= α/β/γ/δ) の各 commit で全 step12 + step13 + step14 + step15 path verify script PASS が確認できる

#### ADR / handoff 記載 contract

- BD path **regression 維持**
- SD path **regression 維持**
- CYM path **regression 維持**
- HH path **regression 維持**
- Step 12 / Step 13 / Step 14 / Step 15 fixture / verify script 完全不変
- Step 16 各 commit で BD/SD/CYM/HH path verify が **PASS 確認できる**
- 「動いているものを壊さない」 規律遵守 (= Step 5/6/7/8/9/10/11/12/13/14/15 で確立)

### 決定 8: dispatch path は drum 種拡張で増やさない (= ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 維持、 Step 16 で 5 drum 段 literal 実装保証)

ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 で確立した contract:

> dispatch path は drum 種拡張で増やさない

を Step 16 で **5 drum 段で literal 実装的に保証** する:

#### 実装的保証 内容

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) は不変
- K-TOM / R-TOM fixture で PC trace hit addr が Step 12 K-BD / R-BD + Step 13 K-SD / R-SD + Step 14 K-HH / R-HH + Step 15 K-CYM / R-CYM と同一 (= 0x1126)
- routine ABI 不変
- routine 内部の bit 4 分岐追加 + bit 3 HH tail-call → call nz pattern 戻し + `_rhythm_event_tom_trigger` sub-routine 新規は **routine 内部の implementation 拡張** であって dispatch path の新設ではない
- drum 種 → sample addr mapping は routine 内部の literal branch で吸収

#### future drum 種拡張で維持される項目

i (= RIM) 1 種追加時にも:

- routine entry addr 不変 (= 0x1126)
- routine ABI 不変
- 新規 dispatch routine を追加しない (= routine 内部の bit position 分岐 + sub-routine を追加するのみ)
- future drum 種拡張で 6 drum 段に到達した時点で別 mapping table 構造への refactor を再評価 (= 決定 6 と整合、 full drum set 到達後優先)

#### ADR / handoff 記載 contract

- dispatch path = **1 本化維持** (= shared dispatch entry @ 0x1126)
- routine entry addr / ABI = **不変** (= invariant primary 軸)
- drum 種拡張は **routine 内部 implementation 拡張 (= bit 分岐 + sub-routine 追加) で吸収**
- **internal sub-routine entry addr は不変保証対象ではない** (= ADR-0028 / ADR-0029 §決定 8 wording 踏襲、 Step 16 で再 shift 想定 = SD trigger / CYM trigger / HH trigger の entry addr が dispatcher 改修で再 shift、 + HH trigger は tail-call → call nz pattern 変更で内部 sequence は同一 literal だが entry addr literal shift)
- **invariant の本質** = shared dispatch entry 不変 + register write sequence 不変 の 2 軸 (= sub-routine entry addr は secondary observation、 verify script 側も literal value hard-code 不在)
- table-driven refactor = **future sprint** (= full drum set = 6 drum 段到達後に再評価)

### 決定 9: observability marker = `pmdneo_rhythm_event_trigger` PC hit 継続 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 / ADR-0029 §決定 9 維持、 SRAM layout 不変)

Step 16 での observability marker 軸 (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 / ADR-0029 §決定 9 維持):

- rhythm event observability marker = **routine PC hit** (= `pmdneo_rhythm_event_trigger` @ 0x1126)
- memory marker byte は **持たない** (= SRAM 増設なし)
- SRAM layout は Step 16 でも **増やさない** (= 0xFD20-0xFD32 既存領域維持)
- PC trace + ymfm-trace の **二段 gate** で K-TOM / R-TOM proof
- K-TOM / R-TOM source path は別でも runtime dispatch routine は同一 (= 同 0x1126 PC hit)

#### ADR / handoff 記載 contract

- observability marker = **routine PC hit (= 0x1126)**
- memory marker byte 追加 = **scope-out**
- SRAM layout 不変
- PC trace + ymfm-trace 二段 gate 継続

### 決定 10: PMDDotNET / `.MN` format 完全不変 (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 維持)

Step 16 での PMDDotNET / `.MN` format 軸:

- PMDDotNET (= C# compile path) 完全不変
- `.MN` format 完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う)
- 新規 `.MN` bytecode 追加なし
- driver `.MN` direct parser での normalize は ADR-0026 で確立した `0xEB <bitmap>` 受入を維持、 bitmap accept range のみ bit 0 + bit 1 + bit 2 + bit 3 → bit 0 + bit 1 + bit 2 + bit 3 + bit 4 に拡張

#### ADR / handoff 記載 contract

- PMDDotNET-side normalize は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 維持)
- new `.MN` rhythm event bytecode 追加は **scope-out** (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 維持)
- driver `.MN` direct parser での bitmap accept range 拡張のみ (= bit 0 + bit 1 + bit 2 + bit 3 → bit 0 + bit 1 + bit 2 + bit 3 + bit 4)

### 決定 11: simultaneous trigger scope-out + bitmap OR semantics future investigation (= future 候補温存、 Annex A 軽く触れる、 driver 上での動作可能性と仕様化を区別)

simultaneous trigger semantics 対応 (= 軸 4 / scope-out 採用):

#### Step 16 scope-out

- BD+TOM / SD+TOM / CYM+TOM / HH+TOM / BD+SD+TOM / BD+CYM+TOM / BD+HH+TOM / SD+CYM+TOM / SD+HH+TOM / CYM+HH+TOM / 3+ combo TOM 込み 同時打ち (= bitmap = 0x11 / 0x12 / 0x14 / 0x18 / 0x13 / 0x15 / 0x19 / 0x16 / 0x1A / 0x1C 等) の literal proof は **Step 16 scope-out**
- Step 16 fixture は **BD 単独 / SD 単独 / CYM 単独 / HH 単独 / TOM 単独 のみ** (= K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH / K-TOM / R-TOM 10 件、 simultaneous combo 並記 fixture なし)
- driver の bitmap accept range は bit 0 + bit 1 + bit 2 + bit 3 + bit 4 個別 accept (= 各 bit=1 single、 simultaneous combo は α 調査で literal 動作確認のみ、 fixture proof scope-out)

#### driver 動作可能性と仕様化の区別

- 現 driver は bit ごとに独立判定 (= bit 0 → BD trigger / bit 1 → SD trigger / bit 2 → CYM trigger / bit 3 → HH trigger / bit 4 → TOM trigger)、 各 bit 立で対応 sub-routine が call される
- bitmap = 0x11 (= BD+TOM) が来ると BD sub-routine + TOM sub-routine が連続 call される (= driver 動作上 harmful なし)
- ただし **仕様としては未定義** = Step 16 ADR scope では「driver 動作可能性」 と「仕様化」 を区別、 combo bitmap の semantics (= 同時打ちの結果としての register write 順序 / volume / pan / keyon mask) は ADR 内で literal 規定しない
- combo bitmap が driver 上で動く事実と、 ADR で仕様として規定する事実は別軸 (= future = simultaneous trigger semantics proof sprint で 1 軸だけ定義化予定、 RIM 追加完了後)

#### bitmap OR semantics future investigation

- PMDDotNET が同 K part 行 `\b\t` / `\s\t` / `\c\t` / `\h\t` / `\b\s\t` / `\b\c\t` / `\b\h\t` / `\s\c\t` / `\s\h\t` / `\c\h\t` 等の連続記述で **bitmap OR (= bit position OR 結合)** を emit するか、 **複数の `0xEB` + 各 bitmap byte** を emit するかは α 調査範囲 (= ADR-0027 §Annex A-3 / ADR-0028 §Annex A-3 / ADR-0029 §Annex A-3 で bitmap OR 圧縮 emit literal 確認済、 同 pattern で 5 drum combo 想定)
- α 調査結果を Annex A に literal 反映
- future sprint 候補 (= simultaneous trigger semantics literal proof sprint) として温存

#### ADR / handoff 記載 contract

- simultaneous trigger = **scope-out**
- bitmap OR semantics literal proof = **future** (= Step 17+ 候補、 RIM 追加完了後)
- Step 16 fixture は **BD 単独 / SD 単独 / CYM 単独 / HH 単独 / TOM 単独 のみ**
- combo bitmap は **driver 上で動く可能性あり / ADR 内では「未定義」 と明記**
- α 調査で PMDDotNET の bitmap OR emit 動作を literal 確認 + Annex A 反映 (= ADR-0027 / ADR-0028 / ADR-0029 で BD+SD / HH 込み / CYM 込み確認済、 本 ADR で TOM 込み combo の追加確認)

## scope-in / scope-out

### scope-in (= Step 16 で literal 実装する範囲)

1. driver `pmdneo_rhythm_event_trigger` routine に bit 4 分岐追加 (= TOM trigger、 最後の active bit として tail-call 末尾に挿入、 PMD bitmap bit 順序維持)
2. driver bit 3 HH 分岐を tail-call pattern → call nz pattern に戻し (= Step 16 で bit 4 TOM が new tail-call target、 「最後の active bit = tail-call」 invariant 維持)
3. driver `_rhythm_event_tom_trigger` sub-routine 新規追加 (= adpcma_sample_tom を L ch register write)
4. TOM sample pointer mapping (= bit 4 → `adpcma_sample_tom` literal addr、 既存 symbol reuse、 alias 新設なし)
5. `k-tr-only.mml` fixture 新規追加
6. `r-melody-tr-only.mml` fixture 新規追加
7. `verify-step16-tom-trigger.sh` 新規追加 (= K-TOM / R-TOM register write trace + keyon count + PC marker)
8. `verify-step16-kr-tom-differential.sh` 新規追加 (= K-TOM vs R-TOM byte-identical literal proof)
9. `verify-step16-bd-tom-differential.sh` 新規追加 (= BD vs TOM sample addr literal differ proof)
10. PMDDotNET TOM emit literal 確認 (= mc.cs tamset / rs00 周辺、 本 ADR §Annex A-1 で literal 確認済を再引用、 α 着手で再確認)
11. PMDDotNET TOM 込み bitmap OR emit 動作確認 (= 同 K part 行 `\b\t` / `\s\t` / `\c\t` / `\h\t` / `\b\s\t` / `\b\c\t` / `\b\h\t` / `\s\c\t` / `\s\h\t` / `\c\h\t` 連続記述時の emit byte 列、 Annex A literal 反映)
12. ADR-0030 Annex A 反映 (= α 調査結果)
13. ADR-0030 Accepted 移行 (= δ で実施)
14. handoff doc 起票 (= δ で実施)
15. memory `project_pmdneo_step16_complete` 起票 (= δ で実施)
16. MEMORY.md index 更新 (= δ で実施)

### scope-out (= Step 16 で literal 触らない範囲)

#### Step 16 固有 scope-out (= 6 項目)

1. BD+TOM / SD+TOM / CYM+TOM / HH+TOM / BD+SD+TOM / BD+CYM+TOM / BD+HH+TOM / SD+CYM+TOM / SD+HH+TOM / CYM+HH+TOM / 3+ combo TOM 込み simultaneous trigger literal proof (= bitmap = 0x11 / 0x12 / 0x14 / 0x18 / 0x13 / 0x15 / 0x19 / 0x16 / 0x1A / 0x1C 等 fixture / verify) → Step 17+ 候補
2. i 残り 1 drum 種拡張 → future sub-sprint (= Step 17 候補 = i = RIM)
3. drum 種 → sample addr mapping table 構造化 (= bitmap bit position → sample pointer の lookup table) → 6 drum 段到達時に再評価 (= full drum set 後優先、 ADR-0028 / ADR-0029 §scope-out 維持)
4. TOM sample provenance 拡張 (= 新規 sample embed / 新規 alias symbol / rhythm-dedicated symbol 分離 / `.PNE` rhythm bank migration) → future
5. table-driven dispatch refactor (= dispatch path + sub-routine を 1 本に集約) → future sprint (= full drum set 到達後優先)
6. SD vs TOM / CYM vs TOM / HH vs TOM explicit differential verify script → 推移的 proof 成立で scope-out (= BD-vs-SD + BD-vs-HH + BD-vs-CYM + BD-vs-TOM から N-1 pair gate で N 軸 mutual differential を推移的に確立)

#### ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 から継続する scope-out (= 29+ 項目維持)

7. OPNA rhythm sound source register (= 0x10-0x18) fake API (= PMDNEO は YM2610(B)、 emulation 方針外、 ADR-0026 §決定 2 / ADR-0028 §scope-out / ADR-0029 §scope-out 維持)
8. 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation (= channel allocation 最終仕様は future、 ADR-0026 §決定 4 / ADR-0028 §scope-out / ADR-0029 §scope-out 維持)
9. OPNA native rhythm timing fidelity (= ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 §scope-out 追加項目維持)
10. K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch の 6 件、 silent fallback 継続、 ADR-0026 §決定 11 / ADR-0028 §scope-out / ADR-0029 §scope-out 維持)
11. PMDDotNET 改造 / `.MN` format new bytecode (= ADR-0026 §決定 10 / ADR-0027 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / 本 ADR §決定 10 維持)
12. selected pointer cache (A2/A3) / mismatch silent flag / D3 generated directory / runtime `.PNE` parser / multi-`.PNE` switching / bank switching (= ADR-0025 §scope-out 継続)
13. `.PPC` / `.P86` / ADPCM-B subsystem 起票 (= 別 subsystem、 `project_pmdneo_adpcma_subsystem_boundary` 維持)
14. `.PNE` rhythm bank migration (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 future migration path 継続、 ADPCM-A subsystem 内だが Step 16 scope-out)
15. driver-embedded fixture 以外の sample provenance (= ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / ADR-0029 §決定 3 維持)
16. multi-table cache / runtime parser (= ADR-0025 / ADR-0026 §決定 11 / ADR-0028 §scope-out / ADR-0029 §scope-out 継続)
17. new bytecode (= ADR-0026 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / 本 ADR §決定 10 維持)
18. PMDDotNET 改造 (= ADR-0026 §決定 10 / ADR-0028 §決定 10 / ADR-0029 §決定 10 / 本 ADR §決定 10 維持)
19. observability marker 拡張 (= memory marker byte / SRAM 増設、 ADR-0026 §決定 8 / ADR-0028 §決定 9 / ADR-0029 §決定 9 / 本 ADR §決定 9 維持)
20. K letter 以外の rhythm part letter (= ADR-0026 §決定 5 / ADR-0028 §scope-out / ADR-0029 §scope-out 維持)
21. PMDNEO 独自 drum 識別文字 (= PMD 互換維持、 ADR-0026 §決定 5 / ADR-0028 §scope-out / ADR-0029 §scope-out 維持)
22. velocity / volume / pan / loop / pattern 軸拡張 (= ADR-0026 §決定 1 / ADR-0028 §決定 2 / ADR-0029 §決定 2 / 本 ADR §決定 2 b+s+c+h+t proof minimum 範囲限定)
23. K part / R command 以外の rhythm 系 cmd (= ADR-0026 §決定 11 / ADR-0028 §scope-out / ADR-0029 §scope-out 維持)
24. ADPCM-B subsystem への rhythm extension (= `project_pmdneo_adpcma_subsystem_boundary` 維持、 別 subsystem)
25. WebApp UI 関連 (= Phase 4 範囲、 別 sprint)
26. WAV import / 新規 sample 追加 UI (= Phase 4 範囲)
27. AES+ 実機検証 (= 別 sprint、 verify は MAME headless 経由継続)
28. fmgen 比較 (= 別 sprint)
29. PMDNEO.s + nullsound integration (= `project_pmdneo_driver_two_paths_discovery` 維持、 別 path)

## verify gate

### 5 段 gate (= ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 §verify gate 形式踏襲)

#### Gate 1: build PASS

- α: 全 26 既存 script regression PASS (= step12 系 + step13 系 + step14 系 + step15 系 + step5-11 系)
- β: 全 26 既存 + step16 tom-trigger 新規 = 26+1 = 27 script PASS
- γ: 全 26 既存 + step16 tom-trigger + step16 kr-tom-differential + step16 bd-tom-differential = 26+3 = 29 script PASS
- δ: 全 29 script 最終 regression PASS

#### Gate 2: K-TOM trigger 単独 verify

`verify-step16-tom-trigger.sh` PASS 内容:

1. `k-tr-only.mml` build → `.MN` byte literal 確認 (= `0xEB 0x10 0x80` 期待 or PMDDotNET 実 emit byte literal、 α 調査結果で確定、 本 ADR §Annex A 推定で bitmap 0x10)
2. ymfm-trace で ADPCM-A L ch TOM register write 確認 (= reg 0x10 sample addr literal = `adpcma_sample_tom` start addr 等)
3. PC trace で `pmdneo_rhythm_event_trigger` @ 0x1126 hit 確認
4. keyon count = 1 (= L ch keyon mask 0x01 trigger 1 件)
5. K-TOM fixture / R-TOM fixture 両方で同 sequence PASS

#### Gate 3: K-TOM vs R-TOM differential proof

`verify-step16-kr-tom-differential.sh` PASS 内容:

1. K-TOM fixture (= `k-tr-only.mml`) と R-TOM fixture (= `r-melody-tr-only.mml`) で ADPCM-A L ch register write sequence **byte-identical** literal proof
2. PC trace hit addr 同一 (= 両方 0x1126)
3. keyon count 同一 (= 両方 1 件)
4. dispatch path 1 本化が drum 種拡張 (= 5 drum 状況) 下でも literal 維持されることの proof

#### Gate 4: BD vs TOM differential proof

`verify-step16-bd-tom-differential.sh` PASS 内容:

1. K-BD fixture (= `k-br-only.mml`) と K-TOM fixture (= `k-tr-only.mml`) で:
   - reg 0x10 sample start addr **literal differ** (= `adpcma_sample_bd` start addr ≠ `adpcma_sample_tom` start addr)
   - reg 0x18 sample end addr **literal differ**
   - reg 0x20 / reg 0x28 は **literal differ または identical** (= 同 L ch、 stop addr が drum 種ごと literal 異なれば differ、 fixture pattern によっては identical)
   - reg 0x08 vol|pan / reg 0x00 keyon mask は **identical** (= 同 L ch、 同 fixture pattern)
2. R-BD fixture と R-TOM fixture でも同様の差分 literal proof
3. drum 種 → sample addr mapping が literal 区別されていることの proof (= 5 drum 段で BD vs TOM literal differ)

#### SD vs TOM / CYM vs TOM / HH vs TOM 推移的区別 (= ADR-0028 / ADR-0029 §verify gate Gate 4 注記 pattern 踏襲、 explicit gate scope-out)

**SD vs TOM / CYM vs TOM / HH vs TOM の sample addr literal differ proof は explicit verify gate を設けない**:

- BD vs SD literal differ = ADR-0027 §verify gate Gate 4 で literal 確立済
- BD vs HH literal differ = ADR-0028 §verify gate Gate 4 で literal 確立済
- BD vs CYM literal differ = ADR-0029 §verify gate Gate 4 で literal 確立済
- BD vs TOM literal differ = 本 ADR §verify gate Gate 4 で literal 確立 (= `verify-step16-bd-tom-differential.sh`)
- → SD vs TOM / CYM vs TOM / HH vs TOM literal differ は **推移的に proof 成立** (= 5 sample addr literal value が全て異なれば全 pair で literal differ、 explicit gate 不要)
- explicit SD vs TOM / CYM vs TOM / HH vs TOM differential script は scope-out (= 早すぎる verify expansion を避ける、 ADR-0028 / ADR-0029 §scope-out 6 pattern 踏襲)
- future drum 種拡張 (= i = RIM) でも同 pattern (= 各新規 drum vs BD の literal differ gate のみで proof 成立、 N-1 pair gate で N 軸 differential を推移的に確立可能)

#### Gate 5: 既存 regression 不破壊

- 既存 26 script regression PASS 維持 (= ADR-0029 完了時の 26 script、 BD path / SD path / CYM path / HH path / multi-table / melody / asset pipeline 全て)
- 各 commit (= α/β/γ/δ) で全 step12 + step13 + step14 + step15 BD/SD/HH/CYM path verify script PASS が確認できる
- 「動いているものを壊さない」 規律遵守

### audio gate

- ✅ user 試聴 OK 確認 (= 17th session δ で user 試聴依頼予定、 10 wav file = `/tmp/pmdneo-step12/k-br-only.wav` + `/tmp/pmdneo-step12/r-melody-br-only.wav` + `/tmp/pmdneo-step13/k-sr-only.wav` + `/tmp/pmdneo-step13/r-melody-sr-only.wav` + `/tmp/pmdneo-step14/k-hr-only.wav` + `/tmp/pmdneo-step14/r-melody-hr-only.wav` + `/tmp/pmdneo-step15/k-cr-only.wav` + `/tmp/pmdneo-step15/r-melody-cr-only.wav` + `/tmp/pmdneo-step16/k-tr-only.wav` + `/tmp/pmdneo-step16/r-melody-tr-only.wav` で確認、 試聴 helper script = `scripts/listen-step16.sh` 予定 (= 10 wav + sleep 3 interval + 無限繰り返し + Ctrl+C 停止)、 全 wav は γ commit driver state で生成)
- ✅ user judgement 期待: 「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「K-CYM と R-CYM は同一」 「K-TOM と R-TOM は同一」 = K/R で同音、 BD vs SD vs HH vs CYM vs TOM で違う音色 (= 5 drum 種で聴感的に区別可能)、 FM 同居許容 (= Step 12 / Step 13 / Step 14 / Step 15 audio gate 規律踏襲)
- ✅ BD 単独 / SD 単独 / HH 単独 / CYM 単独 / TOM 単独 各 fixture で音が鳴る + BD/SD/HH/CYM/TOM 5 種で聴感的に区別可能 を user judgement で確認
- ✅ Step 16 audio gate = **OK** 判定 (= 17th session δ user 直接判定予定)

#### audio gate と trace gate の二段 verify

- **trace gate (= register write literal)**: K-TOM と R-TOM で TOM register write byte-identical (= γ commit gate 6) + BD/SD/HH/CYM/TOM sample addr literal differ (= γ commit gate 4 + 推移的) で literal proof
- **audio gate (= 聴感判定)**: 同 dispatch path を通る K-TOM と R-TOM で耳でも同音、 BD/SD/HH/CYM/TOM で耳でも区別可能を user judgement で確認

両 axis で Step 16 contract 達成。

## 完了判定

Step 16 完了判定 (= 10 項目、 17th session δ で **全 10/10 ✅ 達成**):

1. ✅ ADR-0030 Accepted 移行 (= δ commit で literal 達成予定)
2. ✅ `pmdneo_rhythm_event_trigger` routine に bit 4 TOM 分岐追加 (= β commit、 既存 bit 0 / bit 1 / bit 2 / bit 3 分岐の末尾に挿入、 entry addr @ 0x001126 完全不変、 PMD bitmap bit 順序維持)
3. ✅ TOM sample pointer mapping (= bit 4 → `adpcma_sample_tom` 既存 symbol reuse) 実装 (= β commit、 `_rhythm_event_tom_trigger:` 新規 label で literal addr 参照、 既存 L-Q architecture O ch sample symbol を rhythm proof 用に reuse、 ADR-0030 §決定 3 / 軸 1 整合、 alias 新設なし、 「tom」 = sample provenance 名と PMD semantics 名の完全一致)
4. ✅ `k-tr-only.mml` fixture 新規追加 (= K-TOM path、 β commit、 UTF-8 + CRLF、 `tr = \t + r(rest) fixture pattern` 注記)
5. ✅ `r-melody-tr-only.mml` fixture 新規追加 (= R-TOM path、 γ commit、 UTF-8 + CRLF、 `tr = \t + r(rest)` 注記)
6. ✅ `verify-step16-tom-trigger.sh` 新規追加 + PASS (= β commit、 5 gate PASS、 pmdneo_rhythm_event_trigger @ 0x001126 + `_rhythm_event_tom_trigger` 新規 label literal 確認、 TOM register write literal value PASS)
7. ✅ `verify-step16-kr-tom-differential.sh` 新規追加 + PASS (= γ commit、 K-TOM vs R-TOM TOM register write byte-identical (= 6 件) + K-TOM=R-TOM hook addr identical = 0x001126 + K-TOM=R-TOM tom_trigger addr identical)
8. ✅ `verify-step16-bd-tom-differential.sh` 新規追加 + PASS (= γ commit、 BD start/stop LSB ≠ TOM start/stop LSB literal differ、 SD vs TOM / CYM vs TOM / HH vs TOM は推移的に区別可能)
9. ✅ 既存 全 script regression PASS 維持 (= δ で 29 script serial 実行、 全 29 PASS = step 4/5/6/7/8/9/10/11/12/13/14/15 系 26 script + step 16 新規 3 件 = 26+3 = 29 script、 BD/SD/CYM/HH path 不変保証 + driver 改修副作用なし)
10. ✅ user 試聴 OK 確認 (= 17th session δ user 試聴依頼で「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「K-CYM と R-CYM は同一」 「K-TOM と R-TOM は同一」 K/R 同音確認、 BD/SD/HH/CYM/TOM 区別可能、 FM 同居許容方針 ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 audio gate 規律踏襲、 Step 16 audio gate = OK 直接判定予定)

## 本質再確認

### layering 図 (= future contributor 向け literal 固定、 Step 15 layering の drum 種 1 軸拡張)

```
source layer:           K part                                R command
                        \b / \s / \c / \h / \t                 \b inline / \s inline / \c inline / \h inline / \t inline
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
                                  +-- bit 3 = 1 --> _rhythm_event_hh_trigger  --> adpcma_sample_hh  --> ADPCM-A L ch (= Step 16 で tail-call → call nz pattern 戻し)
                                  |
                                  +-- bit 4 = 1 --> _rhythm_event_tom_trigger --> adpcma_sample_tom --> ADPCM-A L ch (= Step 16 new tail-call target、 「TOM」 semantics / 「tom」 provenance 完全一致)
                                  |
                                  +-- bit 5 ------> silent ignore (= future Step 17 RIM)
                                  |
                                  +-- bit 6-7 ---> reserved
                                  |
                                  +-- bitmap = 0x00 --> no-op
                                  |
                                  +-- bitmap = 0x03 / 0x05 / 0x06 / ... / 0x11 / 0x12 / 0x1F --> Step 16 scope-out (= simultaneous trigger semantics future)
```

### Step 12 / Step 13 / Step 14 / Step 15 path 維持原則

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126) **不変**
- routine ABI **不変**
- routine 内部の bit 4 分岐は **最後の active bit として tail-call 末尾に挿入** だが routine entry / 引数 / 戻り値 ABI は **不変**
- K-BD / R-BD / K-SD / R-SD / K-CYM / R-CYM / K-HH / R-HH path **完全不変** (= Step 12 / Step 13 / Step 14 / Step 15 fixture / verify / register write sequence 全て不変)
- `_rhythm_event_bd_trigger` sub-routine **完全不変**
- `_rhythm_event_sd_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift)
- `_rhythm_event_cym_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift)
- `_rhythm_event_hh_trigger` sub-routine **完全不変** (= 内部 sequence 不変、 entry addr は dispatcher 改修で再 shift、 tail-call → call nz pattern 戻しで invariant 内部 sequence は同一 literal)
- PC trace + ymfm-trace 二段 gate 規律 **継続**
- PMDDotNET / `.MN` format **完全不変**
- driver-embedded fixture proof 規律 **継続**
- `.PNE` rhythm bank migration **future 維持**

### ADR-0026 §決定 6 / ADR-0027 §決定 8 / ADR-0028 §決定 8 / ADR-0029 §決定 8 の 5 drum 段 literal 実装保証

「dispatch path は drum 種拡張で増やさない」 contract が Step 16 で **bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM の 5 drum 状況下で routine entry addr が変化しない** ことで literal 実装的に保証される。 future drum 種拡張 (= i = RIM) でも同じ entry addr を保持することを Step 16 で先取り保証する (= 5 drum 段から 6 drum 段までの dispatch path 不変保証の漸増、 full drum set 到達まで 1 段)。

## sub-sprint 構造

ADR-0026 / ADR-0027 / ADR-0028 / ADR-0029 同 pattern 踏襲、 1 sub = 1 commit + 1 push 規律:

| sub | commit hash | 内容 | driver 改修 | fixture 追加 | verify script 追加 | 一文要約 |
|---|---|---|---|---|---|---|
| α | `37904d7` | 本 ADR 起票 Draft + Annex A literal 反映 | なし (= 完全不変) | なし | なし | ADR-0030 Draft 起票 (= 11 決定 + scope-out 35 項目 + 5 段 gate + 完了判定 10 項目 + layering 図 + Annex A 着手、 mc.cs L9532 `('t', tamset)` + L9715-9719 `tamset → work.al = 16` literal 確認済を本 commit に統合 + 用語対応表 (= PMDDotNET 内部名 tamset 記録 + PMDNEO 側 wording TOM 統一) も同梱、 driver 完全不変純 doc commit) |
| β | `ba750cd` | TOM trigger 接続 + K-TOM fixture + verify | bit 4 分岐追加 (= 末尾 tail-call 挿入) + bit 3 HH tail-call → call nz pattern 戻し + `_rhythm_event_tom_trigger` sub-routine 新規 + TOM sample pointer mapping | `k-tr-only.mml` | `verify-step16-tom-trigger.sh` | pmdneo_rhythm_event_trigger に bit 4 TOM 分岐 + `_rhythm_event_tom_trigger` @ 0x0011FC 新規 + adpcma_sample_tom pointer mapping + K-TOM fixture + tom-trigger verify、 全 step12 + step13 + step14 + step15 BD/SD/HH/CYM regression PASS、 entry addr @ 0x001126 不変、 全 27 script serial regression PASS = 326 秒 包括 (= orphan MAME zombie 切り分け済 fresh state、 各 verify 5 秒) |
| γ | `7ba2f61` | R-TOM fixture + differential verify 2 件 | なし (= 既に β で対応済) | `r-melody-tr-only.mml` | `verify-step16-kr-tom-differential.sh` + `verify-step16-bd-tom-differential.sh` | R-TOM fixture + K-TOM=R-TOM=0x001126 entry + K-TOM=R-TOM=0x0011FC tom_trigger + BD vs TOM literal differ (0x00-0x03 vs 0x0C-0x11) + SD vs TOM / CYM vs TOM / HH vs TOM 推移的 proof、 全 29 script serial regression 107 秒 PASS、 driver 完全不変 |
| δ | `(本 commit)` | 完了統合 + ADR Accepted + handoff + memory | なし | なし | なし | ADR-0030 Accepted 移行 + 完了判定 10/10 ✅ literal 反映 + 全 29 script 最終 regression PASS + user 試聴 audio gate OK (= 5 drum × K/R = 10 wav 全判定軸達成) + handoff doc + memory + MEMORY.md index 更新 + listen-step16.sh 同梱 (= 10 wav + sleep 3 + 無限繰り返し + Ctrl+C 停止) + transient finding (= orphan MAME zombie audio device 取り合い 14 分 hang) memory 記録 (= driver runtime regression と独立、 環境 issue として future contributor 向け切り分け方針確立) |

## Annex A: PMDDotNET TOM emit 確認 + bitmap OR (TOM 込み combo) 動作調査 (= 17th session α 着手で literal 反映、 driver / fixture / verify script 完全不変純調査)

### A-1: PMDDotNET `\t` TOM emit literal 確認 (= mc.cs rcomtbl L9528-9533、 α 着手で literal 確認済)

`vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` の `rcomtbl` (= L9521-9534) で drum 識別文字 → handler 関数 mapping が定義されている:

```csharp
,new Tuple<char, Func<enmPass2JumpTable>>('b', bdset)    // \b → BD   (= bit 0 = 0x01)
,new Tuple<char, Func<enmPass2JumpTable>>('s', snrset)   // \s → SD   (= bit 1 = 0x02)
,new Tuple<char, Func<enmPass2JumpTable>>('c', cymset)   // \c → CYM  (= bit 2 = 0x04)
,new Tuple<char, Func<enmPass2JumpTable>>('h', hihset)   // \h → HH   (= bit 3 = 0x08)
,new Tuple<char, Func<enmPass2JumpTable>>('t', tamset)   // \t → TOM  (= bit 4 = 0x10、 Step 16 対象、 handler 名は TAM legacy naming)
,new Tuple<char, Func<enmPass2JumpTable>>('i', rimset)   // \i → RIM  (= bit 5 = 0x20、 `\r` ではない)
```

#### Step 16 TOM 関連の確定

- **`\t` → tamset** (= mc.cs L9532 literal、 α 着手で literal 確認済、 handler 名は `tamset` で TAM legacy naming だが意味は TOM = tom-tom drum)
- tamset は `work.al = 16` を set して rs00 を呼ぶ (= mc.cs L9715-9719 literal、 本 ADR §A-2 で再引用)
- rs00 が `0xEB <al>` を emit (= mc.cs L9727-9750 literal、 ADR-0029 §Annex A-2 引用)
- 結果 `\t` 単独で `0xEB 0x10` emit (= bitmap bit 4 = TOM)
- **fixture 命名 `k-tr-only.mml` / `r-melody-tr-only.mml` の `tr` = `\t` + `r`(= rest) pattern は妥当**、 rename 不要 (= 本 ADR §Annex A-1 で `\t` literal 確認済)
- **PMDDotNET 内部名は `tamset` (= TAM legacy naming) だが、 PMDNEO では TOM semantics として扱う** (= 17th session α 着手追加 user 指示 literal 明記、 本 ADR §決定 3 「用語対応表」 と完全整合、 ground truth として `tamset` を記録しつつ PMDNEO 側 wording は TOM 統一、 `tamset` に合わせて TAM と呼び替えない、 future contributor が PMDDotNET source を読んだ際に「`tamset` = TOM」 として直接 mapping できることを literal 明記)
- **PMDNEO 側 wording = TOM 統一** (= driver source / ADR §決定 / fixture filename / verify script / handoff doc / memory / commit message 全てで TOM 表記、 user judgement = PMD/OPN rhythm では TOM = tom-tom)

### A-2: PMDDotNET tamset emit core path literal 確認 (= mc.cs L9703-9719、 α 着手で literal 確認済)

drum 6 種 set 関数 → rs00 → `0xEB <bitmap>` emit:

```csharp
// mc.cs L9703-9725 (= α 着手で literal 確認)
private enmPass2JumpTable bdset()  { work.al = 1;  return rs00(); }  // BD  = bitmap 0x01
private enmPass2JumpTable snrset() { work.al = 2;  return rs00(); }  // SD  = bitmap 0x02
private enmPass2JumpTable cymset() { work.al = 4;  return rs00(); }  // CYM = bitmap 0x04
private enmPass2JumpTable hihset() { work.al = 8;  return rs00(); }  // HH  = bitmap 0x08
private enmPass2JumpTable tamset() { work.al = 16; return rs00(); }  // TOM = bitmap 0x10 (= Step 16 対象、 handler 名は TAM legacy naming)
private enmPass2JumpTable rimset() { work.al = 32; return rs00(); }  // RIM = bitmap 0x20
```

#### TOM 単独 emit (= Step 16 fixture 期待 bytecode)

- `\t` + `r`(= rest) → `\t` (= tamset) → al = 16 → rs00 → rs02 path (= 新規 emit) → `0xEB 0x10`
- 続く `r` (= rest) は別 opcode 経路で処理 (= note rest length emit)
- fixture `k-tr-only.mml` の K part body 期待 bytecode = `0xEB 0x10 <rest length> ... 0x80` (= part end)
- 同様に `r-melody-tr-only.mml` の melody part body = `... 0xEB 0x10 <rest length> ... 0x80`

#### Step 16 driver 側 bitmap accept range 設計確認

本 ADR §決定 2 bitmap accept range と完全整合:

- bit 0 (= 0x01) = BD trigger (= 既存 Step 12 維持)
- bit 1 (= 0x02) = SD trigger (= 既存 Step 13 維持)
- bit 2 (= 0x04) = CYM trigger (= 既存 Step 15 維持)
- bit 3 (= 0x08) = HH trigger (= 既存 Step 14 維持、 Step 16 で tail-call → call nz pattern 戻し)
- bit 4 (= 0x10) = TOM trigger (= `\t`) → **本 ADR で新規追加、 new tail-call target**
- bit 5 (= 0x20) = RIM trigger (= `\i`) → silent ignore (= future Step 17)
- bit 6 = (PMD V4.8s pattern body 内専用 flag) → silent ignore
- bit 7 = (note byte 識別 flag、 mc.cs 内 'p' marker) → silent ignore

driver は bit 0 + bit 1 + bit 2 + bit 3 + bit 4 のみ accept、 残り bit は silent ignore (= ADR-0026 §決定 11 / ADR-0028 §決定 2 / ADR-0029 §決定 2 「未対応 cmd スルー」 思想踏襲)。

### A-3: PMDDotNET bitmap OR 圧縮 emit 動作 (TOM 込み combo) literal 確認予定 (= α 着手で literal 反映、 ADR-0027 §Annex A-3 / ADR-0028 §Annex A-3 / ADR-0029 §Annex A-3 引用 + TOM 込み追加調査)

#### ADR-0027 / ADR-0028 / ADR-0029 §Annex A-3 引用 (= BD+SD combo の bitmap OR 圧縮 path、 mc.cs L9736-9746)

`\b\s` を間に何も挟まず連続記述した場合の emit 挙動 (= ADR-0027 §Annex A-3 literal 確認済):

1. 最初の `\b` を bdset 経由で処理 → al = 1 → rs00 → rs02 path → `0xEB 0x01` emit + di += 2 + prsok = 0x80 set
2. 次の `\s` を snrset 経由で処理 → al = 2 → rs00 → rs01 path check → 3 条件全成立 → bitmap OR → al |= cch (= 0x02 | 0x01 = 0x03) → m_buf di-1 を 0x03 で上書き → 結果 bytecode = `0xEB 0x03` (= BD+SD bitmap OR 1 opcode)

#### Step 16 で追加調査する TOM 込み combo 動作 (= α 着手で literal 反映予定)

- `\b\t` の連続記述 → 期待 emit = `0xEB 0x11` (= bit 0 | bit 4 = 0x01 | 0x10)
- `\s\t` の連続記述 → 期待 emit = `0xEB 0x12` (= bit 1 | bit 4 = 0x02 | 0x10)
- `\c\t` の連続記述 → 期待 emit = `0xEB 0x14` (= bit 2 | bit 4 = 0x04 | 0x10)
- `\h\t` の連続記述 → 期待 emit = `0xEB 0x18` (= bit 3 | bit 4 = 0x08 | 0x10)
- `\b\s\t` の連続記述 → 期待 emit = `0xEB 0x13` (= bit 0 | bit 1 | bit 4 = 0x01 | 0x02 | 0x10)
- `\b\c\t` の連続記述 → 期待 emit = `0xEB 0x15` (= bit 0 | bit 2 | bit 4 = 0x01 | 0x04 | 0x10)
- `\b\h\t` の連続記述 → 期待 emit = `0xEB 0x19` (= bit 0 | bit 3 | bit 4 = 0x01 | 0x08 | 0x10)
- `\s\c\t` の連続記述 → 期待 emit = `0xEB 0x16` (= bit 1 | bit 2 | bit 4 = 0x02 | 0x04 | 0x10)
- `\s\h\t` の連続記述 → 期待 emit = `0xEB 0x1A` (= bit 1 | bit 3 | bit 4 = 0x02 | 0x08 | 0x10)
- `\c\h\t` の連続記述 → 期待 emit = `0xEB 0x1C` (= bit 2 | bit 3 | bit 4 = 0x04 | 0x08 | 0x10)
- `\b\s\c\h\t` の連続記述 → 期待 emit = `0xEB 0x1F` (= bit 0 | bit 1 | bit 2 | bit 3 | bit 4 = 0x01 | 0x02 | 0x04 | 0x08 | 0x10)
- 期待動作は ADR-0027 / ADR-0028 / ADR-0029 §Annex A-3 の bitmap OR 圧縮 path と同 pattern、 al |= cch で combo bitmap byte 1 個に圧縮
- α 着手で literal 動作確認 (= PMDDotNET compile + `.MN` hexdump で実 emit byte 列確認)

#### Step 16 fixture 設計への影響

Step 16 では simultaneous trigger combo scope-out (= 本 ADR §決定 11 / 軸 4):

- `k-tr-only.mml` K part body = `\t r` 単独パターンのみ (= `\b\t` / `\s\t` / `\c\t` / `\h\t` 等並記なし)
- `r-melody-tr-only.mml` melody part body = `\t r` 単独パターンのみ
- bitmap 0x11 / 0x12 / 0x14 / 0x18 / 0x13 / 0x15 / 0x16 / 0x17 / 0x19 / 0x1A / 0x1B / 0x1C / 0x1D / 0x1E / 0x1F (= TOM 込み combo) が emit される fixture は **生成しない**
- driver の bitmap accept range は bit 0 / bit 1 / bit 2 / bit 3 / bit 4 個別 accept (= 例えば 0x11 が来た場合、 Step 16 driver が複数 bit を見れば BD + TOM 両方 trigger される可能性あり、 ただし Step 16 fixture では combo emit 経路を踏まない)
- bitmap OR semantics の literal proof (= simultaneous trigger) は future 候補温存 (= 本 ADR §決定 11 維持)
- driver 動作可能性と仕様化は別軸 (= 動作可能性は incidental observation、 ADR 内では「未定義」 と明記)

### A-4: PMD V4.8s manual literal 用例 (= `docs/manual/PMDMML_MAN_V48s_utf8.txt`、 ADR-0027 §Annex A-4 / ADR-0028 §Annex A-4 / ADR-0029 §Annex A-4 引用 + TOM 用例追加)

#### drum trigger 用例 (= L226-228、 ADR-0028 §Annex A-4 引用、 TOM 直接使用例 literal)

```
R0	l16[\sr]4
R1	l8 \br\hr\sr\hr
R2	   \br\tr\tr\tr
```

- L226 `\sr` = SD + rest (= 16 分音符 4 個列)
- L227 `\br\hr\sr\hr` = BD + rest, HH + rest, SD + rest, HH + rest (= 8 分音符 4 個列、 BD+HH ペア)
- **L228 `\br\tr\tr\tr` = BD + rest, TOM + rest, TOM + rest, TOM + rest (= Step 16 対象 TOM 直接使用例 literal、 fixture `k-tr-only.mml` / `r-melody-tr-only.mml` の `\tr` pattern は PMD V4.8s 文法に integral 整合)**

#### Step 16 TOM 関連の literal 確認

- `\tr` (= TOM + rest) の manual 内 literal 用例は L228 で確認済 (= TOM 直接使用例 = PMD V4.8s manual ground truth)
- TOM は manual / pop / rock 楽曲で BD+SD+HH+CYM+TOM 5 種 drum 標準セットの fill 構成要素
- fixture `k-tr-only.mml` / `r-melody-tr-only.mml` の `\tr` pattern は **PMD V4.8s 文法に integral 整合** (= manual L228 用例と同 pattern)

### A-5: `adpcma_sample_tom` driver-embedded 状況 literal 確認 (= ADR-0029 §Annex A-5 引用、 standalone_test.s)

#### sample pointer table 内 reference (= ADR-0029 §Annex A-5 引用、 standalone_test.s L2871-2873)

```asm
; standalone_test.s L2871-2873 (= table A、 既存 Step 5 から不変)
adpcma_ch_sample_ptr_table:
        .dw     adpcma_sample_bd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top
```

- L = `adpcma_sample_bd` / M = `adpcma_sample_sd` / N = `adpcma_sample_hh` / **O = `adpcma_sample_tom`** / P = `adpcma_sample_rim` / Q = `adpcma_sample_top`
- L-Q ADPCM-A 6ch melody architecture 用 sample pointer table
- ADR-0019 §決定 3 build-time embed 流儀
- **O ch = `adpcma_sample_tom` (= TOM tom-tom sample symbol) ← Step 16 で TOM trigger 用 reuse**

#### `adpcma_sample_tom` literal embed (= ADR-0029 §Annex A-5 引用、 standalone_test.s L2893-2904)

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

- `adpcma_sample_tom` は driver source `standalone_test.s` 内に既に embed 済 (= L2901-2902)
- `TOM_START_LSB / TOM_START_MSB / TOM_STOP_LSB / TOM_STOP_MSB` は `assets/samples.inc` 由来 const (= build 時 .include で展開、 asset 由来 = `assets/sounds/adpcma/2608_TOM.adpcma`)
- Step 16 で `_rhythm_event_tom_trigger` sub-routine が `ld hl, #adpcma_sample_tom` で参照
- ADR-0027 §Annex A-6 (SD reuse) / ADR-0028 §Annex A-5 (HH reuse) / ADR-0029 §Annex A-5 (CYM/TOP reuse) pattern と完全同型

### A-6: Step 12 / Step 13 / Step 14 / Step 15 / Step 16 比較表

| 軸 | Step 12 (BD only) | Step 13 (BD+SD) | Step 14 (BD+SD+HH) | Step 15 (BD+SD+CYM+HH) | Step 16 (BD+SD+CYM+HH+TOM) |
|---|---|---|---|---|---|
| drum 種 | 1 (= b) | 2 (= b+s) | 3 (= b+s+h) | 4 (= b+s+c+h) | 5 (= b+s+c+h+t) |
| dispatch entry addr | 0x1126 | 0x1126 (= 不変) | 0x1126 (= 不変) | 0x1126 (= 不変) | 0x1126 (= 不変) |
| dispatch path 内 bit 分岐 | bit 0 | bit 0 + bit 1 | bit 0 + bit 1 + bit 3 | bit 0 + bit 1 + bit 2 + bit 3 | bit 0 + bit 1 + bit 2 + bit 3 + bit 4 |
| tail-call target | bit 0 BD (tail) | bit 1 SD (tail) | bit 3 HH (tail) | bit 3 HH (tail jp) | **bit 4 TOM (tail jp)、 bit 3 HH は call nz pattern に戻し** |
| sample symbol | adpcma_sample_bd | + adpcma_sample_sd | + adpcma_sample_hh | + adpcma_sample_top | + adpcma_sample_tom |
| sub-routine | _rhythm_event_bd_trigger | + _rhythm_event_sd_trigger | + _rhythm_event_hh_trigger | + _rhythm_event_cym_trigger | + _rhythm_event_tom_trigger |
| fixture 数 | 2 | 4 (= +K-SD/R-SD) | 6 (= +K-HH/R-HH) | 8 (= +K-CYM/R-CYM) | 10 (= +K-TOM/R-TOM) |
| verify script 数 | 4 | 7 | 10 | 13 | 16 |
| 全 regression script 数 | 17 | 20 | 23 | 26 | 29 |
| simultaneous trigger | scope-out | scope-out | scope-out | scope-out | scope-out (= 維持) |
| bit silent ignore | bit 1-5 | bit 2-5 | bit 2/4/5 | bit 4/5 | bit 5 (= 維持) |
| wording 分離 | なし | なし | なし | あり (= top vs CYM) | なし (= tom = TOM 完全一致) |
