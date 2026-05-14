# ADR-0026: Step 12 — K/R rhythm compatibility proof (b-only / driver-embedded / L ch scaffold) (= MML syntax + audible 互換 β 軸、 driver `.MN` direct parser normalize、 独立 routine `pmdneo_rhythm_event_trigger` 共通 dispatch、 PC trace + ymfm-trace 二段 gate、 drum 種 b only、 sub-sprint ADR + α/β/γ/δ 5 commit chain)

- 状態: **Draft** (= 2026-05-14 13th session 冒頭壁打ち成果、 δ 完了統合時に Accepted 移行予定)
- 起票日: 2026-05-14
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 §決定 2 (= step 5 設計判断 2、 K/R rhythm compat は legacy retained but inactive、 「現役化は L-Q 成立後の別 micro-sprint で起票」 → 本 ADR がその「別 micro-sprint」 相当)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 §決定 4 sample 増加は別 sprint 接続点予約)、 ADR-0024 (= step 10 sample_table_id selection consumption、 §決定 6 selected pointer state cache 不採用)、 ADR-0025 (= step 11 multi-table id=0x01 proof、 §決定 1 A2 cache scope-out 維持)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様)

## 背景

Step 11 (= ADR-0025) 完了 (= 2026-05-14 12th session、 commit `64fa17d`) で multi-table id=0x01 differentiation proof が成立した。 driver は `sample_table_id` を selection key として L ch の sample pointer を 2 table から切替えることが literal observable な状態に到達し、 **「identity resolution → playback selection → multi-table selection differentiation」 contract chain** が成立した。

ADR-0025 Accepted 後の重要境界に明記された通り、 Step 11 時点では:

- multi-table architecture の **proof-of-selection stage** に到達、 完成版 (= generated directory / table-of-tables / cache / runtime parser) は scope-out 維持
- ADPCM-A subsystem 軸の延伸は段階的に進行中 (= ADR-0021 から ADR-0025 までの 5 sprint 連続で)
- 直前 12th session δ レビューで `project_pmdneo_adpcma_subsystem_boundary.md` 整理 = PMDNEO は YM2610(B) ADPCM-A subsystem 専用 runtime-managed architecture、 PCM 全般 abstraction ではない
- Step 12 候補 (= 7 件) のうち K/R rhythm compatibility が user 推奨で温存 (= ADR-0016 §決定 2 「現役化は別 micro-sprint」 と整合)

Step 12 はこの境界の **「ADPCM-A subsystem の MML 互換 surface area の rhythm 軸への拡張」** を担う。 PMD V4.8s 系 K part + R command の syntax + audible semantics を、 Step 5-11 で確立した PMDNEO native ADPCM-A runtime 上で再現する compatibility layer の **1 段目** を実装する sprint である。

ただし「K/R rhythm compatibility」 と素朴に定義すると scope が肥大化する (= 全 6 drum / OPNA rhythm register fake / 6ch drum sub-allocation / `.PNE` rhythm bank / 複数 drum 同時打ち / 動的 channel allocation 等を同時に触る)。 13th session 冒頭の壁打ち (= 7 軸) で以下の方針整理が確定:

- **K/R compatibility 軸 = β** (= MML syntax + audible 互換、 OPNA rhythm register API fake は不採用、 syntax のみ + 独自 audio も不採用) (= 軸 1)
- **sample source = (s4) driver-embedded fixture + `.PNE` migration path 明記** (= 軸 2)
- **channel allocation = (c5) L ch 暫定占有 scaffold + L-Q melody fixture 衝突回避 + 最終 allocation future sprint** (= 軸 3)
- **drum 種 = b-only proof** (= BD only、 s/c/h/t/r 残り 5 種 future) (= 軸 4)
- **K と R の dispatch = (b3) 共通 rhythm event hook に normalize** (= source 2 系統 → runtime 1 系統 collapse) (= 軸 5)
- **normalize 担当 layer = (n2) driver `.MN` direct parser** (= PMDDotNET / `.MN` format 不変) (= 軸 6)
- **rhythm event observability marker = (m1) 独立 routine label `pmdneo_rhythm_event_trigger` PC hit** (= memory marker byte なし、 SRAM layout 増設なし) (= 軸 7)
- **「動いているものを壊さない」 規律 (= Step 5/6/7/8/9/10/11 で確立) を継続遵守**

これに基づき Step 12 を **「K/R rhythm compatibility proof sprint」** として定義する。 driver-embedded rhythm fixture + 独立 hook routine + driver parser normalize により、 PMD K part + R command の MML syntax が PMDNEO native ADPCM-A trigger に届くことを実証する最小成立形である。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 Step 12 着手前に方針を ADR として独立起票する。

### 13th session 冒頭壁打ちでの 7 軸方針確定

ADR-0026 起票前に user 主導で 7 軸の壁打ちが行われ、 Step 12 の出口像が以下に固定された。

**前提軸: A1 vs A2 (compatibility-first vs native-first) = A1 採用**

K/R compatibility を:

- A1 (= **継続採用**): compatibility-first (= 既存 PMD K/R semantics を最小再現、 MML 互換維持)
- A2 (= 不採用): native-first (= PMDNEO native rhythm runtime として再構成、 PMD K/R との互換を捨てる)

A1 採用根拠: 「PMD K/R syntax を受け取り、 PMDNEO native ADPCM-A trigger に audible に再現する compatibility layer」 という Step 12 定義に整合、 K/R の価値は「PMD MML として書けること」 と「それらしく鳴ること」、 PMDDotNET MML 文化を NEOGEO に持ち込む PMDNEO の目的 (= [`CLAUDE.md §プロジェクト要旨`]) と整合、 native-first は別 sprint で必要なら後段検討。

**軸 1: K/R compatibility 軸 = β 採用**

K/R を OPNB 上で再現する方針:

- α (= 不採用): Hardware register API 互換 (= driver 内に OPNA rhythm register 風 API を持ち、 内部で ADPCM-A 6ch に mapping)
- β (= **採用**): MML syntax + audible 互換 (= driver 内部は OPNB native ADPCM-A trigger、 MML syntax のみ PMD 互換、 hardware API は fake しない)
- γ (= 不採用): MML syntax 互換のみ (= compile error なし、 audio は PMDNEO 独自で PMD と一致させない)

β 採用根拠: OPNB(YM2610/B) には OPNA rhythm sound source register (= 0x10-0x18) が物理的に不在で hardware API fake は重い、 Step 5-11 で育てた ADPCM-A native architecture と噛み合わせるなら driver 内部は OPNB native のままが良い、 K/R の価値は「PMD MML として書けること」 と「それらしく鳴ること」、 register-level OPNA rhythm 互換は PMDNEO の目的から外れる、 γ は軽すぎて compatibility と呼ぶには弱い。

ADR / handoff 記載要件:
- K/R compatibility は **hardware API compatibility ではない**
- OPNB 上で OPNA rhythm register を **fake しない**
- K/R syntax → PMDNEO native ADPCM-A trigger へ変換する
- Step 5 の「legacy retained but inactive」 を Step 12 で「retained and reconnected under PMDNEO native mapping」 に更新
- 既存 L-Q ADPCM-A native path は壊さない
- `.PPC` / `.P86` / ADPCM-B は別 subsystem として scope-out 維持

