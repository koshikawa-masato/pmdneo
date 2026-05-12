# ADR-0016 step 5 β-1 finding handoff: sample A/B fixture + `.MN` diff 確定

- 起票日: 2026-05-12 (= 6th session β-1)
- 起票者: Claude Code
- 関連: α-1/2/3 commit (= 3e01f48 / ae6b419 / e97210c / 335dec1)、 ADR-0019 §決定 6 sub-sprint β、 議題 5

## 概要

**β-1 は build infra commit** (= driver 実装変更なし)。 sample 切替の MML 表現 `@<n>` を 2 fixture (= sample A / sample B) で確定、 mc compiler 出力 `.MN` の差分 + ROM embed byte-identical を verify。 β-2 (= driver `0xFF` cmd dispatch + sample table lookup) の ground truth を残す。

## β-0 調査結果 (= β-1 前提)

L-Q part 内 `@<n>` の動作を mc.cs 読解 + 実験で確定:

| 項目 | 結果 |
|---|---|
| L-Q part 内 `@<n>` 受理 | ✅ 受理される (= EXIT 0、 Compile Completed) |
| mc compiler の `@<n>` 経路 | `neirochg()` (= mc.cs L7920-7968) |
| L-Q ongen | `mml_seg.pcm` (= ADPCM-B と同じ ongen 扱い) |
| emit byte sequence | **`0xFF nn`** (= 2 byte、 PMD V4.8s 規約) |
| `0xFF` の意味 | instrument cmd byte (= L7942 `work.dx = 0xff00 + voice_idx`) |
| `nn` の意味 | voice index (= 0-255) |
| 既存 PMD / ADPCM-B / PPZ 整合 | ✅ 同じ `neirochg()` 経路、 同じ `0xFF nn` emit format |

driver 側で `0xFF` cmd dispatch を追加すれば sample table lookup 可能。

## β-1 fixture

### 新規 fixture

| file | 内容 | size |
|---|---|---|
| `src/test-fixtures/step5/l-part-sample-a.mml` | `L @0 o4 l1 c` | (UTF-8+CRLF) |
| `src/test-fixtures/step5/l-part-sample-b.mml` | `L @1 o4 l1 c` | (UTF-8+CRLF) |

両者は `@<n>` の n だけが異なる (= 0 vs 1)。 Title / Memo は識別用に `A` / `B` 表記、 残りは baseline `l-part-minimum.mml` と同形。

### fixture 規律 (= α-1 規律踏襲)

- `#PNEFile "step5.PNE"` 必須 (= mc compiler strict 要求対応、 driver は filename 使わず)
- UTF-8 + CRLF
- step 4 fixture cp pattern で encoding 維持
- ASCII 範囲外文字 (= ギリシャ文字 α/β 等) は MML 内に書かない、 file 名は `alpha` / `beta` で代替

## `.MN` 出力差分

### sample A (= @0)

- **sha256**: `aefaca47ede35a652aadc7d9d547d49855993cefb70a94b7e607688ec0b48d3f`
- **size**: 278 byte
- **L body**: `FF 00 30 60 80` (= 5 byte)
  - byte 0: `0xFF` (= instrument cmd)
  - byte 1: `0x00` (= voice index 0)
  - byte 2: `0x30` (= note byte = o4 c)
  - byte 3: `0x60` (= length 0x60 = 96 tick = l1)
  - byte 4: `0x80` (= terminator)

### sample B (= @1)

- **sha256**: `bf70489eb4c75b64575ba2620b963b5f5a9ec6548477c643ccaede11d3cc2d33`
- **size**: 278 byte
- **L body**: `FF 01 30 60 80` (= 5 byte)
  - byte 1 のみ sample A から差異 (= `0x00` → `0x01`)

### cmp -l 差分 (= 機能的差分検出)

```
   59   0   1     ← L body byte 1 (= voice index)、 ★ 機能的差分
  127 101 102    ← Title/Memo 文字列 (`A` vs `B`)
  133  60  61    ← (= 同上)
  ...
```

**機能的差分 = file offset 59 (= L body 内 voice index 1 byte) のみ**。 残りは Title/Memo string の `A`/`B` 差。

### layout shift (= α-1 layout からの拡張)

| 項目 | baseline (= l-part-minimum) | sample A/B | 差 |
|---|---|---|---|
| L body | 3 byte (= `30 60 80`) | 5 byte (= `FF nn 30 60 80`) | +2 |
| extended_data_adr (= m_buf[26..27]) | 39 (= 0x0027) | 39 (= 同) | 同 |
| Rhythm addr (= m_buf[22..23]) | 71 (= 0x0047) | 73 (= 0x0049) | +2 |
| pne_filename_adr (= m_buf[51..52]) | 59 (= 0x003B) | 61 (= 0x003D) | +2 |
| file size | 283 byte | 278 byte | -5 (= Title/Memo 短縮分) |

L body +2 byte により後段の Rhythm / filename string も後ろに +2 shift。 これは **正常な mc compiler 動作** (= L body 拡大時の自動 shift)。

extended_data_adr (= m_buf[26..27]) は不変。 これは「後方拡張領域開始位置」 = 「Part A-K body 領域末尾」 で、 私の MML では K 部まで empty (= 11 byte terminator 0x80) なので不変。

### pointer 解決規則 (= α-1 ground truth、 β-1 でも整合)

```
file_address = pmddotnet_song + 1 + pointer_value
```

α-1 で確定した規則が β-1 でも完全に整合。 driver parser は次のステップで sample addr を解決可:

1. extended_data_adr = 39 を m_buf[26..27] から読む
2. offset_table_base = pmddotnet_song + 1 + 39 = file[40]
3. L entry (= offset_table_base + 0) = LE_word → L_offset
4. L_body_addr = pmddotnet_song + 1 + L_offset = file 内 L body 先頭
5. **L body byte 0 で `0xFF` 検出 → byte 1 を voice index として読む** (= β-2 で実装)
6. voice index → sample table lookup (= driver 側 sample addr table を引く)

## ROM embed byte-identical 確認

build-poc.sh で順次 build、 `vendor/ngdevkit-examples/00-template/pmddotnet_song.m` (= ROM 内 .MN コピー) の sha256 を直接生成 .MN と比較。

| build | pmddotnet_song.m sha256 | 直接生成 .MN sha256 | 一致 |
|---|---|---|---|
| sample A | `aefaca47ede35a652aadc7d9d547d49855993cefb70a94b7e607688ec0b48d3f` | (同) | ✅ |
| sample B | `bf70489eb4c75b64575ba2620b963b5f5a9ec6548477c643ccaede11d3cc2d33` | (同) | ✅ |

両者で ROM embed が byte-identical (= mc compiler 出力 = ROM payload で完全一致)。

## β-2 への引継ぎ事項

### driver 改修範囲 (= β-2 で実装)

1. **`0xFF` cmd dispatch 追加**:
   - 既存 `pmdneo_part_main_parse` (= L1756) に `0xFF` 分岐
   - L body parse 中に `0xFF` byte を見たら次 1 byte (= voice index) を読む
   - voice index を workarea field (= `PART_OFF_INSTRUMENT` 仮称) に保存
2. **`PART_OFF_INSTRUMENT` field 追加**:
   - workarea L-Q part の field offset 定義
   - 既存 `PART_OFF_VOLUME` / `PART_OFF_ADDR` 等と並列
3. **adpcma_ch_sample_ptr_table 構造拡張**:
   - 現状: ch index で fixed sample (= ch 0=bd, ch 1=sd, ...)
   - β 後: voice index で sample addr 引き (= `@0`=sample 0, `@1`=sample 1, ...)
   - 議題 1 「sample ptr table は拡張可能な構造へ整理」 具現化
4. **samples.inc 拡張** (= 必要に応じて):
   - 既存 6 sample (= bd/sd/hh/tom/rim/top) を voice index 0-5 として再解釈
   - もしくは voice 用 sample を新規追加
5. **adpcma_keyon_simple 改修**:
   - 現状: ch index から sample addr 引く
   - β 後: `PART_OFF_INSTRUMENT(ix)` から voice index 取得 → sample table lookup

### β-2 trace gate (= 拡張)

α-3 6 段階 trace gate に **gate 4.5** を追加:
- gate 4.5: voice index dispatch (= `PART_OFF_INSTRUMENT(ix)` 書込 + sample addr lookup)

### β-3 verify script (= 拡張)

α-3 verify-l-part-alpha-trace-gate.sh を派生:
- sample A / sample B 並列 build
- ROM_A / ROM_B trace を **2 並列実行**
- reg 0x10/0x18/0x20/0x28 **差分検出** = β PASS 条件
- key bit (= reg 0x00) / volume (= reg 0x08) / pan は **同一性検証**

### voice index → sample mapping (= β-2 で固定)

β-2 着手直前に user と確定:
- 例: `@0` = bd、 `@1` = sd、 `@2` = hh、 ...
- 既存 `adpcma_ch_sample_ptr_table` を流用 or 新規 voice 用 table

## β-1 完了判定

- ✅ 2 fixture 作成 (= UTF-8+CRLF、 step 4 fixture cp pattern)
- ✅ mc compiler /B EXIT 0、 .MN 生成
- ✅ L body 差分確認 (= `FF 00 30 60 80` / `FF 01 30 60 80`)
- ✅ cmp 機能的差分 = file offset 59 のみ (= voice index)
- ✅ ROM embed byte-identical (= sample A/B 各々 sha256 一致)
- ✅ pointer 解決規則 (= α-1 ground truth) と整合
- ✅ driver 実装変更なし (= α-2 状態維持)

## 関連

- **commit**: 3e01f48 (= α-1)、 ae6b419 (= α-2)、 e97210c (= α-3)、 335dec1 (= α-3 audio finding)、 [本 commit] (= β-1)
- **ADR**: ADR-0019 §決定 6 sub-sprint β、 議題 5
- **handoff**: 
  - `docs/design/handoff/adr-0016-step5-alpha-1-mn-layout.md` (= α-1 ground truth)
  - `docs/design/handoff/adr-0016-step5-alpha-2-trace-gate-findings.md` (= α-3 trace gate + audio finding)
- **fixture**:
  - `src/test-fixtures/step5/l-part-minimum.mml` (= baseline、 α 用)
  - `src/test-fixtures/step5/l-part-sample-a.mml` (= β 用、 @0)
  - `src/test-fixtures/step5/l-part-sample-b.mml` (= β 用、 @1)
- **memory**: 
  - `project_adr_0016_step5_design_decision_5_verify_sample_first.md` (= 議題 5)
  - `feedback_audio_gate_solo_isolation.md` (= α-3 経験、 β audio gate 規律)

α-1 / α-2 / α-3 (= ADR-0019 §決定 6 sub-sprint α) 完了後の β-1 build infra commit。 次は β-2 (= driver `0xFF` cmd dispatch + voice index → sample table lookup) 着手前 user 擦り合わせ。
