# ADR-0033: リズム音源 sample の由来管理と完全自作化 migration policy (= asset provenance / licensing / redistribution 軸独立起票 / runtime semantics 軸 ADR-0026-0032 と完全分離 / Yamaha mask ROM dump 永久排除 / 越川将人 100% 著作物のみ同梱 / Surge XT 完全合成 prototype → プロ session acoustic drum 録音 → library 同梱 3 段階 migration / current temporary fixture 段階 3 完了まで暫定許容 / sound-alike caution = RX-11 似は OK / ROM sample derivative 不可 / PMD culture rhythm.wav 仕様互換 (= 2608_*.wav / 44100 Hz / 16 bit / mono) / 完全ホワイト化 milestone 確立 / runtime dispatch invariant 完全不変 / multi-table architecture (= ADR-0025) 経由 kit 入替 design)

- 状態: **Draft** (= 2026-05-15 20th session 中盤起票 + 2026-05-15 21st session 冒頭 sub-sprint α 5 軸壁打ち決定 + §決定 15-19 追加 + §Annex A-5 / A-7 後埋め枠の調査軸 literal 化 + migration roadmap 段階 1 sub-sprint α 内容詳細化、 段階 1-3 完了後に Accepted 移行予定、 注: step 18 = ADR-0032 simultaneous trigger semantics proof と並走、 step 番号は段階 1 着手時に再採番予定、 ADR-0033 自体は policy fixation で step 軸とは独立)
- 起票日: 2026-05-15
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR: ADR-0032 (= step 18 simultaneous trigger semantics proof、 **runtime semantics 軸**で本 ADR と完全分離、 driver dispatch invariant の semantics 拡張軸初段)、 ADR-0031 (= step 17 K/R drum kind expansion proof — i = RIM、 §決定 8 「dispatch path は drum 種拡張で増やさない」 + drum 種拡張軸 sprint chain 完成 milestone、 本 ADR は runtime invariant 完全保持を前提)、 ADR-0030 / ADR-0029 / ADR-0028 / ADR-0027 / ADR-0026 (= step 12-16 drum 種拡張 sprint chain、 「rim」 「tom」 「top」 wording 規律確立)、 ADR-0025 (= step 11 multi-table id=0x01 proof、 本 ADR §決定 10 「multi-table architecture 経由 kit 入替」 の前提)、 ADR-0023 / ADR-0024 (= step 9 / step 10 sample_table_id resolver + selection consumption、 同前提)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 本 ADR §決定 8 chip 化 pipeline の前提)、 ADR-0021 (= step 7 `.PNE` asset pipeline、 本 ADR §決定 10 multi-table 入替の物理経路前提)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` (= 本 ADR Accepted 後に §rhythm sample 章追記予定、 段階 3 sub-sprint β で実施)、 `README.md` (= 段階 3 sub-sprint γ で license + 由来表記更新予定)、 `CLAUDE.md` (= §中核原則「記憶は AI に、 判断は自分が握る」 + §著作権者表記「越川将人 / M.Koshikawa.」 + §設計書ファースト + §動作確認義務 + §表記スタイル との完全整合)
- 関連 memory: `project_pmdneo_step17_complete.md` (= drum 種拡張軸 sprint chain 完成 milestone、 「Step 18+ candidate」 list に「simultaneous trigger semantics proof」 と並ぶ別軸候補として本 ADR を起票)、 `project_pmdneo_adpcma_subsystem_boundary.md` (= ADPCM-A subsystem 専用 architecture、 本 ADR は ADPCM-A rhythm sample 軸限定)、 `feedback_explain_in_plain_japanese_before_commit.md` (= 平易日本語報告規律、 段階毎 commit で遵守)
- 関連外部資料 (= §Annex A 各 sub-section に literal 引用):
  - BambooTracker GitHub repository (= `chip/mame/fmopn_2608rom.h` 8 KB embed、 `chip/ymfm/ymfm_2608.cpp` extern reference、 `chip/nuked/nuked_2608.cpp` rhythm 不在)
  - VGMRips forum thread t=3013 (= Yamaha DD10 / YRW801 / TG100 で同 sample 再利用、 1984 RX-11 系譜)
  - pedipanol's MML guide (= mml-guide.readthedocs.io、 PMD rhythm syntax + RSS wav 仕様 + setup 経路)
  - projmd repository (= OPNA2608/projmd、 *"for legal reasons, these files are not included"* literal)
  - snesmusic.org/hoot/drum_samples.zip (= community 配布 RSS wav、 出所不明)
  - PMDDotNET (= kuma4649 氏、 mc.cs L9533 rcomtbl ground truth、 vendor/ 配下 rhythm 資産有無は段階 1 sub-sprint α で機械的確認予定)

## 背景

PMDNEO は ADR-0016 から ADR-0032 まで 17 ADR / 17 step / 60+ commit を経て、 **runtime / dispatch / verification 軸**が高度に固まってきた:

- ADR-0016-0019: Phase 3 driver Z80 source 確立 + ADPCM-A 6ch native path 成立
- ADR-0020-0022: audio isolation + `.PNE` asset pipeline + filename runtime observation
- ADR-0023-0025: sample_table_id resolver + selection consumption + multi-table proof
- ADR-0026-0031: K/R rhythm compatibility + drum 種拡張 sprint chain (= full 6 drum completion)
- ADR-0032: simultaneous trigger semantics proof (= multi-bit bitmap dispatch latent semantics 証明、 進行中)

これらは全て **runtime semantics / dispatch architecture / driver Z80 invariant** 軸の ADR で、 「driver がどう動くか」 + 「sample addr / register write / dispatch path がどう literal proof されるか」 + 「PMD V4.8s 系譜の MML semantics をどう移植するか」 を扱う。

一方、 **「PMDNEO 配布物に何を embed するか」 という asset ownership / licensing / redistribution 軸**は、 これまで明示的に文書固定されていなかった。 現状 PMDNEO の `samples.inc` には rhythm sample が embed されている (= driver 上で literal 読まれる) が、 その由来 / 著作権者 / 配布許諾の追跡記録が ADR / 設計書に存在しない。

この空白は、 PMDNEO が将来 v1 release / fork / 第三者派生 / 商用利用 / WebApp 配布 等の局面で **license 連鎖問題**を引き起こす重大 risk となる。 具体的には:

1. **Yamaha mask ROM dump 流入 risk**: BambooTracker / MAME / ymfm 等の他 emulator project は YM2608 内蔵 mask ROM の 8 KB dump (= `fmopn_2608rom.h` 形式) を embed しており、 これは Yamaha 株式会社著作物の literal copy。 PMDNEO が PMD culture 起源で OPNA semantics 再現を志向する以上、 「PMD player は ROM dump を使う」 という community 暗黙慣行に流される risk あり。 これは PMDNEO が掲げる GPL-3.0 license 整合性を完全破壊する。

2. **community 配布 RSS wav 流入 risk**: `snesmusic.org/hoot/drum_samples.zip` 等の community 配布 RSS wav は PMD ecosystem (= PMDDotNET / mml2vgm / projmd / FMPMD2000 / 98fmplayer 等) で広く使われているが、 出所 / 著作権者 / 配布許諾 明記なし。 `projmd` README は *"for legal reasons, these files are not included"* と明記しており、 community 開発者自身が「同梱は法的に危険」 と認識している実態がある。 PMDNEO 配布物に embed すると同じ法的 risk を継承する。

3. **「mimic = clone」 主張の出所証明不在**: community 配布 RSS wav の一部は *"created to mimic the original sounds rather than being direct copies"* と主張されるが、 著者 / 録音 day / 録音機材 / 録音 protocol の証明が存在しない。 PMDNEO が「mimic 主張に乗っかる」 と将来 fork / 派生作品で証拠不在の主張を継承する形になり、 license 健全性が証明不能となる。

4. **sample-based instrument 二次配布の business 実態と厳密法理の乖離**: SampleScience / AREX 2011 / PausePlayRepeat 等の Yamaha RX-11 sample pack は実機録音由来 (= Yamaha 著作物派生) で、 業界実態として「個人楽曲制作は容認」 「商用配布は黙認」 されているが、 厳密 license clean ではない。 PMDNEO が GPL-3.0 で OSS として配布する以上、 「業界容認」 ≠ 「license 整合」 を明確に区別すべき。

5. **hardware ownership と内蔵 sample 著作権の混同**: 越川氏が中古 RX-11 hardware を購入し analog 経路で録音する案も検討されたが、 これは「CD を analog 経由で録音しても元曲 copyright は消えない」 のと同型の誤認で、 結果 wav は依然 Yamaha sound recording の派生物となる。 PMDNEO 配布物として再配布する権利は越川氏には移転していない。

これらの危険を **runtime semantics 軸とは完全に独立した「asset provenance / licensing / redistribution 軸」 の policy ADR として固定**し、 「現状把握 → migration roadmap → 完全ホワイト化」 の 3 段階で段階的に migration を進めることが本 ADR の目的である。

ここで重要なのは、 **「今すぐ全部差し替える」 のではなく「将来的に完全ホワイト化可能な方針を固定する」** 段階的 migration policy ADR として起票する点。 これは ADR-0019 (= step 5 §scope-out 固定 ADR) と同 pattern で、 「ADR で軸を固定し、 sub-sprint で段階的に implementation」 という PMDNEO 流儀の踏襲である。 current temporary fixture の即断 blacklist は scope 肥大化を招き、 既存 PMDNEO build / verify pipeline を不要に揺さぶる可能性があるため避ける。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 + §中核原則「判断は自分が握る」 + §著作権者表記「越川将人 / M.Koshikawa.」 + §動作確認義務 + §スコープ外への踏み込み禁止 を全面遵守する。

### 20th session 中盤壁打ちでの 4 軸方針確定

ADR-0033 起票前に user 主導で 4 軸の壁打ちが行われ、 ADR-0033 の出口像が以下に固定された (= ADR-0026-0032 と同 pattern、 軸 1-4 全部 A 案合意、 sub-sprint は 3 段階 (= 段階 1/2/3) で各々 α/β/γ/δ chain、 完全ホワイト化 milestone 確立)。

#### 軸 1: 同梱 rhythm sample の著作権帰属 (= A 案採用)

PMDNEO 配布物 (= ROM / source repository / WebApp 配布物 等の全 distribution channel) に embed する rhythm sample の著作権帰属:

- (a1) (= **採用**): 越川将人 100% 著作物のみ採用 (= 越川氏が録音 / 合成 / 編集した wav のみ embed、 GPL-3.0 で再配布、 license 連鎖完全切断、 future fork / 派生で license 健全性を継承可能)
- (a2) (= 不採用): Yamaha mask ROM dump 採用 (= BambooTracker / MAME / ymfm 経路の `fmopn_2608rom.h` literal embed、 Yamaha 著作物の literal copy = GPL-3.0 主張破綻、 license 連鎖 risk 最大、 永久排除)
- (a3) (= 不採用): community 配布 RSS wav 採用 (= `snesmusic.org/hoot/drum_samples.zip` 等の出所不明 wav embed、 「mimic」 主張は証拠不在、 projmd 流儀「for legal reasons, not included」 の認識と矛盾)
- (a4) (= 不採用): SampleScience / AREX 2011 等の RX-11 sample pack embed (= 実機 RX-11 録音由来 = Yamaha 著作物派生、 業界容認だが厳密 license clean ではない、 PMDNEO GPL-3.0 主張と不整合)
- (a5) (= 不採用): 中古 RX-11 hardware → analog 自己録音 wav embed (= hardware 所有権 ≠ 内蔵 sample 著作権、 結果 wav は依然 Yamaha 派生物、 PMDNEO 同梱 license risk 残存)

(a1) 採用根拠: GPL-3.0 整合性の唯一の literal path、 future fork / 派生作品が license 健全性を継承可能、 PMDNEO の「PMD culture を NEOGEO に持ち込む」 narrative を「越川氏が物理世界から音を持ち込む」 という強い物語性に昇華、 越川氏が KAJA 氏 / kuma4649 氏の延長として PMDNEO に立つ姿勢と完全整合、 「業界容認」 ≠ 「license 整合」 を PMDNEO で明確に区別する立場確立、 ADR-0033 完了で「PMDNEO は完全ホワイト化」 と公式宣言可能。

ADR / handoff 記載要件:
- 同梱 rhythm sample = **越川将人 100% 著作物のみ** (= 同梱 / 配布全 channel で literal 拘束)
- Yamaha mask ROM dump 形式 (= `fmopn_2608rom.h` / `ym2608_adpcm_rom.bin` 等) = **永久排除** (= PMDNEO build pipeline で取り込み禁止を契約化、 §Annex A-6 の sound-alike caution と整合)
- community 配布 RSS wav = **永久排除** (= 出所不明である事実を ADR §Annex A-2 に明記)
- 既存 RX-11 sample pack (= SampleScience / AREX 2011 / PausePlayRepeat 等) = PMDNEO **同梱しない**、 ただし越川氏個人 reference 用途は許可 (= 制作工程で聴くのは license 制限外、 出力配布物に含めなければ問題なし)
- 中古 RX-11 hardware analog 録音 wav = PMDNEO **同梱しない** (= hardware ownership と内蔵 sample copyright の境界明示、 越川氏が個人楽曲制作に使う分は自由)

#### 軸 2: migration approach 段階構造 (= A 案採用)

完全ホワイト化までの段階構造:

- (b1) (= **採用**): 3 段階 migration roadmap (= 段階 1 Surge XT 完全合成 prototype + OPNA pipeline 構築 → 段階 2 プロ session で acoustic drum 録音 → 段階 3 library 同梱判断 + 設計書統合 + README + LICENSE 整理)
- (b2) (= 不採用): 1 段階 即時差替え (= 既存 rhythm sample を直接置換、 検証なし、 PMDNEO build / verify pipeline の安定性を破壊する risk)
- (b3) (= 不採用): 2 段階 (= 合成のみで完結 / acoustic のみで完結 のどちらか単独、 pipeline 検証と本番品質を 1 sprint で両立する scope 肥大化)
- (b4) (= 不採用): 5+ 段階細分 (= sample 1 種ずつ別 sprint、 6 種 × 4 sub-sprint で sprint chain 過大、 全体完了 milestone が遠のく)

(b1) 採用根拠: 段階 1 で「投資 0 prototype + OPNA pipeline 構築」 を成立させると **段階 2 acoustic 録音前に pipeline 動作確認が完了**し、 段階 2 録音 day 終了直後に PMDNEO build 投入可能、 段階 3 で synth kit と acoustic kit の用途棲み分けを multi-table architecture (= ADR-0025) 経由で実現可能、 各段階の verify gate (= ymfm register trace + audio family-similarity) を独立に成立させやすい、 PMDNEO 既存 sub-sprint α/β/γ/δ chain 規律に完全整合 (= 各段階内で 4 sub-sprint)、 段階毎の milestone が明瞭で「完全ホワイト化」 達成を段階的に証明可能。

ADR / handoff 記載要件:
- 段階 1 = **Surge XT 完全合成 prototype + OPNA pipeline 構築** (= 投資 0、 license 完全 clean、 越川氏 100% 著作、 sub-sprint α/β/γ/δ chain、 future step 候補)
- 段階 2 = **プロ session で acoustic drum 録音** (= birch shell drum + cymbal、 RX-11 ルーツ整合、 work-for-hire 契約で越川氏 100% 著作、 sub-sprint α/β/γ/δ chain)
- 段階 3 = **library 同梱判断 + 設計書統合 + README + LICENSE 整理** (= synth kit vs acoustic kit 用途棲み分け、 multi-table 経由 kit 入替 design、 完全ホワイト化 milestone 確立、 sub-sprint α/β/γ/δ chain)
- 各段階間の transition gate = ymfm register trace byte-identical + audio family-similarity gate + 越川氏聴感 OK + 全 regression script PASS

#### 軸 3: current temporary fixture の扱い (= A 案採用)

ADR-0033 起票時点で PMDNEO `samples.inc` に embed されている既存 rhythm sample (= 起源未調査の current temporary fixture) の扱い:

- (c1) (= **採用**): 段階 3 完了まで暫定許容 + 段階 1 sub-sprint α で機械的起源調査を実施 + 調査結果を §Annex A-5 に記録 + 起源に応じた追加判断 (= Yamaha 由来なら段階 3 で即時差替え必須、 越川氏自前なら段階 3 完了まで継続許容)
- (c2) (= 不採用): 即時 blacklist (= ADR Accepted 同時に削除、 PMDNEO build pipeline が暫定停止、 段階 1 開始前に build 不能化、 scope 肥大化)
- (c3) (= 不採用): 永久許容 (= 起源調査せず継続使用、 ADR-0033 完全ホワイト化 milestone と矛盾、 license 健全性証明不能)

(c1) 採用根拠: PMDNEO build / verify pipeline の安定性を維持しつつ migration を段階的に進める実用判断、 「現状把握 → migration roadmap → 最終ホワイト化」 という現実的順序、 既存 ADR-0019 (= step 5 scope-out 固定 ADR) 流儀踏襲 (= 「即断 blacklist しない、 段階で migration」 という ADR 自体の意義)、 起源調査 (= §Annex A-5) を段階 1 sub-sprint α で機械的に実施することで判断材料を確保可能、 調査結果に応じて段階 3 で「即時差替え」 「継続許容」 を再判断する余地を残す、 越川氏の future judgement freedom を保持。

ADR / handoff 記載要件:
- current temporary fixture = **段階 3 完了まで暫定許容** (= 段階 1 着手時点で削除しない)
- 段階 1 sub-sprint α で **機械的起源調査** (= file 由来 / sha256 比較 / vendor/ 配下資産有無 / git history 等で起源特定)
- 調査結果 = **§Annex A-5 に literal 記録** (= 後埋め枠、 段階 1 sub-sprint α 完了時点で reveal)
- 起源 = Yamaha 由来 / 越川氏自前 / 出所不明 / 第三者著作物 等の分類別判断軸を §決定 11 で固定

#### 軸 4: sound-alike caution の明文化 (= A 案採用)

PMDNEO 同梱 rhythm sample が RX-11 / YM2608 内蔵 rhythm に「音色的に似ている」 ことの法的境界:

- (d1) (= **採用**): 「RX-11 に音色を似せること自体は OK、 ただし ROM sample derivative にならないようにする」 を §決定 14 + §Annex A-6 で literal 明文化
- (d2) (= 不採用): 「sound-alike も避ける」 (= 過剰防衛、 「物理楽器の音色は public domain」 という著作権法の前提と矛盾、 acoustic drum 録音まで否定する形になる)
- (d3) (= 不採用): 「sound-alike を意識せず作る」 (= migration narrative が「PMD culture 体験継承」 と乖離、 RX-11 ルーツ整合性を放棄)

(d1) 採用根拠: 著作権法上「録音物」 は録音実行時点の固定で保護される一方、 「物理楽器の音色」 は public domain、 「同じ acoustic drum を別途独立録音」 は別著作物として越川氏帰属、 「sound-alike = OK / ROM derivative = NG」 の境界は法理的に明確、 future contributor が「acoustic 自己録音は OK だが ROM dump は NG」 を正しく区別できるよう ADR + 設計書で明文化、 「mimic」 表現は出所証明不在の community 慣行と区別するため使わず、 PMDNEO は「越川氏自前録音 / 自前合成」 と明確に名乗る、 法的 risk を future fork / 派生作品でも継承可能。

ADR / handoff 記載要件:
- sound-alike caution = **明文化** (= §決定 14 + §Annex A-6 literal 拘束)
- 「RX-11 / YM2608 rhythm に音色を似せること」 = **許可** (= acoustic drum 物理楽器音は public domain、 越川氏 / contributor が独立録音 / 合成で似た音色を作るのは合法)
- 「ROM sample derivative」 = **永久禁止** (= Yamaha 1984 sound recording の literal copy / analog 経由 copy / digital dump 経由 copy 全て排除、 hardware ownership と sample copyright の境界明示)
- future contributor 向け **判断 decision tree** (= §Annex A-6 に明記、 「acoustic 自己録音 = OK / 中古 RX-11 自己録音 = NG / Surge XT 合成 = OK / 既存 free RX-11 sample pack 流用 = NG」 の典型例)
- 「mimic」 表現の **使用禁止** (= 出所証明不在の community 慣行と区別、 PMDNEO は「越川氏自前」 と明確に名乗る wording 規律)

### 21st session 冒頭壁打ちでの段階 1 sub-sprint α 5 軸方針確定

20th session 末で ADR-0033 Draft 起票 (= §決定 1-14 + scope + migration roadmap + Annex A-1 から A-7 + wording 規律) 完了後、 21st session 冒頭で段階 1 sub-sprint α (= 起票後最初の実作業 sub-sprint) の進め方を 5 軸壁打ちで確定した (= ADR-0026-0032 / ADR-0033 20th session 4 軸壁打ちと同 pattern、 軸 5-9 全部 user 推奨採用)。

#### 軸 5: current temporary fixture 起源調査の深度 (= B 中程度 forensic 採用)

ADR-0033 起票時点で PMDNEO `samples.inc` に embed されている既存 rhythm sample (= 6 種 drum 由来) + vendor 内未追跡 wav (= 2026-05-15 21st session 起点で `vendor/ngdevkit-examples/06-sound-adpcma/assets/lefthook.wav` 等が untracked 検出) の起源調査をどの深度で実施するか:

- (a) (= 不採用、 最小 forensic): sha256 + git log + filename pattern + 既知 sample pack 候補 top-level 一致確認のみ。 起源 4 分類の振り分けには足りるが、 Annex A-5 として証跡が薄い。
- (b) (= **採用**、 中程度 forensic): 最小 forensic + binary 内容 sampling (= header / sample rate / 長さ / spectral fingerprint) + BambooTracker / MAME / ymfm 経路と既知 RX-11 sample pack 公開 URL crawl 結果との照合。 起源特定が法的判断材料として残る形で記録。
- (c) (= 不採用、 深掘り forensic): 中程度 forensic + reverse research (= snesmusic.org/hoot/drum_samples.zip / SampleScience / AREX 2011 / PausePlayRepeat / projmd README literal / RSS 配布物全網羅) + 完全な起源 chain 再構築 + Annex A-5 を法務 review 可能 level まで詰める。 工数が大きすぎ、 完全ホワイト化 migration の本筋から外れる。
- (d) (= 不採用、 起源不明確定 + scope-out): 起源調査を諦め「unknown origin、 段階 3 で全排除 + 越川氏 100% 著作物に置換」 と Annex A-5 に明記して closed。 方針として正しいが、 現状 fixture の provenance 記録を残さないのは惜しい。

(b) 採用根拠: 「十分な調査をしたが、 最終的には置換する」 という判断材料が残り、 ADR-0033 完全ホワイト化 narrative の重要証跡となる。 法的判断ではなく engineering provenance note として記録、 sha256 含む engineering note + 起源不明なら "unknown origin, temporary only, must be replaced before full whitening" を 3 段階分類で literal 化。

ADR / handoff 記載要件:
- 調査深度 = **中程度 forensic** (= §決定 15 literal 拘束)
- Annex A-5 = **3 段階分類 (= confirmed / likely / unknown)** + engineering provenance note 性格 (= 法的判断ではなく engineering note)
- 調査軸 = sha256 / git log / filename pattern / file header / sample rate / bit depth / length / spectral fingerprint / current samples.inc 対応 / vendor 内 wav 関係 / BambooTracker・MAME・ymfm 経路非一致確認 / 既知 RX-11 sample pack 候補 top-level 照合

#### 軸 6: Surge XT prototype の粒度 (= B 設計明明 prototype 採用)

段階 1 sub-sprint β で作成する Surge XT prototype の精度 / 成果物形式:

- (a) (= 不採用、 最小 prototype): 6 patch 手作り + render wav 1 点ずつ。 設計仕様 doc は最小 (= patch 名 / 主要 param メモ)、 設計論理は Surge XT GUI 状態に委ねる。 OPNA pipeline 接続最短路だが「単なる wav 出力」 で創作過程説明不能。
- (b) (= **採用**、 設計明明 prototype): 最小 prototype + 各 patch の設計メモ (= osc 構成 / env / filter / FX / target frequency / target decay) + render audio 試聴 audition log + 「PMD drum culture に親和」 のコメント。 patch は future contributor (= fork 派生) も参照可能な状態。
- (c) (= 不採用、 中立設計 patch): RX-11 / OPNA 風 wording を一切使わず「越川氏設計 6 種 drum patch」 として中立設計。 ADR-0033 sound-alike caution の推奨 wording に完全準拠だが、 仕上がりが generic synthetic drum、 PMDNEO 独自の drum identity 確立を優先せず PMD culture narrative を弱める。

(b) 採用根拠: ADR-0033 本質は「越川氏 100% 著作」 を engineering provenance として残すこと、 patch 設計メモがあれば「どのように作ったか」 の創作過程を説明可能、 future contributor / fork 派生側に reference を残せる、 sound-alike caution と整合、 「設計された synth drum」 であることを示せる。

ADR / handoff 記載要件:
- prototype 粒度 = **設計明明 prototype** (= §決定 16 literal 拘束)
- 成果物 5 種 = `.fxp` / render wav / short design memo / audition log / intended role
- 推奨 wording = 「OPNA 風 drum」 「PMD rhythm family」 「retro FM/ADPCM drum aesthetic」 「越川氏自前合成」 「synthetic drum prototype」
- 禁止 wording = 「RX-11 clone」 「mimic」 「ROM recreation」 「RX-11 identical recreation」 (= 既存 §Annex A-6 wording 規律 + 「RX-11 identical recreation」 「ROM recreation」 を 21st session 追加)
- §migration roadmap 段階 1 で「文化的参照 (= PMD drum culture / RX-11 family 音色家族度)」 と「sample derivative (= ROM dump / sample pack 由来)」 を分離して書く

#### 軸 7: OPNA pipeline (= wav 44.1 kHz → 18.5 kHz decimate → 4-bit ADPCM-A → samples.inc embed) の scripts 化深度 (= C 完全 scripts 化 採用)

段階 1 sub-sprint γ で構築する OPNA pipeline の自動化深度:

- (a) (= 不採用、 手作業): scripts/ に何も作らず sox / ffmpeg / superctr/adpcm encoder を都度手打ち。 段階 1-2-3 で何度も反復する可能性があり cost 増、 future contributor も同 reproduce 不可。
- (b) (= 不採用、 単発 script): `scripts/wav_to_adpcma.sh` 1 本のみ。 最小限の reproduce 性、 verify 不足、 build target 統合なし。
- (c) (= **採用**、 完全 scripts 化): 単発 script + `scripts/build_drum_samples.sh` (= 6 drum 統括 build) + `scripts/verify-drum-samples.sh` (= sha256 / length / spectral fingerprint regression) + `Makefile` / `build.mk` target 追加候補 + Annex A-7 encoder 採用根拠記述。 段階 3 library 同梱時の reproducibility を doc level まで保障。
- (d) (= 不採用、 WebApp 統合方針優先): WebApp の WAV→ADPCM-A converter (= CLAUDE.md WebApp 機能 literal) に重複ロジック設定しないため scripts は最小限。 ただし scripts canonical を放棄するので source of truth が不明確化。

(c) 採用根拠: ADR-0033 は asset provenance / licensing / redistribution policy ADR で再現性が重要、 「越川氏 100% 著作」 主張には render 後 pipeline 追跡可能性が必要、 段階 1 synth / 段階 2 acoustic / 段階 3 library 全段階で同 pipeline 利用可能、 future contributor / fork 派生も同手順で検証可能。 手作業 (= a) は provenance / reproducibility が弱い。 WebApp 統合方針優先 (= d) は scripts canonical 放棄で source of truth 不明確。

ADR / handoff 記載要件:
- pipeline 自動化 = **完全 scripts 化** (= §決定 17 literal 拘束)
- 役割分離 = **scripts/ = canonical build / verification pipeline** (= source of truth、 byte-identical reproducibility 重視) + **WebApp converter = future UI / interactive converter** (= scripts と同仕様に追随する future UI、 重複ロジック設定しない)
- scripts 構成 = `scripts/wav_to_adpcma.sh` + `scripts/build_drum_samples.sh` + `scripts/verify-drum-samples.sh` + `Makefile` / `build.mk` target 追加候補
- 手作業変換 = **禁止 / 非推奨**
- byte-identical 再現性 = **重視**

#### 軸 8: ADPCM-A encoder の採用方針 (= B 既存 superctr/adpcm + 薄い wrapper 採用)

§決定 9 で「encoder 採用判断は段階 1 sub-sprint γ で superctr/adpcm 候補確認 + §Annex A-7 後埋め」 と既出。 21st session sub-sprint α 段階で採用方針を確定:

- (a) (= 不採用、 既存単独): `github.com/superctr/adpcm` を build tooling として直接利用、 wrapper script なし。 越川氏は patch 設計に集中可能だが、 PMDNEO 独自の standard parameter (= 18.5 kHz / 4-bit / mono) 固定機能を持たず future contributor 用途で散漫化。
- (b) (= **採用**、 既存 + 薄い wrapper): 既存 encoder 利用 + `scripts/wav_to_adpcma.sh` で PMDNEO 独自 default param + file 名規約 (= `2608_{bd,sd,top,hh,tom,rim}.wav`) を提供。 wrapper script は PMDNEO project license (= GPL-3.0)、 encoder 本体は vendor license 保持。
- (c) (= 不採用、 既存 + 検証 reference 並走): 既存 encoder + reference encoder (= 越川氏自作 or Python reference) で byte-identical 比較。 cross-verify 価値あるが encoder 自作 cost をほぼ全部発生させる。
- (d) (= 不採用、 完全自作 encoder): ADPCM-A encoder を PMDNEO scope 内で実装。 build tooling 100% PMDNEO 著作物化で fork 派生の license 追随単純化だが、 encoder 設計 / audio quality チューニング cost が段階 1 sub-sprint scope を越えて重い。

(b) 採用根拠: encoder 自作 (= d) は段階 1 scope として重すぎる、 越川氏 drum 音色設計 hand-on time を圧迫、 既存 encoder で越川氏は drum 音色設計に集中可能、 wrapper script を PMDNEO 側に持てば PMDNEO 標準 parameter を固定可能、 build reproducibility と future WebApp 統合の橋渡しになる、 encoder 本体 license と同梱 rhythm sample provenance を分離して扱える。

ADR / handoff 記載要件:
- encoder 採用 = **既存 `github.com/superctr/adpcm` 採用 + PMDNEO 側 薄い wrapper script** (= §決定 18 literal 拘束)
- wrapper script = `scripts/wav_to_adpcma.sh` (= PMDNEO project license = GPL-3.0)
- default parameter = mono / 18.5 kHz / 4-bit ADPCM-A / `2608_{bd,sd,top,hh,tom,rim}.wav` naming
- encoder 本体 license = **Annex A-7 に記録** (= vendor / 外部依存どちらにするかは段階 1 sub-sprint γ 着手時確定)
- encoder 自作 = **scope-out** (= 段階 1-3 全部で永久 scope-out)
- reference encoder 並走 = **future** (= 必要なら別 ADR 起票)
- build tooling provenance ≠ sample provenance (= 軸が別 + literal 区別)
- output ADPCM-A binary 由来 = input wav + pipeline metadata で追跡

#### 軸 9: acoustic recording 着手 timing (= D 段階 1 完全集中 + acoustic 後回し 採用)

§決定 6 で migration roadmap 3 段階 + 段階 2 = プロ session acoustic drum 録音 が既出。 21st session sub-sprint α 段階で段階 2 着手 timing を確定:

- (a) (= 不採用、 段階 1 完了 + 満足判断を trigger に同 session 着手): Surge XT 6 patch render が PMDNEO drum identity として合格なら acoustic 不要判断、 不満足なら acoustic recording を同 session で企画 + booking。 trigger 2 条件依存で動きが複雑化。
- (b) (= 不採用、 段階 1 完了 + V1 release 後企画): 段階 1 Surge XT prototype を V1 release 同梱、 V1 実績 + community fb を見てから acoustic 企画。 V1 を「synthetic kit で出す」 と確定する形になり、 「段階 2 acoustic は V1 含むか含まないか」 が ambiguous。
- (c) (= 不採用、 段階 1 中に booking 並走): Surge XT prototype 作成中に acoustic recording session を booking 並走、 段階 1 完了タイミングと同期で acoustic 実施。 V1 起こりが強くなるが cost / スケジュール調整が重く scope 過大。
- (d) (= **採用**、 段階 1 完全集中 + acoustic 後回し): ADR-0033 acoustic recording ポリシーは policy として固定、 企画・タイミングは future session 判断軸。 段階 1 sub-sprint を Surge XT prototype + OPNA pipeline + Annex A-5 / A-7 + wording 規律に集中。

(d) 採用根拠: 今は「越川氏 100% 著作 + OPNA pipeline + reproducible build」 を成立させるのが最優先、 acoustic recording は studio / drummer / contract / mic / editing まで含み軸が重い、 段階 1 だけでも patch design + render + pipeline + encoder + provenance + verify + documentation で十分大きい、 PMDNEO identity を「まず synthetic prototype で固める」 方が architecture 的にも綺麗、 Surge XT prototype が予想以上に PMDNEO identity に合えば acoustic を optional expansion にできる + V1 を synthetic kit で成立させられる、 「1 軸ずつ完了させる」 PMDNEO 流儀と整合、 push-per-commit 規律にも合う。

段階 1 / 段階 2 役割分離:
- **段階 1 = legality / reproducibility / ownership / pipeline** (= 完全ホワイト化への技術証明)
- **段階 2 = aesthetic refinement / acoustic realism / session quality** (= 音楽的完成度向上)

ADR / handoff 記載要件:
- acoustic recording = **future enhancement** (= §決定 19 literal 拘束、 ADR-0033 段階 2 として policy 保持、 企画・着手は future session judgement)
- 段階 1 completion = **先**
- 段階 2 trigger = **future session judgement**
- synthetic prototype 単独 release 可能性 = **明示維持** (= 越川氏聴感判断軸、 V1 を synthetic kit で成立させる選択肢)

## §決定

### §決定 1: PMDNEO 同梱 rhythm sample = 越川将人 100% 著作物のみ採用

PMDNEO 配布物 (= ROM image / source repository / WebApp 配布物 / future v1 release 等の全 distribution channel) に embed する rhythm sample は、 越川将人 100% 著作物のみとする。 越川氏が録音 / 合成 / 編集 / 取得した wav / ADPCM-A binary のみ embed 可、 GPL-3.0 で再配布、 license 連鎖完全切断。

軸 1 (a1) 採用の literal 拘束。 future fork / 派生作品が GPL-3.0 license 健全性を継承可能となる literal path。

### §決定 2: Yamaha mask ROM dump 永久排除

Yamaha mask ROM dump 形式の rhythm sample (= `fmopn_2608rom.h` / `ym2608_adpcm_rom.bin` 形式、 8 KB / 4-bit ADPCM 圧縮、 BambooTracker / MAME / ymfm 由来) は PMDNEO build pipeline で取り込み禁止。

軸 1 (a2) 不採用の literal 拘束。 PMDNEO build script / vromtool.py / samples.inc 生成 pipeline で `fmopn_2608rom.h` / `ym2608_adpcm_rom.bin` 等の Yamaha mask ROM dump origin file を input として受け付けない。 §Annex A-1 で BambooTracker / MAME / ymfm の embed 実装証跡を literal 記録、 将来 contributor が誤って取り込まないための reference とする。

### §決定 3: 出所不明 community 配布物排除

`snesmusic.org/hoot/drum_samples.zip` / 各種 PMD player 同梱 RSS wav set 等、 著者 / 録音 day / 録音 protocol / license 表記が不明な community 配布物は PMDNEO 同梱に採用しない。

軸 1 (a3) 不採用の literal 拘束。 「mimic = clone」 主張が証拠不在のため、 PMDNEO は出所証明可能な越川氏自前 wav のみ採用。 §Annex A-2 で projmd README *"for legal reasons, these files are not included"* literal を記録、 community 内 license 認識の共通理解として明示。

### §決定 4: 既存 RX-11 sample pack 排除 (個人 reference 用途は許可)

SampleScience RX-11 HD / AREX 2011 / PausePlayRepeat RX-11 / freewavesamples RX-15 等の既存 RX-11 / RX-15 sample pack は PMDNEO 同梱に採用しない。 ただし越川氏個人 reference 用途 (= 制作工程で「目標音」 を聴く、 FFT / RMS で家族度比較する 等) は許可、 出力配布物に sample 自体を含めなければ license 制限外。

軸 1 (a4) 不採用の literal 拘束。 実機 RX-11 録音由来 = Yamaha 著作物派生で業界容認だが厳密 license clean ではない、 という認識を ADR で明文化。

### §決定 5: 中古 RX-11 hardware analog 自己録音排除

越川氏が中古 RX-11 hardware を所有して analog 経由で録音した wav は PMDNEO 同梱に採用しない。 hardware ownership は内蔵 ROM 著作権を移転せず、 analog 経由でも結果 wav は依然 Yamaha sound recording の派生物となる (= CD を analog 経由で録音しても元曲 copyright が消えないのと同型)。 越川氏個人楽曲制作での利用は越川氏判断軸とし、 PMDNEO 配布物には含めない。

軸 1 (a5) 不採用の literal 拘束。 hardware ownership と sample copyright の境界を ADR で明文化、 future contributor が誤認しないための reference とする。

### §決定 6: migration roadmap 3 段階

完全ホワイト化までの段階構造を 3 段階で固定:

- **段階 1**: Surge XT 完全合成 prototype + OPNA pipeline 構築 (= 投資 0、 license 完全 clean、 越川氏 100% 著作)
- **段階 2**: プロ session で acoustic drum 録音 (= birch shell drum + cymbal、 RX-11 ルーツ整合、 work-for-hire 契約で越川氏 100% 著作)
- **段階 3**: library 同梱判断 + 設計書統合 + README + LICENSE 整理 (= synth kit / acoustic kit 用途棲み分け、 multi-table 経由 kit 入替 design、 完全ホワイト化 milestone 確立)

各段階内で sub-sprint α/β/γ/δ chain (= ADR Draft 修正 + 実装 + verify + 完了統合) で進行、 既存 PMDNEO 規律 (= 1 sub-sprint = 1 commit + 1 push) に完全整合。

軸 2 (b1) 採用の literal 拘束。 各段階の詳細は §migration roadmap 章で展開。

### §決定 7: 命名規則 = PMD culture 互換

PMDNEO 同梱 rhythm wav (= source wav、 chip 化前の原音) の file 名は PMD culture 互換命名規則を採用:

- `2608_bd.wav` (= Bass Drum)
- `2608_sd.wav` (= Snare Drum)
- `2608_top.wav` (= Top Cymbal = PMD MML `\c` semantics、 「TOP」 wording は ADR-0029 「top」 vs 「CYM」 wording 分離規律踏襲、 sample provenance 名としての「top」)
- `2608_hh.wav` (= Hi-Hat)
- `2608_tom.wav` (= Tom = PMD MML `\t` semantics、 「tom」 wording は ADR-0030 「tom」 = sample provenance 名 + PMD semantics 名 完全一致 規律踏襲)
- `2608_rim.wav` (= Rim Shot = PMD MML `\i` semantics、 「rim」 wording は ADR-0031 「rim」 = sample provenance 名 + PMD semantics 名 完全一致 規律踏襲)

PMDDotNET / mml2vgm / projmd / FMPMD2000 / Neko Project (np2) と命名互換、 future PMDNEO sample 入替えで PMD ecosystem 全体に provide する形態を想定。

### §決定 8: source wav format = RIFF WAVE PCM / 1 ch / 44100 Hz / 16 bit

source wav (= chip 化前の原音 wav) format は PMD culture 公式仕様に従う:

- format: RIFF WAVE PCM (= 非圧縮)
- channels: 1 (mono)
- sample rate: 44100 Hz
- bit depth: 16 bit

pedipanol's MML guide (= mml-guide.readthedocs.io) + projmd / PMDDotNET / mml2vgm setup doc literal 仕様踏襲。 §Annex A-3 で literal 引用。

### §決定 9: chip 化 pipeline = 18.5 kHz decimate + 4-bit ADPCM-A 圧縮

source wav から chip 内 ADPCM-A bank への変換 pipeline は以下を採用:

1. **18.5 kHz decimate** (= 44100 Hz → 18500 Hz、 YM2610 ADPCM-A nominal sample rate)
2. **short envelope 適用** (= drum 種ごとに 50-500 ms attack-decay、 越川氏判断軸)
3. **4-bit ADPCM-A 圧縮** (= Yamaha 4-bit ADPCM、 encoder 採用判断は段階 1 sub-sprint γ で実施、 候補 = `github.com/superctr/adpcm` 既存 library、 license 確認 + 動作確認後採用、 自前 encoder 実装は不採用 (= 3 行重複より早すぎる抽象化を避ける CLAUDE.md §スコープ外 規律))
4. **`samples.inc` 形式 Z80 assembly 出力** (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 既存 PMDNEO build pipeline 整合)
5. **driver 引き table 接続** (= ADR-0023/0024/0025 multi-table architecture 経由、 ADR-0019 sample addr build-time embed 経路)

encoder 採用判断は段階 1 sub-sprint γ で実施、 §Annex A-7 に採用根拠を記録予定。

### §決定 10: multi-table architecture (= ADR-0025) 経由 kit 入替

synth kit (= 段階 1 Surge XT 合成由来) と acoustic kit (= 段階 2 プロ session 録音由来) の両方を default kit 候補として保持し、 ADR-0025 で確立した multi-table architecture (= `sample_table_id` selection consumption) 経由で kit 入替を実現する。

具体的:
- `sample_table_id=0x00`: 段階 3 で決定される primary kit (= synth or acoustic、 越川氏判断軸)
- `sample_table_id=0x01`: 段階 3 で決定される secondary kit (= primary の対立 kit)
- multi-table architecture 経由で `.PNE` 切替により kit 入替 (= ADR-0025 proof-of-selection stage が実用 segment に進化)

driver Z80 source は完全不変 (= ADR-0025 dispatch path 1 本化維持)。 段階 3 で primary kit 選定 + 設計書記載 + README 反映を完了。

### §決定 11: current temporary fixture 段階 3 完了まで暫定許容

ADR-0033 起票時点で PMDNEO `samples.inc` に embed されている既存 rhythm sample は段階 3 完了まで暫定許容、 段階 1 sub-sprint α で機械的起源調査を実施 + 結果を §Annex A-5 に記録する。

調査結果に応じた追加判断:
- **起源 = Yamaha mask ROM dump 由来**: 段階 3 完了 + 越川氏自前 sample 完成と **同時に即時差替え必須** (= 永久排除契約 §決定 2 と整合、 §Annex A-5 で literal 記録)
- **起源 = 越川氏自前 (= 過去 sprint で越川氏が作成 / 録音)**: 段階 3 完了まで継続許容、 越川氏自前 sample 完成後は越川氏判断で残置 / 差替えを選択
- **起源 = 出所不明 community 配布物**: 段階 3 完了 + 越川氏自前 sample 完成と **同時に即時差替え必須** (= 永久排除契約 §決定 3 と整合)
- **起源 = ngdevkit-examples / 他 GPL-3.0 / CC0 等の license clean 第三者著作物**: 段階 3 完了まで継続許容、 越川氏自前 sample 完成後は越川氏判断軸 (= 第三者著作物継続使用は license 整合だが、 「PMDNEO は完全自作」 narrative とは別判断)

軸 3 (c1) 採用の literal 拘束。

### §決定 12: 段階 3 完了後の越川氏自前以外排除契約

段階 3 完了 (= 完全ホワイト化 milestone 確立) 以降、 越川氏自前以外の rhythm wav は PMDNEO build pipeline に反映しない:

- Yamaha mask ROM dump = 永久排除 (= §決定 2 強化)
- 出所不明 community 配布物 = 永久排除 (= §決定 3 強化)
- 既存 RX-11 sample pack = 永久排除 (= §決定 4 強化)
- 中古 RX-11 自己録音 = 永久排除 (= §決定 5 強化)
- 段階 3 完了時点で current temporary fixture に残存する第三者著作物 = 越川氏判断で残置 / 差替えを最終決定 (= §決定 11 連動)

段階 3 完了後の policy violation = ADR 違反として future contributor / fork 側でも継承される literal 拘束。 「PMDNEO は完全ホワイト化済」 という公式 narrative を破壊しない契約。

### §決定 13: future contributor / fork 派生作品向け license 連鎖継承明示

PMDNEO repository の future contributor 受入 + fork 派生作品が「PMDNEO は完全ホワイト化済」 narrative を継承する場合の license 連鎖規律を明示:

- PMDNEO が同梱する越川氏自作 rhythm sample は、 **PMDNEO の定めるライセンス条件に従って再利用可能** (= PMDNEO repository が宣言する license 条件下で fork 派生作品でも継続利用可能、 将来 PMDNEO 全体 license 構造が変化した場合は当該変化に追随、 ライセンス条件の具体 wording を §決定 13 内では cement せず PMDNEO 本体 license に追随する設計判断 = ADR 自体が license 構造の最終決定者ではない)
- **第三者由来 sample の混入は禁止** (= contributor が新たに rhythm sample を PR 形式で提案する場合、 contributor 自身が 100% 著作権者である証拠を提示する義務、 越川氏 review で license 検証必須、 §決定 14 sound-alike caution + §Annex A-6 decision tree 適用)
- fork / 派生 project が別 sample を追加する場合は、 **各 fork 側で provenance を明示する義務** (= fork 側が「PMDNEO は完全ホワイト化済」 narrative を継承するなら、 越川氏自前 sample を借用するか、 fork 側 contributor が独自自作するかの選択肢、 各 sample の出所 / 著作権者 / 録音 day / 録音機材 / license 表記を fork 側 ADR / 設計書 / LICENSE / metadata.md 等で literal 明示する義務、 PMDNEO 上流 narrative の license 健全性を fork 側で破壊しない契約)
- §決定 2-5 の永久排除契約 = **fork 派生でも継承** (= PMDNEO 名乗りで配布する以上、 Yamaha mask ROM dump / community 配布物 / 既存 RX-11 sample pack / 中古 RX-11 自己録音は永久排除、 fork 側で同 sample 群を新規 embed すると「PMDNEO 完全ホワイト化済」 narrative 自体が破壊される)
- ライセンス条件不整合の解釈順序 = (1) PMDNEO 本体 license 宣言が primary、 (2) ADR-0033 §決定が secondary、 (3) 個別 sample metadata が tertiary、 (4) fork 側 ADR / LICENSE 等は fork repository scope 内で primary、 ただし PMDNEO 上流継承 narrative を fork 側で逸脱する場合は fork 側で「PMDNEO 系列を名乗らない」 選択肢を取る義務 (= license narrative の純度を保つため)

### §決定 14: sound-alike caution の明文化

PMDNEO 同梱 rhythm sample が RX-11 / YM2608 内蔵 rhythm に「音色的に似ている」 ことは許容、 ただし「ROM sample derivative にならない」 ことを保証する規律を §Annex A-6 で literal 明文化:

- **「RX-11 / YM2608 rhythm に音色を似せること」 = 許可** (= 物理楽器音は public domain、 越川氏 / contributor が独立録音 / 合成で似た音色を作るのは合法)
- **「ROM sample derivative」 = 永久禁止** (= Yamaha 1984 sound recording の literal copy / analog 経由 copy / digital dump 経由 copy / sample-based emulator output 録音 全て排除)
- **判断 decision tree** = §Annex A-6 で future contributor 向け典型例を明記:
  - acoustic 自己録音 = ✓ OK (= 物理楽器音 public domain + 越川氏帰属録音)
  - Surge XT 完全合成 = ✓ OK (= 数学計算のみ、 既存録音物使わず)
  - 中古 RX-11 自己録音 = ✗ NG (= hardware ownership ≠ sample copyright)
  - 既存 free RX-11 sample pack 流用 = ✗ NG (= 第三者録音物の二次配布)
  - MAME / ymfm 経由 OPNA emulator output 録音 = ✗ NG (= 元 sample が Yamaha mask ROM dump)
- **「mimic」 表現の使用禁止** (= 出所証明不在の community 慣行と区別、 PMDNEO は「越川氏自前録音」 「越川氏自前合成」 と明確に名乗る wording 規律)

軸 4 (d1) 採用の literal 拘束。

### §決定 15: current temporary fixture 起源調査 = 中程度 forensic + 3 段階分類 + engineering provenance note

段階 1 sub-sprint α で実施する current temporary fixture (= ADR-0033 起票時点で `samples.inc` に embed されている既存 rhythm sample + vendor 内未追跡 wav) の起源調査を中程度 forensic で実施し、 結果を §Annex A-5 に **confirmed / likely / unknown** 3 段階分類 + engineering provenance note として記録する。

調査軸 (= §Annex A-5 後埋め時の具体実施項目):
1. sha256 / git log (= 作成経緯) / filename pattern
2. file header / sample rate / bit depth / length
3. basic waveform / spectral fingerprint
4. current samples.inc との対応 / vendor 内 wav (= `vendor/PMDDotNET/` / `vendor/pmd48s/` / `vendor/ngdevkit-examples/` 配下) との関係
5. BambooTracker `chip/mame/fmopn_2608rom.h` / ymfm extern reference / MAME 経路との非一致確認
6. 既知 RX-11 sample pack 候補 (= SampleScience / AREX 2011 / PausePlayRepeat / freewavesamples 等) との top-level 照合
7. snesmusic.org/hoot/drum_samples.zip + PMD player 同梱 RSS wav set との top-level 照合

調査の目的:
- **起源を完全に暴くことではなく** 「段階 3 で越川氏 100% 著作物に置換する判断を補強する」
- **法的判断ではなく engineering provenance note** として記録
- §Annex A-5 = sha256 含む engineering note + 3 段階分類

3 段階分類:
- **confirmed**: 起源が機械的に特定済 (= sha256 一致 / git log 明示 / file header 明示)
- **likely**: 起源が高確度で推定可能 (= 命名 + 配置 + 内容類似で 1 候補に絞れる)
- **unknown**: 起源が特定不能 (= "unknown origin, temporary only, must be replaced before full whitening" を literal で記録)

軸 5 (b) 採用の literal 拘束。 §決定 11 (= 起源 4 分類別追加判断軸) と整合、 §決定 11 は政策軸 / §決定 15 は forensic 実施軸として並存。

### §決定 16: Surge XT prototype = 設計明明 prototype (= 5 成果物 + sound-alike 推奨 wording)

段階 1 sub-sprint β で作成する Surge XT prototype を「設計明明 prototype」 として作成する。 6 patch (= BD/SD/CYM/HH/TOM/RIM) ごとに以下 5 種類の成果物を残す:

1. `.fxp` / Surge patch (= 各 drum、 越川氏 100% 著作)
2. render wav (= 44100 Hz / 16 bit / mono、 §決定 7 / §決定 8 仕様準拠)
3. short design memo (= osc 構成 / env / filter / FX / target frequency / target decay)
4. audition log (= 越川氏聴感 + 「PMD drum culture に親和」 コメント)
5. intended role (= BD/SD/CYM/HH/TOM/RIM、 PMD MML semantics との mapping 明記)

sound-alike caution 連動 wording 規律 (= §決定 14 + §Annex A-6 整合):

- ✓ 推奨 wording (= 21st session 追加分):
  - 「OPNA 風 drum」
  - 「PMD rhythm family」
  - 「retro FM/ADPCM drum aesthetic」
  - 「越川氏自前合成」
  - 「synthetic drum prototype」
- ✗ 禁止 wording (= 21st session 追加分):
  - 「RX-11 clone」
  - 「mimic」
  - 「ROM recreation」
  - 「RX-11 identical recreation」

§migration roadmap 段階 1 内記述で「文化的参照」 と「sample derivative」 を分離:

- **文化的参照 (= 許可)**: PMD drum culture / RX-11 family の音色家族度に親和する設計、 §Annex A-6 sound-alike caution 適用範囲内
- **sample derivative (= 禁止)**: ROM dump / sample pack 由来、 §決定 2-5 永久排除契約適用

軸 6 (b) 採用の literal 拘束。 future contributor / fork 派生作品でも同 wording 規律継承 (= §決定 13 license 連鎖継承明示と整合)。

### §決定 17: OPNA pipeline = 完全 scripts 化 (= canonical source + future WebApp UI 役割分離)

段階 1 sub-sprint γ で構築する OPNA pipeline (= wav 44.1 kHz → 18.5 kHz decimate → 4-bit ADPCM-A encode → samples.inc embed) を完全 scripts 化する。

scripts 構成:
- `scripts/wav_to_adpcma.sh` (= 単 wav 変換 wrapper、 superctr/adpcm 呼出し、 §決定 18 連動)
- `scripts/build_drum_samples.sh` (= 6 drum 統括 build)
- `scripts/verify-drum-samples.sh` (= sha256 / length / sample rate / channel count / bit depth / ADPCM-A output size regression)
- `Makefile` / `build.mk` target 追加候補 (= 既存 ADR-0019 build-time embed 経路と整合)

役割分離 (= source of truth 軸):
- **scripts/ = canonical build / verification pipeline** (= source of truth、 byte-identical reproducibility 重視)
- **WebApp converter = future UI / interactive converter** (= scripts と同仕様に追随する future UI、 重複ロジック設定しない、 CLAUDE.md WebApp 機能 literal 「WAV → ADPCM-A / ADPCM-B コンバータ」 は scripts 仕様を踏襲する形)

literal 拘束:
- scripts CLI = source of truth (= 永久維持)
- WebApp converter (= Phase 3/4) = scripts 仕様に追随する future UI
- 手作業変換 = **禁止 / 非推奨**
- byte-identical 再現性 = **重視** (= 同 source wav から同 ADPCM-A binary が出ること)

軸 7 (c) 採用の literal 拘束。

### §決定 18: ADPCM-A encoder = 既存 superctr/adpcm + PMDNEO 側薄い wrapper script

§決定 9 の encoder 採用判断 (= 段階 1 sub-sprint γ で確定予定) を 21st session sub-sprint α で前倒し確定:

- **encoder 本体** = 既存 `github.com/superctr/adpcm` 採用 (= sound chip ADPCM codec library、 YM2610 ADPCM-A 対応、 既存 library、 license / 動作確認 / 採用根拠の literal 記録は段階 1 sub-sprint γ で実施)
- **PMDNEO 側 wrapper script** = `scripts/wav_to_adpcma.sh` (= PMDNEO project license = GPL-3.0、 default parameter mono / 18.5 kHz / 4-bit / `2608_{bd,sd,top,hh,tom,rim}.wav` naming)

採用構造:
- **superctr/adpcm = build tooling** (= encoder source は PMDNEO 同梱物の著作性とは別軸、 vendor / 外部依存どちらにするかは段階 1 sub-sprint γ 着手時確定)
- **wrapper script = PMDNEO project license** (= GPL-3.0)

literal 拘束:
- encoder 自作 = **scope-out** (= 段階 1-3 全部で永久 scope-out、 越川氏 drum 音色設計 hand-on time を圧迫しない)
- reference encoder 並走 = **future** (= 必要なら別 ADR で起票)
- **build tooling provenance ≠ sample provenance** (= 軸が別、 同梱物に encoder source ではなく output ADPCM-A binary のみ embed)
- output ADPCM-A binary の由来 = input wav (= 越川氏 100% 著作) + pipeline metadata (= encoder version + parameter) で追跡

軸 8 (b) 採用の literal 拘束。 §決定 9 の「encoder 採用判断は段階 1 sub-sprint γ で実施」 を 21st session sub-sprint α で前倒し確定したことに対応、 sub-sprint γ では license / 動作確認 / Annex A-7 後埋め記述のみ実施。

### §決定 19: 段階 1 完全集中 + acoustic recording 後回し (= 段階 1 / 段階 2 役割分離)

段階 1 sub-sprint α 着手時点で段階 2 (= acoustic recording) は **future session judgement** に後回し、 段階 1 (= Surge XT prototype + OPNA pipeline + Annex 後埋め + wording 規律) に完全集中する。

段階 1 / 段階 2 役割分離 (= 21st session 中核 wording):
- **段階 1 = legality / reproducibility / ownership / pipeline** (= 完全ホワイト化への技術証明、 越川氏 100% 著作 + OPNA pipeline + reproducible build 成立)
- **段階 2 = aesthetic refinement / acoustic realism / session quality** (= 音楽的完成度向上)

段階 2 起動 trigger (= future session judgement):
- 越川氏聴感判断 = Surge XT prototype が PMDNEO drum identity として不満足、 かつ acoustic 技術的見込みあり (= studio / drummer / contract / mic / editing 等の見通し)
- ADR-0033 段階 2 sub-sprint α (= studio + drum kit + drummer 選定 + 録音 protocol 追記) を future session で起動

synthetic prototype 単独 release 可能性:
- Surge XT prototype が予想以上に PMDNEO identity に合う場合、 acoustic を **optional expansion** にできる (= 段階 2 を起動せず段階 1 で完結も可能)
- V1 を synthetic kit で成立させる選択肢 (= 越川氏聴感判断軸、 permanent retained)

literal 拘束:
- acoustic recording = **future enhancement** (= ADR-0033 段階 2 として policy 保持、 企画・着手は future session judgement)
- 段階 1 completion = **先** (= 21st session sub-sprint α 着手時の優先順位)
- synthetic prototype 単独 release 可能性 = **明示維持**

軸 9 (d) 採用の literal 拘束。 §決定 6 (= migration roadmap 3 段階) と整合、 §決定 6 は roadmap 軸 / §決定 19 は timing / 役割分離軸として並存。

## scope-in

ADR-0033 が扱う範囲 (= 段階 1-3 sprint 全体で消化):

- BD / SD / TOP / HH / TOM / RIM 6 種の越川氏 100% 自作化 (= 軸 1 + §決定 1)
- 越川氏帰属 + GPL-3.0 再配布可能 asset 確立 (= §決定 1 + §決定 13)
- provenance 記録 (= 録音 day / studio / 機材 / drummer / take 数 / 編集 log 等の制作 metadata、 §Annex A-5 ベース)
- converter pipeline (= wav → 18.5 kHz decimate + 4-bit ADPCM-A 圧縮 → `samples.inc` 出力、 §決定 9 + §Annex A-7)
- sample replacement policy (= ADR-0025 multi-table architecture 経由の kit 入替 contract、 §決定 10)
- current temporary fixture 起源調査 (= 段階 1 sub-sprint α で機械的実施、 §決定 11 + §Annex A-5)
- ADR-0033 完了後の future contribution 受入 policy (= §決定 13)
- sound-alike caution (= §決定 14 + §Annex A-6)
- BambooTracker / MAME / ymfm / community 配布物 / 既存 sample pack の license 整理 (= §Annex A-1 + A-2)
- PMD culture rhythm.wav 公式仕様踏襲 (= §決定 7 + §決定 8 + §Annex A-3)
- YM2608 rhythm sample 系譜 (= 1984 RX-11 → DD10 → YM2608 経路、 §Annex A-4)

## scope-out

ADR-0033 が **触らない** 範囲 (= 32 項目以上、 ADR-0019 / ADR-0031 / ADR-0032 規律踏襲):

- runtime dispatch semantics (= ADR-0026-0031 で完了済、 ADR-0033 で再触らない)
- simultaneous trigger semantics (= ADR-0032 で別軸、 ADR-0033 で再触らない)
- OPNA timing fidelity (= runtime semantics 軸、 ADR-0033 で再触らない)
- driver Z80 source 改修 (= migration は driver 完全不変前提、 §決定 1-10 内で driver 改修ゼロ literal 拘束)
- pmdneo_rhythm_event_trigger @ 0x001126 entry addr 移動 (= ADR-0026-0031 invariant 維持、 ADR-0033 で再触らない)
- pmdneo_rhythm_event_*_trigger sub-routine 改修 (= 同上)
- bit 0 → bit 5 dispatch order semantics (= ADR-0032 §決定 で固定済、 ADR-0033 で再触らない)
- multi-bit bitmap dispatch latent semantics (= ADR-0032 で別軸)
- L ch scaffold 解除 (= ADR-0026 / ADR-0030 / ADR-0031 規律踏襲、 multi-channel allocation は future sprint)
- ADPCM-A 6 ch sub-allocation (= L ch scaffold 維持 + future sprint)
- PCM subsystem 全般 (= ADPCM-B / .PPC / .P86、 別 ADR 候補、 ADR-0033 で touch なし)
- `.PNE` rhythm bank の wire format 設計 (= Step 18+ 別候補、 ADR-0033 で touch なし)
- `.PNE` 動的 sample lookup (= future sprint、 ADR-0023 §決定 11 「playback decision に使用しない literal 維持」 解除は別 ADR)
- `#PCMFile` integration (= Step 18+ 別候補)
- K/R 制御 cmd (= 音量 / pan 等) 現役化 (= ADR-0016 §決定 2 K part scope-out 解除は別 ADR、 ADR-0033 で touch なし)
- WebApp 配布物 (= Phase 3/4 別軸)
- IPL (= 越川氏オリジナル別 license、 ADR-0033 で touch なし)
- プレイヤー V1 (= Phase 4 別軸)
- AES+ 実機 audio gate (= 既存 audio gate 体系の別軸、 ADR-0033 段階 1-3 verify では MAME 中心)
- 商用 sample pack の license 個別交渉 (= 排除方針なので negotiation 不要、 §決定 4 永久拘束)
- Yamaha 株式会社との license 交渉 (= 排除方針、 §決定 2 永久拘束)
- ROM dump 形式の検出 / blacklist 自動化 (= contributor 自己責任、 §決定 13 license 連鎖継承明示で代替)
- vendor/PMDDotNET / vendor/pmd48s 内 rhythm 資産の借用 (= license 連鎖 risk、 §Annex A-5 起源調査結果次第で追加判断)
- DD10 / RX-15 / RX-21 / RX-5 / RX-7 等 Yamaha drum machine 系の sample 取り込み (= 全て Yamaha mask ROM dump 系譜、 §決定 2 永久拘束)
- TR-808 / TR-909 / Linn LM-1 / Drumulator 等他社 drum machine 系の sample 取り込み (= 第三者著作物、 §決定 13 contributor 自己責任)
- Plogue chipsynth 系商用 plugin の output embed (= 商用 license、 §決定 4 永久拘束)
- Freesound.org CC0 drum kit の embed (= 第三者著作物、 越川氏判断軸、 ADR-0033 段階 3 で必要なら別判断)
- MT Power Drum Kit 2 / Steven Slate Drums SSD5 等 free drum sample pack の embed (= 第三者著作物 EULA 依存、 §決定 4 流儀拘束、 ADR-0033 段階 3 で必要なら別判断)
- audio-gate.sh legacy script (= memory `project_audio_gate_sh_gngeo_legacy.md` 既 scope-out、 ADR-0033 verify は scripts/run-mame.sh 系を使う)
- v1 release タイミング (= 別 ADR / 別 milestone)
- v1 release アナウンス内 license narrative (= 段階 3 完了後の別 sprint)
- PMD V4.8s 公式 source (= vendor/pmd48s/、 KAJA 氏 GPL-3.0 公開) 内の rhythm 資産有無 (= 段階 1 sub-sprint α 機械的調査の対象、 起源調査結果次第で判断)

