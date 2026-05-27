# ADR-0073: PMDNEO driver FM volume scaling semantics repair (= comv 二重 v→V 変換 + fm_volume_hook voice TL replace + per-alg carrier mask 不在)

- 状態: **Draft** (= 2026-05-27 43rd session 起票、 sprint α scope = 5 並走 sub-agent investigation 完走 + 真の root cause 確定 = driver FM volume scaling logic の 3 件 semantic divergence (= PMD V4.8s / PMDDotNET から独立 rewrite で導入された bug) + Annex α 6 sub-section literal record + Annex β-1 plan v1 起草 doc-only sprint。 ADR-0072 ε Accepted (= PR #154 MERGED at `78a1087`) で audio non-silent (= rms=5 / -76 dBFS / peak=-55 dBFS) 達成、 ただし δ-5 engineering gate Layer 1 threshold (= wav RMS > -60 dBFS) 未達 = audio 音量問題が残課題、 本 ADR-0073 で repair。 fixture voice 001 設計妥当性 confirm (= 仮説 A reject)、 driver touch が必須 (= ADR-0072 「driver no-touch mandate」 を覆す pivot = user 明示 GO mandatory point = β plan review approve 経由限定)、 fix 候補 A/B/C 並列 record + 確定は β plan review iteration へ defer)
- 起票日: 2026-05-27
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 user 明示「ADR-0073 を doc-only で起票し、 今回の root cause と設計判断を記録 + driver patch はまだ実施しない + scope / allowed-touch / rollback / verify を固定 + fix A/B/C は driver semantics を変えるため慎重に β plan review approve 経由限定」 mandate)
- 関連 ADR:
  - **ADR-0072** (= driver-PMDDOTNET voice opcode data delivery repair、 ε Accepted、 voice opcode @N dispatch + voice_table 1-based offset + #FFFile support 確立、 δ-5 Layer 1 threshold 未達 = 本 ADR-0073 が repair)
  - **ADR-0071** (= driver-PMDDOTNET integration repair、 rest 0x0F handler + tempo 3-byte = ε Accepted、 guarded change `.if PMDNEO_USE_PMDDOTNET` precedent literal 継承)
  - **ADR-0050** (= fadeout-semantics、 `pmdneo_fade_scale` 経路 precedent、 fade_level=64 passthrough confirm)
  - **ADR-0065** (= roadmap ⑥ audition、 sprint B follow-up integration verify framework、 §決定 13 4 層 engineering gate executor = 本 ADR の δ-5 verify base)
  - **ADR-0069** (= A-J distinctness 拡張、 guarded change `.if PMDNEO_USE_PMDDOTNET` pattern precedent + production sha256 維持戦略 base)
  - **ADR-0067** (= 16 ch fixture 拡張、 既存 verify script regression 維持対象)
  - **ADR-0068** (= 16 ch integration trace、 既存 verify script regression 維持対象)
  - **ADR-0051** (= SSG tone-enable owner contract、 既存 RMW owner 不可触対象)
  - **ADR-0058** (= roadmap ② v2 dispatcher、 `pmdneo_v2_*` 系 routine 不可触対象)
  - **ADR-0048** (= 軸 G dynamic supply、 ε partial state placement 不可触対象継承)
  - **ADR-0041** (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化 default + §決定 4-3 main agent fallback approve + retrospective Codex review + §決定 5 escalation 6 種 (= `design_judgment_needed` 軸が driver touch pivot escalation 該当))
  - **ADR-0026** (= K dispatch L ch 固定占有 不可触対象継承)
- 関連 memory:
  - `feedback_codex_rescue_audition_material_review_prompt.md` (= 4 層 engineering gate framework executor、 本 ADR の δ-5 verify gate base)
  - `feedback_main_agent_engineering_responsibility.md` (= main agent autonomous + Codex Rescue review-only + user judgment 限定 scope = 設計不可逆/scope 変更/aesthetic/本番切替のみ = driver touch pivot は user judgment 該当)
  - `feedback_pr_merge_branch_delete_atomic.md` (= branch 運用 4 条 + atomic 1 セット規律、 適用予定 = 13 回目)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= review-only 6 件 literal)
  - `feedback_parallel_subagent_investigation_default.md` (= 5 並走 sub-agent default、 本 ADR で適用 6 回目 = 5/5 success no preflight fail)
  - `feedback_long_running_hang_auto_recovery_rule.md` (= build / verify hang threshold)
  - `feedback_subagent_isolation_worktree_base_ref_mismatch.md` (= worktree base ref mismatch 9 件 guard、 本 ADR で sub-agent worktree isolation 不使用 path 採用で回避 = ADR-0072 sprint α preflight fail pattern 反復防止)
  - `feedback_sdas_if_no_value_comparison.md` (= sdasz80 `.if X == 1` 値比較非対応、 binary toggle `.if X` 統一)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= main agent autonomous + Codex layer 2 review-only)
  - `feedback_doc_governance_two_systems.md` (= AI協働用 ADR 不可触 mandate、 ADR doc plan iteration history immutable 維持)

## 背景

ADR-0072 sprint γ impl (= `731cffd` + `dfec8e9` + `6503738`) + ε Accepted (= `f1d40a8`) + PR #154 MERGED (= `78a1087`) で **build-side voice resolution + #FFFile support 完了** = PMDDotNET MML voice opcode `@N` runtime dispatch 動作確認達成。 ADR-0071 ε δ-5 silent failure (= wav RMS = -∞ dBFS) の substantive 根本治療達成:

- ✅ ADR-0072 ε δ verify = voice_table[1] → voice0_data 1-based offset fix + driver `comat` routine voice load 経路動作 + MAME ymfm-trace で reg 0x40=0x11 (= voice 001 OP1 TL=17) + reg 0x44=0x19 (= OP2 TL=25) 等 voice data exact load confirmed
- ❌ ADR-0072 ε δ-5 engineering gate executor `scripts/analyze-audition-wav.py` = **FAIL on Layer 1 WAV hygiene** = wav RMS = -76 dBFS、 peak = -55 dBFS、 Layer 1 threshold (= wav RMS > -60 dBFS) 未達

audio non-silent (= rms=5) は確認できたが、 audition material としては成立しない quiet (= -76 dBFS RMS、 通常 BGM の -20〜-12 dBFS RMS と 50〜60 dB の差)。 ADR-0072 ε Accepted record で「audio 音量問題は ADR-0072 scope OUT (= driver volume scaling or fixture voice design 由来、 別 sprint / 別 ADR 範疇)」 と明示、 本 ADR-0073 が follow-up repair。

user 明示 mandate 経路:
1. 「次は audio 音量問題 follow-up sprint の起票判断」
2. 「まず root cause を切り分けてください」 + 5 仮説 literal (= fixture voice design / driver volume scaling / FM TL/volume/expression / PMDDOTNET vs PMDNEO semantics 差分 / #FFFile voice data 反映)
3. 「sub-agent 並走で root cause 調査 + Codex Rescue plan review 必須」
4. 「driver touch が必要か、 fixture / voice design / compile.py 側で解けるかを先に切り分け」
5. 「production baseline `457a237c...` 維持方針を明記」
6. 「user audition にはまだ進まない」
7. ADR-0073 PR1 = doc-only mandate (= 後続 user 介入経路) = 「driver patch はまだ実施しない + scope / allowed-touch / rollback / verify を固定する方が安全 + fix A/B/C は driver semantics を変えるため β plan review approve 経由限定 + fix C 単独先行禁止 + fix A/B/C を sprint α で混ぜない + user audition に進まない + 音量問題を threshold calibration だけで済ませない + production sha256 が変わる driver patch を無断で入れない」

### 5 並走 sub-agent investigation 結果 (= sprint α 完走)

5 sub-agent 並列 investigation (= ADR-0072 sprint α worktree base ref mismatch 3 件 preflight fail pattern 反復防止のため、 本 ADR では **worktree isolation 不使用 + 主軸 working dir 経由 read-only investigation** path 採用):

| agent | scope | 結果 |
|---|---|---|
| agent 1 (= `a262ddf8410b100e2`) | fixture voice design 音量妥当性 + YM2610 spec dBFS 計算 | ✅ SUCCESS、 confidence high |
| agent 2 (= `a9e30ece3ca499a89`) | driver volume scaling logic + MAME trace 解析 | ✅ SUCCESS、 confidence high (= 二重 v→V 変換 bug literal trace 経路特定) |
| agent 3 (= `a51e0c5b4084a4265`) | FM TL/volume/expression spec 解釈 + master volume 経路 | ✅ SUCCESS、 confidence high |
| agent 4 (= `a58e2c353e5f92cea`) | PMD V4.8s / PMDDotNET / PMDNEO 音量 semantics 比較 | ✅ SUCCESS、 confidence high (= PMDDotNET = PMD V4.8s line-by-line port confirm、 PMDNEO 独立 rewrite divergence 確定) |
| agent 5 (= `a453ee616db228adc`) | root cause 切り分け framework + allowed-touch/sha256 plan v0 起草 | ✅ SUCCESS、 confidence high |

全 5 agent SUCCESS。 worktree isolation 不使用 path = sub-agent が主軸 working dir で read-only investigation (= Read / Bash grep / Bash xxd / Bash iconv のみ、 file edit / commit / push 一切なし)。

### 真の root cause (= agent 1-4 統合確定)

PMDNEO driver の FM volume scaling logic に **3 件の semantic divergence** = PMD V4.8s / PMDDotNET から独立 rewrite で導入された bug (= compound effect で audio -76 dBFS quiet 帰結):

1. **二重 v→V 変換 bug** = `src/driver/standalone_test.s:3984` `comv` 内 `call pmdneo_v_to_V_convert` が compile 済 byte (= 既に PMDDotNET `fmvol[]` table で TL-domain 値に変換済 = 例 v15 → 125) を **再度 v→V table lookup** 適用 + `cp #17` clamp → 全 v 値が **v16 = 127 に丸まる** (= compile 済 v15=125 / v16=127 区別消失)
2. **voice TL replace 数式** = `src/driver/standalone_test.s:4472-4529` `fm_volume_hook` の TL 公式 `TL = 0x7F - V/2` = voice data の TL field 値を **完全無視 + 全 4 op に同 TL 一律書込** (= PMD V4.8s `volset_slot` の voice TL + ~vol additive semantic と根本的に異なる)
3. **per-alg carrier mask 不在** = `fm_volume_hook` が `carrier_table[alg]` slot mask を見ず **全 4 op TL 書込** (= PMD V4.8s `volset_slot` の `and bl, carrier[di]` mask 経路欠落 → ALG=0-6 で modulator/carrier 区別なく voice 音色設計破壊)
4. (+) default vol 初期値 mismatch = `pmdneo5_init_part` line 3481-3505 で `c = #0x0F = 15` (= PMD V4.8s = 108、 PMDDotNET = 同 108、 PMDNEO のみ 15)

#### -76 dBFS RMS の物理整合 (= agent 1 + agent 3 + agent 4 統合 dBFS 計算)

| 経路 | dB attenuation |
|---|---|
| `fm_volume_hook` TL=0x40 carrier 上書き (= voice OP4 TL=0 → 0x40) | -48 dB (= TL 0.75 dB/step × 64) |
| modulator (= OP1/OP2/OP3) TL=0x40 上書き → modulation depth 抑制 + sine pure 化 | 副次寄与 (= 倍音減少 + carrier sine 近似) |
| envelope SL=2 (= sustain level -17.7 dB) + duty cycle (= l4 note + r4 release) RMS 平均 | 追加 -21〜-27 dB |
| **合算** | **-76 dBFS RMS / -55 dBFS peak (= 実測整合 high confidence)** |

#### 比較表 (= agent 4 ground truth literal、 PMD V4.8s / PMDDotNET / PMDNEO の volume semantics)

| 観点 | PMD V4.8s | PMDDotNET | PMDNEO |
|---|---|---|---|
| v→V 変換 (= compile 時) | あり 1 回 (= `vendor/pmd48s/source/mc48s/MC.ASM:8274-8290` `fmvol[]`) | あり 1 回 (= `vendor/PMDDotNET/PMDDotNETCompiler/mml_seg.cs:152-171` `fmvol[]` byte-identical port) | あり 1 回 (= `src/tools/pmd-mml/compile.py` 想定) |
| v→V 変換 (= runtime `comv`) | **なし** (= `vendor/pmd48s/source/pmd48s/PMD.ASM:3406-3411` `mov volume[di],al; ret` byte 直接 store) | **なし** (= `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs:4813-4829` `partWk[di].volume = al; ret` line-by-line port) | **あり** (= `src/driver/standalone_test.s:3972-4003` `comv` で `call pmdneo_v_to_V_convert` 二重適用 bug) |
| volume → TL 換算 method | `volset_slot` macro (= `PMD.ASM:4709-4724`) = voice TL + ~vol additive + saturate (= voice 音色設計保存) | `volset_slot()` (= `PMD.cs:6822-6838`) = byte-identical port | `fm_volume_hook` (= `standalone_test.s:4472-4529`) = `TL = 0x7F - V/2` replace + 全 4 op 一律書込 (= voice TL 完全無視) |
| per-alg carrier slot mask | あり (= `PMD.ASM:7958-7964` `carrier_table[ALG]` + `volset_slot` 内 `and bl, carrier[di]`) | あり (= `PMD.cs` 同 port) | **なし** (= `fm_volume_hook` 全 4 op 一律、 ALG=7 全 op carrier 想定 hard-coded) |
| v15 + voice OP4 TL=0 (= ALG=0 carrier) final | TL ≈ 2 (= -1.5 dB ≈ max output) | TL ≈ 2 (= -1.5 dB) | TL = 0x40 (= **-48 dB**) |
| default 初期 vol | 108 (= 0x6C、 `PMD.ASM:558` `mov volume[di],108`) | 108 (= 同 port) | **15** (= 0x0F、 `standalone_test.s:1754` 等) |
| `#Volumedown` directive | 実装あり (= F±N,S±N,P±N,R±N、 全 part bias) | 実装あり (= 同 port) | **未実装** (= grep で `voldown` 該当 routine 不在) |

### 3 fix 候補 (= sprint β plan v1 で確定、 sprint α では並列 record only)

| fix | 対象 | 変更内容 | 影響 dB |
|---|---|---|---|
| **fix A** | `src/driver/standalone_test.s:3972-4003` `comv` | `call pmdneo_v_to_V_convert` 削除 → PMD V4.8s と同じ byte 直接 store | 二重変換解消 = v15 → V=125 (= 正しい table 値) |
| **fix B** | `src/driver/standalone_test.s:4472-4529` `fm_volume_hook` | `TL = 0x7F - V/2` replace 数式 → `volset_slot` 数式 port (= voice TL + ~vol additive + carrier mask 経由) | voice TL 保存 + carrier-only 書込 = 大幅 audio 改善 |
| **fix C** | `src/driver/standalone_test.s:3481-3505` `pmdneo5_init_part` | default vol 0x0F → 0x6C (= 108、 PMD V4.8s 初期値) | volume cmd 未指定時の初期挙動 PMD V4.8s 整合 |

3 fix の **driver semantics 変更** = 設計判断軸、 sprint α では確定せず β plan review chain で iterate + Codex Rescue 投入後の approve 経由 + driver patch 実施判断は user 明示 GO mandatory point。

## 決定

### 決定 1: ADR-0073 scope = PMDNEO driver FM volume scaling semantics repair に限定

#### scope IN (= ADR-0073 で修理対象)

- **(1) `comv` opcode handler の二重 v→V 変換 bug** = `src/driver/standalone_test.s:3972-4003` 修正対象 (= fix A)
- **(2) `fm_volume_hook` の voice TL replace 数式 + per-alg carrier mask 不在** = `src/driver/standalone_test.s:4472-4529` 修正対象 (= fix B)
- **(3) `pmdneo5_init_part` default vol 初期値 mismatch** = `src/driver/standalone_test.s:3481-3505` 修正対象 (= fix C)
- production sha256 invariant `457a237c...` 維持 (= guarded change `.if PMDNEO_USE_PMDDOTNET` 配下限定 + flag-off byte-identical)
- 4 build matrix verify (= ADR-0071/0072 precedent 継承)
- δ-5 engineering gate Layer 1 PASS (= wav RMS > -60 dBFS、 primary success metric)

#### scope OUT (= 別軸 / 別 ADR future、 ADR-0073 では touch しない)

- **(a) `#Volumedown` directive 実装** (= PMD V4.8s + PMDDotNET 実装あり、 PMDNEO 未実装、 別 ADR scope = compile.py + driver 両 touch 必要)
- **(b) `comV` (= 大文字 V、 opcode 0xCC、 byte 直接 store の既に正しい経路) 経路修正** (= 修正不要)
- **(c) LFO/AMS/PMS scaling logic** (= ALG-aware carrier mask 以外の voice scaling、 別 ADR scope)
- **(d) ADR-0065 ε audition session 実施判断** = user 介入 mandatory、 ADR-0073 ε Accepted + audition material 再設計 + user audition session
- **(e) production-ready 全体達成 / 本番 cmd 切替判断** = ADR-0066 候補 future、 user 明示 GO 必須
- **(f) ADR-0070 K bitmap pair distinct** = user 明示 GO 必須
- **(g) MAME runtime audio audible verify on user 別作業 fixture** (= fm/ssg-active-ladder.mml) = ADR-0073 ε Accepted 後 follow-up、 user 明示 GO 必須

### 決定 2: sub-sprint chain plan = α/β/γ/δ/ε 5 段 (= ADR-0067/0068/0069/0071/0072 precedent)

| sub-sprint | scope | user 介入 | 完了判定 | 駆動 driver/runtime touch |
|---|---|---|---|---|
| **α** | root cause investigation = 5 並走 sub-agent + 真 root cause 確定 + Annex α literal record | optional (= main agent autonomous + Codex Rescue review-only) | **本 PR1 起票時完了** = Annex α 6 sub-section fill + ADR doc 起票 | なし (= 全 sub-agent read-only) |
| **β** | plan iteration = Annex β-1 plan v1 起草 (= fix A/B/C 比較 + 採用案確定 + allowed-touch literal + verify gate literal + rollback condition literal) + Codex Rescue plan review chain + plan v2/v3 iteration | **mandatory escalation point = driver patch 実施判断は β plan review approve 経由限定、 user 明示 GO で γ 着手** | plan approve (= Codex approve or main agent fallback approve + retrospective Codex review = ADR-0041 §決定 4-3 precedent) | なし (= doc-only) |
| **γ** | repair implementation = approve plan に基づき driver-side fix A/B/C (= guarded change `.if PMDNEO_USE_PMDDOTNET` 配下限定 + ADR-0071 precedent pattern 継承) | **mandatory = user 明示 GO 必須** (= driver patch impl 開始時に再 confirm、 ADR-0072 「driver no-touch mandate」 を覆す pivot) | impl 完了 + 4 build matrix PASS + production sha256 byte-identical 維持 confirm (= flag-off byte-identical) + 既存 routine body 不変 confirm | **あり** (= scope IN (1)/(2)/(3) 関連 routine のみ、 guarded change 配下限定) |
| **δ** | MAME runtime functional verify = δ-1〜δ-7 gate 実施 + audio render + trace + expected behavior 確認 + **primary success metric = δ-5 engineering gate Layer 1 PASS = wav RMS > -60 dBFS** | optional | δ verify findings literal record (= ADR-0071 ε / ADR-0072 ε 後 δ verify pattern) + **primary success = δ-5 Layer 1 PASS** | なし (= MAME render only) |
| **ε** | Accepted 移行 doc-only = Draft → Accepted + Annex 全統合 + 「PMDNEO driver FM volume scaling semantics repair 完了」 milestone wording 解禁 (= 併記必須 = (i) δ MAME runtime functional verify 結果 + (ii) production-ready 全体達成ではない + (iii) (d) audition gate 達成ではない + (iv) 軸 B 完成ではない + (v) 軸 G 完成ではない + (vi) 16ch full candidate distinctness 完了ではない + (vii) 本番 cmd 切替完了ではない) + ADR-0065 audition material 再開 trigger 完全解除 record | optional | Accepted milestone + ADR-0065 ε δ session 起票 ready (= user 介入 mandatory) | なし (= doc-only) |

#### sub-sprint chain dependency

- ADR-0073 ε Accepted → ADR-0065 audition material 再開 trigger 完全解除 → user 明示 GO で δ session 起票判断
- ADR-0066 (= roadmap ⑦ 本番 cmd 切替) = ADR-0065 ε Accepted 後 future (= 順序固定)
- ADR-0070 (= K bitmap pair distinct) = ADR-0069 γ Accepted で dependency 解除済、 user 明示 GO で独立起票可

### 決定 3: production sha256 維持方針 (= user 明示 mandate)

production sha256 = `457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092` **維持 mandate** (= dashboard active baseline marker section literal、 base anchor `wip-pmddotnet-opnb-extension@397e49f` baseline)。

修理は **`.if PMDNEO_USE_PMDDOTNET ... .endif` guarded change pattern** (= ADR-0069 §決定 4 + ADR-0071 §決定 3 + ADR-0072 plan v1-v4 (= revert 済) precedent literal 継承) で実装し、 production default build (= `PMDNEO_USE_PMDDOTNET=0`) では **byte-identical 維持**。

guarded change で実装不可能 (= 修理 routine が両 build mode 共通で sha256 衝突不可避) と判明した場合は **user 明示 GO + 新 baseline 設定 へ pivot**、 main agent 自走では実施しない。

#### γ 実装時の 4 build matrix 検証 (= ADR-0071/0072 precedent 継承)

- (B1) production baseline = `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` → sha256 == `457a237c...` byte-identical
- (B2) post-patch flag-off = (B1) と byte-identical (= guarded change flag-off 完全無効化)
- (B3) flag-on pre-patch with fixture = ADR-0072 baseline (= voice opcode dispatch 機能あり + volume scaling bug 残存)
- (B4) flag-on post-patch with fixture = (B3) と diff = ADR-0073 patch byte 量のみ + audio audible 改善
- production sha256 不一致時 = rollback condition #1 発火 (= ADR-0071 §決定 6 + ADR-0069 §決定 5 継承)

### 決定 4: allowed-touch literal (= plan v1 で確定、 sprint α では候補列挙)

#### (i) repo diff allowed-touch 候補 (= ADR-0073 γ PR3 想定対象 file)

- **driver-side fix (= 必須)**:
  - `src/driver/standalone_test.s` = scope IN (1)/(2)/(3) 関連 routine (= `comv` line 3972-4003 + `fm_volume_hook` line 4472-4529 + `pmdneo5_init_part` line 3481-3505、 全て guarded change `.if PMDNEO_USE_PMDDOTNET ... .endif` 配下限定)
  - 新規 helper routine (= 必要に応じて `pmdneo_volset_pmddotnet` or `pmdneo_fm_volume_hook_pmddotnet` additive、 0x0610 セクション末尾、 ADR-0071 precedent)
- **fixture (= 必要に応じて)**:
  - `src/test-fixtures/adr-0073/` = δ functional verify gate 用 fixture (= ADR-0069 §決定 3-d「新規 fixture MML 例外的許可」 precedent 継承)
  - 新規 verify script (= `src/test-fixtures/adr-0073/verify-volume-scaling.sh` 等)
- **doc / dashboard**:
  - `docs/adr/0073-pmdneo-driver-fm-volume-scaling-semantics-repair.md` (= 本 ADR doc)
  - `docs/parallel-axes-dashboard.md` (= 0073 行 add + escalation 履歴 entry)

#### (ii) 不可触対象 (= 全 case 共通)

- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38)
- ADR-0026 §決定 3/4 K dispatch L ch 固定占有
- ADR-0051 `pmdneo_ssg_tone_sync` (= reg 0x07 RMW 唯一 owner)
- ADR-0058 `pmdneo_v2_*` 系 routine body
- ADR-0067〜0072 既存 Annex 本文 (= immutable history、 memory `feedback_doc_governance_two_systems.md`)
- 既存 verify script (= ADR-0049〜0072 全 verify gate)
- 既存 fixture MML (= ADR-0067/0068/0069/0072 PR で commit 済)
- vendor (= `vendor/pmd48s/` + `vendor/PMDDotNET/` + `vendor/ngdevkit-examples/`)
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked + 退避 branch + 集約 branch 上 user 別作業

