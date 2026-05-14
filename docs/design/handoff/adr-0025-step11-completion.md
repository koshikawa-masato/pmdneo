# ADR-0025 step 11 δ completion handoff: multi-table id=0x01 proof sprint 完了統合

- 関連 ADR: [ADR-0025](../../adr/0025-pmdneo-step11-multi-table-id-0x01-proof.md) **Accepted** (= 2026-05-14 12th session δ 完了統合で移行)
- sub-sprint: δ (= 4 sub-sprint chain の 4 段目 = 最終、 完了統合 + Accepted 移行)
- commit: 本 commit
- 前段: γ commit `12b7b89` (= verify-step11-multi-table.sh 新設 + differential proof literal assert)
- 次段: Step 12 候補 (= 本 ADR §次 sprint 候補参照、 user β handoff で K/R rhythm compatibility を Step 12 候補として温存と整理)

## Step 11 sprint の本質 (= Accepted 後の literal 固定)

**Step 11 は selection differentiation proof であり、 generated directory / table-of-tables / cache / runtime parser は未実装**。 future contributor が「multi-table architecture 完成」 と誤解せず、 「proof-of-selection stage」 として扱えるよう本 handoff で literal 明記する (= user δ handoff 記載要件)。

具体的に達成したこと:

| 項目 | 内容 |
|---|---|
| `sample_table_id` が **selection key として機能** | 単なる gate (= 0x00 accept / 他 silent) → 2 値 selection (= 0x00 → table A / 0x01 → table B / 他 → sentinel) |
| **L ch addr regs differ literal proof** | step5 = BD literal `0x00/0x00/0x03/0x00` vs step5b = SD literal `0x04/0x00/0x06/0x00` (= LSB reg で 2 件 differ + MSB は偶然同値) |
| **M-Q ch addr regs identical** (= 副作用なし) | 20 reg × ch 1-5 で 0 件 differ (= id 切替で意図しない ch まで影響しない literal 証明) |
| **keyon count identical** (= silent ではない、 別 sample) | step5 / step5b 共に keyon trigger count = 41 (= mismatch silent path 2 と区別、 「同じ回数鳴る + 別 sample」 literal 証明) |

具体的に達成していないこと (= future scope):

| 項目 | scope-out 維持理由 |
|---|---|
| selected pointer runtime state cache (= A2/A3) | sample_table_id 再生中不変、 per-keyon resolve は構造的に冗長だが実害小、 動的化局面で再検討 (= memory `project_pmdneo_step11_a2_deferred` 整合) |
| 3 table 以上の multi-table | explicit if/jr は 2 table 用 proof 構造、 N table 化は table-of-tables refactor が必要 |
| generated directory (= D3 migration) | hand-written D1 が source-of-truth、 D3 migration は asset pipeline 軸の別 sprint |
| `.PNE` binary runtime parser | directory も sample data も build-time embed、 runtime parse は dynamic asset 段階 |
| multi-`.PNE` switching / bank switching / dynamic reload | 楽曲交換 ROM rebuild 不要化は別 sprint 群 |
| mismatch silent flag micro-sprint | sentinel pointer `0x0000` ベース継続、 flag 化は future hook 性が強く CLAUDE.md「仮想の将来要件のために抽象化しない」 注意 |
| K/R rhythm compatibility 現役接続 | rhythm 系の独立 sub-system、 user 12th session で **Step 12 候補として温存** と整理 |
| `adpcma_keyon_simple` 全体 refactor / `adpcma_ch_sample_ptr_table` rename | ADR-0019 / ADR-0024 §scope-out 維持 |
| 新規 sample 追加 / WAV import | WebApp Phase 4 領域、 Step 11 では既存 VROM 内 sample 再利用 (= 未追跡 wav 3 件は scope-out 維持) |

## sub-sprint chain 完了結果

### 5 commit chain (= ADR + α/β/γ/δ)

| sub | commit | 一文要約 |
|---|---|---|
| ADR | `bc60663` | ADR-0025 起票 Draft、 12th session 冒頭壁打ち 5 axes 確定 + §決定 8 件 + sub-sprint 分割 + scope-out 18 項目明示 + 「本質再確認」 callout |
| α | `ead638f` | data placement only (= table B + entry 1 + EQU + step5b MML fixture)、 driver routine 0 改修 + ADR §決定 8 revised split 改定 |
| β | `a02a696` | selector accept rule 拡張 (= id=0x01 → table B、 explicit if/jr + EQU 上限判定、 ABI 完全保存) |
| γ | `12b7b89` | verify-step11-multi-table.sh 新設 (= 7 gate differential proof + literal value assert)、 step5b MML CRLF 変換 fix |
| δ | 本 commit | 完了統合 + ADR-0025 Accepted 移行 + 全 14 script regression PASS + audible 試聴 + memory + MEMORY.md update |

### 「動いているものを壊さない」 規律遵守 (= ADR-0021-0024 で確立)