## migration roadmap

### 段階 1: Surge XT 完全合成 prototype + OPNA pipeline 構築

#### sub-sprint α: ADR-0033 起票 + ADR-0033 update (= 5 軸決定反映) + current temporary fixture 起源調査 + Surge XT 環境設置

ADR-0033 Draft 起票 (= 20th session 末 commit、 §決定 1-14 + scope + roadmap + §Annex A-1〜A-7 枠 + 完了判定 10 項目 + wording 規律)。

**ADR-0033 Draft update (= 21st session 本 commit):**
- §決定 15-19 追加 (= 5 軸壁打ち決定の literal 拘束、 軸 5 forensic 深度 / 軸 6 prototype 粒度 / 軸 7 pipeline scripts 化 / 軸 8 encoder 採用 / 軸 9 acoustic timing)
- §Annex A-5 後埋め枠 update (= 3 段階分類 confirmed / likely / unknown + engineering provenance note 性格 + 中程度 forensic 7 調査軸 literal 化)
- §Annex A-7 後埋め枠 update (= superctr/adpcm + wrapper script 採用方針確定、 sub-sprint γ で license + 動作確認 + 採用根拠 literal 反映)
- ## 重要 wording 規律 拡充 (= 21st session 追加推奨 wording + 禁止 wording)
- 本 sub-sprint α 内容詳細化 (= 本 update)

