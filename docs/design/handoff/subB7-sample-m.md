# SubB-7 — Codex 向け詳細設計書 (SAMPLE.M 駆動 audio gate Step 1)

	位置付け: Phase 2 SubB-7 = Phase 2 完成手前の最大 milestone
	書き手: Claude Code (= zero-trust orchestration の実装設計担当)
	読み手: Codex (実装担当)
	状態: handoff 待ち

---

## 0. 役割分担

- **Claude Code (= 私)**: 設計書執筆、 完了基準の定義、 Codex 実装後の session log + diff review
- **Codex**: 本書を読んで実装、 build 通過まで持っていく
- **user (越川氏)**: judgment、 Codex 実装後の audio gate 聴感確認

---

## 1. 背景と現状

### 1-1. 直近の到達点

`commit 697ed98` で SubB-5/6 単体検証完了 (= hardcoded MML data でドレミファソラシド、 user 聴感確認済)。 `pmdneo_psgmain` (= per-part main loop) と `commandsp + cmdtblp` (= PSG dispatch table) が動作確認済。

### 1-2. SubB-7 の目的

PMD V4.8s 公式 sample (`vendor/pmd48s/SAMPLE.M`、 1142 byte) を Z80 ROM に組み込み、 driver で **`.m` バイナリ format を解析**して per-part workarea に流し込み、 楽曲再生する。 SubB-7 達成 = **設計書 3 §7-1 の audio gate Step 1 通過 = SAMPLE.M で G/H/I (SSG 3 part) が鳴る**。

### 1-3. SAMPLE.M の構造 (= analysis_m_data_structure.md §3 で完全解析済)

```
file byte 0     : 0x00 (= m_start、 OPNA mode flag = 0)
file byte 1〜26 : m_buf header (24-26 byte)
  m_buf[0..1]   : Part A (FM 1) offset = 0x001A = 26
  m_buf[2..3]   : Part B (FM 2) offset = 0x001B = 27
  m_buf[4..5]   : Part C (FM 3) offset = 0x001C = 28
  m_buf[6..7]   : Part D (FM 4) offset = 0x001D = 29
  m_buf[8..9]   : Part E (FM 5) offset = 0x001E = 30
  m_buf[10..11] : Part F (FM 6) offset = 0x001F = 31
  m_buf[12..13] : Part G (SSG 1) offset = 0x0020 = 32
  m_buf[14..15] : Part H (SSG 2) offset = 0x00F6 = 246
  m_buf[16..17] : Part I (SSG 3) offset = 0x011E = 286
  m_buf[18..19] : Part J (PCM) offset = 0x0251 = 593
  m_buf[20..21] : Part K=R (Rhythm) offset = 0x0452 = 1106
  m_buf[22..23] : rhythm address table offset = 0x0453 = 1107
  m_buf[24..25] : prgdat_adr = 0x045F = 1119
file byte 27〜31 : Part A〜F の empty marker (= 0x80 が並ぶ領域)
file byte 32〜  : Part G の MML body (= 約 213 byte)
file byte 246〜 : Part H の MML body (= 約 39 byte)
file byte 286〜 : Part I の MML body (= 約 306 byte)
file byte 593〜 : Part J / Part R の領域 (= empty、 0x80 のみ)
file byte 1107〜: rhythm address table + prgdat
```

つまり SAMPLE.M は:
- Part A〜F (FM): 全て empty (= 即終了)
- **Part G/H/I (SSG): 実 MML body あり** ← SubB-7 の音響 target
- Part J (ADPCM-B): empty
- Part R (rhythm): empty

PMDNEO の `pmdneo_song_main` は SSG 3 part を loop で `pmdneo_psgmain` に渡すので、 SAMPLE.M を流し込むと G/H/I が並列演奏される (= 期待動作)。

---

## 2. 作業内容

### 2-1. 全体経路

```
user main.c
  *REG_SOUND = 3 (= reset_driver、 nullsound default)
  ng_wait_vblank() × 2
  *REG_SOUND = 2
    ↓
[Z80] snd_command_02_play_song
  ↓
  pmdneo_init (= SSG silent + TIMER-B 起動 + driver state init)
  ↓
  pmdneo_load_m (= 新規実装、 sample_m_data を mmlbuf として load + header 解析)
  ↓
  pmdneo_play_loop (= polling、 既存)
    ↓ TIMER-B tick
  pmd_z80_main → pmdneo_song_main → pmdneo_psgmain × 3 ch
    ↓ Part G/H/I の MML body を解釈、 cmdtblp dispatch
  SSG ch A/B/C で発音
```

