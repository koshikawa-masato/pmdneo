# ADR-0032: Step 18 — simultaneous trigger semantics proof (= multi-bit bitmap dispatch latent semantics 証明 / driver 改修ゼロ / pmdneo_rhythm_event_trigger @ 0x1126 invariant 6 drum + multi-bit 状況下で維持 / BD-anchor pair proof 5 件 + 0x3F full-boundary proof / drum semantics naming → bitmap semantics naming 転換点 / simultaneous dispatch ≠ simultaneous audio mixing 境界明示)

- 状態: **Draft** (= 2026-05-15 20th session α 起票、 ADR/β/γ/δ 4 commit chain 完成後に Accepted 移行予定、 注: ADR-0030 / ADR-0031 同型 sub-sprint 4 段表のうち α 段は本 commit に統合 = PMDDotNET mc.cs L9691-9725 各 drum bitmap value literal 確認済 + L9727-9755 rs00() OR 蓄積 path literal 確認済 + L9540-9552 rhycom() dispatch loop literal 確認済を ground truth として α phase 1 で取得済)
- 起票日: 2026-05-15
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0031 (= step 17 K/R drum kind expansion proof — i = RIM、 §決定 8 「dispatch path は drum 種拡張で増やさない」 + §決定 2 「b+s+c+h+t+i = full 6 drum」 + scope-out 「simultaneous trigger semantics proof = future Step 18 候補」 を本 ADR で **drum 種拡張軸とは別軸 (= semantics 拡張軸)** として独立消化 = full 6 drum 状況下で multi-bit bitmap dispatch の latent semantics 証明)、 ADR-0030 (= step 16 K/R drum kind expansion proof — t = TOM、 §決定 8 「dispatch path は drum 種拡張で増やさない」)、 ADR-0029 (= step 15 K/R drum kind expansion proof — c = CYM)、 ADR-0028 (= step 14 K/R drum kind expansion proof — h = HH)、 ADR-0027 (= step 13 K/R drum kind expansion proof — s = SD、 §Annex A-1 で `\r` ≠ RIM literal 訂正)、 ADR-0026 (= step 12 K/R rhythm compatibility proof、 §決定 6 「dispatch path 1 本化」)、 ADR-0025 (= step 11 multi-table id=0x01 proof)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed)、 ADR-0016 (= step 5 §決定 2 K/R legacy retained but inactive → step 12 で reconnected → step 13-17 で b/b+s/b+s+h/b+s+c+h/b+s+c+h+t/b+s+c+h+t+i drum kind 段階拡張 = full 6 drum completion → 本 ADR で **drum 種拡張軸完成後の semantics 拡張軸初段** へ移行)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/manual/PMDMML_MAN_V48s_utf8.txt` (= PMD V4.8s K part / R command syntax 仕様、 連続 drum command `\b\s` 等 syntax で multi-bit bitmap OR 蓄積される PMDDotNET implementation 由来、 manual L228 `\br\tr\tr\tr` 用例 = 単 drum 連続用例で multi-bit 同時打ち用例は manual 内に literal 用例なし = mc.cs rs00() のみが ground truth、 本 ADR §Annex A-2 で literal 引用)

## 背景

Step 12-17 (= ADR-0026 から ADR-0031 まで、 2026-05-14 から 2026-05-15 まで、 13-19th session で完成、 5 commit chain x 6 step) で **drum 種拡張軸 sprint chain** が完了した:

- Step 12 (ADR-0026): K/R rhythm compatibility proof — b-only (= BD 単独 dispatch path 1 本化)
- Step 13 (ADR-0027): K/R drum kind expansion proof — s (= b+s = BD+SD 2 drum)
- Step 14 (ADR-0028): K/R drum kind expansion proof — h (= b+s+h = 3 drum)
- Step 15 (ADR-0029): K/R drum kind expansion proof — c (= b+s+c+h = 4 drum)
- Step 16 (ADR-0030): K/R drum kind expansion proof — t (= b+s+c+h+t = 5 drum)
- Step 17 (ADR-0031): K/R drum kind expansion proof — i (= b+s+c+h+t+i = **full 6 drum** = full PMD rhythm drum set completion)

ADR-0026 §決定 6 / ADR-0027-0031 §決定 8 で確立した「**dispatch path は drum 種拡張で増やさない**」 contract は、 Step 12-17 で `pmdneo_rhythm_event_trigger` (@ 0x1126) entry addr が 12 fixture (= K/R x 6 drum) 下で完全同一 literal 維持 + 各 drum sub-routine の register write sequence が drum 種ごとに sample addr literal differ するが sequence 構造完全不変 + BD-anchor N-1 pair gate (= BD-vs-SD / BD-vs-HH / BD-vs-CYM / BD-vs-TOM / BD-vs-RIM) で N 軸 mutual differential が推移的に確立、 という形で **6 drum 段で literal 実装的に保証** された。

Step 17 完了統合 (ADR-0031 §決定 / Accepted 移行 commit `de65f86`) で **drum 種拡張軸 sprint chain (= Step 12-17) 完成 milestone** が確定し、 next sprint は drum 種拡張軸とは **別軸** へ移行する判断が user 主導で確立した (= ADR-0031 §Annex「next = drum 種拡張軸完了で別軸へ移行 (= simultaneous trigger semantics proof / table-driven dispatch refactor / .PNE rhythm bank migration / #PCMFile integration / K/R 制御 cmd 現役化 等)」 literal)。

Step 18 はその「別軸」 の初段として **simultaneous trigger semantics proof** を扱う:

- 「**multi-bit bitmap dispatch の semantics を formal 化する**」 (= 例 0x03 BD+SD / 0x09 BD+HH / 0x3F 全 6 drum 同時)
- 「**driver source 改修ゼロ**」 (= 現実装の自然 dispatch (= bit 0 → bit 5 順次 call nz 連鎖) が **既に multi-bit bitmap semantics を structurally 持っている** ことの literal 観測)
- 「**latent semantics の証明**」 (= 新機能追加ではなく、 既に存在していた dispatch 構造の semantic 化)
- 「**dispatch path は simultaneous trigger でも増やさない**」 new invariant 確立 (= 「drum 種拡張で増やさない」 invariant に並ぶ第 2 invariant)
- 「**simultaneous dispatch ≠ simultaneous audio mixing**」 境界明示 (= L ch scaffold 1 本下での last-write-dominant observation は expected behavior、 true audio mixing / multi-channel allocation は future sprint)

ADR-0031 §決定 11 (= scope-out 36+ 項目維持) の延長で、 driver Z80 source は完全不変、 multi-bit fixture (= 12 件新規) + verify script (= 12 件新規) のみ追加する小規模 proof sprint。 「simultaneous trigger semantics proof」 という言葉自体が示すように、 audio mixing 改定 / channel allocation 改定 / `.PNE` rhythm bank migration / dispatch table-driven refactor / 制御 cmd 現役化軸は触らない。

ただし「multi-bit dispatch proof」 と素朴に定義すると scope が再び肥大化する (= true simultaneous audio mixing 一気 / multi-channel allocation 一気 / priority semantics / voice stealing / 全 63 combo full proof / table-driven refactor 一気 等を同時に触る)。 19th session 末 user 直接指示 + 20th session 冒頭壁打ちで以下の方針整理が確定 (= 5 軸壁打ち全 A 案合意):

- **multi-bit bitmap dispatch 許可 + 現自然 dispatch (= 複数 `call nz` 連鎖) semantics 化** (= 軸 1)
- **bitmap ascending dispatch order (= bit 0 → bit 5 順固定) semantics 化** (= 軸 2)
- **L ch scaffold 維持 + 同一 channel 上書き keyon 許可 + last-write-dominant observation = expected behavior** (= 軸 3)
- **BD-anchor pair proof 5 件 (= BD+SD/BD+CYM/BD+HH/BD+TOM/BD+RIM) + 0x3F full-boundary proof + middle-width combo は induction** (= 軸 4)
- **audio gate = listen-step18.sh + sleep 3 + loop + K/R pair comparison + representative pair + 0x3F、 3 項目 judgement (= silent でない / K-R 同音 / last-write-dominant)** (= 軸 5)
- **fixture naming = bitmap hex pattern (= `k03` / `k05` / `k09` / `k11` / `k21` / `k3f`) + drum semantics naming からの転換点 = Step 18 sprint chain 軸転換 milestone** (= 軸 5 派生)
- **dispatch 構造 = driver source 完全不変 (= Step 17 hybrid pattern そのまま、 table-driven refactor scope-out 維持)** (= 軸 1 派生)

これに基づき Step 18 を **「simultaneous trigger semantics proof」** として定義する。 ADR-0026 から ADR-0031 で確立した dispatch path 1 本化 invariant を **multi-bit bitmap 状況下で literal 維持** することの proof であり、 「**dispatch path は simultaneous trigger でも増やさない**」 が Step 18 で multi-bit 状況下で実装的に保証される (= drum 種拡張軸 sprint chain 完成後の semantics 拡張軸初段 = sprint chain 軸転換 milestone)。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 Step 18 着手前に方針を ADR として独立起票する。

### 20th session 冒頭壁打ちでの 5 軸方針確定

ADR-0032 起票前に user 主導で 5 軸の壁打ちが行われ、 Step 18 の出口像が以下に固定された (= ADR-0026-0031 と同 pattern、 軸 1-5 全部 A 案合意、 sub-sprint は ADR-0028-0031 と同 4 段、 verify gate 構成は 7-8 段で full 6 drum completion sprint より厚め設定、 sprint chain 軸転換 milestone 反映)。

#### 軸 1: multi-bit bitmap dispatch 許可 + 現自然 dispatch semantics 化 (= A 案採用)

multi-bit bitmap (= 例 0x03 BD+SD) 受信時の dispatch:

- (a1) (= **採用**): 現 dispatch の自然な「複数 `call nz`」 連鎖を許可 + literal proof で明示的確立 (= 既存 bit 0 → bit 5 順次 `call nz` 連鎖が multi-bit 状況下で自動的に複数 sub-routine 連続実行、 driver 改修ゼロ、 literal observation で proof 完結)
- (a2) (= 不採用): priority 制で 1 bit のみ処理 (= 何らかの優先順位で 1 drum だけ trigger、 driver 改修必要、 PMD オリジナル semantics から離脱、 「semantics 拡張」 ではなく「semantics 制限」)
- (a3) (= 不採用): 別経路 routine 化 (= 単 drum と multi drum で entry を分ける、 dispatch path 1 本化 invariant 崩壊、 「dispatch path は drum 種拡張で増やさない」 と矛盾)

(a1) 採用根拠: Step 12-17 で築いた dispatch path 1 本化をそのまま流用、 driver 改修ゼロで成立、 PMD オリジナル semantics (= mc.cs rs00() OR 蓄積 path 経由で multi-bit bitmap が emit される) と完全整合、 「dispatch path は drum 種拡張で増やさない」 invariant に加えて「dispatch path は同時打ちでも増やさない」 invariant を新規確立、 Step 12-17 sub-sprint chain pattern (= ADR + α/β/γ/δ) で進めやすい、 「新機能追加」 ではなく「latent semantics の証明」 という Step 18 の identity を最も literal に表現できる。

ADR / handoff 記載要件:
- multi-bit bitmap dispatch = **許可** (= 現自然 dispatch の semantics 化)
- driver source = **完全不変** (= 改修ゼロ literal 確認、 Z80 source touch なし)
- separate multi-bit routine 不作成 (= dispatch path 1 本化 invariant 維持)
- priority 制不導入 / early-return 不導入 / bit-suppression 不導入
- 「新機能追加ではなく **latent semantics の証明**」 wording 統一 (= ADR §背景 + §決定 1 + commit message + handoff doc + memory)

#### 軸 2: bitmap ascending dispatch order (= bit 0 → bit 5 順固定) semantics 化 (= A 案採用)

multi-bit bitmap 内の各 bit の dispatch 順序 / register write 順序:

- (b1) (= **採用**): bitmap 昇順固定 (= bit 0 → bit 5) を semantics として明文化 (= 現実装の自然 dispatch 順序を formal 化、 ymfm-trace で順序 literal verify、 future refactor でも順序保持 contract)
- (b2) (= 不採用): 観察値として記録するが semantics 固定はしない (= 順序変更を将来許容、 fixture verify との関係が曖昧、 Step 12-17 literal proof 規律と不整合)
- (b3) (= 不採用): bitmap 降順 (= bit 5 → bit 0) または他の優先順 (= driver 改修必要、 自然順から離れる根拠が薄い)

(b1) 採用根拠: 現実装の自然 dispatch 順序 (= source code 上の `call nz` 並び順 = bit 0 BD → bit 1 SD → bit 2 CYM → bit 3 HH → bit 4 TOM → bit 5 RIM、 ADR-0031 §決定 で確立した bit 順序) を semantics として固定、 driver 改修ゼロで成立、 Step 12-17 literal proof 規律と最も整合、 source code order = bitmap order = register write order の 3 軸が完全一致で「綺麗」、 future contributor が dispatch 順を contract として理解可能。

ADR / handoff 記載要件:
- bitmap ascending dispatch order (= bit 0 → bit 5) を **semantics 化**
- register write sequence order も **contract**
- ymfm-trace で順序 literal verify (= multi-bit fixture で BD reg writes → SD reg writes 等の順序を literal assert)
- future refactor でも順序保持 (= table-driven refactor 等で dispatch order が変わってはならない、 ADR-0032 §決定 で literal 拘束)
- source code order = bitmap order = register write order = **3 軸完全一致**

#### 軸 3: L ch scaffold 維持 + 同一 channel 上書き keyon 許可 + last-write-dominant observation = expected behavior (= A 案採用)

同一 ADPCM-A ch (= L ch scaffold 1 本) に複数 drum が連続 keyon された時の挙動:

- (c1) (= **採用**): priority なし + 「現実装挙動 = L ch 1 本順次上書き keyon」 を observed value として ADR に記録 + last-write-dominant observation = expected behavior 明文化 (= 軸 1 priority 制不導入と整合、 L ch scaffold ADR-0030 等維持規律下での実観察を literal 記録、 「simultaneous dispatch ≠ simultaneous audio mixing」 境界明示)
- (c2) (= 不採用): 何らかの drum priority 導入 (= BD 最優先 / RIM 最優先 / bitmap LSB 優先、 軸 1 と矛盾)
- (c3) (= 不採用): L ch scaffold を multi-ch allocation に拡張 (= channel allocation semantics 軸へ踏み込む、 「semantics 拡張」 を「scaffold 解除」 と同時に行うのは scope 肥大化、 別 sprint へ分離)

(c1) 採用根拠: 軸 1 priority 制不導入と整合、 現実装の自然挙動を semantics として固定、 driver 改修ゼロ、 Step 12-17 literal observation 規律延長、 「同時音響」 と「同時 dispatch」 を切り分け可能、 simultaneous dispatch (= scope-in) ≠ simultaneous audio mixing (= scope-out) 境界明示が Step 18 中核 wording として確立、 future contributor が「BD+SD なのに SD しか聞こえない、 bug?」 と誤認するのを ADR / audio gate doc で防止可能。

ADR / handoff 記載要件:
- L ch scaffold 維持 (= ADR-0030 §Annex 等継続)
- multi-bit dispatch は **順次 register write semantics** (= bitmap 昇順 sub-routine 連続実行 + 各 sub-routine 内 register write sequence)
- 同一 channel 上書き keyon 許可 (= 同一 L ch に sample addr / vol / pan / keyon mask が後勝ちで上書き)
- **last-write-dominant observation = expected behavior** (= bitmap 末尾 drum が聴感的に支配的、 bug ではなく L ch scaffold 自然結果、 ADR + audio gate doc 両方で明文化)
- **simultaneous dispatch ≠ simultaneous audio mixing** 境界明示 (= ADR §決定 8 中核 wording、 §scope-out 中核、 commit message + handoff doc + memory 統一表記)
- true simultaneous audio mixing = **未実装 / 未定義 / future sprint**
- multi-channel allocation = **future sprint** (= L ch scaffold 解除 + 動的 ch 割当)
- voice stealing / exact OPNA timing fidelity / cycle-level scheduling = **scope-out**

#### 軸 4: BD-anchor pair proof 5 件 + 0x3F full-boundary proof + middle-width combo は induction (= B 案採用)

multi-bit combo proof 範囲:

- (d1) (= 不採用): minimum proof = 0x03 (BD+SD) + 0x3F (全 6 drum) のみ + K/R 両系統 4 fixture (= 最小 multi-bit + max multi-bit で induction 主張、 中間 combo 隠れ regression 捕捉不可)
- (d2) (= **採用**): BD-anchor pair 5 件 (= BD+SD / BD+CYM / BD+HH / BD+TOM / BD+RIM) + 0x3F 全 6 drum simultaneous + K/R 両系統 12 fixture (= Step 12-17 N-1 pair gate pattern 踏襲、 middle 4-bit combo は induction 規律、 約 12 verify script 新規 = Step 17 5 件と同等規模、 audio gate も 12 wav で listen-step18.sh 同梱)
- (d3) (= 不採用): 2-bit 全 15 combo (= 6C2 完全網羅) + 0x3F + K/R 両系統 32 fixture (= combinatorial complete on 2-bit、 regression 時間肥大化、 diminishing returns)
- (d4) (= 不採用): 全 63 combo full literal proof + K/R 両系統 126 fixture (= combinatorial complete on all bit-widths、 over-engineering、 「最小で十分 + induction で外挿」 規律と矛盾)

(d2) 採用根拠: Step 12-17 N-1 pair gate pattern (= BD を anchor に各 drum との pair で推移的 proof) を simultaneous 軸で踏襲、 minimum / maximum boundary 両方押さえる (= 2-bit + 6-bit full)、 middle-width combo (= 3-bit / 4-bit / 5-bit) は dispatch path + bitmap 昇順順次 write が 2-bit pair で全 5 件 + 6-bit full で成立すれば induction で同 pattern 自動成立、 約 12 verify script で Step 17 5 件と同規模、 listen-step18.sh 12 wav で convention 踏襲、 sprint chain 自然延長、 「combinatorial explosion を避けつつ boundary 押さえる」 verify philosophy 確立。

ADR / handoff 記載要件:
- proof 範囲 = **BD-anchor pair 5 件 + 0x3F full-boundary**
- BD-anchor pair = **representative pairwise semantics** (= BD+SD = 0x03 / BD+CYM = 0x05 / BD+HH = 0x09 / BD+TOM = 0x11 / BD+RIM = 0x21)
- 0x3F = **full-boundary proof** (= 全 6 drum simultaneous = upper bound literal proof)
- middle-width combo (= 3-bit / 4-bit / 5-bit) = **induction** (= 2-bit pair + 6-bit full で N+1 bit case が同 pattern 自動成立)
- exhaustive combinatorial matrix (= 全 63 combo full proof) = **scope-out**
- fixture 数 = 12 件 (= K-0x03 / R-0x03 / K-0x05 / R-0x05 / K-0x09 / R-0x09 / K-0x11 / R-0x11 / K-0x21 / R-0x21 / K-0x3F / R-0x3F)
- verify script 数 = 約 12 件 (= 5 BD-anchor pair x 2 K/R = 10 件 + 0x3F K/R = 2 件)

#### 軸 5: audio gate = listen-step18.sh + 3 項目 judgement (= A 案採用)

audio gate (= MAME 録音 + user 試聴 judgement):

- (e1) (= **採用**): Step 16/17 convention 踏襲 + listen-step18.sh + user 試聴 judgement + 「last-write-dominant = expected」 を ADR / audio gate doc 明文化 (= 12 wav + sleep 3 + 無限繰り返し、 3 項目 judgement、 future contributor confusion 防止)
- (e2) (= 不採用): trace gate only + audio gate scope-out (= CLAUDE.md driver/runtime touch 動作確認義務と矛盾、 Step 12-17 規律から外れる)
- (e3) (= 不採用): full audio sequence observation (= 「BD then SD」 順序を聴感識別、 L ch scaffold 物理的に不可能、 last-write-dominant と矛盾)
- (e4) (= 不採用): regression-only audio gate (= 既存 Step 12-17 fixture 再生のみ、 新規 multi-bit 聴感を省略、 中間案として保守的だが Step 18 新規 semantics の audio judgement 機会を失う)

(e1) 採用根拠: Step 12-17 listen-stepNN.sh convention 踏襲、 3 項目 judgement (= 後述) で multi-bit dispatch の audio literal 確立、 last-write-dominant expected behavior 明文化で future contributor 誤認回避、 CLAUDE.md 動作確認義務遵守、 「simultaneous dispatch = scope-in / simultaneous audio mixing = scope-out」 境界が audio gate でも明示される。

audio gate 3 項目 judgement:

1. **multi-bit fixture が silent ではない** (= dispatch が動いている literal 聴感)
2. **K-multi-bit と R-multi-bit が同音** (= K/R 同 dispatch 規律延長、 ADR-0026 §決定 6 dispatch path 1 本化 invariant の multi-bit 状況下での維持)
3. **bitmap 末尾 drum が支配的に聴こえる** (= last-write-dominant observation literal、 例: 0x03 → SD 支配 / 0x3F → RIM 支配)

#### fixture naming = bitmap hex pattern (= drum semantics naming からの転換点、 軸 5 派生)

fixture 命名:

- (f1) (= **採用**): hex bitmap pattern (= `k03` / `k05` / `k09` / `k11` / `k21` / `k3f` / `r03` / `r05` / `r09` / `r11` / `r21` / `r3f`) + drum semantics naming からの転換点として明文化
- (f2) (= 不採用): drum semantics naming 継続 (= `k-bd-sd-only.mml` / `r-melody-bd-cym-only.mml` 等、 multi-bit で命名爆発)
- (f3) (= 不採用): hybrid naming (= 2-bit は semantics / 0x3F は hex、 一貫性なし)

(f1) 採用根拠: single drum 時代の drum-centric semantics (= `k-br-only.mml` / `k-sr-only.mml` 等) は simultaneous semantics で命名爆発 (= `k-bd-sd-hh-rim-only.mml` 等)、 bitmap semantics が本質なので fixture 名に bitmap 値を直接反映、 「何 bit が立っているか」 が一目瞭然、 Step 12-17 single drum expansion → Step 18 simultaneous semantics への **phase transition を naming でも表現** = drum semantics naming → bitmap semantics naming **転換点** = sprint chain 軸転換 milestone。

ADR / handoff 記載要件:
- fixture naming = **hex bitmap pattern** (= `k03` / `k05` / `k09` / `k11` / `k21` / `k3f`)
- drum semantics naming (= `k-br-only.mml` 等 Step 12-17 流儀) からの **転換点** として明文化
- Step 12-17 = drum-centric semantics naming (= single drum expansion 期)
- Step 18+ = bitmap-centric semantics naming (= simultaneous semantics 期)
- sprint chain 軸転換 milestone (= drum 種拡張軸 → semantics 拡張軸 への移行点)
- fixture pattern 内 `kXX` / `rXX` の `XX` = 2 文字 hex bitmap value (= 0x00 - 0xFF 範囲、 PMDDotNET emit 範囲は 0x00 - 0x3F + 0x80 reserved)
- verify script naming も bitmap hex pattern 踏襲 (= `verify-step18-k03-trigger.sh` 等)

#### 軸 6 (meta): sub-sprint 構成 = ADR-0028 / ADR-0029 / ADR-0030 / ADR-0031 同型 4 段 (= ADR / β / γ / δ)

sub-sprint 構成:

- (s1) (= **採用**): 4 sub-sprint = α (= ADR-0032 Draft 起票、 doc only commit、 PMDDotNET mc.cs L9691-9725 / L9727-9755 / L9540-9552 literal 確認済を ground truth として本 commit に統合) + β (= 最小 representative multi-bit fixture `k03` / `r03` + verify script + driver 改修ゼロ literal 確認) + γ (= representative pair 4 件拡張 `k05` / `k09` / `k11` / `k21` x K/R + verify script + N-1 pair gate 推移的 proof) + δ (= 0x3F full-boundary fixture `k3f` / `r3f` + verify script + 完了統合 + listen-step18.sh + handoff doc + memory + MEMORY.md + ADR-0032 Accepted 移行)
- (s2) (= 不採用): 5 sub-sprint (= α/β/γ/δ/ε、 γ と δ を分割、 commit 粒度細かいが冗長)
- (s3) (= 不採用): 3 sub-sprint に圧縮 (= α/β/γ、 全 fixture + 全 verify を 1 commit に同梱、 PR レビュー粒度粗化)

(s1) 採用根拠: ADR-0028 / ADR-0029 / ADR-0030 / ADR-0031 と同型 4 段 = pattern 安定、 1 sub = 1 commit + 1 push 規律遵守、 audio gate は δ 前 (= γ 完了時または δ 序盤) に user 試聴、 各 sub で全 step12 + step13 + step14 + step15 + step16 + step17 BD/SD/HH/CYM/TOM/RIM path verify script PASS が確認できる粒度、 driver source 改修ゼロ前提で fixture + verify script 追加のみのため各 sub commit は doc + fixture + verify 範囲。

## 決定

### 決定 1: Step 18 を「simultaneous trigger semantics proof」 として定義 (= multi-bit bitmap dispatch latent semantics 証明、 driver 改修ゼロ、 dispatch path 1 本化 multi-bit 状況下で維持、 BD-anchor pair proof 5 件 + 0x3F full-boundary proof、 last-write-dominant observation 明文化、 simultaneous dispatch ≠ simultaneous audio mixing 境界明示、 fixture naming = bitmap hex pattern 転換点)

Step 18 の最終 deliverable boundary を **「K part 連続 `\b\s` 等 multi-bit syntax + melody part inline 連続 `\b\s` 等 multi-bit syntax の 2 系統 MML syntax を受取り、 PMDDotNET mc.cs rs00() OR 蓄積 path 経由で `0xEB <multi-bit bitmap>` 単一 bytecode に collapse され、 driver `.MN` direct parser で normalize して、 共通 routine `pmdneo_rhythm_event_trigger` (@ 0x1126) 経由で bitmap 内 active bit を bit 0 → bit 5 昇順順次 `call nz` 連鎖で各 drum sub-routine 連続実行し、 ADPCM-A L ch に bitmap 昇順順次 register write を発行 + last-write-dominant に keyon trigger に audible に dispatch する」** とする。 PMDDotNET / `.MN` format / `pmdneo_rhythm_event_trigger` routine entry / observability marker / driver-embedded fixture 規律は完全不変、 driver Z80 source は **完全不変** (= 改修ゼロ literal 確認)、 multi-bit fixture (= 12 件新規 = K/R x 6 bitmap) + verify script (= 約 12 件新規) のみ追加。 PC trace + ymfm-trace の 7-8 段 gate (= K-bitmap trigger + R-bitmap trigger + KR byte-identical + bitmap 昇順順次 write 順序 + last-write-dominant + dispatch entry invariant + 0x3F full-boundary) で **multi-bit 状況下でも dispatch path が 1 本化されていること** + **bitmap 昇順順次 register write が literal 観測されること** + **L ch 1 本 last-write-dominant が literal 観測されること** + **既存 Step 12-17 単 drum path regression が壊れていないこと** を literal 観測可能にすることを目的とする。

#### Step 17 → Step 18 拡張点

ADR-0031 で確立した contract のうち、 Step 18 で **拡張** されるのは:

- driver の bitmap accept range: 単 bit (= 0x01 / 0x02 / 0x04 / 0x08 / 0x10 / 0x20) → **multi-bit** (= 0x03 / 0x05 / 0x09 / 0x11 / 0x21 / 0x3F 等を含む 0x00-0x3F 全範囲、 bit 6-7 reserved 維持) (= driver 実装は自然 dispatch で既に accept 可能、 「latent semantics の証明」 で formal 化)
- fixture 数: 12 件 (= K/R x 6 単 drum) → 24 件 (= 12 単 drum 不変 + 12 multi-bit 新規)
- verify script 数: 34 件 → 約 46 件 (= 34 既存不変 + 12 step18 系新規)
- fixture naming: drum semantics (= `k-br-only.mml` 等 Step 12-17) → bitmap hex pattern (= `k03.mml` 等 Step 18+) = **転換点**
- invariant 数: 「dispatch path は drum 種拡張で増やさない」 → 「dispatch path は drum 種拡張で増やさない」 + 「**dispatch path は simultaneous trigger でも増やさない**」 (= 第 2 invariant 確立)
- sprint chain 軸: drum 種拡張軸 (= Step 12-17) → semantics 拡張軸 (= Step 18+) = **軸転換 milestone**

Step 18 で **不変** に保つもの:

- `pmdneo_rhythm_event_trigger` routine entry addr (= 0x1126、 ADR-0031 §決定 9 PC marker 維持) ← **primary invariant**
- `pmdneo_rhythm_event_trigger` routine 構造 (= bit 0 → bit 5 順次 `call nz` 連鎖、 末尾 tail-call、 ADR-0031 で確立した最終形)
- 全 6 drum sub-routine の register write sequence (= BD / SD / CYM / HH / TOM / RIM の各 6 件 reg write literal value 完全不変)
- 全 6 drum sub-routine entry addr (= Step 17 で確定した addr 維持、 driver 改修ゼロのため再 shift なし)
- driver Z80 source 全体 (= 改修ゼロ literal 確認、 byte-for-byte 不変)
- PMDDotNET (= C# compile path) 完全不変
- `.MN` format 完全不変
- 既存 L-Q ADPCM-A melody architecture (= ADR-0019 / ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 / ADR-0025 で確立)
- `sample_table_id` resolver / selector ABI / sentinel 0x0000 semantics / driver SRAM layout
- 既存 Step 12-17 単 drum fixture (= 12 件) 完全不変
- 既存 34 script regression PASS

#### invariant 精密化 (= ADR-0028-0031 §invariant 精密化引用 + Step 18 拡張)

**invariant の本質は「sub-routine entry addr 不変」 ではなく「shared dispatch entry 不変 + register write sequence 不変 + multi-bit 状況下でも dispatch path 1 本化維持」**:

- **shared dispatch entry 不変**: `pmdneo_rhythm_event_trigger` entry addr (= 0x1126) は Step 12/Step 13/Step 14/Step 15/Step 16/Step 17/Step 18 で完全同一 literal 維持 (= K/R 両 source path が同 entry に collapse、 単 drum + multi-bit 両 bitmap が同 entry に collapse)
- **register write sequence 不変**: 各 drum trigger sub-routine 内の 6 件 reg write は drum 種ごとに sample addr literal differ するが sequence 構造は完全不変、 multi-bit 状況下では bitmap 昇順順次連結で出現
- **multi-bit dispatch path 1 本化維持**: 「dispatch path は drum 種拡張で増やさない」 (= Step 12-17 確立) に加えて「**dispatch path は simultaneous trigger でも増やさない**」 (= Step 18 新規確立)、 single drum (= 単 bit) と multi-bit (= 複数 bit) が同 entry @ 0x1126 を通る literal proof
- **driver source 不変**: dispatcher 改修ゼロ → sub-routine entry addr 再 shift なし、 Step 17 で確定した addr が Step 18 でも維持
- verify script 側は multi-bit fixture でも単 drum fixture と同 dispatch entry hit + bitmap 昇順順次 register write を assert
- PMDDotNET (= C# compile path) は完全不変、 multi-bit bitmap emit は既存 rs00() OR 蓄積 path 経由で成立

### 決定 2: multi-bit bitmap accept range = 0x00 - 0x3F (= bit 0-5 任意組合せ accept、 bit 6-7 reserved 維持、 ADR-0031 §決定 2 bitmap accept range の multi-bit 一般化)

driver `.MN` direct parser での `0xEB <bitmap>` 受入:

- **bitmap = 0x00**: no-op (= 既存 Step 12-17 維持)
- **single-bit bitmap** (= 0x01 / 0x02 / 0x04 / 0x08 / 0x10 / 0x20): 各 drum 単独 trigger (= 既存 Step 12-17 維持)
- **multi-bit bitmap** (= 0x03 / 0x05 / 0x06 / 0x07 / 0x09 / ... / 0x21 / ... / 0x3F): 複数 drum 同時 trigger = **本 ADR で formal 化** (= bitmap 内 active bit を bit 0 → bit 5 昇順順次 `call nz` 連鎖、 各 sub-routine 内 register write sequence 連結発行、 L ch 1 本 last-write-dominant)
- **bit 6-7 set bitmap** (= 0x40 / 0x80 / 0xC0 等): reserved (= PMD bitmap 範囲外、 silent ignore 維持、 ADR-0031 §決定 2 継続)
- **bit 7 = 1** (= 0x80 系): PMDDotNET rs00() L9734 `work.al |= 0x80` で「直前 byte = rest」 表現に予約 (= 本 ADR §Annex A-2 literal 確認、 driver `.MN` direct parser では既存 silent ignore で問題なし)

#### 採用根拠

- PMDDotNET mc.cs rs00() OR 蓄積 path で 0x00 - 0x3F 範囲は emit 可能 (= 本 ADR §Annex A-2 literal 確認済)
- 現 driver 自然 dispatch (= bit 0 → bit 5 順次 `call nz` 連鎖) で 0x00 - 0x3F 範囲は accept 可能 (= latent semantics)
- bit 6-7 = reserved は ADR-0031 §決定 2 継続で silent ignore
- 「bitmap accept range 拡張」 は driver 改修ゼロで成立 (= 実装はすでに accept 可能、 ADR で formal 化のみ)

#### ADR / handoff 記載 contract

- bitmap accept range = **0x00 - 0x3F (= 64 値全部 = single + multi 全範囲)**
- bit 6-7 = **reserved + silent ignore** (= ADR-0031 §決定 2 維持)
- bit 7 = `work.al |= 0x80` 「直前 byte = rest」 PMDDotNET 内部表現に予約 (= driver では silent ignore で副作用なし)
- driver 改修 = **ゼロ** (= 実装は既に multi-bit accept 可能、 latent semantics)

### 決定 3: bitmap ascending dispatch order (= bit 0 → bit 5 順固定) を semantics 化 (= 軸 2 / 現自然 dispatch 順序の formal 化)

multi-bit bitmap dispatch 順序:

- multi-bit bitmap (= 例 0x03 BD+SD) を受信時、 driver は bit 0 → bit 5 昇順で active bit を順次処理
- 各 active bit に対応する drum sub-routine が `call nz` または tail-call で連続実行
- 結果として register write も bit 0 → bit 5 順次連結発行 (= BD reg writes → SD reg writes → CYM reg writes → HH reg writes → TOM reg writes → RIM reg writes)
- 順序 contract は ymfm-trace で literal verify (= 多 bit fixture で BD reg 値が SD reg 値より前に出現することを literal assert)

#### bitmap → register write 順序 example (= 軸 2 確定 + §Annex A-3 詳細)

- 0x03 (BD+SD) → BD reg writes (= reg 0x10/0x18/0x20/0x28/0x08/0x00 with BD literal value) → SD reg writes (= 同 reg set with SD literal value)
- 0x09 (BD+HH) → BD reg writes → HH reg writes
- 0x21 (BD+RIM) → BD reg writes → RIM reg writes
- 0x3F (全 6 drum) → BD reg writes → SD reg writes → CYM reg writes → HH reg writes → TOM reg writes → RIM reg writes (= 36 件 reg write 連結)

#### ADR / handoff 記載 contract

- bitmap ascending dispatch order = **bit 0 → bit 5 順固定**
- register write sequence order も **contract** (= ymfm-trace で順序 literal verify)
- future refactor (= table-driven dispatch refactor 等) でも順序保持 contract
- source code order = bitmap order = register write order = **3 軸完全一致**

### 決定 4: dispatch path は simultaneous trigger でも増やさない (= 新 invariant、 ADR-0026 §決定 6 / ADR-0031 §決定 8 「drum 種拡張で増やさない」 invariant に並ぶ第 2 invariant)

新 invariant:

- `pmdneo_rhythm_event_trigger` entry addr (= 0x1126) は **single-bit + multi-bit 両 bitmap で完全同一** literal 維持
- single drum fixture (= Step 12-17 既存 12 件、 単 bit bitmap) と multi-bit fixture (= Step 18 新規 12 件、 multi-bit bitmap) が **同 entry addr に collapse**
- separate multi-bit dispatch routine = **不作成** (= dispatch path 1 本化 invariant 維持、 single-bit と multi-bit で別経路 routine を新設しない)
- 「**dispatch path は drum 種拡張で増やさない**」 (= Step 12-17 確立、 第 1 invariant) + 「**dispatch path は simultaneous trigger でも増やさない**」 (= Step 18 確立、 第 2 invariant)
- 2 invariant 統合 = 「**dispatch path は drum 種拡張でも simultaneous trigger でも増やさない**」 = PMDNEO rhythm event dispatch architecture の最終 invariant

#### ADR / handoff 記載 contract

- 第 2 invariant = **「dispatch path は simultaneous trigger でも増やさない」**
- multi-bit fixture でも `pmdneo_rhythm_event_trigger` @ 0x1126 entry addr 不変 literal proof (= 12 multi-bit fixture の PC trace marker hit が単 drum fixture と同 addr literal)
- separate multi-bit routine 不作成 (= driver 改修ゼロ + dispatch path 1 本化)

### 決定 5: L ch scaffold 維持 + 同一 channel 上書き keyon 許可 + last-write-dominant observation = expected behavior (= 軸 3、 「simultaneous dispatch ≠ simultaneous audio mixing」 境界明示)

L ch scaffold (= ADPCM-A 6 ch のうち L ch 1 本のみ rhythm trigger に割当、 ADR-0030 等維持規律) 下での multi-bit dispatch 挙動:

- multi-bit fixture (= 例 0x03 BD+SD) で BD sub-routine が L ch (ch 0) に register write + keyon、 続いて SD sub-routine も L ch (ch 0) に register write + keyon
- 同一 ch で sample addr / vol / pan / keyon mask が後勝ちで上書き
- **音響的結果 = bitmap 末尾 drum が ADPCM-A L ch 出力として支配的に発音** (= last-write-dominant、 例: 0x03 → SD 支配 / 0x3F → RIM 支配)
- これは **bug ではなく L ch scaffold 自然結果** (= ADR §決定 5 + audio gate doc で expected behavior 明文化)

#### simultaneous dispatch ≠ simultaneous audio mixing 境界 (= 中核 wording)

- **simultaneous dispatch** (= scope-in): multi-bit bitmap → bit 0 → bit 5 順次 `call nz` 連鎖 → 各 sub-routine register write 連結発行
- **simultaneous audio mixing** (= scope-out): 複数 drum が同時に異なる ch で発音 + audio output で audio mixing される (= 実現には multi-ch allocation + L ch scaffold 解除が必要、 future sprint)
- Step 18 で formal 化するのは **simultaneous dispatch** のみ、 **simultaneous audio mixing** は未実装 / 未定義 / future sprint

#### ADR / handoff 記載 contract

- L ch scaffold = **維持** (= ADR-0030 §Annex 等継続)
- 同一 channel 上書き keyon = **許可** (= last-write-dominant 自然挙動)
- last-write-dominant observation = **expected behavior** (= ADR + audio gate doc + future contributor 向け literal 注記)
- **simultaneous dispatch ≠ simultaneous audio mixing** 境界 = **中核 wording** (= ADR §決定 5 + §scope-out + commit message + handoff doc + memory 統一表記)
- true simultaneous audio mixing = **未実装 / 未定義 / future sprint**
- multi-channel allocation = **future sprint**
- voice stealing / exact OPNA timing fidelity / cycle-level scheduling = **scope-out**

### 決定 6: PMDDotNET multi-bit bitmap OR emit path = mc.cs rs00() L9727-9755 で ground truth literal 確認 (= α phase 1 調査結果、 §Annex A-2 literal 引用)

PMDDotNET が multi-bit bitmap を emit する path:

- **mc.cs L9691-9725**: 各 drum function (= `bdset` / `snrset` / `cymset` / `hihset` / `tamset` / `rimset`) で `work.al = <bit value>` literal 設定 (= bit 0 = 1 / bit 1 = 2 / bit 2 = 4 / bit 3 = 8 / bit 4 = 16 / bit 5 = 32)
- **mc.cs L9727-9755**: `rs00()` 関数で **OR 蓄積 path** (= 直前 byte が `0xEB rhykey` + 直前 bitmap に rest bit (0x80) なし + `prsok = 0x80` 「直前 byte = リズム」 flag 立ち、 の 3 条件全部満たす場合に `work.al |= cch` で前 bitmap と OR 蓄積 + 直前 0xEB arg を OR 値で上書き)
- **mc.cs L9540-9552**: `rhycom()` dispatch loop (= char → drum function pointer の linear search dispatch、 `rcomtbl` 経由)
- `prsok = 0x80` flag は連続 `\b\s\h` syntax で連続 drum command 判定条件として機能
- 結果: 連続 `\b\s` syntax → `0xEB 0x03` 単一 bytecode、 連続 `\b\s\c\h\t\i` syntax → `0xEB 0x3F` 単一 bytecode

#### PMDNEO consumes the same multi-bit bitmap through existing pmdneo_rhythm_event_trigger

- PMDDotNET emits multi-bit bitmap (= `0xEB 0x03` 等) via mc.cs rs00() OR 蓄積 path
- PMDNEO `.MN` direct parser で `0xEB <bitmap>` を normalize
- PMDNEO driver `pmdneo_rhythm_event_trigger` (@ 0x1126) entry に bitmap を渡す
- 既存 dispatch 構造 (= bit 0 → bit 5 順次 `call nz` 連鎖) が **自動的に** multi-bit bitmap を処理 (= latent semantics)
- **no new bytecode** (= 0xEB rhykey 維持、 ADR-0026 §決定 4 継続)
- **no new driver entry** (= 0x1126 維持、 ADR-0026 §決定 6 継続)
- **no new multi-bit routine** (= 第 2 invariant 「dispatch path は simultaneous trigger でも増やさない」 維持)

#### ADR / handoff 記載 contract

- PMDDotNET multi-bit bitmap OR emit path = **mc.cs rs00() L9727-9755 で確認済**
- PMDNEO 側 driver = **改修ゼロ** (= 既存 dispatch 構造で自動 accept、 latent semantics)
- **PMDDotNET emits multi-bit bitmap** (= rs00() OR 蓄積 path)
- **PMDNEO consumes the same multi-bit bitmap** through existing `pmdneo_rhythm_event_trigger`
- **no new bytecode** + **no new driver entry** + **no new multi-bit routine**

### 決定 7: BD-anchor pair proof 5 件 + 0x3F full-boundary proof + middle-width combo は induction (= 軸 4、 Step 12-17 N-1 pair gate pattern 踏襲)

proof 範囲:

- **BD-anchor pair 5 件** (= BD+SD = 0x03 / BD+CYM = 0x05 / BD+HH = 0x09 / BD+TOM = 0x11 / BD+RIM = 0x21)
- **0x3F full-boundary** (= 全 6 drum simultaneous = upper bound literal proof)
- **K/R 両系統** (= 各 bitmap に K-source + R-source = 12 fixture)
- **middle-width combo** (= 3-bit / 4-bit / 5-bit、 例 0x0B = BD+SD+HH / 0x0D = BD+CYM+HH / 0x1F = BD+SD+CYM+HH+TOM 等) = **induction** (= 2-bit pair + 6-bit full で N+1 bit case 自動成立)
- **exhaustive combinatorial matrix** (= 全 63 combo full proof) = **scope-out**

#### N-1 pair gate 推移的 proof (= Step 12-17 確立規律踏襲)

BD-anchor pair で proof 確立される invariant:
- 0x03 (BD+SD) → BD reg → SD reg 順次 (= bit 0 → bit 1 順序、 SD vs BD differential 推移的)
- 0x05 (BD+CYM) → BD reg → CYM reg 順次 (= bit 0 → bit 2 順序、 CYM vs BD differential 推移的)
- 0x09 (BD+HH) → BD reg → HH reg 順次 (= bit 0 → bit 3 順序、 HH vs BD differential 推移的)
- 0x11 (BD+TOM) → BD reg → TOM reg 順次 (= bit 0 → bit 4 順序、 TOM vs BD differential 推移的)
- 0x21 (BD+RIM) → BD reg → RIM reg 順次 (= bit 0 → bit 5 順序、 RIM vs BD differential 推移的)
- N-1 pair gate (= BD anchor 5 pair) で BD-vs-X 全 5 ペア確立 → X-vs-Y (= SD-vs-CYM / SD-vs-HH 等) は推移的 proof で自動成立

0x3F full-boundary で proof 確立される invariant:
- 6 drum 順次 register write (= BD → SD → CYM → HH → TOM → RIM、 36 件 reg write 連結)
- last-write-dominant = RIM 支配
- upper bound multi-bit (= bit 0-5 全部 set) で driver dispatch path 1 本化維持
- middle-width combo (= 3-bit / 4-bit / 5-bit) は 2-bit pair + 6-bit full で induction 成立

#### ADR / handoff 記載 contract

- proof 範囲 = **BD-anchor pair 5 件 + 0x3F full-boundary**
- BD-anchor pair = **representative pairwise semantics**
- 0x3F = **full-boundary proof**
- middle-width combo = **induction**
- exhaustive combinatorial matrix = **scope-out**
- fixture 数 = **12 件新規** (= K/R x 6 bitmap)
- verify script 数 = **約 12 件新規** (= 5 pair x K/R + 0x3F x K/R)

### 決定 8: simultaneous dispatch ≠ simultaneous audio mixing 境界明示 (= 中核 wording、 §決定 5 内包 + §scope-out 中核)

境界の formal 定義:

- **simultaneous dispatch** (= scope-in、 本 ADR で formal 化):
  - multi-bit bitmap を受信
  - bit 0 → bit 5 昇順順次 `call nz` 連鎖で各 active bit 対応 drum sub-routine 連続実行
  - 各 sub-routine が L ch 1 本に対し register write + keyon を発行
  - 結果: bitmap 昇順順次 register write シーケンス + L ch 1 本 last-write-dominant 発音
- **simultaneous audio mixing** (= scope-out、 future sprint):
  - 複数 drum が同時に **異なる ADPCM-A ch slot** で発音
  - 異なる ch slot の audio output が hardware level で audio mixing される
  - 実現要件: multi-ch allocation (= L ch scaffold 解除) + 動的 ch 割当 + voice stealing semantics
  - Step 18 では **未実装 / 未定義 / future sprint**

#### ADR / handoff 記載 contract

- **simultaneous dispatch ≠ simultaneous audio mixing** = **中核 wording**
- 境界明示が ADR §決定 / §scope-out / §備考 / commit message / handoff doc / memory で **統一表記**
- simultaneous dispatch = **scope-in** (= Step 18 で formal 化)
- simultaneous audio mixing = **scope-out** (= future sprint)
- audio gate doc 冒頭で「BD+SD fixture で SD のみ支配的に聴こえるのが正常」 を **future contributor 向け literal 注記**

### 決定 9: audio gate = listen-step18.sh + 3 項目 judgement + last-write-dominant expected behavior 明文化 (= 軸 5)

audio gate 構成:

- `listen-step18.sh` helper script (= 12 wav + sleep 3 + 無限繰り返し + Ctrl+C 停止、 Step 15/16/17 convention 踏襲)
- 12 wav = K-0x03 / R-0x03 / K-0x05 / R-0x05 / K-0x09 / R-0x09 / K-0x11 / R-0x11 / K-0x21 / R-0x21 / K-0x3F / R-0x3F
- user 試聴 3 項目 judgement:
  1. **multi-bit fixture が silent ではない** (= dispatch literal 動作確認)
  2. **K-multi-bit と R-multi-bit が同音** (= K/R 同 dispatch invariant の multi-bit 状況下での維持)
  3. **bitmap 末尾 drum が支配的に聴こえる** (= last-write-dominant observation literal、 例: 0x03 → SD / 0x3F → RIM)

#### ADR / handoff 記載 contract

- audio gate = **listen-step18.sh + 12 wav + sleep 3 + loop**
- audio gate 3 項目 judgement (= 上記 1-3)
- last-write-dominant = **expected behavior** (= ADR + audio gate doc + future contributor 向け literal 注記)
- 「BD+SD で SD のみ聴こえる、 0x3F で RIM のみ聴こえる」 = **bug ではなく L ch scaffold 自然結果**
- audio gate は γ 完了時 または δ 序盤 で user 試聴
- audio gate user 試聴 OK が δ Accepted 移行の必須条件

### 決定 10: fixture naming = bitmap hex pattern (= `k03` / `k05` / `k09` / `k11` / `k21` / `k3f` + drum semantics naming からの転換点、 軸 5 派生)

fixture 命名:

- Step 12-17: drum-centric semantics naming (= `k-br-only.mml` / `r-melody-br-only.mml` 等)
- Step 18+: **bitmap-centric semantics naming** (= `k03.mml` / `r-melody-03.mml` 等、 hex bitmap pattern)

#### naming 規則

- fixture filename = `k<hex>.mml` (= K-source 単独) / `r-melody-<hex>.mml` (= melody source inline)
- `<hex>` = 2 文字 lowercase hex (= bitmap value、 PMDDotNET emit range は 00-3F + 80 reserved)
- 例: `k03.mml` = K part 内 `\b\s` syntax → `0xEB 0x03` bytecode、 `r-melody-3f.mml` = melody part L 内 inline `\b\s\c\h\t\i` syntax → `0xEB 0x3F` bytecode
- verify script naming も同 pattern (= `verify-step18-k03-trigger.sh` / `verify-step18-kr-03-byte-identical.sh` 等)

#### sprint chain 軸転換 milestone

- Step 12-17 = **drum 種拡張軸** = drum-centric semantics naming
- Step 18+ = **semantics 拡張軸** = bitmap-centric semantics naming
- naming 転換 = sprint chain 軸転換の **literal 表現**

#### ADR / handoff 記載 contract

- fixture naming = **hex bitmap pattern** (= `k<hex>.mml` / `r-melody-<hex>.mml`)
- drum-centric semantics naming (= Step 12-17) からの **転換点**
- Step 12-17 = drum-centric (= single drum expansion 期)
- Step 18+ = bitmap-centric (= simultaneous semantics 期)
- sprint chain 軸転換 milestone (= drum 種拡張軸 → semantics 拡張軸)

### 決定 11: driver source 完全不変 + multi-bit accept は latent semantics 証明 (= 軸 1 派生、 「新機能追加ではなく latent semantics の証明」 wording 統一)

driver Z80 source 改修 status:

- driver source = **完全不変** (= 改修ゼロ literal 確認、 byte-for-byte 不変、 verify script で literal assert)
- multi-bit accept 能力 = **既に存在** (= 既存 bit 0 → bit 5 順次 `call nz` 連鎖が structurally multi-bit dispatch 可能)
- Step 18 は新機能追加ではなく **latent semantics の証明** (= 既に存在していた dispatch 構造の semantic 化、 documentation + verify infrastructure 整備)

#### latent semantics 証明の Step 18 における意味

- 「dispatch path 自体は既に存在」 (= ADR-0026-0031 で確立)
- 「multi-bit bitmap も structurally 通る」 (= 現自然 dispatch で自動 accept)
- 「それを semantics として formal 化する」 (= Step 18 で ADR + fixture + verify)
- 結果: 「新 runtime 実装」 ではなく「**latent behavior の specification 化**」
- PMDNEO architecture 設計として「綺麗な単純化」 = 「実装は既に正しく動いており、 仕様だけが追いついていなかった」 paradigm

#### ADR / handoff 記載 contract

- driver source = **完全不変** (= 改修ゼロ literal 確認)
- 「**新機能追加ではなく latent semantics の証明**」 wording 統一 (= ADR §背景 + §決定 1 + §決定 11 + commit message + handoff doc + memory)
- latent semantics = 「実装は既に正しく動いており、 仕様だけが追いついていなかった」 paradigm の literal 表現
- ADR-0032 identity = **latent semantics の specification 化 ADR**

### 決定 12: Step 18 = simultaneous trigger semantics proof sprint、 sprint chain 軸転換 milestone (= drum 種拡張軸 Step 12-17 完了 → semantics 拡張軸 Step 18+ 初段)

sprint chain context:

- **drum 種拡張軸** (= Step 12-17、 ADR-0026-0031): single drum expansion sprint chain
  - Step 12 b-only → Step 13 b+s → Step 14 b+s+h → Step 15 b+s+c+h → Step 16 b+s+c+h+t → Step 17 b+s+c+h+t+i (= full 6 drum completion)
  - drum-centric semantics naming
  - 第 1 invariant 「dispatch path は drum 種拡張で増やさない」 確立
- **semantics 拡張軸** (= Step 18+、 ADR-0032+): simultaneous / dispatch / asset 系 sprint chain
  - Step 18: simultaneous trigger semantics proof (= 本 ADR)
  - Step 19+ 候補: table-driven dispatch refactor / .PNE rhythm bank migration / multi-channel allocation / true simultaneous audio mixing / voice stealing / K sequencer semantics / R1/R2 pattern definition / 制御 cmd 現役化 等
  - bitmap-centric semantics naming
  - 第 2 invariant 「dispatch path は simultaneous trigger でも増やさない」 確立

#### sprint chain 軸転換の意味

- drum 種拡張軸完成 (= Step 17 full 6 drum) で **drum 種** 軸の sprint chain は完結
- 同 dispatch infrastructure 上で次の拡張軸 (= semantics) に進む
- naming convention も drum-centric から bitmap-centric に転換
- 「同じ dispatch path で複数の expansion 軸を順次扱う」 という PMDNEO architecture identity の literal 表現

#### ADR / handoff 記載 contract

- Step 18 = **simultaneous trigger semantics proof sprint** (= ADR-0032 identity)
- sprint chain 軸転換 milestone (= drum 種拡張軸 → semantics 拡張軸)
- 第 1 invariant + 第 2 invariant の 2 invariant 体系確立
- naming convention 転換 (= drum-centric → bitmap-centric)
- Step 19+ 候補 = semantics 拡張軸 初段以降 (= table-driven / .PNE migration / multi-ch allocation / true mixing / voice stealing 等)

## scope-out

明確に Step 18 で扱わない項目:

- **true simultaneous audio mixing** (= 複数 drum が異なる ch slot で同時発音 + audio mixing) = future sprint
- **multi-channel allocation** (= L ch scaffold 解除 + 動的 ch 割当) = future sprint
- **priority semantics** (= bitmap LSB 優先 / BD 最優先 等) = 不導入
- **voice stealing** (= ch slot 取り合い時の選択 logic) = scope-out
- **exact OPNA timing fidelity** (= 実機相当の timing 再現) = scope-out
- **cycle-level scheduling** (= Z80 cycle 単位の dispatch timing) = scope-out
- **exhaustive combinatorial matrix** (= 全 63 combo full literal proof) = scope-out
- **middle-width combo literal proof** (= 3-bit / 4-bit / 5-bit) = induction
- **K sequencer semantics** (= K part 内 sequence cmd) = future sprint
- **R1/R2 pattern definition** (= rhythm pattern macro) = future sprint
- **K `[R1]4 [R2]` pattern call** (= rhythm pattern invocation) = future sprint
- **`.PNE` rhythm bank migration** (= rhythm-dedicated sample bank) = future sprint
- **#PCMFile integration** (= .PPC / .P86 / .PNE 統合 dispatcher) = future sprint
- **table-driven dispatch refactor** (= bit → sample addr lookup table 集約) = future sprint
- **K/R 制御 cmd 現役化** (= V/v/l/m/r/p control cmd) = future sprint
- **rhythm-dedicated sample symbol 分離** (= adpcma_sample_*_rhythm 等) = future sprint
- **tempo / pan distribution for simultaneous** (= 同時打ち時の pan 分布) = future sprint
- **multi-bit fixture が単 drum と異なる sample 構成** (= 例 BD+SD で BD=ch0 + SD=ch1) = scope-out
- **driver Z80 source 改修** (= 改修ゼロ literal、 latent semantics 証明のみ)
- **PMDDotNET (C# compile path) 改修** (= 既存 rs00() OR 蓄積 path 利用、 改修なし)
- **`.MN` format 改修** (= 既存 0xEB rhykey bytecode 利用、 改修なし)
- **`pne_sample_directory` 改修** (= ADR-0023 既存維持、 改修なし)
- **`sample_table_id` resolver / selector 改修** (= ADR-0024 既存維持、 改修なし)
- **L-Q ADPCM-A melody architecture 改修** (= ADR-0019-0025 既存維持、 改修なし)
- **driver SRAM layout 改修** (= 0xFD20-0xFD32 既存維持、 新規 marker byte なし)
- **既存 Step 12-17 単 drum fixture 改修** (= 12 件完全不変)
- **既存 34 script regression 改修** (= 全 PASS literal 維持)
- **新規 bytecode 追加** (= 0xEB rhykey 維持、 第 2 invariant)
- **新規 driver entry 追加** (= 0x1126 維持、 第 1 + 第 2 invariant)
- **separate multi-bit dispatch routine 新設** (= 第 2 invariant)
- **bit 6-7 active 化** (= reserved + silent ignore 維持、 PMDDotNET emit range 範囲外)
- **bit 7 = 0x80 「直前 byte rest」 を driver で actively 扱う** (= silent ignore 維持で副作用なし)
- **multi-bit fixture を BD+SD+HH+CYM+TOM+RIM-multi-bit-only 等の 6-way 単一 fixture に統合** (= 12 fixture 分離維持)
- **K-multi-bit と R-multi-bit を 1 fixture にマージ** (= K/R 分離維持で dispatch invariant proof)
- **listen-step18.sh で multi-bit fixture と単 drum fixture を mix 再生** (= step18 専用 audio gate 維持)
- **既存 Step 17 listen-step17.sh の改修** (= 不変)
- **既存 Step 16 listen-step16.sh の改修** (= 不変)
- **既存 Step 15 listen-step15.sh の改修** (= 不変)
- **PMDDotNETConsole compile chain 改修** (= 既存 /C option 維持)
- **既存 ADR-0026-0031 改訂** (= 本 ADR は新規 invariant 追加で過去 ADR は不変)
- **既存 CLAUDE.md 改訂** (= 設計書ファースト + 動作確認義務 + 表記スタイル維持)

## sub-sprint 構成 (= ADR-0028 / ADR-0029 / ADR-0030 / ADR-0031 同型 4 段)

### α sub-sprint (= 本 commit、 doc only)

- ADR-0032 Draft 起票 (= 本 file)
- 内容: 5 軸壁打ち統合 + 12 件 §決定 + 30+ 件 scope-out + 4 段 sub-sprint + 7-8 段 verify gate + 10 項目完了判定 + §Annex A-1 用語対応表 + §Annex A-2 PMDDotNET literal quote 4 件 + §Annex A-3 bitmap example + §Annex A-4 future sprint + §Annex A-5 sprint chain milestone
- driver / fixture / verify script = **完全不変** (= doc only commit)
- α phase 1 (= PMDDotNET ground truth 調査) = 完了 (= mc.cs L9691-9725 / L9727-9755 / L9540-9552 literal 確認済)
- α phase 2 (= ADR Draft 起票) = 本 commit
- α phase 3 (= commit + push) = 本 commit + GitHub URL report
- 完了判定: ADR commit + push + user review

### β sub-sprint (= 最小 representative multi-bit fixture)

- `tests/fixtures/mml/k03.mml` 新規追加 (= K part 内 `\b\s` syntax → `0xEB 0x03` bytecode)
- `tests/fixtures/mml/r-melody-03.mml` 新規追加 (= melody part L 内 inline `\b\s` syntax → `0xEB 0x03` bytecode)
- `scripts/verify-step18-k03-trigger.sh` 新規追加 (= K-0x03 fixture で BD reg writes → SD reg writes 順次 + PC marker @ 0x1126 hit + ymfm-trace literal assert)
- driver Z80 source = **完全不変** (= 改修ゼロ literal 確認、 verify script で byte-for-byte assert)
- 全 34 既存 script regression PASS + 1 新規 script PASS = 35 script 体制
- 完了判定: β commit + push + user review

### γ sub-sprint (= representative pair 4 件拡張)

- `tests/fixtures/mml/k05.mml` 新規追加 (= K part 内 `\b\c` syntax → `0xEB 0x05` bytecode)
- `tests/fixtures/mml/k09.mml` 新規追加 (= K part 内 `\b\h` syntax → `0xEB 0x09` bytecode)
- `tests/fixtures/mml/k11.mml` 新規追加 (= K part 内 `\b\t` syntax → `0xEB 0x11` bytecode)
- `tests/fixtures/mml/k21.mml` 新規追加 (= K part 内 `\b\i` syntax → `0xEB 0x21` bytecode)
- `tests/fixtures/mml/r-melody-05.mml` / `r-melody-09.mml` / `r-melody-11.mml` / `r-melody-21.mml` 新規追加 (= melody part L 内 inline 同 syntax)
- R-0x03 verify script 新規 (= `scripts/verify-step18-r03-trigger.sh`)
- representative pair 4 件 verify script 新規 (= `verify-step18-k05-trigger.sh` / `k09-trigger.sh` / `k11-trigger.sh` / `k21-trigger.sh` + r 系 4 件 + KR byte-identical 5 件 = 計 13 件)
- N-1 pair gate 推移的 proof (= BD-vs-X 5 pair で X-vs-Y 推移的成立)
- driver Z80 source = **完全不変**
- 全 34 既存 + 14 新規 = 48 script regression PASS
- 完了判定: γ commit + push + user review

### δ sub-sprint (= 0x3F full-boundary + 完了統合)

- `tests/fixtures/mml/k3f.mml` 新規追加 (= K part 内 `\b\s\c\h\t\i` syntax → `0xEB 0x3F` bytecode)
- `tests/fixtures/mml/r-melody-3f.mml` 新規追加 (= melody part L 内 inline 同 syntax)
- `scripts/verify-step18-k3f-trigger.sh` 新規追加 (= K-0x3F fixture で 6 drum 順次 register write + last-write-dominant + 36 件 reg write 連結 assert)
- `scripts/verify-step18-r3f-trigger.sh` 新規追加
- `scripts/verify-step18-kr-3f-byte-identical.sh` 新規追加
- `scripts/listen-step18.sh` 新規追加 (= 12 wav + sleep 3 + 無限繰り返し + Ctrl+C 停止、 Step 15/16/17 convention 踏襲)
- audio gate user 試聴 (= 3 項目 judgement)
- ADR-0032 Accepted 移行
- handoff doc 起票
- memory 1 件追加 (= step18 完了 + drum semantics → bitmap semantics naming 転換 + 第 2 invariant 確立)
- MEMORY.md index 更新
- driver Z80 source = **完全不変**
- 全 34 既存 + 約 14 新規 + 0x3F 系 3 件 = 約 51 script regression PASS
- 完了判定: δ commit + push + user review + ADR Accepted

## verify gate (= 7-8 段、 ADR-0028-0031 多軸 pattern 拡張)

### Gate 1: K-multi-bit trigger (= 各 representative bitmap で K part fixture が dispatch entry @ 0x1126 hit + bitmap 昇順順次 register write)

- 対象: K-0x03 / K-0x05 / K-0x09 / K-0x11 / K-0x21 / K-0x3F (= 6 K fixture)
- 検証: PC trace marker @ 0x1126 hit literal + ADPCM-A L ch register write sequence ymfm-trace literal assert + bitmap 昇順順次 register write 順序 literal assert
- script: `verify-step18-k03-trigger.sh` / `k05-trigger.sh` / `k09-trigger.sh` / `k11-trigger.sh` / `k21-trigger.sh` / `k3f-trigger.sh`

### Gate 2: R-multi-bit trigger (= 各 representative bitmap で R melody part fixture が同 dispatch entry hit)

- 対象: R-0x03 / R-0x05 / R-0x09 / R-0x11 / R-0x21 / R-0x3F (= 6 R fixture)
- 検証: K-multi-bit と同 dispatch entry @ 0x1126 hit + 同 register write sequence
- script: `verify-step18-r03-trigger.sh` / `r05-trigger.sh` / `r09-trigger.sh` / `r11-trigger.sh` / `r21-trigger.sh` / `r3f-trigger.sh`

### Gate 3: K-multi-bit vs R-multi-bit byte-identical (= 各 representative bitmap で K vs R が ymfm register write byte-for-byte identical literal proof)

- 対象: 各 bitmap で K vs R pair = 6 pair
- 検証: K-source と R-source の register write シーケンスが完全同一 (= dispatch path 1 本化 invariant の multi-bit 状況下での維持)
- script: `verify-step18-kr-03-byte-identical.sh` / `kr-05-byte-identical.sh` / `kr-09-byte-identical.sh` / `kr-11-byte-identical.sh` / `kr-21-byte-identical.sh` / `kr-3f-byte-identical.sh`

### Gate 4: bitmap 昇順順次 register write 順序 (= 各 multi-bit fixture で BD reg writes が SD reg writes より先、 SD が CYM より先、 ... の literal 順序 assert)

- 対象: 全 12 multi-bit fixture
- 検証: ymfm-trace 内で bitmap 内 active bit の register write が bit 0 → bit 5 昇順順次に出現することを literal 順序 assert (= source code order = bitmap order = register write order 3 軸完全一致)
- 内包: Gate 1 + Gate 2 script 内で順序 assert (= 別 script 不要)

### Gate 5: last-write-dominant observation (= 各 multi-bit fixture で bitmap 末尾 drum の register write が ADPCM-A L ch に最後に書かれている literal proof)

- 対象: 全 12 multi-bit fixture
- 検証: bitmap 末尾 drum の sample addr / vol / pan / keyon mask が L ch 上で最後に書かれている (= ADPCM-A reg 0x10/0x18/0x20/0x28/0x08/0x00 の最終 value が末尾 drum 由来)
- 内包: Gate 1 + Gate 2 script 内で last-write assert (= 別 script 不要)
- audio gate (= Gate 8) で user 試聴 3 項目 judgement と整合

### Gate 6: dispatch entry @ 0x1126 invariant (= 全 multi-bit fixture で同 entry addr literal、 single drum + multi-bit 両方で完全同一、 第 2 invariant literal proof)

- 対象: 全 24 fixture (= 12 単 drum + 12 multi-bit)
- 検証: PC trace marker hit addr が 0x1126 で完全同一 (= 「dispatch path は drum 種拡張で増やさない」 + 「dispatch path は simultaneous trigger でも増やさない」 の 2 invariant literal proof)
- 内包: Gate 1 + Gate 2 + step 12-17 既存 verify script で全 PC marker hit literal 確認

### Gate 7: 0x3F full-boundary literal proof (= 全 6 drum simultaneous 上限 case の 36 件 reg write 連結 + last-write-dominant = RIM 支配 literal proof)

- 対象: K-0x3F / R-0x3F (= 2 fixture)
- 検証: 6 drum 順次 register write 連結 (= BD 6 件 + SD 6 件 + CYM 6 件 + HH 6 件 + TOM 6 件 + RIM 6 件 = 36 件) + RIM reg value が L ch 最終 value + keyon trigger 6 回連続発行 literal
- script: `verify-step18-k3f-trigger.sh` / `verify-step18-r3f-trigger.sh` + KR byte-identical 含む

### Gate 8: audio gate (= user 試聴 3 項目 judgement、 γ 完了時 または δ 序盤)

- 対象: listen-step18.sh で 12 multi-bit wav 再生
- 検証:
  1. multi-bit fixture が silent ではない (= dispatch literal 動作)
  2. K-multi-bit と R-multi-bit が同音 (= dispatch invariant multi-bit 状況下維持)
  3. bitmap 末尾 drum が支配的に聴こえる (= last-write-dominant observation literal)
- script: `scripts/listen-step18.sh`
- user 試聴判定が δ Accepted 移行の必須条件

### Gate 9 (= regression、 既存 34 script PASS)

- 対象: step12 系 4 件 + step13 系 3 件 + step14 系 3 件 + step15 系 3 件 + step16 系 3 件 + step17 系 5 件 + step5-11 系 14 件 + step4 1 件 = 34 既存 script
- 検証: 全 PASS literal (= driver 改修ゼロのため既存 PC marker / ymfm-trace / sample addr / keyon count / byte-identical 全項目不変)
- driver source 完全不変 literal 確認 (= byte-for-byte assert または git diff empty assert)

## 完了判定 (= 10 項目)

1. **ADR-0032 Accepted 移行** (= α/β/γ/δ 4 commit chain 完成後、 user 試聴 OK + 全 verify gate PASS で δ commit 内で Accepted 移行)
2. **driver Z80 source 完全不変 literal 確認** (= 改修ゼロ literal、 verify script で byte-for-byte または git diff empty assert)
3. **β/γ/δ sub-sprint chain 完成** (= 1 sub = 1 commit + 1 push、 各 sub で全 既存 + 新規 script PASS)
4. **全 12 multi-bit fixture 新規追加** (= K-0x03 / R-0x03 / K-0x05 / R-0x05 / K-0x09 / R-0x09 / K-0x11 / R-0x11 / K-0x21 / R-0x21 / K-0x3F / R-0x3F)
5. **全 約 14 verify script 新規追加** (= Gate 1 6 件 + Gate 2 6 件 + Gate 3 6 件 + Gate 7 3 件 = 21 件、 ただし KR byte-identical を K/R trigger script 内包する場合は 12-14 件)
6. **既存 34 script regression 全 PASS** (= driver 改修ゼロ literal 保証)
7. **pmdneo_rhythm_event_trigger @ 0x1126 invariant 維持 literal** (= 24 fixture = 12 単 drum + 12 multi-bit 全て同 entry addr literal proof、 第 1 + 第 2 invariant 両方確立)
8. **bitmap ascending dispatch order literal proof** (= Gate 4、 bit 0 → bit 5 順次 register write 順序 literal assert)
9. **last-write-dominant observation literal proof + user 試聴 OK** (= Gate 5 trace + Gate 8 audio 3 項目 judgement)
10. **listen-step18.sh + handoff doc + memory + MEMORY.md index 整備** (= audio gate helper + sprint chain 軸転換 milestone 記録 + future contributor 向け literal 注記)

## Annex A: 補足資料

### Annex A-1: 用語対応表 (= Step 18 中核 wording 統一)

| layer | 識別子 | 出典 / 用途 |
|---|---|---|
| Step 18 identity | **latent semantics の証明** | ADR §背景 + §決定 1 + §決定 11、 「新機能追加ではなく既存 dispatch 構造の semantic 化」 |
| dispatch 軸 | **simultaneous dispatch** (= scope-in) | ADR §決定 5 + §決定 8、 「multi-bit bitmap → bit 0 → bit 5 順次 `call nz` 連鎖 → 各 sub-routine register write 連結発行」 |
| audio 軸 | **simultaneous audio mixing** (= scope-out) | ADR §決定 5 + §決定 8 + §scope-out、 「複数 drum が異なる ch slot で同時発音 + audio mixing」、 future sprint |
| L ch 挙動 | **last-write-dominant observation** | ADR §決定 5 + §決定 9、 「L ch 1 本に bitmap 末尾 drum が支配的発音、 bug ではなく expected behavior」 |
| 第 1 invariant | **「dispatch path は drum 種拡張で増やさない」** | ADR-0026 §決定 6 + ADR-0027-0031 §決定 8、 Step 12-17 確立 |
| 第 2 invariant | **「dispatch path は simultaneous trigger でも増やさない」** | ADR-0032 §決定 4、 Step 18 確立 |
| sprint chain 軸 | **drum 種拡張軸 → semantics 拡張軸 転換 milestone** | ADR §決定 12、 Step 12-17 (= drum-centric) → Step 18+ (= bitmap-centric、 simultaneous / dispatch / asset 系) |
| naming 軸 | **drum-centric semantics naming → bitmap-centric semantics naming** | ADR §決定 10、 `k-br-only.mml` → `k03.mml` 転換 |
| bitmap range | **0x00 - 0x3F (= bit 0-5 任意組合せ)** | ADR §決定 2、 bit 6-7 reserved、 PMDDotNET emit range 一致 |
| dispatch order | **bitmap ascending (= bit 0 → bit 5 順固定)** | ADR §決定 3、 source code order = bitmap order = register write order 3 軸完全一致 |
| proof 範囲 | **BD-anchor pair 5 件 + 0x3F full-boundary + middle induction** | ADR §決定 7、 Step 12-17 N-1 pair gate pattern 踏襲 |
| fixture naming | **`k<hex>.mml` / `r-melody-<hex>.mml`** | ADR §決定 10、 2 文字 lowercase hex = bitmap value |
| verify naming | **`verify-step18-<k or r><hex>-trigger.sh` / `kr-<hex>-byte-identical.sh`** | ADR §sub-sprint β/γ/δ |

### Annex A-2: PMDDotNET multi-bit bitmap OR emit path literal quote (= α phase 1 ground truth 調査結果)

#### A-2-1: mc.cs L9691-9725 = 各 drum function literal bitmap value

```csharp
private enmPass2JumpTable bdset()
{
    work.al = 1;
    return rs00();
}

