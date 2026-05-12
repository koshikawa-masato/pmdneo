# ADR-0016 step 5 α-1 finding handoff: `.MN` byte layout 確定

- 起票日: 2026-05-12 (= 6th session α-1)
- 起票者: Claude Code + Codex (= zero-trust dual verify)
- 関連: ADR-0019 §決定 4 補正注記 (= .MN direct load path 前提)、 ADR-0016 §step 5

## 目的

step 5 α-1 (= build infra) で mc compiler `/B` 出力 `.MN` の **実 byte layout** を確定し、 α-2 (= driver `.MN` direct parser 新規追加) の ground truth を残す。

α-1 の作業中に発見した「4 byte 謎」 が **hex dump 読み違い** であった経緯も記録し、 後 sub-step で同じ誤読を防ぐ。

## α-1 作業 + 観測 sum-up

### fixture

| file | 内容 | 用途 |
|---|---|---|
| `src/test-fixtures/step5/l-part-minimum.mml` | `#PNEFile "step5.PNE"` + FM voice `@001 000 005` + `L o4 l1 c` | α-1 本番 fixture |
| `/tmp/pmdneo-step5-alpha1/l-part-minimum-v2.mml` (= 永続化せず) | v1 から `@` 音色定義削除 | prg_flg 仮説検証用 |

fixture 規律:
- UTF-8 + CRLF (= step 4 j-part-minimum.mml と同じ encoding)
- ASCII 範囲名前 (= ギリシャ文字 α 等は MML body に入れない、 file 名は `alpha-1` で代替)
- `#PNEFile` 宣言が必須 (= ADPCM-A 使用時 mc compiler が Error 6 で停止)

### mc compiler `/B` 実行

```bash
dotnet vendor/PMDDotNET/PMDDotNETConsole/bin/Release/net6.0/PMDDotNETConsole.dll /C /B <fixture>.mml
```

- EXIT 0 / Compile Completed
- 出力: `l-part-minimum.MN` (= 283 byte)
- sha256: `9c676c2e0d8f33d93fd677c7dc43ae45aed57cca4061d9407fccb64b74381169`
- v1 と v2 が **byte-identical** (= `@` 音色定義は L part が `@<n>` 呼出しない場合 mc compiler 出力に影響しない)

### dotnet build 状態

- `dotnet build -c Release` は「up-to-date」 で skip (= 0.59 秒)
- dll mtime = 14:10:42、 mc.cs mtime = 14:09:26、 commit `0b12f0a` timestamp = 14:14:30
- 順序: mc.cs edit → dll build (= 1m16s 後) → git commit (= 4m48s 後)
- **dll は最新 mc.cs (= step 1 commit 4e 内容) で build 済**

## 確定 `.MN` layout

### byte 単位 layout (= 283 byte file)

| file offset | m_buf offset | size | 内容 | 実例値 |
|---|---|---|---|---|
| 0 | — | 1 | m_start | 0x04 (= bit 2=1、 PMDNEO `.MN` mode) |
| 1-22 | 0-21 | 22 | Part A-K 開始 addr (= 11 entry × 2 byte LE) | A=28, B=29, ..., K=38 |
| 23-24 | 22-23 | 2 | Rhythm 開始 addr (= LE) | 71 |
| 25-26 | 24-25 | 2 | prgdat_adr (= LE、 PMDNEO mode で常に確保) | 0 |
| 27-28 | 26-27 | 2 | **extended_data_adr** (= LE、 ADPCM-A 拡張領域開始) | **39** |
| 29-39 | 28-38 | 11 | Part A-K body (= 各 1 byte 0x80 terminator) | 0x80 × 11 |
| 40-51 | 39-50 | 12 | **ADPCM-A 6 part offset table** (= 6 entry × 2 byte LE) | L=56, M-Q=55 |
| 52-53 | 51-52 | 2 | pne_filename_adr (= LE、 PNE filename string 開始 addr) | 59 |
| 54-55 | 53-54 | 2 | 予約 (= 将来拡張用) | 0 |
| 56 | 55 | 1 | 共有 empty marker (= 0x80、 empty L-Q entry が指す位置) | 0x80 |
| 57-59 | 56-58 | 3 | **L body** (= note + length + terminator) | `30 60 80` |
| 60-71 | 59-70 | 12 | pne_filename string (= 引用符込み + NUL) | `"step5.PNE"\0` |
| 72-282 | 71-281 | 211 | Rhythm body + Title + Composer + Memo + 他 | (Title `ADR-0016 step 5 alpha-1 L part...`) |