### 決定 5: verify gate literal

#### γ build verify (= production sha256 維持 + 4 build PASS)

- gate γ-1: 4 build matrix PASS (= 決定 3 § γ 実装時の検証 literal)
- gate γ-2: production sha256 byte-identical 維持 (= `457a237c...` ALL build mode (B1)/(B2) で)
- gate γ-3: `.lst` predicate (= ADR-0071/0072 precedent 4 件 = 新規 inline label / guarded block assemble / 既存 routine body 不変 / 既存 symbol table 不変)
- gate γ-4: ADR-0051 owner contract untouched (= `pmdneo_ssg_tone_sync` 完全不変)
- gate γ-5: 既存 verify script ALL PASS (= ADR-0049〜0072 regression-free)

#### δ functional verify (= 実音成立確認、 audio audible)

- gate δ-1〜δ-3: fm-active-ladder / ssg-active-ladder / candidate 2 v3 staircase audible (= user 別作業 fixture も含む、 ε Accepted 後 follow-up scope)
- gate δ-4: 既存 18+ verify script regression carry (= ADR-0071/0072 δ-4 同 pattern)
- gate δ-5: `scripts/analyze-audition-wav.py` engineering gate 4 層 ALL PASS = **特に Layer 1 WAV hygiene = wav RMS > -60 dBFS で audio audible confirm**、 これが本 ADR-0073 の **primary success metric**
- gate δ-6: MAME ymfm trace で FM reg 0x40-0x4F (= TL register area) write timeline 解析 = `fm_volume_hook` 修正後の TL final value confirm (= voice OP4 TL=0 carrier が v15 後も小さい TL 維持 = max output 近傍)
- gate δ-7: MAME z80-mem-trace で `comv` 修正後の PART_OFF_VOLUME storage value 確認 (= byte 直接 store = compile 済 byte 整合)

### 決定 6: rollback condition (= ADR-0071 §決定 6 11 condition + ADR-0072 §決定 6 13 condition 継承 + ADR-0073 固有 condition)

ADR-0071 §決定 6 11 unique rollback condition + 4 段 stop action + 3 段 responsibility + destructive git 禁止 (= `git revert` のみ) **完全継承**。

ADR-0072 固有 #12 / #13 carry:
- #12 voice load failure on PMDDOTNET path (= ADR-0072 確立 voice opcode dispatch regression、 γ impl 後 MAME ymfm trace で voice register writes 0 件発生時)
- #13 audio silent persistence after γ impl (= ADR-0072 ε confirm 状態より悪化 = rms=0 silent 再発時)

ADR-0073 固有追加 condition:
- **#14 audio audible regression on default voice** = ADR-0073 γ impl 後 既存 `test-voice-load.mml` (= ADR-0072 fixture) で rms 悪化 (= ADR-0072 ε -76 dBFS より更に低下) 発生 → 即 sub-sprint halt + revert + design 再評価
- **#15 δ-5 engineering gate Layer 1 FAIL on ADR-0073 new fixture** = ADR-0073 新規 audible fixture (= guarded change flag-on path) で wav RMS ≤ -60 dBFS = primary success metric 未達 → 1 retry → 再 FAIL なら sub-sprint halt + 仮説 priority 再評価
- **#16 ADR-0072 既存機能 regression** = ADR-0072 ε で確立した voice opcode @N dispatch + voice_table 1-based offset + #FFFile support が ADR-0073 γ impl で破壊された場合 → 即 sub-sprint halt + revert + ADR-0072 ε state baseline 再確認
- **#17 fix A/B/C 単独実装の追加 finding 由来 pivot 必要性発覚** = β plan review iteration で fix A/B/C 単独適用では root cause 解消不可能と判明時 → user 明示 GO 必須 + 別 fix path 採用判断 (= main agent 自走では実施しない)

#### 共通原則 (= ADR-0069 §決定 5 + ADR-0071 §決定 6 + ADR-0072 §決定 6 完全継承)

