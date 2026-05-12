# ADR-0016 step 5 α-2 trace gate findings + α-3 verify infrastructure

- 起票日: 2026-05-12 (= 6th session α-3)
- 起票者: Claude Code
- 関連: α-2 commit `ae6b419`、 α-1 commit `3e01f48`、 ADR-0019 §決定 6

## 概要

**α-3 は検証 infrastructure commit** (= driver 実装変更なし)。 α-2 (= `.MN direct path` + L part dispatch) で成立した「`.MN` → L body → ADPCM-A keyon」 経路を **regression test 化**、 後続 β/γ/δ sub-sprint で挙動回帰を検出可能にする。

driver 変更なし、 既存挙動を **固定 verify** するのみ。

## α-2 成果 (= 本 doc で固定する対象)

α-2 (= commit `ae6b419`) で:
- `standalone_test.s` に新規 routine `pmdneo_mn_direct_load_l_part_addr` 追加
- L part init 部分に `.if PMDNEO_USE_PMDDOTNET == 1` 分岐追加
- 6 段階 trace gate を MAME で手動確認

α-3 で上記を **自動化** + **handoff doc に永続化**。

## verify script

### 場所

`src/test-fixtures/step5/verify-l-part-alpha-trace-gate.sh`

### 使い方

```bash
bash src/test-fixtures/step5/verify-l-part-alpha-trace-gate.sh
```

### Exit code

| code | 意味 |
|---|---|
| 0 | PASS (= 全 6 gate 通過) |
| 1 | verify fail (= 1 つ以上 gate 落ち、 出力で fail gate 明示) |
| 2 | infra fail (= build / MAME / trace file / listing missing 等) |

### 動作

1. fixture 存在確認
2. `build-poc.sh` で build (= `PMDDOTNET_MML` + `PMDDOTNET_MODE=B` + `PMDNEO_USE_PMDDOTNET=1`)
3. `standalone_test.lst` から **pmddotnet_song symbol addr を動的取得** (= hardcode 禁止)
4. expected L body addr = `pmddotnet_song + 1 + 56` を計算
5. MAME headless + trace で実行
6. 6 段階 gate を逐次確認
7. exit code を返す

### robust 化

- L body addr 期待値は **build 毎に linker が assign する pmddotnet_song addr** に依存 → listing から動的取得
- ROM layout 変動でも script は追従

## 6 段階 trace gate 詳細

### gate 1: `.MN` header parse 到達

- **source**: `standalone_test.lst` の symbol 存在確認
- **判定**: `pmdneo_mn_direct_load_l_part_addr::` symbol が ROM に配置されているか
- **PC**: 動的 (= 例 `0x0010B3`、 build 毎に変動)
- **直接 PC trace の限界**: `z80-mem-trace` は **write のみ** 記録、 PC trace は別経路。 parser 内では memory write が起きないため、 直接到達確認は不可。 gate 4 (= workarea write 経由) で間接確認

### gate 2: `extended_data_adr` read

- **source**: mc compiler 出力固定値 (= α-1 hex dump で確認済)
- **判定**: `m_buf[26..27] LE = 39` (= `.MN` layout ground truth)
- **static**: driver は読むだけ、 mc compiler が固定で出力。 fixture 不変なら値も不変

### gate 3: L offset read

- **source**: mc compiler 出力固定値 (= α-1 hex dump で確認済)
- **判定**: `offset_table[0] LE = 56` (= L body の m_buf-relative offset)
- **static**: fixture 不変なら値も不変

### gate 4: L body addr setup

- **source**: `/tmp/pmdneo-trace/z80-mem-trace.tsv`
- **判定**: `0xFAE0` (= part_workarea[PART_ADPCMA1].PART_OFF_ADDR LSB) + `0xFAE1` (= MSB) に expected L body addr (= `pmddotnet_song + 1 + 56`) が連続書込
- **expected**: 動的計算 (= `pmddotnet_song` 値 + 57)
- **awk filter**: FAE0 に expected_LSB → 直後 FAE1 に expected_MSB なら MATCH
- **意義**: `.MN` parser → `pmdneo5_init_part` 経路成立の **唯一の直接証拠**

### gate 5: L part hook 到達

- **source**: gate 4 + gate 6 の論理積 (= 間接確認)
- **判定**:
  - gate 4 PASS = `part_workarea` 設定済 → `song_main_loop` が L part を iterate
  - gate 6 PASS = ADPCM-A reg write 発生 → `adpcma_keyon_hook` → `adpcma_keyon_simple` 経由
  - 両者が成立すれば hook 経路は確実に通っている
- **直接確認の限界**: z80-mem-trace に hook 内 memory access は出ない (= I/O port write のみ、 stack push/pop は `0xFFFE-0xFFFF` 周辺で識別困難)。 logical AND で代替

### gate 6: ADPCM-A register write

- **source**: `/tmp/pmdneo-trace/ymfm-trace.tsv`
- **port 区別**: ymfm-trace で port B reg は `100 + 内部 reg` 表記 (= port A は `00-FF`、 port B は `100-1FF`)
- **必須 reg** (= 全 PASS 条件):

