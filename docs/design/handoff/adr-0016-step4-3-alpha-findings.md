# ADR-0016 step 4-3-α — main.c cmd 0x05 revert + J part dispatch 到達 trace gate PASS

	位置付け: ADR-0016 step 4-3 sub-commit α (= W-3 後 main.c / standalone_test.s 整合補正)
	書き手: Claude Code
	状態: 4-3-α PASS、 4-3-β/γ/δ へ繋ぐ土台確立
	関連 commit: W-1 `8fc326a` (= cmd 0x02 暫定、 V-1 era)、 W-3 `464cff1` (= build top revert)

---

## 0. 目的

W-3 で本線 driver を `standalone_test.s` に戻した後、 main.c が cmd 0x02 を送っていたが、
standalone_test.s では cmd 0x02 = `nmi_cmd_2_play_song` (= FM scale test) であり MML
song 経路では **ない**。 真の入口は cmd 0x05 + TEST_MODE_CHORD=5 →
`nmi_cmd_5_init_mml_song` (L321-322)。 4-3-α で main.c を cmd 0x05 に revert し、 J
part dispatch まで実 trace で到達確認。

## 1. 改修内容

`vendor/ngdevkit-examples/00-template/main.c` L77-82:

- 旧 (W-1 era、 V-1 PMDNEO.s build top 前提):
  ```c
  /* ADR-0016 step W-1 ... cmd 0x02 = play_song = pmdneo_load_m 経由 */
  *REG_SOUND = 2;
  ```
- 新 (W-3 後、 standalone_test.s build top 本線整合):
  ```c
  /* ADR-0016 step 4-3-α ... cmd 0x05 + TEST_MODE_CHORD=5 → nmi_cmd_5_init_mml_song */
  *REG_SOUND = 5;
  ```

driver / 他 source 一切不変。 1 行 + comment 改修のみ。

## 2. 検証 setup

### 2-1. ROM_A (= test01.mml + test02.mml default、 Part J empty)

- build: `bash scripts/build-poc.sh`
- run: `bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace`
- 保存: `/tmp/pmdneo-A/{audio.wav,z80-mem-trace.tsv,ymfm-trace.tsv}`
- wav sha256: `3c1f776f76dd66647bcad04c6914822490850a4342d5dc4928a63d69a0f985d6`

### 2-2. ROM_B (= j-part-minimum.mml + test02.mml、 Part J=`o4 l1 c`)

- build: `MML_INPUTS="/tmp/j-part-minimum.mml,test02.mml" bash scripts/build-poc.sh`
- run: 同上
- 保存: `/tmp/pmdneo-B/{audio.wav,z80-mem-trace.tsv,ymfm-trace.tsv}`
- wav sha256: `eabb80d4e1d3fe0034e12a93384f8997d23806e6cde802563a02f050df694b49`

### 2-3. routine 帯 (= build/standalone_test.lst より抽出)

| routine | PC 範囲 |
|---|---|
| `nmi_cmd_5_adpcmb_beat` (cmd 5 entry) | `0x00F2-0x00F7` |
| `init_adpcmb_beat` (固定 beat、 ADPCM-B fixed register write) | `0x0610-0x0656` |
| `nmi_cmd_5_init_mml_song` (= MML song init) | `0x0657-0x094B` |
| `pmdneo5_init_part_hooks_pcm` (= PCM hooks setup) | `0x094C-0x09B1` |
| `pmdneo_song_main` (per-tick dispatcher) | `0x09B2-0x0A35` |
| `pmdneo_part_main` (part body parser) | `0x0A36-0x0EE0` |
| `adpcmb_keyon_hook` | `0x0EE1-0x0F2C` |
| `adpcmb_keyon` | `0x0F2D-0x0F30` |
| `adpcmb_keyoff` | `0x0F31-0x0F3F` |

## 3. 観測結果

### 3-1. z80-mem-trace writes 比較

| routine | ROM_A (J empty) | ROM_B (J=note) | 差分解釈 |
|---|---|---|---|
| cmd 0x05 entry | 2 | 2 | init 等価 (= dispatch 経路共通) |
| `nmi_cmd_5_init_mml_song` | 2001 | 2001 | 17 part init 共通 |
| `pmdneo5_init_part_hooks_pcm` | 88 | 88 | PCM hooks 設定共通 |
| `pmdneo_song_main` | 30096 | 23226 | per-tick loop 動作 |
| `pmdneo_part_main` | 1907 | 218 | J body 差で iteration 数異 |
| **`adpcmb_keyon_hook`** | **0** | **4** | **ROM_B のみ keyon 経路到達** |
| **`adpcmb_keyon`** | **0** | **2** | 同上 |
| **`init_adpcmb_beat`** | **0** | **20** | 同上、 固定 beat register write fire |
| **`adpcmb_keyoff`** | **0** | **4** | ROM_B のみ keyoff |

