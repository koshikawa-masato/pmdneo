# 軸 G sub-sprint ε integration audition request (= 越川氏 audition 用、 reject 1 回目 fix 後 round 2)

ADR-0048 §決定 8 案 C 経路の ε integration + audition gate。 δ で実装した `.PPC` runtime selection proof が、 同一 MAME 起動内で既存 yaml passthrough 経路 + ADPCM-A 経路と同居して破綻しないことを越川氏 audition で確認するための request 文書。

## ε reject 1 回目 → round 2 fix 経緯 (= 36th session、 主軸単独 + Codex layer 2 review)

### reject 1 回目時の状況 (= 35th session 末)

越川氏 audition で「両 wav とも `.PPC` 由来 ADPCM-B が鳴っていない」 reject。

### 主軸 5 件切り分け (= user 指示通り literal 確認)

| 切り分け | finding | result |
|---|---|---|
| 1: clean rebuild で TEST_MODE_AXIS_G_INT=1 effective か | preprocessed.s に `.equ TEST_MODE_AXIS_G_INT, 1` literal + IRQ block literal 反映済 | PASS (= sed 経路は正常) |
| 2: 1 秒以降に reg 0x10 keyon が出ているか trace | reg 0x10 = 0x80 は audition build で **0 件** | **FAIL** (= ADPCM-B keyon が起きていない) |
| 3: 4 layer offset 突き合わせ | entry 0 START=0x0400 + blob_base=0x00AF = 0x04AF、 blob 範囲 (= 0x00AF-0x00B0) を遥か超え (= V-ROM uninitialized 領域 273 KB 後) | **FAIL** (= entry word が blob 範囲外) |
| 4: minimum.PPC filler が ADPCM-B として可聴か | filler PCM data = `(i & 0x7F)` deterministic byte = ADPCM-B として非可聴 (= 仮に正しい addr を指しても音が出ない fixture) | **FAIL** (= user 補足通り) |
| 5: TIMER-B IRQ rate 確認 | z80-mem-trace で 0xF816 (= pmdneo_irq_count) への write が 6 秒で **3 件のみ** (= IRQ 2 回しか発火していない) | **FAIL** (= 1 秒後 trigger は IRQ 経路で不能、 別 sprint 改修 scope) |

### round 2 fix 内容 (= 36th session、 ε reject 1 回目 root cause 反映、 3 件修正)

| 修正 | before (= reject 1 回目時) | after (= round 2 fix) |
|---|---|---|
| 1. minimum.PPC fixture | entry 0 START=0x0400 / STOP=0x0480 (= blob 範囲外を指す nonzero word) + PCM data filler 256 byte (= ADPCM-B として非可聴) | entry 0 START=0x0000 / STOP=0x0004 (= blob 内 1024 byte 範囲) + PCM data = 既存 beat sample raw byte slice 1024 byte (= audible ADPCM-B、 既存 V-ROM 焼き 済 sample から抽出) |
| 2. driver source 強制 keyon 位置 | IRQ handler 内 (= 1 秒後 trigger 想定、 ただし IRQ tick 不足で発火せず) | init 経路 (= cold boot 直後 1 度 trigger、 IRQ counter 不要) |
| 3. verify script expected reg | entry 0 = 0xAF/0x04/0x2F/0x05 (= 旧 mapping-B 期待値) | entry 0 = 0xAF/0x00/0xB3/0x00 (= 新 fixture mapping-B 期待値) |

### round 2 fix trace 確認 (= 修正後 reg 0x10 keyon literal)

```
reg 0x10 = 0x80 keyon trigger: write_idx 9 (= init 経路、 1 件発火)
reg 0x12 = 0xAF  (= entry 0 START LSB、 mapping-B literal)
reg 0x13 = 0x00  (= entry 0 START MSB)
reg 0x14 = 0xB3  (= entry 0 STOP LSB、 mapping-B literal)
reg 0x15 = 0x00  (= entry 0 STOP MSB)
```

= driver の強制 keyon が effective、 `.PPC` 経路 entry 0 sample (= blob 内 1024 byte audible beat slice) で keyon trigger 発火。

## audition 用 wav file (= round 2 fix 後)

| wav | path | size | 内容 |
|---|---|---|---|
| production | `/tmp/pmdneo-axis-g-production.wav` | 1152048 byte (= 6 秒、 48 kHz stereo) | TEST_MODE_AXIS_G_INT=0 (= production default)、 既存 ADR-0043 経路 + ADPCM-A 経路通常運転、 軸 G 経路は呼ばれない |
| audition | `/tmp/pmdneo-axis-g-audition.wav` | 1152048 byte (= 6 秒、 48 kHz stereo) | TEST_MODE_AXIS_G_INT=1 (= ε integration audition build)、 **cold boot 直後 1 度** `.PPC` 経路 entry 0 sample で ADPCM-B keyon trigger + 既存経路通常運転 |

sha256 literal (= audio が違うことの literal 証跡):

```
production: e48cf7731f0862ccd153c4aee2803f12946667eb1ef8417812137cccee082920
audition:   928093c094a7b2f6d1877d10a0dd836f791cd7177a3cd12374d181098f2c9b3a
```