- 軽微 fix-up (= condition #2 / #4 / #8a / #8b) = 連鎖 commit fix-up (= rollback ではない)
- sub-sprint 単位 halt (= condition #1 / #3 / #5 / #6 / #7 / #9 / #14 / #15 / #16) = ADR-0065 β PR3 halt precedent literal 同形
- ADR-0073 全体 halt (= condition #10 / #17) = Draft 維持 + 全 sub-sprint rollback record + 後続 ADR dependency update
- **destructive git 操作禁止** = `git reset --hard` / `git push --force` / `git checkout --` 等は user 明示なし禁止、 `git revert` のみ採用

### 決定 7: 表記制約 + 解禁表現候補

#### ADR-0073 起票時点 (= 本 sprint α、 PR1 doc-only)

- **使用可**:
  - 「build-side voice resolution + #FFFile support 完了」 (= ADR-0072 ε Accepted 後継承)
  - 「PMDDotNET MML voice opcode @N runtime dispatch 動作確認」 (= ADR-0072 δ verify 後継承)
  - 「ADR-0072 ε Accepted」
  - 「ADR-0073 sprint α 完走 = 真の root cause = FM volume scaling logic 3 件 semantic divergence 確定」
  - 「ADR-0073 fix 候補 A/B/C 並列 record」
- **禁止維持 (= 起票時点)**:
  - 「audio 音量問題解決」 (= ADR-0073 ε Accepted 後解禁)
  - 「PMDNEO driver FM volume scaling semantics repair 完了」 (= ADR-0073 ε Accepted 後解禁)
  - 「δ-5 engineering gate Layer 1 PASS」 (= ADR-0073 δ verify ALL PASS 後解禁)
  - 「(d) audition gate 達成 / roadmap ⑥ audition 完了 / production-ready 全体達成 / 軸 B 完成 / 軸 G 完成 / 本番 cmd 切替完了」 (= 各 user 明示 GO 必須)
  - 「16ch full candidate distinctness 完了」 (= ADR-0070 候補 future)

#### ADR-0073 ε Accepted 後 (= 解禁候補)

- 「**PMDNEO driver FM volume scaling semantics repair 完了**」 (= 併記必須 = (i) δ MAME runtime functional verify 結果 + (ii) production-ready 全体達成ではない + (iii) (d) audition gate 達成ではない + (iv) 軸 B 完成ではない + (v) 軸 G 完成ではない + (vi) 16ch full candidate distinctness 完了ではない + (vii) 本番 cmd 切替完了ではない)
- 「ADR-0073 ε Accepted」

### 決定 8: 番号 chronology + ADR 関連順序

ADR-0073 = ADR-0072 ε Accepted 後の natural follow-up sprint = audio 音量問題 (= δ-5 Layer 1 threshold 未達) repair。 ADR-0070 候補 (= K bitmap pair distinct) は ADR-0073 と独立 (= user 明示 GO 必須)。 ADR-0065 ε audition session は ADR-0073 ε Accepted + user 介入 mandatory で再開判断。

ADR-0072 plan v5 で確立した「driver no-touch mandate」 は voice opcode data delivery 範疇に限定された判断、 audio volume scaling 範疇 (= 本 ADR-0073) では別軸の root cause (= driver semantics divergence) のため **driver touch pivot 必須** = ADR-0041 §決定 5 `design_judgment_needed` escalation 軸該当 = β plan review approve + user 明示 GO で γ 着手。

## verify gate (= 本 PR1 sprint α scope = doc-only、 spec consistency check)

- gate 1: ADR doc 整合性 (= 8 決定 literal + Annex α 6 sub-section + Annex β-1 plan v1 placeholder + 平易要約 6 構造)
- gate 2: 5 並走 sub-agent investigation finding literal record (= 5/5 success literal、 worktree isolation 不使用 path 採用記録)
- gate 3: dashboard 0073 行 add (= status + scope + allowed-touch + verify gate + dependency literal)
- gate 4: 改訂履歴 起票 entry append (= append only mandate 厳守)
- gate 5: production sha256 = `457a237c...` 維持 confirm (= 本 sprint α doc-only で build しない、 carry)
- gate 6: branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` + (2) merge atomic + (3) close 不要時削除 + (4) 保持対象 3 type 不可触
- gate 7: 5 並走 sub-agent default 規律遵守 confirm (= memory `feedback_parallel_subagent_investigation_default.md`、 同一 message 内多 Agent tool call + nesting 禁止)
- gate 8: fix A/B/C を sprint α で混ぜない確認 (= 並列 record only + plan iteration は β scope) + fix C 単独先行禁止 confirm + user audition 進めない confirm + production sha256 が変わる driver patch 無断 commit 禁止 confirm (= 本 PR1 doc-only)

## Codex layer 2 plan review chain

sprint α 完走後の sprint β = Codex Rescue plan review chain (= ADR-0071 5 round + ADR-0072 7 round precedent から類推):
- round 1: plan v1 投入 + scope / allowed-touch / sha256 / verify plan / fix A/B/C 採用案確定 重点 review
- round chain: revise → plan v2/v3 iteration → approve (= Codex approve or main agent fallback approve + retrospective Codex review = ADR-0041 §決定 4-3 precedent)
- β approve 後 = **user 明示 GO mandatory point** = γ driver patch impl 着手判断 (= ADR-0072 「driver no-touch mandate」 を覆す pivot escalation)

## Annex α: root cause investigation 5 sub-agent finding synthesis (= sprint α scope literal fill)

### α-1: agent 1 finding = fixture voice design 音量妥当性 + YM2610 spec dBFS 計算 (= confidence high、 worktree isolation 不使用 read-only)

#### 確定 finding 5 軸

##### 軸 1 = `test-voice-load.mml` voice 001 register-major bytes 解釈
- compile.py `--voice-only` 出力 voice0_data 25 byte literal:
  ```
  byte 00-03: 0x01 0x02 0x01 0x01   ; reg 0x30 (DT/ML) slot 0-3
  byte 04-07: 0x11 0x19 0x26 0x00   ; reg 0x40 (TL)    slot 0-3 = OP1=17/OP2=25/OP3=38/OP4=0
  byte 08-11: 0x1F 0x1F 0x1F 0x1F   ; reg 0x50 (KS/AR) slot 0-3
  byte 12-15: 0x00 0x00 0x00 0x12   ; reg 0x60 (AMS/DR) slot 0-3
  byte 16-19: 0x00 0x00 0x00 0x00   ; reg 0x70 (SR)    slot 0-3
  byte 20-23: 0x00 0x00 0x00 0x2F   ; reg 0x80 (SL/RR) slot 0-3
  byte 24:    0x00                  ; reg 0xB0 (ALG/FBL) = ALG=0, FBL=0
  ```
- **OP4 (slot 3、 ALG=0 carrier) TL byte = byte index 7 = 0x00 = max output (= 0 dB attenuation)**
- voice 001 設計意図 = OP4 carrier full output + modulator OP1/OP2/OP3 を段階減衰させて軽い modulation 付与 = audible 想定

##### 軸 2 = SSGEG.FF vs voice 001 carrier TL 値比較
- SSGEG.FF 4 voices 全 OP4 carrier TL = 0x00 (= max output、 voice 001 と整合設計)
- voice 1 (= SSG-EG1) は bit 7 = SSG-EG enable bit、 下位 7 bit TL=0 (= driver `pmdneo_fm_clear_ssg_eg_ch` で 0x90 group ZERO clear で SSG-EG 機能無効化)

##### 軸 3 = driver `fm_voice_data_default` literal byte dump
- `src/driver/standalone_test.s:1493-1502` literal:
  ```
  fm_voice_data_default:
        .db     0x01, 0x01, 0x01, 0x01   ; reg 0x30 (DT/ML)
        .db     0x18, 0x18, 0x18, 0x18   ; reg 0x40 (TL) = -18 dB 各 OP
        .db     0x1F, 0x1F, 0x1F, 0x1F   ; reg 0x50 (KS/AR)
        .db     0x00, 0x00, 0x00, 0x00   ; reg 0x60 (AMS/DR)
        .db     0x00, 0x00, 0x00, 0x00   ; reg 0x70 (SR)
        .db     0x0F, 0x0F, 0x0F, 0x0F   ; reg 0x80 (SL/RR)
        .db     0x07                     ; reg 0xB0 = ALG=7, FBL=0
  ```
- default voice = ALG=7 (= 全 4 OP carrier) + 全 OP TL=0x18 (= -18 dB) = test01.mml existing audible 経路

##### 軸 4 = YM2610 carrier TL → dBFS 換算計算
- TL = 7-bit (= 0-127、 reg 0x40-0x4F bit 0-6)
- **1 step = -0.75 dB attenuation** (= YM2610 公式仕様)
- TL=0 → 0 dB (full output) / TL=127 → -95.25 dB (effective silence)
- 換算 table 抜粋: TL=0x18 (24) → -18 dB / TL=0x40 (64) → -48 dB / TL=0x41 (65) → -48.75 dB
- voice 001 OP4 TL=0 + v15 + ALG=0 期待 = -3〜-6 dBFS (= PMD V4.8s/PMDDotNET semantics)
- 実測 PMDNEO = -76 dBFS RMS / -55 dBFS peak = -48 dB attenuation (= TL=0x40) + envelope SL=2 sustain (-17.7 dB) + duty cycle (-10〜-20 dB) で説明可能

##### 軸 5 = root cause 仮説 A/B/C/D/E 評価
- **A. voice 001 OP4 TL register-major emit 位置誤り** = **REJECT** (= byte index 7 = 0x00 で reg 0x40 slot 3 literal verify 済 + compile.py format_voice_table_only 経路 + driver pmdneo_fm_voice_set layout 整合)
- **B. voice 001 envelope 極端 + 即 decay** = **PARTIAL** (= OP4 AR=31/DR=18/SL=2/RR=15 で sustain phase -6 dB + RR fast、 副次寄与のみ、 root cause は次の D)
- **C. ALG=0 + modulator TL 上書きで modulation 歪み** = **PARTIAL** (= fm_volume_hook が modulator にも TL=0x41 上書きで modulation depth 抑制、 副因)
- **D. driver 側 volume hook で attenuation 適用** = **ACCEPT = main culprit** (= `fm_volume_hook` line 4472-4504 が `TL = 0x7F - V/2 = 0x41` で carrier 含む全 OP 上書き、 voice 001 OP4 TL=0 設計を完全 override = -48.75 dB carrier attenuation)
- **E. #FFFile voice data 値正しいが TL 適用 logic で attenuation** = **REJECT** (= ADR-0072 β-5-2 reg 0x40=0x11 voice TL exact load 確認済、 attenuation は voice data 由来ではない)

### α-2: agent 2 finding = driver volume scaling logic + MAME trace 解析 (= confidence high)

#### 確定 finding 5 軸

##### 軸 1 = MML `v15` → driver byte + volume memory
- PMDDotNET emit: `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:7726-7796` `vseta() → vset() → vset2()`、 `work.bx = mml_seg.fmvol[15] = 127-0x05 = 0x7A = 122` → **emit 2 byte `0xFD 0x7A`**
- `fmvol[]` table = `mml_seg.cs:152-171` + PMD V4.8s `MC.ASM:8274-8290` byte-identical (= 17 entry: 85/87/90/93/95/98/101/103/106/109/111/114/117/119/122/125/127)
- driver opcode handler = `commandsp:4210-4211` `cp #0xFD; jp z, commandsp_v` → `commandsp_v: jp comv` (= line 4267) → `comv` routine (= line 3972-4003)
- volume memory offset = `PART_OFF_VOLUME = 9` (= `standalone_test.s:132`)

##### 軸 2 = fm volume hook 経路 trace
- routine = `fm_volume_hook` `standalone_test.s:4472-4505`
- 計算式 literal:
  ```
  A = PART_OFF_VOLUME(ix)        ; raw volume byte
  A = pmdneo_fade_scale(A)       ; fade_level=64 で passthrough
  A = A >> 1                     ; A = V / 2
  TL = 0x7F - A                  ; final TL value
  ```
- **4 op (= reg 0x40/0x44/0x48/0x4C + ch index) 全 op 同 TL 書込** (= line 4471 comment「ALG 7 全 op carrier 想定」、 carrier_table / per-alg masking なし)
- keyon path との関係 = `pmdneo_part_main_note_keyon` (= line 3819) は volume hook を call しない (= fnumset_hook + keyon_hook のみ)、 volume hook は MML volume command 時のみ起動 (= `comv` / `comV` / `comvshift_*` 等)

##### 軸 3 = MAME trace 実測 analysis
- `/tmp/pmdneo-trace/ymfm-trace.tsv` FM ch 0 TL register writes timeline:
  ```
  idx  port reg val   駆動 routine
  32   A    40  7F    init mass write (= nmi_cmd_5_init_mml_song:1599-1604)
  119  A    40  18    fm_voice_data_default load (= pmdneo_fm_voice_set:1497)
  316  A    40  11    voice 001 OP1 TL=17 load
  317  A    44  19    voice 001 OP2 TL=25
  318  A    48  26    voice 001 OP3 TL=38
  319  A    4C  00    voice 001 OP4 TL=0 (= carrier)
  341  A    40  40    fm_volume_hook 全 OP 上書き (= V=127 → TL=0x40)
  342  A    44  40    同上
  343  A    48  40    同上
  344  A    4C  40    同上 (= carrier の TL=0x00 → 0x40 で破壊)
  349  A    28  F0    fm_keyon ch 0 all-slot
  ```
- transition `0x00 → 0x40` (= OP4 carrier) で +64 attenuation 適用が `fm_volume_hook` (= line 4472-4505) で発生
- **0x40 = 64 = v15 経由 attenuation = 0.75 dB × 64 = -48 dB**

##### 軸 4 = PMD V4.8s vs PMDNEO volume scaling 比較
- PMD V4.8s `comv` handler (= `vendor/pmd48s/source/pmd48s/PMD.ASM:3406-3411`) = `lodsb; mov volume[di],al; ret` = **storage only、 v_to_V_convert 再適用なし**
- PMD V4.8s TL 書込 (= `fmvs` `PMD.ASM:4760-4810`) = `cl = NOT(volume); bl = carrier[di] & ch_mask` = **per-alg carrier mask、 carrier op のみ TL 書込**
- PMDNEO 比較表 = 決定 1 § 真の root cause § 比較表 literal

##### 軸 5 = root cause 仮説 A/B/C/D 評価
- A: attenuation curve v15=0 → OK 仮説 = **WRONG** (= `v_to_V_fm[15]=125` だが PMDDotNET emit `0xFD 0x7A` を comv が index 誤解釈 → clamp 16 → table[16]=127 → TL=0x40)
- B: voice TL に v scaling 加算 = **WRONG** (= `fm_volume_hook` は加算ではなく上書き)
- C: v 値の解釈が逆 = **PARTIALLY CORRECT** (= TL=0x40 結果は一致だが mechanism = 加算ではなく per-op 一律上書き)
- D: ALG=0 で carrier OP4 のみ audible + scaling 差 = **MOSTLY CORRECT** (= ALG=0 で OP4 reg 0x4C 唯一 carrier、 fm_volume_hook が reg 0x4C=0x40 上書きで carrier 自体 -48 dB 減衰 = -76 dBFS の直接原因)

### α-3: agent 3 finding = FM TL/volume/expression spec 解釈 + master volume 経路 (= confidence high)

#### 確定 finding 5 軸

##### 軸 1 = YM2610 FM volume control register 列挙
- reg 0x40-0x4F = op TL (= 4 op × 6 ch + bank A/B)、 bit 0-6 = 0.75 dB/step linear attenuation、 0x7F = -95.25 dB ≈ silence、 0x00 = 0 dB max
- reg 0x28 = keyon、 bit 4-7 = op slot enable mask (= 4 op 全 enable = 0xF0)
- reg 0xB0-0xB6 = FB/ALG、 bit 0-2 = ALG、 bit 3-5 = FB
- reg 0xB4-0xB6 = PAN/LR/LFO、 bit 7 = L、 bit 6 = R = 0xC0 (= LR both)
- **master volume relevant register = 存在しない** (= reg 0x07 mixer は SSG tone/noise enable のみ、 FM 無関係)
- master 制御 = 全 carrier op TL の software 一括 attenuation で実装
- ALG=0 semantics literal (= `PMD.ASM:7958-7964` `carrier_table`):
  - ALG=0/1/2/3 = OP4 のみ carrier (`10000000b`)
  - ALG=4 = OP4 + OP2 carrier (`10100000b`)
  - ALG=5/6 = OP4 + OP3 + OP2 carrier (`11100000b`)
  - ALG=7 = OP4 + OP3 + OP2 + OP1 全 op carrier (`11110000b`)

##### 軸 2 = PMD MML v / V / ( ) 命令仕様 (= `docs/manual/PMDMML_MAN_V48s_utf8.txt:1856-1857`)
- v 値 → V 値 換算 table literal:
  ```
  v	|  0|  1|  2|  3|  4|  5|  6|  7|  8|  9| 10| 11| 12| 13| 14| 15| 16|
  V	| 85| 87| 90| 93| 95| 98|101|103|106|109|111|114|117|119|122|125|127|
  ```
- v15 → V=125、 v16 → V=127 (= max)
- driver emit byte format (= `compile.py:104-110`):
  - `v N` → `0xFD N` (= 2 byte)
  - `V N` → `0xCC N` (= 2 byte)
  - `(` / `)` → `0xF3 N` / `0xF4 N`
  - `v+` / `v-` → `0xDE N` / `0xDD N`
  - `v(` / `v)` → `0xDA N` / `0xDB N`

##### 軸 3 = PMD V4.8s + PMDDotNET v→V table と PMDNEO comparison
- v→V 変換は **compile 時 1 回** (= PMD V4.8s + PMDDotNET)、 driver `comv` は byte 直接 store
- PMDNEO `comv` (= 3984) = compile 済 byte を **再度 v→V table lookup** (= 二重変換 bug) + `cp #17` clamp で 16 → table[16]=127

##### 軸 4 = YM2610 TL → dBFS 数式
- attenuation_dB = TL × 0.75
- voice 001 OP4 TL=0 + ALG=0 carrier theoretical output (= PMD V4.8s semantics) = 約 -3〜-6 dBFS (= OP4 単独 sine、 OPNB DAC max 近傍)
- PMDNEO 実測 -76 dBFS = TL=0x40 carrier upstream + modulator suppression + envelope SL=2 sustain で説明可能

##### 軸 5 = master / expression / aux 経路検証
- YM2610 hardware master volume register **不在**、 software 全 carrier TL 一括制御で実装
- PMD MML `#Volumedown` directive (= F±N,S±N,P±N,R±N) で global FM/SSG/PCM/rhythm bias 加減算 (= line 855-895)
- **PMDNEO driver は `#Volumedown` 未実装** (= grep で `voldown` routine 不在、 line 696-2200 範囲)
- test01.mml (= existing audible) vs test-voice-load.mml (= -76 dBFS quiet) 差分:
  - voice ALG 差 = ALG=7 (= default、 全 op carrier、 fm_volume_hook 全 op 一律書込が偶然正しい挙動) vs ALG=0 (= OP4 のみ carrier、 全 op 一律書込で modulator 破壊 + carrier 減衰)
  - v command 有無 = test01 = v なし (= default PART_OFF_VOLUME=15 + fm_volume_hook 未起動) vs test-voice-load = v15 (= hook 起動 + TL=0x40 上書き)

### α-4: agent 4 finding = PMD V4.8s / PMDDotNET / PMDNEO 音量 semantics 比較 (= confidence high)

#### 確定 finding 5 軸

##### 軸 1 = PMD V4.8s FM volume hook trace
- ground truth = `vendor/pmd48s/source/pmd48s/PMD.ASM` (= x86 MASM、 Shift_JIS encoded)
- 主要 routine:
  - `volset` line 4726-4742 = FM 音量設定 entry
  - `volset_slot` macro line 4709-4724 = per-op TL 出力 micro
  - `fmvs` line 4765-4860 = slot mask 解析 + LFO 適用
  - `pmdAsm_4743_voldown` line 4743-4752 = `fm_voldown` global 適用
  - `fm_fade_calc` line 4753-4764 = `fadeout_volume` 50% 乗算
  - `comv` opcode 0xFD = line 1757 dispatch + line 3406-3411 = byte 直接 store
- `volset_slot` 数式 literal:
  ```
  入力: al = ~partWk.volume、 dl = voice TL
  処理: al = clamp(al + dl, ≤ 255)        ; carry → 255 saturate
        al = clamp(al - 0x80, ≥ 0)        ; borrow → 0 saturate
        dl = al                            ; 最終 TL
        opnset                             ; reg 0x40-0x4C 書込
  ```
- semantic = **voice TL は base、 ~vol は additive bias** (= voice 音量設計を保ったまま vol で attenuate)
- v→V 換算 = compile.exe 側で v0-v15 → V byte (= 85-127) compile 時 1 回変換、 driver `comv` は変換せず byte 直接 store

##### 軸 2 = PMDDotNET driver FM volume hook trace
- ground truth = `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` (= x86 MASM の line-by-line C# port)
- 主要 method:
  - `volset()` line 6846-6872 = `volset` 完全 port (= comment「4723-4742」)
  - `volset_slot()` line 6822-6838 = macro 完全 port
  - `fmvs()` line 6924-7028 = `fmvs` 完全 port
  - `comv()` line 4813-4829 = `partWk[di].volume = al` 直接 store
- `vseta()` line 7730-7762 (= compiler side) = `work.bx = mml_seg.fmvol[work.bx]` (= line 7759) で `fmvol[]` table lookup
- `fmvol[]` table = `mml_seg.cs:152-171` = PMD V4.8s `MC.ASM:8274-8290` と byte-identical
- PMD V4.8s からの差分 = **なし** (= line-by-line port、 数式 + table 完全同等)

##### 軸 3 = PMDNEO driver FM volume hook trace
- ground truth = `src/driver/standalone_test.s`
- 主要 routine:
  - `comv` line 3972-4003 = opcode 0xFD handler (= **byte 取得後 2 度目の v→V table lookup 実行 = 二重変換 bug**)
  - `pmdneo_v_to_V_convert` line 3671-3702 = runtime side v→V 変換
  - `v_to_V_fm` line 5703-5704 = FM 用 17-entry table (= PMD V4.8s `fmvol[]` + PMDDotNET `fmvol[]` と byte-identical)
  - `fm_volume_hook` line 4472-4529 = 実 TL register 書込
  - `pmdneo_part_call_volume_hook` line 3922 = hook dispatcher
  - `pmdneo5_init_part` line 3481-3505 = part init、 `c = #0x0F = 15` を `PART_OFF_VOLUME` に store
- `comv` 二重変換問題 line 3972-4003:
  ```
  1. byte 取得 (= compile 済 V value、 例 v15 → 125)
  2. PART_OFF_V_SCALE 加算
  3. cp #17 / clamp 16 → 125 だと 16 に clamp
  4. pmdneo_v_to_V_convert(16) → v_to_V_fm[16] = 127
  5. PART_OFF_VOLUME_SHIFT 適用
  6. PART_OFF_VOLUME(ix) = 127 (= 元値 125 と異なる、 v15 と v16 区別消失)
  ```
- `fm_volume_hook` TL 数式 line 4472-4529:
  ```
  A = PART_OFF_VOLUME (= 0-255 想定だが上で 127 上限)
  srl a                   ; A = vol/2
  A = 0x7F - vol/2         ; TL value
  4 op (= reg 0x40/0x44/0x48/0x4C) 全部に 同 TL を直接書込
  ```
- semantic = **voice TL 完全 replace** (= add でも subtract でもなく、 全 4 op に同 TL 上書き、 voice data の TL field 値無視)

##### 軸 4 = semantic 差分 vs identical
- 差分点 literal 4 件:
  1. 二重 v→V 変換 bug = PMDNEO `comv` line 3984 が compile 済 byte に再 lookup 適用
  2. TL 数式 fundamental 差 = PMD V4.8s/PMDDotNET = additive、 PMDNEO = replace
  3. modulator/carrier 区別なし = PMDNEO は carrier mask 見ず全 4 op 一律
  4. default vol 初期値 = PMDNEO=15 vs PMD V4.8s/PMDDotNET=108
- 影響 dB 推定 (= voice 001 + v15 想定):
  ```
  driver         v15 → VOLUME    TL on op4 (= carrier、 voice TL=0)    dB
  PMD V4.8s      125             ~125 + 0 - 0x80 = 2 (TL=2)            -1.5 dB
  PMDDotNET      125             同 = 2                                -1.5 dB
  PMDNEO         127 (再 lookup) 0x7F - 63 = 64                        -48 dB
  ```

##### 軸 5 = root cause 仮説 A/B/C 評価
- A. PMD V4.8s + PMDDotNET 同 semantics、 PMDNEO で independent rewrite で attenuation curve 過大 = **高 confidence で正しい** (= line-by-line port confirm + PMDNEO 独立実装由来)
- B. 3 driver 同等、 root cause は別 = **否定** (= PMDDotNET と PMD V4.8s line-by-line 等価、 PMDNEO のみ divergence)
- C. PMDDotNET が PMD V4.8s から微小 semantic 変更 + PMDNEO がそれを model に rewrite で compound = **否定** (= PMDDotNET PMD.cs comment 付き完全 port confirm、 PMDNEO divergence は PMDDotNET 模倣由来ではなく独立実装)

#### 修復案 outline (= scope-out detail、 sprint β plan で確定)

- 修復 A = `comv` から `pmdneo_v_to_V_convert` 呼出削除 (= byte 直接 store して PMD V4.8s と同 semantics)
- 修復 B = `fm_volume_hook` を `volset_slot` 数式 port に置換 (= voice TL additive + carrier mask 経由)
- 修復 C = `pmdneo5_init_part` の default vol を 108 (= PMD V4.8s) に変更

### α-5: agent 5 finding = root cause 切り分け framework + allowed-touch/sha256 plan v0 起草 (= confidence high)

#### 確定 framework 5 軸

##### 軸 1 = 5 仮説の driver touch 要否 (= 主軸 synthesis で agent 1-4 finding 反映後の再評価)
- 仮説 A (= fixture voice design 過小) = **REJECT** (= agent 1 軸 5 + agent 3 軸 5 で voice 001 設計妥当 confirm)
- 仮説 B (= driver volume scaling 過大) = **ACCEPT 主因 #1** = driver touch 必須 (= guarded change pattern)
- 仮説 C (= FM TL/volume/expression 解釈ズレ) = **ACCEPT 主因 #2** = driver touch 必須 (= comv 二重変換)
- 仮説 D (= PMDDOTNET vs PMDNEO semantics 差分) = **ACCEPT 主因 #3** = driver touch 必須 (= fm_volume_hook replace 数式)
- 仮説 E (= #FFFile voice data 反映) = **REJECT** (= ADR-0072 β-5-2 reg 0x40=0x11 voice TL exact load confirm)

##### 軸 2 = production sha256 維持戦略
- driver touch 必須 = **guarded change `.if PMDNEO_USE_PMDDOTNET ... .endif` pattern** = production default (= flag-off) で byte-identical
- precedent = ADR-0069 §決定 4 + ADR-0071 §決定 3 + ADR-0072 plan v1-v4 (= revert 済)
- baseline anchor = `457a237c...` (= dashboard production baseline section literal、 ADR-0071 ε Accepted 後)
- historical reference = `b15883fe...` (= ADR-0048〜ADR-0070 era、 immutable 保持)

##### 軸 3 = γ 実装時の 4 build matrix
- (B1) production baseline = `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` → sha256 == `457a237c...` byte-identical
- (B2) post-patch flag-off = (B1) と byte-identical
- (B3) flag-on pre-patch with fixture = ADR-0072 baseline (= voice opcode dispatch 機能あり + volume scaling bug 残存)
- (B4) flag-on post-patch with fixture = (B3) と diff = ADR-0073 patch byte 量のみ + audio audible 改善

##### 軸 4 = allowed-touch 候補 framework
- driver-side fix = `src/driver/standalone_test.s` 関連 routine guarded change (= 決定 4 § literal)
- fixture = `src/test-fixtures/adr-0073/` 新規 (= ADR-0069 §決定 3-d precedent)
- verify script = 新規 (= TL register write trace gate)
- doc + dashboard = 同 pattern

##### 軸 5 = sub-sprint chain plan
- α/β/γ/δ/ε 5 段構成 (= ADR-0067/0068/0069/0071/0072 precedent literal 継承)
- dependency 順序固定 = ADR-0073 ε → ADR-0065 audition material 再開 → ADR-0066 (= 本番 cmd 切替)
- driver patch γ 着手 = **user 明示 GO mandatory point** (= ADR-0072 「driver no-touch mandate」 を覆す pivot)

### α-6: 主軸 synthesis = 5 agent finding 統合 + 真の root cause 確定 + 設計判断 record

#### 5 agent finding 統合結論

agent 1-4 結果の統合で **仮説 A reject 確定**、 root cause = **driver-side 3 件 semantic divergence** (= 主因 B+C+D 統合) = PMDNEO の `comv` 二重変換 + `fm_volume_hook` voice TL replace + per-alg carrier mask 不在 = PMD V4.8s + PMDDotNET の semantics と独立 rewrite divergence。 agent 5 framework draft で「仮説 A highest priority」 推定したが、 agent 1-4 evidence で覆された (= agent 5 framework 起草時点では agent 1-4 finding 未取得、 全 agent 結果統合後の最終評価)。

#### 設計判断 record (= user 明示 mandate carry)

1. **driver touch 必須結論** = ADR-0072 plan v5 で確立した「driver no-touch mandate」 は voice opcode data delivery 範疇に限定された判断、 audio volume scaling 範疇 (= 本 ADR-0073) では別軸 root cause (= driver semantics divergence) のため driver touch pivot 必須
2. **ADR-0041 §決定 5 `design_judgment_needed` escalation 軸該当** = user 明示 GO mandatory point = β plan review approve + γ 着手判断
3. **production sha256 維持 mandate** = `457a237c...` byte-identical 維持 = guarded change `.if PMDNEO_USE_PMDDOTNET` 配下限定で実装
4. **fix A/B/C を sprint α で混ぜない** = 並列 record only、 採用案確定は β plan review iteration で
5. **fix C 単独先行禁止** = default vol 修正のみでは root cause 解消不可能、 fix A+B 必須
6. **user audition 進めない** = δ-5 Layer 1 PASS verify が primary success metric、 user audition は ADR-0065 ε scope
7. **音量問題を threshold calibration だけで済ませない** = 真の root cause = driver semantics divergence、 threshold 緩和では本質解決にならない
8. **production sha256 が変わる driver patch 無断 commit 禁止** = 本 PR1 doc-only、 driver patch は β approve + user 明示 GO 後 γ で commit

## Annex β-1: repair plan v1 (= sprint β round 1 投入 target、 Codex Rescue plan review 対象)

### β-1-1: plan v1 採用案 = fix A + fix B + fix C 全 3 件統合 (= guarded change 配下限定)

| fix | 採用判断 | 根拠 |
|---|---|---|
| **fix A** = `comv` 二重 v→V 変換 削除 | **採用 mandatory** | PMD V4.8s + PMDDotNET の `comv` (= `PMD.ASM:3406-3411` + `PMD.cs:4813-4829`) は byte 直接 store + v_to_V 変換 compile 時 1 回のみ、 PMDNEO `comv` line 3984 `call pmdneo_v_to_V_convert` 二重適用は明らかな bug |
| **fix B** = `fm_volume_hook` を PMD V4.8s `volset_slot` 数式 port + per-alg carrier mask 経由 | **採用 mandatory** | replace 数式 `TL = 0x7F - V/2` は voice TL を完全無視、 全 4 op 一律書込で ALG=0-6 voice 音色設計破壊、 PMD V4.8s `volset_slot` (= `PMD.ASM:4709-4724`) additive + carrier mask の line-by-line port が PMD MML 音量 semantics 完全継承 path |
| **fix C** = `pmdneo5_init_part` default vol 0x0F → 108 guarded override | **採用 conditional** (= fix A 適用後の意味整合性確保) | 現状 default = 0x0F (= 15、 v scale 想定) は `comv` 二重変換 bug と組み合わせで偶然動いていた、 fix A 適用後は byte 直接 store のため default = 15 だと `fm_volume_hook` srl → 7 → TL=0x78 (= -90 dB ≈ mute) で v cmd 不在 fixture 静音化 regression risk、 fix C で default = 108 (= V byte semantics 整合) override が必要 |

### β-1-2: 採用判断の literal 補足

**fix A 単独不可**:
- fix A 適用後の `comv` = byte 直接 store
- byte = PMDDotNET emit `0xFD 0x7A` (= V=125 fmvol[15])
- `fm_volume_hook` 既存数式 `0x7F - V/2 = 0x7F - 62 = 0x41 = -48.75 dB` = 結局 carrier attenuation
- fix B が voice TL additive semantic 復元しない限り audio audible 改善限定的

**fix B 単独不可**:
- fix B 適用後の `fm_volume_hook` = voice TL + ~V additive
- `comv` 二重変換 bug で V byte が常時 127 (= v16 丸め) に丸まる
- `~127 = 0` → voice TL + 0 - 0x80 (saturate) → final TL = voice TL (= 妥当だが v 値段階制御失効)
- fix A が二重変換解消しない限り MML v0-v15 段階制御失効

**fix C 単独不可**:
- fix C のみは fix A/B 未適用で root cause 完全未解消
- default vol 108 にしても `comv` 二重変換 + `fm_volume_hook` replace 数式が voice TL=0 carrier を上書きする bug は残存

**結論**: **fix A + fix B 必須統合 + fix C conditional (= fix A consequence による意味整合性確保)** = sprint γ 着手判断時に **「fix A+B+C 統合実装」 で確定推奨**。

### β-1-3: fix A 実装案 literal

**対象 routine** = `comv` (= `src/driver/standalone_test.s:3972-4003`)、 line range 32 行。

**修正方式** = guarded change `.if PMDNEO_USE_PMDDOTNET` binary toggle (= memory `feedback_sdas_if_no_value_comparison.md` 整合):

```
comv:
        call    pmdneo_part_fetch_byte
.if PMDNEO_USE_PMDDOTNET
        ;; ADR-0073 fix A: PMDDotNET 経路は byte 直接 store (= PMD V4.8s comv:3406-3411 semantic port)
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret
.else
        ;; 既存 PMDNEO 経路 (= v scale 想定の v→V 変換 + V scale shift)
        ld      b, a
        ld      a, PART_OFF_V_SCALE(ix)
        add     a, b
        jp      p, _pmdneo_comv_scale_pos
        xor     a
_pmdneo_comv_scale_pos:
        cp      #17
        jr      c, _pmdneo_comv_scale_ok
        ld      a, #16
_pmdneo_comv_scale_ok:
        call    pmdneo_v_to_V_convert
        ld      b, a
        ld      a, PART_OFF_VOLUME_SHIFT(ix)
        or      a
        jp      p, _pmdneo_comv_shift_pos
        neg
        ld      c, a
        ld      a, b
        sub     c
        jr      nc, _pmdneo_comv_shift_ok
        xor     a
        jr      _pmdneo_comv_shift_ok
_pmdneo_comv_shift_pos:
        add     a, b
        jr      nc, _pmdneo_comv_shift_ok
        ld      a, #0xFF
_pmdneo_comv_shift_ok:
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret
.endif
```

**意義**:
- flag-on (= PMDDotNET 経路) = byte 直接 store + v_to_V_convert 削除 = PMD V4.8s 同 semantics
- flag-off (= production 経路) = 既存 logic 完全保存 = production sha256 `457a237c...` byte-identical 維持

**患部分離 expected diff (= byte 単位)**:
- flag-off binary = byte-identical (= 期待値 0 byte diff)
- flag-on binary = comv routine 短縮 = 推定 ~25 byte 減 (= 既存 ~32 byte → fix 後 ~7 byte 部分)

### β-1-4: fix B 実装案 literal

**対象 routine** = `fm_volume_hook` (= `src/driver/standalone_test.s:4472-4529`)、 line range 58 行。

**修正方式** = guarded change 配下で新規 helper routine `fm_volume_hook_pmddotnet` additive + 既存 `fm_volume_hook` 内 flag dispatch + 新規 `fm_carrier_table` data (= ALG 8 値 mask table、 PMD V4.8s `PMD.ASM:7958-7964` literal port)。

**新規 data table** (= `fm_carrier_table`、 8 byte additive、 0x0610 セクション末尾):

```
fm_carrier_table:
        ;; ADR-0073 fix B: per-ALG carrier slot mask (= PMD V4.8s PMD.ASM:7958-7964 port、 bit 7-4 = OP4/OP3/OP2/OP1 mask)
        .db     0b10000000      ; ALG=0: OP4 のみ carrier
        .db     0b10000000      ; ALG=1: OP4 のみ carrier
        .db     0b10000000      ; ALG=2: OP4 のみ carrier
        .db     0b10000000      ; ALG=3: OP4 のみ carrier
        .db     0b10100000      ; ALG=4: OP4 + OP2 carrier
        .db     0b11100000      ; ALG=5: OP4 + OP3 + OP2 carrier
        .db     0b11100000      ; ALG=6: OP4 + OP3 + OP2 carrier
        .db     0b11110000      ; ALG=7: 全 4 op carrier
```

**新規 helper routine** (= `fm_volume_hook_pmddotnet`、 0x0610 セクション末尾 additive):

```
fm_volume_hook_pmddotnet:
        ;; ADR-0073 fix B: PMD V4.8s volset_slot 数式 port + per-alg carrier mask 経由
        ;; 入力: ix = PART_OFF_*、 PART_OFF_VOLUME(ix) = V byte (= 0-127)
        ;; 副作用: voice data の per-op TL を参照、 carrier op のみ TL register write
        ld      a, PART_OFF_VOLUME(ix)
        call    pmdneo_fade_scale       ; ADR-0050 β: fade factor 乗算 (= 既存経路継承)
        cpl                             ; A = ~V = 0xFF - V (= PMD V4.8s NOT(volume) semantic)
        ld      e, a                    ; E = ~V
        ;; ALG 取得 + carrier mask lookup
        call    pmdneo_get_voice_ptr    ; HL = voice data 先頭 (= 新規 helper、 別途実装 or 既存 ptr 経路再利用)
        ld      a, PART_OFF_FM_ALG(ix)  ; A = ALG (= 0-7、 voice load 時 cache 想定 or voice data 末尾 byte read)
        and     #0x07
        ld      l, a
        ld      h, #0
        ld      bc, fm_carrier_table
        add     hl, bc
        ld      d, (hl)                 ; D = carrier mask (= bit 7-4 = OP4/3/2/1)
        ;; 各 op (= slot 0-3) について carrier mask bit 確認 → voice TL fetch → additive → TL write
        ;; (= 詳細展開は plan v2 以降の fix B 細部詳細化で literal、 概念は PMD V4.8s volset_slot per-op loop port)
        ;; ... (= per-op loop = 4 反復、 各 slot で carrier mask bit & 1 == 1 → voice TL + ~V - 0x80 saturate → ym2610_write_port_*)
        ret
```

**既存 `fm_volume_hook` 修正** (= guarded change dispatch):

```
fm_volume_hook:
.if PMDNEO_USE_PMDDOTNET
        ;; ADR-0073 fix B: PMD V4.8s volset_slot semantics port 経路へ dispatch
        jp      fm_volume_hook_pmddotnet
.else
        ;; 既存 PMDNEO 経路 (= TL replace 数式 + 全 4 op 一律書込、 ALG=7 全 op carrier 想定)
        ld      a, PART_OFF_VOLUME(ix)
        call    pmdneo_fade_scale
        srl     a
        ld      l, a
        ld      a, #0x7F
        sub     l
        ld      c, a
        ;; ... (= 既存 4 op 一律書込 logic 完全保存)
        ret
.endif
```

**意義**:
- flag-on = voice TL additive + per-alg carrier mask 経由 = voice 音色設計保存 + carrier-only TL write
- flag-off = 既存 logic 完全保存 = production sha256 byte-identical 維持

**患部分離 expected diff (= byte 単位)**:
- flag-off binary = byte-identical (= 期待値 0 byte diff)
- flag-on binary = `fm_volume_hook_pmddotnet` additive (= 推定 ~80 byte) + `fm_carrier_table` data (= 8 byte) = 合計 ~88 byte 増

**latent risk**:
- `pmdneo_get_voice_ptr` 経路は plan v2 以降で literal 詳細化必要 (= voice data の格納位置 + ALG byte offset)
- `PART_OFF_FM_ALG` cache offset 新規追加判定 = part_workarea offset extension risk = ADR-0058 v2 PartWork 不可触 mandate 抵触 risk → voice data 末尾 reg 0xB0 byte (= byte index 24) を都度 read する経路推奨

### β-1-5: fix C 実装案 literal

**対象 routine** = `pmdneo5_init_part` (= `src/driver/standalone_test.s:3481-3505`)、 line range 25 行。

**修正方式** = guarded change 配下 PART_OFF_VOLUME store 直前で `c` override:

```
pmdneo5_init_part:
        push    hl
        push    bc
        call    pmdneo_part_ix_from_part
        pop     bc
        pop     hl
        ld      d, a
        ;; ... (= 既存 PART_OFF_ADDR / LOOP / LEN / GATE / TRANSPOSE / FLAGS / OCTAVE init 完全保存)
        ld      PART_OFF_CH_IDX(ix), b
.if PMDNEO_USE_PMDDOTNET
        ;; ADR-0073 fix C: PMD V4.8s default vol 108 (= PMD.ASM:558 mov volume[di],108) port、
        ;; fix A 適用後 byte 直接 store のため v scale 15 → V byte semantics 整合要
        ld      c, #108
.endif
        ld      PART_OFF_VOLUME(ix), c
        ;; ... (= 既存 VOLUME_SHIFT / V_SCALE / chip_type 分岐 完全保存)
```

**意義**:
- flag-on = default vol = 108 (= PMD V4.8s + PMDDotNET 同 default = V byte semantics 整合)
- flag-off = caller 渡し `c = #0x0F = 15` そのまま (= v scale 想定 既存 logic 保存)
- 患部分離 = caller 側 (= line 1093, 1096, 1099, 1172, 1754-1834 等 ~14 site) は touch しない = blast radius 単一 site 内に閉じる

**患部分離 expected diff (= byte 単位)**:
- flag-off binary = byte-identical (= 期待値 0 byte diff)
- flag-on binary = 5 byte 増 (= `ld c, #108` = 2 byte + .if/.endif 0 byte)

### β-1-6: allowed-touch literal (= γ PR3 想定対象 file 確定)

#### 修正対象 (= γ で touch)

- **`src/driver/standalone_test.s`**:
  - line 3481-3505 `pmdneo5_init_part` (= fix C guarded change 5 byte 増 in flag-on)
  - line 3972-4003 `comv` (= fix A guarded change、 既存 logic を `.else` 配下に完全保存)
  - line 4472-4529 `fm_volume_hook` (= fix B guarded change dispatch + 既存 logic を `.else` 配下に完全保存)
  - 0x0610 セクション末尾 (= `fm_carrier_table` 8 byte data + `fm_volume_hook_pmddotnet` ~80 byte routine additive)
- **`src/test-fixtures/adr-0073/`** (= 新規 directory、 ADR-0069 §決定 3-d「新規 fixture MML 例外的許可」 precedent 継承):
  - `test-volume-baseline.mml` (= voice 001 + v15 + l4 c4 等 minimal、 PMDDotNET 経由 build + audio render baseline)
  - `verify-volume-scaling.sh` (= TL register write trace gate + sha256 4 build matrix + audio rms threshold)
- **`docs/adr/0073-pmdneo-driver-fm-volume-scaling-semantics-repair.md`** (= 本 ADR doc、 Annex β-2 以降 fill + 改訂履歴 + 平易要約 update)
- **`docs/parallel-axes-dashboard.md`** (= 0073 行 status update + escalation 履歴 entry append)

#### 不可触対象 (= γ で完全 untouched)

- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不変
- ADR-0026 §決定 3/4 K dispatch L ch 固定占有 完全不変
- ADR-0051 `pmdneo_ssg_tone_sync` (= reg 0x07 RMW 唯一 owner) 完全不変
- ADR-0058 `pmdneo_v2_*` 系 routine body 完全不変
- ADR-0067〜0072 既存 Annex 本文 (= immutable history、 memory `feedback_doc_governance_two_systems.md`) 完全不変
- 既存 verify script (= ADR-0049〜0072 全 verify gate) regression-free
- 既存 fixture MML (= ADR-0067/0068/0069/0072 PR で commit 済) 完全不変
- vendor (= `vendor/pmd48s/` + `vendor/PMDDotNET/` + `vendor/ngdevkit-examples/`) 完全不変
- `src/tools/pmd-mml/compile.py` (= ADR-0072 で touch、 本 ADR-0073 では完全不変 = build-side voice resolution 機能 regression 防止)
- `scripts/build-poc.sh` (= ADR-0072 で touch、 本 ADR-0073 では完全不変)
- `pmdneo5_init_part` の caller 側 (= line 1093, 1096, 1099, 1172, 1754-1834 等 ~14 site の `ld c, #0x0F`) = fix C は単一 site (= init_part 内 guarded override) のみ、 caller side untouched
- `comV` routine (= line 4005-4009) = 既に byte 直接 store の正しい経路、 完全不変
- `pmdneo_v_to_V_convert` (= line 3671-3702) + `v_to_V_fm` table (= line 5703-5704) = 削除しない (= flag-off 経路で使用) = 完全不変
- 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` + scope-out branch `wip-dashboard-coverage` + `docs/dashboard/` untracked + user 別作業 = 完全 untouched

### β-1-7: production sha256 維持戦略 (= 4 build matrix verify)

production sha256 = `457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092` **維持 mandate**、 全 fix は `.if PMDNEO_USE_PMDDOTNET ... .endif` guarded change 配下限定。

#### 4 build matrix (= ADR-0071/0072 precedent literal 継承)

| build | flag | fixture | 期待 sha256 |
|---|---|---|---|
| **(B1) production baseline** | `PMDNEO_USE_PMDDOTNET=0` | no PMDDOTNET_MML | == `457a237c...` byte-identical |
| **(B2) post-patch flag-off** | `PMDNEO_USE_PMDDOTNET=0` + ADR-0073 patch 全適用 | no PMDDOTNET_MML | == (B1) byte-identical (= guarded change flag-off 完全無効化) |
| **(B3) flag-on pre-patch** | `PMDNEO_USE_PMDDOTNET=1` + ADR-0072 ε state (= 本 ADR-0073 patch 未適用) | `src/test-fixtures/adr-0073/test-volume-baseline.mml` 経由 PMDDOTNET_MML | ADR-0072 ε baseline (= sha256 別値、 voice opcode dispatch 機能あり + volume scaling bug 残存 = audio -76 dBFS quiet 期待) |
| **(B4) flag-on post-patch** | `PMDNEO_USE_PMDDOTNET=1` + ADR-0073 patch 全適用 | 同上 | (B3) と diff = ADR-0073 patch byte 量のみ (= 推定 ~70 byte 増 net = fix A: -25 + fix B: +88 + fix C: +5 + 0x0610 セクション末尾 additive) + audio audible 改善 (= wav RMS > -60 dBFS expected) |

#### 検証 command literal (= scripts/build-poc.sh 経由)

```
# (B1) production baseline
PMDNEO_USE_PMDDOTNET=0 scripts/build-poc.sh
sha256sum build/ipl/rom.p1  # expected: 457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092

# (B2) post-patch flag-off byte-identical
PMDNEO_USE_PMDDOTNET=0 scripts/build-poc.sh
sha256sum build/ipl/rom.p1  # expected: 同上 byte-identical

# (B3) flag-on pre-patch (= ADR-0072 ε state)
PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=src/test-fixtures/adr-0073/test-volume-baseline.mml scripts/build-poc.sh
sha256sum build/ipl/rom.p1  # ADR-0072 ε baseline 記録 = 別値

# (B4) flag-on post-patch (= ADR-0073 patch 全適用)
PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=src/test-fixtures/adr-0073/test-volume-baseline.mml scripts/build-poc.sh
sha256sum build/ipl/rom.p1  # (B3) と diff = ADR-0073 patch byte 量のみ
diff <(z80dasm build/ipl/rom.p1) <(z80dasm <B3 build/ipl/rom.p1>)  # 患部 routine のみ diff
```

#### `.lst` predicate (= 4 件、 ADR-0071/0072 precedent 継承)

- predicate 1 = `fm_carrier_table` symbol assemble PASS (= 0x0610 セクション末尾配置確認)
- predicate 2 = `fm_volume_hook_pmddotnet` symbol assemble PASS (= 同上)
- predicate 3 = 既存 `comv` / `fm_volume_hook` / `pmdneo5_init_part` routine body の `.else` 配下が byte-identical 維持 (= production 経路保護)
- predicate 4 = 既存 symbol table 順序不変 (= `comv` / `fm_volume_hook` / `pmdneo5_init_part` / `pmdneo_v_to_V_convert` / `v_to_V_fm` / `comV` 全 symbol 維持)

### β-1-8: verify gate literal (= γ build verify + δ functional verify)

#### γ build verify (= production sha256 維持 + 4 build matrix PASS)

- gate γ-1: 4 build matrix B1-B4 PASS (= β-1-7 §)
- gate γ-2: production sha256 `457a237c...` byte-identical 維持 (= (B1)/(B2) で)
- gate γ-3: `.lst` predicate 4 件 PASS (= β-1-7 §)
- gate γ-4: ADR-0051 owner contract untouched (= `pmdneo_ssg_tone_sync` 完全不変、 reg 0x07 RMW 唯一 owner 維持)
- gate γ-5: 既存 verify script ALL PASS (= ADR-0049〜0072 regression-free = 18+ verify script transitively)

#### δ functional verify (= 実音成立確認 + ADR-0072 機能 regression 防止)

- gate δ-1: voice register trace = MAME ymfm-trace `reg 0x40/0x44/0x48/0x4C` write timeline 確認 = voice 001 OP4 (= reg 0x4C) carrier TL=0 (= max output) 維持 post-`fm_volume_hook_pmddotnet` (= fix B 経路、 carrier-only write 確認)
- gate δ-2: modulator TL untouched = voice 001 OP1/OP2/OP3 (= reg 0x40/0x44/0x48) TL=17/25/38 (= voice data exact 値) post-`fm_volume_hook_pmddotnet` (= fix B carrier mask 経路、 modulator 上書き発生せず)
- gate δ-3: voice opcode dispatch regression-free (= ADR-0072 既存機能 regression 防止 = `comat` routine + voice_table 1-based offset + #FFFile support all functional、 voice 001 TL=0x11/0x19 voice data load 確認)
- gate δ-4: 既存 18+ verify script regression-free (= ADR-0049〜0072 全 verify gate transitively PASS、 ADR-0071/0072 δ verify pattern 継承)
- gate **δ-5: `scripts/analyze-audition-wav.py` engineering gate 4 層 ALL PASS** = **特に Layer 1 WAV hygiene = wav RMS > -60 dBFS で audio audible confirm** = **primary success metric** (= ADR-0072 ε -76 dBFS quiet の根本治療 confirm)
- gate δ-6: ADR-0050 fade factor 経路継承 = `pmdneo_fade_scale` (= fade_level=64 passthrough) 経路 untouched 確認 = ADR-0050 β fade scale 経路 regression-free
- gate δ-7: MML v0-v15 段階制御回復確認 = test fixture で v0 → ほぼ silent / v8 → 中庸 / v15 → max output に対応する TL register trace + audio RMS dBFS 段階性確認 (= fix A 二重変換解消 evidence)

### β-1-9: rollback condition (= sprint α §決定 6 17 condition 継承 + β plan v1 refinement)

ADR-0071 §決定 6 11 condition + ADR-0072 §決定 6 #12/#13 + sprint α §決定 6 #14/#15/#16/#17 = 計 17 condition **完全継承**。

β plan v1 refinement (= γ impl 時の trigger 条件具体化):

- **#14 audio audible regression on default voice trigger 具体化** = ADR-0073 γ impl 後 既存 `src/test-fixtures/adr-0072/test-voice-load.mml` で `scripts/analyze-audition-wav.py` Layer 1 rms 悪化 (= ADR-0072 ε -76 dBFS より更に低下、 例えば -80 dBFS) → 即 sub-sprint halt + revert + design 再評価
- **#15 δ-5 Layer 1 FAIL on ADR-0073 new fixture trigger 具体化** = `src/test-fixtures/adr-0073/test-volume-baseline.mml` Layer 1 rms ≤ -60 dBFS = primary success metric 未達 → 1 retry → 再 FAIL なら sub-sprint halt + 仮説 priority 再評価
- **#16 ADR-0072 既存機能 regression trigger 具体化** = ADR-0073 γ impl 後 MAME ymfm-trace で `reg 0x40 = 0x11` (= voice 001 OP1 TL=17 exact load、 ADR-0072 ε で確認済 baseline) が消失 or `voice_table[1] = voice0_data` 1-based offset 経路 broken → 即 sub-sprint halt + revert + ADR-0072 ε state baseline 再確認
- **#17 fix A/B/C 単独実装の追加 finding 由来 pivot 必要性発覚 trigger 具体化** = β plan iteration で fix A+B+C 統合適用 (= 本 plan v1) では root cause 解消不可能と判明時 (= 例: fix B 内 `pmdneo_get_voice_ptr` 経路実装不可能 finding) → user 明示 GO 必須 + 別 fix path 採用判断 (= main agent 自走では実施しない)

#### 共通原則 (= ADR-0069 §決定 5 + ADR-0071 §決定 6 + ADR-0072 §決定 6 + sprint α §決定 6 完全継承)

- 軽微 fix-up (= condition #2 / #4 / #8a / #8b) = 連鎖 commit fix-up
- sub-sprint 単位 halt (= condition #1 / #3 / #5 / #6 / #7 / #9 / #14 / #15 / #16) = ADR-0065 β PR3 halt precedent 同形
- ADR-0073 全体 halt (= condition #10 / #17) = Draft 維持 + 全 sub-sprint rollback record + 後続 ADR dependency update
- **destructive git 操作禁止** = `git reset --hard` / `git push --force` / `git checkout --` 等は user 明示なし禁止、 `git revert` のみ採用

### β-1-10: Codex Rescue plan review 重点軸 (= sprint β round 1 投入 mandate)

| 軸 | scope literal |
|---|---|
| **AXIS-R1: root cause correctness** | sprint α Annex α-1〜α-6 確定 root cause 3 件 + (+) default vol mismatch が plan v1 fix A/B/C で **完全 cover** + literal source 整合 (= driver source / PMD V4.8s / PMDDotNET ground truth literal) |
| **AXIS-R2: fix correctness (= 3 件統合妥当性)** | fix A 単独不可 + fix B 単独不可 + fix C conditional 論理 (= β-1-2 §) が妥当 + PMD V4.8s `volset_slot` 数式 + carrier mask 経路 port が PMD MML 音量 semantics 完全継承 path |
| **AXIS-R3: allowed-touch limited** | γ で touch する file が `src/driver/standalone_test.s` 3 routine guarded change + 0x0610 セクション末尾 additive + 新規 fixture + 新規 verify script + doc/dashboard のみ + 不可触対象 全 untouched mandate 反映 |
| **AXIS-R4: sha256 維持可否** | guarded change `.if PMDNEO_USE_PMDDOTNET ... .endif` 配下限定 + flag-off byte-identical 保証 + 4 build matrix B1-B4 spec + .lst predicate 4 件 + production baseline `457a237c...` 維持 mandate |
| **AXIS-R5: ADR-0072 既存機能 regression 防止** | δ-3 gate (= voice opcode dispatch + voice_table 1-based offset + #FFFile support functional 維持) + #16 rollback condition trigger 具体化 + ADR-0072 で touch した compile.py + build-poc.sh は本 ADR-0073 で完全不変 mandate |
| **AXIS-R6: fix B implementation feasibility** | `pmdneo_get_voice_ptr` 経路 + `PART_OFF_FM_ALG` cache offset 新規追加 vs voice data 末尾 reg 0xB0 都度 read + per-op loop 詳細展開 + carrier mask bit & 1 == 1 → voice TL + ~V - 0x80 saturate → ym2610_write_port_* logic feasibility (= ADR-0058 v2 PartWork 不可触 mandate 抵触なし) |
| **AXIS-R7: verify gate executability** | δ-1〜δ-7 gate spec が MAME ymfm-trace + analyze-audition-wav.py + 既存 verify script で機械実行可能 + γ-1〜γ-5 build verify spec が scripts/build-poc.sh + z80dasm で機械実行可能 |
| **AXIS-R8: rollback condition triggerability** | 17 condition + β plan v1 refinement #14/#15/#16/#17 trigger 具体化が γ impl 後 machine-detect 可能 + sub-sprint halt + revert 手順 literal |

#### Codex Rescue review-only mandate 6 件 (= 冒頭 literal 強調)

1. no commit
2. no file change
3. no branch
4. no merge
5. no GitHub write
6. return judgment + findings only (= approve / revise + must-fix / nice-to-have / latent-risk + per-axis verdict)

placeholder response (= 「バックグラウンドで実行中です」 等) 禁止 = 機械復旧 rule cancel + 1 retry 適用 (= memory `feedback_long_running_hang_auto_recovery_rule.md` + `feedback_codex_rescue_always_monitor.md`)。

## Annex β-2: repair plan v2 (= sprint β round 1 Codex revise 反映 + must-fix 4 + nh 2 + lr 2 全反映、 round 2 投入 target、 plan v1 supersede)

### β-2-0: round 1 Codex Rescue plan review 結果 + plan v1 supersede pointer

**round 1 (= agentId `a5f9c31df62103a6a`、 elapsed 約 4m 31s) judgment = revise** + 4 must-fix + 2 nice-to-have + 2 latent-risk + 越権操作なし confirmed:

| 軸 | 結果 |
|---|---|
| AXIS-R1 root cause correctness | PASS |
| AXIS-R2 fix correctness 3 件統合妥当性 | **FAIL** (= MF-1) |
| AXIS-R3 allowed-touch limited | **FAIL** (= MF-2) |
| AXIS-R4 sha256 維持可否 | **FAIL** (= MF-3) |
| AXIS-R5 ADR-0072 既存機能 regression 防止 | PASS |
| AXIS-R6 fix B implementation feasibility | **FAIL** (= MF-2 carry) |
| AXIS-R7 verify gate executability | **FAIL** (= MF-4) |
| AXIS-R8 rollback condition triggerability | **FAIL** (= #15/#17 carry) |

**plan v1 supersede**: 本 Annex β-2 plan v2 が plan v1 (= Annex β-1) を **完全 supersede** (= memory `feedback_doc_governance_two_systems.md` immutable history mandate 整合 = plan v1 は immutable carry、 本 plan v2 が round 1 finding 反映 ground truth)。

### β-2-1: plan v2 = round 1 must-fix 4 件反映 + fix A+B+C 統合採用 carry

| MF | 反映内容 | 該当 sub-section |
|---|---|---|
| **MF-1** = fix C FM part 限定 | `pmdneo5_init_part` 内 `ld c, #108` override を chip_type=FM 判定後限定 (= `cp #PART_SSG1` 経由分岐、 SSG/PCM/ADPCM-A/Rhythm/FM3EXT untouched) | β-2-4 |
| **MF-2** = fix B voice data 再取得設計 | SRAM 0xFD62-0xFD6D (= 12 byte free region) 内 FM 6 ch 用 voice ptr cache 配置 + `comat` 内 voice ptr 保存追加 + `fm_volume_hook_pmddotnet` 内 ch_idx → ptr lookup、 `PART_OFF_INSTRUMENT` 流用回避 (= LR-1 mitigation)、 ADR-0058 v2 PartWork 不可触 mandate 抵触なし、 allowed-touch 拡張 = `comat` も guarded change touch 対象 | β-2-3 / β-2-5 |
| **MF-3** = sha256 target artifact 修正 | `build/ipl/rom.p1` ❌ → **`vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1`** ✅ (= main agent 直接 verify confirmed = `457a237c...` 完全一致) | β-2-6 |
| **MF-4** = verify command 実行可能化 | B1-B4 sha256 + diff + δ-5 WAV RMS + δ-7 v0-v15 trace/RMS の executor literal command 固定 (= placeholder なし) | β-2-7 |

### β-2-2: fix A 実装案 v2 (= plan v1 β-1-3 unchanged literal carry、 supersede pointer only)

plan v1 β-1-3 `comv` (= line 3972-4003) guarded change literal は **plan v2 で完全保持** (= `.if PMDNEO_USE_PMDDOTNET` 配下 byte 直接 store + `.else` 配下既存 logic 完全保存)。 must-fix 影響なし、 carry。

### β-2-3: fix B 実装案 v2 (= round 1 MF-2 + AXIS-R6 反映 = voice ptr cache 設計確定)

**SRAM voice ptr cache 配置** (= 新規 equ 7 件、 PMDDOTNET 経路限定):

```
;; ADR-0073 fix B v2 (= MF-2 反映): FM ch 別 current voice ptr cache、
;; 0xFD62-0xFD6D (= 12 byte) free region 占有、 PMDDOTNET 経路限定 (= guarded change 配下)
.equ    driver_pmddotnet_fm_voice_ptr_ch0,  0xFD62
.equ    driver_pmddotnet_fm_voice_ptr_ch1,  0xFD64
.equ    driver_pmddotnet_fm_voice_ptr_ch2,  0xFD66
.equ    driver_pmddotnet_fm_voice_ptr_ch3,  0xFD68
.equ    driver_pmddotnet_fm_voice_ptr_ch4,  0xFD6A
.equ    driver_pmddotnet_fm_voice_ptr_ch5,  0xFD6C
.equ    driver_pmddotnet_fm_voice_ptr_base, 0xFD62
```

**SRAM 占有 verify** (= main agent 直接 confirm):
- 既存 SRAM map = 0xFD20-0xFD61 (= PNE + ppc_scratch + audition + v2 markers + adpcmb_shim + ppc_bit7_scratch) + 0xFD79+ (= pmdneo_v2_partwork_base)
- **0xFD62-0xFD78 = 23 byte free region** (= ADR-0072 plan v3 driver-side fix 全 revert で未使用)
- 12 byte 占有 (= 0xFD62-0xFD6D) で 11 byte 残余 (= 0xFD6E-0xFD78) carry

**`comat` 内 voice ptr 保存追加** (= line 4419-4439 への guarded change additive、 FM path 限定):

```
comat:
        call    pmdneo_part_fetch_byte    ; A = voice index (0-based)
        ld      c, a
        ld      a, PART_OFF_CHIP_TYPE(ix)
        cp      #2
        jp      z, comat_pcm
        or      a
        jp      nz, comat_done
        ld      l, c
        ld      h, #0
        add     hl, hl
        ld      de, #voice_table
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl                    ; HL = voiceN_data address
.if PMDNEO_USE_PMDDOTNET
        ;; ADR-0073 fix B v2: FM ch 別 voice ptr cache 保存
        push    hl
        ld      a, PART_OFF_CH_IDX(ix)
        cp      #6                        ; FM ch 0-5 のみ cache
        jr      nc, _pmdneo_comat_no_cache
        sla     a                         ; A = ch_idx * 2
        ld      c, a
        ld      b, #0
        ld      hl, #driver_pmddotnet_fm_voice_ptr_base
        add     hl, bc                    ; HL = cache addr
        pop     de                        ; DE = voice ptr
        ld      (hl), e
        inc     hl
        ld      (hl), d
        ex      de, hl                    ; HL = voice ptr 復元
        jr      _pmdneo_comat_set
_pmdneo_comat_no_cache:
        pop     hl
_pmdneo_comat_set:
.endif
        ld      b, PART_OFF_CH_IDX(ix)
        call    pmdneo_fm_voice_set
comat_done:
        ret
```

**`fm_volume_hook_pmddotnet` 内 voice ptr 再取得 logic** (= plan v1 β-1-4 refinement、 概念展開):

- step 1: PART_OFF_CH_IDX → cache addr lookup (= base + ch_idx*2)
- step 2: cache addr → DE = voice ptr 復元
- step 3: voice ptr + 24 → reg 0xB0 byte (ALG/FBL) fetch → A = ALG (0-7)
- step 4: fm_carrier_table[ALG] → carrier mask (= bit 7-4 = OP4/3/2/1)
- step 5: PART_OFF_VOLUME → pmdneo_fade_scale (= ADR-0050 β passthrough) → ~V (= cpl)
- step 6: per-op unrolled loop (slot 0-3) = mask bit 確認 → voice TL fetch (= voice ptr + 4 + slot) → additive (= voice TL + ~V - 0x80 saturate) → ym2610_write_port_* (reg 0x40 + slot*4 + ch index、 ch < 3 → port A、 ch >= 3 → port B)

**詳細 Z80 assembly literal** は γ impl 時に展開 (= plan v2 では概念 + ~120 byte 推定で acknowledge、 γ 時に refine)。

**LR-1 mitigation**:
- `PART_OFF_INSTRUMENT` (= offset 31、 ADPCM-A voice idx) **流用しない** = SRAM 0xFD62-0xFD6D 別領域採用で semantic 混同回避 confirmed

**LR-2 acknowledge**:
- fix A で PMDDotNET path `PART_OFF_V_SCALE` / `PART_OFF_VOLUME_SHIFT` bypass = `comvshift_up/down` (= line 4011-4037) は本 ADR-0073 で touch しない
- δ-7 内に v+/v- emit verify gate 追加 (= LR-2 mitigation) = `bash scripts/build-poc.sh --emit-bytes-only src/test-fixtures/adr-0073/test-v-shift-coverage.mml | grep -E "0xDE\|0xDD"` で emit 確認、 emit あれば #18 rollback condition trigger (= γ scope 拡張 user 明示 GO 必須)、 emit なければ scope-out OK

**patch byte estimate v2** (= NH-2 反映):
- fix A: ~25 byte 減
- fix B: `fm_volume_hook_pmddotnet` ~120 byte + `fm_carrier_table` 8 byte = ~128 byte 増
- fix B comat additive: ~25 byte 増
- fix C: ~8 byte 増 (= chip_type 判定込み)
- 新規 SRAM equ: 0 byte (= equ は size 占有なし、 cache 実体は 12 byte SRAM 占有)
- **合計 patch byte 量推定 = ~136 byte 増 net** (= plan v1 70 byte 推定から +66 byte 増)

### β-2-4: fix C 実装案 v2 (= round 1 MF-1 反映 = FM part 限定)

**修正方式** = `pmdneo5_init_part` line 3481-3505 内 PART_OFF_VOLUME store 直前に **chip_type=FM 先行判定**:

```
pmdneo5_init_part:
        push    hl
        push    bc
        call    pmdneo_part_ix_from_part
        pop     bc
        pop     hl
        ld      d, a                      ; D = part_id
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        xor     a
        ld      PART_OFF_LOOP(ix), a
        ld      PART_OFF_LOOP+1(ix), a
        ld      PART_OFF_LEN(ix), a
        ld      PART_OFF_GATE(ix), a
        ld      PART_OFF_TRANSPOSE(ix), a
        ld      PART_OFF_FLAGS(ix), a
        ld      a, #4
        ld      PART_OFF_OCTAVE(ix), a
        ld      PART_OFF_CH_IDX(ix), b
.if PMDNEO_USE_PMDDOTNET
        ;; ADR-0073 fix C v2 (= MF-1 反映): FM part 限定 default vol 108、
        ;; SSG/PCM/ADPCM-A/Rhythm/FM3EXT は caller 渡し c carry
        ld      a, d                      ; A = part_id
        cp      #PART_SSG1                ; part_id < 6 (= FM1-FM6) のみ override
        jr      nc, _pmdneo5_init_part_vol_default
        ld      c, #108                   ; FM default vol 108 (= PMD V4.8s PMD.ASM:558 port)
_pmdneo5_init_part_vol_default:
.endif
        ld      PART_OFF_VOLUME(ix), c
        xor     a
        ld      PART_OFF_VOLUME_SHIFT(ix), a
        ld      PART_OFF_V_SCALE(ix), a
        ld      a, d
        ;; ... (= 既存 chip_type 分岐 完全保存)
```

**注意**:
- `PART_FM1`〜`PART_FM6` (= 0-5) = `cp #PART_SSG1=6` で `jr nc` 経由 FM 確定、 override 適用
- `PART_SSG1`〜`PART_PCM` (= 6-9)、 `PART_PCMA_K`〜`PART_PCMA_Q` (= 10-16)、 `PART_FM3EXT_X`〜`PART_FM3EXT_Z` (= 17-19) = `jr nc` で skip、 caller 渡し `c=#0x0F` carry
- FM3EXT は ADR-0006 §H literal で「当面 mute」 + chip_type=FM 扱いだが volume 影響なし (= mute)、 override 不要

**patch byte 量推定**: 8 byte 増 (= ld a,d + cp #6 + jr nc + ld c,#108 + label)

### β-2-5: allowed-touch literal v2 (= round 1 MF-2 反映 = fix B comat scope 拡張)

#### 修正対象 (= γ で touch)

- **`src/driver/standalone_test.s`**:
  - line 3481-3505 `pmdneo5_init_part` (= fix C v2 guarded change ~8 byte 増 in flag-on)
  - line 3972-4003 `comv` (= fix A guarded change、 plan v1 unchanged)
  - **line 4419-4439 `comat`** (= fix B v2 新規 scope = guarded change additive voice ptr cache 保存 ~25 byte 増 in flag-on)
  - line 4472-4529 `fm_volume_hook` (= fix B guarded change dispatch、 plan v1 unchanged)
  - 0x0610 セクション末尾 (= `fm_carrier_table` 8 byte + `fm_volume_hook_pmddotnet` ~120 byte additive)
  - SRAM equ 新規 7 件 (= `driver_pmddotnet_fm_voice_ptr_chN` × 6 + base、 0xFD62-0xFD6D = 12 byte 占有 in PMDDOTNET 経路)
- **`src/test-fixtures/adr-0073/`** (= 新規 directory):
  - `test-volume-baseline.mml`
  - `test-v-shift-coverage.mml` (= LR-2 mitigation gate fixture)
  - `verify-volume-scaling.sh` (= 4 build matrix + TL trace + audio rms threshold gate)
- `docs/adr/0073-pmdneo-driver-fm-volume-scaling-semantics-repair.md` (= 本 ADR doc maintenance)
- `docs/parallel-axes-dashboard.md` (= 0073 行 + escalation 履歴)

#### 不可触対象 (= plan v1 β-1-6 carry + plan v2 追加)

plan v1 β-1-6 不可触 list **完全 carry** + 追加:
- `PART_OFF_INSTRUMENT` (= offset 31、 ADPCM-A voice idx) 完全不変 (= LR-1 mitigation)
- `comvshift_up` / `comvshift_down` / `comvscale_up` / `comvscale_down` (= line 4011-4048) **完全不変** (= LR-2 scope-out、 verify gate で coverage 確認のみ)
- `pmdneo_fm_voice_set` (= line 1315 周辺) 完全不変 (= fix B は新規 hook additive で対応)

### β-2-6: production sha256 維持戦略 v2 (= round 1 MF-3 反映 = artifact path 修正)

production sha256 = `457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092` **維持 mandate**、 active artifact = **`vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1`** (= main agent 直接 verify、 plan v1 `build/ipl/rom.p1` 誤りを fix)。

#### 4 build matrix verify (= MF-3 + MF-4 反映)

| build | flag | fixture | 期待 sha256 |
|---|---|---|---|
| **(B1) production baseline** | `PMDNEO_USE_PMDDOTNET=0` | no PMDDOTNET_MML | == `457a237c...` byte-identical |
| **(B2) post-patch flag-off** | `PMDNEO_USE_PMDDOTNET=0` + ADR-0073 patch 全適用 | no PMDDOTNET_MML | == (B1) byte-identical |
| **(B3) flag-on pre-patch** | `PMDNEO_USE_PMDDOTNET=1` + ADR-0072 ε state | `src/test-fixtures/adr-0073/test-volume-baseline.mml` | ADR-0072 ε baseline (= 別値、 γ impl 時記録) |
| **(B4) flag-on post-patch** | `PMDNEO_USE_PMDDOTNET=1` + ADR-0073 patch 全適用 | 同上 | (B3) と diff = ADR-0073 patch byte のみ |

#### 検証 command literal v2 (= 全 placeholder 排除、 機械実行可能)

```bash
# (B1) production baseline
make -C vendor/ngdevkit-examples/00-template clean
PMDNEO_USE_PMDDOTNET=0 scripts/build-poc.sh
sha256sum vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1
# 期待 = 457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092

# (B2) post-patch flag-off byte-identical
make -C vendor/ngdevkit-examples/00-template clean
PMDNEO_USE_PMDDOTNET=0 scripts/build-poc.sh
sha256sum vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1
# 期待 = (B1) と byte-identical

# (B3) flag-on pre-patch (= γ impl 前に ADR-0072 ε state で record)
make -C vendor/ngdevkit-examples/00-template clean
PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=src/test-fixtures/adr-0073/test-volume-baseline.mml scripts/build-poc.sh
sha256sum vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1 > /tmp/adr-0073-b3-sha256.txt
cp vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1 /tmp/adr-0073-b3.m1

# (B4) flag-on post-patch
make -C vendor/ngdevkit-examples/00-template clean
PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=src/test-fixtures/adr-0073/test-volume-baseline.mml scripts/build-poc.sh
sha256sum vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1 > /tmp/adr-0073-b4-sha256.txt

# (B3) vs (B4) diff (= 患部 routine のみ確認)
z80dasm /tmp/adr-0073-b3.m1 > /tmp/adr-0073-b3.asm
z80dasm vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1 > /tmp/adr-0073-b4.asm
diff /tmp/adr-0073-b3.asm /tmp/adr-0073-b4.asm
# 期待 = comv + comat + fm_volume_hook + pmdneo5_init_part + fm_carrier_table + fm_volume_hook_pmddotnet のみ diff
```

#### `.lst` predicate v2 (= 5 件、 plan v1 4 件 + voice ptr cache predicate 追加)

- predicate 1 = `fm_carrier_table` symbol assemble PASS + 0x0610 セクション末尾配置確認
- predicate 2 = `fm_volume_hook_pmddotnet` symbol assemble PASS
- predicate 3 = 新規 SRAM equ 7 件 assemble PASS
- predicate 4 = 既存 `comv` / `fm_volume_hook` / `pmdneo5_init_part` / `comat` routine body の `.else` 配下 byte-identical 維持
- predicate 5 = 既存 symbol table 順序不変

### β-2-7: verify gate literal v2 (= round 1 MF-4 反映 = executor command 固定)

#### γ build verify (= plan v1 β-1-8 unchanged + sha256 artifact path 修正)

- gate γ-1〜γ-5 (= plan v1 carry + sha256 artifact 修正 + .lst predicate 5 件)

#### δ functional verify literal command (= 各 gate executor 経路固定)

- **gate δ-1**: voice register TL trace
  ```bash
  mame -seconds_to_run 5 -trace /tmp/adr-0073-d1-ymfm.tsv neogeo
  grep -E "^[0-9]+\s+A\s+4C" /tmp/adr-0073-d1-ymfm.tsv | head -10
  # 期待 = reg 0x4C (OP4 carrier) = 0x00 (= voice 001 TL=0 max output 維持)
  ```
- **gate δ-2**: modulator TL voice data exact 維持
  ```bash
  grep -E "^[0-9]+\s+A\s+(40|44|48)\s" /tmp/adr-0073-d1-ymfm.tsv | head -10
  # 期待 = reg 0x40=0x11 (OP1 TL=17) + reg 0x44=0x19 (OP2 TL=25) + reg 0x48=0x26 (OP3 TL=38)
  ```
- **gate δ-3**: ADR-0072 既存機能 voice opcode dispatch regression-free
  ```bash
  # voice 001 load 経路 confirm (= ADR-0072 ε baseline と同 trace)
  diff <(grep -E "^[0-9]+\s+A\s+(30|40|50|60|70|80|B0)" /tmp/adr-0073-d1-ymfm.tsv) <(grep -E "^[0-9]+\s+A\s+(30|40|50|60|70|80|B0)" /tmp/adr-0072-eps-ymfm.tsv)
  # 期待 = voice load 経路 trace は ADR-0072 ε baseline と一致 (= modulator/carrier 計算の追加 write のみ post-hook で差分)
  ```
- **gate δ-4**: 既存 18+ verify script regression-free
  ```bash
  for sh in $(find src/test-fixtures -name "verify-*.sh" -path "*adr-00[0-9][0-9]*"); do
      bash "$sh" || echo "FAIL: $sh"
  done
  # 期待 = ALL PASS (= ADR-0049〜0072 全 verify gate)
  ```
- **gate δ-5 (= primary success metric)**: `scripts/analyze-audition-wav.py` engineering gate 4 層 ALL PASS
  ```bash
  mame -seconds_to_run 5 -wavwrite /tmp/adr-0073-d5.wav neogeo
  python3 scripts/analyze-audition-wav.py /tmp/adr-0073-d5.wav --layer 1
  # 期待 = Layer 1 PASS = wav RMS > -60 dBFS (= ADR-0072 ε -76 dBFS の根本治療 confirm)
  # JSON output 全 4 layer = pass mandate
  ```
- **gate δ-6**: ADR-0050 fade factor 経路継承
  ```bash
  # fade_level memory probe (= MAME debugger 経由 or z80-mem-trace)
  # 期待 = pmdneo_v2_fade_level (= 0xFD39) = 64 (= 無減衰) 維持
  ```
- **gate δ-7**: MML v0-v15 段階制御回復確認 + v+/v- coverage gate (= LR-2 mitigation)
  ```bash
  for v in 0 8 15; do
      sed "s/v15/v${v}/" src/test-fixtures/adr-0073/test-volume-baseline.mml > /tmp/adr-0073-v${v}.mml
      make -C vendor/ngdevkit-examples/00-template clean
      PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=/tmp/adr-0073-v${v}.mml scripts/build-poc.sh
      mame -seconds_to_run 3 -wavwrite /tmp/adr-0073-d7-v${v}.wav neogeo
      python3 scripts/analyze-audition-wav.py /tmp/adr-0073-d7-v${v}.wav --layer 1 --rms-only
  done
  # 期待 = v0 ≈ -90 dBFS / v8 ≈ -30〜-40 dBFS / v15 ≈ -10 dBFS (= 段階性)
  # v+/v- emit coverage check
  bash scripts/build-poc.sh --emit-bytes-only src/test-fixtures/adr-0073/test-v-shift-coverage.mml | grep -E "0xDE|0xDD"
  # 期待 = emit なし (= PMDDotNET 経路で v+/v- 未使用) → LR-2 scope-out OK
  # 期待 = emit あり → #18 rollback condition trigger (= γ scope 拡張 user 明示 GO 必須)
  ```

### β-2-8: rollback condition v2 (= plan v1 β-1-9 unchanged + plan v2 #18 追加)

plan v1 β-1-9 17 condition + refinement trigger **完全 carry** + 1 condition 追加:

| # | trigger 具体化 |
|---|---|
| **#14** | audio audible regression on default voice = `test-voice-load.mml` Layer 1 rms 悪化 → 即 halt + revert |
| **#15** | δ-5 Layer 1 FAIL on `test-volume-baseline.mml` = wav RMS ≤ -60 dBFS、 1 retry → 再 FAIL なら halt |
| **#16** | ADR-0072 既存機能 regression = `reg 0x40=0x11` 消失 or `voice_table[1]` 経路 broken → 即 halt + revert |
| **#17** | fix A+B+C 統合不可 finding 由来 pivot = γ impl で voice ptr cache 設計欠陥 or per-op loop 実装不可能 finding → user 明示 GO 必須 |
| **#18 (new)** | LR-2 v+/v- coverage FAIL = δ-7 で PMDDotNET 経路 `0xDE`/`0xDD` opcode emit 確認 + `comvshift_*` saturate 未対応で regression → γ scope 拡張 user 明示 GO 必須 |

**合計 18 condition** + 4 段 stop action + 3 段 responsibility + destructive git 禁止 (= `git revert` のみ)。

### β-2-9: Annex β-3 / β-4 / β-5 placeholder 整理 (= round 1 NH-1 反映)

旧 plan v1 末尾の `## Annex β-2 / β-3 / β-4 / β-5: placeholder` 重複 header (= 2 件) は本 plan v2 で `## Annex β-2` literal fill した結果 supersede。 後続 round 3/4/5 用 placeholder は **単一化** = `## Annex β-3 / β-4 / β-5: placeholder (= sprint β round 3/4/5 iteration、 fill 予定)`。

### β-2-10: Codex Rescue plan review round 2 投入 mandate

#### round 2 重点 review 軸 (= plan v1 8 軸 carry + plan v2 反映確認軸 追加)

- AXIS-R1〜R8 (= plan v1 carry)
- **AXIS-R9 (= 新規)**: round 1 must-fix 4 + nh 2 + lr 2 全反映 confirm
  - MF-1 fix C FM part 限定 = β-2-4 §
  - MF-2 fix B voice data 再取得設計 (= SRAM cache + comat 保存 + helper lookup) = β-2-3 / β-2-5 §
  - MF-3 sha256 artifact path = β-2-6 §
  - MF-4 verify command literal = β-2-7 §
  - NH-1 placeholder header 整理 = β-2-9 §
  - NH-2 fix B byte estimate (= ~136 byte 増 net) = β-2-3 §
  - LR-1 `PART_OFF_INSTRUMENT` 流用回避 (= SRAM 別領域) = β-2-3 §
  - LR-2 v+/v- coverage acknowledge (= #18 condition + δ-7 emit verify) = β-2-7 / β-2-8 §

#### review-only mandate 6 件 literal carry (= round 1 同)

## Annex β-3 / β-4 / β-5: placeholder (= sprint β round 3/4/5 iteration、 fill 予定)

## 改訂履歴

- 2026-05-27: ADR-0073 起票 (= sprint α 完走 + Annex α 6 sub-section literal record + Annex β-1 plan v1 placeholder) = Draft、 起票者: 越川将人 (= 主軸 Claude Code 経由)、 PR1 doc-only sprint = 5 並走 sub-agent investigation 5/5 success + 真の root cause 3 件 confirm (= driver FM volume scaling logic semantic divergence) + fix 候補 A/B/C 並列 record + driver touch β plan review approve 経由限定 mandate + scope-out 明示 (= user audition + ADR-0070 + 本番 cmd 切替 + #Volumedown 実装 + LFO/AMS/PMS scaling)。 PR #155 MERGED at `91ad9be` + Codex Rescue plan review 1 round chain approve plan v1 (= agentId `ab9cae5deb4def312`、 elapsed 約 5m 13s) 全 8 軸 PASS + must-fix 0 + nh 1 + lr 1 + 越権操作なし confirmed + atomic 1 セット規律 13 回目適用完走。
- 2026-05-27: ADR-0073 sprint β PR2 起票 (= Annex β-1 plan v1 placeholder → plan v1 literal fill = β-1-1〜β-1-10 10 sub-section)、 起票者: 越川将人 (= 主軸 Claude Code 経由)、 PR2 doc-only sprint = fix A+B+C 統合採用判断 (= fix A 単独不可 + fix B 単独不可 + fix C conditional after fix A) + 各 fix 実装案 literal (= guarded change `.if PMDNEO_USE_PMDDOTNET ... .endif` 配下 = fix A `comv` 既存 logic を `.else` 配下に保存 + fix B 新規 routine `fm_volume_hook_pmddotnet` additive + carrier_table data + fix C `pmdneo5_init_part` 内 `ld c, #108` override) + allowed-touch literal 詳細化 (= `src/driver/standalone_test.s` 3 routine guarded change + 0x0610 セクション末尾 additive + 新規 fixture + 新規 verify script + doc/dashboard) + 4 build matrix B1-B4 verify command literal + .lst predicate 4 件 + δ-1〜δ-7 verify gate literal (= primary success = δ-5 Layer 1 PASS) + ADR-0072 既存機能 regression 防止 mandate + rollback 17 condition + β plan v1 refinement #14/#15/#16/#17 trigger 具体化 + Codex Rescue plan review 8 重点軸 (= AXIS-R1 root cause / AXIS-R2 fix correctness / AXIS-R3 allowed-touch / AXIS-R4 sha256 / AXIS-R5 ADR-0072 regression / AXIS-R6 fix B feasibility / AXIS-R7 verify executability / AXIS-R8 rollback triggerability)。 user mandate「driver patch にはまだ入らない + β scope = fix A/B/C 採用案確定 + γ は β approve 後 user 明示 GO 必須」。
- 2026-05-27: ADR-0073 sprint β PR2 round 1 Codex Rescue plan review **revise** + must-fix 4 + nh 2 + lr 2 + 越権操作なし confirmed (= agentId `a5f9c31df62103a6a`、 elapsed 約 4m 31s、 doc-only plan review 経験則 5-8 分 threshold 内 = 妥当)、 per-axis verdict = AXIS-R1 PASS + AXIS-R2/R3/R4/R6/R7/R8 FAIL + AXIS-R5 PASS、 must-fix 4 件 = MF-1 fix C scope creep (= `pmdneo5_init_part` 共通 init 位置で SSG/PCM/ADPCM-A/Rhythm/FM3EXT も 108 にする risk、 FM part 限定要) + MF-2 fix B voice data 再取得設計欠落 (= `pmdneo_get_voice_ptr` 不在 + voice ptr/ALG cache 不在 = `comat` または `pmdneo_fm_voice_set` 側 touch 必要 = allowed-touch 拡張要) + MF-3 sha256 target artifact 誤り (= `build/ipl/rom.p1` → `vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1` = active production baseline = main agent 直接 verify confirmed `457a237c...` 完全一致) + MF-4 verify command literal 不完全 (= B3/B4 diff + δ-5 WAV RMS + δ-7 v0-v15 trace executor command 固定要)、 nh 2 件 = NH-1 placeholder header `Annex β-2 / β-3 / β-4 / β-5` 重複 (= 2 件 line 896/898) + NH-2 fix B byte estimate 80 byte 再見積もり (= voice ptr 解決後)、 lr 2 件 = LR-1 `PART_OFF_INSTRUMENT` 流用時 ADPCM-A field 混同 (= SRAM 別領域採用で回避) + LR-2 fix A で PMDDotNET path `PART_OFF_V_SCALE`/`PART_OFF_VOLUME_SHIFT` bypass の v+/v- coverage 整合 (= δ-7 emit verify gate で acknowledge)、 main agent autonomous で plan v2 起草 (= Annex β-2 literal fill = β-2-0〜β-2-10 11 sub-section + plan v1 supersede pointer + SRAM 0xFD62-0xFD6D voice ptr cache 設計 + chip_type FM 限定 fix C + 新規 SRAM equ 7 件 + 新規 18 番 rollback condition #18 v+/v- coverage + Annex β-2/β-3/β-4/β-5 placeholder 単一化 + Codex Rescue round 2 投入 mandate)、 round 2 投入予定 (= AXIS-R9 = round 1 finding 全反映 confirm 新軸)。

## 平易要約

### やりたいこと

PMDDotNET 経由 build した MML を MAME で再生したとき、 音量が小さすぎて (= -76 dBFS) audition material としては成立しない (= 通常 BGM の -20〜-12 dBFS と 50〜60 dB 差) 問題を direct repair したい。 ADR-0072 で voice opcode dispatch は通ったが、 音量問題が残課題として確定。

### 前提

- ADR-0072 ε Accepted (= PR #154 MERGED at `78a1087`) = build-side voice resolution + #FFFile support 完了、 audio non-silent (= rms=5) 達成、 ただし -76 dBFS quiet で δ-5 Layer 1 threshold (= -60 dBFS) 未達
- ADR-0072 で「audio 音量問題は scope OUT = driver volume scaling or fixture voice design 由来、 別 sprint / 別 ADR 範疇」 明示
- production sha256 invariant `457a237c...` 維持 mandate carry
- ADR-0072 「driver no-touch mandate」 は voice opcode data delivery 範疇限定、 audio volume scaling では別軸 root cause

### やったこと

1. 5 並走 sub-agent investigation (= worktree isolation 不使用 path = ADR-0072 sprint α 3 件 preflight fail pattern 反復防止)
2. 5 仮説の root cause 切り分け (= fixture voice design / driver volume scaling / FM TL/volume/expression / PMDDOTNET vs PMDNEO semantics / #FFFile voice data)
3. agent 1-4 evidence で 真の root cause = driver-side 3 件 semantic divergence 確定 (= `comv` 二重 v→V 変換 + `fm_volume_hook` voice TL replace + per-alg carrier mask 不在)
4. agent 5 framework draft (= driver touch 要否 + allowed-touch case A/B/C + production sha256 維持戦略 + rollback condition + sub-sprint chain plan)
5. ADR-0073 doc 起票 (= 8 決定 literal + Annex α 6 sub-section + Annex β-1 placeholder + 改訂履歴 + 平易要約)
6. dashboard 0073 行 add + escalation 履歴 entry append

### 結果

- 真の root cause = PMDNEO driver の FM volume scaling logic 3 件 semantic divergence 確定 = PMD V4.8s + PMDDotNET の line-by-line port から独立 rewrite で導入された bug (= compound effect で -76 dBFS quiet 帰結)
- fixture voice 001 設計妥当性 confirm (= 仮説 A reject)、 driver touch が必須 (= ADR-0072 「driver no-touch mandate」 を覆す pivot 必要 = user 明示 GO mandatory point)
- fix 候補 A/B/C 並列 record (= 採用案確定は β plan review iteration へ defer)
- production sha256 維持戦略 = guarded change `.if PMDNEO_USE_PMDDOTNET` 配下限定 (= ADR-0069/0071/0072 precedent literal 継承)
- ADR-0073 起票 Draft 完了 = sprint α 完走

### 解釈

- ADR-0072 ε Accepted 後の natural follow-up = audio 音量問題 root cause repair。 ADR-0072 build-side fix (= compile.py + build-poc.sh 拡張) で voice delivery は解消、 残課題 = driver volume scaling semantics
- driver touch pivot は ADR-0041 §決定 5 `design_judgment_needed` escalation 軸該当 = user 明示 GO mandatory
- user 明示 mandate「fix A/B/C は driver semantics を変えるため慎重に β plan review approve 経由限定 + fix C 単独先行禁止 + sprint α で混ぜない + user audition 進めない + threshold calibration だけで済まさない + 無断 driver patch 禁止」 を本 ADR-0073 doc に literal 固定
- 真の解決 = 駆 PMDV4.8s + PMDDotNET の volset_slot 数式 + carrier mask 経路を PMDNEO driver guarded change 配下に port = 既存 PMD MML 文化の音量 semantics 完全継承

### 次

- 本 PR1 = doc-only 起票 → Codex Rescue plan review / impl review → merge (= atomic 1 セット規律 13 回目適用予定 = PR #142+#143+#144+#145+#146+#147+#148+#149+#151+#152+#153+#154+本 PR)
- sprint β = Annex β-1 plan v1 起草 + Codex Rescue plan review chain (= fix A/B/C 採用案確定 + allowed-touch literal 詳細化)
- sprint β approve 後 = **user 明示 GO mandatory point** = γ driver patch impl 着手判断
- sprint γ = driver-side fix (= guarded change `.if PMDNEO_USE_PMDDOTNET` 配下限定) + 4 build matrix verify + sha256 byte-identical 維持 confirm
- sprint δ = MAME runtime functional verify + δ-5 engineering gate Layer 1 PASS = primary success metric
- sprint ε = Accepted milestone + 「PMDNEO driver FM volume scaling semantics repair 完了」 wording 解禁 (= 併記必須 7 件)
- ADR-0065 ε δ session 起票判断 = ADR-0073 ε Accepted 後 user 介入 mandatory
- ADR-0066 / ADR-0070 候補 起票判断 = 各 user 明示 GO 必須

### 平易要約 sprint β PR2 context section 追加 (= 2026-05-27 43rd session、 sprint β plan v1 起票)

#### やりたいこと

sprint α で確定した root cause 3 件 + (+) default vol mismatch に対する driver patch を γ で実装する前に、 fix A/B/C の **採用案確定** + 実装案 literal + allowed-touch + verify plan + rollback condition を sprint β plan v1 で literal 固定する。 driver patch 着手は β approve 後 user 明示 GO 経由 γ で別途。

#### 前提

- sprint α 完走 = PR #155 MERGED at `91ad9be` + Codex Rescue plan review 1 round approve 全 8 軸 PASS
- 真の root cause 3 件確定 = driver-side semantic divergence
- fix 候補 A/B/C 並列 record only (= sprint α では候補列挙、 sprint β で採用案確定)
- production sha256 `457a237c...` 維持 mandate carry
- ADR-0072 「driver no-touch mandate」 を覆す pivot = ADR-0041 §決定 5 `design_judgment_needed` escalation 軸該当 (= γ user 明示 GO mandatory point)
- user mandate「β scope = fix A/B/C 採用案確定 + γ は β approve 後 user 明示 GO 経由」

#### やったこと

1. Annex β-1 plan v1 起草 = β-1-1〜β-1-10 10 sub-section literal fill
2. fix A+B+C 統合採用判断 (= fix A 単独不可 + fix B 単独不可 + fix C conditional after fix A) literal 根拠記録
3. 各 fix 実装案 literal (= guarded change `.if PMDNEO_USE_PMDDOTNET ... .endif` 配下、 既存 logic は `.else` 配下に完全保存)
4. allowed-touch literal 詳細化 (= 修正対象 + 不可触対象)
5. 4 build matrix B1-B4 verify command + .lst predicate 4 件
6. δ-1〜δ-7 verify gate literal (= primary success = δ-5 Layer 1 PASS)
7. rollback 17 condition + β plan v1 refinement trigger 具体化
8. Codex Rescue plan review 8 重点軸 + review-only mandate 6 件 literal

#### 結果

- ADR-0073 sprint β plan v1 起票 Draft = Annex β-1 plan v1 literal 固定完了
- fix A+B+C 統合採用判断 record (= γ で実装する fix 確定)
- allowed-touch + verify gate + rollback condition + Codex review 重点軸 literal 全 fill
- driver / vendor / verify / fixture 完全不変 (= 本 sprint β doc-only)
- production sha256 `457a237c...` 維持期待 (= doc-only で build しない、 carry)

#### 解釈

- ADR-0072 「driver no-touch mandate」 を覆す pivot 判断は voice opcode data delivery 範疇限定の insight、 audio volume scaling 範疇では driver guarded change 経路必須 (= memory `project_pmdneo_adr_0072_initiated.md` 末尾 supersede insight 訂正 section 整合)
- fix B の per-alg carrier mask 経路 (= PMD V4.8s `volset_slot` line-by-line port) が PMD MML 音量 semantics 完全継承の path
- fix B implementation feasibility (= AXIS-R6 軸) = voice data 末尾 reg 0xB0 byte (= byte index 24) 都度 read で `PART_OFF_FM_ALG` cache offset 新規追加回避 + ADR-0058 v2 PartWork 不可触 mandate 抵触なし
- guarded change pattern で flag-off byte-identical 保証 = production sha256 `457a237c...` 維持 + flag-on 経路で audio audible 改善 + flag-off + flag-on 経路独立性確保

#### 次

- sprint β PR2 = doc-only 起票 → Codex Rescue plan review chain 投入 → approve loop → main agent 経路 merge (= atomic 1 セット規律 14 回目適用予定)
- sprint β approve 後 = **user 明示 GO mandatory point** = γ driver patch impl 着手判断
- sprint γ = fix A+B+C 統合実装 (= guarded change 配下限定) + 4 build matrix verify + sha256 byte-identical 維持 confirm
- sprint δ = MAME runtime functional verify + δ-5 engineering gate Layer 1 PASS = primary success metric
- sprint ε = Accepted milestone + 「PMDNEO driver FM volume scaling semantics repair 完了」 wording 解禁 (= 併記必須 7 件)
- ADR-0065 ε δ session 起票判断 = ADR-0073 ε Accepted 後 user 介入 mandatory
- ADR-0066 / ADR-0070 候補 起票判断 = 各 user 明示 GO 必須