### 3-2. ymfm ADPCM-B register write 比較

| idx 帯 | reg | ROM_A | ROM_B | 解釈 |
|---|---|---|---|---|
| 103-110 | 0x10/0x1B/0x11-0x15 | 8 件 reset/mute | 8 件 reset/mute | init mute 共通 |
| 249-258 | 0x10/0x12-0x15/0x19/0x1A/0x1B/0x11 | — | **10 件** | J body 由来 keyon (= start/stop/delta-N/vol/pan/keyon) |
| 258 | **0x10 = 0x80** | — | **1 件** | **playback START (= 真の J body keyon)** |
| 1624-1625 | 0x10 | — | 2 件 retrigger | 後続 J body |

ROM_A は post-init で 0 件 ADPCM-B writes。 ROM_B は 12 件 (= idx 249-258 / 1624-1625)。

### 3-3. wav

ROM_A `3c1f776f...` vs ROM_B `eabb80d4...` = 異なる、 J body 差が wav byte に反映。

## 4. gate 評価

| user 指示 4-3-α gate | 結果 |
|---|---|
| nmi_cmd_5_init_mml_song 実行確認 | ✅ PASS (= 2001 writes) |
| pmdneo_song_main 実行確認 | ✅ PASS (= 30096 writes、 per-tick loop) |
| PART_PCM dispatch 実行確認 | ✅ PASS (= pmdneo5_init_part_hooks_pcm 88 + pmdneo_part_main 1907) |
| adpcmb_keyon_hook 実行確認 | ✅ PASS (= ROM_B で 4 writes、 ROM_A で 0、 = J body 由来 dispatch 実証) |
| ROM_A / ROM_B / fixture 差分が trace に反映 | ✅ PASS (= adpcmb_keyon 経路の writes 差分 + wav sha256 差分) |

## 5. 含意 + 次 step 引継

### 含意

- W-1 (= 旧 cmd 0x02 切替) は V-1 PMDNEO.s build top 時の補正だったが、 W-3 で build top を本線に戻したため整合性が破綻していた (= 4 度目の trivial verify 候補だった)
- 4-3-α 補正で「本線 driver + main.c cmd 整合」 確立
- J part dispatch の chain (= cmd 0x05 → init_mml_song → song_main → part_main → keyon_hook → keyon → init_adpcmb_beat) が ROM_B で fully alive、 ただし register 内容は **固定 beat** (= init_adpcmb_beat hardcoded、 sample addr 0x002A/0x00A8、 delta-N 0x6E96、 vol 0xFF、 pan 0xC0)

### 4-3-β/γ/δ 課題 (= 持ち越し)

| sub-commit | 内容 | 範囲 |
|---|---|---|
| 4-3-β | `adpcmb_keyon_hook` (L2509-2512) で `PART_OFF_NOTE(ix)` を A レジスタで `adpcmb_keyon` に引渡し (= refactor のみ、 register 書込内容不変) | standalone_test.s L2509-2512 minimal |
| 4-3-γ | `adpcmb_keyon` (L2571-2573) refactor: A レジスタの note 値を delta-N に変換 + reg 0x19/0x1A に書込み (= 設計書 3 §4-4 「直接 register 書込流儀」)。 sample/vol/pan は beat fixed 維持 | standalone_test.s L2571-2573 + 変換 table |
| 4-3-δ | 2 件の J part fixture (= note 値違い) で register 0x19/0x1A の delta-N 差 + wav 差を verify | fixture + verify script |

### 留意点

- 現状 cmd 0x05 + TEST_MODE_CHORD=5 経路は確立済、 4-3-β/γ/δ で driver 改修を進めても dispatch 経路は不変 (= 安定基盤)
- ROM_A baseline (wav sha256 `3c1f776f...`) は 4-3-β refactor 後も維持する (= no register write 内容変化、 audio 不変期待)
- ROM_B (j-part-minimum.mml fixture) wav は 4-3-γ 後に変わる (= note → delta-N で reg 0x19/0x1A が変わる)

## 6. 関連

- ADR-0016 §決定 3 step 4-3 (= SubE / ADPCM-B 本実装)
- `docs/design/handoff/adr-0016-step4-2-findings.md` (= 4-2 finding、 V-1 era の見立て)
- memory `project_pmdneo_driver_two_paths_discovery.md` (= W-3 後の本線整理)
- memory `feedback_trivial_verify_detection_and_correction_commit.md` (= 4 度目補正規律)
- commit `8fc326a` (= W-1、 cmd 0x02 暫定切替)
- commit `464cff1` (= W-3、 build top revert)
- standalone_test.s L26 (= TEST_MODE_CHORD = 5)
- standalone_test.s L319-322 (= cmd 0x05 → nmi_cmd_5_init_mml_song)
- standalone_test.s L390-402 (= IRQ per-tick song dispatch enable)
- fixture: `src/test-fixtures/step4/j-part-minimum.mml`