private enmPass2JumpTable snrset()
{
    work.al = 2;
    return rs00();
}

private enmPass2JumpTable cymset()
{
    work.al = 4;
    return rs00();
}

private enmPass2JumpTable hihset()
{
    work.al = 8;
    return rs00();
}

private enmPass2JumpTable tamset()
{
    work.al = 16;
    return rs00();
}

private enmPass2JumpTable rimset()
{
    work.al = 32;
    return rs00();
}
```

各 drum function は `work.al` に **literal bit value** (= 1 / 2 / 4 / 8 / 16 / 32) を設定して `rs00()` に flow。 bit 0 = BD / bit 1 = SD / bit 2 = CYM / bit 3 = HH / bit 4 = TOM / bit 5 = RIM の 6 drum mapping。

#### A-2-2: mc.cs L9727-9755 = rs00() OR 蓄積 path 核心 literal

```csharp
private enmPass2JumpTable rs00()
{
    if (mml_seg.skip_flag != 0) goto rs_skip;

    char ch = work.si < mml_seg.mml_buf.Length ? mml_seg.mml_buf[work.si] : (char)0x1a;
    if (ch != 'p') goto rs01;
    work.si++;
    work.al |= 0x80;
    goto rs02;
rs01:;
    var o = m_seg.m_buf.Get(work.di - 2);
    if (o == null) goto rs02;
    byte cch = (byte)m_seg.m_buf.Get(work.di - 2).dat;
    if (cch != 0xeb) goto rs02;
    cch = (byte)m_seg.m_buf.Get(work.di - 1).dat;
    if ((cch & 0x80) != 0) goto rs02;
    if (mml_seg.prsok != 0x80) goto rs02;//直前byte = リズム?
    work.al |= cch;
    m_seg.m_buf.Set(work.di - 1, new MmlDatum(work.al));
    goto rsexit;
rs02:;
    m_seg.m_buf.Set(work.di, new MmlDatum(0xeb));
    m_seg.m_buf.Set(work.di + 1, new MmlDatum(work.al));
    work.di += 2;
    if ((work.al & 0x80) == 0) goto rsexit;
    return enmPass2JumpTable.olc0;
rsexit:;
    mml_seg.prsok = 0x80;//直前byte = リズム
    return enmPass2JumpTable.olc02;
rs_skip:;
    ch = work.si < mml_seg.mml_buf.Length ? mml_seg.mml_buf[work.si] : (char)0x1a;
    if (ch != 'p') return enmPass2JumpTable.olc03;
    work.si++;
    return enmPass2JumpTable.olc03;
}
```

**OR 蓄積 path 解説**:

- `rs01` block: 連続 drum command (= `\b\s\h` 等) の判定。 3 条件全部満たす場合に OR 蓄積:
  1. `cch != 0xeb`: 直前 byte が `0xEB rhykey` でない → 新規 emit (= `rs02`)
  2. `(cch & 0x80) != 0`: 直前 bitmap に rest bit (0x80) 立ち → 新規 emit
  3. `mml_seg.prsok != 0x80`: 直前 byte がリズムでない → 新規 emit
  - 3 条件全部満たさない (= 直前 byte = `0xEB rhykey` + 直前 bitmap rest bit なし + `prsok = 0x80` 立ち) 場合: `work.al |= cch` で **OR 蓄積** + 直前 0xEB arg を OR 値で **上書き**
- `rs02` block: 新規 `0xEB <bitmap>` emit (= 2 byte sequence)
- `rsexit`: `prsok = 0x80` flag set (= 「直前 byte = リズム」 連続判定用)

**multi-bit emit 例**:
- `\b\s` syntax → bdset → `work.al = 1` → rs00 → rs02 (= 直前 byte not 0xEB) → emit `0xEB 0x01` → prsok = 0x80
  - 次の `\s` → snrset → `work.al = 2` → rs00 → rs01 (= 3 条件全部満たす: 直前 0xEB + rest bit なし + prsok = 0x80) → `work.al |= cch` = `2 | 1` = `0x03` → 直前 arg を `0x03` で上書き → final `0xEB 0x03`
- 連続 `\b\s\c\h\t\i` syntax → 同様に `0xEB 0x3F` 単一 bytecode に collapse

#### A-2-3: mc.cs L9540-9552 = rhycom() dispatch loop literal

```csharp
private enmPass2JumpTable rhycom()
{
    work.al = (byte)(work.si < mml_seg.mml_buf.Length ? mml_seg.mml_buf[work.si++] : (char)0x1a);
    work.bx = 0;//offset rcomtbl
                //rc00:;
    do
    {
        if (rcomtbl[work.bx].Item1 == 0) error('\\', 1, work.si);
        if (work.al == rcomtbl[work.bx].Item1) goto rc01;
        work.bx++;
    } while (true);
rc01:;
    return rcomtbl[work.bx].Item2();
    //return enmPass2JumpTable.olc0;
}
```

`rhycom()` は `\` (= backslash) 直後の char を読み、 `rcomtbl` (= mc.cs L9521-9535) を linear search して対応 drum function を dispatch。

#### A-2-4: prsok = 0x80 flag literal semantics

- 設定箇所: mc.cs L9754 = `mml_seg.prsok = 0x80;//直前byte = リズム`
- 判定箇所: mc.cs L9743 = `if (mml_seg.prsok != 0x80) goto rs02;`
- 役割: 「直前に emit された byte が rhythm 関連かどうか」 を示す 1-bit flag
- 効果: 連続 `\b\s` syntax で前 byte が `0xEB` + `prsok = 0x80` 立ち時に OR 蓄積発火、 他 cmd (= note / control 等) が間に入ると `prsok` がクリアされて新規 emit に倒れる