**current temporary fixture 中程度 forensic 起源調査 (= §決定 15 + §Annex A-5 literal 反映、 21st session 内または next session で実施):**
- 7 調査軸 (= §決定 15 literal):
  1. sha256 / git log (= 作成経緯) / filename pattern
  2. file header / sample rate / bit depth / length
  3. basic waveform / spectral fingerprint
  4. current `samples.inc` 内 rhythm sample 開始 addr + binary 内容との対応 / vendor 内 wav 関係
  5. BambooTracker `chip/mame/fmopn_2608rom.h` / ymfm extern reference / MAME 経路非一致確認
  6. 既知 RX-11 sample pack 候補 (= SampleScience / AREX 2011 / PausePlayRepeat / freewavesamples 等) との top-level 照合
  7. snesmusic.org/hoot/drum_samples.zip + PMD player 同梱 RSS wav set + ngdevkit-examples との top-level 照合
- 結果を §Annex A-5 に 3 段階分類 (= confirmed / likely / unknown) + 起源 4 分類別判断 + engineering provenance note として表形式で literal 反映 (= update commit)

**Surge XT install (= 越川氏 hand-on、 越川氏 macOS):**
- 公式 https://surge-synthesizer.github.io/ から download (= 無料、 GPL-3.0)
- VST3 / AU / standalone の 3 形式が同梱、 standalone で DAW なしで wav export 可能
- 確認: install 後 BD prototype patch 1 件で「合成 path が現実的か」 を hand-on 体感

