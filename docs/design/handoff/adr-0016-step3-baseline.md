# ADR-0016 step 3 — baseline 録音手順

	位置付け: ADR-0016 step 3 (= 動的 load 経路 establish) の波形比較 reference を取る手順
	書き手: Claude Code
	状態: 確立 (= 2026-05-12 4th session sub-commit 3a で実走確認済)

---

## 0. 目的

ADR-0016 step 3 完了判定「既存 sample_m.s 経路と動的 load 経路で同一波形」 の **「既存経路」 側 baseline** を録音する。 3b/3c で driver 改修 + build chain 改修した後、 改修後波形と本 baseline を比較して「同一」 とみなせるか判定する。

---

## 1. 前提

- ngdevkit toolchain install 済 (= `brew install ngdevkit ngdevkit-gngeo ngdevkit-toolchain`)
- `vendor/ngdevkit-examples/config.mk` 生成済 (= `cd vendor/ngdevkit-examples && autoreconf -i && ./configure`)
- MAME install 済 (= `/opt/homebrew/bin/mame`)
- BIOS ROM 配置済 (= `vendor/mame-fork/roms/neogeo.zip`)

---

## 2. 手順

### 2-1. ROM build

```bash
bash scripts/build-poc.sh
```

成果物: `vendor/ngdevkit-examples/00-template/build/rom/lastbld2.zip` (NEOGEO ROM ZIP、 puzzledp slot に 243- prefix data 配置)。

### 2-2. MAME baseline 録音

```bash
bash scripts/run-mame.sh --headless --wavwrite
```

default option:
- `--gamerom lastbld2` (= cca9683 で default 化、 指定不要)
- `--wavwrite-seconds 8` (= 8 秒録音)
- ROM 隔離 path = `/tmp/pmdneo-mame-rom/`
- wav 出力 = `/tmp/pmdneo-trace/audio.wav`

### 2-3. baseline 保存 (= 比較 reference として残す)

```bash
cp /tmp/pmdneo-trace/audio.wav /tmp/pmdneo-baseline-3a-standalone_test.wav
```

repo には残さない (= 1.5 MB バイナリ、 .gitignore 流儀)。 必要なら別 sprint で `build/step3-baseline-wav/` 等に正式 baseline 配置。

---

## 3. 期待値

| 項目 | 値 |
|---|---|
| wav format | RIFF WAVE, stereo, 48000 Hz, 16-bit PCM |
| 長さ | 8.00 秒 (= 384001 frames) |
| file size | 約 1.5 MB |
| 1st sec RMS | 約 2687 (range 0-32768) |
| 1st sec peak | 約 7905 |
| Average speed | 4000% 前後 (= headless で 8 秒録音 ≒ 0.2 sec 実時間) |

CRC mismatch warning は無視可 (= build chain で puzzledp ROM slot を流用 + 独自 data 配置のため意図通り、 `WARNING: the machine might not run correctly` も問題なし)。

---

## 4. 改修後比較 (= 3c 完了時)

PMDNEO.s build top + 動的 load 経路に切替えた後、 同手順で改修後 wav を取得し本 baseline と比較する。

### 4-1. 比較 method (= 現状の選択肢)

- **(現状) JSON 解析 → diff**: `scripts/analyze-audio.py --json --baseline <prev.json> <wav>` で各 wav を JSON 化し、 既存の `--baseline` 経路で diff 出力。 ただし JSON 化は wav 全体の summary (RMS / onset 数 / BPM 等) のみで、 sample-level の波形差分は出ない。
- **(未実装、 別 sprint 候補) `--compare` mode**: 2 つの wav を直接受け取って RMS / 相関係数 / sample-level diff を出す機能。 `scripts/analyze-audio.py` に追加実装する想定。 3c verify 時に必要性が確定したら別 sprint で実装。

### 4-2. 判定基準 (= 別 sprint で確定)

- 完全一致 (= byte 単位 / sha256)
- RMS 一致 (= ±5% 以内)
- 相関係数 (= 0.99 以上)
- 聴感比較 (= user 確認)

判定基準の重み付け + 採用順位は 3c 着手時に user 壁打ちで確定。

---

## 5. 関連

- ADR-0016 §決定 3 step 3 (= driver 既存 .M 再生 verify)
- memory `project_mame_headless_recording_mode.md` (= MAME headless 録音 mode 確立)
- commit `cca9683` (= scripts/run-mame.sh default GAMEROM 修正)
- commit (= 3a 実走時に baseline 取得した 4th session 記録、 commit なし)
