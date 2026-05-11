# ADR-0005: PMD 音色検証 local DB 設計 (= PMDDotNET reference vs PMDNEO MAME 録音 合致率評価)

- 状態: Accepted (= ADR-0013 で §H 評価基準訂正、 ADR-0014 で比較ツール部分は再利用)
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: memory `project_pmd_template_complete.md` (= TEMPLATE-Bscale)、 memory `project_pmd_voice_tl_verified.md` ほか voice 検証 6 件、 memory `feedback_mml_redesign_when_unobservable.md`

> **※ ADR-0013 で §H 評価基準訂正、 ADR-0014 で部分再利用 (2026-05-11 追記)**
>
> ADR-0013 D3 で §H の「PMDDotNET 録音『正』、 PMDNEO 自前 driver via MAME 録音」 を「同一 .mml から改造 PMDDotNETConsole で生成した同一 .M を 2 経路で再生して比較」 に訂正。 比較ツール (= measure.py / migrate_existing.py / MAME headless 録音 mode) は ADR-0014 カテゴリ A で **再利用扱い**、 改造 PMDDotNET driver の検証経路にそのまま流用予定。

## 背景

PMDNEO 自前 driver の `@` 系 (= 音色) cmd 実装検証で、 PMDDotNET → pmdplay 経路を「正」 とし、 PMDNEO 自前 driver via MAME 録音を比較対象とする検証 dataset が必要。

本 session (2026-05-11) で TL/AR/DR/ML/alg/fbl の 6 step 28 entry を `src/tools/pmd-mml/reference/pmddotnet/voice-test/` に commit したが、 これは「氷山の一角」 — 音色 43 パラメータの組み合わせ + 音重ね + chord + multi-part 等で実質無限の検証空間。

加えて、 過去 silent 化事例 (= memory `project_pmd_b_only_silent_root_cause.md`) で実証されたとおり **Python 機械処理の数値判定だけでは盲点を暴けない**。 user 経験則: 「測定する時間間隔が長くて正確なサンプルが取れていない状態で AI も user も判定していた」 = 解析 window 粗さで微差を見逃す。

→ 「機械処理を続けるが見逃しを限りなく 0 に」 する仕組みとして、 raw WAV 必須保存 + 1ms 解像度の解析 + MATLAB 互換 mat 形式での raw 保存 (= 後追い解析の保険) を設計。

## 決定 (= F-W 27 論点)

### F. 解析時間分解能

**1 ms minimum**。 VGM トレース基準 (= 1/1000 sec)、 人耳判別不能レベル。 envelope follower window 1ms、 spectrogram hop 1ms。

### G. 解析手段の役割分担

- **Python (scipy/librosa) main** で機械処理
- **MATLAB は保険** (= Python で「区別つかない / スルー」 が起きた時、 raw WAV を MATLAB に流して再解析)
- → raw 保存があれば後から MATLAB 可能、 mat 形式で MATLAB 直接 load 互換

### H. 評価基準

**PMDDotNET → pmdplay 経路の録音を「正」 とし、 PMDNEO 自前 driver via MAME 録音との合致率で判定**。 閾値超過なら driver 実装 OK。

### I. 保存形式

**wav + mat 両方**。 wav は他 tool (= MATLAB / Audacity / Audition) で開ける汎用性、 mat は MATLAB / scipy.io.loadmat 直接 load + 解析 metadata 含む。

### J. 保存場所

**`/Users/koshikawamasato/Projects/pmdneo/data/`** (= repo 内、 `.gitignore` で除外)。 GitHub に上げると repo 肥大、 local DB として運用。

### K. 論理構造

**JSONL manifest + blob/<entry-id>__{pmddotnet,mame}.{wav,mat}**。 1 entry = 1 manifest 行、 raw data は entry-id 命名で blob/ に物理保存。

### L. 合致指標 (= L6)

