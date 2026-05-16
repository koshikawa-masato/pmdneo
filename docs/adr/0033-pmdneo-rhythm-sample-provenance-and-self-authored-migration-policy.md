# ADR-0033: リズム音源 sample の由来管理と完全自作化 migration policy (= asset provenance / licensing / redistribution 軸独立起票 / runtime semantics 軸 ADR-0026-0032 と完全分離 / Yamaha mask ROM dump 永久排除 / 越川将人 100% 著作物のみ同梱 / Surge XT 完全合成 prototype → プロ session acoustic drum 録音 → library 同梱 3 段階 migration / current temporary fixture 段階 3 完了まで暫定許容 / sound-alike caution = RX-11 似は OK / ROM sample derivative 不可 / PMD culture rhythm.wav 仕様互換 (= 2608_*.wav / 44100 Hz / 16 bit / mono) / 完全ホワイト化 milestone 確立 / runtime dispatch invariant 完全不変 / multi-table architecture (= ADR-0025) 経由 kit 入替 design)

- 状態: **Draft** (= 2026-05-15 20th session 中盤起票 + 2026-05-15 21st session 冒頭 sub-sprint α 5 軸壁打ち決定 + §決定 15-19 追加 + §Annex A-5 / A-7 後埋め枠の調査軸 literal 化 + migration roadmap 段階 1 sub-sprint α 内容詳細化 + 2026-05-16 22nd session 冒頭 sub-sprint α 5 軸壁打ち決定 (= forensic 実施順序 / scripts canonical pipeline 粒度 / Surge XT install 環境 / prototype render naming / synthetic drum identity aesthetic) + §決定 20-24 追加 + §Annex A-5 inventory-first / sha256 canonical / observed-facts-first wording 補強 + §Annex A-7 4 系統 scripts 化 (= forensic-drum-samples.sh + wav_to_adpcma.sh + build_drum_samples.sh + verify-drum-samples.sh) + Makefile target 4 件 補足 + ## 重要 wording 規律 22nd session 追加 wording 反映 (= synth kit first-class identity / OPNA-era digital drum identity / ADPCM-A friendly drum design / Homebrew cask canonical / filename = drum identity / directory = kit identity 等) + 2026-05-16 23rd session 段階 1 sub-sprint α 実作業着手 = `scripts/forensic-drum-samples.sh` 新規作成 (= §決定 21 4 系統 1 件目 read-only inventory) + §決定 20 8 段階 flow mechanical 実行 + §Annex A-5 後埋め (= 12 file inventory 表 sha256 / size / meta / magic + 4 分類 all unknown + 重要 finding 5 件 = 18500 Hz roundtrip wav / source wav 不在 / 6 adpcma 別 sha256 / driver embed symbol / drum 軸 vendor wav 不在 literal 反映) + 23rd session 第 2 commit = `scripts/wav_to_adpcma.sh` + `scripts/build_drum_samples.sh` + `scripts/verify-drum-samples.sh` 3 件 interface fixation stub 新規作成 (= §決定 21 4 系統 2-4 件目、 9 項目 header / usage / not-implemented exit 2 sentinel / source wav 完成前は middle 実装しない literal 規律) + §決定 21 scripts 構成 4 件 status marker 反映 + sub-sprint α 進捗 23rd session 反映 section 追加 + 23rd session 第 3 commit ζ = top-level `Makefile` 新規作成 (= drum-sources / drum-build / drum-verify / drum-clean 4 target 軽量 stub、 「Makefile = 作業者向け入口、 script 名の写像ではない」 軸転換 literal、 wav_to_adpcma.sh は Makefile 直下に露出させない = drum-build 内部 invoke 扱い、 drum-clean は 23rd session ζ 新規 = rebuild path 確立後に有効化) + §決定 21 Makefile target 命名 update (= 旧 4 件 forensic-drum-samples / wav-to-adpcma / build-drum-samples / verify-drum-samples → 新 4 件 drum-sources / drum-build / drum-verify / drum-clean) + reasoning 「Makefile = 作業者向け入口」 literal 追加 + migration roadmap sub-sprint α + §Annex A-5 reference 同 target 命名 update + 23rd session 第 4 commit ζ' = §Annex A-7 superctr/adpcm evidence collection literal 反映 (= encoder repo `e431c94` HEAD / Public Domain Unlicense / build 成功 Apple clang 17.0.0 arm64 / ADPCM-A `ae` command 存在 / `-a` anti-overflow / signed 16-bit PCM little-endian input / stdlib 依存 / 2025-12-15 ValleyBell yma-overflow-fix maintenance / 7 ADPCM variant 対応 8 finding + §決定 18 採用条件 4 件クリア = encoder 採用 finalize ✓、 Surge XT install version 列は η commit で後追い後埋め) + 23rd session 第 5 commit η = §Annex A-7 Surge XT install version 列 後埋め完了 (= surge-xt 1.3.4 / install 2026-05-16 13:01:59 JST / path /opt/homebrew/Caskroom/surge-xt/1.3.4 / 419.8 MB / Apple Silicon arm64 / official upstream + cask source URL literal + brew lookup quirk reference 追加 = `brew list --versions <name>` formula default の cask 不在 quirk + `--cask` flag 明示で取得可能 future contributor 向け notation)、 23rd session 5 段階構成 (δ/ε/ζ/ζ'/η) で sub-sprint α 完了 milestone 達成 → sub-sprint β = BD 1 音先行 provenance chain 縦通し着手可能 + 23rd session 第 6 commit θ = sub-sprint β scaffolding 全面置換 (= 旧「6 種一括 patch 設計」 → 新「BD 1 音先行 chain → 残 5 音横展開」、 depth-first scaling 流儀 ADR レベル固定、 reproducible workflow first / aesthetic refinement second 軸、 BD chain 6 step literal 化 = patch / .fxp / wav / audition / adpcma / verify + 残 5 音 commit 粒度 3 候補 + 各 drum starting hint 維持 doc only commit、 sub-sprint β BD hand-on 着手準備完了 milestone) + 23rd session 第 7 commit θ' = sub-sprint β BD chain 着手前確定 parameters 8 軸 literal 固定 (= .fxp path / WAV no-normalize parameter / trim 規約 leading 0 + trailing +50-100 ms / WAV path / direct invoke encode 経路 -a anti-overflow ON / ADPCM-A 並行配置 path / 既存 fixture 隔離維持 / WAV → raw PCM 経路、 重要 wording 規律 = no normalize + 並行配置 + ι commit scope canonical の 3 件 literal、 ι commit (= 越川氏 hand-on 完成時) 安全 boundary 確立 milestone) + 23rd session 第 8 commit ι' = §決定 25 追加 = Surge XT fxp2wav CLI 化を future から self-authored source-of-truth pipeline 必須調査として scope-in 昇格 (= spike track 1 並走、 別 branch / 別 commit 系列 / 別 session 着手、 7 step work + 3 制約 + branch 名候補 3 件 + 成立/不成立時の反映先 literal、 β-main BD chain は止めない並走規律、 23rd session ζ' §Annex A-7「公式 distribution CLI render 不在」 literal 観察を踏まえた軸転換、 spike 性格 = .fxp source-of-truth ⇄ WAV 再生成可能経路の必須化、 audio capture 経路は段階 3 完全ホワイト化 milestone に持ち込めない reproducibility 規律根拠) + 23rd session 第 9 commit ι'' = §決定 25 repo boundary 規律補強 = 「scope-in だが repo-in ではない」 中核 wording literal 追加 (= fxp2wav-surge = PMDNEO 外部 spike + required external producer 扱い、 superctr/adpcm と同 pattern、 PMDNEO source tree に Surge fork / JUCE / build artifacts を入れない 4 件目制約追加、 役割境界 literal = PMDNEO consumer / fxp2wav-surge producer、 branch 名候補 → external repo location 候補に置換 = github.com/koshikawa-masato/fxp2wav-surge 推奨、 spike 成立時の tools/ 取り込み禁止 literal、 PMDNEO license narrative 独立性確保 repo hygiene 規律) + 23rd session 第 10 commit κ = §決定 26 追加 = Surge XT `.fxp` authoring spec literal 固定 (= 7 軸 = patch naming / synthesis goal / note convention / output constraint / patch design constraint / metadata-provenance / acceptance gate + 非目標 4 件 = YM2608 BD 模倣 / 完成音追い込み / 6 音同時設計 / GUI 依存暗黙手順 + spec 適用順序 + spec 範囲外、 BD hand-on 着手前の `.fxp` source-of-truth 仕様規律確立、 patch naming = `2608_bd.fxp` / Surge XT display `PMDNEO 2608 BD Self v0`、 note = MIDI 36 / vel 127 / 800 ms、 output = mono / no normalize / -6〜-3 dBFS peak / clipping 禁止、 design = Surge XT 内蔵 only / external sample 禁止 / random+drift+unseeded modulation 禁止 or seed 固定 / long tail 回避 / 低域+attack 明確化、 provenance = version + author + date + render command + `SURGE_RNG_SEED` + sha256 `.fxp` / `.wav` / `.adpcma`、 acceptance gate 5 件 = fxp2wav-surge render 可 + bit-identical WAV + 44100 mono 16-bit + BD 聴感成立 + 既存 fixture 別物並行配置、 残 5 音横展開時の canonical template として BD spec 再利用可能化、 §決定 14 sound-alike caution / §決定 16 prototype 粒度 / §決定 24 aesthetic / §決定 25 fxp2wav-surge external producer 整合、 `.fxp` = 単なる hand-on 成果物 → 再現可能 source-of-truth へ昇格、 BD hand-on artifact 受領前の安全 boundary 確立 + 残 5 音 template 確立 milestone、 driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変) + 23rd session 第 11 commit λ = §決定 27 追加 = AI-assisted patch generation workflow literal 固定 (= 8 軸 = AI 役割境界 / source-of-truth 階層 / patch spec 形式 / patch spec 最低必須 12 項目 / provenance chain 4 段階 / acceptance workflow / 越川氏 100% 著作整合 narrative / 成果物 path canonical 5 件 + spec 適用順序 8 step + scope-out 7 件、 AI 設計補助 + 越川氏 acceptance 軸独立確立、 AI = candidate 提示 / 越川氏 = audition + edit + accept 権限保持 / 最終 asset = 越川氏 100% 著作物方針不変、 source-of-truth = `patch-spec.yaml` / Markdown table (= `.fxp` binary より上位の human-readable layer)、 `.fxp` binary 直生成 / reverse engineering 永久 scope-out、 provenance chain = `patch-spec.yaml` → `.fxp` → `.wav` → `.adpcma` 4 段階、 §決定 26 (6) の 3 段階 sha256 を 4 段階に格上げ、 §決定 1 100% 著作物 / §決定 14 sound-alike caution / §決定 16 prototype 粒度 / §決定 19 段階 1 集中 / §決定 24 aesthetic / §決定 25 fxp2wav-surge external producer / §決定 26 `.fxp` authoring spec 整合、 越川氏 100% 著作と AI 利用の境界を ADR レベル literal で確立 milestone、 RX-11 clone / mimic / ROM recreation 方向 AI candidate は越川氏 reject 必須 wording 連動、 新規 directory `docs/design/rhythm-patches/synth/` patch spec source-of-truth canonical path 確立、 driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変) + 23rd session 第 12 commit μ = §決定 27 (6) acceptance workflow step 1 初回適用 = `docs/design/rhythm-patches/synth/2608_bd.patch-spec.yaml` AI candidate 生成 (= 303 行 / 22 top-level keys、 path B AI-assisted workflow 初回実 file 化、 BD = 残 5 音 template 候補確立、 §決定 26 7 軸 + §決定 27 12 必須項目 + §決定 24 aesthetic 5 target 整合、 OSC1 Sine pitched body + OSC2 S&H Noise click + LP24 800Hz + Soft Clip +3dB + AHDSR D=280ms + pitch sweep 130Hz→65Hz / 50ms、 provenance chain step 1 literal 記録 + step 2-4 pending state、 越川氏 audition / edit / accept 待ち、 driver / fixture / verify script / runtime semantics 完全不変) + 23rd session 第 13 commit ν = §決定 27 全面再定義 = AI-assisted patch generation + **rendered-audio self-analysis workflow** へ拡張 (= λ 8 軸 → ν 10 軸、 acceptance workflow 5 step → 11 step、 4 段 → 5 段 provenance chain、 user acceptance **upstream → downstream 再配置**、 engineering pass / aesthetic accept **軸独立分離**、 AI 役割 1 軸 (= spec 設計補助) → 2 軸 (= spec 設計補助 + rendered audio self-analysis 10 項目) 拡張、 AI self-analysis 10 項目 = waveform sanity / peak / RMS / clipping / silence / attack / decay / transient strength / spectral balance / tail length、 ν 中核 wording = 「acceptance は downstream、 upstream ではない」 / 「machine-checkable quality gate + human aesthetic final gate 2 layer」、 成果物 5 → 6 件に拡張 = `analysis-report.yaml` 新規追加 (= `docs/design/rhythm-patches/synth/2608_<drum>.analysis-report.yaml`)、 scope-out 7 → 9 件に拡張 = AI による aesthetic judgement / 越川氏 acceptance signature 代理生成 永久 scope-out 2 件追加、 23rd session ν 末 user finding = AI 機械検査を user audition 前に済ませる方が user の aesthetic judgement 軸 clean / 認知負荷低減、 §決定 1 100% 著作物 / §決定 14 sound-alike caution / §決定 24 aesthetic / §決定 26 spec 整合維持、 23rd session μ で生成済 `2608_bd.patch-spec.yaml` は ν workflow stage 軸に対応する形で同 commit 内で更新 (= `acceptance` → `workflow_stage: candidate-pending-render-analysis` + `engineering_pass: pending` + `aesthetic_acceptance: pending` 3 field 軸分離、 provenance chain 4 段 → 5 段拡張 = step 4 AI self-analysis 新規挿入 + step_4 → step_5 adpcma renumber、 acceptance_criteria 2 階層化 = engineering_pass_ai_self_analysis_10_items + aesthetic_acceptance_user_final_gate)、 driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変) + 23rd session 第 14 commit ξ = §決定 27 ν step 2 役割再配置 + `.fxp` bridge 軸統合 (= ν の本質 (= acceptance downstream / 越川氏 認知負荷を engineering correctness から解放) を貫徹するため、 ν step 2 の「越川氏 hand-on」 を「AI/toolchain による patch-spec → `.fxp` template-based bridge」 へ役割再配置、 越川氏 hand-on は template `.fxp` 作成 1 度のみに限定 = 全 6 drum 種共通 base、 drum-specific patch は AI/toolchain bridge 生成、 越川氏 review 対象は rendered audio のみ = aesthetic final gate 純化、 ξ scope-in 5 件 = patch-spec.yaml → template `.fxp` parameter patching bridge + template `.fxp` provenance/hash 記録 + patching 対象 parameter allowlist + generated `.fxp` は candidate + `.fxp` → wav render → AI self-analysis → user final gate、 ξ scope-out 拡張 4 件 = arbitrary `.fxp` binary full generation + full `.fxp` binary format reverse engineering + `.fxp` checksum/chunk format 無制限解析 (= 永久 scope-out、 必要最小限のみ許容) + AI が user acceptance を代替すること (= 永久 scope-out、 user 明示 wording literal)、 ξ 中核 wording 4 件 = template-based `.fxp` candidate generation / parameter allowlist patching / bridge not full synthesizer patch compiler / engineering candidate before aesthetic judgement、 ν 中核 wording (= acceptance downstream / machine-checkable + aesthetic final gate 2 layer) 維持、 AI 役割 2 軸 → 4 軸 拡張 (= spec 設計補助 + `.fxp` bridge + render orchestration + self-analysis)、 §決定 27 (9) 成果物 path 6 件 → 9 件 拡張 (= `assets/drum_samples/synth/templates/2608_template.fxp` + `docs/design/rhythm-patches/synth/parameter-allowlist.yaml` + `docs/design/rhythm-patches/synth/template.fxp.provenance.yaml` 3 件 ξ 新規追加、 全 6 drum 種共通 1 件のみ)、 acceptance workflow 11 step structure 不変 (= step 2 + 3 wording のみ AI/toolchain 軸に置換)、 §決定 27 (11) ξ scope-in literal 5 件 subsection 新規追加、 §決定 27 (1) AI 役割境界 2 軸 → 4 軸 expand、 23rd session μ で生成済 `2608_bd.patch-spec.yaml` workflow comment block step 2/3 wording のみ AI/toolchain 軸に update (= patch parameter / structure 不変)、 driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変、 ξ scope = ADR-0033 doc only + 2608_bd.patch-spec.yaml workflow comment 軽微 update、 spike 投資調査 (= Surge XT `.fxp` format / patch-spec → fxp bridge feasibility / 最小 spike) は ο commit 以降に分離)、 段階 1-3 完了後に Accepted 移行予定、 注: step 18 = ADR-0032 simultaneous trigger semantics proof と並走、 step 番号は段階 1 着手時に再採番予定、 ADR-0033 自体は policy fixation で step 軸とは独立)
- 起票日: 2026-05-15
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR: ADR-0032 (= step 18 simultaneous trigger semantics proof、 **runtime semantics 軸**で本 ADR と完全分離、 driver dispatch invariant の semantics 拡張軸初段)、 ADR-0031 (= step 17 K/R drum kind expansion proof — i = RIM、 §決定 8 「dispatch path は drum 種拡張で増やさない」 + drum 種拡張軸 sprint chain 完成 milestone、 本 ADR は runtime invariant 完全保持を前提)、 ADR-0030 / ADR-0029 / ADR-0028 / ADR-0027 / ADR-0026 (= step 12-16 drum 種拡張 sprint chain、 「rim」 「tom」 「top」 wording 規律確立)、 ADR-0025 (= step 11 multi-table id=0x01 proof、 本 ADR §決定 10 「multi-table architecture 経由 kit 入替」 の前提)、 ADR-0023 / ADR-0024 (= step 9 / step 10 sample_table_id resolver + selection consumption、 同前提)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 本 ADR §決定 8 chip 化 pipeline の前提)、 ADR-0021 (= step 7 `.PNE` asset pipeline、 本 ADR §決定 10 multi-table 入替の物理経路前提)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` (= 本 ADR Accepted 後に §rhythm sample 章追記予定、 段階 3 sub-sprint β で実施)、 `README.md` (= 段階 3 sub-sprint γ で license + 由来表記更新予定)、 `CLAUDE.md` (= §中核原則「記憶は AI に、 判断は自分が握る」 + §著作権者表記「越川将人 / M.Koshikawa.」 + §設計書ファースト + §動作確認義務 + §表記スタイル との完全整合)
- 関連 memory: `project_pmdneo_step17_complete.md` (= drum 種拡張軸 sprint chain 完成 milestone、 「Step 18+ candidate」 list に「simultaneous trigger semantics proof」 と並ぶ別軸候補として本 ADR を起票)、 `project_pmdneo_adpcma_subsystem_boundary.md` (= ADPCM-A subsystem 専用 architecture、 本 ADR は ADPCM-A rhythm sample 軸限定)、 `feedback_explain_in_plain_japanese_before_commit.md` (= 平易日本語報告規律、 段階毎 commit で遵守)、 `project_adr_0033_sub_sprint_alpha_5_decisions.md` (= 21st session 軸 5-9 決定 = §決定 15-19 literal 拘束 + 段階 1 sub-sprint α 着手準備完了 milestone)、 `project_adr_0033_sub_sprint_alpha_5_decisions_22nd.md` (= 22nd session 軸 10-14 決定 = §決定 20-24 literal 拘束 + sub-sprint α 実作業着手準備完了 milestone、 本 22nd session update commit 直後作成予定)
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

### 22nd session 冒頭壁打ちでの段階 1 sub-sprint α 5 軸方針確定

21st session 末で ADR-0033 Draft update (= §決定 15-19 + §Annex A-5 / A-7 後埋め枠 update + sub-sprint α 詳細化、 commit 5a2549a) 完了後、 22nd session 冒頭で段階 1 sub-sprint α 実作業着手前の方針を 5 軸壁打ちで確定した (= 20th session 軸 1-4 + 21st session 軸 5-9 と並列構造、 軸 10-14 全部 user 推奨採用、 1 軸 = 1 §決定 mapping)。

軸 5-9 (= 21st session) は「実施軸 (= どの深度 / 粒度 / 採用方針 / timing で)」 を policy として固定したが、 軸 10-14 (= 22nd session) は更にその下位の「実施順序 / 系統分離 / install 経路 / naming / aesthetic」 を実作業着手直前の literal 拘束として固定する。 段階 1 sub-sprint α の policy fixation 完了 milestone (= 軸 1-14 全 14 軸が ADR-0033 に literal 反映済) と見なせる。

#### 軸 10: current temporary fixture forensic 実施順序 (= A 現存棚卸し先行採用)

§決定 15 で「中程度 forensic + 3 段階分類 + engineering provenance note」 が確定済、 22nd session で実施 entry point を確定:

- (a) (= **採用**、 現存棚卸し先行): `src/test-fixtures/` + `vendor/ngdevkit-examples/` 配下の rhythm 関連 wav 全列挙 + sha256 取得 → 4 分類別振り分け。 observed-facts-first / provenance-inference-second 規律。 中程度 forensic の最も自然な entry point、 §Annex A-5 後埋め基盤早期完成。
- (b) (= 不採用、 4 分類順走破): §Annex A-1〜A-4 順 (= BambooTracker → community → PMD culture → RX-11) で各分類の参照 dataset を順次取得 + 機械照合。 4 分類完成度均等化、 棚卸し範囲が予め拘束されない。
- (c) (= 不採用、 driver symbol 先行): `adpcma_sample_{bd,sd,cym,hh,tom,rim}` symbol → binary chain を ROM/.PNE/yaml 経路で追跡 + 起源逆引き。 driver-embedded 経路と forensic 対象の対応早期固定、 runtime 経路透明性確保。
- (d) (= 不採用、 git history 先行): 各 rhythm wav blob 初出 commit を `git log` で追跡 + author / date / commit message から推定。 過去 sprint context 補強できるが engineering note 中核ではない。

(a) 採用根拠:
- forensic の最初の目的は「**何が存在しているか**」 を固定すること
- current temporary fixture の実体を先に inventory 化した方が、 後の分類・比較・推定がやりやすい
- §Annex A-5 の engineering provenance note を早く具体化できる
- sha256 を先に固定しておくと、 後の比較結果が reproducible になる
- scripts canonical 化 (= 軸 11) とも相性が良い
- 「観測可能事実先固定 → provenance 推定後追い」 という ADR-0033 legality / reproducibility / engineering provenance 方針と一致

推奨 8 段階 flow:
1. **current wav inventory** (= `src/test-fixtures/` + `vendor/ngdevkit-examples/` 配下 rhythm 関連 wav 全列挙)
2. **sha256** (= canonical identity 固定)
3. **sample rate / length / channel count** (= wav metadata)
4. **file header** (= RIFF WAVE PCM header parse)
5. **current `samples.inc` 対応** (= `adpcma_sample_{bd,sd,cym,hh,tom,rim}` symbol と wav の対応)
6. **vendor wav 対応** (= `vendor/PMDDotNET/` / `vendor/pmd48s/` / `vendor/ngdevkit-examples/` 配下 wav との関係)
7. **4 分類推定** (= Yamaha mask ROM dump / community 配布物 / PMD culture / RX-11 sample pack のどれに likely / unknown するか)
8. **git history / external comparison は必要時のみ追加** (= forensic 中程度 = 7 軸内で完結、 法的判断ではなく engineering note)

ADR / handoff 記載要件:
- forensic 実施順序 = **inventory first** (= §決定 20 literal 拘束)
- sha256 = **canonical identity** (= 後の比較で reproducible、 §Annex A-5 表に sha256 列必須)
- provenance inference = **inventory 完了後の後追い軸** (= 観測可能事実先固定)
- forensic result = **engineering note** (= 法的 certification ではない、 §決定 15 連動)
- §Annex A-5 update commit = 8 段階 flow 全完了後に表形式で literal 反映

#### 軸 11: scripts canonical pipeline 粒度 (= A 4 系統分離採用)

§決定 17 で「scripts canonical / WebApp future UI 役割分離 + scripts/wav_to_adpcma.sh + scripts/build_drum_samples.sh + scripts/verify-drum-samples.sh + Makefile target」 (= 3 系統) が確定済、 22nd session で forensic 系統独立化により 4 系統化を確定:

- (a) (= **採用**、 4 系統分離): `forensic-drum-samples.sh` / `wav_to_adpcma.sh` / `build_drum_samples.sh` / `verify-drum-samples.sh` の 4 script + Makefile target 4 件。 forensic は forward build pipeline とは性格が違う (= 読み取り専用 inventory vs 変換 / orchestration / verify)。
- (b) (= 不採用、 3 系統統合): forensic を `wav_to_adpcma.sh` の前段処理として統合 (= sha256 / meta 抽出は wav_to_adpcma 処理の一部として実行)、 §決定 17 の 3 系統 literal 保存、 forensic 単独実行は Makefile target で抽出。
- (c) (= 不採用、 2 系統 build + verify): `build_drum_samples.sh` に forensic + wav_to_adpcma 統合、 `verify-drum-samples.sh` は独立。 粒度粗、 script 数最小、 forensic / encode / pack の責務境界混在。
- (d) (= 不採用、 5+ 系統細分): `forensic-inventory` / `forensic-sha256` / `forensic-meta` / `wav_to_adpcma` / `build_drum_samples` / `verify-drum-samples` / `forensic-report` 等細粒度分離。 責務 1 軸 1 script、 8 段階 flow を script 単位で表現、 script 数 / Makefile target 数肥大。

(a) 採用根拠:
- forensic は forward build pipeline とは性格が違う
- current temporary fixture の棚卸し / sha256 / metadata は変換前に単独完結できるべき
- `wav_to_adpcma` は純粋な変換責務に集中できる (= 1 wav → 1 ADPCM-A binary)
- `build_drum_samples` は 6 drum 統括 orchestration に集中できる
- `verify-drum-samples` は生成物の検証に集中できる
- future contributor が forensic だけ再実行しやすい
- ADR-0033 「engineering provenance note」 と相性が良い

推奨 script 構成:
- `scripts/forensic-drum-samples.sh` (= **read-only inventory**): inventory / sha256 / file header / sample rate / bit depth / length / channel count / current `samples.inc` 対応候補 / report 出力
- `scripts/wav_to_adpcma.sh` (= **one-file converter**): wav 1 file → ADPCM-A binary 1 file / 18.5 kHz / mono / 4-bit ADPCM-A / superctr/adpcm wrapper (= §決定 18 整合)
- `scripts/build_drum_samples.sh` (= **orchestration**): 6 drum wav → 6 ADPCM-A binary → `samples.inc` / assets 出力 / 命名 `2608_{bd,sd,top,hh,tom,rim}` (= §決定 7 整合)
- `scripts/verify-drum-samples.sh` (= **reproducibility gate**): sha256 / expected length / channel count / sample rate / output binary size / optional spectral fingerprint

Makefile target 4 件分離:
- `make forensic-drum-samples`
- `make wav-to-adpcma`
- `make build-drum-samples`
- `make verify-drum-samples`

ADR / handoff 記載要件:
- scripts 粒度 = **4 系統分離** (= §決定 21 literal 拘束)
- forensic = **read-only inventory** (= §Annex A-7 役割境界 literal)
- wav_to_adpcma = **one-file converter** (= 同)
- build_drum_samples = **orchestration** (= 同)
- verify-drum-samples = **reproducibility gate** (= 同)
- Makefile target = **4 件独立** (= 各 script を単独実行可能)

#### 軸 12: Surge XT install 環境 (= A Homebrew cask canonical 採用)

§決定 16 で Surge XT prototype = 設計明明 prototype (= 5 成果物) が確定済、 22nd session で install 経路 canonical を確定:

- (a) (= **採用**、 Homebrew cask canonical): `brew install --cask surge-xt` で install、 version 管理 reproducible、 future contributor が同 version を 1 コマンドで install 可能。 scripts canonical 方針と整合、 reproducibility 重視。
- (b) (= 不採用、 native .dmg installer): surge-synthesizer.github.io 公式 .dmg を download + GUI install、 version pin 自由、 brew タイムラグ遅れ回避、 ADR install 仕様 wording 拘束必須。
- (c) (= 不採用、 system 既存 install 流用): 越川氏現環境に既に Surge XT install されているか調査先行、 あればそれを canonical として採用 + version 記録、 install 手間ゼロ、 future contributor への再現性 wording 補強要。
- (d) (= 不採用、 standalone + plugin 両形式): `.app` standalone + `.vst3` / `.au` plugin 両方 install + DAW (= Reaper / Logic / GarageBand 等) で wav render、 automation (= CLI wav render) と GUI 試行両者対応、 DAW 依存 + install 複雑化。

(a) 採用根拠:
- ADR-0033 の中心は **reproducibility**
- future contributor / fork 派生も同じ install 手順を再現しやすい
- scripts canonical 方針と整合する
- version 固定 / upgrade 管理がしやすい
- 「**環境構築も provenance の一部**」 として扱える
- 段階 1 β の目的は「まず 6 drum prototype を render できること」 なので DAW integration まで scope を広げない方が良い

推奨 install 手順:
- `brew install --cask surge-xt`
- version を §Annex A-7 / design memo に記録
- standalone app を canonical とする
- plugin / DAW integration は future optional

ADR / handoff 記載要件:
- install 経路 = **Homebrew cask canonical** (= §決定 22 literal 拘束)
- canonical form = **standalone-first** (= GUI standalone app で wav export、 DAW 不要)
- plugin / DAW integration = **future optional** (= 必要なら別 ADR or 別 sub-sprint で扱う)
- install version 記録 = **必須** (= §Annex A-7 install version 列追加、 段階 1 sub-sprint α で literal 反映)
- future contributor reproducibility = **重視** (= 同 version を 1 command で install 可能)

#### 軸 13: prototype render naming (= A directory 分離 synth/acoustic 採用)

§決定 7 で source wav 公式命名 = `2608_{bd,sd,top,hh,tom,rim}.wav` 確定済 + §決定 10 で synth kit + acoustic kit 棲み分け確定済、 22nd session で synth/acoustic 命名衝突回避方針を確定:

- (a) (= **採用**、 directory 分離 synth/acoustic): `assets/drum_samples/synth/2608_{bd,...}.wav` + `assets/drum_samples/acoustic/2608_{bd,...}.wav`。 §決定 7 公式命名不変 + directory で kit 識別、 ADR-0025 multi-table architecture と整合、 future kit 追加も同パターン (= `synth_v2/` 等)。
- (b) (= 不採用、 suffix 分離 _synth/_acoustic): `2608_bd_synth.wav` / `2608_bd_acoustic.wav` 等 suffix で kit 識別、 flat directory で一覧性高、 公式命名との互換性低下、 PMD culture rhythm.wav 命名規約から離れる。
- (c) (= 不採用、 version suffix _v0/_v1): `2608_bd_v0.wav` (= synthetic prototype) / `2608_bd_v1.wav` (= acoustic future) 等、 段階進捗 = version 映射、 chronological に明確、 synth/acoustic semantic が version 数値に隠れる。
- (d) (= 不採用、 prototype suffix のみ): `2608_bd_prototype.wav` (= 段階 1) → `2608_bd.wav` (= 段階 3 公式 rename)、 acoustic が公式命名独占、 段階 3 で acoustic が canonical narrative、 synth kit 単独 release 可能性 (= §決定 19) と不整合。

(a) 採用根拠:
- §決定 7 公式命名 `2608_{bd,sd,top,hh,tom,rim}.wav` を維持できる
- §決定 10 multi-table architecture と綺麗に整合する
- synth kit 単独 release 可能性 (= §決定 19) と矛盾しない
- acoustic を「最終版」 に固定しないので narrative が柔軟
- future kit expansion に自然に伸ばせる
- **filename = drum identity / directory = kit identity** の責務分離

推奨 directory 構造:
- `assets/drum_samples/synth/2608_bd.wav`
- `assets/drum_samples/synth/2608_sd.wav`
- `assets/drum_samples/synth/2608_top.wav`
- `assets/drum_samples/synth/2608_hh.wav`
- `assets/drum_samples/synth/2608_tom.wav`
- `assets/drum_samples/synth/2608_rim.wav`

future expansion:
- `assets/drum_samples/acoustic/...` (= 段階 2)
- `assets/drum_samples/synth_v2/...` (= future kit)
- `assets/drum_samples/experimental/...` (= future kit)

ADR / handoff 記載要件:
- naming 戦略 = **directory 分離 synth/acoustic** (= §決定 23 literal 拘束)
- filename = **drum identity** (= `2608_{bd,sd,top,hh,tom,rim}.wav` 不変)
- directory = **kit identity** (= synth / acoustic / future kit)
- PMD culture compatibility = **filename レベルで維持** (= §決定 7 整合)
- kit provenance = **directory レベルで表現** (= synth / acoustic は parallel kit families)
- acoustic = **非自動 canonical** (= synth kit 単独 release 維持、 §決定 19 整合)
- synthetic-only release = **継続有効**

#### 軸 14: synthetic drum identity aesthetic (= A OPNA / retro FM-ADPCM aesthetic 採用)

§決定 14 sound-alike caution + §決定 16 推奨/禁止 wording 確定済、 22nd session で Surge XT prototype の音色キャラクター方針を確定:

- (a) (= **採用**、 OPNA / retro FM-ADPCM aesthetic): 80s digital drum (= YM2608 + ADPCM-A 6ch 文化) 雰囲気追求、 RX-11 似や生 drum 再現ではない。 §決定 14 推奨 wording と整合、 PMDNEO target (= NEOGEO/OPNB 文化) と一致、 段階 1 synth kit narrative 明確。
- (b) (= 不採用、 PMD culture rhythm 継承): PMD V4.8s 同梱 rhythm.wav (= §Annex A-3) 雰囲気継承、 sample 由来は完全自前合成。 PMD 文化依存 narrative 追加豊かさ、 sound-alike caution (= RX-11 と PMD culture の距離説明) が複雑化。
- (c) (= 不採用、 acoustic-leaning realism): 段階 3 acoustic (= birch shell + Zildjian 系) への橋渡しとして synthetic で acoustic-like 設定。 段階連続性高、 §決定 19 「段階 1 完全集中 / synth 単独 release 可能」 narrative 不整合 risk。
- (d) (= 不採用、 character-neutral / minimal): 個性最小の clinical synth drum、 future kit 入替前提の neutral baseline。 同梱 default としての中立性 + 後で上書き前提、 PMDNEO narrative (= NEOGEO/OPNB 文化) の表現力低下。

(a) 採用根拠:
- PMDNEO の identity と最も自然に一致する
- 「RX-11 recreation」 ではなく「**80s digital drum culture**」 を参照できる
- §決定 14 sound-alike caution と整合する
- synthetic kit 単独 release (= §決定 19) narrative を作りやすい
- acoustic realism を目指さないので段階 1 役割明確 (= legality / reproducibility / ownership / pipeline)

aesthetic target 5 項目:
- **short decay** (= ADPCM-A 圧縮 + retro digital drum 特性)
- **bright transient** (= attack 強調 + 4-bit ADPCM-A 親和)
- **compressed body** (= 全体音量 envelope short + retro digital character)
- **retro digital texture** (= 80s YM2608 / OPNA 期 digital drum 質感)
- **ADPCM-friendly frequency balance** (= 18.5 kHz sample rate / 4-bit ADPCM-A 圧縮で degrade しない周波数分布)

中核 wording (= 22nd session narrative 核心):
- 「**RX-11 を再現する**」 ではなく、 「**YM2608 / ADPCM-A 時代の aesthetic を継承する**」
- 段階 1 synth kit は **「placeholder」 ではなく「正式な PMDNEO drum family」** として扱う
- acoustic kit が future に来ても、 synth kit は **obsolete ではなく parallel family**
- **synthetic-only release は valid な PMDNEO release form**

22nd session 追加推奨 wording (= §決定 16 wording 規律拡張):
- 「retro FM/ADPCM drum aesthetic」 (= 既存推奨 wording 強化)
- 「OPNA-era digital drum identity」 (= 22nd session 新規追加)
- 「PMD rhythm family compatible」 (= 既存 wording 表記揺れ統一)
- 「synthetic drum prototype」 (= 既存 wording 継続)
- 「ADPCM-A friendly drum design」 (= 22nd session 新規追加)
- 「transient-focused drum design」 (= 22nd session 新規追加)
- 「synth kit first-class identity」 (= 22nd session narrative 核心、 placeholder ではなく正式)
- 「parallel kit families」 (= 22nd session 新規追加、 synth / acoustic 並存表現)

22nd session 禁止 wording (= §決定 16 wording 規律 reaffirm):
- 「RX-11 clone」
- 「ROM recreation」
- 「exact reproduction」
- 「mimic」

ADR / handoff 記載要件:
- aesthetic 方針 = **OPNA / retro FM-ADPCM aesthetic** (= §決定 24 literal 拘束)
- synth kit identity = **first-class** (= placeholder ではなく正式 PMDNEO drum family)
- acoustic kit = **optional future expansion** (= §決定 19 整合、 自動 canonical 化しない)
- design philosophy = **retro digital aesthetic over realism** (= acoustic realism は段階 2 役割)
- ADPCM-A friendly = **transient-focused design** (= 5 aesthetic target 統合表現)
- §migration roadmap 段階 1 で「retro FM/ADPCM drum aesthetic」 を target 言語として使用、 sound-alike caution 推奨 wording 強化

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

### §決定 20: current temporary fixture forensic 実施順序 = inventory first + sha256 canonical + observed-facts-first + 8 段階 flow

§決定 15 (= 中程度 forensic + 3 段階分類 + engineering provenance note 性格) の実施 entry point を「現存棚卸し先行」 に確定し、 §Annex A-5 後埋め枠を以下の 8 段階 flow で literal 化する:

1. **current wav inventory** (= `src/test-fixtures/` + `vendor/ngdevkit-examples/` 配下 rhythm 関連 wav 全列挙)
2. **sha256** (= canonical identity 固定)
3. **sample rate / length / channel count** (= wav metadata)
4. **file header** (= RIFF WAVE PCM header parse)
5. **current `samples.inc` 対応** (= `adpcma_sample_{bd,sd,cym,hh,tom,rim}` symbol と wav の対応)
6. **vendor wav 対応** (= `vendor/PMDDotNET/` / `vendor/pmd48s/` / `vendor/ngdevkit-examples/` 配下 wav との関係)
7. **4 分類推定** (= Yamaha mask ROM dump / community 配布物 / PMD culture / RX-11 sample pack のどれに likely / unknown するか)
8. **git history / external comparison は必要時のみ追加** (= forensic 中程度 = 7 軸内で完結、 法的判断ではなく engineering note)

literal 拘束:
- forensic 実施順序 = **inventory first** (= 観測可能事実先固定 → provenance 推定後追い)
- sha256 = **canonical identity** (= 後の比較で reproducible、 §Annex A-5 表に sha256 列必須)
- provenance inference = **inventory 完了後の後追い軸** (= 観測可能事実先固定)
- forensic result = **engineering note** (= 法的 certification ではない、 §決定 15 連動)
- §Annex A-5 update commit = 8 段階 flow 全完了後に表形式で literal 反映

軸 10 (a) 採用の literal 拘束。 §決定 15 (= forensic 深度軸) と整合、 §決定 15 は深度軸 / §決定 20 は実施順序軸として並存。

### §決定 21: scripts canonical pipeline 粒度 = 4 系統分離 + 4 script + Makefile target 4 件 + 役割境界

§決定 17 (= scripts canonical / WebApp future UI 役割分離 + 3 系統 scripts + Makefile target) を 22nd session で forensic 系統独立化により 4 系統化を確定する:

scripts 構成 (= 4 系統分離):
- `scripts/forensic-drum-samples.sh` (= **read-only inventory**) — **23rd session δ 新規作成 + 動作確認済 ✓** (= commit 326c88b、 8 段階 flow 1-7 mechanical 実行、 §Annex A-5 後埋め反映):
  - inventory / sha256 / file header / sample rate / bit depth / length / channel count / current `samples.inc` 対応候補 / report 出力
  - §決定 20 8 段階 flow 1-7 を mechanical に実行する read-only script
  - output = stdout 構造化 text (= 段階 8 git history は escape hatch、 必要時別途)
- `scripts/wav_to_adpcma.sh` (= **one-file converter**) — **23rd session ε interface fixation stub 新規作成 ✓** (= 9 項目 header + usage + not-implemented exit 2 sentinel、 中身実装は sub-sprint γ):
  - wav 1 file → ADPCM-A binary 1 file 変換
  - default parameter = mono / 18.5 kHz / 4-bit ADPCM-A / `2608_{bd,sd,top,hh,tom,rim}.wav` naming (= §決定 7 / §決定 8 / §決定 18 整合)
  - superctr/adpcm wrapper (= §決定 18 整合)
- `scripts/build_drum_samples.sh` (= **orchestration**) — **23rd session ε interface fixation stub 新規作成 ✓** (= 9 項目 header + usage + not-implemented exit 2 sentinel、 中身実装は sub-sprint γ):
  - 6 drum wav → 6 ADPCM-A binary → `samples.inc` / assets 出力
  - 命名 `2608_{bd,sd,top,hh,tom,rim}` (= §決定 7 整合)
  - 既存 PMDNEO build pipeline (= ADR-0019 sample addr build-time embed) 整合
- `scripts/verify-drum-samples.sh` (= **reproducibility gate**) — **23rd session ε interface fixation stub 新規作成 ✓** (= 9 項目 header + usage + not-implemented exit 2 sentinel、 中身実装は sub-sprint γ build_drum_samples 完成同時 + sub-sprint δ 段階 1 完了統合):
  - sha256 / expected length / channel count / sample rate / output binary size / optional spectral fingerprint
  - 生成物 deterministic 検証 (= 同 source wav から同 ADPCM-A binary が出ること)
  - 検証粒度 = byte-identical (= sha256 一致、 §決定 20 canonical identity 規律、 sample-level similarity は scope-out)

Makefile target = 作業者向け入口 (= 23rd session ζ 軸転換 literal、 「Makefile = script 名の写像ではない、 作業者向け公開 entry point」):

- `make drum-sources`  (= scripts/forensic-drum-samples.sh、 read-only inventory、 23rd session ζ 動作確認済 ✓)
- `make drum-build`    (= scripts/build_drum_samples.sh、 orchestration、 内部で wav_to_adpcma.sh を invoke = 低レベル変換は Makefile 直下に露出させない)
- `make drum-clean`    (= 23rd session ζ 新規追加、 generated artifact 削除、 source wav は保持、 rebuild path 確立後に有効化)
- `make drum-verify`   (= scripts/verify-drum-samples.sh、 reproducibility gate、 byte-identical sha256)

literal 拘束 (= 23rd session ζ 軸転換):
- target 名 = `drum-*` prefix で grouping (= 作業者覚えやすい、 後で内部実装差し替えても target 名固定、 4 操作軸 = 棚卸し / build / verify / clean を 1 単語で表現)
- `wav_to_adpcma.sh` は Makefile 直下に露出しない (= 低レベル変換、 `drum-build` 内部で呼ばれる扱い、 §決定 18 superctr/adpcm wrapper の隠蔽 layer)
- `drum-clean` は §決定 11 (= 段階 3 完了まで暫定許容) との安全境界として interface stub 段階で「rebuild path 確立後有効化」 を literal 規律化、 23rd session 時点 = adpcma 6 件 temporary fixture 削除すると driver build 不能のため exit 2 sentinel
- 4 件 target 命名 = 将来の `.pne` / `.neo` asset pipeline (= ADR-0021 step 7 .PNE 軸) との naming consistency (= `pne-build` / `pne-verify` 等 future extension の起点)
- Makefile target == 公開 API、 内部 script 名 == 実装詳細、 両者の独立性を確保

旧命名との対応 (= sub-sprint α 内 ζ 軸転換 traceability):
| 旧 (= 22nd session γ 22nd session 軸 11 §決定 21 literal) | 新 (= 23rd session ζ 軸転換 literal) | 軸転換根拠 |
|---|---|---|
| `make forensic-drum-samples` | `make drum-sources` | drum-* prefix grouping + 短縮 |
| `make wav-to-adpcma`         | (= Makefile 直下から排除)        | 低レベル変換は公開 entry point ではない |
| `make build-drum-samples`    | `make drum-build`               | drum-* prefix grouping + 短縮 |
| `make verify-drum-samples`   | `make drum-verify`              | drum-* prefix grouping + 短縮 |
| (= 新規)                      | `make drum-clean`               | 4 操作軸完成 (= 棚卸し / build / verify / clean) |

役割境界 (= 各 script 責務 literal):
- `forensic-drum-samples.sh` = **read-only inventory** (= 既存資産の調査専用、 wav も binary も生成しない)
- `wav_to_adpcma.sh` = **one-file converter** (= 1 wav 入力 1 ADPCM-A binary 出力、 batch ではない)
- `build_drum_samples.sh` = **orchestration** (= 6 drum batch + samples.inc 統合)
- `verify-drum-samples.sh` = **reproducibility gate** (= 生成物検証、 build pipeline 後段)

literal 拘束:
- scripts 粒度 = **4 系統分離** (= 1 script = 1 責務)
- forensic 系統 = **forward build pipeline と独立**
- 各 script は **単独実行可能** (= Makefile target 4 件で抽出)
- future contributor が **forensic だけ再実行しやすい** (= 設計目的)
- WebApp converter = **future UI** (= scripts と同仕様に追随、 §決定 17 整合)

軸 11 (a) 採用の literal 拘束。 §決定 17 (= 3 系統 scripts canonical) を 22nd session で 4 系統化に拡張、 §決定 17 は role 分離軸 (= scripts canonical / WebApp future UI) / §決定 21 は系統粒度軸として並存。

### §決定 22: Surge XT install 環境 = Homebrew cask canonical + standalone-first + plugin DAW optional + version 記録

§決定 16 (= Surge XT prototype 設計明明 prototype + 5 成果物) の install 経路を「Homebrew cask canonical」 に確定する:

install 手順:
- **`brew install --cask surge-xt`** (= macOS canonical install 経路)
- version を §Annex A-7 / design memo に literal 記録 (= future contributor reproducibility)
- standalone app を canonical (= GUI standalone で wav export、 DAW 不要)
- plugin / DAW integration は future optional (= 必要なら別 ADR or 別 sub-sprint)

literal 拘束:
- install 経路 = **Homebrew cask canonical** (= 1 command で同 version 再現可能)
- canonical form = **standalone-first** (= DAW 依存回避、 段階 1 β scope 縮減)
- plugin / DAW integration = **future optional** (= scope 拡大は別軸で判断)
- install version 記録 = **必須** (= §Annex A-7 install version 列追加、 段階 1 sub-sprint α で literal 反映)
- future contributor reproducibility = **重視** (= scripts canonical 方針と整合)
- 「**環境構築も provenance の一部**」 という観点で扱う

軸 12 (a) 採用の literal 拘束。 §決定 16 (= prototype 粒度軸) と整合、 §決定 16 は prototype 内容軸 / §決定 22 は install 経路軸として並存。

### §決定 23: prototype render naming = directory 分離 synth/acoustic + filename = drum identity + directory = kit identity + parallel kit families

§決定 7 (= source wav 公式命名 `2608_{bd,sd,top,hh,tom,rim}.wav`) + §決定 10 (= synth kit + acoustic kit 棲み分け / multi-table architecture 経由 kit 入替) を 22nd session で命名衝突回避方針として確定:

推奨 directory 構造:
- `assets/drum_samples/synth/2608_bd.wav`
- `assets/drum_samples/synth/2608_sd.wav`
- `assets/drum_samples/synth/2608_top.wav`
- `assets/drum_samples/synth/2608_hh.wav`
- `assets/drum_samples/synth/2608_tom.wav`
- `assets/drum_samples/synth/2608_rim.wav`

future expansion:
- `assets/drum_samples/acoustic/...` (= 段階 2 acoustic kit)
- `assets/drum_samples/synth_v2/...` (= future kit、 同 pattern で expand)
- `assets/drum_samples/experimental/...` (= future kit)

責務分離:
- **filename = drum identity** (= `2608_{bd,sd,top,hh,tom,rim}.wav` 不変、 §決定 7 公式命名維持)
- **directory = kit identity** (= synth / acoustic / future kit、 §決定 10 multi-table 入替 design 整合)

literal 拘束:
- naming 戦略 = **directory 分離 synth/acoustic** (= 1 filename = 1 drum identity / 1 directory = 1 kit identity)
- PMD culture compatibility = **filename レベルで維持** (= §決定 7 整合、 PMD ecosystem 全体と命名互換)
- kit provenance = **directory レベルで表現** (= synth / acoustic は **parallel kit families**)
- acoustic = **非自動 canonical** (= synth kit 単独 release 可能性 §決定 19 整合、 acoustic を「最終版」 として固定しない)
- synthetic-only release = **継続有効** (= V1 を synthetic kit で成立させる選択肢 §決定 19 整合)
- future kit expansion = **同 pattern 採用** (= `synth_v2/` `experimental/` 等、 ADR-0025 multi-table architecture activate path)

軸 13 (a) 採用の literal 拘束。 §決定 7 (= 公式命名軸) + §決定 10 (= multi-table kit 入替軸) と整合、 §決定 7 は filename 軸 / §決定 10 は architecture 軸 / §決定 23 は directory + kit identity 軸として並存。

### §決定 24: synthetic drum identity aesthetic = OPNA / retro FM-ADPCM aesthetic + synth kit first-class identity + ADPCM-A friendly transient-focused + 5 aesthetic target

§決定 14 (= sound-alike caution) + §決定 16 (= 推奨/禁止 wording 規律) を 22nd session で Surge XT prototype の音色キャラクター方針として確定:

aesthetic 方針:
- **OPNA / retro FM-ADPCM aesthetic** = 80s digital drum (= YM2608 + ADPCM-A 6ch 文化) 雰囲気追求
- 「**RX-11 を再現する**」 ではなく、 「**YM2608 / ADPCM-A 時代の aesthetic を継承する**」
- acoustic realism を目指さない (= 段階 2 役割と分離)

aesthetic target 5 項目 (= Surge XT patch 設計 target):
- **short decay** (= ADPCM-A 圧縮 + retro digital drum 特性)
- **bright transient** (= attack 強調 + 4-bit ADPCM-A 親和)
- **compressed body** (= 全体音量 envelope short + retro digital character)
- **retro digital texture** (= 80s YM2608 / OPNA 期 digital drum 質感)
- **ADPCM-friendly frequency balance** (= 18.5 kHz sample rate / 4-bit ADPCM-A 圧縮で degrade しない周波数分布)

synth kit narrative 確立 (= 22nd session 中核 wording):
- 段階 1 synth kit は **「placeholder」 ではなく「正式な PMDNEO drum family」** として扱う
- acoustic kit が future に来ても、 synth kit は **obsolete ではなく parallel family**
- **synthetic-only release は valid な PMDNEO release form** (= §決定 19 整合)

22nd session 追加推奨 wording (= §決定 16 wording 規律拡張):
- 「retro FM/ADPCM drum aesthetic」 (= 既存推奨 wording 強化)
- 「OPNA-era digital drum identity」 (= 22nd session 新規追加)
- 「PMD rhythm family compatible」 (= 既存 wording 表記揺れ統一)
- 「synthetic drum prototype」 (= 既存 wording 継続)
- 「ADPCM-A friendly drum design」 (= 22nd session 新規追加)
- 「transient-focused drum design」 (= 22nd session 新規追加)
- 「synth kit first-class identity」 (= 22nd session narrative 核心)
- 「parallel kit families」 (= 22nd session 新規追加、 synth / acoustic 並存表現)

22nd session 禁止 wording (= §決定 16 reaffirm):
- 「RX-11 clone」
- 「ROM recreation」
- 「exact reproduction」
- 「mimic」

literal 拘束:
- aesthetic 方針 = **OPNA / retro FM-ADPCM aesthetic** (= PMDNEO target NEOGEO/OPNB 文化と整合)
- synth kit identity = **first-class** (= placeholder ではなく正式 PMDNEO drum family)
- acoustic kit = **optional future expansion** (= §決定 19 整合、 自動 canonical 化しない)
- design philosophy = **retro digital aesthetic over realism** (= acoustic realism は段階 2 役割)
- ADPCM-A friendly = **transient-focused design** (= 5 aesthetic target 統合表現)
- §migration roadmap 段階 1 で「retro FM/ADPCM drum aesthetic」 を target 言語として使用、 sound-alike caution 推奨 wording 強化

軸 14 (a) 採用の literal 拘束。 §決定 14 (= sound-alike caution 軸) + §決定 16 (= prototype 粒度軸 + wording 規律) と整合、 §決定 14 は法的境界軸 / §決定 16 は prototype 内容軸 / §決定 24 は aesthetic 方針軸として並存。

### §決定 25: Surge XT fxp2wav CLI 化 = self-authored source-of-truth pipeline 必須調査として scope-in 昇格 (= spike track 1 並走、 23rd session ι' 軸転換)

§決定 16 / §Annex A-7 ζ' / 23rd session θ で「Surge XT は公式 distribution に CLI render 不在 = GUI hand-on を sub-sprint β workflow 中心とする」 で確定したが、 23rd session ι' 末 user 軸転換で **fxp2wav-surge CLI 化を future ではなく必須調査項目に昇格** 確定:

**軸転換 (= 旧 → 新):**
- **旧 (= 22nd session γ / 23rd session ζ' まで):** fxp2wav CLI 化 = future / sub-sprint γ 以降の余地として保留
- **新 (= 23rd session ι' 採用):** fxp2wav-surge CLI 化 = self-authored source-of-truth pipeline の土台として **必須**、 spike track 1 として並走着手

**根拠 (= 23rd session ι' 末 user 明示):**
- `.fxp` が source-of-truth な以上、 WAV は **再生成可能** であるべき (= 手動 audio capture は reproducibility 破綻、 [[reproducible-workflow-first-aesthetic-second]] 整合)
- 既存 unknown 起源 `2608_*.WAV` の段階 3 完了時 literal 置換 (= §決定 12 整合) には、 手動録音ではなく **再生成可能な経路** が必須 = audio capture 経路は段階 3 完全ホワイト化 milestone に持ち込めない
- DAW / VST host 経路は外部 tool 依存になり標準 pipeline にできない (= ADR-0033 自律性破壊、 §決定 17 scripts canonical 整合)
- Surge XT 公式 distribution に CLI render は不在 (= §Annex A-7 ζ' literal observed) だが、 source build で `surge-headless` 系 dev tool 化可能性あり (= github.com/surge-synthesizer/surge / surge-xt repo source)

**spike track 1 性格 = repo boundary 規律 (= 23rd session ι'' 末 user 補強、 重要):**
- **scope-in だが repo-in ではない** (= 23rd session ι'' 末 user 中核 wording literal)
- fxp2wav-surge は **PMDNEO 外部の独立 spike** として進める = 別 repo / 別 license boundary / 別 build pipeline
- PMDNEO 側は本 §決定 25 で fxp2wav-surge を **required external producer** として扱う (= 既存 §決定 18 superctr/adpcm + §Annex A-7 ζ' literal の required external producer pattern と同型 = `~/src/superctr-adpcm/` clone / make / direct invoke)
- PMDNEO source tree には Surge fork / JUCE / build artifacts を **入れない** = repo hygiene + license complexity (= Surge XT GPL-3.0 + JUCE dual license) 回避 + PMDNEO license narrative 独立性確保
- 役割境界 literal:
  - **PMDNEO**: `.fxp` を source-of-truth として扱う + `.wav` / `.adpcma` / manifest を 受け取る = consumer role
  - **fxp2wav-surge (= external producer)**: `.fxp` → deterministic `.wav` render を提供 = producer role

**spike track 1 = fxp2wav-surge CLI 調査 + PoC scope (= 23rd session 末提案、 別 branch / 別 commit 系列 / 別 session 並走):**

7 step work:
1. Surge XT source build で `surge-headless` / render 可能 component の存在確認 (= github.com/surge-synthesizer/surge / surge-xt repo clone + CMake build)
2. `.fxp` load 可否確認 (= load API or programmatic patch state set 経路)
3. note / velocity / duration 指定可否確認 (= MIDI command, OSC, programmatic note trigger 経路)
4. 44100 Hz mono 16-bit WAV 出力可否確認 (= §決定 8 整合、 file render 直接 or sample buffer → wav serialization 経路)
5. 最小 CLI 仕様案作成 (= 例 `fxp2wav-surge --input X.fxp --note D2 --velocity 100 --duration 500ms --sample-rate 44100 --output X.wav`)
6. 実装可能な場合 **PMDNEO 外部 repo** として PoC (= **PMDNEO source tree に repo-in しない**、 shell wrapper or Python wrapper + native binary、 license 整合確認 = Surge XT GPL-3.0 + JUCE dual license、 fxp2wav-surge external project は独立 license 判断)
7. spike 結果を ADR-0033 §Annex A-8 (= 新規後埋め枠) に **required external producer reference** として literal 反映 (= §Annex A-7 ζ' superctr/adpcm reference pattern 踏襲 = repo URL + commit sha + build 手順 + license + 動作確認 log)

**制約 (= 23rd session ι' 末 user 明示 + 23rd session ι'' 末 user 補強、 spike track 1 規律):**
- **β-main BD ADPCM-A chain は止めない** (= 並走 work、 BD-main は引き続き artifact 受領待ち + ι commit 別系列、 spike 結果は BD chain workflow に後 fold in)
- **DAW / VST host 経路は標準 pipeline にしない** (= scope-out、 spike 段階で「不成立時の現実的選択肢」 として確認のみ、 採用しない)
- **既存 fixture (= `assets/sounds/adpcma/2608_*.adpcma`) 置換しない** (= §決定 11 + 23rd session θ' 並行配置整合維持、 spike work は完全独立 track)
- **PMDNEO source tree に Surge fork / JUCE / build artifacts を入れない** (= 23rd session ι'' 末 user 中核制約、 repo hygiene + license complexity 回避 + PMDNEO license narrative 独立性確保)

**external repo location 候補 (= 23rd session ι'' 末 user 補強、 PMDNEO 外、 別 session 着手時に確定):**
- `github.com/koshikawa-masato/fxp2wav-surge` (= 推奨、 PMDNEO 著作者 namespace で公開 spike、 community 参照可能性確保)
- private / personal repo (= 公開しないオプション、 spike 性格的に許容、 後で公開 repo へ migration 可能)
- local-only directory (= `~/src/fxp2wav-surge/` 等、 公開しない初期 dev、 後で repo 化判断、 superctr/adpcm の `~/src/superctr-adpcm/` model と同型)

**spike 結果反映先 (= PMDNEO 本体への戻し方、 23rd session ι'' 末 user 軸転換反映):**
- **spike 成立** (= 外部 repo PoC 動作確認 + CLI render 成立) → ADR-0033 §Annex A-8 後埋め (= external producer URL + commit sha + install/build 手順 + license + version 整合確認 = §Annex A-7 ζ' superctr/adpcm pattern 踏襲)。 **PMDNEO 内 `tools/` / `vendor/` ディレクトリへ取り込まない、 external require のみ**。
- **spike 不成立** (= dev build 失敗 / API 不在 / 動作不可) → ADR-0033 §Annex A-8 に「不成立、 audio capture 経路で対応」 literal 記録 + DAW 経路再評価 (= 制約再交渉 軸として user 壁打ち) or 段階 3 完了 milestone を「acoustic 録音 only」 に redefine

**spike track 1 と β-main BD chain の関係 (= 23rd session ι'' 末 external boundary 反映):**
- β-main = PMDNEO 本体 branch (= `wip-pmddotnet-opnb-extension`) で BD hand-on artifact 受領 → encode → verify → ι commit (= 並行配置、 既存 fixture 非破壊)
- spike track 1 = **PMDNEO 外部 spike** (= 別 repo `fxp2wav-surge` 等)、 PMDNEO repo には commit しない、 PMDNEO ADR-0033 §Annex A-8 から external require reference のみ
- BD-main の `.wav` 生成経路を将来 audio capture から **external fxp2wav-surge による CLI render** に置換可能化 (= reproducibility 強化、 §決定 11/12 段階 3 完全ホワイト化 milestone への確実 path、 「scope-in だが repo-in ではない」 model で実現)
- 両 track 独立進行、 spike 成立後の BD-main rerun (= 同 .fxp で external fxp2wav-surge により再生成 WAV byte-identical) で reproducibility 統合検証

22nd session γ §決定 16 (= prototype 粒度軸) / 22nd session γ §決定 18 (= encoder = superctr/adpcm wrapper) / 23rd session ζ' §Annex A-7 (= encoder evidence collection) と整合、 §決定 25 は **synth pipeline reproducibility 軸** として独立追加、 既存 §決定 1-24 と直交。

### §決定 26: Surge XT `.fxp` authoring spec = patch source-of-truth 仕様の literal 固定 (= BD hand-on 着手前 spec 確定、 23rd session κ 軸転換)

§決定 16 / §決定 22 / §決定 23 / §決定 24 / §決定 25 で Surge XT prototype 粒度 / install 環境 / naming + directory / aesthetic / fxp2wav-surge external producer まで確定したが、 23rd session κ 末 user 軸転換で **`.fxp` 自体の authoring spec を BD hand-on 着手前に literal 固定** する規律確定 = `.fxp` を単なる hand-on 成果物ではなく **再現可能な source-of-truth** として扱う:

**軸転換 (= 旧 → 新):**
- **旧 (= 23rd session θ / θ' まで):** BD chain step 1 `.fxp` 保存 = hand-on artifact、 配置 path + 命名のみ確定 + 中身設計は越川氏 hand-on judgement 委ね
- **新 (= 23rd session κ 採用):** `.fxp` authoring spec を ADR レベル literal で先行確定 = 7 軸 (= patch naming / synthesis goal / note convention / output constraint / patch design constraint / metadata-provenance / acceptance gate) + 非目標 4 件、 BD hand-on は spec に従って実施

**根拠 (= 23rd session κ 末 user 明示):**
- `.fxp` = source-of-truth (= §決定 25 整合) である以上、 中身 spec も再現可能 / verify 可能であるべき
- spec 不在で hand-on 着手 = aesthetic refinement と reproducibility 規律の境界曖昧化 risk (= [[reproducible-workflow-first-aesthetic-second]] 整合)
- BD chain 残 5 音横展開 (= 23rd session θ depth-first scaling) 時の **canonical template** として BD spec 再利用可能化 (= future SD / CYM / HH / TOM / RIM へ同 spec 雛形展開)
- κ commit = doc only、 driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変

**7 軸 literal 拘束:**

(1) **patch naming:**
- file name = `2608_bd.fxp` (= §決定 7 命名 + §決定 23 directory = kit identity 整合)
- Surge XT display name = `PMDNEO 2608 BD Self v0` (= 越川氏 self-authored 識別 + version 軸初期値 `v0` = 段階 1 sub-sprint β BD chain initial proof + future iteration 余地保持)

(2) **synthesis goal:**
- YM2608 BD **完全再現ではない** (= §決定 14 sound-alike caution + §決定 24 aesthetic 整合)
- **modern reusable BD** (= NEOGEO/OPNB 環境で broad 用途に再利用可能な汎用 BD 設計)
- ADPCM-A 変換後も BD として成立する **短い kick** (= §決定 9 chip 化 pipeline 18.5 kHz decimate + 4-bit 圧縮整合 + §決定 24 short decay / bright transient / ADPCM-friendly frequency balance 整合)

(3) **note convention:**
- render note = **MIDI note 36 / C1** (= GM drum kick 標準 + Surge XT 標準 trigger 経路整合)
- velocity = **127** (= maximum velocity、 normalize 規約と分離 = patch envelope 単独で peak target 制御)
- duration = **800 ms** (= ADPCM-A 上での実用 BD 長 + §決定 24 short decay 整合、 23rd session θ' trim 規約 leading 0 + trailing +50-100 ms 適用後の実 sample 長 700-750 ms 想定)

(4) **output constraint:**
- mono 想定 (= §決定 8 RIFF WAVE PCM / 1 ch / 44100 Hz / 16 bit 整合)
- **no normalize** (= 23rd session θ' parameter literal 整合 = patch envelope 単独で peak 制御)
- peak target = 安全域 = 例 **-6 dBFS 〜 -3 dBFS** (= clipping 確実回避 + ADPCM-A encode 余地確保)
- clipping 禁止 (= 0 dBFS reach は ADPCM-A encode 時 anti-overflow `-a` ON で safety net あるが、 patch 側で先制回避)

(5) **patch design constraint (= 再現性 + 自律性確保 軸):**
- external sample 禁止 (= Surge XT 内蔵以外の WAV / AIFF / SF2 sample 取り込み排除 = §決定 25 self-authored + repo boundary 整合)
- Surge XT 内蔵 osc / filter / env / fx のみ使用 (= synthesis primitive 軸限定)
- random / drift / unseeded modulation **禁止または seed 固定** (= deterministic render 必須 = §決定 25 spike track 1 / fxp2wav-surge bit-identical render 整合)
- long reverb / delay tail を避ける (= §決定 24 short decay + ADPCM-A 18.5 kHz / 4-bit 圧縮後の tail degradation 回避)
- ADPCM-A 後の劣化を前提に **低域と attack を明確化** (= §決定 24 bright transient + ADPCM-friendly frequency balance 整合)

(6) **metadata / provenance:**
- Surge XT version (= 例 `1.3.4` = §Annex A-7 η install version 整合)
- author (= 越川将人 / `M.Koshikawa.`、 CLAUDE.md §著作権者表記整合)
- creation date (= ISO 8601 形式、 例 `2026-05-16`)
- render command (= fxp2wav-surge invoke command literal、 §決定 25 spike track 1 成立後確定)
- `SURGE_RNG_SEED` (= 内部 RNG seed 固定値、 §決定 25 spike track 1 で seed 制御経路確認時に確定)
- sha256 of `.fxp` / `.wav` / `.adpcma` (= 3 段階 artifact hash = manifest 一括記録、 23rd session θ' parameter literal 整合)

(7) **acceptance gate (= BD chain ι commit 完了条件統合):**
- fxp2wav-surge で render 可能 (= external producer 経路成立 = §決定 25 spike track 1 成立前提)
- 同 seed で **bit-identical WAV** (= deterministic 再現性 verify 必須 = §決定 25 spike 成立条件整合)
- WAV format = **44100 Hz / mono / 16-bit** (= §決定 8 整合)
- 聴感上 BD として成立 (= 越川氏 hand-on judgement、 §決定 24 OPNA / retro FM-ADPCM aesthetic 整合)
- 既存 fixture (= `assets/sounds/adpcma/2608_BD.adpcma`) とは **別物として並行配置** (= 23rd session θ' literal 整合 = 並行配置 path `assets/sounds/adpcma/2608_bd_self.adpcma`)

**非目標 (= scope-out literal):**
- YM2608 BD の模倣 (= §決定 14 sound-alike caution + §決定 24 aesthetic 整合 = RX-11 clone 禁止 wording 連動)
- 完成音の追い込み (= §決定 19 段階 1 完全集中 + acoustic 後回し + [[reproducible-workflow-first-aesthetic-second]] = workflow canonical 確立後の別軸)
- 6 音同時設計 (= 23rd session θ depth-first scaling / BD 1 音先行 chain 整合、 残 5 音は BD spec 雛形横展開)
- GUI 依存の暗黙手順 (= §決定 25 fxp2wav-surge CLI 化 + spec literal 化整合、 hand-on judgement 軸はあるが手順自体は文書化)

**spec 適用順序 (= BD hand-on 着手前 → 着手 → 完了 までの literal 規律):**
- BD hand-on 着手前 = 本 §決定 26 spec を Surge XT GUI 上で patch 構築前に通読
- BD hand-on 着手 = 7 軸 + 非目標 を遵守して patch 構築 (= 越川氏 hand-on judgement、 7 軸内で aesthetic 自由度確保)
- BD hand-on 完了 = 7 軸 acceptance gate 全 PASS で `.fxp` 保存 → BD chain step 3 (= WAV render) へ
- 残 5 音 (= SD / CYM / HH / TOM / RIM) hand-on 時 = 本 spec を template として patch naming + note + aesthetic を drum 種固有調整 (= drum 種別差分 spec は別 §決定 候補、 sub-sprint β-2 以降)

**spec 範囲外 (= κ commit で confirm しない、 future 軸):**
- 残 5 音 spec 雛形展開 (= BD spec 横展開時の差分 spec、 BD chain 完成後の sub-sprint β-2 候補)
- aesthetic refinement iteration (= §決定 24 aesthetic target 5 項目の hand-on judgement、 BD chain 1 巡完成後の別軸 + [[reproducible-workflow-first-aesthetic-second]] 整合)
- Surge XT GUI 操作手順詳細 (= screenshot / video tutorial、 docs/guide/ 等の人間向け公開 docs で別軸)
- fxp2wav-surge CLI 仕様 (= §決定 25 spike track 1 で確定、 本 §決定 26 は consumer 側 spec のみ)

§決定 7 (= 命名規則) / §決定 8 (= source wav format) / §決定 9 (= chip 化 pipeline) / §決定 14 (= sound-alike caution) / §決定 16 (= prototype 粒度軸 + wording 規律) / §決定 19 (= 段階 1 集中) / §決定 22 (= Surge XT install) / §決定 23 (= naming + directory) / §決定 24 (= aesthetic) / §決定 25 (= fxp2wav-surge external producer) と整合、 §決定 26 は **`.fxp` authoring spec 軸** として独立追加、 既存 §決定 1-25 と直交、 driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変。

### §決定 27: AI-assisted patch generation + `.fxp` bridge + rendered-audio self-analysis workflow = AI 設計補助 + AI/toolchain bridge + AI engineering 検査 + 越川氏 aesthetic final acceptance 軸独立 (= source-of-truth = `patch-spec.yaml`、 template-based `.fxp` candidate generation + parameter allowlist patching = scope-in、 arbitrary `.fxp` binary full generation + full binary RE = scope-out、 23rd session λ 起票 / μ 初回適用 / ν 全面再定義 / ξ AI/toolchain bridge 軸統合 + 越川氏 hand-on engineering 役割解放)

§決定 1 (= 100% 著作物のみ採用) / §決定 14 (= sound-alike caution) / §決定 16 (= prototype 粒度 + wording 規律) / §決定 19 (= 段階 1 集中) / §決定 24 (= aesthetic) / §決定 25 (= fxp2wav-surge external producer) / §決定 26 (= `.fxp` authoring spec) で patch source-of-truth の中身規約まで確定、 23rd session λ で AI-assisted patch generation workflow を起票、 μ で BD candidate を 1 件生成、 ν で全面再定義 (= user acceptance downstream 配置 + AI self-analysis 軸追加)。 その結果 23rd session ξ で **「ν step 2 = 越川氏 hand-on は engineering correctness を越川氏に押し付ける構造で ν 本質と矛盾」 finding** 確認 = 越川氏 acceptance を aesthetic final gate に純化するなら `.fxp` 生成も AI/toolchain 軸に置くべき。 23rd session ξ で **AI/toolchain による patch-spec → `.fxp` template-based bridge + parameter allowlist patching を scope-in 化** + **越川氏 hand-on の engineering 役割を解放** で役割再配置:

**軸転換 (= λ/μ → ν → ξ の 3 段):**
- **旧 (= 23rd session κ まで):** `.fxp` 制作は越川氏 hand-on のみ前提 = §決定 26 spec を Surge XT GUI 上で人間が直接構築
- **λ/μ 中間 (= 23rd session λ/μ):** AI candidate spec → 越川氏 audition / edit / accept → `.fxp` hand-on → wav render → ADPCM-A encode (= **user acceptance が upstream**)
- **ν 中間 (= 23rd session ν):** AI candidate spec → 越川氏 hand-on → wav render → AI self-analysis → ... → 越川氏 final accept (= **user acceptance を downstream に再配置**、 但し step 2 で越川氏 hand-on 残存 = engineering correctness が越川氏に残る矛盾)
- **新 (= 23rd session ξ 採用):** AI candidate spec → **AI/toolchain による template-based `.fxp` bridge** → AI/toolchain orchestrated wav render → AI self-analysis → AI revision → wav re-render → ADPCM-A encode → MAME / audio gate → **越川氏 audition / edit / accept (= aesthetic final gate)** (= **越川氏 hand-on を engineering 軸から完全解放**、 越川氏 role = aesthetic judgement only)

**根拠 (= ν 5 項目維持 + ξ 5 項目追加):**
- AI が機械的に判定可能なもの (= waveform sanity / peak / RMS / clipping / silence / attack / decay / transient strength / spectral balance / tail length / ADPCM-A friendly frequency balance) を **user audition 前に全部落とす** 方が越川氏の認知負荷が下がる (= ν 維持)
- user audition で「engineering 検査 fail の candidate」 を聴かせるのは時間 + aesthetic judgement 軸の浪費 (= ν 維持)
- AI engineering 検査と人間 aesthetic judgement は **別軸** = 軸独立で順序関係 (= engineering 先 / aesthetic 後) を ADR レベル literal で確立 (= ν 維持)
- 既存 §決定 27 (λ/μ 時点) は AI 役割を「patch spec 設計補助」 のみに限定していたが、 「rendered wav self-analysis」 まで含めれば AI の貢献が signal analysis 軸でも明確化 (= ν 維持)
- 越川氏 acceptance は **aesthetic / musical judgement** に絞られる = 「engineering 検査の代行」 から解放される (= ν 維持)
- **(ξ 追加)** ν step 2 の「越川氏 hand-on」 は ν 本質 (= acceptance downstream / 越川氏 認知負荷を engineering correctness から解放) と矛盾 = 越川氏が GUI で patch parameter を実装する work は **engineering correctness 業務**、 aesthetic judgement ではない
- **(ξ 追加)** 「AI が `.fxp` 直接生成不可」 という旧前提は λ 起票時の制約由来。 `.fxp` 全 binary format reverse engineering ではなく **template + parameter allowlist patching 方式** なら 技術リスク最小で AI 生成可能
- **(ξ 追加)** template-based bridge の利点 = (a) 越川氏 1 度だけ template `.fxp` を Surge XT GUI で作成 + (b) 全 6 drum 種で template を共有 + (c) drum-specific parameter のみ AI が patching + (d) template `.fxp` の provenance / hash 記録で reproducibility 確保
- **(ξ 追加)** template-based 制約で技術リスク最小化 = (a) Surge XT `.fxp` chunk format の **無制限解析を避ける** + (b) parameter allowlist 経由で patching 範囲を literal 制限 + (c) 「bridge, not full synthesizer patch compiler」 wording で目標範囲明確化
- **(ξ 追加)** 越川氏 hand-on は GUI で 1 度だけ template `.fxp` を作成する base patch design 段階のみに限定 = drum-specific patch は AI/toolchain bridge で生成、 越川氏 review 対象は rendered audio のみ = aesthetic judgement 純化
- **ν 中核 wording 維持** = 「acceptance は downstream、 upstream ではない」 / 「machine-checkable quality gate + human aesthetic final gate 2 layer」
- **ξ 中核 wording 追加** = 「template-based `.fxp` candidate generation」 / 「parameter allowlist patching」 / 「bridge, not full synthesizer patch compiler」 / 「engineering candidate before aesthetic judgement」

**11 軸 literal 拘束 (= λ 8 軸 → ν 10 軸 → ξ 11 軸に拡張):**

(1) **AI 役割境界 = 4 軸に拡張 (= 設計補助 + bridge + render + 検査):**
- AI 役割 1 = patch spec 設計補助 (= λ 起票分、 維持)
- AI 役割 2 = **patch-spec → `.fxp` template-based bridge** (= ξ 追加、 template `.fxp` + parameter allowlist patching 軸、 toolchain implementation、 「bridge, not full synthesizer patch compiler」)
- AI 役割 3 = **wav render orchestration** (= ξ 追加、 fxp2wav-surge external producer invoke、 toolchain integration、 1-command 化 goal)
- AI 役割 4 = **rendered audio self-analysis** (= ν 追加、 engineering / signal analysis 軸)
- AI は **arbitrary `.fxp` binary full generation を行わない** (= ξ 制約、 template-based + parameter allowlist patching のみ scope-in、 「bridge, not full synthesizer patch compiler」)
- AI は **full `.fxp` binary format reverse engineering を行わない** (= ξ 制約、 必要最小限のみ許容、 「checksum / chunk format の無制限解析」 は scope-out)
- AI は **aesthetic / musical judgement を行わない** (= 永久 scope-out、 越川氏専管)
- AI は **越川氏 acceptance signature の代理生成をしない** (= 永久 scope-out、 §決定 1 100% 著作物方針整合)
- AI が生成する全 artifact (= spec / `.fxp` / `.wav` / `.adpcma`) は **candidate** = 採用候補、 越川氏 aesthetic final gate 経由で初めて PMDNEO asset 化

(2) **source-of-truth 階層 (= 4 段 → 5 段 chain に拡張、 ν analysis report 追加):**
- 最上位 = `patch-spec.yaml` (= human-readable、 AI / 越川氏 / future contributor 共通 source-of-truth、 §決定 27 (4) 12 項目)
- 次位 = `.fxp` (= Surge XT binary、 越川氏 hand-on 生成、 §決定 26 spec 整合)
- 派生 1 = `.wav` (= fxp2wav-surge render、 **AI self-analysis 通過までは「candidate wav」**、 §決定 25 reproducibility 整合)
- 派生 1 検査 = `analysis-report.yaml` (= **ν 新規 artifact**、 AI self-analysis 10 項目結果、 patch-spec 同 directory)
- 派生 2 = `.adpcma` (= superctr/adpcm encode、 self-analysis 通過後、 §Annex A-7 ζ' literal 整合)
- chain 全体 = `patch-spec.yaml` → `.fxp` → `.wav (candidate)` → `analysis-report.yaml` → (必要なら revision loop) → `.wav (analysis-passed)` → `.adpcma` → MAME / audio gate → 越川氏 acceptance

(3) **patch spec 形式 (= 維持、 λ 起票分):**
- 推奨形式 = **YAML** (= machine-readable + human-readable + version control friendly)
- 代替 = **Markdown table** (= 人間 review friendly、 narrative 補強)
- formal schema は本 §決定 27 では未確定 (= sub-sprint β BD chain 1 巡完成後の別軸 = patch spec schema 確定 commit 候補)

(4) **patch spec 最低必須 12 項目 (= 維持、 λ 起票分):**
- `drum role` (= BD / SD / TOP / HH / TOM / RIM のいずれか、 §決定 7 命名軸整合)
- `design intent` (= 設計意図、 §決定 24 aesthetic target 5 項目との関係 narrative)
- `oscillator plan` (= Surge XT 内蔵 osc 構成案、 §決定 26 (5) 内蔵 only 整合)
- `noise / transient plan` (= attack / transient 設計案、 §決定 24 bright transient 整合)
- `pitch envelope` (= pitch modulation 設計案)
- `amplitude envelope` (= AHDSR 等 envelope 設計案、 §決定 24 short decay 整合)
- `filter / waveshaper / drive` (= 音色加工 chain 設計案、 §決定 26 (5) Surge XT 内蔵 only 整合)
- `modulation` (= LFO / step seq 等 modulation 設計案、 §決定 26 (5) seed 固定 or random/drift/unseeded 禁止整合)
- `expected decay` (= 期待 sample duration、 §決定 26 (3) 800 ms 規約整合)
- `ADPCM-A friendly notes` (= 4-bit 圧縮 / 18.5 kHz decimate 親和の design hint、 §決定 9 + §決定 24 整合)
- `prohibited references` (= RX-11 clone / ROM recreation / mimic 禁止 wording 明記、 §決定 14 + §決定 24 整合)
- `acceptance criteria` (= engineering pass + aesthetic accept 個別条件、 §決定 27 ν 分離後は 2 階層、 §決定 26 (7) base + drum 種固有追加)

(5) **AI self-analysis 必須検査 10 項目 (= ν 新規):**
- `waveform sanity` (= WAV file 構造 valid、 RIFF header 正常、 sample data 読込可、 spec parameter integrity)
- `peak amplitude` (= 全 sample 中の max abs value、 dBFS 換算、 §決定 26 (4) -6〜-3 dBFS 範囲 verify)
- `RMS amplitude` (= root-mean-square energy、 dBFS 換算、 drum 種別の expected RMS 範囲との対比)
- `clipping detection` (= 0 dBFS reach sample count、 §決定 26 (4) clipping 禁止 literal verify、 期待値 0)
- `silence detection` (= leading silence ms + trailing silence ms、 23rd session θ' trim 規約整合確認)
- `attack characteristics` (= attack ms、 transient peak position、 §決定 24 bright transient + patch spec amp envelope 整合)
- `decay characteristics` (= decay ms、 decay curve shape、 §決定 24 short decay + patch spec amp envelope `decay_ms` 整合確認)
- `transient strength` (= attack peak / sustained body ratio、 §決定 24 transient-focused 整合確認)
- `spectral balance` (= FFT 帯域別 energy distribution、 §決定 24 ADPCM-friendly frequency balance + patch spec `adpcm_a_friendly_notes` 整合確認)
- `tail length / ADPCM-A friendly` (= silence threshold 以下 trailing energy 持続 ms、 §決定 24 short decay + sustain 0 整合確認)

(6) **acceptance workflow (= ν 全面再定義 11 step + ξ step 2/3 役割再配置):**
1. AI が drum role + design intent (= 越川氏指定) を受け取り、 `patch-spec.yaml` candidate 生成
2. **AI/toolchain による patch-spec → `.fxp` template-based bridge** (= template `.fxp` + parameter allowlist patching、 「engineering candidate before aesthetic judgement」、 §決定 26 spec 整合 verify、 §決定 27 (9) ξ artifact `template.fxp` / `parameter-allowlist.yaml` / `template.fxp.provenance.yaml` 経由)
3. **AI/toolchain orchestrated wav render** (= fxp2wav-surge external producer invoke、 §決定 25 spike track 1 経路、 deterministic `.wav (candidate)` 生成、 1-command 化 goal = step 2-3 ideally 連動)
4. **AI self-analysis (= 上記 (5) 10 項目検査、 `analysis-report.yaml` 生成)**
5. AI revision proposal (= 検査結果に基づく patch-spec / `.fxp` 調整案、 engineering FAIL 時のみ)
6. 必要なら patch-spec / `.fxp` 再調整 → step 3 へ loop (= engineering 検査全通過まで iterate)
7. AI self-analysis 全項目 PASS = `.wav (analysis-passed)` 認定 = `engineering_pass: passed`
8. superctr/adpcm encode (= §Annex A-7 ζ' literal、 `ae -a` direct invoke、 `.adpcma` 生成)
9. MAME / audio gate (= 必要に応じて driver fixture 差替で trigger 確認、 runtime regression 防衛)
10. **越川氏 audition / edit / accept (= 最終 gate、 aesthetic / musical judgement、 rendered audio のみが review 対象)**
11. accept 後 = `aesthetic_acceptance: accepted` + signature + ι commit (= 並行配置、 既存 fixture 非破壊)

注意: ν → ξ で step 2 + 3 のみ AI/toolchain 軸に置換、 step 1 / 4-11 は不変。 越川氏 hand-on の **唯一の engineering 接点** = template `.fxp` 作成 (= 全 6 drum 種共有 base、 1 度だけ実施、 §決定 27 (9) ξ artifact `template.fxp.provenance.yaml` に記録)。 drum-specific patch は AI/toolchain bridge で生成、 越川氏 review 対象は **rendered audio のみ** = aesthetic judgement 純化。

(7) **provenance chain 5 段階記録 (= ν 拡張、 AI self-analysis report 追加):**
- step 1: `patch-spec.yaml` (= sha256 + AI agent identifier + 生成日)
- step 2: `.fxp` (= sha256 + Surge XT version + 越川氏 hand-on signature)
- step 3: `.wav` (= sha256 + seed + render command + render-passed flag)
- step 4: **`analysis-report.yaml`** (= sha256 + 10 項目 PASS/FAIL + revision iteration count)
- step 5: `.adpcma` (= sha256 + encoder version)
- + MAME audio gate log (= optional、 trace 結果 ref)
- + 越川氏 acceptance signature (= 最終 gate、 aesthetic judgement 記録)

(8) **越川氏 100% 著作方針との整合 (= ν 拡張 narrative):**
- AI-assisted patch generation + AI engineering 検査を採用しても、 **最終 asset = 越川氏 100% 著作物** という ADR-0033 中核方針は不変
- 根拠 = AI は (a) 設計補助 (= candidate 提示) + (b) 機械検査 (= engineering signal analysis) のみ、 aesthetic judgement / 採用判断は越川氏専管
- AI engineering 検査 = 信号解析 (= 客観的、 数値判定)
- 越川氏 aesthetic judgement = 音楽的 / 文化的判断 (= 主観的、 ear judgement)
- 軸独立 = engineering pass = 「asset として使える」 (= 客観品質)、 aesthetic accept = 「asset として採用する」 (= 主観品質 + 文化的整合)
- provenance metadata に「AI-assisted spec + AI self-analysis + 越川氏 aesthetic acceptance」 を **literal 明記** (= future contributor / 第三者から判別可能)
- RX-11 clone / mimic / ROM recreation 方向の AI candidate は越川氏 reject 必須 + AI self-analysis でも `prohibited_references` 違反 flag を出す (= §決定 14 + §決定 24 sound-alike caution gatekeeping 二重化)

(9) **成果物 path canonical (= 6 → 9 件に拡張、 ξ bridge artifacts 3 件追加):**
- `docs/design/rhythm-patches/synth/2608_bd.patch-spec.yaml` (= λ μ 起票分、 維持)
- `assets/drum_samples/synth/templates/2608_template.fxp` (= **ξ 新規**、 越川氏 hand-on で 1 度だけ作成する canonical template `.fxp`、 全 6 drum 種で共有 base、 §決定 26 spec parameter base structure 整合、 越川氏の engineering 接点はここのみ)
- `docs/design/rhythm-patches/synth/parameter-allowlist.yaml` (= **ξ 新規**、 template `.fxp` の patching 可能 parameter list、 AI bridge が touch 可能な parameter 範囲を literal 制限、 「parameter allowlist patching」 軸の literal 制約)
- `docs/design/rhythm-patches/synth/template.fxp.provenance.yaml` (= **ξ 新規**、 template `.fxp` の sha256 + Surge XT version + 越川氏 hand-on 日時 + base patch design intent 記録、 reproducibility 確保)
- `assets/drum_samples/synth/patches/2608_bd.fxp` (= 維持、 ξ で AI/toolchain bridge 出力に役割変更、 candidate 扱い)
- `assets/drum_samples/synth/2608_bd.wav` (= 維持、 ξ で AI/toolchain render 出力に役割変更、 candidate 扱い)
- `docs/design/rhythm-patches/synth/2608_bd.analysis-report.yaml` (= ν 維持、 AI self-analysis 10 項目結果)
- `assets/sounds/adpcma/2608_bd_self.adpcma` (= 維持、 23rd session θ' 並行配置 literal 整合、 既存 `2608_BD.adpcma` 非破壊)
- `metadata/provenance entry` (= 維持、 5 段階 sha256 + analysis report ref + template provenance ref 拡張)

注意: `docs/design/rhythm-patches/synth/` は λ/μ 起票分の新規 directory、 ν で `analysis-report.yaml` 並列追加、 ξ でさらに `parameter-allowlist.yaml` + `template.fxp.provenance.yaml` 並列追加。 `assets/drum_samples/synth/templates/` は ξ 新規 directory、 template `.fxp` 配置先。 残 5 音 (= SD/CYM/HH/TOM/RIM) 横展開時に `2608_<drum>.patch-spec.yaml` + `2608_<drum>.analysis-report.yaml` + `2608_<drum>.fxp` + `2608_<drum>.wav` + `2608_<drum>_self.adpcma` ペア命名で並ぶ、 template `.fxp` + `parameter-allowlist.yaml` + `template.fxp.provenance.yaml` は **6 drum 種共通 1 件のみ** (= 越川氏 hand-on は template 作成 1 度のみで完結)。

(10) **engineering pass と aesthetic accept の分離 (= ν 中核 wording):**
- **engineering pass** = AI self-analysis 10 項目全 PASS = `.wav (analysis-passed)` 認定 = 越川氏 audition 前段資格
- **aesthetic accept** = 越川氏 audition / edit / accept = asset 化 final gate
- **engineering pass ≠ aesthetic accept** (= 別軸、 順序関係 = engineering 先 / aesthetic 後 literal)
- **engineering FAIL** なら越川氏 audition なし (= AI revision loop 経由で先に engineering 修正)
- **engineering PASS かつ aesthetic REJECT** は valid = 越川氏は signal が綺麗でも musical に reject 可能 (= aesthetic 最終 gate 権限)
- **acceptance は downstream、 upstream ではない** (= ν 中核 wording literal)
- **machine-checkable quality gate** + **human aesthetic final gate** の 2 layer 構成

(11) **ξ scope-in literal = AI/toolchain bridge 軸 5 件 (= ξ 新規):**
- `patch-spec.yaml` → template `.fxp` parameter patching bridge (= §決定 27 (1) AI 役割 2 軸、 toolchain implementation、 「bridge, not full synthesizer patch compiler」)
- template `.fxp` の provenance / hash 記録 (= §決定 27 (9) ξ artifact `template.fxp.provenance.yaml` 経由、 sha256 + Surge XT version + 越川氏 hand-on 日時 + base patch design intent、 reproducibility 確保)
- patching 対象 parameter の allowlist (= §決定 27 (9) ξ artifact `parameter-allowlist.yaml` 経由、 「parameter allowlist patching」 軸の literal 制限、 AI bridge touch 範囲を 明示的に enumerate)
- generated `.fxp` は candidate (= §決定 27 (1) AI 役割 2 軸出力、 越川氏 aesthetic final gate 経由で asset 化、 「engineering candidate before aesthetic judgement」)
- `.fxp` → wav render → AI self-analysis → user final gate (= §決定 27 (6) workflow step 2-10 整合、 全段 candidate 扱い、 越川氏 final gate でのみ asset 化)

**spec 適用順序 (= AI-assisted patch generation + self-analysis workflow 11 step、 ξ step 2/3 役割再配置版):**
上記 (6) acceptance workflow 11 step と同一、 ν 軸 + ξ 軸の中核 process literal。

**scope-out (= §決定 27 で confirm しない、 future 軸 10 件、 ξ refinement):**
- **arbitrary `.fxp` binary full generation** (= ξ 改修、 template-based + parameter allowlist patching のみ scope-in、 「bridge, not full synthesizer patch compiler」 wording 連動)
- **full `.fxp` binary format reverse engineering** (= ξ 改修、 必要最小限のみ許容、 template-based bridge 成立に不可欠な部分のみ調査許容)
- **`.fxp` checksum / chunk format の無制限解析** (= ξ 新規、 template-based bridge 成立に必要な最小限のみ許容、 future 拡張は別 sprint 候補)
- AI による final asset 直生成 (= 維持、 永久 scope-out、 越川氏 aesthetic final gate を bypass する pattern 禁止)
- patch spec schema formal 確定 (= 維持、 sub-sprint β BD chain 1 巡完成後の別軸 commit 候補)
- 「自動 listen test / 自動 aesthetic score」 (= ν 整理、 永久 scope-out 維持、 但し AI self-analysis = engineering 検査は scope-in 化、 軸境界明確化)
- AI agent identity の version pinning 規約 (= 維持、 free choice、 metadata 記録のみ義務)
- RX-11 clone / mimic / ROM recreation 方向の AI candidate (= 維持、 §決定 14 + §決定 24 sound-alike caution literal、 AI 経由でも禁止維持 + AI self-analysis でも flag 立て)
- **AI による aesthetic judgement (= ν 新規 scope-out、 永久)** = 越川氏 final gate を bypass する pattern 禁止、 「acceptance は downstream」 literal 連動
- **AI が user acceptance を代替すること** (= ξ user 明示 literal wording、 ν の「AI による 越川氏 acceptance signature 代理生成」 を含む、 §決定 1 100% 著作物方針 literal 違反、 永久 scope-out)

§決定 1 (= 100% 著作物のみ採用) / §決定 14 (= sound-alike caution) / §決定 16 (= prototype 粒度 + wording 規律) / §決定 19 (= 段階 1 集中) / §決定 24 (= aesthetic) / §決定 25 (= fxp2wav-surge external producer) / §決定 26 (= `.fxp` authoring spec) と整合、 §決定 27 は **AI-assisted patch generation + `.fxp` bridge + rendered-audio self-analysis workflow 軸** として独立追加 + ν 全面再定義 + ξ AI/toolchain bridge 軸統合 (= λ 8 軸 → ν 10 軸 → ξ 11 軸、 AI 役割 1 軸 → ν 2 軸 → ξ 4 軸、 4 段 → 5 段 chain、 user acceptance upstream → downstream、 越川氏 hand-on engineering 軸解放 / aesthetic final gate 純化、 template-based `.fxp` bridge + parameter allowlist patching scope-in)、 既存 §決定 1-26 と直交、 driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 完全不変。

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

**ADR-0033 Draft update 21st session 完了 commit (= commit 5a2549a):**
- §決定 15-19 追加 (= 5 軸壁打ち決定の literal 拘束、 軸 5 forensic 深度 / 軸 6 prototype 粒度 / 軸 7 pipeline scripts 化 / 軸 8 encoder 採用 / 軸 9 acoustic timing)
- §Annex A-5 後埋め枠 update (= 3 段階分類 confirmed / likely / unknown + engineering provenance note 性格 + 中程度 forensic 7 調査軸 literal 化)
- §Annex A-7 後埋め枠 update (= superctr/adpcm + wrapper script 採用方針確定、 sub-sprint γ で license + 動作確認 + 採用根拠 literal 反映)
- ## 重要 wording 規律 拡充 (= 21st session 追加推奨 wording + 禁止 wording)
- 本 sub-sprint α 内容詳細化 (= 21st session update)

**ADR-0033 Draft update 22nd session 本 commit:**
- §決定 20-24 追加 (= 5 軸壁打ち決定の literal 拘束、 軸 10 forensic 実施順序 / 軸 11 scripts canonical pipeline 粒度 / 軸 12 Surge XT install 環境 / 軸 13 prototype render naming / 軸 14 synthetic drum identity aesthetic)
- §Annex A-5 inventory-first / sha256 canonical / observed-facts-first wording 補強 + 8 段階 flow literal 化 + §決定 21 連動 forensic-drum-samples.sh reference 追加
- §Annex A-7 4 系統 scripts 化 (= forensic-drum-samples.sh + wav_to_adpcma.sh + build_drum_samples.sh + verify-drum-samples.sh) + Makefile target 4 件 + 役割境界 literal 化 + Surge XT install 環境 (= Homebrew cask canonical) 後埋め枠追加
- ## migration roadmap 段階 1 sub-sprint α 22nd session 反映 (= 本 update)
- ## 重要 wording 規律 22nd session 追加 wording 反映 (= synth kit first-class identity / OPNA-era digital drum identity / ADPCM-A friendly drum design / Homebrew cask canonical / filename = drum identity / directory = kit identity / parallel kit families 等)

**段階 1 sub-sprint α 実作業 (= 22nd session update commit 後、 3 work 独立並走可能):**

(1) **current temporary fixture forensic** (= §決定 15 + §決定 20 + §Annex A-5 literal 反映):
- 実施 entry point = **inventory first** (= §決定 20 literal 拘束、 22nd session 中核規律)
- 8 段階 flow (= §決定 20 literal):
  1. current wav inventory (= `src/test-fixtures/` + `vendor/ngdevkit-examples/` 配下 rhythm 関連 wav 全列挙)
  2. sha256 (= canonical identity)
  3. sample rate / length / channel count
  4. file header (= RIFF WAVE PCM header parse)
  5. current `samples.inc` 対応 (= `adpcma_sample_{bd,sd,cym,hh,tom,rim}` symbol と wav の対応)
  6. vendor wav 対応 (= `vendor/PMDDotNET/` / `vendor/pmd48s/` / `vendor/ngdevkit-examples/` 配下 wav との関係)
  7. 4 分類推定 (= Yamaha mask ROM dump / community 配布物 / PMD culture / RX-11 sample pack のどれに likely / unknown するか)
  8. git history / external comparison は必要時のみ追加
- 実施 script = `scripts/forensic-drum-samples.sh` (= §決定 21 literal、 read-only inventory)
- 結果を §Annex A-5 に 3 段階分類 (= confirmed / likely / unknown) + 起源 4 分類別判断 + engineering provenance note として表形式で literal 反映 (= update commit)

(2) **scripts canonical pipeline 雛形** (= §決定 17 + §決定 21 + §Annex A-7 literal 反映):
- 4 系統 scripts 雛形作成:
  - `scripts/forensic-drum-samples.sh` (= read-only inventory、 上記 8 段階 flow 実行)
  - `scripts/wav_to_adpcma.sh` (= one-file converter、 superctr/adpcm wrapper、 §決定 18 整合)
  - `scripts/build_drum_samples.sh` (= orchestration、 6 drum batch、 §決定 23 naming)
  - `scripts/verify-drum-samples.sh` (= reproducibility gate)
- Makefile target 4 件追加 (= 23rd session ζ 軸転換後 literal、 「Makefile = 作業者向け入口」):
  - `make drum-sources` (= scripts/forensic-drum-samples.sh)
  - `make drum-build`   (= scripts/build_drum_samples.sh、 内部で wav_to_adpcma.sh invoke)
  - `make drum-verify`  (= scripts/verify-drum-samples.sh)
  - `make drum-clean`   (= 23rd session ζ 新規、 rebuild path 確立後有効化)
- 役割境界 (= §Annex A-7 表形式 literal): read-only inventory / one-file converter / orchestration / reproducibility gate
- 段階 1 sub-sprint α 段階では forensic-drum-samples.sh のみ動作確認 (= (1) で使用)、 他 3 script は雛形のみで sub-sprint β-γ で本格稼働

(3) **Surge XT install** (= §決定 22 + §Annex A-7 literal 反映、 越川氏 hand-on、 越川氏 macOS):
- install 経路 = **Homebrew cask canonical** (= §決定 22 literal 拘束)
- 手順 = `brew install --cask surge-xt`
- canonical form = **standalone-first** (= GUI standalone で wav export、 DAW 不要)
- plugin / DAW integration = **future optional**
- version 記録 = §Annex A-7 install version 列に literal 反映 (= `brew list --versions surge-xt` 出力)
- 確認: install 後 BD prototype patch 1 件で「合成 path が現実的か」 を hand-on 体感

**reference 機材設置 (= 越川氏個人 license、 PMDNEO 同梱しない、 §決定 4 個人 reference 用途許可):**
- AREX 2011 (= free VSTi、 Windows のみ、 越川氏判断で skip 可)
- SampleScience RX-11 HD (= 無料 / 個人 reference、 越川氏判断軸)

完了判定 (= 22nd session 反映、 sub-sprint α 完了で sub-sprint β = Surge XT 6 patch 設計に進む):
- ADR-0033 Draft update commit 完了 (= 22nd session 本 commit = §決定 20-24 + Annex A-5 / A-7 22nd session 反映 + migration roadmap 段階 1 sub-sprint α 22nd session 反映 + wording 規律 22nd session 反映 + sub-sprint α 詳細化)
- §Annex A-5 起源調査結果 literal 記録済 (= 中程度 forensic 8 段階 flow + 3 段階分類 + 起源 4 分類別判断 + engineering provenance note 表形式、 §決定 20 inventory-first 反映)
- §Annex A-7 install version 列 literal 反映済 (= Homebrew cask install 後の `brew list --versions surge-xt` 出力)
- scripts 4 系統雛形作成済 (= `forensic-drum-samples.sh` + `wav_to_adpcma.sh` + `build_drum_samples.sh` + `verify-drum-samples.sh` + Makefile target 4 件)
- Surge XT install 確認 (= Homebrew cask canonical)、 BD prototype 1 件 hand-on (= 越川氏 hand-on)
- handoff doc + memory + commit + push 完了

**23rd session 進捗 (= sub-sprint α 進行中、 段階 1 sub-sprint α 完了は本進捗 + Surge XT install 確認 + Makefile target 4 件追加で達成):**

| 完了判定項目 | 状況 | reference commit |
|---|---|---|
| ADR-0033 Draft update commit 完了 (= 22nd session) | ✓ 完了 | commit 617a139 (= 22nd session γ) |
| §Annex A-5 起源調査結果 literal 記録済 | ✓ 完了 | commit 326c88b (= 23rd session δ) |
| §Annex A-7 superctr/adpcm evidence 反映済 | ✓ 完了 (= encoder 採用 finalize、 8 finding + 4 採用条件クリア literal) | 23rd session ζ' (= 本 commit) |
| §Annex A-7 Surge XT install version 列 反映済 | ✓ 完了 (= surge-xt 1.3.4 / install 2026-05-16 13:01:59 / Apple Silicon arm64 literal、 brew quirk reference 追加) | 23rd session η (= 本 commit) |
| scripts 4 系統雛形作成済 | ✓ 完了 (= 4 件、 forensic は完成 / 他 3 件は interface fixation stub) | commit 326c88b (= forensic) + 23rd session ε (= wav_to_adpcma + build_drum_samples + verify-drum-samples) |
| Makefile target 4 件追加 | ✓ 完了 (= drum-sources / drum-build / drum-verify / drum-clean、 軸転換命名後) | 23rd session ζ |
| Surge XT install 確認 (= Homebrew cask canonical) | ✓ 完了 (= user step 1 完了報告、 23rd session 並走 work) | user hand-on (= 23rd session 中盤) |
| BD prototype 1 件 hand-on (= 「合成 path が現実的か」 体感) | ☐ pending (= sub-sprint β 着手時に実施) | sub-sprint β 着手時 user hand-on |
| handoff doc + memory + commit + push 完了 | 進行中 | session 末で実施予定 |

**23rd session 規律 (= interface fixation stub の意義):**

- source wav が project 内に **不在** (= §Annex A-5-5 finding 2 literal observed) な現実下で、 wav_to_adpcma / build_drum_samples / verify-drum-samples の中身実装を進めても dry-run できない (= input が仮なら設計が歪む)
- そのため 23rd session ε commit は **「4 系統 canonical pipeline の interface fixation」** のみを scope とし、 中身実装は **sub-sprint γ** (= source wav 完成 = sub-sprint β 完了後の OPNA pipeline 構築) に分離
- 4 系統境界 (= read-only inventory / one-file converter / orchestration / reproducibility gate) を script header の 9 項目 (= purpose / §決定 21 対応 / input / output / format / future phase / exit code / examples / TODO) で literal 化することで、 §決定 21 4 系統分離を **1 stub = 1 責務** で固定
- exit code 2 = not-implemented sentinel = source wav 完成前は middle 実装しない literal 規律 (= shell convention 整合、 CI 統合時に「pending」 として識別可能)
- forensic は read-only inventory なので 23rd session δ で **動作完成**、 残 3 件 (= wav_to_adpcma + build_drum_samples + verify-drum-samples) は **interface のみ完成 = source wav 完成後に本実装**

#### sub-sprint β: Surge XT BD 1 音先行 chain + 残 5 音横展開 (= depth-first scaling)

**進行流儀 (= 23rd session ζ' 末 user 壁打ち validated、 22nd session γ 起票時の旧流儀から置換):**
- **旧 (= 22nd session γ 起票時、 置換):** 「Surge XT で 6 種 patch 設計 + wav render」 = N 並列 aesthetic 試行 = 6 unit を同時並走で完成させる流儀
- **新 (= 23rd session ζ' 末、 採用):** 「BD 1 音先行 chain → 残 5 音横展開」 = depth-first scaling = 1 unit (= BD) で full pipeline (= patch / .fxp / wav / audition / adpcma / verify) を縦通し、 workflow canonical 化後に残 5 音に横展開

**根拠 (= memory `feedback_reproducible_workflow_first_aesthetic_second.md` literal、 ADR レベル固定):**
- workflow defect の N 並列発生は 1 件発生に対して fix cost N 倍以上 (= 同じ defect を N 箇所で再修正 + 既出力の re-render 必要)
- 1 unit (= BD) で workflow canonical 化 → 残り 5 unit (= SD / HH / TOM / TOP / RIM) は workflow に従うだけで「regulation 軸」 「aesthetic 軸」 が分離 = いずれも安定的に進められる
- **「reproducible workflow first, aesthetic refinement second」** = workflow 不安定段階の aesthetic 試行は workflow gap を aesthetic gap と誤認 risk
- 23rd session 4 layer 構造 (= policy → forensic → interface → public API) の「縦に通してから横に広げる」 原則の continuation
- contract exists / implementation pending 分離 (= [[interface-fixation-stub-pattern]]) と同型 = workflow canonical / aesthetic pending の 2 軸分離

**BD chain 6 step literal (= sub-sprint β 進行 canonical):**

| step | 名称 | 内容 | 担当 |
|---|---|---|---|
| 1 | **patch 設計** | Surge XT 内で BD patch hand-on 設計 = oscillator (= sine 50-80 Hz) + pitch envelope + amp envelope short attack + long decay (= 22nd session γ hint、 hand-on 探索で逸脱可) | 越川氏 hand-on |
| 2 | **`.fxp` 保存** | Surge XT patch file (`.fxp`) として保存 = canonical patch source、 命名 + 配置規約 sub-sprint β 内で確定 (= 候補 `assets/drum_samples/synth/patches/2608_bd.fxp`) | 越川氏 hand-on |
| 3 | **WAV render** | Surge XT standalone で §決定 8 仕様 (= 44100 Hz / mono / 16-bit / RIFF WAVE PCM) export、 normalize / silence trim 規約も sub-sprint β 内確定 | 越川氏 hand-on |
| 4 | **audition gate** | 聴感判定 (= 越川氏 hand-on 評価 + 設計 intent 整合)、 reference (= AREX 2011 / SampleScience RX-11 HD 個人 reference) との家族度メモ化 | 越川氏 hand-on |
| 5 | **ADPCM-A encode** | `scripts/wav_to_adpcma.sh` 経由 (= sub-sprint γ で中身実装、 sub-sprint β 内は暫定 = `~/src/superctr-adpcm/adpcm ae` direct invoke で代用可、 §Annex A-7 ζ' evidence 整合) | Claude / 越川氏 hand-on |
| 6 | **verify** | 出力 adpcma の sha256 manifest 記録 + 既存 driver build + MAME 再生確認 (= A 系統 audio gate、 ADR-0026-0031 invariant 整合) | Claude |

**BD chain 着手前確定 parameters (= 23rd session θ' 末 user 壁打ち validated literal、 ι commit 着手前の安全 boundary):**

| 軸 | literal 値 | 根拠 |
|---|---|---|
| 1. `.fxp` 保存 path | `assets/drum_samples/synth/patches/2608_bd.fxp` | §決定 23 directory = kit identity (`synth/`) + patches subdirectory で source 階層化 + §決定 7 命名 |
| 2. WAV render parameter | **no normalize** / 44100 Hz / mono / 16-bit / RIFF WAVE PCM | §決定 8 仕様整合 + **no normalize** = 初回 BD は「完成音」 より provenance chain 縦通し優先、 音量規約を後から変えられる余地保持 = reproducible workflow first 軸整合 ([[reproducible-workflow-first-aesthetic-second]] 連動) |
| 3. trim 規約 | **leading 0 ms** / **trailing 自然減衰後 +50-100 ms** | aesthetic を細かく固定せず、 chain 縦通しに最低限必要な silence 規約のみ literal 化 |
| 4. WAV 保存 path | `assets/drum_samples/synth/2608_bd.wav` | §決定 23 kit identity directory 直下、 §決定 7 命名 (= lowercase = source wav 軸) |
| 5. ADPCM-A encode 経路 | `~/src/superctr-adpcm/adpcm ae -a <input.pcm> <output.adpcma>` direct invoke | sub-sprint β 内は暫定 direct invoke、 `-a` **anti-overflow ON** (= §Annex A-7 ζ' 8 finding 2 推奨整合)、 `scripts/wav_to_adpcma.sh` 中身実装は sub-sprint γ |
| 6. ADPCM-A 保存 path | `assets/drum_samples/synth/encoded/2608_BD.adpcma` | **既存 `assets/sounds/adpcma/2608_BD.adpcma` (= unknown 起源 temporary fixture) は touched しない (= 並行配置 / 隔離維持)、 新 BD は self-authored asset chain として並存** (= upper case = §決定 7 既存 driver-embed 命名整合) |
| 7. 既存 fixture 扱い | **置換しない、 unknown-origin fixture として隔離維持** | §決定 11 (= 段階 3 完了まで暫定許容) 整合 + driver / fixture / runtime semantics 軸 ADR-0026-0032 完全不変維持 + 段階 3 完了時に literal 置換 (= §決定 12 整合) |
| 8. WAV → raw PCM 経路 | sox / python wave + struct 等で RIFF WAVE header strip + 18.5 kHz decimate (= §決定 9 chip 化 pipeline 整合) | sub-sprint β 内では暫定経路 (= sub-sprint γ wrapper で正式実装、 §Annex A-7 sub-sprint γ 継続項目「WAV header strip 経路選定」 連動) |

**重要 wording 規律 (= 23rd session θ' 末 user 補強):**
- **「no normalize」** = 初回 BD chain の音量規約 = aesthetic 確定前の安全規約 = 後から音量正規化規約を変えられる余地保持 ([[reproducible-workflow-first-aesthetic-second]] 「workflow canonical 後の aesthetic iteration」 整合)
- **「並行配置」 = existing fixture untouched + new self-authored asset coexists** = 段階 3 完全ホワイト化 milestone 前の安全 boundary = §決定 11 + §決定 12 段階的 migration 整合
- **ι commit scope = 新 BD chain を追加する / 既存 fixture は触らない** が canonical (= 23rd session θ' 末 user 明示)

**BD chain 完了判定 (= sub-sprint β BD 1 commit (= ι) 完了条件):**
- BD `.fxp` patch literal 保存 (= `assets/drum_samples/synth/patches/2608_bd.fxp`、 越川氏 100% 著作物 = §決定 1 整合)
- BD wav render 完了 (= `assets/drum_samples/synth/2608_bd.wav`、 §決定 8 + θ' parameter 軸 2-3 整合 = no normalize / leading 0 ms / trailing 自然減衰 +50-100 ms、 越川氏 audition gate ✓)
- BD adpcma encode 完了 (= `assets/drum_samples/synth/encoded/2608_BD.adpcma`、 `adpcm ae -a` direct invoke、 sha256 manifest 記録、 既存 `assets/sounds/adpcma/2608_BD.adpcma` (= unknown 起源 temporary fixture) との **並行配置 / 隔離維持** literal 確認 = 越川氏自前 sample の独立性証明 + driver 不変)
- **BD chain workflow regulation literal 化済** (= patch naming / 配置 / wav render parameter / trim 規約 / encode option / 並行配置軸 / verify gate を θ' で本 sub-sprint β section の「BD chain 着手前確定 parameters」 表に 8 軸 literal 反映済 = 残 5 音横展開で踏襲する規約)
- commit + push 完了 (= ι commit scope = `.fxp` + `.wav` + `.adpcma` 新規追加のみ、 既存 fixture は touched しない = 並行配置流儀)

**残 5 音横展開 (= BD 規約確定後):**
- 対象: SD / HH / TOM / TOP / RIM (= 5 drum、 BD と同 chain 6 step)
- 進行方法: BD で確定した workflow に **完全準拠** = workflow regulation 側を曲げない (= 曲げるなら BD に戻して workflow update + 既出力 re-render)
- 各音 aesthetic iteration は独立に可能 (= 互いに干渉しない)
- **commit 粒度 (= user 判断軸として 2-3 候補温存、 BD chain 完了時に sub-sprint β 内で再壁打ち軸として確認):**
  - (a) **5 音まとめて 1 commit** = aesthetic iteration の独立性が高い場合 (= 各音独立に hand-on 完成 → 一括反映)
  - (b) **1 音 1 commit** = 各音ごとに audition gate + verify を厳格に通す場合 (= 5 commit chain、 incremental axis expansion 流儀)
  - (c) **折衷** = workflow regulation gap が出る音 (= cymbal TOP の長 decay / SD noise + sine layer 等) は別 commit、 simple な音 (= TOM / RIM 等) はまとめる

**reference 比較 (= 各 unit audition gate で適用):**
- AREX 2011 / SampleScience RX-11 HD 個人 reference 環境で「目標音」 聴感確認 (= §決定 4 個人 reference 用途許可、 §決定 14 sound-alike caution 整合 = 文化的参照は OK、 sample literal copy は禁止)
- FFT spectrum + RMS envelope で家族度評価 (= 越川氏判断軸、 §決定 24 aesthetic 整合)

**各 drum patch 設計 starting hint (= 22nd session γ 時点の出発点、 hand-on 探索で逸脱可、 BD chain 完了時に確定 spec へ移行):**
- BD: sine wave (= 50-80 Hz) + pitch envelope + amp envelope short attack + long decay
- SD: noise + band-pass filter (= 200 Hz 中心) + 別 layer sine 100-200 Hz body
- TOP: noise + hi-pass filter (= 6 kHz 以上) + long decay (= 1-3 秒) + FM modulation
- HH: noise + hi-pass filter (= 7 kHz 以上) + very short decay (= 50-150 ms)
- TOM: BD と同構造で pitch 中音域 (= 100-300 Hz)
- RIM: short click + short body sine (= 800 Hz)

**完了判定 (= sub-sprint β 完了 = sub-sprint γ 着手可能):**
- 6 種 wav + .fxp + adpcma all 越川氏 100% 著作物確定 (= §決定 1)
- file 名 規律準拠 (= §決定 7 命名 `2608_{bd,sd,top,hh,tom,rim}`)
- workflow regulation literal 化 完了 (= ADR-0033 内 reference 反映済)
- reference との家族度評価 メモ化 (= 越川氏判断軸)
- commit + push 完了 (= BD chain + 残 5 音、 user 選択した粒度)

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

実施順序 (= §決定 20 literal、 22nd session 軸 10 反映):

- **inventory first** (= 観測可能事実先固定 → provenance 推定後追い、 22nd session 中核規律)
- **sha256 as canonical identity** (= 後の比較で reproducible、 本表に sha256 列必須)
- **provenance inference happens after inventory** (= 「何が存在しているか」 を fix した後で「それが何由来か」 を推定する 2 段階構造)
- **forensic result is engineering note, not legal certification** (= §決定 15 性格再強調、 PMDNEO 完全ホワイト化 narrative の証跡として残すが法的判断は段階 3 越川氏判断軸)

8 段階 flow (= §決定 20 literal):

1. **current wav inventory** (= `src/test-fixtures/` + `vendor/ngdevkit-examples/` 配下 rhythm 関連 wav 全列挙、 file path / file size を表化)
2. **sha256** (= canonical identity 固定、 表 sha256 列の primary value)
3. **sample rate / length / channel count** (= wav metadata、 表 metadata 列)
4. **file header** (= RIFF WAVE PCM header parse、 §決定 8 仕様準拠確認も兼ねる)
5. **current `samples.inc` 対応** (= `adpcma_sample_{bd,sd,cym,hh,tom,rim}` symbol と wav の対応関係表化、 driver-embedded 経路の透明性)
6. **vendor wav 対応** (= `vendor/PMDDotNET/` / `vendor/pmd48s/` / `vendor/ngdevkit-examples/` 配下 wav との関係、 vendor 内資産の起源候補抽出)
7. **4 分類推定** (= Yamaha mask ROM dump / community 配布物 / PMD culture / RX-11 sample pack のどれに likely / unknown するか、 起源 4 分類別判断連動)
8. **git history / external comparison は必要時のみ追加** (= forensic 中程度 = 7 軸内で完結、 8 軸目は escape hatch、 法的判断ではなく engineering note)

実施 scripts (= §決定 21 literal):
- `scripts/forensic-drum-samples.sh` (= read-only inventory、 上記 8 段階 flow 1-7 を mechanical に実行、 **23rd session 新規作成 ✓**)
- `make drum-sources` で起動 (= top-level Makefile target、 23rd session ζ 軸転換 = 「Makefile = 作業者向け入口」 literal 整備済 ✓、 直接 invocation `./scripts/forensic-drum-samples.sh` も等価)

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

**調査結果** (= 23rd session 反映、 段階 1 sub-sprint α 進行中、 `scripts/forensic-drum-samples.sh` 経由 mechanical 収集、 observed-facts-first / provenance inference second 規律):

#### A-5-1. inventory 表 (= 段階 1-4 = sha256 + size + wav meta + magic、 observed facts literal)

| drum | file | size (B) | sha256 (head 16) | wav meta / adpcma meta |
|---|---|---|---|---|
| BD  | `assets/sounds/adpcma/2608_BD-roundtrip.wav`   |  3144 | `e83798365d20da71` | wav: 18500 Hz mono 16 bit / 1550 frames / 83.8 ms (magic `52494646` = RIFF) |
| BD  | `assets/sounds/adpcma/2608_BD.adpcma`          |  1024 | `0dd42be876987e22` | adpcma: 2048 nibble / 110.7 ms @ 18500 Hz (magic `08080880`) |
| SD  | `assets/sounds/adpcma/2608_SD-roundtrip.wav`   |  2762 | `19758f0fcbd9cf79` | wav: 18500 Hz mono 16 bit / 1359 frames / 73.5 ms (magic `52494646`) |
| SD  | `assets/sounds/adpcma/2608_SD.adpcma`          |   768 | `d517d7083d404578` | adpcma: 1536 nibble / 83.0 ms @ 18500 Hz (magic `08080808`) |
| HH  | `assets/sounds/adpcma/2608_HH-roundtrip.wav`   |  2642 | `d2e8e603c75d4bf2` | wav: 18500 Hz mono 16 bit / 1299 frames / 70.2 ms (magic `52494646`) |
| HH  | `assets/sounds/adpcma/2608_HH.adpcma`          |   768 | `6f6353b918027614` | adpcma: 1536 nibble / 83.0 ms @ 18500 Hz (magic `6b02c4f3` = 他 5 件と異なる nibble pattern) |
| RIM | `assets/sounds/adpcma/2608_RIM-roundtrip.wav`  |  1202 | `f4653d8b70411768` | wav: 18500 Hz mono 16 bit / 579 frames / 31.3 ms (magic `52494646`) |
| RIM | `assets/sounds/adpcma/2608_RIM.adpcma`         |   512 | `952c9200c2c2f08f` | adpcma: 1024 nibble / 55.4 ms @ 18500 Hz (magic `08080808`) |
| TOM | `assets/sounds/adpcma/2608_TOM-roundtrip.wav`  |  5844 | `be9fad13e54eedbd` | wav: 18500 Hz mono 16 bit / 2900 frames / 156.8 ms (magic `52494646`) |
| TOM | `assets/sounds/adpcma/2608_TOM.adpcma`         |  1536 | `388f7b49435f6a53` | adpcma: 3072 nibble / 166.1 ms @ 18500 Hz (magic `08080808`) |
| TOP | `assets/sounds/adpcma/2608_TOP-roundtrip.wav`  | 24074 | `90a3e3afbedc88a9` | wav: 18500 Hz mono 16 bit / 12015 frames / 649.5 ms (magic `52494646`、 size 比 4-8x = cymbal sustain 長 literal) |
| TOP | `assets/sounds/adpcma/2608_TOP.adpcma`         |  6144 | `f1eb2b35b7f8b848` | adpcma: 12288 nibble / 664.2 ms @ 18500 Hz (magic `08080880`) |

12 file の sha256 = 全部 literal 異なる canonical identity (= 後続 verify で reproducible)。

#### A-5-2. driver source 対応 (= 段階 5、 `samples.inc` vs driver-embedded symbol)

`assets/samples.inc` は build-time generated (= `vromtool.py` 経由) で source-of-truth ではない。 driver source `src/driver/standalone_test.s` 内に `adpcma_sample_{bd,sd,hh,rim,tom,top}` label が literal 直接 embed されており、 ADR-0026〜0031 §決定 3 と整合する driver-embedded fixture 経路:

| PMD semantics | driver embed symbol | 対応 ADR | 該当 wav |
|---|---|---|---|
| BD  | `adpcma_sample_bd`  | ADR-0026 Step 12 | `2608_BD.adpcma`  |
| SD  | `adpcma_sample_sd`  | ADR-0027 Step 13 | `2608_SD.adpcma`  |
| HH  | `adpcma_sample_hh`  | ADR-0028 Step 14 | `2608_HH.adpcma`  |
| CYM | `adpcma_sample_top` | ADR-0029 Step 15 | `2608_TOP.adpcma` (= symbol reuse、 ADR-0029 「top」 = sample provenance 名 / 「CYM」 = PMD semantics 名 wording 分離) |
| TOM | `adpcma_sample_tom` | ADR-0030 Step 16 | `2608_TOM.adpcma` |
| RIM | `adpcma_sample_rim` | ADR-0031 Step 17 | `2608_RIM.adpcma` |

#### A-5-3. vendor wav 対応 (= 段階 6)

drum 軸に該当する vendor wav は **不在**。 `assets/sounds/adpcma/` 配下 12 file (= 6 wav + 6 adpcma) が唯一の現存 drum sample 集合:

- `vendor/PMDDotNET/*.wav` = PMDDotNET 動作確認 wav (= voice 検証等、 drum 軸 ✗)
- `vendor/PMDDotNET/voice-*/*.wav` = voice 検証 dataset (= TL/AR/DR/ML/ALG/FBL、 drum 軸 ✗)
- `vendor/ngdevkit-examples/06-sound-adpcma/assets/*.wav` = ngdevkit example sample (= lefthook / lightbulbbreaking / woosh、 drum 軸 ✗、 license clean 第三者著作物だが本 ADR 対象外)
- `data/blob/voice-*.wav` = Phase 0 voice 検証 wav (= drum 軸 ✗)

#### A-5-4. 3 段階分類 + 起源 4 分類別 assessment (= 段階 7、 engineering provenance note)

23rd session 時点での observed facts based assessment = **全 12 file 起源 unknown**:

| file | 3 段階分類 | 起源 4 分類 | engineering note (= 観察事実 literal) |
|---|---|---|---|
| `2608_BD-roundtrip.wav`  | unknown | unknown | 命名 `-roundtrip.wav` suffix = ADPCM-A → decode 経由の roundtrip output literal。 sample rate 18500 Hz = chip canonical rate であり §決定 8 source wav format (= 44100 Hz) **ではない** literal 観察。 source wav (= encoder input、 44100 Hz 想定) は project 内 **不在**。 |
| `2608_BD.adpcma`         | unknown | unknown | encoder 不明 / source wav 不明 / git 起源不明。 magic `08080880` |
| `2608_SD-roundtrip.wav`  | unknown | unknown | 同上 (= BD-roundtrip.wav と同 finding) |
| `2608_SD.adpcma`         | unknown | unknown | 同上、 magic `08080808` |
| `2608_HH-roundtrip.wav`  | unknown | unknown | 同上 |
| `2608_HH.adpcma`         | unknown | unknown | 同上、 magic `6b02c4f3` (= 他 5 件と異なる nibble pattern、 sample 起源差 likely literal) |
| `2608_RIM-roundtrip.wav` | unknown | unknown | 同上 |
| `2608_RIM.adpcma`        | unknown | unknown | 同上、 magic `08080808` |
| `2608_TOM-roundtrip.wav` | unknown | unknown | 同上 |
| `2608_TOM.adpcma`        | unknown | unknown | 同上、 magic `08080808` |
| `2608_TOP-roundtrip.wav` | unknown | unknown | 同上、 wav size 24074 B = 他 5 件比較 4-8x (= cymbal sustain 長 literal) |
| `2608_TOP.adpcma`        | unknown | unknown | 同上、 magic `08080880`、 6144 B = 他 5 件比較 4-8x |

12 file 全部 **unknown 起源** = 「現状の rhythm sample は engineering forensic 中程度では出所が特定不能、 段階 3 完了同時に越川氏 100% 著作物に置換必須」 と engineering note literal 記録。 §決定 11 (= 段階 3 完了まで暫定許容) + §決定 12 (= 段階 3 完了後越川氏自前以外排除契約) + 起源 4 分類別判断 分類 3「出所不明 community 配布物 → 段階 3 完了同時即時差替え必須」 と整合。

#### A-5-5. 重要 finding 5 件 (= 23rd session 観察事実、 engineering note literal)

1. **6 wav 全部が 18500 Hz mono 16-bit** = ADPCM-A chip canonical rate と一致、 §決定 8 source wav format (= 44100 Hz) **ではない**。 つまり「source wav (= 44100 Hz) → encoder → adpcma → decode → roundtrip.wav (= 18500 Hz)」 経路の最終段の roundtrip output。 命名 `-roundtrip.wav` suffix が示す通り。
2. **source wav (= 44100 Hz encoder input) は project 内不在**。 段階 1 sub-sprint β = Surge XT prototype で 6 種「越川氏自前合成 source wav」 を新規 create することが、 まさに段階 3 完全ホワイト化 milestone への entry point。
3. **adpcma 6 件は全部別 sha256 + 別 size** = 別 drum literal 識別可能 (= ADR-0026〜0031 dispatch path proof と整合、 runtime semantics 軸 invariant と provenance 軸 unknown が独立して並存)。 HH の magic `6b02c4f3` が他 5 件 (= `0808xxxx`) と異なる = HH 単独で nibble pattern 起源差 likely literal observed。
4. **driver source 内 `adpcma_sample_*` symbol 6 件** が `src/driver/standalone_test.s` 内に literal 直接 embed (= ADR-0026〜0031 §決定 3 整合、 driver-embedded fixture 経路)。 `samples.inc` は build-time generated で source-of-truth ではなく派生物。
5. **drum 軸 vendor wav 不在** = `assets/sounds/adpcma/` 配下 12 file のみが現存 drum sample 集合。 `vendor/PMDDotNET/` / `vendor/ngdevkit-examples/` / `data/blob/` 配下 wav は voice 検証 / ngdevkit example で drum 軸対象外 (= not-applicable 分類)。 つまり段階 3 完全ホワイト化 milestone で置換対象は本 12 file 限定。

#### A-5-6. 結論 + 段階 3 移行判断

23rd session forensic 結果 = **12 file 全部 unknown 起源 + source wav 不在 (= 18500 Hz roundtrip wav のみ存在) + driver-embedded symbol 6 件**。

判断:

- §決定 11「段階 3 完了まで暫定許容」 維持 (= driver / fixture / verify script / runtime semantics 軸 ADR-0026-0032 への影響なし)
- 段階 1 sub-sprint β = Surge XT prototype で 6 種「越川氏自前合成 source wav (= 44100 Hz)」 を新規 create + sub-sprint γ で OPNA pipeline (= 18.5 kHz decimate + 4-bit ADPCM-A 圧縮) 経由 adpcma 化 + samples.inc 反映、 段階 3 完了時に literal 置換
- 起源 4 分類別判断 = 全 12 file 「分類 3: 出所不明 community 配布物」 相当扱い (= 段階 3 完了同時即時差替え必須、 §決定 11 連動)
- forensic は engineering provenance note としてここで一旦完了 (= sub-sprint α 後埋め完了)、 段階 8 git history / external comparison は **escape hatch** = 必要時別途実行 (= 中程度 forensic 7 軸内で完結、 §決定 15 性格再強調)

`scripts/forensic-drum-samples.sh` は reproducibility gate (= future contributor が同 inventory 結果を再現可能) として canonical 維持、 §決定 21 4 系統 1 件目 = read-only inventory 役割 fix。

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

**scripts canonical pipeline 構成 (= §決定 21 literal、 22nd session 軸 11 反映 = 4 系統分離):**

| script | 役割境界 | 入力 | 出力 | Makefile target |
|---|---|---|---|---|
| `scripts/forensic-drum-samples.sh` | **read-only inventory** | 既存 wav 資産 | inventory report (= `forensic-report.md` / `forensic-inventory.yaml` 等、 実装時確定) | `make forensic-drum-samples` |
| `scripts/wav_to_adpcma.sh` | **one-file converter** | wav 1 file (= 44100 Hz / 16 bit / mono、 §決定 8 仕様) | ADPCM-A binary 1 file (= 18.5 kHz / 4-bit) | `make wav-to-adpcma` |
| `scripts/build_drum_samples.sh` | **orchestration** | 6 wav (= synth or acoustic kit、 §決定 23 naming) | 6 ADPCM-A binary + `samples.inc` (= ADR-0019 build-time embed 整合) | `make build-drum-samples` |
| `scripts/verify-drum-samples.sh` | **reproducibility gate** | 生成済 6 ADPCM-A binary + `samples.inc` | sha256 / length / channel count / sample rate / output binary size / optional spectral fingerprint 検証 report | `make verify-drum-samples` |

役割境界 literal:
- forensic = **read-only inventory** (= 既存資産の調査専用、 wav も binary も生成しない、 forward build pipeline と独立)
- wav_to_adpcma = **one-file converter** (= 1 wav 入力 1 ADPCM-A binary 出力、 batch ではない、 純粋な変換責務)
- build_drum_samples = **orchestration** (= 6 drum batch + `samples.inc` 統合、 既存 PMDNEO build pipeline と整合)
- verify-drum-samples = **reproducibility gate** (= 生成物 deterministic 検証、 build pipeline 後段)

WebApp converter (= future UI、 §決定 17 連動): scripts 仕様に追随する future UI、 重複ロジック設定しない、 source of truth は scripts canonical。

**Surge XT install 環境 (= §決定 22 literal、 22nd session 軸 12 反映 = Homebrew cask canonical):**

| 項目 | 仕様 |
|---|---|
| install 経路 | `brew install --cask surge-xt` (= macOS canonical) |
| canonical form | standalone app (= GUI standalone で wav export、 DAW 不要) |
| plugin / DAW integration | future optional (= 必要なら別 ADR or 別 sub-sprint) |
| install version 記録 | **✓ 完了 (= 23rd session η commit、 user hand-on 取得)** |
| version literal | **`surge-xt 1.3.4`** (= `brew list --cask --versions surge-xt` 出力) |
| install date | **2026-05-16 13:01:59 JST** (= `brew info --cask surge-xt` "Installed" 行 literal) |
| install path | `/opt/homebrew/Caskroom/surge-xt/1.3.4` (= Apple Silicon prefix literal) |
| install size | 419.8 MB |
| architecture | Apple Silicon (= macOS arm64、 `/opt/homebrew/` prefix が示す Apple Silicon 用 Homebrew install) |
| official upstream | `https://surge-synthesizer.github.io/` |
| cask source | `https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/s/surge-xt.rb` |
| cask description | Hybrid synthesiser (= cask metadata literal) |
| reproducibility 評価 | 1 command で同 version install 可能 (= future contributor / fork 派生も `brew install --cask surge-xt` で再現、 ただし version は brew cask side で更新される可能性あり、 strict reproducibility 必要なら `--version` pin 検討) |
| brew lookup quirk reference | `brew list --versions <name>` は formula 検索 default で cask 不在 → exit 1。 cask version 取得は `brew list --cask --versions <name>` を使用 (= future contributor 向け notation) |

「環境構築も provenance の一部」 として扱う観点で、 install version を §Annex A-7 に literal 記録する。

**superctr/adpcm 23rd session ζ' evidence collection (= 段階 1 sub-sprint α 着手時 hand-on 取得、 §決定 18 採用候補確認):**

| 項目 | 値 |
|---|---|
| repository URL | `https://github.com/superctr/adpcm` |
| clone path (= 23rd session ζ' local) | `~/src/superctr-adpcm/` |
| git rev-parse HEAD | `e431c94bd7ee88287b0629cd9f1d0a0d163c3642` |
| latest commit date | 2025-12-15 |
| latest commit subject | Merge pull request #7 from ValleyBell/yma-overflow-fix |
| git tag | (= 不在、 latest HEAD が canonical) |
| **license** | **Public Domain (= Unlicense literal、 LICENSE file 1 行目「This is free and unencumbered software released into the public domain.」)** |
| copyright | Ian Karlsson 2019 (= readme.md 末尾) / "ctr" 2018-2022 (= adpcm 起動時 usage literal) |
| build 確認 | ✓ Apple clang 17.0.0 arm64-apple-darwin25.3.0 / `make` 1 発 / binary 35176 bytes / warning 2 件 (= 非 critical format specifier、 program 動作影響なし) |
| binary path | `~/src/superctr-adpcm/adpcm` |
| dependencies | stdlib のみ (= 6 .c file + Makefile 1 行、 vendor 同梱容易) |

ADPCM-A 関連 command (= readme.md literal、 PMDNEO 使用予定):
- `adpcm ae <input.pcm> <output.adpcma>` = Yamaha ADPCM-A (YM2610) Encode (= sub-sprint γ wav_to_adpcma.sh 内部 invoke)
- `adpcm ad <input.adpcma> <output.pcm>` = Yamaha ADPCM-A (YM2610) Decode (= verify roundtrip 用途)
- `-a` option = anti-overflow mode (= Yamaha ADPCM-A encoding 専用、 sub-sprint γ wrapper で default ON 候補)

input format 仕様 (= adpcm 起動時 usage literal):
- "Input format: signed 16 bit PCM little endian"
- §決定 8 source wav (= RIFF WAVE PCM / 1 ch / 44100 Hz / 16 bit) との整合 = **RIFF WAVE header strip 必要** = `scripts/wav_to_adpcma.sh` wrapper で sox / ffmpeg / python wave + struct 等で WAV → raw 16-bit PCM little-endian 経路追加 (= sub-sprint γ wrapper 実装時に経路選定壁打ち軸)
- 補足: §決定 9 chip 化 pipeline は 18.5 kHz decimate 経路を含むので、 wrapper 内部 stage は「44100 Hz wav → decimate → 18500 Hz raw PCM → adpcm ae → adpcma」

23rd session ζ' 観察 8 finding (= engineering note literal):
1. **YM2610 ADPCM-A 専用 encode `ae` command 存在** = §決定 18 採用候補の決定的根拠 (= 自前実装回避の明示的代替)
2. **`-a` anti-overflow option** = ADPCM-A encoding 専用、 sub-sprint γ wrapper で default ON 推奨候補 (= ValleyBell yma-overflow-fix 連動)
3. **input format = signed 16-bit PCM little-endian** = §決定 8 整合、 ただし WAV header strip 経路を wrapper に追加必要
4. **build = `make` 1 発で binary 生成** = reproducibility 容易 (= Apple clang 17.0.0 arm64 = Apple Silicon macOS literal、 future contributor 環境差で gcc / clang 違いの吸収余地あり)
5. **license = Public Domain (= Unlicense literal)** = encoder provenance 完全 clean、 §決定 18 整合 + §決定 12 「越川氏自前以外排除契約」 と矛盾なし (= sample provenance ≠ encoder provenance literal 区別、 §決定 12 排除契約は同梱 sample 軸限定)
6. **dependencies = stdlib のみ** = vendor 同梱 / 外部依存どちらでも整合容易、 §決定 18 wrapper の薄さを保つ
7. **recent maintenance** = 2025-12-15 ValleyBell PR merge = community 信頼性 signal (= ValleyBell = 著名 emulator 開発者、 yma-overflow-fix の追加で ADPCM-A 精度補強)
8. **7 種 ADPCM variant 対応** (= ADPCM-A / ADPCM-B / AICA / OKI VOX / BSMT2000/QSound / X68000 / YMZ280B) = 将来 ADPCM-B (= `.PPC` / `.P86`) sub-system 拡張時に同 binary 流用可能 (= ADR-0033 ADPCM-A scope 軸外だが reference 価値、 PMDNEO ADPCM-B subsystem future 着手時の再利用候補)

**採用判定:** §決定 18 採用条件 (= license 整合 / 動作確認 / maintenance / build 容易) **全 4 件クリア = 23rd session ζ' で encoder 採用 finalize ✓**

**(= 段階 1 sub-sprint γ で詳細 wrapper 実装 + vendor 同梱 vs 外部依存判断 + ADPCM-A bit-accuracy 検証 + Surge XT source wav からの round-trip 検証で本 §Annex A-7 を再度 update commit で literal 反映、 Surge XT install version 列 (= 上記 1638 行 後埋め枠) は 23rd session η commit (= 別軸、 user hand-on 完了後) で後埋め)**

検討候補 (= 21st session 時点提示、 23rd session ζ' で採用 finalize):
1. `github.com/superctr/adpcm` (= **採用 finalize、 23rd session ζ' evidence collection 完了 ✓、 上記表 + 8 finding literal 反映済**)
2. `github.com/freem/adpcma` (= 不採用、 Neo-Geo ADPCM-A sample encoder、 ただし作者推奨は superctr/adpcm、 23rd session ζ' で再評価 skip)
3. 自前実装 (= 不採用、 §決定 18 literal scope-out、 CLAUDE.md §スコープ外 規律 + 3 行重複より早すぎる抽象化を避ける)

23rd session ζ' で確認済 (= ✓ 採用条件クリア、 8 finding literal 整合):
- license 整合 = **Public Domain (= Unlicense)、 PMDNEO GPL-3.0 narrative と完全独立、 §決定 18 整合** ✓
- 動作確認 = `make` build 成功 + usage 確認 + ADPCM-A encode `ae` command 存在 ✓
- maintenance 状況 = 2025-12-15 ValleyBell yma-overflow-fix PR merge active ✓
- ADPCM-A 精度 = readme.md "Yamaha ADPCM-A (YM2610)" 明示 + ValleyBell yma-overflow-fix で精度補強 ✓

段階 1 sub-sprint γ で確認する項目 (= 23rd session ζ' では確認できない / 詳細 wrapper 実装時の継続項目):
- 任意 wav → samples.inc 形式 end-to-end 動作 (= wrapper 実装 + WAV header strip 経路 + 結果 binary 検証)
- PMDNEO build pipeline 統合容易性 (= 既存 vromtool.py / ADR-0019 sample addr build-time embed 経路との整合)
- vendor 同梱 vs 外部依存判断 (= 3 案壁打ち = (a) 外部依存 default / (b) vendor 同梱 / (c) 折衷、 §決定 18 wrapper 流儀整合)
- ADPCM-A bit-accuracy 検証 (= 既存 6 adpcma との比較は scope-out = unknown 起源、 sub-sprint β で生成する Surge XT source wav から chain encode + decode で round-trip 検証)
- `-a` anti-overflow option default 判断 (= ADPCM-A encoding 時 ON / OFF 判断、 wrapper の default literal 化)
- WAV header strip 経路選定 (= sox / ffmpeg / python wave + struct 等の選定軸、 §決定 9 decimate と組み合わせ)

`scripts/wav_to_adpcma.sh` wrapper 仕様 (= §決定 18 literal):
- 入力: 44100 Hz / 16 bit / mono wav (= §決定 8 仕様)
- 処理 1: 18.5 kHz decimate (= sox / ffmpeg / scipy.signal.decimate 等)
- 処理 2: superctr/adpcm CLI 呼出し (= 4-bit ADPCM-A 圧縮)
- 処理 3: `samples.inc` 形式 Z80 assembly 出力 (= ADR-0019 §決定 3 build-time embed 流儀踏襲、 既存 PMDNEO build pipeline 整合)
- default parameter: mono / 18.5 kHz / 4-bit ADPCM-A / `2608_{bd,sd,top,hh,tom,rim}.wav` naming convention

採用結果 + 根拠の literal 反映状況:
- **23rd session ζ' = encoder evidence collection 完了 ✓** (= 上記 superctr/adpcm 表 + 8 finding + 4 採用条件クリア literal 反映済)
- **sub-sprint γ で継続項目 = 詳細 wrapper 実装 + vendor 同梱 vs 外部依存判断 + ADPCM-A bit-accuracy 検証 + Surge XT source wav からの round-trip 検証** (= sub-sprint γ 完了時に再度 update commit で literal 反映)
- **Surge XT install version 列 (= 1638 行 後埋め枠) = 23rd session η commit で後埋め** (= 別軸、 user hand-on Surge XT install 完了報告後)

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

22nd session 追加推奨 wording (= §決定 20 forensic 実施順序 + §決定 21 scripts canonical 4 系統 + §決定 22 Surge XT install + §決定 23 render naming + §決定 24 aesthetic):

forensic / inventory 軸 (= §決定 20 連動):
- 「inventory first」 (= 22nd session 中核規律、 観測可能事実先固定)
- 「sha256 as canonical identity」 (= forensic 比較の primary identity)
- 「observed facts first, provenance inference second」 (= §決定 20 中核 wording、 2 段階構造)
- 「engineering provenance note, not legal certification」 (= §決定 15 性格 reaffirm、 §決定 20 連動)

scripts canonical pipeline 軸 (= §決定 21 連動):
- 「read-only inventory」 (= forensic-drum-samples.sh 役割境界)
- 「one-file converter」 (= wav_to_adpcma.sh 役割境界)
- 「orchestration」 (= build_drum_samples.sh 役割境界)
- 「reproducibility gate」 (= verify-drum-samples.sh 役割境界)
- 「4 系統分離」 (= scripts 粒度方針 literal)

Surge XT install 軸 (= §決定 22 連動):
- 「Homebrew cask canonical」 (= macOS install 経路 literal)
- 「standalone-first」 (= plugin / DAW 不要、 GUI standalone で wav export)
- 「環境構築も provenance の一部」 (= reproducibility 拘張)

prototype render naming 軸 (= §決定 23 連動):
- 「filename = drum identity」 (= §決定 7 公式命名維持)
- 「directory = kit identity」 (= synth / acoustic / future kit)
- 「parallel kit families」 (= synth / acoustic 並存表現、 一方が他方を obsolete 化しない)
- 「filename keeps PMD culture compatibility」 (= PMD ecosystem 全体と命名互換)
- 「directory expresses kit provenance」 (= kit identity を directory レベルで表現)
- 「synthetic-only release remains valid」 (= §決定 19 整合)
- 「acoustic is not automatically canonical」 (= §決定 23 中核 wording)

synthetic drum identity aesthetic 軸 (= §決定 24 連動):
- 「synth kit first-class identity」 (= 22nd session narrative 核心、 placeholder ではなく正式 PMDNEO drum family)
- 「OPNA-era digital drum identity」 (= 80s YM2608 / ADPCM-A 時代の aesthetic 継承表現)
- 「ADPCM-A friendly drum design」 (= 18.5 kHz / 4-bit ADPCM-A 圧縮で degrade しない設計)
- 「transient-focused drum design」 (= attack 強調 + 4-bit ADPCM-A 親和)
- 「PMD rhythm family compatible」 (= 既存 wording 表記揺れ統一)
- 「retro digital aesthetic over realism」 (= acoustic realism は段階 2 役割と分離)
- 5 aesthetic target wording:
  - 「short decay」
  - 「bright transient」
  - 「compressed body」
  - 「retro digital texture」
  - 「ADPCM-friendly frequency balance」

22nd session 中核 narrative wording (= 段階 1 synth kit narrative literal 拘束):
- 「RX-11 を再現する」 のではなく「YM2608 / ADPCM-A 時代の aesthetic を継承する」 (= sound-alike caution 中核表現、 §決定 24 連動)
- 「段階 1 synth kit は placeholder ではなく正式な PMDNEO drum family」
- 「acoustic kit が future に来ても、 synth kit は obsolete ではなく parallel family」
- 「synthetic-only release は valid な PMDNEO release form」

22nd session 禁止 wording (= §決定 16 reaffirm + 22nd session 強化):
- 「RX-11 clone」
- 「ROM recreation」
- 「exact reproduction」
- 「mimic」
- 「acoustic-leaning synthetic」 (= 22nd session 新規禁止、 §決定 24 不採用案 (c) 文化、 段階 1 / 段階 2 役割分離 §決定 19 と不整合)
- 「placeholder kit」 / 「temporary synth kit」 (= 22nd session 新規禁止、 §決定 24 「first-class identity」 narrative 破壊)

ADR-0033 の literal narrative はこの wording 規律に貫徹する。 future commit / fork 派生作品でも継承義務 (= §決定 13 license 連鎖継承明示と整合)。