## 確認してほしい点 (= round 2 fix 後)

1. **audition wav で `.PPC` 経路の音が「鳴っている」 か** (= cold boot 直後 1-2 秒目あたりで ADPCM-B beat 系の音が 1 回再生される、 既存 beat sample slice 1024 byte の音、 約 0.055 秒の短い音)
2. **production wav に同じ音は無い** (= production = TEST_MODE_AXIS_G_INT=0、 軸 G 経路 disabled で `.PPC` 経路の keyon は発火しない)
3. **両 wav で ADPCM-A 経路 + FM 経路が同じく鳴っている** (= 軸 G 経路追加で既存経路を壊していない)
4. **audition wav の冒頭 1 回分の `.PPC` keyon 以外は production と同じ** (= audition build は cold boot 1 度 trigger のみ、 以降は production と同じ動作)

注意: `.PPC` 経路の音 = 既存 yaml beat sample の raw byte slice なので、 「既存 beat の冒頭 0.055 秒」 と同 音色。 既存 yaml passthrough 経路 + `.PPC` 経路で同じ音が鳴ることになる (= sample data 自体は同 source、 経路だけ differ)。

## 再現手順 (= Codex layer 2 nice-to-have #3 literal、 audition wav の regenerate)

```bash
# production build wav (= TEST_MODE_AXIS_G_INT=0、 既存 default)
bash scripts/run-mame.sh --build --headless --wavwrite --wavwrite-seconds 6
cp /tmp/pmdneo-trace/audio.wav /tmp/pmdneo-axis-g-production.wav

# audition build wav (= TEST_MODE_AXIS_G_INT=1、 ε integration mode、 init で 1 度強制 keyon)
PMDNEO_AXIS_G_INT=1 bash scripts/run-mame.sh --build --headless --wavwrite --wavwrite-seconds 6
cp /tmp/pmdneo-trace/audio.wav /tmp/pmdneo-axis-g-audition.wav

# sha256 比較
shasum -a 256 /tmp/pmdneo-axis-g-production.wav /tmp/pmdneo-axis-g-audition.wav

# 視聴 (= macOS afplay)
afplay /tmp/pmdneo-axis-g-production.wav
afplay /tmp/pmdneo-axis-g-audition.wav
```

## minimum.PPC 再生成手順 (= audible fixture regenerate)

```bash
python3 -c "
import struct
vrom = open('vendor/ngdevkit-examples/00-template/build/rom/243-v1.v1', 'rb').read()
beat_raw = vrom[0x2A00:0x2E00]  # 1024 byte = 既存 yaml beat sample (BEAT_START_LSB=0x2a)
assert len(beat_raw) == 1024
buf = bytearray()
buf += (b'ADPCM DATA for  PMD ver.4.4-  ' + b'\\x00' * 30)[:30]
buf += struct.pack('<H', 0x0004)  # Next START = 0x0004
buf += struct.pack('<HH', 0x0000, 0x0004)  # entry 0: blob 全範囲 (= 1024 byte)
buf += struct.pack('<HH', 0x0002, 0x0004)  # entry 1: blob 後半 (= 512 byte)
for _ in range(254):
    buf += struct.pack('<HH', 0, 0)
buf += beat_raw
open('src/test-fixtures/axis-g/minimum.PPC', 'wb').write(buf)
"
```

## audition 結果待ち

越川氏 audition approve (= round 2 fix で「audition wav に `.PPC` 経路の音が確認できる + production wav には無い + 既存経路は両 wav 同じ」) を受領後、 ADR-0048 Draft → Accepted 移行 + ε 完了 section literal + dashboard 軸 G 完了 update + PR2 作成 + merge を主軸が実施します。

audition reject (= 何か破綻 / 期待と違う音 / 別の問題) の場合は driver 改修 + 再 audition request。

## scope-out (= 本 audition 対象外)

- aesthetic 評価 (= テンポ、 音色、 mix balance、 timing artifact 等の趣味判断)
- 1 秒後 trigger 想定 (= IRQ counter 経路、 既存 TIMER-B 構造改修必要で別 sprint scope)
- 真の「同居 audition」 (= 同一 keyon timing で yaml + .PPC + ADPCM-A が並走する fixture、 別 sprint で MML 拡張など)
- vendor wav 3 件 (= 永続 untracked retain、 audition 対象外)

## 関連 ADR + memory

- ADR-0048 §決定 8 案 C (= mapping-B 確定 + ROM directory region 設計 + ppc-to-ngdevkit.py 経路)
- ADR-0048 sub-sprint δ 完了 section (= driver 改修 + verify gate 7/7 PASS literal)
- ADR-0041 §決定 4-2 例外 (= user audition は永久 user scope)
- memory `feedback_audio_gate_solo_isolation.md` (= audio gate 規律)

ε PR1 (= 本 commit chain、 reject 1 回目 + round 2 fix 経緯含む) は audition requested 状態で OPEN 維持。 round 2 fix で audition approve 受領後、 PR1 merge + PR2 で ADR-0048 Accepted + ε 完了 section + dashboard sync + 軸 G 完了 を実施。