### Annex A-3: bitmap example (= 軸 4 representative pair + 0x3F full-boundary)

| bitmap | binary | active bits | drum combo | dispatch order | register write order |
|---|---|---|---|---|---|
| 0x01 | 00000001 | bit 0 | BD | BD | BD reg writes (= 6 件) |
| 0x02 | 00000010 | bit 1 | SD | SD | SD reg writes (= 6 件) |
| 0x04 | 00000100 | bit 2 | CYM | CYM | CYM reg writes (= 6 件) |
| 0x08 | 00001000 | bit 3 | HH | HH | HH reg writes (= 6 件) |
| 0x10 | 00010000 | bit 4 | TOM | TOM | TOM reg writes (= 6 件) |
| 0x20 | 00100000 | bit 5 | RIM | RIM | RIM reg writes (= 6 件) |
| **0x03** | 00000011 | bit 0, 1 | **BD+SD** | BD → SD | BD reg writes → SD reg writes (= 12 件) |
| **0x05** | 00000101 | bit 0, 2 | **BD+CYM** | BD → CYM | BD reg writes → CYM reg writes (= 12 件) |
| **0x09** | 00001001 | bit 0, 3 | **BD+HH** | BD → HH | BD reg writes → HH reg writes (= 12 件) |
| **0x11** | 00010001 | bit 0, 4 | **BD+TOM** | BD → TOM | BD reg writes → TOM reg writes (= 12 件) |
| **0x21** | 00100001 | bit 0, 5 | **BD+RIM** | BD → RIM | BD reg writes → RIM reg writes (= 12 件) |
| **0x3F** | 00111111 | bit 0-5 | **全 6 drum** | BD → SD → CYM → HH → TOM → RIM | BD → SD → CYM → HH → TOM → RIM reg writes (= 36 件) |