各 sub-sprint で driver source 改修を最小化し、 trivial verify (= 既存 path で false PASS) を段階分離で防いだ。

- α: data area 追加 41 行、 routine 0 改修 (= 完全 dead/unused state)
- β: selector 1 routine のみ拡張、 ABI / 他 routine / data 完全不変
- γ: driver source 完全不変 (= verify infrastructure 新設のみ)
- δ: driver source 完全不変 (= regression + Accepted 移行のみ)

各段階の primary gate が trivial verify を弾く設計 (= memory `feedback_trivial_verify_detection_and_correction_commit` 整合):
- α gate = 「step5.PNE register write trace byte-identical + 新 symbol 存在 + routine 不変」
- β gate = 「selector .lst で 4 label 確認 + step5 regression PASS」
- γ gate = 「L differ literal + M-Q identical + keyon count identical の 3 観点同時 + literal value assert」
- δ gate = 「全 14 script regression PASS + user 試聴 OK」

## 全 14 script regression 結果 (= δ で serial 実行)

| step | script | 結果 |
|---|---|---|
| 5 | verify-l-part-alpha-trace-gate.sh | PASS |
| 5 | verify-l-part-beta-sample-lookup.sh | PASS |
| 5 | verify-l-part-delta-volume-pan.sh | PASS |
| 5 | verify-l-q-tutti-gamma.sh | PASS |
| 5 | verify-l-q-rhythm-song-integration.sh | PASS |
| 6 | verify-silent-bcef-audio-isolation.sh | PASS |
| 7 | verify-step7-b1-roundtrip.sh | PASS |
| 7 | verify-step7-b3-byte-identical.sh | PASS |
| 7 | verify-step7-delta-mn-filename-embed.sh | PASS |
| 7 | verify-step7-delta-fix-quote-strip.sh | PASS |
| 8 | verify-step8-filename-observation.sh | PASS |
| 9 | verify-step9-resolver.sh | PASS (= 新 entry 1 含む state で gate 4-5 が terminator hit 経由で正しく 0xFD32=0xFF) |
| 10 | verify-step10-mismatch-silent.sh | PASS (= match keyon 41 / mismatch silent 2 / diff 39 + sample setup 156→0、 Step 10 baseline 維持) |
| 11 | verify-step11-multi-table.sh | PASS (= 7 gate、 selection differentiation observable literal proof) |

→ **全 14 script / 約 63 gate PASS**。 silent-bcef.wav / step5.wav / step5b.wav は user 試聴用に `/tmp/pmdneo-step10/` および `/tmp/pmdneo-step11/` に保存。

## user 試聴用 wav (= audible regression なし + selection differentiation audible)

| wav | 出所 | 内容 |
|---|---|---|
| `/tmp/pmdneo-step10/silent-bcef.wav` | step 6 verify | FM A/C/D/E ch isolated、 silent-bcef fixture (= audible regression なし最終確認) |
| `/tmp/pmdneo-step10/match.wav` | step 10 verify | step5.PNE match path、 FM + ADPCM-A drums (= BD audible) |
| `/tmp/pmdneo-step10/mismatch.wav` | step 10 verify | step5.PNE ROM patch mismatch、 FM only (= ADPCM-A silent、 Step 10 mismatch silent path) |
| `/tmp/pmdneo-step11/step5.wav` | step 11 γ verify | step5.PNE → table A → L ch BD audible (= Step 11 baseline) |
| `/tmp/pmdneo-step11/step5b.wav` | step 11 γ verify | step5b.PNE → table B → L ch SD audible (= Step 11 selection differentiation proof、 BD と区別可能、 silent ではない) |

`step5.wav` と `step5b.wav` を聴き比べることで L ch の sample 差分が ear gate でも確認可能。 BD (= bass drum) と SD (= snare drum) は明確に区別される音色のため、 audio domain で selection differentiation が成立した literal 証跡となる。

## 12th session 全体まとめ

### 12th session 流れ

1. **冒頭壁打ち**: A2 cache scope-out 判断 (= memory `project_pmdneo_step11_a2_deferred`) → Step 11 = multi-table id=0x01 proof sprint 採用 (= memory `project_pmdneo_step11_direction_multi_table`) → 5 axes 全 user 主導確定
2. **ADR commit** (= `bc60663`): ADR-0025 Draft 起票、 8 決定 + sub-sprint 分割 + scope-out 18 項目明示
3. **α commit** (= `ead638f`): data placement only、 user 指示で revised split (= 旧 α/β を新 α に合流、 ADR commit と α 分離)
4. **β commit** (= `a02a696`): selector accept rule 拡張、 ABI 完全保存
5. **γ commit** (= `12b7b89`): differential proof literal assert、 3 件 finding 記録 (= step5b CRLF / BD-SD MSB 偶然同値 / bash 3.2 compat)
6. **δ commit** (= 本 commit): 完了統合 + Accepted 移行 + 全 14 script regression + 5 wav 保存

### Step 9 → Step 10 → Step 11 contract chain (= identity → selection → differentiation 段階)