### 2-2. 実装する作業

#### Step A: SAMPLE.M を Z80 ROM に組み込む手段

sdasz80 は `.incbin` 未対応 (`/opt/homebrew/bin/z80-neogeo-ihx-sdasz80 --help` で確認、 ASxxxx 系)。 別経路で:

1. **python script を新規作成** (`scripts/bin2db.py` 等):
   - 入力: 任意 binary file
   - 出力: sdasz80 用 `.s` file (= `.db 0x00, 0x1A, 0x00, ...` 形式)
2. **build script (`scripts/build-poc.sh`) を拡張**:
   - SAMPLE.M を `bin2db.py` で `vendor/ngdevkit-examples/00-template/sample_m.s` に変換
   - 既存の symlink loop で `sample_m.s` も追加
3. **PMDNEO.s で include**:
   - `.include "sample_m.s"` で取り込み
   - `sample_m.s` 内で global label `sample_m_data::` + `.db` 列 + `sample_m_end::`
4. **`.gitignore`** に `vendor/ngdevkit-examples/00-template/sample_m.s` を追加 (= build artifact)

#### Step B: pmdneo_load_m routine を新規実装

入力: なし
動作:
1. SAMPLE.M を Z80 ROM 内の `sample_m_data` から読み込む前提
2. `mmlbuf` (= 新規 BSS variable) に `sample_m_data + 1` を格納
   (= `m_buf` 開始 = file byte 1 = ROM address sample_m_data + 1)
3. m_start (= byte 0) を読んで OPNA mode 確認 (= 0x00 想定、 違ったら何もしない or 0x00 として扱う)
4. 11 part 分の offset を per-part workarea の `PART_OFF_ADDR` に流し込む:
   ```
   for part_num in 0..10:
       offset = m_buf[part_num * 2] | (m_buf[part_num * 2 + 1] << 8)  # LE 16-bit
       part_workarea[part_num].PART_OFF_ADDR = mmlbuf + offset
       part_workarea[part_num].PART_OFF_LOOP = 0
       part_workarea[part_num].PART_OFF_LEN = 0
       part_workarea[part_num].PART_OFF_VOLUME = 0x0F   # default max
   ```
5. SSG mixer (0x07) = 0x38 (= 3 ch tone enable、 既に pmdneo_init で設定済だが念のため)
6. driver_song_ready = 1 で song mode 起動

破壊: A、 B、 C、 D、 E、 H、 L、 IX

#### Step C: snd_command_02_play_song の修正

```asm
;; 変更前 (SubB-5/6 単体検証):
snd_command_02_play_song::
        call    pmdneo_init
        call    test_play_psgmain
pmdneo_play_loop::
        ...

;; 変更後 (SubB-7):
snd_command_02_play_song::
        call    pmdneo_init
        call    pmdneo_load_m
pmdneo_play_loop::
        ...
```

`test_play_psgmain` / `test_mml_data` / `test_play_scale` / `scale_notes` は **削除しない** (= 比較対象 + scale demo として残す)。

#### Step D: WORKAREA.inc で `mmlbuf` 変数を追加

```asm
        .area BSS

;;; SubB-7: SAMPLE.M load 用 mmlbuf (= m_buf 開始位置の絶対 address)
mmlbuf::
        .ds 2
```

### 2-3. 変更しない部分

- 既存 `pmdneo_init` (= SSG mixer + TIMER-B 起動 + ei + driver state init)
- 既存 `pmdneo_psgmain` (= per-part main loop + cmdtblp dispatch)
- 既存 `commandsp` + `cmdtblp` + PSG handler 群
- 既存 `pmdneo_song_main` (= 3 ch loop)
- 既存 `test_play_scale` / `scale_notes` / `test_play_psgmain` / `test_mml_data`
- `vendor/ngdevkit-examples/00-template/main.c` (= cmd 3 → cmd 2 経路は維持)

---

## 3. 前提 (Codex が知っておくべき context)

### 3-1. 設計書

- `docs/design/analysis_m_data_structure.md` §2-3 (= `.m` 全体構造 + SAMPLE.M 完全解析)
- `docs/design/analysis_m_data_structure.md` §5-1 (= opcode 0x00-0x7F 音程 + 音長解釈、 OCT 4 bit + ONKAI 4 bit)
- `docs/design/analysis_m_data_structure.md` §4-3 (= cmdtblp 79 entry)
- `docs/design/mn_binary_layout.md` §3 (= 前 26 byte header、 PMDNEO mode flag 0x04 は SAMPLE.M では立たない)