#### middle-width combo (= induction、 scope-out)

参考までに記録 (= Step 18 では fixture 化しない、 induction で proof 成立):

| bitmap | binary | active bits | drum combo |
|---|---|---|---|
| 0x06 | 00000110 | bit 1, 2 | SD+CYM |
| 0x0A | 00001010 | bit 1, 3 | SD+HH |
| 0x0B | 00001011 | bit 0-1, 3 | BD+SD+HH |
| 0x0D | 00001101 | bit 0, 2, 3 | BD+CYM+HH |
| 0x0F | 00001111 | bit 0-3 | BD+SD+CYM+HH |
| 0x1F | 00011111 | bit 0-4 | BD+SD+CYM+HH+TOM |
| 0x2F | 00101111 | bit 0-3, 5 | BD+SD+CYM+HH+RIM |
| 0x33 | 00110011 | bit 0-1, 4-5 | BD+SD+TOM+RIM |

これら middle combo は driver dispatch 上で同 pattern (= bitmap 昇順順次 register write) で処理されるが、 Step 18 では explicit verify gate を持たない。 induction で proof 成立。

### Annex A-4: future sprint 候補 (= Step 19+、 semantics 拡張軸 第 2 段以降)

Step 18 完了後の次 sprint 候補:

#### Step 19 候補 (= 最有力)