**軸 2: sample source = (s4) driver-embedded fixture + `.PNE` migration path 明記**

K/R rhythm 用 sample data の供給経路:

- (s1) (= 不採用): Step 11 multi-table を流用 (= rhythm 専用 `sample_table_id` 例 id=0x02 を新規確保、 `.PNE` 経由)
- (s2) (= 中間採用): Driver-embedded fixture (= driver source / `samples.inc` に rhythm sample 表を hand-write embed)
- (s3) (= 不採用): Sample data は scope-out (= 「trigger event が走った」 trace のみ proof)
- (s4) (= **採用**): 部分採用 (= 最初は (s2) で proof、 後段で `.PNE` rhythm bank へ migration path を ADR で明記)

(s4) 採用根拠: K/R compatibility の最初の目的は「K/R semantics が PMDNEO native ADPCM-A trigger に接続できる」 ことの proof、 いきなり `.PNE` multi-table に載せると K/R semantics と asset pipeline 変更が混ざる、 driver-embedded fixture なら sample source を固定でき K/R dispatch の検証に集中できる、 Step 11 multi-table architecture を melody / general ADPCM-A selection のまま壊さずに済む、 最終的には OPNA rhythm 相当 sample set を `.PNE` 側へ寄せる可能性が高いので migration path は ADR に残すべき。

ADR / handoff 記載要件:
- driver-embedded rhythm fixture は **proof 用**、 最終 ownership ではない
- `.PNE` rhythm bank migration は **future sprint**
- Step 12 では K/R semantics と audible trigger を先に証明する
- asset ownership はまだ最終化しない

**軸 3: channel allocation = (c5) Hybrid (L ch 暫定占有 scaffold + 最終仕様 future sprint)**

rhythm event を流す ADPCM-A ch:

- (c1) (= 不採用): L ch 恒久占有 (= L-Q melody は M-Q 5 ch に縮小)
- (c2) (= 不採用): rhythm channel 新概念 + 内部実装 L ch 占有
- (c3) (= 不採用): 6ch sub-allocate (= drum 種別 ↔ ADPCM-A ch 固定 mapping、 OPNA rhythm source semantics)
- (c4) (= 不採用): 動的切替 (= K active 時のみ L ch 流用、 K inactive 時は L ch melody)
- (c5) (= **採用**): Hybrid (= proof 段階 (c1) 相当、 後段 sprint で (c2) / (c4) へ進化、 ADR で migration path 明記)

(c5) 採用根拠: Step 12 の目的は K/R semantics dispatch の最小 proof、 いきなり c2 の rhythm channel 概念を作ると概念設計 + dispatch + sample fixture が混ざる、 c3 は OPNA rhythm 的には美しいが 6ch sub-allocation まで入るので scope が大きい、 c4 は runtime context switching が入り最初の proof には重い、 c1 を恒久仕様にすると L-Q symmetry を壊す、 c5 は proof 最小性と future architecture の余地を両立できる。

ADR / handoff 記載要件:
- L ch 使用は **proof fixture 用の暫定 allocation**
- 「K/R rhythm = L ch 恒久占有」 ではない
- L-Q melody architecture は **恒久的には縮小しない**
- rhythm channel concept / dynamic switching / 6ch drum sub-allocation は **future sprint**
- K/R audible proof のために、 fixture 側で L melody との衝突を避ける

**軸 4: drum 種 = b-only proof (= BD only)**

K part 文法 subset:

- (a1) (= 不採用): PMD V4.8s K part full set (= `b` / `s` / `c` / `h` / `t` / `r` 6 種)
- (a2) (= **採用**): Proof minimum subset (= K letter 維持 + drum 識別文字 `b` = BD 1 種のみ)
- (a3) (= 不採用): PMDNEO 独自 part letter (= Step 12 定義に矛盾)

(a2) 採用根拠: 6 drum full set は proof に対して大きすぎる、 K syntax 自体は PMD 互換、 6 種 full set は future expansion、 同じ枠組みで段階拡張可能。

**軸 5: K と R の dispatch = (b3) 共通 rhythm event hook に normalize**

K part bytecode と R command bytecode の dispatch path:

- (b1) (= 不採用): K + R を別 dispatch で proof (= dispatch path 2 本化)
- (b2) (= 不採用): K only proof、 R command は future sub-sprint
- (b3) (= **採用**): K と R は同じ rhythm event dispatch path に統合 (= compile / emit 側で同じ rhythm event bytecode に reduce、 driver 側は「rhythm trigger event」 だけを見る)

(b3) 採用根拠: 6 drum full set は proof に対して大きすぎる、 K と R を別 dispatch にすると proof が二重化、 rhythm event bytecode に normalize すれば dispatch path を 1 本化できる、 future に drum 種を増やしても dispatch path を増やさずに済む、 Step 12 は「rhythm semantics normalization」 の最初の proof として位置付けられる。

ADR / handoff 記載要件:
- K と R は **source syntax は別でも、 runtime dispatch は同じ「rhythm trigger event」 に reduce される**
- source layer (= K part / R command) → normalize → runtime layer (= rhythm trigger event) → dispatch → ADPCM-A native trigger
- Step 12 では drum kind = b only
- future sprint で s/c/h/t/r を段階追加
- **dispatch path は drum 種拡張で増やさない**

**軸 6: normalize 担当 layer = (n2) driver `.MN` direct parser**

K part bytecode と R command bytecode を「同じ rhythm event」 に reduce する layer:

- (n1) (= 不採用): PMDDotNET (= C# compile path) 側で normalize (= `.MN` format に new rhythm event bytecode emit)
- (n2) (= **採用**): Driver `.MN` direct parser 側で normalize (= PMDDotNET / `.MN` format 完全不変)
- (n3) (= 不採用): Hybrid (= proof は (n2)、 後段 (n1) migration)

(n2) 採用根拠: Step 7-11 の「PMDDotNET / `.MN` format 不変 + driver 側で段階拡張」 という流れと整合、 PMDDotNET と `.MN` format を触ると compile path / binary format / driver の 3 層を同時に動かすことになる、 Step 12 の目的は K/R semantics dispatch proof なので driver 側で既存 bytecode を読む方が scope が小さい、 既存 PMD V4.8s `.M` / `.MN` compatibility にも繋がりやすい、 new rhythm event bytecode を `.MN` format に追加しない方が安全。

ADR / handoff 記載要件:
- normalize layer = driver `.MN` direct parser
- **PMDDotNET-side normalize は scope-out**
- **new `.MN` rhythm event bytecode 追加は scope-out**
- K/R source syntax と runtime dispatch は分離
- dispatch path は K/R 共通の 1 本

**軸 7: rhythm event observability marker = (m1) 独立 routine label PC hit**

β/γ の trace gate で「既存 L-Q ADPCM-A melody path と区別できる rhythm event marker」 を入れる手段:

- (m1) (= **採用**): 独立 routine label による PC marker (= `pmdneo_rhythm_event_trigger:` という label、 PC trace で label addr hit を literal assert)
- (m2) (= 不採用): Memory inspection area への marker byte 書込 (= driver SRAM 1 byte 専用領域追加)
- (m3) (= 不採用): (m1) + (m2) Hybrid

(m1) 採用根拠: Step 9-11 の独立 routine pattern (= `pmdneo_resolve_sample_table_id` / `pmdneo_select_sample_pointer`) と整合、 K と R が同じ dispatch path を通ったことを同じ PC addr hit で証明できる、 SRAM に観測専用 marker byte を増やさずに済む、 proof minimum 性を保てる、 future の rhythm marker state / debug state を先取りしないで済む。

ADR / handoff 記載要件:
- rhythm event observability marker = **routine PC hit**
- memory marker byte は **持たない**
- SRAM layout は Step 12 では **増やさない**
- PC trace + ymfm-trace の **二段 gate** で proof する
- K/R source path は別でも runtime dispatch routine は同一

## 決定

### 決定 1: Step 12 を「K/R rhythm compatibility proof sprint」 として定義 (= β 軸 + b-only + L ch scaffold + driver-embedded fixture + driver parser normalize + 独立 routine PC marker)

Step 12 の最終 deliverable boundary を **「K part + R command の MML syntax を受取り、 driver `.MN` direct parser で normalize して、 独立 routine `pmdneo_rhythm_event_trigger` 経由で ADPCM-A L ch に audible に dispatch する」** とする。 PMDDotNET / `.MN` format は完全不変、 driver-embedded rhythm fixture を sample source とし、 PC trace + ymfm-trace の二段 gate で K/R が同じ dispatch path を経由することを literal 観測可能にすることを目的とする。

#### Step 11 → Step 12 拡張点

ADR-0025 で確立した contract のうち、 Step 12 で **拡張** されるのは:

- driver の MML 解釈範囲: L-Q ADPCM-A melody only → L-Q ADPCM-A melody + K part rhythm + R command rhythm
- driver の独立 routine 集合: `pmdneo_resolve_sample_table_id` + `pmdneo_select_sample_pointer` → 上記 + `pmdneo_rhythm_event_trigger`
- driver-embedded sample 表: L-Q melody sample (= `adpcma_ch_sample_ptr_table` / `adpcma_ch_sample_ptr_table_b`) + rhythm fixture sample (= 新規 hand-write embed)
- ADPCM-A L ch の用途: melody only → melody + rhythm (= K/R active 時の暫定占有 scaffold)

Step 12 で **不変** に保つもの:

- PMDDotNET (= C# compile path) は完全不変
- `.MN` format は完全不変 (= 既存 PMD V4.8s K bytecode + R command bytecode をそのまま使う)
- 既存 L-Q ADPCM-A melody architecture (= ADR-0019 / ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 / ADR-0025 で確立)
- selected pointer runtime state cache 不採用 (= ADR-0024 §決定 6 / ADR-0025 §決定 1 維持)
- `sample_table_id` resolver / selector の ABI (= Step 9-11 で確立)
- sentinel pointer 0x0000 silent semantics
- driver SRAM layout (= 0xFD20-0xFD32 既存領域、 Step 12 で新規 marker byte を追加しない)
- multi-table id=0x01 differentiation proof contract (= ADR-0025 全 §決定)
- `.PNE` / `.MN` asset pipeline (= ADR-0021 で確立)
- 既存 14 script regression PASS

#### multi-table architecture との独立性

Step 12 で導入する driver-embedded rhythm fixture は、 既存 multi-table architecture (= `adpcma_ch_sample_ptr_table` / `adpcma_ch_sample_ptr_table_b` / `pne_sample_directory` / selector) と **完全独立** な sample 供給経路を持つ:

- K/R rhythm event → `pmdneo_rhythm_event_trigger` → driver-embedded rhythm fixture (= 新規 sample 表) → ADPCM-A L ch register write
- L-Q melody event → 既存 `adpcma_keyon_simple` → `pmdneo_select_sample_pointer` → `adpcma_ch_sample_ptr_table[_b]` → ADPCM-A L-Q ch register write

両 path は **同じ ADPCM-A L ch を共有しうる** が、 source / sample 表 / dispatch routine は分離。 channel 衝突 (= K/R active 時に L ch melody を意図しない sample で上書き) は proof 段階の fixture 側で衝突回避 (= L-Q fixture で L part を mute or 不在化)。 動的衝突解決は Step 12 scope-out (= future sprint で channel allocation 最終仕様と同時に検討)。

### 決定 2: K/R compatibility 軸 = β (= MML syntax + audible 互換、 OPNA rhythm register API fake は scope-out)

K/R を PMDNEO 上で再現する方針 (= 軸 1 / β 採用):

- MML 側 (= K part / R command) は PMD V4.8s と同じ書き方で書ける
- compile binary の中身は OPNB native (= ADPCM-A trigger)
- driver には OPNA rhythm register API は持たせない
- 「MML 互換は守るが driver 内部は PMDNEO 流」 路線

#### 採用根拠

- OPNB(YM2610/B) には OPNA rhythm sound source register (= 0x10-0x18) が物理的に存在しない、 emulation は overhead 大
- Step 5-11 で育てた ADPCM-A native architecture と整合
- K/R の価値は「PMD MML として書けること」 と「それらしく鳴ること」
- register-level OPNA rhythm 互換は PMDNEO の目的 (= [`CLAUDE.md §プロジェクト要旨`]) から外れる
- syntax のみ + 独自 audio (= γ 軸) は軽すぎて compatibility と呼ぶには弱い

#### ADR / handoff 記載 contract

- K/R compatibility は **hardware API compatibility ではない**
- OPNB 上で OPNA rhythm register を fake しない
- K/R syntax → PMDNEO native ADPCM-A trigger へ変換する
- Step 5 の「legacy retained but inactive」 (= ADR-0016 §決定 2) を Step 12 で **「retained and reconnected under PMDNEO native mapping」** に更新する
- 既存 L-Q ADPCM-A native path は壊さない
- `.PPC` / `.P86` / ADPCM-B は別 subsystem として scope-out 維持

### 決定 3: sample source = driver-embedded fixture (= proof 用) + `.PNE` rhythm bank migration path を future sprint に明記

K/R rhythm 用 sample data の供給経路 (= 軸 2 / (s4) 採用):

#### Step 12 proof 段階

driver source / `samples.inc` 等に rhythm sample 表 (= BD 1 種 sample data) を hand-write embed する。 既存 ADR-0019 §決定 3 (= sample addr build-time embed) と同じ流儀で:

- rhythm sample header / addr table は driver source 内に literal 配置
- driver の `pmdneo_rhythm_event_trigger` routine は rhythm sample 表 entry を直接引く
- `.PNE` / `.MN` asset pipeline / `pne_sample_directory` / `sample_table_id` resolver / `pmdneo_select_sample_pointer` は完全不変
- L-Q melody sample (= 既存 `adpcma_ch_sample_ptr_table[_b]`) と rhythm sample (= 新規 driver-embedded fixture) は別表 / 別 routine で完全分離

#### future migration path (= scope-out 明示、 ADR で literal 残置)

将来的に OPNA rhythm 相当 sample set を `.PNE` 側へ寄せる可能性が高い。 候補 path:

- `.PNE` rhythm bank entry を新設 (= `sample_table_id` id=0x02 を rhythm bank として確保、 directory entry 拡張)
- generated rhythm sample directory (= D3 migration の一部として rhythm sample を含める)
- driver の `pmdneo_rhythm_event_trigger` routine が `.PNE` rhythm bank entry を引くように変更

ただし上記は **Step 12 scope-out**、 future sprint で必要なら別途検討。

#### ADR / handoff 記載 contract

- driver-embedded rhythm fixture は **proof 用**
- 最終 ownership ではない
- `.PNE` migration は **future sprint**
- Step 12 では K/R semantics と audible trigger を先に証明する
- asset ownership はまだ最終化しない

### 決定 4: channel allocation = L ch 暫定占有 scaffold + L-Q melody fixture 衝突回避 + 最終仕様 future sprint

K/R rhythm event を流す ADPCM-A ch (= 軸 3 / (c5) Hybrid 採用):

#### Step 12 proof 段階

- K/R rhythm event は ADPCM-A **L ch** に dispatch (= scaffold)
- proof 用 fixture は L-Q melody との衝突を回避 (= L-Q fixture で L part を mute or 不在化、 detail は α 調査時に確定)
- K active 判定 / dynamic context switching は不実装
- L-Q symmetry は概念上維持 (= 「L ch 恒久占有」 ではなく「proof 段階の暫定 allocation」)

#### future migration path (= scope-out 明示)

候補:

- (c2) rhythm channel concept formalization (= MML / driver 上「rhythm channel」 を新概念として追加、 内部実装 L ch 占有でも user space ch とは別 layer)
- (c3) 6ch drum sub-allocation (= drum 種別 ↔ ADPCM-A ch 固定 mapping、 BD=L / SD=M / CYM=N / HH=O / TOM=P / RIM=Q、 OPNA rhythm source semantics 復元)
- (c4) 動的 channel allocation (= K active 時のみ L ch 流用、 K inactive 時は L ch melody)

これらは **Step 12 scope-out**、 future sprint で channel allocation 最終仕様を再判断する。

#### ADR / handoff 記載 contract

- L ch 使用は **proof fixture 用の暫定 allocation**
- 「K/R rhythm = L ch 恒久占有」 ではない
- L-Q melody architecture は **恒久的には縮小しない**
- rhythm channel concept / dynamic switching / 6ch drum sub-allocation は **future sprint**
- K/R audible proof のために、 fixture 側で L melody との衝突を避ける

### 決定 5: drum 種 = b-only proof (= BD only、 残り 5 種 future sprint)

K part 文法 subset (= 軸 4 / (a2) 採用):

- K letter = `K` 維持 (= PMD V4.8s 互換)
- drum 識別文字 = **`b` = BD のみ** で proof
- 残り 5 種 (= `s` = SD / `c` = CYM / `h` = HH / `t` = TOM / `r` = RIM) は future sub-sprint で段階追加
- K syntax 自体は PMD 互換 (= drum 種拡張時に既存 K part syntax を維持)

#### 採用根拠

- 6 drum full set は proof に対して大きすぎる (= 6 種 drum sample fixture / dispatch path / register write trace を同時に proof する scope 肥大)
- proof 最小性と PMD 互換維持の両立
- 拡張は同じ枠組みで増やせる (= drum 種別 → sample pointer の mapping table を 1 軸拡張、 dispatch path は不変)

#### ADR / handoff 記載 contract

- Step 12 では drum kind = **b only**
- future sprint で s/c/h/t/r を **段階追加**
- dispatch path は drum 種拡張で **増やさない** (= 決定 6 と整合)

### 決定 6: K と R の dispatch = 共通 rhythm event hook `pmdneo_rhythm_event_trigger` に normalize (= source 2 系統 → runtime 1 系統 collapse)

K part bytecode と R command bytecode の dispatch (= 軸 5 / (b3) 採用):

#### layering 図 (= 本質再確認、 future contributor 向け literal 固定)

```
source layer:      K part        R command
                      \           /
                       \         /
                        normalize  (= driver .MN direct parser)
                            ↓
runtime layer:     rhythm trigger event
                            ↓
                        dispatch
                            ↓
                  pmdneo_rhythm_event_trigger
                            ↓
                  ADPCM-A native trigger (L ch、 scaffold)
```

#### 採用根拠

- K と R を別 dispatch にすると proof が二重化
- rhythm event bytecode に normalize すれば dispatch path を 1 本化できる
- future に drum 種を増やしても、 dispatch path を増やさずに済む (= drum 種別 → sample pointer mapping table の拡張のみ)
- Step 12 は「rhythm semantics normalization」 の最初の proof として位置付けられる
- ADR-0024 §決定 4 (= 中間 routine `pmdneo_select_sample_pointer` 経由 ABI) と同じ規律 (= 独立 routine で routine 境界 + ABI 明示)

#### ADR / handoff 記載 contract

- K と R は **source syntax は別でも、 runtime dispatch は同じ「rhythm trigger event」 に reduce される**
- driver 側は **「rhythm trigger event」 だけを見る** (= K parser path / R parser path から同 routine に call)
- Step 12 では drum kind = b only
- **dispatch path は drum 種拡張で増やさない**

### 決定 7: normalize 担当 layer = driver `.MN` direct parser (= PMDDotNET / `.MN` format 不変)

K part bytecode と R command bytecode を「同じ rhythm event」 に reduce する layer (= 軸 6 / (n2) 採用):

#### 不変保証

- PMDDotNET (= C# compile path) は完全不変
- `.MN` format / `.M` bytecode 形式は完全不変
- 既存 PMD V4.8s K bytecode + R command bytecode をそのまま emit (= PMDDotNET 既存挙動)
- driver の `.MN` direct parser layer で 2 bytecode → 1 rhythm event に collapse

#### 採用根拠

- Step 7-11 で確立した「PMDDotNET / `.MN` format 不変 + driver 側で段階拡張」 という流れと整合
- PMDDotNET と `.MN` format を触ると compile path / binary format / driver の 3 層を同時に動かすことになる
- Step 12 の目的は K/R semantics dispatch proof なので driver 側で既存 bytecode を読む方が scope が小さい
- 既存 PMD V4.8s `.M` / `.MN` compatibility にも繋がりやすい
- new rhythm event bytecode を `.MN` format に追加しない方が安全

#### ADR / handoff 記載 contract

- normalize layer = driver `.MN` direct parser
- **PMDDotNET-side normalize は scope-out**
- **new `.MN` rhythm event bytecode 追加は scope-out**
- K/R source syntax と runtime dispatch は分離
- dispatch path は K/R 共通の 1 本

### 決定 8: rhythm event observability marker = 独立 routine label `pmdneo_rhythm_event_trigger` PC hit (= memory marker byte なし、 SRAM layout 増設なし)

verify gate の literal observability 手段 (= 軸 7 / (m1) 採用):

#### marker 設計

- rhythm event hook を独立 routine として実装
- 推奨 label = `pmdneo_rhythm_event_trigger`
- K part path も R command path もこの routine を call
- PC trace で `pmdneo_rhythm_event_trigger` の addr hit を literal assert
- ymfm-trace で ADPCM-A L ch register write を literal assert
- K と R で同じ routine addr が hit することを verify

#### 採用根拠

- Step 9-11 の独立 routine pattern (= `pmdneo_resolve_sample_table_id` / `pmdneo_select_sample_pointer`) と整合
- K と R が同じ dispatch path を通ったことを、 同じ PC addr hit で証明できる
- SRAM に観測専用 marker byte を増やさずに済む
- proof minimum 性を保てる
- future の rhythm marker state / debug state を先取りしないで済む

#### ADR / handoff 記載 contract

- rhythm event observability marker = **routine PC hit**
- memory marker byte は **持たない**
- SRAM layout は Step 12 では **増やさない**
- PC trace + ymfm-trace の **二段 gate** で proof する
- K/R source path は別でも runtime dispatch routine は同一

### 本質再確認 (= 決定 9 verify gate 設計前の purpose reminder、 future contributor 向け literal 明記)

**Step 12 の目的は K/R full compatibility ではなく、 K/R semantics が PMDNEO native ADPCM-A trigger に届くことの proof である**。 具体的には:

- ✅ Step 12 で達成: K part 1 pattern + R command 1 form が driver `.MN` direct parser で normalize され、 独立 routine `pmdneo_rhythm_event_trigger` 経由で ADPCM-A L ch に audible に dispatch されることの literal 観測 (= b-only proof、 driver-embedded fixture、 L ch scaffold、 PC trace + ymfm-trace 二段 gate)
- ✗ Step 12 で達成しない: full K/R 6 drum compatibility / OPNA rhythm register fake API / `.PNE` rhythm bank integration / 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation / `.PPC` / `.P86` / ADPCM-B subsystem / PMDDotNET 改造 / `.MN` format new bytecode / 複数 drum 同時打ち / pattern loop / velocity 等

future contributor が Step 12 完了状態を「K/R compatibility 完成版」 と誤解せず、 **「K/R semantics dispatch proof stage」** として扱えるよう本 ADR で literal 固定。 K/R compatibility 完成は本 ADR §scope-out 群を含む将来 sprint で段階的に進める。 §決定 9 以下の verify gate 設計はこの「proof stage」 という目的に整合させる (= 「complete K/R compatibility」 ではなく「observable rhythm dispatch path」 を検証する)。

### 決定 9: verify gate = trace primary + audio secondary + routine PC marker + ymfm-trace + Step 11 規律踏襲

Step 12 の verify gate 構造 (= [[feedback-refactor-gate-register-trace-not-wav]] 整合):

#### primary gate = PC trace (= routine label addr hit)

K fixture run / R fixture run それぞれで:

- PC trace に `pmdneo_rhythm_event_trigger` の addr が **literal に出現** することを assert
- K fixture run と R fixture run で **同じ addr が hit** することを assert (= 共通 dispatch routine 証明)

#### primary gate = ymfm-trace (= ADPCM-A L ch register write)

K fixture run / R fixture run それぞれで:

- ADPCM-A L ch addr regs (= 0x10/0x18/0x20/0x28) に **rhythm sample (= BD) の literal addr 値** が書込まれることを assert
- L ch keyon trigger (= 0x00 reg、 mask=0x01) が発火することを assert
- K fixture run と R fixture run で同じ register write sequence (= 同 sample addr) が出ることを assert

#### secondary gate = audio (= user 試聴、 δ で実施)

- K fixture audible OK (= BD 音色が鳴る)
- R fixture audible OK (= BD 音色が鳴る、 K と同 sample)
- 両 fixture で silent 経路に倒れていない ear 確認
- silent-bcef 等の既存 audio isolation fixture との regression なし

#### regression gate = 既存 Step 5/6/7/8/9/10/11 verify script 群

既存 14 script (= Step 5 4 件 + Step 6 1 件 + Step 7 4 件 + Step 8 1 件 + Step 9 1 件 + Step 10 1 件 + Step 11 1 件 + 計 14 件) 全件 PASS 維持。 driver source 改修 (= 新規 routine + parser path 追加) なので regression 必須。

#### trivial verify 防止 = literal value assert

- BD addr literal (= driver-embedded rhythm fixture 内 BD sample header の具体 addr 値) を script に書込
- 「rhythm event が発火した」 だけでなく「この addr 値が L ch に書込まれる」 を literal assert
- 「PC trace に何かが hit した」 だけでなく「`pmdneo_rhythm_event_trigger` の literal addr が hit する」 を assert

これにより noise や unintended trigger で false PASS する trivial を防ぐ。

#### verify script 新設 = `verify-step12-rhythm-event.sh`

Step 9/10/11 pattern と同じく、 Step 12 専用の verify script を新設:

- 入力: K fixture (= K part 1 pattern 含む `.MN`) / R fixture (= R command 1 form 含む `.MN`) の各 ROM
- 動作: 両方を MAME headless で再生 → PC trace + ymfm-trace 取得 → routine addr hit + register write assert
- 出力: PASS / FAIL + 詳細 log

#### β/γ で trace gate に rhythm marker 必須化

β (= K part hook) / γ (= R command hook) の verify gate には、 **既存 L-Q ADPCM-A melody path と区別できる rhythm event marker** を必須で入れる:

- L-Q melody path = `adpcma_keyon_simple` 経由 (= 既存 routine、 ADR-0024 §決定 5 で確立)
- rhythm path = `pmdneo_rhythm_event_trigger` 経由 (= Step 12 で新設)
- 両 path は別 routine label を持つので PC trace で区別可能
- ADPCM-A L ch register write 自体は両 path で発生しうるが、 routine label hit で path 区別可能

#### δ で K と R の audio gate 別々

δ (= 完了統合) の audio gate は K fixture / R fixture を **別々で確認**:

- K fixture audible OK
- R fixture audible OK
- 両 fixture が同じ rhythm event dispatch path (= `pmdneo_rhythm_event_trigger`) を使っていることを PC trace で確認
- K と R で同 sample (= BD) が鳴ることを ear で確認

### 決定 10: 暫定規約 + ADR / handoff 記載 contract (= future contributor 向け literal 固定)

Step 12 で導入される暫定規約 / 命名 contract を future contributor 向けに literal 明記:

| 項目 | 内容 | 再検討契機 |
|---|---|---|
| `pmdneo_rhythm_event_trigger` 独立 routine | Step 12 で新設、 K/R 共通 dispatch hook | future drum 種拡張時も routine 境界維持、 6ch sub-allocation 等の architecture 変更時に再検討 |
| driver-embedded rhythm fixture (= BD sample 1 種 hand-write embed) | Step 12 proof 用、 driver source / `samples.inc` 配置 | `.PNE` rhythm bank migration 時に廃止または併存判断 |
| ADPCM-A L ch を rhythm 用に暫定占有 | scaffold、 L-Q melody architecture は概念上維持 | rhythm channel concept formalization / dynamic switching / 6ch sub-allocation のいずれかが起票される sprint で再検討 |
| K part syntax = PMD V4.8s 互換 + drum 種 b only | proof minimum、 K letter / drum 識別文字 `b` のみ実装 | future sprint で s/c/h/t/r 段階追加 |
| R command syntax = PMD V4.8s 互換 + drum 種 b only | proof minimum、 melody part 内 inline trigger 1 form のみ | future sprint で複数 drum 種 / 多 form 拡張 |
| K と R は同じ rhythm event hook に collapse | dispatch path 1 本化 | drum 種拡張で dispatch path は増やさない |
| normalize layer = driver `.MN` direct parser | PMDDotNET / `.MN` format 不変 | new bytecode 追加が必要な sprint で再検討 |
| observability marker = routine PC hit のみ | memory marker byte なし、 SRAM layout 不変 | runtime state 化 / debug instrumentation が必要な sprint で再検討 |
| audio gate = K fixture / R fixture 別々 | secondary gate、 user 試聴 OK | drum 種拡張時も同 pattern (= 各 fixture で audible 確認) |

### 決定 11: sub-sprint 分割 = ADR + α/β/γ/δ 5 commit chain (= Step 11 pattern 踏襲)

Step 12 を **ADR + α/β/γ/δ の 5 sub-sprint 構造** で進める。 Step 11 の commit chain (= `bc60663` / `ead638f` / `a02a696` / `12b7b89` / `64fa17d`) と同じ pattern を踏襲し、 future contributor mental model を維持する。

#### sub-sprint table

| sub | 範囲 | primary gate |
|---|---|---|
| ADR Draft | ADR-0026 起票 (= 本 commit、 13th session 冒頭壁打ち 7 軸 + §決定 11 件 + sub-sprint 分割 + scope-out 明示) (= **本 commit**) | doc only、 driver source 不変 |
| α | K/R bytecode + legacy K/R routine 調査 + 既存 PMDDotNET K/R emit 状況確認 + Step 12 proof fixture に必要な最小 bytecode sequence 整理 + ADR-0026 §補助 doc (= 調査結果 literal 反映) | driver source / `.MN` format / PMDDotNET 完全不変 (= pure 調査、 ADR doc 更新のみ) + 既存 14 script regression PASS + 調査結果が ADR §補助 doc に literal 反映 |
| β | `pmdneo_rhythm_event_trigger` 独立 routine 新設 (= dead-code-first 規律は同 commit 内で literal 分離せず、 hook 定義 + K part bytecode parser から caller 接続を 1 commit で完結) + driver-embedded rhythm fixture (= BD sample 1 種 hand-write embed) + K fixture (= K part 1 pattern 含む `.MN`) 新規追加 | build PASS + K fixture run PC trace で `pmdneo_rhythm_event_trigger` addr hit + ADPCM-A L ch register write (= BD addr literal) + 既存 14 script regression PASS (= L-Q melody fixture 不変) + L-Q melody との audio 衝突回避 confirmed |
| γ | R command bytecode parser path から `pmdneo_rhythm_event_trigger` への接続追加 + R fixture (= melody part 内 R command 1 form 含む `.MN`) 新規追加 | build PASS + R fixture run PC trace で `pmdneo_rhythm_event_trigger` addr hit (= β と同じ addr) + ADPCM-A L ch register write (= K fixture と同 sample addr) + 既存 14 script regression PASS + K と R で同 routine addr hit literal 比較 |
| δ | `verify-step12-rhythm-event.sh` 新設 (= K fixture / R fixture 比較 differential proof script、 routine PC hit literal + BD addr literal assert) + 全 regression + K fixture audible / R fixture audible (= user 試聴) + ADR-0026 Accepted 移行 + handoff doc 起票 + memory `project_pmdneo_step12_complete.md` 起票 + MEMORY.md index 更新 | 全 sub primary gate PASS + 既存 14 script + 新 step 12 script 計 15 script PASS + K + R audible OK |

#### β の dead-code-first 規律扱い

β は内部的に「hook routine 新設」 + 「K parser から caller 接続」 の 2 段だが、 **同 commit で完結** とし dead-code-first 規律は **literal 分離しない**。 これは ADR-0025 β (= commit `a02a696`、 selector 拡張) と同じ規模感 (= 1 routine 改修で 1 behavior change)、 routine 新設 + caller 接続を分けると commit 数が増える割に observable state が薄いため。 handoff には「hook routine と K parser 接続は同一 commit。 dead-code-first は今回 literal 分離しない」 を明記する。

#### γ の dispatch path 共通化 confirm

γ では「R command path から hook 接続」 のみで、 hook routine 自体は β で確定済。 γ の verify gate は「K fixture と R fixture で同じ `pmdneo_rhythm_event_trigger` addr が PC trace に hit する」 ことを literal 比較で証明する (= ADR-0026 §決定 6 「dispatch path 1 本化」 の literal 証跡)。

#### 1 sub = 1 commit + 1 push 規律

[[feedback-push-per-commit]] / [[feedback-post-commit-push-report-format]] を維持。 各 commit で user 都度レビュー待ち。

#### 分割根拠

- ADR Draft commit を separate にすることで Step 11 pattern と完全一致、 future contributor mental model 維持
- α は pure 調査 (= driver code 不変、 ADR §補助 doc 更新のみ) で trivial verify (= 既存 path で false PASS) を detect しやすい
- β で hook 新設 + K path 接続により K fixture run で初めて `pmdneo_rhythm_event_trigger` addr hit、 audible 差分が出る
- γ で R command path 接続により R fixture run で同 addr hit、 dispatch path 1 本化が literal 観測可能
- δ で literal value assert script を新設 + regression + user 試聴 + Accepted 移行で完了統合

## scope-in / scope-out 明示

### scope-in (= Step 12 本 sprint 範囲)

- ADR-0026 起票 (= 単独 commit、 13th session 冒頭壁打ち 7 軸 + §決定 11 件 + sub-sprint 分割 + scope-out 明示) (= **本 commit**)
- K/R bytecode + legacy K/R routine 調査 + ADR §補助 doc 更新 (= α)
- `pmdneo_rhythm_event_trigger` 独立 routine 新設 (= β)
- driver-embedded rhythm fixture (= BD sample 1 種 hand-write embed) (= β)
- K fixture (= K part 1 pattern 含む `.MN`) 新規追加 (= β)
- K part bytecode parser path から `pmdneo_rhythm_event_trigger` への接続 (= β)
- R command bytecode parser path から `pmdneo_rhythm_event_trigger` への接続 (= γ)
- R fixture (= melody part 内 R command 1 form 含む `.MN`) 新規追加 (= γ)
- `verify-step12-rhythm-event.sh` 新設 (= K + R differential proof script、 routine PC hit + BD addr literal assert) (= δ)
- 既存 14 script regression 全件確認 (= α/β/γ/δ 通じて)
- MAME 試聴で K fixture audible / R fixture audible 確認 (= δ)
- Step 12 完了統合 handoff doc + ADR-0026 Accepted 移行 + memory + MEMORY.md index (= δ)

### scope-out (= Step 12 範囲外、 後続 sprint で扱う)

- s/c/h/t/r 残り 5 drum 種 compatibility (= future sub-sprint、 dispatch path は不変で drum 種 mapping table 拡張のみ)
- OPNA rhythm sound source register (= 0x10-0x18) fake API (= PMDNEO は YM2610(B)、 emulation は方針外)
- `.PNE` rhythm bank integration (= `sample_table_id` id=0x02 rhythm bank、 generated rhythm sample directory)
- L ch 恒久占有 / L-Q melody architecture 縮小 (= scaffold のみ、 最終 channel allocation は future sprint)
- 動的 channel allocation (= K active 判定 + context switching)
- rhythm channel 新概念 (= PMDNEO 独自 part letter 追加、 S ch 等)
- 6ch drum sub-allocation (= drum 種別 ↔ ADPCM-A ch 固定 mapping、 OPNA rhythm source semantics 復元)
- 複数 drum 同時打ち (= BD + SD 同時打ち等)
- K pattern loop / pattern macro / velocity / volume / pan per drum
- OPNA native rhythm timing fidelity (= OPNA rhythm の timing / mixing / overlap fidelity、 Step 12 は dispatch proof であり完全 timing compatibility ではない、 future contributor 向け literal 明記)
- PMDDotNET (= C# compile path) 改造
- `.MN` format new bytecode 追加
- selected pointer runtime state cache (= A2 / A3、 ADR-0024 §決定 6 / ADR-0025 §決定 1 維持)
- mismatch silent flag micro-sprint
- bank switching / multi-`.PNE`
- runtime `.PNE` parser
- D1 → D3 generated directory migration
- dynamic reload (= 動的 `.PNE` 差替)
- memory marker byte / SRAM layout 拡張
- `.PPC` / `.P86` / ADPCM-B subsystem (= 別 subsystem、 PMDNEO ADPCM-A subsystem architecture と分離維持)
- 新規 sample 追加 (= WAV import / ADPCM-A 変換 UI、 WebApp Phase 4 領域)
- 未追跡 wav 3 件 (= `lefthook.wav` / `lightbulbbreaking.wav` / `woosh.wav`) (= Step 12 では touch しない、 handoff で「not used」 明記)
- mc compiler / vromtool.py / converter / `samples.inc` 大規模改修
- PPZ compatibility mode
- FM-Towns-style rhythm mode
- 3 table 以上の multi-table 化 (= ADR-0025 §scope-out 維持)
- explicit id field 化
- duplicate filename 処理
- `adpcma_keyon_simple` 全体 refactor (= ADR-0019 / ADR-0024 / ADR-0025 §scope-out 維持)
- PMDNEO.s + nullsound integration

## 完了判定

### Step 12 全体完了判定 (= ADR-0026 Accepted 移行条件)

1. **ADR**: ADR-0026 draft file 起票 (= 章 1-5 全章記述、 Annex は δ で追記) + commit + push (= **本 commit 範囲**)
2. **α**: K/R bytecode + legacy K/R routine 調査結果 + 既存 PMDDotNET K/R emit 状況 + Step 12 proof fixture 必要 bytecode sequence を ADR §補助 doc に literal 反映 + commit + push
3. **α**: driver source / `.MN` format / PMDDotNET 完全不変確認 + 既存 14 script regression 全 PASS
4. **β**: `pmdneo_rhythm_event_trigger` 独立 routine 新設 + driver-embedded rhythm fixture (= BD) + K fixture 新規 + K part bytecode parser から hook 接続 + commit + push
5. **β**: build PASS + K fixture run PC trace で `pmdneo_rhythm_event_trigger` addr hit + ADPCM-A L ch register write (= BD addr literal) + 既存 14 script regression PASS + L-Q melody fixture 不変
6. **γ**: R command bytecode parser path から `pmdneo_rhythm_event_trigger` 接続 + R fixture 新規 + commit + push
7. **γ**: build PASS + R fixture run PC trace で β と同 routine addr hit + ADPCM-A L ch register write (= K fixture と同 sample addr) + 既存 14 script regression PASS
8. **δ**: `verify-step12-rhythm-event.sh` 新設 (= differential proof script、 routine PC hit + BD addr literal assert) + commit + push
9. **δ**: user 試聴 (= K fixture audible / R fixture audible) + ADR-0026 Accepted 移行 + handoff doc 起票 + commit + push
10. **δ**: memory `project_pmdneo_step12_complete.md` 起票 + MEMORY.md index 更新

### sub-sprint 完了判定 (= 個別)

各 sub-sprint の完了判定は handoff doc に記述。 全 sub-sprint で「1 sub = 1 commit + 1 push + user 都度レビュー待ち」 規律を遵守。

## verify gate 構成

### ADR Draft gate (= doc only)

doc commit、 driver source 不変、 gate 不要 (= 既存 14 script regression は本 commit 時点でも PASS 維持)。

### α gate (= 調査 + ADR §補助 doc 更新、 3 段)

1. **driver source 完全不変確認**: `git diff` で driver source / `.MN` format / PMDDotNET の変更が一切ないことを確認
2. **既存 14 script regression PASS**: Step 5/6/7/8/9/10/11 verify script 全件 PASS (= driver 不変なので当然 PASS だが literal 確認)
3. **ADR §補助 doc literal 反映**: 調査結果 (= PMDDotNET K/R emit 状況 / standalone_test.s legacy K/R routine 状況 / PMD V4.8s K/R bytecode format / Step 12 proof fixture 必要 bytecode sequence) が ADR §補助 doc 内に literal 反映

### β gate (= K part hook、 5 段)

1. **build PASS**: sdcc / sdasz80 / lkz80 通過、 ROM .neo 生成
2. **`pmdneo_rhythm_event_trigger` routine 存在確認**: `.map` / symbol dump で新 routine が存在
3. **K fixture run PC trace で `pmdneo_rhythm_event_trigger` addr hit**: K fixture (= K part 1 pattern 含む `.MN`) を MAME headless で再生、 PC trace に新 routine の addr が **literal に出現** することを assert
4. **K fixture run ADPCM-A L ch register write**: ymfm-trace で L ch addr regs (= 0x10/0x18/0x20/0x28) に driver-embedded BD sample の literal addr 値が書込まれることを assert + keyon trigger (= 0x00 reg、 mask=0x01) 発火
5. **既存 14 script regression PASS**: L-Q melody fixture 含む既存 script 全件 PASS (= L-Q melody path 完全不変)

### γ gate (= R command hook、 5 段)

1. **build PASS**: 同上
2. **R fixture run PC trace で β と同 routine addr hit**: R fixture (= melody part 内 R command 1 form 含む `.MN`) を MAME headless で再生、 PC trace に `pmdneo_rhythm_event_trigger` addr が出現、 かつ β で確認した addr と **同一** であることを assert
3. **R fixture run ADPCM-A L ch register write**: ymfm-trace で L ch addr regs に K fixture と **同 sample addr** が書込まれることを assert (= K と R で同 sample、 共通 dispatch 証明)
4. **K と R で同 routine addr hit literal 比較**: K fixture run と R fixture run の PC trace を diff、 `pmdneo_rhythm_event_trigger` addr hit が両方に存在、 かつ同 addr であることを literal assert
5. **既存 14 script regression PASS**: 同上

### δ gate (= verify script + audible + completion、 包括)

1. **build PASS**: 同上
2. **`verify-step12-rhythm-event.sh` PASS**: differential proof script、 routine PC hit literal + BD addr literal value assert で trivial verify 防止
3. **既存 14 script regression PASS**: Step 5/6/7/8/9/10/11 全件 PASS
4. **新 step 12 script PASS**: 計 15 script PASS
5. **K fixture audible 試聴 OK** (= user)
6. **R fixture audible 試聴 OK** (= user、 K と同 sample、 BD と判別可能)
7. **silent-bcef fixture audible regression なし** (= ADR-0020 step 6-a 確立の audio isolation 維持)
8. **handoff doc 起票**: `docs/design/handoff/adr-0026-step12-completion.md`
9. **ADR-0026 Accepted 移行**
10. **memory + MEMORY.md update**: `project_pmdneo_step12_complete.md` 起票 + MEMORY.md index 更新

## 関連 memory

- `project_pmdneo_step12_direction_kr_compat.md` (= 13th session 冒頭壁打ち成果、 K/R compatibility proof sprint 採用判断 + scope 境界)
- `project_pmdneo_step11_complete.md` (= step 11 完了状態、 multi-table id=0x01 differentiation proof 成立、 ADR-0025 Accepted)
- `project_pmdneo_step11_direction_multi_table.md` (= Step 11 multi-table proof sprint 採用)
- `project_pmdneo_step11_a2_deferred.md` (= A2 selected pointer cache scope-out、 A1 per-keyon selector 継続、 Step 12 でも維持)
- `project_pmdneo_adpcma_subsystem_boundary.md` (= PMDNEO は ADPCM-A subsystem 専用、 `.PPC` / `.P86` / ADPCM-B は別 subsystem、 Step 12 scope 境界の前提)
- `project_adr_0016_step5_design_decision_2_k_part_scope_out.md` (= Step 5 で K/R を「legacy retained but inactive」 と判断、 Step 12 で「retained and reconnected under PMDNEO native mapping」 に格上げ)
- `project_pmdneo_step10_complete.md` (= step 10 完了状態、 identity → selection consumption 成立、 ADR-0024 Accepted)
- `project_pmdneo_step9_complete.md` (= step 9 完了状態、 0xFD32 identity resolver 成立)
- `project_pmdneo_step8_complete.md` (= step 8 完了状態、 runtime filename observation 成立)
- `project_pmdneo_step7_complete.md` (= step 7 完了状態、 `.PNE` asset pipeline 成立)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 Step 12 は「ADPCM-A subsystem の MML 互換 surface area の rhythm 軸への拡張」)
- `project_pmdneo_step6_complete.md` (= step 6 完了状態、 audio isolation 戦略、 silent-bcef fixture 流用)
- `project_pmdneo_step5_complete.md` (= step 5 完了状態、 ADPCM-A 6ch native path、 既存 keyon path 改修対象)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 Step 12 で PC trace + ymfm-trace 二段)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 検出 + 補正 commit 規律、 α dead 調査 → β K hook → γ R hook の段階分離が直接対応)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除、 K/R fixture で L-Q melody との衝突回避)
- `feedback_verify_script_serial_execution.md` (= verify script 群は serial 実行、 δ で適用)
- `feedback_codex_implementation_review.md` (= Codex 実装の Claude Code 側 review 義務、 Step 12 で Codex 経由実装があれば適用)