**reference 機材設置 (= 越川氏個人 license、 PMDNEO 同梱しない、 §決定 4 個人 reference 用途許可):**
- AREX 2011 (= free VSTi、 Windows のみ、 越川氏判断で skip 可)
- SampleScience RX-11 HD (= 無料 / 個人 reference、 越川氏判断軸)

完了判定 (= 21st session 反映、 sub-sprint α 完了で sub-sprint β = Surge XT 6 patch 設計に進む):
- ADR-0033 Draft update commit 完了 (= §決定 15-19 + Annex A-5 / A-7 update + wording 規律拡充 + sub-sprint α 詳細化)
- §Annex A-5 起源調査結果 literal 記録済 (= 中程度 forensic 7 軸 + 3 段階分類 + 起源 4 分類別判断 + engineering provenance note 表形式)
- Surge XT install 確認、 BD prototype 1 件 hand-on (= 越川氏 hand-on)
- handoff doc + memory + commit + push 完了

#### sub-sprint β: Surge XT で 6 種 patch 設計 + wav render

BD / SD / TOP / HH / TOM / RIM 各 patch 設計 (= 1 patch 30 分 - 1 時間目安、 越川氏判断軸):
- BD: sine wave (= 50-80 Hz) + pitch envelope + amp envelope short attack + long decay
- SD: noise + band-pass filter (= 200 Hz 中心) + 別 layer sine 100-200 Hz body
- TOP: noise + hi-pass filter (= 6 kHz 以上) + long decay (= 1-3 秒) + FM modulation
- HH: noise + hi-pass filter (= 7 kHz 以上) + very short decay (= 50-150 ms)
- TOM: BD と同構造で pitch 中音域 (= 100-300 Hz)
- RIM: short click + short body sine (= 800 Hz)

