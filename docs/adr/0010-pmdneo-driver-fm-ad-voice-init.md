# ADR-0010: PMDNEO driver A/D voice 初期化漏れ修正 + MAME chip emulation 制約の整理 (= ym2610b mode の FM 6 ch voice setup 拡張 / MAME 検証は別 sprint)

- 状態: Accepted
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0001 (= FM ch1/ch4 no use policy 旧方針)、 ADR-0006 §B (= chip target / A/D 発音規約)、 ADR-0009 (= PAN 規律、 A/D silent 真因 PAN 否定 → 別 sprint)

## 背景

ADR-0009 PAN 規律完了後の MAME ym2610b mode 録音検証で、 A (ch1) / D (ch4) の PAN reg 0xB4 を Center (0xC0) に明示書込しても完全 silent (= raw byte 0) であることが判明済。 ADR-0009 §C で「A/D silent の真因は PAN ではない」 と切分けされ、 voice 設定 / keyon dispatch / TL ハードコード / その他経路が別 sprint 課題 (= 本 ADR-0010) として残されていた。

## 当初仮説 (= driver source 静解析)

driver source `src/driver/standalone_test.s` 読込で確認:

| 経路 | A (ch1) / D (ch4) 対応状況 |
|---|---|
| PAN init (reg 0xB4) | ADR-0009 §A で ym2610b 限定で 0xC0 書込済 ✓ |
| keyon (reg 0x28) | `fm_keyon` + `fm_keyon_values` が bit 2 (port A/B select) を含む 0xF0/0xF4 等で chip ch1-6 全対応 ✓ |
| fnum (reg 0xA0-A6) | `fnumset_fm` 内 `cp #3; jr c, fnumset_fm_porta` で port A/B 自動切替 ✓ |
| volume (TL reg 0x40-0x4C) | `fm_volume_hook` 内 `cp #3; jr nc, fm_volume_hook_portb` で port A/B 自動切替 ✓ |
| **voice setup (reg 0x30-0x9F + 0xB0)** | **`init_chip_ch2_voice` (line 956-965) が ch index 1, 2, 4, 5 のみ voice setup、 ch index 0 (A) / 3 (D) を skip ✗** |

`init_chip_ch2_voice` は ADR-0001 期「FM ch1/ch4 不使用」 方針下で「鳴る 4 ch のみ voice setup」 として書かれた遺物。 ADR-0006 §B (= 「ym2610b mode で 6 ch 全部発音、 A/D も init」) 定立で voice setup 経路も追従更新が必要だったが、 PAN 経路のみ ADR-0009 §A で追従して voice 経路は取り残されていた。

## driver fix 実装 + ymfm trace 実測 verify

仮説に基づき driver fix を実装:

- `init_chip_ch2_voice` (line 956 周辺) に `.if PMDNEO_TARGET_CHIP_YM2610B` conditional で ch index 0 (A) と ch index 3 (D) の voice setup を追加
- B/C/E/F (= ch index 1/2/4/5) の voice setup は不変 (= ym2610 / ym2610b 共通で常時実行)
- ADR-0009 §A の PAN init block と parallel な構造

build + MAME ym2610b mode + ymfm trace 実測 (= `vendor/mame-fork/neogeo` 改造 binary で `/tmp/pmdneo-trace/ymfm-trace.tsv` 取得) の結果:

```
Per-ch FM voice register write counts (trace 解析):
  ch1 (A): DT/ML 4, TL 8, KS/AR 4, AMS/DR 4, SR 4, SL/RR 4, SSG-EG 8, FNUM 4, ALG/PAN 3 ✓
  ch2 (B): 同上 ✓
  ch3 (C): 同上 (= FNUM なし、 MML で C 音なし) ✓
  ch4 (D): 同上 ✓
  ch5 (E): 同上 ✓
  ch6 (F): 同上 ✓

keyon (reg 0x28 port A):
  idx=315 val=0xF0 (= ch1 A keyon, 4 op enable) ✓
  idx=320 val=0xF1 (= ch2 B keyon) ✓
  idx=325 val=0xF4 (= ch4 D keyon, port B select) ✓

fnum (reg 0xA0-A6):
  ch1 (A) block=4 fnum=0x26A → 261.9 Hz (= MIDI C4) 書込済 ✓
  ch2 (B) block=4 fnum=0x30B → 330.5 Hz (= MIDI E4) 書込済 ✓
  ch4 (D) block=4 fnum=0x39E → 392.4 Hz (= MIDI G4) 書込済 ✓
```