- **table-driven dispatch refactor** (= bit → sample addr lookup table 集約、 dispatch path + sub-routine も 1 本に帰結、 driver source 改修必要、 §決定 4 第 2 invariant 維持 + dispatch order contract 維持)

#### Step 20+ 候補 (= 順次選定)

- **`.PNE` rhythm bank migration** (= rhythm-dedicated sample bank、 ADR-0026-0031 future migration path、 sample_table_id rhythm bank entry 新設)
- **multi-channel allocation** (= L ch scaffold 解除 + 動的 ch 割当、 multi-bit 同時音 audio mixing 実現の前提)
- **true simultaneous audio mixing** (= multi-bit 同時音が異なる ch slot で発音 + hardware audio mixing、 multi-channel allocation 後の自然延長)
- **voice stealing** (= ch slot 取り合い時の選択 logic、 multi-ch allocation 後)
- **#PCMFile integration** (= .PPC / .P86 / .PNE 統合 dispatcher、 ADPCM-A subsystem 全体統合)
- **K sequencer semantics** (= K part 内 sequence cmd、 K [R1]4 [R2] pattern call の前提)
- **R1/R2 pattern definition** (= rhythm pattern macro、 K sequencer 後)
- **K/R 制御 cmd 現役化** (= V/v/l/m/r/p、 ADR-0016 §決定 2 K/R legacy retained but inactive の現役化)
- **rhythm-dedicated sample symbol 分離** (= adpcma_sample_*_rhythm、 .PNE rhythm bank migration の一部)