### 3-2. 既存実装 (= Codex が SubB-4 / SubB-5/6 で実装済)

`src/driver/PMD_Z80.inc`:
- `pmdneo_init` / `pmd_z80_main` / `pmdneo_song_main` / `pmdneo_psgmain` / `pmdneo_part_ix_from_part` / `pmdneo_part_fetch_byte` / `pmdneo_psg_keyon/keyoff` / `commandsp` + `cmdtblp` + PSG handler 群
- `psg_tune_data` / `scale_notes` / `test_mml_data` / `test_play_scale` / `test_play_psgmain`

`src/driver/WORKAREA.inc`:
- per-part workarea (`part_workarea` × 17 part × 64 byte)
- `PART_OFF_*` field offset 定数 (ADDR / LOOP / LEN / QDATA / VOLUME / NOTE / 等)
- `driver_state` field 化 (= driver_tempo_d / driver_song_ready / driver_song_base / driver_song_end / 等)
- `scale_step` / `scale_tick_lo/hi` / `pmdneo_irq_count`

### 3-3. PART 番号と SSG ch index

| PART_* 定数 | 番号 | letter | SSG ch |
|---|---|---|---|
| PART_FM1 | 0 | A | (FM 1) |
| ... | ... | ... | ... |
| PART_SSG1 | 6 | G | A |
| PART_SSG2 | 7 | H | B |
| PART_SSG3 | 8 | I | C |
| PART_PCM | 9 | J | (ADPCM-B) |
| PART_RHYTHM | 10 | R | (rhythm) |

### 3-4. 規約 / 罠

- **sdasz80 syntax**: `.area CODE` / `.area DATA` / `.db` / `.dw` / `.equ name, value`
- **`.incbin` は使えない**: python script で `.db` 列に変換する方法を採る
- **重複定義禁止 symbol** (nullsound.lib 提供):
  - `snd_command_unused / 01_prepare_for_rom_switch / 03_reset_driver`
  - `ym2610_write_port_a / port_b`
  - `init_*_state_tracker / update_*_state_tracker`
- **ym2610_write_port_a の calling convention**: `B = register、 C = data` (= input)、 内部で B/C を破壊する可能性 (= SubB-5/6 で `pmdneo_psg_keyoff` に push/pop bc を追加した bug fix と同類)

### 3-5. SAMPLE.M の MML 内容 (= 想定動作)

Part G の最初の数 byte (= file byte 32〜):
- 詳細は SAMPLE.M を hexdump で見るか、 PMD V4.8s mc compiler の入力 SAMPLE.MML と照合
- 想定: 短い tempo 設定 + note 列 + part end

実 MML では:
- com@ (0xFF) = 音色設定 — PSG では PSG envelope set に該当
- comq (0xFE) = gate time
- comv (0xFD) = volume
- comt (0xFC) = tempo
- 0x00-0x7F = note + length

これらが Codex 既実装の handler でほぼ動くはず。 ただし 0x00-0x7F の音程 + 音長解釈 routine (= `pmdneo_psgmain` 内の note 解釈経路) で **PMD V4.8s では length 単位が分音符**(= 4 分音符 = 全音符の 1/4)、 driver 側で tempo + 分音符 → tick 換算が必要。

ただし Codex の現 psgmain は **length をそのまま 1 byte tick として扱う簡易実装**。 これで SAMPLE.M を流すと:
- length 値 (= MML 内の値) がそのまま tick 数になる
- 4 分音符 (= length 24 等) なら 24 tick = TIMER-B 488 µs × 24 ≈ 12 ms (= 短い、 「ぶっ」 と聞こえる)
- 「楽曲」 として聴こえるかは未知、 ただし「複数の音が出る、 切り替わる」 確認は可能

### 3-6. build 経路

- `cd /Users/koshikawamasato/Projects/pmdneo && bash scripts/build-poc.sh`
- build script を拡張する場合は scripts/build-poc.sh を編集

### 3-7. .m header の絶対 address vs 相対 offset

**重要**: `.m` の part offset table は `mmlbuf` (= file byte 1) からの **相対 offset**。 driver では:

```
per-part PART_OFF_ADDR = mmlbuf + offset
                       = (sample_m_data + 1) + (offset 値)
```

つまり sample_m_data が ROM 内の絶対 address になる (= sdasz80 が link 時に決定)。 Codex の psgmain は `PART_OFF_ADDR` を絶対 address として扱う実装。

---

## 4. 完了基準

### 4-1. build 通過