## 関連 doc

- ADR-0016 §決定 2 (= step 5 設計判断 2、 K/R rhythm compat は legacy retained but inactive、 本 ADR で「retained and reconnected」 に格上げ)
- ADR-0016 §決定 6 (= 全 step 完了後の検証 infra 強化)
- ADR-0019 §決定 3 (= sample addr は build 時 embed、 本 ADR §決定 3 driver-embedded rhythm fixture で同流儀適用)
- ADR-0021 §Accepted 後の重要境界 (= runtime resolution は Step 8 以降、 `.PNE` asset pipeline、 本 ADR で migration path 候補)
- ADR-0022 §Accepted 後の重要境界 (= driver は filename を読めるが解決していない)
- ADR-0023 §決定 11 (= ADR-0024 §決定 7 で解除済、 本 ADR では sample_table_id は無関係)
- ADR-0024 §決定 4 (= 中間 routine ABI、 本 ADR §決定 8 で `pmdneo_rhythm_event_trigger` 独立 routine と同規律)
- ADR-0024 §決定 6 (= selected pointer runtime state は持たない、 本 ADR で継続維持)
- ADR-0025 §決定 1 (= A2 cache scope-out 維持、 本 ADR で継続維持)
- ADR-0025 §scope-out (= K/R rhythm compatibility 現役接続 を Step 12 候補として温存、 本 ADR で実行)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様、 α 調査で参照)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止 / §「記憶は AI に、 判断は自分が握る」 / §Codex 実装の Claude Code 側 review 義務

