# `.m` データ構造徹底解析

	解析対象: `vendor/pmd48s/SAMPLE.M`(1142 byte、 PMD V4.8s mc 出力)
	一次資料: `PMDDotNET`(kuma4649氏作、 GPL-3.0、 https://github.com/kuma4649/PMDDotNET)
	補助資料: `vendor/pmd48s/source/pmd48s/PMD.ASM`(x86 アセンブリ、 10864 行)
	目的: PMDNEO Phase 2 driver(Z80 フルスクラッチ)の仕様基盤

	状態: v1 解析完了、 §5(part body opcode)以降は v2 で詰める

---

## 0. PMD ファミリ拡張子と format の関係

PMD ファミリの拡張子(`.m` / `.m2` / `.mz` / `.mn`)は **どの driver で再生
されるかを示す慣習**。 ファイル format 自体は全て同じ。

- `.m` = PMD.COM(OPN/OPNA、 ADPCM/PCM なし)で再生
- `.m2` = PMDB2.COM(OPNA + ADPCM RAM)/PMD86.COM(OPNA + PCM 別経路)で再生
- `.mz` = PMDPPZ.COM(+ PPZ8 拡張)で再生
- `.mn` = PMDNEO(YM2610/B、 ADPCM-A 6ch + ADPCM-B 1ch)で再生(本プロジェクト
  で新規定義)

検証根拠:

- PMDDotNET `mc.cs` L593: `mml_filename + ".M"` で出力、 拡張子分岐なし
- PMDDotNETConsole `Program.cs` L113: 出力先は常に `.M` 拡張子
- MC.ASM L350、 L8481(`m_filename db 128 dup(?)`): 同一 routine で出力、
  拡張子分岐なし

つまり mc compiler 一本で全形式の `.m`(系列)を生成し、 拡張子は MML source
ファイルの拡張子置換で決まる(慣習的 cross-checking)。

違うのは **driver 側の dispatch table 解釈ルール**(part J が ADPCM-B か /
PCM 別経路か / PPZ 経由か、 等)。 本ドキュメントの解析結果(§2 以降)は
全形式に共通する基本構造を扱う。

PMDNEO の `.mn` も同じ基本構造を採用し、 driver(YM2610/B 駆動 + ADPCM-A
拡張)が解釈する形(設計書 §1-8 参照)。

---

## 1. 解析方針

PMD.ASM(x86 アセンブリ)を読み解くより、 **PMDDotNET の C# source を一次資料**
とする。 PMDDotNET は kuma4649氏が PMD V4.8s を .NET 移植したもので、 mc
compiler / driver のロジックがそのまま C# で書かれており、 .m バイナリの
構造と解釈ロジックが C# レベルで把握できる。

主要参照ファイル:

- `PMDDotNETCompiler/m_seg.cs`(.m の buffer 構造)
- `PMDDotNETCompiler/mc.cs`(mc compiler 本体、 .m 出力ロジック)
- `PMDDotNETCompiler/mml_seg.cs`(MML パース、 max_part 等の定数)
- `PMDDotNETDriver/PMD.cs`(driver、 .m 解釈ロジック)

PMD.ASM は補助資料として、 PMDDotNET と矛盾がないか確認するのに使う。

---

## 2. `.m` ファイル全体構造

### 2-1. ファイル先頭 1 byte = m_start

PMDDotNET `mc.cs` L260-264:

```csharp
//.Mファイルデータの整形(m_bufが出力データの実態になるよう、m_startをはじめに追加する)
List<MmlDatum> dst = new List<MmlDatum>();
dst.Add(new MmlDatum(m_seg.m_start));
for (int i = 0; i < m_seg.m_buf.Count; i++) dst.Add(m_seg.m_buf.Get(i));
```

つまり `.m` ファイルは:

- **file byte 0** = `m_start`(1 byte)
- **file byte 1〜** = `m_buf` 配列(MML データ本体)

driver 側は `m_buf` を `mmlbuf` というメモリ位置にロードし、 m_start は
`mmlbuf - 1` 位置から読む(PMD.cs L481「`pw.md[r.si - 1].dat`」)。

### 2-2. m_start の中身

PMDDotNET `mc.cs` L816:

```csharp
m_seg.m_start = (byte)(mml_seg.opl_flg * 2 | mml_seg.x68_flg);
```

- bit 0(`x68_flg`): X68000 mode flag(0 = 通常、 1 = X68000 mode)
- bit 1(`opl_flg`): OPL/OPM mode flag(0 = OPNA系、 1 = OPL/OPM)
- → m_start の値範囲は 0〜3

PMDNEO では x68_flg / opl_flg ともに使わないため、 **常に 0 で出力する**
方針(Phase 3 で PMDDotNET 改良時に確定)。

### 2-3. m_buf 構造

PMDDotNET `mc.cs` L819:

```csharp
work.di = (mml_seg.max_part + 1) * 2;//KUMA: ? -> ver48sで理解w
```

`mml_seg.max_part = 11`(`mml_seg.cs` L190)。 `work.di = 24` から MML body
の書き込みが始まる、 つまり m_buf[0..23] が固定 header。

```
m_buf 内 offset    内容
-----------------  -------------------------------------------------------
m_buf[0..1]        part 0 (A=FM1) offset (LE 16-bit)
m_buf[2..3]        part 1 (B=FM2) offset
m_buf[4..5]        part 2 (C=FM3) offset
m_buf[6..7]        part 3 (D=FM4) offset
m_buf[8..9]        part 4 (E=FM5) offset
m_buf[10..11]      part 5 (F=FM6) offset
m_buf[12..13]      part 6 (G=SSG1) offset
m_buf[14..15]      part 7 (H=SSG2) offset
m_buf[16..17]      part 8 (I=SSG3) offset
m_buf[18..19]      part 9 (J=PCM/ADPCM-B) offset
m_buf[20..21]      part 10 (R body) offset
m_buf[22..23]      rhythm address table offset
m_buf[24..25]      (option) prgdat_adr (= 音色データ等の領域 offset)
m_buf[26..]        各 part の MML body / 各種データ
```

### 2-4. prgdat_adr の扱い(option)

PMDDotNET `PMD.cs` L484-491:

```csharp
//	;２．６追加分
pw.prg_flg = 0;
if (pw.md[r.si].dat != (pw.max_part2 + 1)*2)
{
    r.bx = Common.Common.GetLe16(pw.md, r.si + (2 * (pw.max_part2 + 1)));
    r.bx += r.si;
    pw.prgdat_adr = r.bx;
    pw.prg_flg = 1;
}
```

`(max_part2 + 1) * 2 = 24`。 driver は m_buf[0]bit(= part A offset の LO byte)
が 24 と等しいか比較する:

- **m_buf[0] == 24**: part A が m_buf[24] から始まる(prgdat なし、 not_prg path)
- **m_buf[0] != 24**: part A が m_buf[26] 以降から始まる(prgdat あり、 prg path)
  - m_buf[24..25] = prgdat_adr(LE 16-bit、 mmlbuf 相対 offset)
  - prgdat_adr は音色データ等の領域開始位置を示す

つまり mc compiler は楽曲が音色定義などの拡張データを持つ場合、
m_buf[24..25] に prgdat_adr 値を書き、 part offset を 26 以降にずらす。

---

## 3. SAMPLE.M(1142 byte)完全解析

### 3-1. file byte 0(m_start)

```
file byte 0 = 0x00
```

m_start = 0 → opl_flg = 0、 x68_flg = 0 → **OPNA 系 + 通常 PC-98 mode**。

### 3-2. m_buf header(file byte 1〜26、 m_buf[0..25])

hexdump:

```
00000000: 00 1a 00 1b 00 1c 00 1d  00 1e 00 1f 00 20 00 f6
00000010: 01 1e 02 51 04 52 04 53  04 5f 04 ...
```

| m_buf 位置 | file byte | 値(LE) | 意味 |
|---|---|---|---|
| m_buf[0..1] | 1, 2 | 0x001a = 26 | part A(FM1)offset |
| m_buf[2..3] | 3, 4 | 0x001b = 27 | part B(FM2)offset |
| m_buf[4..5] | 5, 6 | 0x001c = 28 | part C(FM3)offset |
| m_buf[6..7] | 7, 8 | 0x001d = 29 | part D(FM4)offset |
| m_buf[8..9] | 9, 10 | 0x001e = 30 | part E(FM5)offset |
| m_buf[10..11] | 11, 12 | 0x001f = 31 | part F(FM6)offset |
| m_buf[12..13] | 13, 14 | 0x0020 = 32 | part G(SSG1)offset |
| m_buf[14..15] | 15, 16 | 0x01f6 = 502 | part H(SSG2)offset |
| m_buf[16..17] | 17, 18 | 0x021e = 542 | part I(SSG3)offset |
| m_buf[18..19] | 19, 20 | 0x0451 = 1105 | part J(PCM)offset |
| m_buf[20..21] | 21, 22 | 0x0452 = 1106 | part 10(R body)offset |
| m_buf[22..23] | 23, 24 | 0x0453 = 1107 | rhythm address table offset |
| m_buf[24..25] | 25, 26 | 0x045f = 1119 | prgdat_adr(prg path) |

**判定**: m_buf[0] = 0x1a ≠ 0x18(24) → **prg path、 prgdat_adr = 1119**。

### 3-3. m_buf[26〜]: 各 part の MML body / empty marker

```
file byte 27 〜 32:  80 80 80 80 80 80   (m_buf[26..31])
file byte 33      :  f0                  (m_buf[32]、 part G 先頭)
```

| m_buf 位置 | file byte | 値 | 意味 |
|---|---|---|---|
| m_buf[26] | 27 | 0x80 | part A 先頭 = empty marker(SAMPLE.MML で A 不使用) |
| m_buf[27] | 28 | 0x80 | part B empty |
| m_buf[28] | 29 | 0x80 | part C empty |
| m_buf[29] | 30 | 0x80 | part D empty |
| m_buf[30] | 31 | 0x80 | part E empty |
| m_buf[31] | 32 | 0x80 | part F empty |
| m_buf[32] | 33 | 0xf0 | part G 先頭 opcode(= cmdtblp の 0xf0 = `psgenvset`) |

PMDDotNET `PMD.cs` L513-516:

```csharp
if (pw.md[r.ax].dat == 0x80)//;先頭が80hなら演奏しない
{
    r.ax = 0;
}
```

**part body 先頭 byte が 0x80 なら driver は演奏しない**(empty part マーカー)。

### 3-4. SAMPLE.MML との対応

SAMPLE.MML(原文):

```
G	E1,-2,24,0 v15 q0
G	o4l8[{{eg>c<}}2. {{eg>c<}},,,2 {{fa>c<}}%108
...
H	E2,-2,6,0 v14o2l8 [c>Q6cQ8<]56 <gggrrgr>c r1
!b	E1,-4,1,0v15q99,3P1o3c16q0
...
I	l16MP-128 [!b[!h]3!s[!h]3]15 ...
```

→ G/H/I の 3 パートのみ使用、 A〜F / J / R は empty。

file 内訳:

| 範囲 | サイズ | 内容 |
|---|---|---|
| file byte 0 | 1 | m_start = 0x00 |
| file byte 1〜26 | 26 | m_buf header(part offset table 22 + rhythm offset 2 + prgdat 2) |
| file byte 27〜32 | 6 | empty marker(A〜F の 0x80 × 6) |
| file byte 33〜502 | 470 | part G(SSG1) MML body |
| file byte 503〜542 | 40 | part H(SSG2) MML body |
| file byte 543〜1105 | 563 | part I(SSG3) MML body |
| file byte 1106 | 1 | part J(PCM)= 0x80 empty |
| file byte 1107 | 1 | part 10(R body)= 0x80 empty(R/K 不使用) |
| file byte 1108〜 | ? | rhythm address table |
| file byte 1119〜 | ? | prgdat 領域 |
| file byte 〜 1141 | 〜 | (file 末尾) |

[補足] R / J が 1 byte 0x80 で empty 表現される場合、 「R body 開始」 と
「rhythm address table 開始」 が 1 byte ずれていれば成立する。 SAMPLE.M
では R body offset = 1106、 rhythm addr table offset = 1107 でちょうど 1
byte 差。 部分的に整合(さらなる検証は §6 で行う)。

---

## 4. dispatch table 概要(part body 解釈)

PMD.ASM L1713-1716(commands routine):

```
commands:
    mov bx, offset cmdtbl
    jmp command00
```

L1724-1737(command00、 dispatch 共通):

```
command00:
    cmp al, com_end          ; com_end = 0xB1
    jc out_of_commands       ; al < 0xB1 なら part END
    not al                   ; al = 0xFF - al
    add al, al               ; *2(2 byte entry)
    xor ah, ah
    add bx, ax
    mov ax, cs:[bx]
    jmp ax
```

つまり:

- **opcode 0x00〜0xB0** → dispatch table 範囲外 → 別 logic(音程 + 音長 / part END)
- **opcode 0xB1〜0xFF** → cmdtbl[idx] を呼び出し(idx = 0xFF - opcode、 entry は 2 byte LE)

dispatch table は 3 種類:

- **cmdtbl** (FM/PCM 用、 PMD.ASM L1745-)
- **cmdtblp** (PSG 用、 PMD.ASM L1888-)
- **cmdtblr** (Rhythm 用、 別所)

### 4-1. cmdtbl(FM/PCM)主要 entry

PMD.ASM L1746-(opcode 0xFF から逆順):

| opcode | handler | 機能 |
|---|---|---|
| 0xFF | com@ | 音色番号指定 |
| 0xFE | comq | gate time |
| 0xFD | comv | volume |
| 0xFC | comt | tempo |
| 0xFB | comtie | tie / slur |
| 0xFA | comd | detune |
| 0xF9 | comstloop | ループ start |
| 0xF8 | comedloop | ループ end |
| 0xF7 | comexloop | ループ exit |
| 0xF6 | comlopset | loop set |
| 0xF5 | comshift | shift(オクターブ 等) |
| 0xF4 | comvolup | volume up |
| 0xF3 | comvoldown | volume down |
| 0xF2 | lfoset | LFO 設定 |
| 0xF1 | lfoswitch_f | LFO switch |
| 0xF0 | jump4 | (FM/PCM では未使用、 PSG では psgenvset) |
| 0xEF | comy | OPN(A) reg 直接書込み |
| 0xEC | panset | pan set |
| 0xEB | rhykey | rhythm keyon |
| 0xEA | rhyvs | rhythm volume set(per ch) |
| 0xE9 | rpnset | rhythm pattern set |
| 0xE8 | rmsvs | rhythm master volume set |
| 0xE7 | comshift2 | shift 2 |
| 0xDA | porta | portamento |
| 0xCB | lfowave_set | LFO wave |
| 0xCA | lfo_extend | LFO extend mode |
| 0xC8 | slotdetune_set | FM3 slot detune |
| 0xC0 | fm_mml_part_mask | part mask |
| 0xB7 | mdepth_count | MD count |
| 0xB1 | comq4 | (com_end、 dispatch table 末尾) |

(全 entry は §5 で詳細化、 v2 で完成)

### 4-2. cmdtblp(PSG)差分

PMD.ASM L1888-(同じ opcode 範囲、 一部 entry が異なる):

| opcode | cmdtbl(FM/PCM) | cmdtblp(PSG) |
|---|---|---|
| 0xF4 | comvolup | comvolupp |
| 0xF3 | comvoldown | comvoldownp |
| 0xF1 | lfoswitch_f | lfoswitch |
| 0xF0 | jump4 | **psgenvset** |
| 0xEE | jump1 | psgnoise |
| 0xED | jump1 | psgsel |
| 0xEC | panset | jump1(PSG に pan なし) |
| 0xDE | vol_one_up_fm | vol_one_up_psg |
| 0xDA | porta | portap |

---

## 5. part body の opcode 列詳細(v2 で詰める)

### 5-1. 音程 + 音長(opcode 0x00〜0x7F)

opcode 0x00〜0x7F は dispatch table 範囲外、 「音程 + 音長」 として解釈。

PMD.ASM では別 routine(`mml_main` 系)で処理。 詳細解析は v2 で。

### 5-2. レスト + 拡張(opcode 0x80〜0xB0)

opcode 0x80 = part END / empty marker(driver L538「先頭が80hなら演奏しない」)。

opcode 0x81〜0xB0 はレスト + 各種拡張。 詳細解析は v2 で。

### 5-3. 制御コマンド(opcode 0xB1〜0xFF)

§4 の dispatch table マップで一部判明。 各 handler の引数 byte 数 / 解釈
ルールの完全マップは v2 で。

---

## 6. 残課題(v2 で詰める)

1. **dispatch table の opcode → handler 完全マップ**(全 80 entry × 3 table)
2. **各 handler の引数 byte 数 / 解釈ルール**
3. **opcode 0x00〜0x7F の音程 + 音長 解釈ルール**
4. **opcode 0x80〜0xB0 のレスト + 拡張**
5. **rhythm address table 構造**(SAMPLE2.M で複数 R パターン解析)
6. **prgdat 領域の中身**(音色データ format)
7. **SAMPLE.M file byte 1108〜1141 の解析**(rhythm addr + prgdat の実体)
8. **SAMPLE2.M / SSGEG_S.M との比較解析**
9. **PMDDotNET driver(PMD.cs)の dispatch ループ実装読解** → Phase 2 driver
   実装の参考

---

## 7. PMDNEO 設計への含意

### 7-1. 確定事項(Phase 2 driver 実装で使う)

- `.m` 構造: `m_start (1 byte) + m_buf`、 m_buf header 24 byte
- 11 part offset table(各 LE 16-bit、 mmlbuf 相対)
- rhythm address table offset(2 byte LE)
- option prgdat_adr(2 byte LE、 part A offset != 24 のみ存在)
- 各 part body 先頭 0x80 で empty 判定
- dispatch table 3 種類(FM/PCM / PSG / Rhythm)、 opcode 0xB1〜0xFF を扱う

### 7-2. PMDNEO 専用拡張(`.mn`)の方針

Phase 3 で `.mn` 拡張時、 V4.8s 互換 24 byte header 構造を維持し、
**OPNB 専用 opcode は cmdtbl の `jump1` (= 未使用 entry)を埋める**形で
追加する(§1-8 設計書方針)。 候補となる未使用 entry:

| opcode | 現状 | PMDNEO 拡張候補 |
|---|---|---|
| 0xC9 | jump1 | ADPCM-A keyon? |
| 0xCC | jump1 | ADPCM-A volume? |
| 0xD0 | jump1 | (未定) |
| 0xD1 | jump1 | (未定) |
| 0xD7-0xD9 | jump1 | (未定) |
| 0xE0(PSG) | jump1 | (未定) |

(具体的な opcode 割当は Phase 3 設計時に確定)

### 7-3. driver 実装方針(Phase 2)

- `.m` ロード時に m_start を `mmlbuf - 1` に、 m_buf を `mmlbuf` 以降に配置
- `play_init` で 11 part offset を絶対アドレス化、 各 part workarea に格納
- メイン loop: 各 part の現在位置 byte を読み、 dispatch table で handler 呼出
- empty marker(0x80)を踏んだ part は keyon せず idle

詳細実装は Phase 2 sprint 開始時に `src/driver/` で起こす。

---

[v1 解析完了、 §5(opcode 詳細)・§6 残課題 は v2 で詰める]