### Annex A-5: sprint chain 軸転換 milestone (= drum 種拡張軸 完成 + semantics 拡張軸 初段)

#### Step 12-17 = drum 種拡張軸 sprint chain (= 完成)

| Step | ADR | drum 段 | bitmap accept | naming |
|---|---|---|---|---|
| 12 | ADR-0026 | b | 0x01 | k-br-only.mml |
| 13 | ADR-0027 | b+s | 0x01, 0x02 | + k-sr-only.mml |
| 14 | ADR-0028 | b+s+h | + 0x08 | + k-hr-only.mml |
| 15 | ADR-0029 | b+s+c+h | + 0x04 | + k-cr-only.mml |
| 16 | ADR-0030 | b+s+c+h+t | + 0x10 | + k-tr-only.mml |
| 17 | ADR-0031 | b+s+c+h+t+i | + 0x20 (= **full 6 drum**) | + k-ir-only.mml |

確立 invariant: **第 1 invariant = 「dispatch path は drum 種拡張で増やさない」**

#### Step 18 = semantics 拡張軸 初段 (= 本 ADR)

| Step | ADR | bitmap accept | naming |
|---|---|---|---|
| 18 | ADR-0032 | 0x00-0x3F (= single + **multi-bit**) | **k03.mml** / r-melody-03.mml / k05.mml / k09.mml / k11.mml / k21.mml / **k3f.mml** + r 系 |

