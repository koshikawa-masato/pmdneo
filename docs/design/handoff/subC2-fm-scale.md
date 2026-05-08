# SubC-2 — FM 1 ch スケール (chip ch 2)

	位置付け: Phase 2 SubC 段階分割の 2 番目 (= FM 駆動の音程変化確認)
	書き手: Claude Code
	実装担当: Claude Code (= 規模小、 直接実装、 SubC-1 +1 修正と同流儀)
	状態: 完了 (audio gate pass、 commit 済)

---

## 0. 背景

### 0-1. SubC-1 達成 (commit 23f1bd4)

- chip ch 2 (= ADR-0001 (C) 方針) で C4 hardcoded 持続音 audio gate pass
- fm_voice_data_default (25 byte) + fnum_data + fnumset_fm + test_play_fm_c4
- IRQ.inc snd_command_02_play_song dispatch を test_play_fm_c4 に

### 0-2. SubC-2 = chip ch 2 で FM スケール (= ドレミファソラシド)

SubB-4 の SSG スケール (= test_play_scale + pmd_z80_main_scale 経路) を
FM mode で再利用する。 既存の scale_step / scale_tick_lo/hi / scale_notes
を流用し、 fnumsetp ↔ fnumset_fm の切替を driver state の scale_mode
flag で制御する。

---

## 1. 実装内容

### 1-1. WORKAREA.inc

- `scale_mode` (1 byte) 追加
  - 0 = SSG (= 既存 SubB-4 動作)
  - 1 = FM chip ch 2 (= SubC-2 新規)

### 1-2. PMD_Z80.inc

- `pmdneo_init` 末尾で `scale_mode = 0` 初期化 (= 既存 SubB-4 互換)
- `test_play_fm_scale_b` 新設:
  1. SubC-1 の test_play_fm_c4 と同じ音色 set + PAN + ALG/FB
  2. scale_mode = 1
  3. scale_step = 0
  4. scale_tick_lo/hi = SCALE_TICK_INITIAL
  5. scale_notes[0] (= C4) を fnumset_fm
  6. keyon (= 0xF1)
  7. ret (= polling loop へ戻る)
- `pmd_z80_main_scale_step` 拡張:
  - scale_mode を読んで 1 ならば fnumset_fm、 0 ならば既存 fnumsetp
- `pmd_z80_main_scale_stop` 拡張:
  - scale_mode = 1 ならば chip ch 2 keyoff (= 0x28 ← 0x01)
  - scale_mode = 0 ならば既存 SSG keyoff

### 1-3. IRQ.inc

- `snd_command_02_play_song` dispatch を test_play_fm_c4 → test_play_fm_scale_b
- comment を「chip ch 2 hardcoded C4 持続音」 → 「chip ch 2 FM スケール」

---

## 2. 完了基準

### 2-1. build pass

`bash scripts/build-poc.sh` exit 0。

### 2-2. audio gate (= user 聴感確認)

期待動作:
- chip ch 2 (= Part B) から **ドレミファソラシド** の 1 octave スケール
- FM 音色 (= ALG=7 + 4 op carrier、 SubC-1 と同じ「ぼー」 系)
- 各 note 約 1 秒 (= SCALE_TICK_INITIAL に依存)
- 最後のド (= 8 note 目) 終了後 keyoff、 静音

不合格 case:
- 持続音のまま音程変化なし: scale_mode 切替失敗 / fnumset_fm が呼ばれていない
- 単音のみ: scale_step 進まず
- 音程ずれ: scale_notes table 解釈エラー

### 2-3. user 報告

- build 結果
- gngeo 起動 + 聴感確認

---

## 3. 注意点

### 3-1. FM の fnum 切替で envelope 再 trigger 不要

FM ch で keyon 状態を維持したまま fnum を変えると、 envelope は維持され
frequency だけ変わる (= legato 効果)。 SubC-2 では note 切替時に keyoff/keyon
は行わず、 fnumset_fm のみ呼ぶ。

scale 終端 (= 8 note 目以降) のみ keyoff (= 0x28 ← 0x01 = ch 2 全 op keyoff)。

### 3-2. SCALE_TICK_INITIAL は SubB-4 と同じ値

SubB-4 で「約 1 秒/note」 が確認されているため、 SubC-2 でも同 value 流用。

### 3-3. ADR-0001 (C) 方針の維持

driver は YM2610B 仕様で書く方針だが、 SubC-2 では chip ch 2 のみ駆動。
他 ch (= chip ch 3/5/6) は SubC-3 で 4 ch dispatch 設計時に追加する。

---

## 4. 参照

- `src/driver/PMD_Z80.inc`: 既存 test_play_scale (SubB-4)、 fnumset_fm (SubC-1)
- `src/driver/WORKAREA.inc`: scale_step / scale_tick_lo/hi (SubB-4)
- ADR-0001 `docs/adr/0001-fm-ch1-ch4-no-use-policy.md`
- handoff `docs/design/handoff/subC1-fm-single-note.md`