各 patch を 44100 Hz / 16 bit / mono で render (= §決定 8 仕様):
- file 名: `2608_bd.wav` / `2608_sd.wav` / `2608_top.wav` / `2608_hh.wav` / `2608_tom.wav` / `2608_rim.wav` (= §決定 7 命名)
- 配置: `assets/rhythm/synth/` (= 仮、 越川氏判断軸)
- 越川氏 100% 著作物確定 (= §決定 1)

reference 比較:
- AREX 2011 / SampleScience RX-11 HD 個人 reference 環境で「目標音」 聴感確認
- FFT spectrum + RMS envelope で家族度評価 (= 越川氏判断軸)

完了判定:
- 6 種 wav render 完了
- 越川氏 100% 著作物確定 + file 名 規律準拠
- reference との家族度評価 メモ化
- commit + push 完了

#### sub-sprint γ: OPNA pipeline 構築 (= wav → samples.inc 自動化)

`scripts/wav2adpcma.py` (= 仮称) 新規作成:
- 入力: 44100 Hz / 16 bit / mono wav (= §決定 8 仕様)
- 処理 1: 18.5 kHz decimate (= scipy.signal.decimate 等)
- 処理 2: 4-bit ADPCM-A 圧縮 (= encoder 採用判断、 候補 = `github.com/superctr/adpcm` 既存 library)
- 処理 3: `samples.inc` 形式 Z80 assembly 出力 (= 既存 PMDNEO build pipeline 整合)
- encoder 採用判断 = §Annex A-7 に literal 記録

