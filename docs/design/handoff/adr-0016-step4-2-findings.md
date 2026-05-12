# ADR-0016 step 4-2 — finding memo (= register write / 音出し gate PASS、 ただし J part fixture 由来ではない)

	位置付け: ADR-0016 step 4-2 (= PMDDotNET J part fixture を本線 driver に投入 + register write 観測) の状況整理
	書き手: Claude Code
	状態: 4-2 PASS (= 最低 gate)、 4-3 で本格 fixture-driven verify 予定
	関連 commit: `6813d70` (= V-1 本線接続)、 4-2 commit pending

---

## 0. 目的

ADR-0016 step 4 (= SubE / ADPCM-B 本実装) sub-commit 4-2 の verify 結果を整理。 「最低 gate (= register write / 音出し) 通過」 と「fixture-driven verify 未達 (= 4-3 へ持ち越し)」 を明示。

---

## 1. 検証 setup

### 1-1. ROM_A (= SAMPLE.M baseline)
- build: `bash scripts/build-poc.sh` (= PMDNEO.s build top、 flag off)
- driver: pmdneo_load_m が `sample_m_data` を読む
- SAMPLE.M Part J body: `m[0x0451] = 0x80` (= **empty**、 即 part end)

### 1-2. ROM_B (= j-part-minimum.M fixture)
- fixture: `src/test-fixtures/step4/j-part-minimum.mml` (= J part 含む最小 MML、 PMDDotNET /N compile)
- compile 結果: `j-part-minimum.M` (211 byte、 sha256 `52a8948...`)
- Part J offset = 33、 body = `0x30 0x60 0x80` (= octave 3 onkai 0 c、 音長 96、 part end)
- build: `PMDNEO_USE_PMDDOTNET=1 PMDNEO_M_RAW=.../j-part-minimum.M bash scripts/build-poc.sh`
- driver: pmdneo_load_m が `pmddotnet_song` (= j-part-minimum.M) を読む

---

## 2. 観測結果

### 2-1. ADPCM-B register write 観測(両 ROM で完全同一)

| idx | reg | value | 解釈 |
|---|---|---|---|
| 29-30 | 0x10 | 0x01 → 0x00 | 初期化 reset |
| 33 | 0x10 | 0x01 | 再 reset |
| 36 | 0x12 | 0x2A | start addr LSB = 0x002A |
| 37 | 0x13 | 0x00 | start addr MSB |
| 38 | 0x14 | 0xA8 | stop addr LSB = 0x00A8 |
| 39 | 0x15 | 0x00 | stop addr MSB |
| 40 | 0x19 | 0x96 | delta-N LSB |
| 41 | 0x1A | 0x6E | delta-N MSB = 0x6E96 (= 24 kHz) |
| 42 | 0x11 | 0xC0 | pan = both (L+R) |
| 43 | 0x1B | 0xFF | volume = max |
| 44 | 0x10 | **0x80** | **playback START (= keyon)** |

両 ROM とも 12 件 ADPCM-B writes + final reg 0x10 = 0x80 (= keyon 発火)。

### 2-2. wav

両 ROM とも sha256 = `1dfee1ec6c1aaa608592ec89883c79690efd786581e576bfc33e0e1eafaba426` (= 完全一致)。

---

## 3. finding 解釈

### 3-1. 「fixture-driven ではない」

SAMPLE.M の Part J body = `0x80` (= empty) なのに driver が adpcmb_keyon を呼んでいる → これは driver の **main loop 内の別経路** から keyon が発火している (= 現行 `adpcmb_keyon` は固定 `adpcm_b_beat_struct` を call、 4-1 で確認済の既存実装)。

つまり:
- driver が pmdneo_load_m 経由で .M を読んでいる (= V-1 で establish)
- ただし main loop の J part 解釈は **fixture-driven ではない** (= 固定 beat sample 再生)
- adpcmb_keyon が呼ばれる経路は J part body と無関係に発火

### 3-2. 「register write trace は本線 driver 経路から」

12 件の ADPCM-B writes は **本線 driver (= PMDNEO.s + ADPCMB_DRV.inc) の経路で出力**。 これは V-1 で確立した「本線 driver で chip register を操作する経路」 が機能している証拠 ✅。

### 3-3. 4-2 gate 評価

| user 指示 4-2 gate | 結果 |
|---|---|
| ADPCM-B register write 観測 | ✅ PASS (12 writes、 全 register 帯到達) |
| 音が出る | ✅ PASS (sec 0-2 RMS=813-3190、 peak=14163) |
| (補足) **fixture-driven の reflection** | ❌ 未達成 → 4-3 課題 |

---

## 4. 4-3 へ持ち越す要件

### 4-3 で達成すべき gate (= 「J part body 差分が trace / wav に反映」)

1. **fixture の Part J body 差分** が ADPCM-B register trace に反映:
   - 例: j-part-minimum.M で octave/onkai を変えると delta-N (= reg 0x19/0x1A) が変わる
   - 例: 異なる音長で keyon の timing / 数が変わる
2. **fixture の Part J body 差分** が wav に反映:
   - SAMPLE.M (Part J empty) と j-part-minimum.M で wav byte が変わる

### 必要な driver 改修(= 4-3 範囲)

- **`adpcmb_keyon` の引数化**: 現状固定 `adpcm_b_beat_struct` 呼出 → MML body 由来の sample 番号 / delta-N / volume / pan を受け取る形に refactor (= 設計書 3 §4-4 「直接 register 書込流儀」)
- **J part main loop integration**: `adpcmb_main_note` (PMD_Z80.inc L1432) で MML body の音程 byte を delta-N に変換 + `adpcmb_keyon` を新引数で呼出
- **caller 側 (= standalone_test.s L2509 `adpcmb_keyon_hook`)** の IX 設定: legacy / refactor 判断必要

### memory への submit

ADR-0016 step 4-2 完了 → step 4-3 着手の引継 memo として `project_next_session_kickoff.md` 等に反映 (= 必要なら別 sprint で)。

---

## 5. 関連

- ADR-0016 §決定 3 step 4 (= SubE / ADPCM-B 本実装)
- 設計書 3 §4-4 ADPCM-B 駆動 routine 概要 (= 直接 register 書込流儀)
- commit `25e74ce` (= 4-1 ADPCMB_DRV.inc volset/panset/setfreq 本実装)
- commit `6813d70` (= V-1 本線 driver 接続)
- memory `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 検出規律)
- fixture: `src/test-fixtures/step4/j-part-minimum.mml`