| reg | ymfm 表記 | 意味 |
|---|---|---|
| 0x00 | `100` | keyon bit (= 0x01 で ch 0 keyon **必須**) |
| 0x08 | `108` | volume/pan (= ch 0) |
| 0x10 | `110` | start LSB (= ch 0) |
| 0x18 | `118` | start MSB (= ch 0) |
| 0x20 | `120` | stop LSB (= ch 0) |
| 0x28 | `128` | stop MSB (= ch 0) |

- **判定**: 各 reg で port B write が 1 件以上。 reg 0x00 のみ value 0x01 (= ch 0 keyon) を追加確認
- **意義**: chip register level での L body 反映確認、 上流 hook 経路の最終的副作用

## verify script 実行結果 (= 2026-05-12 自動 PASS 確認)

```
=== build (= PMDDOTNET_MML=l-part-minimum.mml, MODE=B, USE_PMDDOTNET=1) ===
  pmddotnet_song addr = 0x001286 (= listing 動的取得)
  expected L body addr = 0x12BF (= +1 +56)

=== gate 1: .MN header parse 到達 ===
  parser symbol (= pmdneo_mn_direct_load_l_part_addr) PC = 0x0010B3
  ✅ parser symbol 存在確認

=== gate 4: L body addr setup ===
  expected: 0xFAE0=0xBF, 0xFAE1=0x12 (= 0x12BF LE)
  ✅ z80-mem-trace で match 確認

=== gate 6: ADPCM-A register write ===
  ✅ reg 0x10 (= start LSB): port B write 1 件
  ✅ reg 0x18 (= start MSB): port B write 1 件
  ✅ reg 0x20 (= stop LSB): port B write 1 件
  ✅ reg 0x28 (= stop MSB): port B write 1 件
  ✅ reg 0x08 (= volume/pan): port B write 1 件
  ✅ reg 0x00 (= keyon): port B write 3 件, ch 0 keyon (= 0x01) 1 件

🎉 ADR-0016 step 5 α-2 trace gate verify PASS
```

exit code 0。

## β への引継ぎ事項

### β = sample table lookup (= 議題 5 確定)

α-3 は α-2 挙動を**固定**したので、 β で次の改修を行う際に regression を検出できる:

- `adpcma_ch_sample_ptr_table` の拡張 (= 1 sample fixed → sample A/B 切替)
- `samples.inc` に L 用 sample A + B を build 時 embed
- L ch only で sample A / sample B 2 fixture 作成
- reg 0x10/0x18/0x20/0x28 (= start/stop LSB/MSB) の **差分検証**
- key bit (= reg 0x00) / volume (= reg 0x08+ch) / pan は **同一性検証**

### β verify script 拡張

α-3 の verify script (= `verify-l-part-alpha-trace-gate.sh`) を β で派生:

- `verify-l-part-sample-fixture-driven.sh` (= 仮称、 step 4-3-δ 直系)
- L sample A fixture + L sample B fixture を**並列 build + trace**
- ROM_A / ROM_B の 2 trace を比較
- reg 0x10/0x18/0x20/0x28 の **差分検出** が PASS 条件
- key/vol/pan 同一性検証

β 完了判定 = sample 切替差分が trace で検出 + 自動 verify script PASS。

### α-3 が β に提供する infrastructure

| 提供物 | β での再利用 |
|---|---|
| `pmddotnet_song` addr 動的取得 logic | β でも build 毎の addr 変動に対応可 |
| L body addr expected 計算式 | β でも `pmddotnet_song + 1 + L_offset` で再利用 |
| z80-mem-trace + ymfm-trace 分離判定 | β でも parser / chip level 分離 |
| ADPCM-A reg full set 判定 | β で reg 0x10/0x18/0x20/0x28 を差分軸、 0x00/0x08 を同一性軸に再構成 |
| 6 段階 trace gate 構造 | β の 2 fixture 並列にも展開可 |

## 関連

- **commit**: ae6b419 (= α-2)、 3e01f48 (= α-1)、 [本 commit] (= α-3)
- **ADR**: ADR-0019 §決定 6 sub-sprint α、 ADR-0019 §決定 4 補正注記
- **handoff**: `docs/design/handoff/adr-0016-step5-alpha-1-mn-layout.md` (= α-1 ground truth)
- **memory**: 
  - `project_adr_0016_step5_design_decision_5_verify_sample_first.md` (= 議題 5、 β 設計)
  - `project_adr_0016_step5_alpha_prep_mn_direct_path.md` (= α 冒頭調査)
- **fixture**: `src/test-fixtures/step5/l-part-minimum.mml`

## α-3 完了判定

- ✅ verify script 作成 + 自動 PASS (exit 0)
- ✅ handoff doc 作成 (= 本 doc)
- ✅ driver 実装変更なし (= regression test 化のみ)
- ✅ β への引継ぎ事項明記

α 全体 (α-1 / α-2 / α-3) 完了 → ADR-0019 §決定 6 sub-sprint α 完了 → 次は β。