`bash scripts/build-poc.sh` が exit 0 で完了 (= python 変換 + sdasz80 + sdldz80 + ROM 焼込全て成功)。

### 4-2. SAMPLE.M sample data の組み込み確認

- ROM 内に sample_m_data シンボルが存在 (= linker map で確認可能)
- `pmdneo_driver.ihx` size が SubB-5/6 比で +1142 byte 程度増加
- M1 ROM (= 202-m1.m1、 128 KB padded) に sample_m_data 領域が含まれる

### 4-3. audio gate (= 聴感確認、 user 担当)

期待動作:
1. 「PMDNEO Phase 1 PoC」 表示
2. **複数の音が出る**(= G/H/I の SSG 3 part が並列に発音)
3. note が次々切り替わる (= MML 解釈が進んでいる証跡)
4. 楽曲として聴こえなくても OK、 「異音 / 切り替わり / 持続音」 が出れば OK
5. hang up なし (= MML 解釈経路が opcode 全範囲で安全に動作)

### 4-4. 不合格 case の例

- **完全無音**: SAMPLE.M が ROM に組み込まれていない / pmdneo_load_m が走っていない / mmlbuf 計算ミス
- **1 音だけ持続**: pmdneo_load_m で per-part workarea ADDR が間違って set されている (= 全 part が同じ位置を指す等)
- **hang up**: cmdtblp dispatch で 未実装 opcode を踏んで infinite loop
- **異音 (= ノイズ / クラックル)**: SSG mixer 設定 or volume が壊れている

### 4-5. user 報告内容 (= Codex から user に渡す)

- build 結果 (exit code、 PMDNEO.rel size、 pmdneo_driver.ihx size、 sample_m_data 組み込み確認)
- 聴感確認は user 担当のため、 Codex は **commit せず diff のまま終了**
- Claude Code が session log + diff を review して user report、 user 判断で commit + push

---

## 5. 注意点

### 5-1. SAMPLE.M の length 単位の罠

PMD V4.8s では length byte が **MML 上の音長表現**(= 4 分音符 = 24 tick @ default tempo 等) で、 driver 側で tempo に応じて変換するのが本来の仕様。 Codex の現 psgmain は length を **そのまま 1 byte tick として扱う簡易実装**で、 SAMPLE.M を流しても「楽曲」 にはならない可能性が高い。

それでも:
- 各 note は短時間で切り替わる
- 複数 part が並列演奏される
- 「異音 / クラックル なし」 + 「音は出る」 で SubB-7 audio gate 通過

楽曲として正しく聴こえる実装は **SubC (= FM 6ch dispatch + 音色 set) や Phase 2 SubF (= 統合) で詰める**。 SubB-7 ではあくまで **psgmain 経路の汎用性確認**が目的。

### 5-2. cmdtblp で未対応 opcode を踏む可能性

SAMPLE.M の Part G/H/I は SSG part だが、 PMD V4.8s mc compiler は同じ MML を全 part 共通の opcode で出力する。 Part G が踏む opcode は:
- com@ (0xFF) = 音色番号 (= PSG envelope set 用)
- comq / comv / comt
- 各種 LFO / pan 系

cmdtblp の対応 entry は Codex が SubB-5/6 で実装済 (= 79 entry 全て埋まっている)。 ただし一部 handler は no-op (= 引数 byte 消費のみ) なので、 機能的に rich でなくても si pointer ずれない (= PMD ファミリ「未対応 cmd スルー」 思想)。

### 5-3. driver_song_ready flag

`pmdneo_load_m` の最後で `driver_song_ready = 1` set。 これで `pmd_z80_main` が `pmdneo_song_main` 経路に分岐し、 G/H/I の psgmain が呼ばれる。

ただし、 既存の `test_play_psgmain` も同じ `driver_song_ready = 1` を set している。 つまり cmd 2 で `test_play_psgmain` ではなく `pmdneo_load_m` を call すれば、 driver_song_ready = 1 + per-part workarea が SAMPLE.M 由来 という違いが生まれる。

### 5-4. python script は自動化

`scripts/bin2db.py` は build script 内で自動実行。 user が手動で run する必要なし。

### 5-5. SAMPLE.M の更新性

将来 SAMPLE2.M / SSGEG_S.M / 自作 .m 等に切り替えるための **拡張性**は SubB-7 では不要。 hardcoded で SAMPLE.M を 1 個組み込めば OK。 拡張性は SubF (= 統合) や Phase 3-4 で。

### 5-6. audio gate 義務