確立 invariant: **第 2 invariant = 「dispatch path は simultaneous trigger でも増やさない」**

軸転換:
- drum 種拡張軸 (= 完成) → **semantics 拡張軸** (= 開始)
- drum-centric naming → **bitmap-centric naming**
- 「単一 drum 種 dispatch path 1 本化」 → 「**multi-bit dispatch path 1 本化**」

## 備考

- 本 ADR は **Draft** 状態 (= 2026-05-15 20th session α 起票)、 β/γ/δ 4 commit chain 完成後に Accepted 移行予定
- driver Z80 source 改修ゼロ (= 「新機能追加ではなく latent semantics の証明」 paradigm)
- α 段は本 commit に統合 (= ADR-0028-0031 同型 + PMDDotNET mc.cs L9691-9725 / L9727-9755 / L9540-9552 literal 確認済を ground truth として本 commit に統合)
- 「simultaneous dispatch ≠ simultaneous audio mixing」 境界明示が **中核 wording**、 future contributor 誤認回避用 literal 注記が ADR + audio gate doc + handoff doc + memory 統一表記
- 「latent semantics の証明」 paradigm = 「実装は既に正しく動いており、 仕様だけが追いついていなかった」 という PMDNEO architecture identity の literal 表現
- sprint chain 軸転換 milestone = drum 種拡張軸 (= Step 12-17) 完成後の semantics 拡張軸 (= Step 18+) 初段
- naming convention 転換 (= drum-centric → bitmap-centric) は sprint chain 軸転換の literal 表現
- 第 2 invariant 「dispatch path は simultaneous trigger でも増やさない」 = 第 1 invariant に並ぶ PMDNEO rhythm event dispatch architecture の最終 invariant
- exhaustive combinatorial matrix (= 全 63 combo full proof) を意図的に scope-out、 BD-anchor pair 5 件 + 0x3F full-boundary + middle induction で minimal sufficient proof 確立
- audio gate user 試聴 OK が δ Accepted 移行の必須条件 (= CLAUDE.md 動作確認義務遵守)