つまり **driver fix は完璧に動作**、 全 6 FM ch の voice 設定 + ch1/2/4 の keyon/fnum 書込が ymfm chip register file に届いている。

## MAME 動作確認結果と真の制約発見

しかし MAME 録音 (= `/tmp/pmdneo-trace/audio.wav`) では:

| 期待 (= PMD V4.8s 規約 + driver fix 完了) | 実測 |
|---|---|
| A (= ch1) C4 = 261.9 Hz 発音 | silent (= raw 0) |
| B (= ch2) E4 = 330.5 Hz 発音 | 330 Hz 確認 ✓ |
| D (= ch4) G4 = 392.4 Hz 発音 | silent (= raw 0) |

ymfm chip register file には A/D の voice/keyon/fnum 書込が到達しているのに、 audio output 経路で発音されない。 真因 source code 確認 (= `vendor/mame-fork/src/mame/neogeo/neogeo.cpp:1964`):

```cpp
YM2610(config, m_ym, NEOGEO_YM2610_CLOCK);
```

MAME NEOGEO driver は **YM2610** chip device を instantiate しており、 **YM2610B ではない**。 ymfm 内部で YM2610 emulation は datasheet 仕様通り「FM 4 ch (= ch2/3/5/6) + ADPCM-A 6 ch + ADPCM-B 1 ch」 として動作し、 ch1/ch4 への FM voice/keyon/fnum 書込は **register file に保存される**が **audio output 経路では発音されない** (= chip device の internal mute)。

つまり A/D silent の真因は driver の voice 設定漏れ + MAME chip emulation の制約の 2 段:

1. **driver 側**: `init_chip_ch2_voice` の A/D voice setup 漏れ (= 本 ADR で fix 完了)
2. **MAME 側**: NEOGEO driver の YM2610 instantiate (= AES+ YM2610B 環境を MAME 上で再現するには別 sprint で MAME 改造必要)

実機 AES+ (= YM2610B 改造ハードウェア) では本 ADR の driver fix で正しく動作する想定 (= 実機検証は別途必要)。

## 決定

### A. `init_chip_ch2_voice` を 6 FM ch 全対応に書換 (= ADR-0006 §B 準拠)

`src/driver/standalone_test.s:956-965` を ADR-0006 §B の chip target 規律に整合させ、 A (ch index 0) と D (ch index 3) の voice setup を `.if PMDNEO_TARGET_CHIP_YM2610B` conditional で追加。

実装後 (= 本 sprint で commit 済):

```asm
init_chip_ch2_voice:
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      b, #0                   ; chip ch 1 (A) [ym2610b 限定]
        call    pmdneo_fm_voice_set_default
.endif
        ld      b, #1                   ; chip ch 2 (B)
        call    pmdneo_fm_voice_set_default
        ld      b, #2                   ; chip ch 3 (C)
        call    pmdneo_fm_voice_set_default
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      b, #3                   ; chip ch 4 (D) [ym2610b 限定]
        call    pmdneo_fm_voice_set_default
.endif
        ld      b, #4                   ; chip ch 5 (E)
        call    pmdneo_fm_voice_set_default
        ld      b, #5                   ; chip ch 6 (F)
        call    pmdneo_fm_voice_set_default
        ret
```

### B. driver fix の動作確認 oracle

ymfm trace (= `vendor/mame-fork/neogeo` 改造 binary + `--trace` option) で driver からの reg 書込を実測 verify。 本 sprint の trace で 6 FM ch 全 voice setup + ch1/ch2/ch4 keyon/fnum 書込到達を確認済 (= `/tmp/pmdneo-trace/ymfm-trace.tsv` 4252 行)。

audio output ではなく **register write trace** が driver fix の primary oracle。 audio 経路は MAME chip mismatch (= §C) で抑制されるため、 trace が driver 機能の唯一の客観的 verify。

### C. MAME chip mismatch 制約は別 sprint 扱い (= ADR-0010 範囲外)

MAME NEOGEO driver は YM2610 chip instantiate で、 A/D FM 経路を audio output から抑制する。 本 ADR では:

- MAME 上での audio verify は **不可能** と認める (= 駆動 chip の根本的制約)
- driver fix の verify oracle は ymfm trace の register write 到達確認に切替
- AES+ 実機 (= YM2610B) での audio verify は別 sprint
- MAME 改造 (= neogeo.cpp の YM2610 → YM2610B 切替、 or 専用 machine 定義) も別 sprint