| Step | contract 達成 | runtime state | playback への効果 |
|---|---|---|---|
| 9 | filename → `sample_table_id` resolve (= identity resolution) | 0xFD32 = 0x00 / 0xFF (= match / mismatch) | 不影響 (= ADR-0023 §決定 11 で literal 固定) |
| 10 | `sample_table_id` → playback selection consumption (= identity consumed) | 0xFD32 = 0x00 (= accept) / その他 (= silent) | match = 既存 table A 引き / 他 = sentinel silent (= 2-C accept rule) |
| 11 | `sample_table_id` で複数 table から 1 つを selection (= selection differentiation observable) | 0xFD32 = 0x00 (= table A) / 0x01 (= table B) / 他 (= sentinel) | 0x00 = L ch BD / 0x01 = L ch SD / 他 = silent (= multi-table proof) |

### 12th session 学び (= 後続 sprint 向け教訓)

- **「再生中不変な runtime state は cache 化しない」** (= memory `project_pmdneo_step11_a2_deferred`) を判断軸として future sprint で再利用
- **revised sub-sprint split** (= ADR commit と α 実装を分離、 旧 α/β を新 α に合流) が複数軸 sprint で読みやすい
- **既存 resolver の terminator driven 性質** を活かせば α で resolver code 改修なしで entry 拡張可能 (= 既存設計の自然な柔軟性)
- **BD/SD MSB 偶然同値 finding** で「literal value assert は全 reg で必要、 differ 要件は条件付き」 と verify gate 設計の知見更新
- **PMDDotNET MML 必須 CRLF** は fixture 新規作成時に必ず確認すべき (= memory `feedback_pmddotnet_mml_authoring_rules` 整合、 LF 起票は γ で初顕在化)
- **macOS /bin/bash 3.2 compat** は verify script 共通要件 (= `declare -A` 不可、 case 文で代替)

## 次 sprint 候補 (= Step 12 候補)

user 12th session で K/R rhythm compatibility を Step 12 候補として温存と整理した。 本 ADR §scope-out のうち未消化 + future sprint で扱う候補:

1. **K/R rhythm compatibility 現役接続** (= ADR-0016 §決定 2 micro-sprint、 rhythm 系独立 sub-system、 user 推奨温存)
2. **mismatch silent flag micro-sprint** (= 別 runtime state で silent 化指示、 future hook 性、 CLAUDE.md「仮想の将来要件のために抽象化しない」 注意)
3. **D1 → D3 generated directory migration** (= asset pipeline 軸、 hand-written → generated)
4. **3 table 以上の multi-table** (= table-of-tables refactor が必要な段階)
5. **selected pointer runtime state cache** (= A2 / A3、 動的化局面で再検討)
6. **`.PNE` runtime parser** (= directory / sample entry / addr table 動的読込)
7. **multi-`.PNE` switching** (= 楽曲ごと別 `.PNE` 切替)
8. **bank switching / dynamic reload** (= 動的 asset 管理)
9. **overflow / edge-case hardening** (= 防御系)
10. **PMDNEO.s + nullsound integration** (= 大規模 sprint)
11. **WebApp Phase 4 領域 (= WAV import / 新規 sample 追加 UI)**

Step 11 完了で「identity resolution → playback selection → multi-table differentiation」 chain が成立、 Phase 3 driver (= ADPCM-A 6ch) の機能カバレッジは selection 軸まで完成。 future sprint は (1) dynamic asset 軸 (2) rhythm sub-system 軸 (3) WebApp 軸 のいずれかへの展開。

## 関連 memory

- `project_pmdneo_step10_complete.md` (= Step 10 完了、 identity → selection consumption)
- `project_pmdneo_step11_a2_deferred.md` (= 12th session 冒頭、 A2 cache scope-out 判断)
- `project_pmdneo_step11_direction_multi_table.md` (= 12th session、 multi-table id=0x01 proof sprint 採用)
- `project_pmdneo_step9_complete.md` (= step 9 完了、 0xFD32 identity resolver)
- `project_pmdneo_step8_complete.md` (= step 8 完了、 runtime filename observation)
- `project_pmdneo_step7_complete.md` (= step 7 完了、 `.PNE` asset pipeline)
- `project_pmdneo_step6_complete.md` (= step 6 完了、 audio isolation)
- `project_pmdneo_step5_complete.md` (= step 5 完了、 ADPCM-A 6ch native path)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 Step 11 は「runtime selection」 軸 2 段目)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_trivial_verify_detection_and_correction_commit.md` (= dead code → call insertion → behavior change 段階分離規律)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 wav sha256 は使わない)
- `feedback_pmddotnet_mml_authoring_rules.md` (= MML 新規作成時 CRLF 必須、 γ finding 1 根拠)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_verify_script_serial_execution.md` (= δ で全 14 script serial 実行)
- `feedback_audio_gate_solo_isolation.md` (= silent-bcef fixture で audible regression なし最終確認)