build pipeline 統合:
- `Makefile` / `build.mk` で `assets/rhythm/synth/2608_*.wav` から `build/assets/samples.inc` 自動生成
- 既存 vromtool.py / ADR-0019 sample addr build-time embed 経路と整合

verify:
- Surge XT prototype 6 種を pipeline 通して `samples.inc` 生成
- PMDNEO build → MAME 再生 → ymfm register write trace
- 各 drum sub-routine entry で sample addr literal が新 sample 位置を指していること確認

完了判定:
- wav2adpcma.py 動作確認 + encoder 採用根拠 §Annex A-7 記録
- build pipeline 統合済
- PMDNEO build + MAME 再生で synth kit 6 種音色観測可能
- commit + push 完了

#### sub-sprint δ: 段階 1 完了統合 + verify

verify gate:
- ymfm register write trace で K \b/\s/\c/\h/\t/\i 各打鍵時の sample addr literal が synth kit 6 種を正しく指す
- 既存 verify script 全 PASS (= regression 34+ script、 既存 K-BD/SD/HH/CYM/TOM/RIM path + R-* path + step 5-11 系 14 件 + step 4 1 件)
- audio gate (= 越川氏聴感 + listen-stepNN.sh helper script 案、 越川氏判断軸)
- 「synth kit が chip 化後に chiptune drum として成立する」 評価 (= 越川氏聴感 OK)

完了判定:
- 段階 1 全 sub-sprint α/β/γ/δ 完了
- ADR-0033 §決定 11 起源調査結果 §Annex A-5 反映済
- Surge XT prototype 6 種が PMDNEO build に統合 + MAME 再生 OK
- 全 regression PASS + 越川氏聴感 OK
- handoff doc + memory + commit + push 完了

### 段階 2: プロ session で acoustic drum 録音

#### sub-sprint α: studio + drum kit + drummer 選定 + ADR-0033 §録音 protocol 追記

drum studio 調査:
- 越川氏所在地ベース (= 都内 / 関西 / 他、 越川氏判断軸)
- birch shell drum (= Yamaha Recording Custom / Stage Custom 系) + cymbal (= Zildjian / Sabian 系) availability
- 録音 mic + interface 完備、 acoustic 録音実績ある studio 優先
- 候補: studio Sound Valley / studio Dede / Sound City / studio 246 / studio Lab 等 (= 越川氏判断軸)

drummer 選定:
- (i) 越川氏自演奏 (= 録音者 = 演奏者で完全 clean、 越川氏 drum 演奏 skill 依存)
- (ii) session drummer 委託 (= work-for-hire 契約で越川氏 100% 著作確保、 演奏品質最大化、 cost 増)

ADR-0033 §録音 protocol 章を追記 (= sub-sprint β-γ 準備):
- mic 配置 (= BD 内 + 外 / SD top + bottom / overhead / room)
- take 数 (= 各 drum 10 take)
- 編集規律 (= normalize / trim / level matching / best select)

完了判定:
- studio 選定 + drummer 選定 確定
- ADR-0033 §録音 protocol 追記済
- studio booking + 録音 day 確定
- commit + push 完了

#### sub-sprint β: 録音 day (= 1 day session)

録音 protocol 実施:
- 6 種 drum × 10 take (= BD/SD/TOM/TOP/HH/RIM)
- 各 take 44100 Hz / 16 bit / mono trim
- best 1 select + label
- 録音 metadata 記録 (= studio name / date / mic model / drum brand / drummer name / take log)

work-for-hire 契約 (= session drummer 委託の場合):
- 越川氏が著作権者として契約書記録
- drummer は performance fee 受領 + 著作権 transfer 明記
- 契約書 PDF を `assets/rhythm/acoustic/contracts/` 等に保存 (= license 証跡)

完了判定:
- 6 種 best take 録音完了
- 録音 metadata + work-for-hire 契約書記録済
- assets/rhythm/acoustic/raw/ に raw wav 配置
- commit + push 完了

#### sub-sprint γ: 編集 + library 化

編集 pipeline:
- normalize (= -3 dBFS 等の越川氏判断軸)
- trim (= attack 前 / decay 後の silence 除去)
- level matching (= 6 種で psycho-acoustic 均衡)
- mono down (= source が stereo の場合)
- file 名 規律 `2608_*.wav` (= §決定 7)

library 配置:
- `assets/rhythm/acoustic/2608_*.wav` (= source wav、 §決定 8 仕様)
- license 表記 `assets/rhythm/acoustic/LICENSE` (= 越川氏 100% 著作 + GPL-3.0 明記)
- 録音 metadata `assets/rhythm/acoustic/metadata.md` (= studio / date / drum / drummer / take 等の制作詳細)

完了判定:
- 6 種 acoustic wav 完成 + 命名規律準拠
- license 表記 + 録音 metadata 整備
- commit + push 完了

#### sub-sprint δ: 段階 2 完了統合 + verify

verify gate:
- acoustic kit を pipeline 通して `samples.inc` 生成
- PMDNEO build + MAME 再生 + ymfm register write trace
- audio gate (= 越川氏聴感 + listen-stepNN.sh helper script)
- 「acoustic kit が chip 化後に RX-11 family 音色として成立する」 評価 (= 越川氏聴感 OK)
- 全 regression PASS

完了判定:
- 段階 2 全 sub-sprint α/β/γ/δ 完了
- acoustic kit が PMDNEO build に統合 + MAME 再生 OK + RX-11 family 成立判定
- 全 regression PASS + 越川氏聴感 OK
- handoff doc + memory + commit + push 完了

### 段階 3: library 同梱判断 + 設計書統合 + 完全ホワイト化 milestone

#### sub-sprint α: synth kit vs acoustic kit 用途棲み分け判断

primary kit / secondary kit 選定 (= 越川氏判断軸):
- 候補 A: synth kit を primary (= 投資 0 path、 「chiptune 寄り」 character)
- 候補 B: acoustic kit を primary (= RX-11 family、 「自然 drum」 character、 PMD culture narrative 強)
- 候補 C: 両方を primary 候補として同梱 + `.PNE` rhythm bank で切替 (= ADR-0025 multi-table architecture activate、 user 選択型、 §決定 10 完全実装)

current temporary fixture の最終判断 (= §決定 11 起源調査結果連動):
- 起源 = Yamaha / 出所不明 → 即時差替え (= primary / secondary に置換)
- 起源 = 越川氏自前 / license clean → 越川氏判断軸で残置 / 差替え

完了判定:
- primary / secondary kit 確定
- current temporary fixture 最終判断確定
- `sample_table_id` 割当 確定 (= 0x00 primary / 0x01 secondary)
- commit + push 完了

#### sub-sprint β: 設計書 §rhythm sample 章追記

`docs/design/PMDNEO_DESIGN.md` に §rhythm sample 章追記:
- 制作 narrative (= 越川氏自前録音 / 自前合成 / 越川氏 100% 著作)
- license 整理 (= GPL-3.0 で再配布可、 永久排除契約 §決定 2-5)
- 命名規則 (= §決定 7 + PMD culture 互換)
- chip 化 pipeline (= §決定 9 + §Annex A-7)
- multi-table architecture 経由 kit 入替 (= §決定 10 + ADR-0025)
- sound-alike caution (= §決定 14 + §Annex A-6)

`README.md` 更新:
- rhythm sample 由来表記 (= 「越川将人 100% 著作物」 明記、 CLAUDE.md §著作権者表記 整合)
- license 整理 (= GPL-3.0 統合)
- 完全ホワイト化 milestone 公式宣言

完了判定:
- PMDNEO_DESIGN.md §rhythm sample 章追加
- README.md license + 由来表記 更新
- commit + push 完了

#### sub-sprint γ: LICENSE 整理 + future contributor 受入 policy 反映

`LICENSE` / `docs/credits.md` 等の license 関連 file 整理:
- 越川氏 100% 著作 rhythm sample 明記
- 段階 2 work-for-hire 契約書 reference
- §決定 13 future contributor 受入 policy 反映 (= contributor が新 rhythm sample 提案する場合の規律)
- §決定 14 sound-alike caution 反映

`CONTRIBUTING.md` (= future 作成、 越川氏判断軸) で rhythm sample 受入条件明示:
- contributor 自身が 100% 著作権者である証拠提示義務
- license = GPL-3.0 整合性確認
- 越川氏 review で license 検証必須
- 第三者 sample 流用 = PR reject

完了判定:
- LICENSE + docs/credits.md 整理済
- CONTRIBUTING.md (= 越川氏判断で作成) rhythm sample 章 反映済
- commit + push 完了

#### sub-sprint δ: 段階 3 完了統合 + Step chain 完了 milestone + ADR-0033 Accepted

verify gate:
- primary kit + secondary kit 両方が PMDNEO build に統合 + MAME 再生 OK
- `.PNE` 切替で kit 入替動作確認 (= ADR-0025 multi-table architecture activate literal proof)
- 全 regression PASS + 越川氏聴感 OK (= primary / secondary 両 kit で K/R 6 drum 区別可能)
- 設計書 + README + LICENSE + CONTRIBUTING.md 整合確認

milestone 確立:
- 「**PMDNEO は完全ホワイト化済**」 公式宣言 (= 段階 3 sub-sprint β README で記載)
- asset provenance / licensing / redistribution 軸 完了 milestone
- ADR-0033 Accepted 化 (= 本 commit)
- memory + MEMORY.md index 更新
- handoff doc

next sprint candidate:
- Step 17 完了時 candidate に戻る (= simultaneous trigger semantics proof = ADR-0032 進行継続 / table-driven dispatch refactor / `.PNE` rhythm bank migration / `#PCMFile` integration / K/R 制御 cmd 現役化 等)
- runtime semantics 軸 (= ADR-0026-0032 系) 再開

完了判定:
- ADR-0033 全章 Accepted
- 段階 1-3 全 sub-sprint chain 完了
- 完全ホワイト化 milestone 公式宣言済
- 全 regression PASS + 越川氏聴感 OK
- handoff doc + memory + MEMORY.md index 更新
- next sprint candidate user 提示
- commit + push 完了

## verify gate

各段階内で以下 verify gate を成立させる:

### A 系統 (= runtime / audio gate、 既存 PMDNEO 規律踏襲)

1. **ymfm register write byte-identical** (= 各段階の wav → samples.inc → driver 経由で register write sequence が期待値と一致、 ADR-0023/0024/0025/0026-0031 流儀踏襲)
2. **ymfm-trace literal observation** (= sample addr / vol / pan / keyon mask の各 register write を literal assert)
3. **既存 verify script 全 PASS** (= regression 34+ script、 K-BD/SD/HH/CYM/TOM/RIM + R-* + step 5-11 系)
4. **MAME 再生 + 越川氏聴感** (= driver / runtime layer 動作確認義務、 CLAUDE.md §動作確認義務 遵守)
5. **listen-stepNN.sh helper script** (= 段階毎、 越川氏判断で命名、 ADR-0030 / ADR-0031 / ADR-0032 流儀踏襲)

### B 系統 (= build / asset pipeline gate)