3 指標 AND、 中段階閾値:
- **L1 cross-correlation ≥ 0.90** (= 波形類似度、 timing 補正後)
- **L3 spectral cosine ≥ 0.95** (= 倍音構造、 位相耐性)
- **L4 envelope correlation ≥ 0.90** (= ADSR shape)

全部 over → PASS、 1 つでも under → FAIL + どの指標で fail かを log。

### M. MAME 録音条件

- **M1.** 1 entry = 1 ROM build (= measure script で flow 統合)
- **M2.** 録音時間は MML 全長 + テンポから動的計算 (= 後述 Q 公式) + safety margin
- **M3.** marker tone (= P) で 1ms 精度 timing 同期
- **M4.** driver 微差は中段階閾値で許容 (= 厳密 bit-perfect は不要)

### N. 不合致時挙動

**N4 = log + plot 自動生成 + 続行**。 蓄積止めず、 不合致 entry には spectrogram/waveform plot を自動生成 → user review 容易。

### O. manifest schema

```jsonc
{
  "id": "voice-tl-10",
  "category": "voice/single/param-step",
  "tags": ["TL", "alg-0", "carrier"],
  "voice_def": {"alg": 0, "fbl": 5, "op1": {...}, ...},
  "mml_pattern": {"melody": "...", "setup": "...", "loop": true, "tempo": 75, "part": "B"},
  "source_mml_repo_path": "src/tools/pmd-mml/reference/.../voice-tl-10.mml",
  "data_files": {
    "wav_pmddotnet": "blob/voice-tl-10__pmddotnet.wav",
    "mat_pmddotnet": "blob/voice-tl-10__pmddotnet.mat",
    "wav_mame": "blob/voice-tl-10__mame.wav",
    "mat_mame": "blob/voice-tl-10__mame.mat",
    "plot_dir": "blob/voice-tl-10__plots/"   // FAIL 時のみ
  },
  "expected_summary": {"rms_L": 278.3, "peak_L": 858, "fft_top3_hz": [261, 523, 785]},
  "match": {"L1_xcorr": 0.95, "L3_spectral": 0.98, "L4_envelope": 0.92, "verdict": "PASS"},
  "verified_at": "2026-05-11",
  "tool_versions": {"pmddotnet": "4.8s", "pmdplay": "SDL 2022-07-26", "mame": "...", "scipy": "..."},
  "driver_commit": "85f2c87"   // U: driver 状態 snapshot
}
```

詳細データ (= 1ms envelope array、 FFT bin 全部) は manifest に入れず mat 内のみ。

### P. marker 注入 = P2 (script 動的注入) + クリック音 (T)

measure script が compile 直前に marker 音色定義 + 発音 cmd を注入、 reference MML 自体は不変保持。 marker は別 part (= W、 A part) で完全分離。

### Q. 全長予測式

**`#Zenlen 192` を全 MML で強制**。 PMD spec から:
```
1 clock 時間 = 60 / (tempo × 48) sec
duration_sec = total_clock × 60 / (tempo × 48)
```
(例: tempo=75、 Zenlen=192 → 1 clock ≈ 16.67 ms、 1 全音符 = 192 clock = 3.2 sec)

### R. measure script 構造

`src/tools/pmd-mml/reference/measure.py`:
```
1. duration 予測 (Q)
2. marker 注入 (P2)
3. PMDDotNET 経路: compile + render
4. PMDNEO ROM build + MAME 録音 (M1)
5. marker 検出 + align (M3)
6. 1ms 解像度で全指標解析 (F)
7. 合致判定 (L6)
8. local DB 保存 (O schema、 N4 plot 条件付き)
```

### S. migration