## 次 sprint 候補

1. **α 着手 (= 本 commit 直後)** (= K/R bytecode + legacy K/R routine 調査 + ADR §補助 doc literal 反映、 driver code 不変)
2. β 着手 (= `pmdneo_rhythm_event_trigger` 独立 routine 新設 + driver-embedded rhythm fixture + K fixture + K part bytecode parser hook 接続、 1 commit)
3. γ 着手 (= R command bytecode parser path から hook 接続 + R fixture、 dispatch path 1 本化 literal 観測)
4. δ 着手 (= `verify-step12-rhythm-event.sh` 新設 + regression + audible + 完了統合 + Accepted 移行)
5. **Step 13 候補** (= 本 ADR scope-out のうち未消化):
   - drum 種拡張 (= s/c/h/t/r の追加、 dispatch path は 1 本のまま drum 種 → sample pointer mapping のみ拡張)
   - `.PNE` rhythm bank migration (= driver-embedded fixture → `.PNE` 経由 `sample_table_id` id=0x02 rhythm bank)
   - rhythm channel concept formalization (= K part / R command の channel allocation 最終仕様)
   - 動的 channel allocation / multi-drum 同時打ち
   - 6ch drum sub-allocation (= OPNA rhythm source semantics 復元、 K/R subsystem fully realized)
   - selected pointer cache (= A2 / A3、 動的化局面で再検討)
   - mismatch silent flag micro-sprint
   - D3 generated directory migration
   - runtime `.PNE` parser / multi-`.PNE` switching / bank switching
   - `.PPC` / `.P86` / ADPCM-B subsystem 起票 (= 別 subsystem、 PMDNEO architecture 拡張)