### pointer 解決規則 (★ Codex verify 確定)

**全 pointer 値は m_buf 座標**。 driver parser で file 内 addr を求めるには:

```
file_addr = file_base + 1 + pointer_value
```

例:
- extended_data_adr = 39 → file 内 offset table 開始 = `file_base + 1 + 39 = file[40]`
- L entry 値 = 56 → file 内 L body 開始 = `file_base + 1 + 56 = file[57]`
- M-Q entry 値 = 55 → file 内 empty marker = `file_base + 1 + 55 = file[56]`
- pne_filename_adr = 59 → file 内 filename string 開始 = `file_base + 1 + 59 = file[60]`

### `+1` の由来 (= m_start 1 byte 挿入)

mc.cs L263-267:

```csharp
//.Mファイルデータの整形(m_bufが出力データの実態になるよう、m_startをはじめに追加する)
dst.Add(new MmlDatum(m_seg.m_start));
for (int i = 0; i < m_seg.m_buf.Count; i++) dst.Add(m_seg.m_buf.Get(i));
for (int i = 0; i < dst.Count; i++) m_seg.m_buf.Set(i, dst[i]);
```

mc compiler は出力前に m_buf 先頭に m_start (= 1 byte) を挿入。 結果として **file[N] = m_buf[N-1]**、 m_buf 内 pointer 値 N は file offset N+1。

## /B vs /N differential dump (= 参考)

| 項目 | /N (.M) | /B (.MN) | 差 |
|---|---|---|---|
| file size | 247 byte | 283 byte | +36 byte |
| m_start | 0x00 | 0x04 | bit 2 set |
| header | 24 byte | 28 byte | +4 (prgdat_adr + extended_data_adr) |
| Part A addr | 24 | 28 | +4 |
| Rhythm addr | 35 | 71 | +36 |
| ADPCM-A 拡張領域 | なし | 33 byte (= file[40..72]) | +33 |
| pne_filename string | なし | `"step5.PNE"\0` | +12 |

`/N` mode では `#PNEFile` は無視 (= Warning 表示)、 ADPCM-A 関連領域は出力されない。

## 「4 byte 謎」 経緯 (= 重要 trivial verify 教訓)

α-1 作業中、 私は dump で「file[29..43] が 15 byte の 0x80 連続 (= 期待 11 byte + 余分 4 byte)」 と読んでいた。 これに基づき:

1. prg_flg 仮説 → v1/v2 byte-identical で却下
2. AutoExtendList Set 副作用仮説 → mc.cs/AutoExtendList.cs 確認で却下
3. mc.cs `cmloop` 4 byte 余分書込仮説 → mc.cs walk-through で見つけられず
4. **Codex 第二意見** で「**hex dump 読み違い**」 と判明

### 真因

xxd 出力 1 行 = 16 byte = **8 ペア**。 私は以下の行を:

```
00000020: 8080 8080 8080 8080 8080 3800 3700 3700 3700  ........8.7.7.7.
```

「`8080 × 5 ペア (= 10 byte) + 3800 + 3700 × 3 ペア = 18 byte」 と数えていた (= 行が 16 byte 制約を超える誤読)。

正しくは:
- pair 0-3: `8080 8080 8080 8080` = 8 byte (= file[32..39] の Part D-K body)
- pair 4: `8080` ← 待って、 これは `3800` が 4 ペア目?

実際の正解 (= ASCII 表示で確認):
```
ASCII: ........8.7.7.7.
       0 1 2 3 4 5 6 7 8 9 a b c d e f  (byte index)
       ^                 ^
       4 個の '.' (0x80)   '8' (0x38)