driver/runtime 層 touch なので、 commit 前に user 聴感確認が **必須**。 Codex は build 通過まで、 commit + push は user 確認後に Claude Code が担当。

---

## 6. 参照

### 6-1. 既存 file

- `src/driver/PMD_Z80.inc` (= Codex 既実装の psgmain 経路)
- `src/driver/WORKAREA.inc` (= field offset 定数 + driver_song_ready 定義)
- `src/driver/IRQ.inc` (= snd_command_02_play_song を変更)
- `scripts/build-poc.sh` (= build 自動化、 拡張対象)
- `vendor/pmd48s/SAMPLE.M` (= 取込対象 binary、 1142 byte)

### 6-2. 設計書

- `docs/design/analysis_m_data_structure.md` (= `.m` 完全解析、 1377 行)
- `docs/design/mn_binary_layout.md` §3 (= 前 26 byte header)
- `docs/design/phase2_driver_plan.md` §7-1 (= audio gate Step 1 = 「SAMPLE.M で SSG 3 part 鳴らす」)
- `docs/design/handoff/subB5-6-mml-test.md` (= 直前の SubB-5/6 検証 handoff 書、 patternの参考)

### 6-3. python script の例 (= 参考実装)

```python
#!/usr/bin/env python3
# scripts/bin2db.py — binary file を sdasz80 用 .s file に変換
import sys

def main():
    if len(sys.argv) < 4:
        print("usage: bin2db.py <input> <output> <symbol_name>", file=sys.stderr)
        sys.exit(1)
    in_path, out_path, sym = sys.argv[1], sys.argv[2], sys.argv[3]
    with open(in_path, 'rb') as f:
        data = f.read()
    with open(out_path, 'w') as f:
        f.write(f';;; auto-generated from {in_path}\n')
        f.write(f';;; size = {len(data)} byte\n')
        f.write('        .area CODE\n\n')
        f.write(f'{sym}::\n')
        for i in range(0, len(data), 16):
            chunk = data[i:i+16]
            f.write('        .db ' + ', '.join(f'0x{b:02X}' for b in chunk) + '\n')
        f.write(f'{sym}_end::\n')

if __name__ == '__main__':
    main()
```

build-poc.sh への追加:
```bash
# SAMPLE.M を sdasz80 用 .s に変換
"$PMDNEO_ROOT/scripts/bin2db.py" \
    "$PMDNEO_ROOT/vendor/pmd48s/SAMPLE.M" \
    "$TEMPLATE_DIR/sample_m.s" \
    "sample_m_data"
```

PMDNEO.s への追加:
```asm
        .include "sample_m.s"
```

---

## 7. 想定 commit message (= Claude Code review 後)

```
feat(driver): SubB-7 — SAMPLE.M 駆動 audio gate Step 1 通過

PMD V4.8s 公式 sample (vendor/pmd48s/SAMPLE.M、 1142 byte) を Z80 ROM に
組み込み、 driver で .m header 解析 → per-part workarea 流し込み →
psgmain 経路で SSG 3 part (G/H/I) 並列演奏。 user 聴感確認: 複数音発音 +
note 切替が確認できた。

実装内容 (Codex 担当、 Claude Code 設計):
- scripts/bin2db.py 新設 (= binary → sdasz80 .s 変換 python script)
- scripts/build-poc.sh 拡張 (= SAMPLE.M を sample_m.s に変換 step)
- PMDNEO.s: .include "sample_m.s" 追加
- PMD_Z80.inc: pmdneo_load_m routine 新設 (= SAMPLE.M を mmlbuf として
  load + 11 part offset 解析 + per-part workarea 流し込み + driver_song_ready set)
- IRQ.inc: snd_command_02_play_song の call 先を test_play_psgmain →
  pmdneo_load_m に変更
- WORKAREA.inc: mmlbuf BSS 変数追加 (2 byte)
- .gitignore: vendor/.../00-template/sample_m.s を除外
- docs/design/handoff/subB7-sample-m.md: 指示書

audio gate (= memory rule):
- SSG 3 part (G/H/I) が並列演奏 (= user 聴感確認)
- 複数音 + note 切替 + hang up なし
- 楽曲として完全に聴こえなくても OK (= length 換算は SubC/SubF で精緻化)

これで Phase 2 SubB-7 = audio gate Step 1 通過。 SubB 全完了、 Phase 2
SubC (= FM 6ch dispatch) に進む準備完成。

Co-Authored-By: Codex (codex-rescue) <noreply@openai.com>
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

---

[本書は handoff 待ち。 user OK で Codex に渡す]
