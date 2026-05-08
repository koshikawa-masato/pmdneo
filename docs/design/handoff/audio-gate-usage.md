# audio-gate.sh usage (= Codex / Claude Code 共通規律)

	位置付け: PMDNEO Phase 2 SubF-1 〜 で audio gate 自動化を行う規律
	書き手: Claude Code
	適用範囲: PMDNEO repo の driver / runtime / main.c touch commit
	状態: 確立 (= SubE-2 baseline 取得済)

---

## 0. 設計原則

- **audio gate emulator == 聴感確認 emulator** (= gngeo lastbld2、 user 原則)
- **macOS audio loopback (BlackHole) で system audio を sox 経由 wav 化**
- **解析は scripts/analyze-audio.py (= numpy + scipy.signal、 librosa 不要)**
- **gngeo 起動は必ず window モード** (= フルスクリーン禁則)
- driver / runtime / main.c touch 後の commit 前に **必ず audio-gate.sh 実行**

---

## 1. one-time setup (= macOS user 操作必要)

### 1-1. BlackHole 2ch install

```bash
brew install --cask blackhole-2ch
```

install 後、 macOS が新 audio driver を認識するため場合により reboot or
`sudo killall coreaudiod` 必要。

### 1-2. Multi-Output Device 作成

1. `/System/Applications/Utilities/Audio MIDI Setup.app` 起動
2. 左下「+」 → **複数出力装置を作成**
3. 右 panel で以下にチェック:
   - **BlackHole 2ch** (= 録音用)
   - **(user 耳用 device、 例: Babyface Pro / 内蔵 speaker / 等)**
4. **プライマリ装置** dropdown を user 耳用 device に
5. **音ずれ補正** で BlackHole 2ch にチェック (= drift correction)、 耳用 device は OFF

### 1-3. system 出力切替

メニューバー音量 icon → **複数出力装置** を選択。

これで gngeo audio が両 device に流れ、 user 耳でも聴こえつつ sox で BlackHole から録音可能に。

### 1-4. 検証

```bash
ls -la /Library/Audio/Plug-Ins/HAL/BlackHole2ch.driver  # exist 確認
sox -t coreaudio "BlackHole 2ch" -c 2 -r 48000 -b 16 /tmp/test.wav trim 0 3
afplay /tmp/test.wav   # 何か system 音が録れていれば OK
```

---

## 2. usage

### 2-1. 基本

```bash
# default song (= SubE-2 ADPCM-B + FM song)、 30 秒録音
bash scripts/audio-gate.sh --skip-build --duration 30
```

### 2-2. fixture 指定 (= SubF-1 以降)

```bash
bash scripts/audio-gate.sh --fixture baseline    # PMDNEO_FIXTURE=1 で再 build
bash scripts/audio-gate.sh --fixture tempo       # = 2
bash scripts/audio-gate.sh --fixture loop        # = 3
bash scripts/audio-gate.sh --fixture fade        # = 4
```

### 2-3. assertion

```bash
bash scripts/audio-gate.sh --fixture baseline \
    --duration 14 --skip-seconds 10 \
    --assert-rms-min 0.005 \
    --assert-peak-hz 261 --tol-hz 8 \
    --assert-bpm 120 --tol-bpm 6 \
    --assert-onset-count 4
```

### 2-4. 機械 parse

```bash
bash scripts/audio-gate.sh --fixture baseline --json \
    | jq '.verdict, .stats.rms, .stats.estimated_bpm'
```

### 2-5. baseline diff

```bash
bash scripts/audio-gate.sh --skip-build --json \
    --baseline docs/work/audio-baseline-subE2.json
```

JSON 出力に `baseline_diff` field が追加 (= RMS / BPM / onset 差分)、
memory `feedback_log_self_check.md` の「数値で何が変わったか報告」 規律。

---

## 3. exit code

| code | 意味 | 対処 |
|---|---|---|
| 0 | 全 assertion pass | commit OK |
| 1 | audio assertion fail | commit 禁止、 baseline diff を user 報告 |
| 2 | infra fail (= build / BlackHole / sox / python) | 環境確認 |

---

## 4. Codex / Claude Code 共通規律

### 4-1. driver / runtime touch 時の必須手順

```bash
# 1. 実装後、 audio-gate を json 出力で実行
bash scripts/audio-gate.sh --skip-build --json > /tmp/pmdneo-gate.json

# 2. verdict + stats を jq で確認
jq '.verdict, .stats.rms, .stats.estimated_bpm, .assertions' /tmp/pmdneo-gate.json

# 3. exit 0 (= verdict pass) でなければ commit 禁止
[[ $(jq -r '.verdict' /tmp/pmdneo-gate.json) == "pass" ]] || exit 1
```

### 4-2. 報告フォーマット

commit 前に user に audio gate 結果を報告する際:

- verdict (= pass / fail)
- RMS / peak (= 主要 stats)
- onset 数 + 最初 5 個 (= 楽曲 phrase 推定)
- estimated BPM (= tempo 検証用)
- baseline JSON との diff (= 退行有無)

### 4-3. user 聴感確認の頻度

- **iteration 毎の聴感確認は依頼しない**(= machine layer で silent regression / BPM 異常 catch)
- **fixture 一連完了時の 1 回のみ** user 聴感確認 (= 例: SubF-1 の baseline / tempo / loop / fade 4 個まとめて)
- 手動聴感 必須領域: timbre (= FM voice) / pan / 音響的「正しさ」 / 楽曲の感情 (= machine 判定不可)

---

## 5. baseline JSON 管理

- `docs/work/audio-baseline-subE2.json` (= 既存 SubE-2 baseline、 gitignored)
- 各 fixture の expected JSON を `docs/work/audio-baseline-fixture-XXX.json` で保存
- baseline JSON は **個人 dev 環境依存**(= BlackHole index、 host 音量等で値変動)、 commit しない

---

## 6. 失敗 case の対処

### 6-1. BlackHole 検出不能

```bash
ls /Library/Audio/Plug-Ins/HAL/BlackHole2ch.driver
```

存在しない → §1-1 を再実行、 もしくは reboot。

### 6-2. 録音 wav が silent

- system 出力が「複数出力装置」 になっているか確認 (= メニューバー音量 icon)
- gngeo の音が user 耳で聞こえているか確認 (= 直接聴感)
- sox log: `cat /tmp/pmdneo-audio-gate-sox.log`

### 6-3. プチノイズ / 速度異常

- Babyface 等 master device の sample rate が 48 kHz か (= Audio MIDI Setup)
- Multi-Output Device の音ずれ補正設定確認 (= master 以外に ☑)

### 6-4. JSON 出力が空 (= 古い bug)

`log()` 関数の bash return 0 強制。 既に修正済 (= 2026-05-08)。

---

## 7. 参照

- `scripts/audio-gate.sh` (= 本 script、 sox + gngeo + analyze-audio.py)
- `scripts/analyze-audio.py` (= numpy + scipy.signal RMS / FFT / onset / BPM)
- `docs/work/audio-baseline-subE2.json` (= SubE-2 baseline、 individual)
- `/Users/koshikawamasato/Projects/neo-sisters/scripts/audio-runtime-verify.sh` (= 由来、 ffmpeg + puzzledp)
- memory `feedback_runtime_audio_verify_required.md` (= 4 層 enforcement、 machine layer 強化)
- memory `feedback_log_self_check.md` (= 数値で何が変わったか報告)