```

つまり行 0x20 byte 0-3 = `0x80` × 4、 byte 4 = `0x80` × 4 (合計 8 byte `0x80`)、 byte 8 = `0x38`、 byte 9 = `0x00`、 ...

待って、 ASCII 16 char で:
- byte 0..7 = `........` (= 8 個の 0x80)
- byte 8 = `8` (= 0x38)
- byte 9 = `.` (= 0x00)
- byte 10 = `7` (= 0x37)
- byte 11 = `.` (= 0x00)
- byte 12 = `7` (= 0x37)
- byte 13 = `.` (= 0x00)
- byte 14 = `7` (= 0x37)
- byte 15 = `.` (= 0x00)

つまり行 0x20 = `80 80 80 80 80 80 80 80 38 00 37 00 37 00 37 00`。 byte 0-7 が 0x80 (= file[32..39])、 byte 8 から ADPCM-A offset table (= file[40..47] = entry 0-3)。

### 教訓

- hex dump 読解では **ASCII 表示部** で byte index と値を確認 (= hex 部だけだと誤読 risk)
- xxd 行は厳密に 16 byte (= 8 ペア)
- 「謎の余分 N byte」 を発見したら **dump 読み違い** を最初に疑う
- Codex 第二意見 (= zero-trust verify) は **2 経路で同一結論** を確認する規律

## driver parser 設計指針 (= α-2 への引継ぎ)

α-2 で standalone_test.s に `.MN direct path` を新規追加する際の指針:

### parse 手順

1. ROM 内 `.MN` の先頭 addr (= `file_base`) を取得 (= `.incbin` label or 動的 load)
2. `m_start = mem[file_base + 0]` を読む
3. `m_start & 0x04 != 0` で PMDNEO `.MN` mode 判定
4. `extended_data_adr = LE_word(file_base + 1 + 26) = LE_word(file_base + 27)` を読む
5. `offset_table_base = file_base + 1 + extended_data_adr`
6. L entry: `L_offset = LE_word(offset_table_base + 0)` (= m_buf 座標)
7. L body 先頭: `L_body_addr = file_base + 1 + L_offset`
8. M-Q entry も同様に読む
9. empty marker offset (= L1521 で記録) は entry 値が指す共有 byte (= 0x80)

### Z80 実装注意

- Z80 LE 16-bit 読み: `ld c, (hl)` + `inc hl` + `ld b, (hl)` で BC に LE 値
- `file_base + 1 + pointer_value` は Z80 で `hl = file_base + 1; add hl, de (= pointer)` で計算
- pointer 値 が 0x8000 以上の場合は file 内 addr 計算で overflow 注意 (= 通常 mc compiler 出力 .MN は 16-bit 未満)

### α 完了判定 (= 補正後 ground truth)

ADR-0019 §決定 6 α 完了判定:
- trace で L part hook 到達 + ADPCM-A register write (= reg 0x10/0x18/0x20/0x28 + 0x00 key bit) を確認

α-2 で:
- driver `.MN direct parse` 経路を実装
- L body addr を `part_workarea + PART_ADPCMA1 × 64 + PART_OFF_ADDR` に設定
- driver_song_ready = 1 で song_main_loop が起動
- L part body の note byte (= 0x30 or 0x60、 PMD MML note format) を adpcma_keyon_hook へ流す

## 関連

- ADR-0019 §決定 4 補正注記 (= .MN direct load path 前提)
- ADR-0016 §step 5 / §step 3-5 補正注記 (= standalone_test.s 本線)
- memory `project_adr_0016_step5_alpha_prep_mn_direct_path.md` (= α 冒頭調査)
- Codex zero-trust verify session (= 4 byte 謎の解明)