これら別 sprint の枠組みは ADR-0006 §5 検証 sprint or 新規 ADR で扱う。

### D. label 命名は touched せず (= scope 厳守)

label 名 `init_chip_ch2_voice` は ADR-0001 期の「ch2 系」 命名で実体と乖離するが、 本 ADR では機能 fix のみに scope を絞り、 命名 refactor は別 sprint 扱い。 「バグ修正に余計なリファクタを混ぜない」 (= CLAUDE.md) 規律遵守。

### E. octave +1 shift 観察の確証 (= ADR-0011 想定への引継)

trace 実測で octave +1 shift も同時確証 (= ADR-0009 §D 観察を数値で固定):

- MML `o4 c` → trace で ch1 fnum 0x26A block=4 → 実周波数 261.9 Hz (= MIDI C4)
- PMD V4.8s 規約 (= `o5 c = MIDI C4 = 261 Hz`) 期待値: 131 Hz (= MIDI C3)
- driver の音階計算 (= `scale_notes_fm` or octave 変換経路 + fnum table) で +1 octave shift

ch2 B の `o4 e` も実周波数 330.5 Hz = MIDI E4 (= 期待 165 Hz = E3 から +1 octave)、 ch4 D の `o4 g` も実周波数 392.4 Hz = MIDI G4 (= 期待 196 Hz = G3 から +1 octave) で一貫した +1 octave shift。

これは ADR-0011 想定 sprint で fnum table + o_offset 検証で fix。

## 影響

- ym2610b mode (= AES+ 想定) で A/D voice 設定が完備 (= ADR-0006 §B 規約を実体化、 AES+ 実機で動作する想定)
- MAME 上では NEOGEO driver の YM2610 chip 制約で A/D は audible にならない (= MAME 検証は別 sprint)
- ymfm trace ベースで driver 機能の verify は確立 (= register write trace を oracle に)
- ym2610 mode (= default) は不変 (= conditional 内 A/D init は skip、 default 経路の挙動変化なし)
- octave +1 shift bug (= ADR-0011 想定) は本 ADR で touched せず、 別 sprint で対応

## 残論点 / 後続 sprint

- **ADR-0011 (= 想定、 着手予定)**: octave +1 shift 修正 (= fnum table + o_offset 検証)、 trace 実測値 (= o4 c → 262 Hz = MIDI C4 で PMD V4.8s 規約から +1 oct) を起点
- **MAME chip mismatch 解消** (= 別 sprint): neogeo.cpp の YM2610 → YM2610B 切替か、 専用 machine 定義 (= neogeo_aesplus 等)
- **AES+ 実機検証** (= 別 sprint): 本 ADR driver fix の実機 audible 検証
- **ADR-0006 §5 検証**: 28 entry baseline 再取得 (= 上記 sprint 群完了後)
- **MML `p` cmd 実装**: PAN 動的制御 (= 本 ADR §D 命名 refactor と並行可)
- **init_chip_ch2_voice 命名 refactor**: 別 sprint、 内容実態を反映する名前 (= 例 `init_fm_audible_voices`) へ

## 改訂履歴

- **2026-05-11 起票 + 訂正**: 初版起票 → MAME 動作確認で真因が「driver fix 漏れ」 ではなく「driver fix は完成 + MAME chip mismatch」 の 2 段であることが trace 実測で判明、 全文を root cause 訂正版へ書換 (= 同日内)

## 参照

- ADR-0001 (C) 方針 (= 「楽曲側 A/D 不使用」 旧設計の `init_chip_ch2_voice` 命名由来)
- ADR-0006 §B: PMDNEO_TARGET_CHIP_YM2610B 条件で A/D init 経路有効化
- ADR-0009 §A/C: PAN init 経路の A/D 追加 + silent 真因 PAN 否定
- `vendor/mame-fork/src/mame/neogeo/neogeo.cpp:1964`: NEOGEO driver の YM2610 instantiate (= MAME chip mismatch の根拠)
- memory `feedback_step_pacing_and_artifact_attribution.md`: 検証 wav の出自明示規律
- memory `feedback_record_unexpected_findings.md`: trace 解析で「port B の reg は 0x100 offset で記録される」 という ymfm fork 流儀の罠
- YM2610 / YM2610B datasheet: chip 内部 FM ch enable (= YM2610 は ch2/3/5/6 のみ FM、 ch1/4 ADPCM 専用)