1. **wav format 検証** (= 44100 Hz / 16 bit / mono、 §決定 8 仕様準拠)
2. **wav2adpcma.py pipeline 動作確認** (= 任意 wav → samples.inc 出力、 §決定 9 段階 1 sub-sprint γ で確立)
3. **samples.inc binary 同一性** (= 同 source wav から同 samples.inc 生成、 deterministic 確認)
4. **build pipeline 統合** (= Makefile / build.mk から wav 自動取込 + samples.inc 生成、 既存 vromtool.py 経路と整合)
5. **license 表記検証** (= assets/rhythm/*/LICENSE / metadata.md 存在 + 越川氏 100% 著作明記)

### audio family-similarity gate (= 段階 3 で primary kit 確定時に活用)

既存 memory `[PMD/OPN TL = 0.75 dB/step 対数減衰、 PMDDotNET 実機検証完了]` 等の voice 検証手法を rhythm に拡張:

1. **FFT spectrum 比較** (= 候補 wav と reference (= RX-11 / YM2608 emulator output) の周波数 peak 一致度)
2. **RMS envelope 比較** (= 1 ms 刻みで attack / decay 形状一致度)
3. **聴感家族度判定** (= 80-90% 数値類似度 + 越川氏聴感 OK で「OPNA family」 成立)
4. **「byte-identical ではなく聴感ファミリー一致」** = gate 核心 (= 完全一致を目指すと結局 dump コピーになるため、 意図的に違いを残す)

注: audio family-similarity gate は **段階 3 越川氏判断軸**で、 段階 1 / 段階 2 では「越川氏聴感 OK」 を simple gate として運用。 数値家族度評価は越川氏が必要と判断したら段階 3 sub-sprint α で実施。

## 完了判定

ADR-0033 Accepted 移行までの完了判定 10 項目:

1. ADR-0033 全 §決定 14 件 + scope-in/out 維持 + §Annex A-1 から A-7 まで literal 記載
2. 越川氏 100% 著作 rhythm wav 6 種完成 (= synth kit + acoustic kit 両方、 segment 2/3 で確立)
3. `scripts/wav2adpcma.py` pipeline 動作 + encoder 採用根拠 §Annex A-7 記録 (= 段階 1 sub-sprint γ)
4. PMDNEO build 統合 + MAME 再生で primary / secondary kit 切替動作確認 (= 段階 3 sub-sprint δ)
5. ymfm register write trace で 6 種 sample addr literal differ 確認 (= 各段階)
6. 既存 verify script 全 PASS (= 段階毎、 全 34+ script)
7. 越川氏聴感 OK (= 段階毎、 RX-11 family 成立判定 / chiptune drum 成立判定)
8. `docs/design/PMDNEO_DESIGN.md` §rhythm sample 章追加 (= 段階 3 sub-sprint β)
9. README + LICENSE + (越川氏判断で) CONTRIBUTING.md 整理完了 (= 段階 3 sub-sprint β-γ)
10. ADR-0033 Accepted 化 + memory + MEMORY.md index 更新 + 完全ホワイト化 milestone 公式宣言 (= 段階 3 sub-sprint δ)

## §Annex A: 由来証跡記録

### A-1: BambooTracker / MAME / ymfm の rhythm 実装 由来証跡

20th session 中盤調査結果 (= WebFetch + WebSearch 経由):

#### MAME backend (`chip/mame/`)

- `chip/mame/fmopn_2608rom.h` に **8 KB の YM2608 内蔵 mask ROM dump** が embed
- declaration: `const unsigned char YM2608_ADPCM_ROM[0x2000] = { 0x88, 0x08, 0x08, 0x08, ... };`
- size: `0x2000` = 8192 byte
- source comment (= literal):
  - *"verified, using real YM2608"* (= 実機 dump 由来明記)
  - *"internal ROM can't be read"* (= YM2608 chip 仕様で CPU からは不可視)
- source identifier (= 元 dump file 名):
  - `01BD.ROM` (= bit 0、 Bass Drum)
  - `02SD.ROM` (= bit 1、 Snare Drum)
  - `04TOP.ROM` (= bit 2、 Top Cymbal、 6 KB と最大)
  - `08HH.ROM` (= bit 3、 Hi-Hat)
  - `10TOM.ROM` (= bit 4、 Tom)
  - `20RIM.ROM` (= bit 5、 Rim Shot、 128 byte と最小)
- bit 番号と file 名 prefix の数値 (= 01/02/04/08/10/20) が完全一致 = PMD MML `\b\s\c\h\t\i` bitmap (= 0x01/0x02/0x04/0x08/0x10/0x20) と完全同型

#### ymfm backend (`chip/ymfm/`)

- `chip/ymfm/ymfm_2608.cpp` に declaration: `extern const unsigned char YM2608_ADPCM_ROM[0x2000];`
- 自身では rhythm sample data を持たず、 **MAME backend の `fmopn_2608rom.h` を extern 参照**して link 時に解決
- ymfm 公式 (= Aaron Giles) は本来 sample data を含めない方針 (= 「license をクリーンに保つ」 流儀)、 BambooTracker が ymfm に MAME ROM data を inject している hack

#### Nuked backend (`chip/nuked/`)

- `chip/nuked/nuked_2608.cpp` で rhythm 関連 register (= 0x10 / 0x11 / 0x18-0x1D) **handling 完全不在**
- Nuked-OPN2 は元々 YM2612 (= mega drive、 rhythm 非搭載) 専用 emulator で、 OPNA への branding 後も rhythm 機能を持たない
- BambooTracker で Nuked 選択時は rhythm 音が出ない仕様

#### opna_controller.cpp rhythm 経路 (= BambooTracker / opna_controller.cpp)

- register 0x10 = keyon / keyoff mask (= bit 0-5、 keyoff は `0x80 | mask`)
- register 0x11 = master TL (= 6 bit、 init で 0x3f max)
- register 0x18-0x1D = 各 ch pan (= bit 6-7) + IL (= bit 0-4)
- keyon dispatch: `keyOnRequestFlagsRhythm_` を 1 frame 末で flush + bitmap aggregate で 1 register write 同時 trigger
- 同 pattern は PMD `\b\s\c\h\t\i` bitmap (= ADR-0026-0031 流儀) と structural 同型、 PMDNEO は OPNA 内蔵 rhythm ではなく ADPCM-A 6 ch native dispatch で再現

#### PMDNEO への含意

- BambooTracker / MAME / ymfm の rhythm 実装 = **Yamaha mask ROM dump 8 KB を emulator binary に embed** する方式
- license は MAME 全体の GPL-2.0+ を冠するが、 ROM data 部分は Yamaha 著作物で MAME が GPL を宣言したからといって Yamaha が GPL 化を認めた訳ではない
- 厳密には Yamaha 株式会社著作物を権利者の許諾なく GPL で再配布している状態
- PMDNEO は §決定 2 でこの経路を永久排除、 ADR-0033 §Annex A-1 reference として future contributor が誤って取り込まないための literal 記録

### A-2: snesmusic.org / hoot/drum_samples.zip + community RSS wav 由来証跡

20th session 中盤調査結果 (= WebSearch 経由):

#### community 配布 RSS wav (= `snesmusic.org/hoot/drum_samples.zip` 等)

- 配布主体: snesmusic.org / Hoot Archive (= retro music emulator + sample archive)
- 配布形態: `drum_samples.zip` 単独 download (= hoot emulator 同梱せず)
- file 構成: `2608_bd.wav` / `2608_sd.wav` / `2608_top.wav` / `2608_hh.wav` / `2608_tom.wav` / `2608_rim.wav` (or `2608_rym.wav`)
- format: RIFF WAVE PCM / 1 ch / 44100 Hz / 16 bit
- 著者 / 録音 day / 録音機材 / 録音 protocol / license = **明記なし**
- WebSearch 結果 literal: *"the distributed YM2608 rhythm sound files available online are created to **mimic** the original sounds rather than being direct copies"*
- 「mimic」 主張だが出所証明不在、 PMDNEO は §決定 3 で永久排除

#### PMD player 開発者の認識

- `OPNA2608/projmd` README literal: *"Place your copies of the `ym2608_adpcm_rom.bin` (preferred, for correct RSS playback speed), or the RSS samples extracted into the following files"* + *"for legal reasons, these files are not included"*
- 同 pattern: PMDDotNET / mml2vgm / FMPMD2000 / 98fmplayer 全て「user 自己責任 download に押し出す」 流儀
- `ym2608_adpcm_rom.bin` (= Yamaha mask ROM dump、 wav より優先される仕組み) も同 directory に置ける = community 内で「ROM dump も wav も同 license 群」 と扱われている

#### PMD ecosystem の rhythm 取扱い慣行

- player binary には rhythm wav / ROM dump を含めない (= 法的安全策)
- user が別 directory に手動配置 (= `.pmdplay/` / `player/` 等)
- `ym2608_adpcm_rom.bin` が wav より優先される仕組み (= ROM 持ち user は ROM 使用、 wav しか無い user は wav 使用)
- 同梱 zip の出所は **community 暗黙の了解で曖昧化**

#### PMDNEO への含意

- PMDNEO は OSS として GPL-3.0 配布で「同梱配布」 の責任を負う以上、 「user 自己責任 download に押し出す」 流儀は不適合
- §決定 1-5 + §決定 12 で「越川氏 100% 著作 sample のみ同梱」 + 「community 配布物排除」 を literal 拘束
- §Annex A-2 reference として「community 配布物に流されない」 規律を future contributor に明示

### A-3: PMD culture rhythm.wav 公式仕様

20th session 中盤調査結果 (= pedipanol's MML guide + projmd / PMDDotNET / mml2vgm / FMPMD2000 setup doc):

| 項目 | 仕様 |
|---|---|
| format | RIFF WAVE PCM (= 非圧縮) |
| channels | 1 (mono) |
| sample rate | 44100 Hz |
| bit depth | 16 bit |
| file 名 | `2608_bd.wav` / `2608_sd.wav` / `2608_top.wav` / `2608_hh.wav` / `2608_tom.wav` / `2608_rim.wav` (or `2608_rym.wav`) |
| 配置 | player 同梱 directory に user 手動配置 (= `.pmdplay/` / `player/` 等) |
| 優先順位 | `ym2608_adpcm_rom.bin` (= mask ROM dump) が wav より優先 |

PMDDotNET / mml2vgm / projmd / FMPMD2000 / Neko Project (np2) 全部が同じ命名 + 同じ format を採用。 PMDNEO §決定 7 + §決定 8 でこの仕様踏襲、 PMD ecosystem 全体と命名互換性確保。

#### PMDNEO への含意

- PMD culture 公式仕様 (= 44100/16/mono + `2608_*.wav`) を踏襲することで PMDNEO 同梱 rhythm wav を PMD ecosystem 他 player でも直接使える形態に統一
- 越川氏自前 wav (= 段階 1 synth / 段階 2 acoustic) を「越川氏作 PMD rhythm clone」 として PMD ecosystem 全体に provide する選択肢を保持 (= 越川氏判断軸、 PMDNEO release 後の別 release)

### A-4: YM2608 rhythm sample 系譜 (= 1984 RX-11 → DD10 → YM2608)

20th session 中盤調査結果 (= VGMRips forum t=3013 + WebSearch):

#### 系譜

```
1984: Yamaha RX-11 (= Yamaha 初の digital drum machine、 12-bit PCM、 6 ROMs x 256 Kbit = 192 KB sample)
        │
        │ Yamaha 社内で sample 再利用
        ▼
1986+: RX-5 / RX-7 / RX-21 (= sample family 継承、 高音質化)
        │
        │ 8 KB に劇的圧縮 + 4-bit ADPCM-A 化
        ▼
1988+: DD10 (= 8-bit、 子供向け toy drum machine)
        YM2608 (OPNA) rhythm rom (= 8 KB、 6 種 4-bit ADPCM)
        その他 Yamaha 製品 (= YRW801 / TG100 / OPL4 系統)
```

VGMRips literal 引用 (= forum t=3013):
- *"Yamaha DD10 は YM2608 のリズム音源と同じサンプルを使用している"*
- *"Yamaha YRW801 サンプル ROM は OPL4 と組み合わせて使用され、 TG100 サウンドモジュールとほぼ同じサンプルセットを含む"*

#### 元 acoustic drum 推定 (= 公開資料からの推定、 Yamaha 内部資料不在)

| RX-11 sample | 推定 acoustic 元楽器 (= 高確度) | 補足 |
|---|---|---|
| Bass Drum | Yamaha Recording Custom 22" (= 1984 Yamaha 最高峰 birch shell BD) | Yamaha 自社製品 promotion を兼ねた可能性高 |
| Snare Drum | Yamaha Recording Custom 14"x6.5" (= 同 series snare) | warm and woody な RX-11 SD 音色と整合 |
| Tom | Yamaha Recording Custom tom (= 同 series) | 同上 |
| Cymbal (TOP) | Zildjian A series ride または Paiste 2002 ride | Yamaha は cymbal 不生産、 3rd party |
| Hi-Hat | Zildjian A series 14" hi-hat または Paiste 2002 hi-hat | 同上 |
| Rim Shot | Yamaha Recording Custom 14" snare の rim | snare と同 kit の rim |

完全特定は困難 (= Yamaha 内部文書、 当時の開発者 interview 等が必要)、 ただし birch shell drum + Zildjian A series cymbal が 1984 Yamaha studio 標準として整合性高。 段階 2 sub-sprint α で studio + drum kit 選定時に同系列を選ぶことで RX-11 ルーツ整合性を担保。

#### PMDNEO への含意

- YM2608 rhythm rom = RX-11 sample family の 4-bit ADPCM 圧縮版
- 元 acoustic drum 録音 = Yamaha studio 1984 session (= 著作権 = Yamaha)
- PMDNEO §決定 2 で永久排除、 §Annex A-4 reference として「rhythm rom dump = 第三者著作物」 を future contributor に明示
- 段階 2 acoustic 録音で同系列 acoustic drum (= birch shell + Zildjian) を選定することで RX-11 family 音色を独立録音物として越川氏帰属で作成可能 (= §Annex A-6 sound-alike caution 適用)

### A-5: current temporary fixture 起源調査結果 (= 段階 1 sub-sprint α 後埋め枠)

ADR-0033 起票時点で PMDNEO `samples.inc` に embed されている既存 rhythm sample + vendor 内未追跡 wav (= 2026-05-15 21st session 起点で `vendor/ngdevkit-examples/06-sound-adpcma/assets/lefthook.wav` 等が untracked 検出) の起源:

**(= 段階 1 sub-sprint α で機械的調査後に literal 記載、 §決定 15 = 中程度 forensic + 3 段階分類 + engineering provenance note 性格)**

性格 (= §決定 15 literal):
- **法的判断ではなく engineering provenance note** として記録
- **3 段階分類 (= confirmed / likely / unknown)** で起源 likelihood を分類
- **目的 = 起源を完全に暴くことではなく、 段階 3 で越川氏 100% 著作物に置換する判断を補強する**

調査軸 (= 中程度 forensic、 §決定 15 連動 7 項目):
1. sha256 / git log (= 作成経緯) / filename pattern
2. file header / sample rate / bit depth / length
3. basic waveform / spectral fingerprint (= ffprobe / sox spectrogram + python numpy FFT 等)
4. current `samples.inc` 内 rhythm sample 開始 addr + binary 内容との対応 / vendor 内 wav (= `vendor/PMDDotNET/` / `vendor/pmd48s/` / `vendor/ngdevkit-examples/` 配下) との関係
5. BambooTracker `chip/mame/fmopn_2608rom.h` 内 `YM2608_ADPCM_ROM[0x2000]` / ymfm extern reference / MAME 経路との非一致確認 (= Yamaha mask ROM dump 検出)
6. 既知 RX-11 sample pack 候補 (= SampleScience RX-11 HD / AREX 2011 / PausePlayRepeat / freewavesamples 等) との top-level 照合
7. snesmusic.org/hoot/drum_samples.zip + PMD player 同梱 RSS wav set + ngdevkit-examples `06-sound-adpcma/assets/*.wav` (= license clean 第三者著作物検出) との top-level 照合

3 段階分類 (= §決定 15 literal):
- **confirmed**: 起源が機械的に特定済 (= sha256 一致 / git log 明示 / file header 明示)
- **likely**: 起源が高確度で推定可能 (= 命名 + 配置 + 内容類似で 1 候補に絞れる)
- **unknown**: 起源が特定不能 (= "unknown origin, temporary only, must be replaced before full whitening" を literal で記録)

起源 4 分類別追加判断 (= §決定 11 連動、 3 段階分類とは独立軸):
- 分類 1: Yamaha mask ROM dump 由来 → 段階 3 完了同時即時差替え必須
- 分類 2: 越川氏自前 → 越川氏判断軸で残置 / 差替え
- 分類 3: 出所不明 community 配布物 → 段階 3 完了同時即時差替え必須
- 分類 4: license clean 第三者著作物 (= ngdevkit-examples 等) → 越川氏判断軸

調査結果は段階 1 sub-sprint α 完了時に本 §Annex A-5 を update commit で literal 反映 (= 各 file ごとに sha256 + 起源 likely 候補 + 3 段階分類 + 4 分類別判断 + engineering note を表形式で記述)。

### A-6: sound-alike caution の法的境界 + 判断 decision tree

#### 法的境界 (= 著作権法 + 録音物の固定原理)

| 軸 | 判断 |
|---|---|
| 物理楽器の音 (= acoustic drum / cymbal 等の空気振動) | **public domain** (= 著作権客体ではない) |
| 物理楽器の brand / model (= Yamaha Recording Custom 22" 等) | **trademark / design 権** (= 商品名で identify するのは権利侵害でない、 楽器 brand を録音 metadata に明記しても問題なし) |
| 物理楽器を叩いた録音物 (= sound recording) | **録音者 / 演奏者の著作物** (= 録音実行時点で固定、 録音者 / 演奏者帰属) |
| 既存録音物の analog 経由 copy | **元著作者の権利継続** (= cable / DAC / ADC 経由でも literal copy として保護対象) |
| 既存録音物の digital dump copy | 同上 |
| 既存録音物を「mimic」 として独立録音した別録音物 | **新録音者の著作物** (= 元著作者の権利と独立、 ただし演奏 / 録音内容が元と「実質同一」 となる程度の literal 模倣は「翻案権」 侵害 risk) |
| 数学計算のみで生成した synth output | **生成者の著作物** (= 既存録音物使わず、 oscillator / filter / envelope 等の数式計算のみ、 license 完全 clean) |

#### sound-alike 判定 OK / NG 分類

- ✓ **OK**: acoustic drum 物理楽器を独立に叩いて録音 (= 越川氏 / drummer 演奏 → 越川氏帰属録音、 元と「家族として近い」 のは物理楽器が同じだから当然で OK)
- ✓ **OK**: Surge XT / SunVox / 他 synth で数式計算のみで「OPNA 風 drum」 を合成 (= 既存録音物使わず、 license 完全 clean)
- ✓ **OK**: CC0 / GPL 等 license clean 第三者録音物を編集 (= 第三者著作物として license 連鎖を整理、 PMDNEO 越川氏帰属とは別だが GPL-3.0 整合)
- ✗ **NG**: 中古 RX-11 hardware を購入して analog 録音 (= hardware ownership ≠ 内蔵 sample copyright)
- ✗ **NG**: 既存 RX-11 sample pack (= SampleScience / AREX 2011 / PausePlayRepeat 等) を embed (= 第三者録音物の二次配布)
- ✗ **NG**: MAME / ymfm / hoot 等 OPNA emulator の output を録音 (= 元 sample が Yamaha mask ROM dump)
- ✗ **NG**: snesmusic.org/hoot/drum_samples.zip 等 community 配布 RSS wav を embed (= 出所不明 / Yamaha mask ROM dump 由来 risk 大)
- ✗ **NG**: `fmopn_2608rom.h` / `ym2608_adpcm_rom.bin` を直接取り込み (= Yamaha mask ROM dump literal copy)

#### 「mimic」 表現の使用禁止

PMDNEO は「mimic = clone」 表現を使用しない (= community 慣行で出所証明不在の主張に流される risk)。 代替 wording:

- ✓ **使用**: 「越川氏自前録音」 (= acoustic 録音 path)
- ✓ **使用**: 「越川氏自前合成」 (= Surge XT 等 synth path)
- ✓ **使用**: 「越川氏 100% 著作」 (= GPL-3.0 配布権の証明)
- ✓ **使用**: 「RX-11 family の音色」 (= 音色家族度の表現、 出所主張ではない)
- ✓ **使用**: 「OPNA 風 drum」 (= 音色 character の表現)
- ✗ **使用禁止**: 「RX-11 clone」 「YM2608 clone」 (= 出所証明含意で誤認招く)
- ✗ **使用禁止**: 「mimic」 (= community 慣行と紛らわしい)
- ✗ **使用禁止**: 「ROM 派生」 「ROM dump 起源」 「emulator output 由来」 (= Yamaha 著作物派生含意)

future contributor / fork 派生作品でも本 wording 規律を継承する義務 (= §決定 13 license 連鎖継承明示と整合)。

### A-7: chip 化 pipeline encoder 採用根拠 (= 段階 1 sub-sprint γ 後埋め枠)

`scripts/wav_to_adpcma.sh` (= §決定 17 + §決定 18 確定 wrapper script、 §決定 9 時点の仮称 `wav2adpcma.py` から sh ベース wrapper に変更) で使用する 4-bit ADPCM-A encoder の採用方針:

**採用方針 = §決定 18 で確定 (= 21st session sub-sprint α 段階で前倒し):**
- **encoder 本体 = `github.com/superctr/adpcm` 採用** (= sound chip ADPCM codec library、 YM2610 ADPCM-A 対応、 既存 library)
- **PMDNEO 側 wrapper = `scripts/wav_to_adpcma.sh`** (= PMDNEO project license = GPL-3.0、 default parameter mono / 18.5 kHz / 4-bit / `2608_{bd,sd,top,hh,tom,rim}.wav` naming)

**(= 段階 1 sub-sprint γ で license 確認 + 動作確認 + 採用根拠 literal 反映後に本 §Annex A-7 を update commit で literal 記載)**

検討候補 (= 21st session 時点):
1. `github.com/superctr/adpcm` (= **採用**、 sound chip ADPCM codec library、 YM2610 ADPCM-A 対応、 既存 library)
2. `github.com/freem/adpcma` (= 不採用、 Neo-Geo ADPCM-A sample encoder、 ただし作者推奨は superctr/adpcm)
3. 自前実装 (= 不採用、 §決定 18 literal scope-out、 CLAUDE.md §スコープ外 規律 + 3 行重複より早すぎる抽象化を避ける)

段階 1 sub-sprint γ で確認する項目 (= sub-sprint γ 着手時に literal 反映):
- license 整合 (= GPL-3.0 / MIT / Apache 等の PMDNEO 整合 license、 vendor / 外部依存どちらか確定)
- 動作確認 (= 任意 wav から samples.inc 形式出力が成立)
- maintenance 状況 (= active commit 状況)
- PMDNEO build pipeline 統合容易性 (= 既存 vromtool.py / ADR-0019 sample addr build-time embed 経路との整合)
- ADPCM-A 精度 (= 4-bit Yamaha 系 ADPCM の bit-accuracy)
- vendor 同梱 vs 外部依存判断 (= 外部依存の場合 README にインストール手順記載、 vendor 同梱の場合 license 整合確認 + `vendor/superctr-adpcm/` 配置)

`scripts/wav_to_adpcma.sh` wrapper 仕様 (= §決定 18 literal):
- 入力: 44100 Hz / 16 bit / mono wav (= §決定 8 仕様)
- 処理 1: 18.5 kHz decimate (= sox / ffmpeg / scipy.signal.decimate 等)
- 処理 2: superctr/adpcm CLI 呼出し (= 4-bit ADPCM-A 圧縮)
- 処理 3: `samples.inc` 形式 Z80 assembly 出力 (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 既存 PMDNEO build pipeline 整合)
- default parameter: mono / 18.5 kHz / 4-bit ADPCM-A / `2608_{bd,sd,top,hh,tom,rim}.wav` naming convention

採用結果 + 根拠は段階 1 sub-sprint γ 完了時に本 §Annex A-7 を update commit で literal 反映 (= 採用 encoder の repository URL + commit hash + license 表記 + vendor 同梱 or 外部依存判断 + 動作確認 log を表形式で記述)。

## Annex 規律 (= future update 経路)

§Annex A-1 から A-4 + A-6 は本 commit (= ADR-0033 起票 Draft) で literal 確定済。 §Annex A-5 / A-7 は後埋め枠で、 段階 1 sub-sprint α / γ 完了時に update commit で literal 反映する。 これは ADR-0032 §Annex 流儀 (= ADR Draft 起票時に Annex 確定 + sub-sprint 進行で additional Annex sub-section literal 反映) を踏襲。

## 重要 wording 規律

ADR-0033 内 + future commit message + handoff doc + memory で統一する wording:

- 「越川氏 100% 著作」 (= primary、 license narrative の核心)
- 「越川将人」 (= 公式日本語著作権者表記、 CLAUDE.md §著作権者表記 整合)
- 「M.Koshikawa.」 (= 公式英語著作権者表記、 同)
- 「完全ホワイト化」 (= 段階 3 完了 milestone wording、 license 健全性の最終形)
- 「越川氏自前録音」 / 「越川氏自前合成」 (= sample 由来表現、 §Annex A-6 wording 規律)
- 「RX-11 family の音色」 (= 音色家族度表現、 出所主張ではない)
- 「OPNA 風 drum」 (= 音色 character 表現)
- 「Yamaha mask ROM dump」 (= 排除対象の literal 表現、 §決定 2)
- 「community 配布物」 (= 排除対象の literal 表現、 §決定 3)
- 「既存 RX-11 sample pack」 (= 排除対象の literal 表現、 §決定 4)
- 「中古 RX-11 自己録音」 (= 排除対象の literal 表現、 §決定 5)
- 「migration roadmap 3 段階」 (= §決定 6 + migration roadmap 章)
- 「current temporary fixture」 (= §決定 11 暫定許容対象の literal 表現)
- 「sound-alike caution」 (= §決定 14 + §Annex A-6 wording 規律)

使用禁止 wording (= §Annex A-6 wording 規律 + 21st session §決定 16 追加):
- 「RX-11 clone」 / 「YM2608 clone」
- 「mimic」
- 「ROM 派生」 / 「ROM dump 起源」 / 「emulator output 由来」
- 「RX-11 identical recreation」 / 「ROM recreation」 (= 21st session §決定 16 追加、 sound-alike caution 強化)

21st session 追加推奨 wording (= §決定 16 Surge XT prototype + §決定 19 段階 1/2 役割分離):
- 「synthetic drum prototype」 (= 段階 1 Surge XT prototype の中立表現)
- 「retro FM/ADPCM drum aesthetic」 (= 音色 character の表現、 OPNA 風 drum の代替候補)
- 「PMD rhythm family」 (= 音色家族度の集合表現)
- 「段階 1 = legality / reproducibility / ownership / pipeline」 (= §決定 19 役割分離 literal)
- 「段階 2 = aesthetic refinement / acoustic realism / session quality」 (= 同)
- 「文化的参照」 (= sound-alike caution 適用範囲内の表現)
- 「sample derivative」 (= §決定 2-5 永久排除契約適用対象の表現)
- 「engineering provenance note」 (= §決定 15 Annex A-5 性格、 法的判断ではなく engineering 記録)

ADR-0033 の literal narrative はこの wording 規律に貫徹する。 future commit / fork 派生作品でも継承義務。
