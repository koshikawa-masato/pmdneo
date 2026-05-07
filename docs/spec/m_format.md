# PMD `.m` バイナリフォーマット仕様

	解析対象: PMD V4.8s mc compiler 出力(`vendor/pmd48s/SAMPLE.M` 等)
	解析根拠: `vendor/pmd48s/source/pmd48s/PMD.ASM`(x86 アセンブリ、 10864行)
	目的: PMDNEO Phase 2 driver 実装の仕様基盤
	状態: Phase 1 (δ) 解析中、 v1 draft

	参考: `docs/manual/PMDMML_MAN_V48s_utf8.txt`(PMD V4.8s MML マニュアル)

---

## 1. 全体構造

`.m` ファイルは PMD driver(Z80 / x86)が `mmlbuf` というメモリ位置にロード
して解釈する音楽データ。 全体構造:

```
+------+----------------------------------------------------------+
| 位置 | 内容                                                     |
+------+----------------------------------------------------------+
|  -1  | X68000 mode flag (byte)                                  |
|      | (※ mmlbuf-1 の byte、 .m ファイル先頭の 1 byte 前が     |
|      |  ロードされる位置として扱われる)                         |
+------+----------------------------------------------------------+
|   0  | part offset table 開始(11 part × 2 byte LE = 22 byte)  |
|      | 各 part の MML body 開始位置(mmlbuf からの相対 offset)  |
+------+----------------------------------------------------------+
|  22  | rhythm address table offset (2 byte LE)                  |
|      | R part の演奏パターンテーブルへの相対 offset             |
+------+----------------------------------------------------------+
|  24  | (上記 24 byte が固定 header)                             |
+------+----------------------------------------------------------+
|  ?   | 各 part の MML body(offset table が指す位置から開始)    |
+------+----------------------------------------------------------+
|  ?   | rhythm address table(rhythm offset が指す位置)          |
+------+----------------------------------------------------------+
|  ?   | rhythm パターン本体                                      |
+------+----------------------------------------------------------+
```

[補足] `.m` ファイル自体の物理的な byte 0 が PMD driver にロードされる
位置は mmlbuf。 PMD.ASM の `play_init`(L506-)で `mov si, [mmlbuf]` した
後、 `-1[si]` を `x68_flg` に読み込んでいるが、 これは PMDNEO 時には
無視できる(PC-98 / X68000 区別不要)。

## 2. パート構成と offset table

`max_part2 = 11`(PMD.ASM L8266)。 Part offset table は以下 11 part 分:

| Part 番号 | パート記号 | 音源 |
|---|---|---|
| 0 | A | FM 1 |
| 1 | B | FM 2 |
| 2 | C | FM 3 |
| 3 | D | FM 4 |
| 4 | E | FM 5 |
| 5 | F | FM 6 |
| 6 | G | SSG 1(PSG 1) |
| 7 | H | SSG 2(PSG 2) |
| 8 | I | SSG 3(PSG 3) |
| 9 | J | PCM(ADPCM-B、 OPNA/OPNB) |
| 10 | (R) | Rhythm body(K/R で参照) |

各 part offset は 2 byte LE で、 mmlbuf からの相対 offset。 driver は
`address[di] = mmlbuf + offset` として絶対アドレスを計算する(PMD.ASM
L536)。

### 2-1. empty part の表現

各 part body の先頭 byte が `0x80` なら「演奏しない」 マーカー
(PMD.ASM L538-540 `cmp byte ptr [bx], 80h ; 先頭が80hなら演奏しない`)。

[補足] empty part の offset table 値は実際の MML body を指さず、 共通の
`0x80` byte 列をまとめて指すことが多い。 例えば SAMPLE.M では A-F が
全て使われていないため、 22 byte header の直後に `0x80` を 6 個並べた
領域(byte 25-30)を A-F の各 offset が指している。

## 3. SAMPLE.M による検証

`vendor/pmd48s/SAMPLE.M`(1142 byte)の先頭 binary:

```
00000000: 001a 001b 001c 001d 001e 001f 0020 00f6
00000010: 011e 0251 0452 0453 045f 0480 8080 8080
00000020: 80f0 01fe 1800 fd0f fe00 f9c1 00f9 3900
```

解析:

```
byte 0       : 0x00          = X68000 mode flag = 0 (PC-98 mode)
byte 1-2     : 0x1a 0x00     = part 0 (A=FM1) offset = 0x001a = 26
byte 3-4     : 0x1b 0x00     = part 1 (B=FM2) offset = 0x001b = 27
byte 5-6     : 0x1c 0x00     = part 2 (C=FM3) offset = 0x001c = 28
byte 7-8     : 0x1d 0x00     = part 3 (D=FM4) offset = 0x001d = 29
byte 9-10    : 0x1e 0x00     = part 4 (E=FM5) offset = 0x001e = 30
byte 11-12   : 0x1f 0x00     = part 5 (F=FM6) offset = 0x001f = 31
byte 13-14   : 0x20 0x00     = part 6 (G=SSG1) offset = 0x0020 = 32
byte 15-16   : 0xf6 0x00     = part 7 (H=SSG2) offset = 0x00f6 = 246
byte 17-18   : 0x1e 0x01     = part 8 (I=SSG3) offset = 0x011e = 286
byte 19-20   : 0x51 0x02     = part 9 (J=PCM) offset = 0x0251 = 593
byte 21-22   : 0x52 0x04     = part 10 (R) offset = 0x0452 = 1106
byte 23-24   : 0x53 0x04     = rhythm address table offset = 0x0453 = 1107
byte 25      : 0x5f          = (empty marker 領域開始?)
byte 26-31   : 0x04 0x80 0x80 0x80 0x80 0x80 = empty part マーカー群
byte 32      : 0xf0          = G part(SSG1)の MML body 開始(opcode 0xf0)
```

[補足] byte 25-31 の `5f 04 80 80 80 80 80 80` は、 part offset 解析と
ずれている。 byte 23-24 の rhythm address table offset = 0x0453(= 1107)
が file size 1142 を超えていない値なので、 1107 番地に rhythm address
table が存在。 byte 25 以降の解釈はさらなる解析が必要(下記 §6 で深掘り
予定)。

## 4. MML opcode 列(part body)

各 part body は opcode 列で、 PMD.ASM の dispatch table が opcode →
handler を解釈する。

詳細 opcode 一覧は別 doc(`docs/spec/m_opcodes.md`、 Phase 1 (δ) 後段で
作成予定)で扱うが、 おおまかな分類:

| 範囲 | 用途 |
|---|---|
| `0x00 - 0x7F` | 音程 + 音長(ノート on)。 12半音 × オクターブの組合せ |
| `0x80` | empty part マーカー / 終端マーカー |
| `0x81 - 0xDF` | レスト + 音長 / 各種拡張ノート |
| `0xE0 - 0xFF` | 制御コマンド(LFO、 音色、 ADPCM、 ループ 等) |

具体的な opcode 表は PMD.ASM の dispatch table area(label 不明、 grep 必要)
と `vendor/pmd48s/PMDMML.MAN`(MML マニュアル)を交互参照して文書化する。

## 5. Rhythm address table

`.m` byte 23-24 が指す offset 位置に rhythm address table がある。 K
part(rhythm pattern selector)が「R0」「R1」 ... と参照するパターンの
それぞれの開始 offset を持つテーブル(PMD.ASM L8043 `radtbl dw ?`)。

詳細構造は SAMPLE.M / SAMPLE2.M で複数 R パターンを含むデータの解析を
通じて確定させる(Phase 1 (δ) 後段)。

## 6. 残課題(Phase 1 (δ) 後段)

1. **dispatch table area の opcode → handler 完全マップ作成**
   - PMD.ASM 内の dispatch table label を特定
   - 各 opcode の引数 byte 数 / 解釈ルール / 引数範囲を一覧化
   - 出力: `docs/spec/m_opcodes.md`(別 doc)

2. **rhythm address table 構造詳細**
   - SAMPLE.M / SAMPLE2.M で複数 R パターンを持つ例を解析
   - K part による参照仕組み(R0, R1 等)の文書化

3. **音色データ領域の有無**
   - PMD.ASM L514 `mov bx, [si+(2*(max_part2+1))]` で参照される領域
   - "2.6 追加分" コメントから、 後発拡張のプログラムデータ領域?
   - 仕様確定が必要

4. **SAMPLE.M byte 25-31 の解釈**
   - 上記 §3 の通り、 部分的に offset 解析と合わない箇所あり
   - 再解析

5. **PMDDotNET 出力との整合性確認**
   - PMD V4.8s 公式 mc compiler 出力 と PMDDotNET 出力で `.m` バイナリ
     が完全一致するか検証

## 7. PMDNEO 設計への含意

Phase 2 で driver(Z80 フルスクラッチ)を実装する際の前提:

- `.m` の前 24 byte(part offset + rhythm offset)が固定 header
- 11 part の MML body が dispatch ループで解釈される
- `0x80` は empty part マーカー(driver は該当 part を keyon せず idle)
- opcode 列の解釈は dispatch table 駆動(関数 pointer 配列で switch)

PMDNEO 専用拡張(`.mn`)では、 上記 V4.8s 互換構造を維持しつつ、 OPNB 専用
opcode を `0xE0-0xFF` 範囲の未使用 entry に追加する方針(設計書 §1-8-2 参照)。

---

[Phase 1 (δ) 仕様書 v1 draft、 後段で §4 opcode 詳細・§5 rhythm 詳細・§6
残課題の解明を進めて完成させる]