**全 28 entry 一括** (= `migrate_existing.py` で voice-test/*/*.mml を seed)。

### T. クリック音色

**@99 専用音色** (= alg=7 全 op carrier additive、 fbl=5、 op×4 全部 AR=31 / DR=31 / RR=15 / TL=0):
```
@099 007 005
 031 031 000 015 015 000 000 008 003 000  ← 全 op 同
 031 031 000 015 015 000 000 008 003 000
 031 031 000 015 015 000 000 008 003 000
 031 031 000 015 015 000 000 008 003 000
```
発音: `A	@99 v15 q1 o8 c%2 r%2` (= 高音 c o8 を 2 clock 短発音 + rest)。

### U. MAME 録音 timing

**U1 = 現状 driver で baseline 取得**。 driver 改修ごとに verdict 更新、 改善進捗を可視化。 driver 未実装 cmd の entry は当面 FAIL = 期待動作。

### V. CLI

- `python3 src/tools/pmd-mml/reference/measure.py <mml> [--category=...] [--tags=...] [--skip-mame]`
- `python3 src/tools/pmd-mml/reference/migrate_existing.py` (= voice-test/*/*.mml 一括)

### W. marker part

**A part** で marker 注入 (= 検証対象 B と完全分離、 解析時の周波数 filter で容易切り分け)。

> **※ ADR-0006 で superseded (2026-05-11)**: AES+ YM2610B 想定 (= PMDNEO_TARGET_CHIP=ym2610b) で A part を将来 FM ch1 として使う方針に変更したため、 marker 用 A part 予約は破棄。 marker host part は **measure.py が動的選定** (= priority: SSG 空 > FM 空 > ADPCM、 ADR-0006 §F 参照)。

## 実装 plan

1. `.gitignore` に `data/` 追加
2. `data/` dir 構造作成 (= `data/blob/`、 空 manifest.jsonl)
3. `measure.py` 実装
4. `migrate_existing.py` 実装
5. 既存 28 entry 一括 migration → 結果確認
6. commit (= script + .gitignore 更新、 data/ 自体は ignore)

## 派生する細部 (= 実装中に詰める)

- click 区間 trim 範囲 (= 何 ms までを click 期間として除外)
- driver state snapshot の記録方法詳細 (= entry に `driver_commit: "85f2c87"` 等)
- verdict 履歴の保持 (= 同 entry の改修前後比較、 manifest に履歴 array?)
- click 注入の MML 文法 (= `#Zenlen 192` 既存 + click 統合方法)

## 関連 memory

- `project_pmd_template_complete.md`
- `project_pmd_voice_tl_verified.md` ほか 5 件 (= 既存 28 entry の seed)
- `feedback_mml_redesign_when_unobservable.md`
- `project_pmddotnet_compile_option_C_required.md`
- `project_pmd_b_only_silent_root_cause.md`
- `project_mame_headless_recording_mode.md` (= F1 前提条件 a 解決、 2026-05-11 追記)

## 実装後の確定事項 (= 順次追記)

### 2026-05-11: F1 前提条件 (a) MAME 録音 format 揃え 解決

改造 MAME (= vendor/mame-fork/neogeo) を完全 headless で動作させ、 PMDDotNET / pmdplay と同 format (= 48 kHz / int16 / stereo) で WAV 録音する起動コマンドを確立。

```bash
SDL_VIDEODRIVER=dummy /Users/koshikawamasato/Projects/pmdneo/vendor/mame-fork/neogeo <ROM> \
  -rompath <DIR> -video none -sound coreaudio -samplerate 48000 \
  -nothrottle -seconds_to_run N -wavwrite <PATH> -skip_gameinfo -noautosave
```

**key 発見**: `SDL_VIDEODRIVER=dummy` 環境変数が **fullscreen / window フォーカス奪取を完全抑止する決定打**。 `-video none` だけでは macOS Window Server を一瞬掴む挙動がある。

**検証結果**: 5 sec 録音 = 240001 samples = 完全同 format、 fullscreen 奪取なし (= user 観察確認、 2026-05-11)。

詳細: `~/.claude/projects/-Users-koshikawamasato-Projects-pmdneo/memory/project_mame_headless_recording_mode.md`

### F1 残り前提条件

- (b) PMDNEO compile.py の PMDDotNET MML 互換性 ← PMDDotNET 拡張別 sprint 待ち
- (c) marker A part の PMDNEO 対応 ← 上記と同じ
