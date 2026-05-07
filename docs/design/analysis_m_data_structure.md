# `.m` データ構造徹底解析

	解析対象: `vendor/pmd48s/SAMPLE.M`(1142 byte、 PMD V4.8s mc 出力)
	一次資料: `PMDDotNET`(kuma4649氏作、 GPL-3.0、 https://github.com/kuma4649/PMDDotNET)
	補助資料: `vendor/pmd48s/source/pmd48s/PMD.ASM`(x86 アセンブリ、 10864 行)
	目的: PMDNEO Phase 2 driver(Z80 フルスクラッチ)の仕様基盤

	状態: v2 解析完了(dispatch table 完全マップ + handler 引数 byte 数 + opcode 0x00〜0xFF 解釈ルール + Phase 2 driver 擬似コード)、 v3 残課題は §6-2 参照

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

### 4-1. jump0〜jump16(引数 N byte skip routine)

PMD.ASM L2035-2049 で `inc si` チェーンとして実装:

```
jump16:  add si, 10  ; → fall through
jump6:   inc si      ; → fall through
jump5:   inc si      ; → fall through
jump4:   inc si      ; → fall through
jump3:   inc si      ; → fall through
jump2:   inc si      ; → fall through
jump1:   inc si      ; → fall through
jump0:   ret
```

つまり `jumpN` = N byte の引数を skip して次の opcode に進む。 これは
**「opcode 自身は機能を持たず、 後続の N byte の引数を消費するだけの
プレースホルダ entry」**を意味する:

- `jump0` (= 0 byte skip) = 引数なし、 即 ret(機能なし)
- `jump1` (= 1 byte skip) = 1 byte 引数を消費するが何もしない
- `jump2` (= 2 byte skip) = 2 byte 引数を消費するが何もしない
- ...
- `jump16` (= 10 byte skip)

dispatch table の `jumpN` entry は、 当該 opcode が「該当 driver で
未実装」 または「予約済」 であり、 引数 byte 数だけ skip する仕様。

### 4-2. cmdtbl 完全マップ(FM/PCM 用、 PMD.ASM L1745-1842)

cmdtbl は opcode 0xFF から 0xB1 まで降順に 79 entry。 `[arg]` 列は
jumpN entry から判定した引数 byte 数(handler 系は不明、 別途要解析)。

| opcode | handler | [arg] | 機能 |
|---|---|---|---|
| 0xFF | com@ | ? | `@` 音色番号指定 |
| 0xFE | comq | ? | `q` gate time |
| 0xFD | comv | ? | `v` volume |
| 0xFC | comt | ? | `t` tempo |
| 0xFB | comtie | ? | `&` tie / slur |
| 0xFA | comd | ? | `D` detune |
| 0xF9 | comstloop | ? | `[` ループ start |
| 0xF8 | comedloop | ? | `]` ループ end |
| 0xF7 | comexloop | ? | `:` ループ exit |
| 0xF6 | comlopset | ? | loop set |
| 0xF5 | comshift | ? | shift |
| 0xF4 | comvolup | ? | volume up |
| 0xF3 | comvoldown | ? | volume down |
| 0xF2 | lfoset | ? | `M` LFO 設定 |
| 0xF1 | lfoswitch_f | ? | `*` LFO switch |
| 0xF0 | jump4 | **4** | (FM/PCM では未実装、 4 byte 引数 skip) |
| 0xEF | comy | ? | `y` OPN(A) reg 直接書込み |
| 0xEE | jump1 | **1** | (未実装、 1 byte skip) |
| 0xED | jump1 | **1** | (未実装、 1 byte skip) |
| 0xEC | panset | ? | `p` pan set |
| 0xEB | rhykey | ? | rhythm keyon |
| 0xEA | rhyvs | ? | rhythm volume set(per ch) |
| 0xE9 | rpnset | ? | rhythm pattern set |
| 0xE8 | rmsvs | ? | rhythm master volume set |
| 0xE7 | comshift2 | ? | shift 2 (V2.0 追加) |
| 0xE6 | rmsvs_sft | ? | rhythm master vol shift |
| 0xE5 | rhyvs_sft | ? | rhythm vol shift |
| 0xE4 | hlfo_delay | ? | hardware LFO delay |
| 0xE3 | comvolup2 | ? | volume up 2 (V2.3 追加) |
| 0xE2 | comvoldown2 | ? | volume down 2 (V2.3 追加) |
| 0xE1 | hlfo_set | ? | hardware LFO 設定 (V2.4) |
| 0xE0 | hlfo_onoff | ? | hardware LFO on/off (V2.4) |
| 0xDF | syousetu_lng_set | ? | 小節長 設定 |
| 0xDE | vol_one_up_fm | ? | 1ノートのみ volume up |
| 0xDD | vol_one_down | ? | 1ノートのみ volume down |
| 0xDC | status_write | ? | STATUS write |
| 0xDB | status_add | ? | STATUS add |
| 0xDA | porta | ? | `{}` portamento |
| 0xD9 | jump1 | **1** | (未実装、 1 byte skip) |
| 0xD8 | jump1 | **1** | (未実装、 1 byte skip) |
| 0xD7 | jump1 | **1** | (未実装、 1 byte skip) |
| 0xD6 | mdepth_set | ? | MDepth 設定 |
| 0xD5 | comdd | ? | `DD` 相対 detune |
| 0xD4 | ssg_efct_set | ? | SSG 効果音設定 |
| 0xD3 | fm_efct_set | ? | FM 効果音設定 |
| 0xD2 | fade_set | ? | fade out 設定 |
| 0xD1 | jump1 | **1** | (未実装、 1 byte skip) |
| 0xD0 | jump1 | **1** | (未実装、 1 byte skip) |
| 0xCF | slotmask_set | ? | slot mask |
| 0xCE | jump6 | **6** | (未実装、 6 byte skip) |
| 0xCD | jump5 | **5** | (未実装、 5 byte skip) |
| 0xCC | jump1 | **1** | (未実装、 1 byte skip) |
| 0xCB | lfowave_set | ? | LFO wave 形 |
| 0xCA | lfo_extend | ? | LFO 拡張 mode |
| 0xC9 | jump1 | **1** | (未実装、 1 byte skip) |
| 0xC8 | slotdetune_set | ? | FM3 slot detune |
| 0xC7 | slotdetune_set2 | ? | FM3 slot detune 2 |
| 0xC6 | fm3_extpartset | ? | FM3 extend part set |
| 0xC5 | volmask_set | ? | volume mask |
| 0xC4 | comq2 | ? | gate time 2 |
| 0xC3 | panset_ex | ? | pan set extended |
| 0xC2 | lfoset_delay | ? | LFO delay |
| 0xC1 | jump0 | **0** | sular(slur)、 引数なし |
| 0xC0 | fm_mml_part_mask | ? | part mask(2-step dispatch、 §4-5 参照) |
| 0xBF | _lfoset | ? | sub LFO 設定 |
| 0xBE | _lfoswitch_f | ? | sub LFO switch |
| 0xBD | _mdepth_set | ? | sub MDepth |
| 0xBC | _lfowave_set | ? | sub LFO wave |
| 0xBB | _lfo_extend | ? | sub LFO extend |
| 0xBA | _volmask_set | ? | sub vol mask |
| 0xB9 | _lfoset_delay | ? | sub LFO delay |
| 0xB8 | tl_set | ? | TL 設定 |
| 0xB7 | mdepth_count | ? | MD count |
| 0xB6 | fb_set | ? | FB 設定 |
| 0xB5 | slot_delay | ? | slot delay |
| 0xB4 | jump16 | **10** | (未実装、 add si,10 で 10 byte skip) |
| 0xB3 | comq3 | ? | gate time 3 |
| 0xB2 | comshift_master | ? | master shift |
| 0xB1 | comq4 | ? | gate time 4(com_end = 0xB1、 dispatch table 末尾) |

合計 79 entry (0xFF - 0xB1 + 1 = 79)。 jumpN(未実装) = 11 entry、
実装ありの handler = 68 entry。

### 4-3. cmdtblp 完全マップ(PSG 用、 PMD.ASM L1843-1938)

cmdtbl と差分があるところを ★ 印で示す:

| opcode | cmdtbl(FM/PCM) | cmdtblp(PSG) | 備考 |
|---|---|---|---|
| 0xFF | com@ | jump1 | ★ PSG に音色番号指定なし |
| 0xFE | comq | comq | |
| 0xFD | comv | comv | |
| 0xFC | comt | comt | |
| 0xFB | comtie | comtie | |
| 0xFA | comd | comd | |
| 0xF9 | comstloop | comstloop | |
| 0xF8 | comedloop | comedloop | |
| 0xF7 | comexloop | comexloop | |
| 0xF6 | comlopset | comlopset | |
| 0xF5 | comshift | comshift | |
| 0xF4 | comvolup | comvolupp | ★ PSG 用 vol up |
| 0xF3 | comvoldown | comvoldownp | ★ PSG 用 vol down |
| 0xF2 | lfoset | lfoset | |
| 0xF1 | lfoswitch_f | lfoswitch | ★ PSG では `_f` なし版 |
| 0xF0 | jump4 | **psgenvset** | ★ PSG では psg envelope set(`E` コマンド) |
| 0xEF | comy | comy | |
| 0xEE | jump1 | **psgnoise** | ★ PSG noise |
| 0xED | jump1 | **psgsel** | ★ PSG select(TONE/NOISE/MIX) |
| 0xEC | panset | jump1 | ★ PSG に pan なし |
| 0xEB | rhykey | rhykey | |
| 0xEA | rhyvs | rhyvs | |
| 0xE9 | rpnset | rpnset | |
| 0xE8 | rmsvs | rmsvs | |
| 0xE7 | comshift2 | comshift2 | |
| 0xE6 | rmsvs_sft | rmsvs_sft | |
| 0xE5 | rhyvs_sft | rhyvs_sft | |
| 0xE4 | hlfo_delay | jump1 | ★ PSG に hardware LFO なし |
| 0xE3 | comvolup2 | comvolupp2 | ★ PSG 用 |
| 0xE2 | comvoldown2 | comvoldownp2 | ★ PSG 用 |
| 0xE1 | hlfo_set | jump1 | ★ PSG に hardware LFO なし |
| 0xE0 | hlfo_onoff | jump1 | ★ PSG に hardware LFO なし |
| 0xDF | syousetu_lng_set | syousetu_lng_set | |
| 0xDE | vol_one_up_fm | vol_one_up_psg | ★ PSG 用 |
| 0xDD | vol_one_down | vol_one_down | |
| 0xDC | status_write | status_write | |
| 0xDB | status_add | status_add | |
| 0xDA | porta | portap | ★ PSG 用 portamento |
| 0xD9-D7 | jump1 ×3 | jump1 ×3 | |
| 0xD6 | mdepth_set | mdepth_set | |
| 0xD5 | comdd | comdd | |
| 0xD4 | ssg_efct_set | ssg_efct_set | |
| 0xD3 | fm_efct_set | fm_efct_set | |
| 0xD2 | fade_set | fade_set | |
| 0xD1 | jump1 | jump1 | |
| 0xD0 | jump1 | **psgnoise_move** | ★ PSG noise 平均周波数移動 |
| 0xCF | slotmask_set | jump1 | ★ PSG に slot mask なし |
| 0xCE | jump6 | jump6 | |
| 0xCD | jump5 | **extend_psgenvset** | ★ PSG 拡張 envelope set(SSG-EG ソフト) |
| 0xCC | jump1 | **detune_extend** | ★ PSG 拡張 detune |
| 0xCB | lfowave_set | lfowave_set | |
| 0xCA | lfo_extend | lfo_extend | |
| 0xC9 | jump1 | **envelope_extend** | ★ PSG 拡張 envelope mode |
| 0xC8 | slotdetune_set | jump3 | ★ PSG では未実装(3 byte skip) |
| 0xC7 | slotdetune_set2 | jump3 | ★ PSG では未実装(3 byte skip) |
| 0xC6 | fm3_extpartset | jump6 | ★ PSG では未実装(6 byte skip) |
| 0xC5 | volmask_set | jump1 | ★ PSG では未実装 |
| 0xC4 | comq2 | comq2 | |
| 0xC3 | panset_ex | jump2 | ★ PSG では未実装(2 byte skip) |
| 0xC2 | lfoset_delay | lfoset_delay | |
| 0xC1 | jump0 | jump0 | sular |
| 0xC0 | fm_mml_part_mask | **ssg_mml_part_mask** | ★ PSG 用 part mask |
| 0xBF | _lfoset | _lfoset | |
| 0xBE | _lfoswitch_f | _lfoswitch | |
| 0xBD | _mdepth_set | _mdepth_set | |
| 0xBC | _lfowave_set | _lfowave_set | |
| 0xBB | _lfo_extend | _lfo_extend | |
| 0xBA | _volmask_set | jump1 | ★ |
| 0xB9 | _lfoset_delay | _lfoset_delay | |
| 0xB8 | tl_set | jump2 | ★ PSG で TL なし |
| 0xB7 | mdepth_count | mdepth_count | |
| 0xB6 | fb_set | jump1 | ★ PSG で FB なし |
| 0xB5 | slot_delay | jump2 | ★ PSG で slot delay なし |
| 0xB4 | jump16 | jump16 | |
| 0xB3 | comq3 | comq3 | |
| 0xB2 | comshift_master | comshift_master | |
| 0xB1 | comq4 | comq4 | |

PSG 拡張機能(PMDAES の R2 sprint で扱った):

- 0xCD `extend_psgenvset` = SSG-EG ソフトウェアエンベロープ
- 0xCC `detune_extend` = 拡張 detune
- 0xC9 `envelope_extend` = エンベロープ拡張 mode 切替

### 4-4. cmdtblr 完全マップ(Rhythm 用、 PMD.ASM L1939-)

K/R パート専用。 cmdtbl との差分:

| opcode | cmdtbl(FM/PCM) | cmdtblr(Rhythm) | 備考 |
|---|---|---|---|
| 0xFF | com@ | jump1 | ★ Rhythm では @ なし |
| 0xFE | comq | jump1 | ★ Rhythm では q なし |
| 0xFD | comv | comv | |
| 0xFC〜0xF6 | (各種) | (同) | tempo / tie / detune / loop |
| 0xF5 | comshift | jump1 | ★ Rhythm では shift なし |
| 0xF4 | comvolup | comvolupp | |
| 0xF3 | comvoldown | comvoldownp | |
| 0xF2 | lfoset | jump4 | ★ Rhythm では LFO なし |
| 0xF1 | lfoswitch_f | **pdrswitch** | ★ Rhythm では PDR switch |
| 0xF0 | jump4 | jump4 | |
| 0xDA | porta | jump1 | ★ Rhythm では porta なし(通常音程コマンドに) |
| 0xC0 | fm_mml_part_mask | **rhythm_mml_part_mask** | ★ Rhythm 用 part mask |
| (他) | (jumpN 多数) | (同等) | 多くは cmdtblp 同様、 jumpN で未実装 |

Rhythm 専用機能はかなり限定的。 大半の opcode が `jump1`〜`jump6` で
未実装、 必要最小限の音楽制御コマンドのみ active。

### 4-5. 0xC0 sub-dispatch(comtbl0c0h)

cmdtbl の 0xC0 = `fm_mml_part_mask`(L1824)、 cmdtblp の 0xC0 =
`ssg_mml_part_mask`、 cmdtblr の 0xC0 = `rhythm_mml_part_mask`。

これらの handler 内で part mask をかけるが、 さらに **追加のサブ
dispatch** がある。 PMD.ASM L2058-(special_0c0h):

```
special_0c0h:
    cmp al, com_end_0c0h     ; com_end_0c0h = 0xF5(なお L2077 に定義)
    jc out_of_commands
    not al
    add al, al
    xor ah, ah
    mov bx, ax
    mov ax, cs:comtbl0c0h[bx]
    jmp ax

comtbl0c0h:
    dw vd_fm        ;0FFh
    dw _vd_fm       ;0FEh
    dw vd_ssg       ;0FDh
    dw _vd_ssg      ;0FCh
    dw vd_pcm       ;0FBh
    dw _vd_pcm      ;0FAh
    dw vd_rhythm    ;0F9h
    dw _vd_rhythm   ;0F8h
    dw pmd86_s      ;0F7h
    dw vd_ppz       ;0F6h
    dw _vd_ppz      ;0F5h
```

二段階 dispatch:

1. opcode 0xC0 → fm_mml_part_mask 等(part 種別で分岐)、 続く 1 byte を
   `lodsb` で読込
2. 続く byte が 0〜1 なら part mask on/off
3. 続く byte が 2〜0xF4 なら out_of_commands(終了)
4. 続く byte が 0xF5〜0xFF なら comtbl0c0h で sub-dispatch

#### 4-5-1. comtbl0c0h sub-handler 引数 byte 数

各 sub-handler は全て **1 byte 引数**(PMD.ASM L2082-2154):

| sub byte | sub-handler | byte | 機能 |
|---|---|---|---|
| 0xFF | vd_fm | 1 | FM 音源 voldown 設定 |
| 0xFE | _vd_fm | 1 | FM 相対 voldown |
| 0xFD | vd_ssg | 1 | SSG voldown 設定 |
| 0xFC | _vd_ssg | 1 | SSG 相対 voldown |
| 0xFB | vd_pcm | 1 | PCM voldown 設定 |
| 0xFA | _vd_pcm | 1 | PCM 相対 voldown |
| 0xF9 | vd_rhythm | 1 | Rhythm voldown 設定 |
| 0xF8 | _vd_rhythm | 1 | Rhythm 相対 voldown |
| 0xF7 | pmd86_s | 1 | PMD86 PCM volume mode |
| 0xF6 | vd_ppz | 1 | PPZ voldown 設定 |
| 0xF5 | _vd_ppz | 1 | PPZ 相対 voldown |

つまり 0xC0 sub-dispatch シーケンス全長 = **3 byte**:

```
0xC0 + [sub byte (0xF5〜0xFF)] + [voldown 値 (1 byte)]
```

通常の 0xC0 part mask シーケンス = **2 byte**:

```
0xC0 + [0 or 1 (part mask off/on)]
```

### 4-6. dispatch ループの仕組み

PMD.ASM L1713-1737:

```
commands:                    ; FM/PCM 用 entry
    mov bx, offset cmdtbl
    jmp command00

commandsr:                   ; Rhythm 用 entry
    mov bx, offset cmdtblr
    jmp command00

commandsp:                   ; PSG 用 entry
    mov bx, offset cmdtblp

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

- 各 part 種別ごとに `commands` / `commandsp` / `commandsr` のいずれかが
  呼ばれる
- 共通 routine `command00` で `al`(opcode)から `cmdtbl[0xFF - opcode]`
  の handler を呼び出す
- `al < 0xB1` なら `out_of_commands` → part END(`mov byte ptr [si], 80h`)

### 4-7. handler 別引数 byte 数表

PMD.ASM の各 handler の冒頭 `lodsb`(1 byte) / `lodsw`(2 byte) を読
取って引数 byte 数を判定した結果。 `?` は未確定(複雑な分岐 / sub
dispatch あり、 v3 で精緻化)。

#### 4-7-1. 基本コマンド系

| handler | byte | 行 | 機能 |
|---|---|---|---|
| com@ | 1 | L3336 | `@` 音色番号 |
| comq | 1 | L3381 | `q` gate time |
| comq2 | 1 | L3398 | gate time 2 |
| comq3 | 1 | L3386 | gate time 3 |
| comq4 | 1 | L3390 | gate time 4 |
| comv | 1 | L3406 | `v` volume |
| comt | 1+ | L3417 | `t` tempo (251 以上で別 mode) |
| comtie | 0 | L3524 | `&` tie / slur (tieflag セットのみ) |
| comd | 2 | L3531 | `D` detune (lodsw) |
| comdd | 2 | L3538 | `DD` 相対 detune (lodsw) |
| comy | 2 | L3878 | `y` OPN reg/val 直書込 (lodsw) |
| panset | 1 | L3914 | `p` pan set |
| comshift | 1 | L3620 | `_` shift |
| comshift2 | 1 | L3628 | `__` shift 2 |
| comshift_master | 1 | L3636 | `_M` master shift |

#### 4-7-2. ループ系

| handler | byte | 行 | 機能 |
|---|---|---|---|
| comstloop | 2 | L3545 | `[` loop start (loop addr lodsw) |
| comedloop | 5 | L3561 | `]` loop end (count + addr 等、 複雑) |
| comexloop | 2 | L3590 | `:` loop exit (lodsw) |
| comlopset | 0 | L3613 | `L` loop set (現在 si を partloop 保存) |

#### 4-7-3. LFO 系

| handler | byte | 行 | 機能 |
|---|---|---|---|
| lfoset | 4 | L3813 | `M` LFO 設定 (delay/speed/step/time) |
| lfoset_delay | 1 | L3827 | LFO delay only |
| lfoswitch | 1 | L3836 | LFO switch (PSG 用) |
| lfoswitch_f | 1 | L3847 | `*` LFO switch FM(lfoswitch + ch3) |
| lfowave_set | 1 | L2630 | LFO wave 形 |
| lfo_extend | 1 | L2607 | LFO extend mode |
| _lfoset | 4 | L3720 | sub LFO 設定 |
| _lfoswitch | 1 | L3749 | sub LFO switch |
| _lfoswitch_f | 1 | L3762 | sub LFO switch FM |
| _lfowave_set | 1 | L3737 | sub LFO wave |
| _lfo_extend | 1 | L3741 | sub LFO extend |
| _lfoset_delay | 1 | L3745 | sub LFO delay |
| mdepth_set | 2 | L3037 | MDepth 設定 (mdspd + mdepth) |
| _mdepth_set | 2 | L3733 | sub MDepth |
| mdepth_count | 1 | L3045 | MD count |

#### 4-7-4. ハードウェア LFO(YM2608/YM2610B 専用)

| handler | byte | 行 | 機能 |
|---|---|---|---|
| hlfo_set | 1 | L3260 | hardware LFO 設定 |
| hlfo_onoff | 1 | L3304 | hardware LFO on/off |
| hlfo_delay | 1 | L3318 | hardware LFO delay |

#### 4-7-5. ボリューム系

| handler | byte | 行 | 機能 |
|---|---|---|---|
| comvolup | 0 | L3646 | `)` volume up (FM 固定 +4) |
| comvolup2 | 1 | L3657 | `)+n` volume up (相対値) |
| comvolupp | 0 | L3663 | `)` volume up (PSG 固定 +1) |
| comvolupp2 | 1 | L3673 | `)+n` volume up (PSG 相対) |
| comvoldown | 0 | L3682 | `(` volume down (FM 固定 -4) |
| comvoldown2 | 1 | L3690 | `(+n` volume down |
| comvoldownp | 0 | L3700 | `(` volume down (PSG 固定 -1) |
| comvoldownp2 | 1 | L3708 | `(+n` volume down (PSG 相対) |
| vol_one_up_fm | 1 | L3218 | 1 ノートのみ vol up (FM) |
| vol_one_up_psg | 1 | L3229 | 1 ノートのみ vol up (PSG) |
| vol_one_up_pcm | 1 | L3237 | 1 ノートのみ vol up (PCM) |
| vol_one_down | 1 | L3248 | 1 ノートのみ vol down |

#### 4-7-6. PSG 系

| handler | byte | 行 | 機能 |
|---|---|---|---|
| psgenvset | 4 | L3854 | `E` PSG envelope set (4 byte) |
| psgnoise | 1 | L3886 | `w` PSG noise pitch |
| psgnoise_move | 1 | L3892 | PSG noise relative move |
| psgsel | 1 | L3906 | `P` PSG TONE/NOISE/MIX |
| extend_psgenvset | 5 | L2638 | 拡張 PSG envelope (eenv_ar/dr/sr/sl + alm) |
| envelope_extend | 1 | L2618 | envelope mode |
| detune_extend | 1 | L2597 | 拡張 detune mode |

#### 4-7-7. Portamento 系

| handler | byte | 行 | 機能 |
|---|---|---|---|
| porta | 2 | L3085 | `{}` FM portamento (start/end onkai) |
| portap | 2 | L3155 | `{}` PSG portamento (start/end onkai) |

#### 4-7-8. リズム系(K/R パート関連)

| handler | byte | 行 | 機能 |
|---|---|---|---|
| rhykey | 1 | L3994 | rhythm keyon (rhythm trigger bitmap) |
| rhyvs | 1 | L4064 | rhythm volume (per ch) |
| rhyvs_sft | 2 | L4097 | rhythm vol shift (per ch + 値) |
| rpnset | 1 | L4136 | rhythm pattern set (pan + ch) |
| rmsvs | 1 | L4155 | `\V` rhythm master vol set |
| rmsvs_sft | 1 | L4184 | rhythm master vol shift |
| pdrswitch | 1 | L2478 | PDR switch (PPSDRV mode) |

#### 4-7-9. FM 拡張 / slot 系

| handler | byte | 行 | 機能 |
|---|---|---|---|
| tl_set | 2 | L2248 | TL 設定 |
| fb_set | 1 | L2176 | FB 設定 |
| slot_delay | 2 | L2159 | slot delay (m + count) |
| slotmask_set | 1 | L2839 | slot mask |
| slotdetune_set | 3 | L2704 | FM3 slot detune (mask + lodsw) |
| slotdetune_set2 | 3 | L2674 | FM3 slot detune2 (相対) |
| fm3_extpartset | 6 | L2549 | FM3 ext part set (3 × lodsw) |
| volmask_set | 1 | L2493 | volume mask |
| _volmask_set | 1 | L2510 | sub volume mask |
| panset_ex | 2 | L3972 | pan set 拡張 (pan 値 + 付加 flag) |

#### 4-7-10. 効果音 / その他

| handler | byte | 行 | 機能 |
|---|---|---|---|
| ssg_efct_set | 1 | L2957 | SSG 効果音設定 |
| fm_efct_set | 1 | L2981 | FM 効果音設定 |
| fade_set | 1 | L3029 | fade out |
| status_write | 1 | L3200 | STATUS write |
| status_add | 1 | L3208 | STATUS add |
| syousetu_lng_set | 1 | L3328 | `Z` 小節長設定 |

#### 4-7-11. Part mask 系(2 段 dispatch)

| handler | byte | 行 | 機能 |
|---|---|---|---|
| fm_mml_part_mask | 1 | L2357 | FM part mask (al = 0/1 で mask on/off、 al ≥ 2 で 0xC0 sub-dispatch) |
| ssg_mml_part_mask | 1 | L2378 | SSG part mask |
| rhythm_mml_part_mask | 1 | L2402 | rhythm part mask |

al ≥ 2 のとき `special_0c0h` ルートに分岐し、 続く byte が 0xF5〜0xFF
なら comtbl0c0h で sub-dispatch (vd_fm/vd_ssg/vd_pcm/vd_rhythm 等)。
sub-handler の引数 byte 数は別途要解析(v3)。

### 4-8. v2 解析の到達点

- **dispatch table 全 79 entry × 3 種(cmdtbl/cmdtblp/cmdtblr) 完全マップ完成**
- **jump0〜jump16 = N byte skip(未実装プレースホルダ) と判明**
- **dispatch ループ実装(command00) 解読完了**
- **0xC0 sub-dispatch(comtbl0c0h) 構造解明**
- **handler 別引数 byte 数 ~70 個判明**

### 4-9. v2 残課題(v3 で精緻化)

1. **opcode 0x00〜0x7F の音程 + 音長解釈**: ノート on の bit field 構造、 12半音 × オクターブ → opcode 値の mapping を解読。 PMD.ASM L1072(mp0 LENGTH CHECK)〜L1110(porta_return) の routine 解析。
2. **opcode 0x80〜0xB0 の用途**: 0x80 = empty / part end、 0x81〜0xB0 はレスト + 音長 / 拡張ノートが含まれる。 該当 routine 特定。
3. **rhythm address table 構造詳細**: cmdtblr で参照される radtbl(L8043)の format。 SAMPLE2.M(rhythm 使用)で複数 R パターン例を解析。
4. **prgdat 領域 format**: 音色データ 1 entry の byte 数 / FM operator 4 個の TL/AR/DR/SR/RR/SL/AM/KS/MUL/DT 等の field 配置。
5. **comtbl0c0h sub-handler 引数 byte 数**: vd_fm / vd_ssg / vd_pcm / vd_rhythm / pmd86_s / vd_ppz の引数仕様。
6. **handler 引数 byte 数 ? 残り**: rhykey / rhyvs / rpnset / rmsvs / rmsvs_sft / rhyvs_sft / panset_ex の確認。

---

## 5. part body の opcode 列詳細

### 5-1. 音程 + 音長(opcode 0x00〜0x7F)

opcode 0x00〜0x7F は dispatch table 範囲外、 PMD.ASM の `fmmain` /
`psgmain` / `rhythmmain` の mp1/mp2 routine(L1077-1110)で **音程 + 音長
の 2 byte 単位**として解釈される。

#### 5-1-1. 音程 byte の bit field 構造

PMD.ASM `fnumset`(L4266) と `oshift`(L4208) の解析より、 1 byte 音程
の bit 配置:

```
bit 7 6 5 4 | 3 2 1 0
+-----------+-----------+
|    OCT    |   ONKAI   |
+-----------+-----------+
```

- 上位 4 bit (bit 4-7) = OCT (オクターブ、 0-7)
- 下位 4 bit (bit 0-3) = ONKAI (音名、 0-11、 `0x0F` = 休符)

| ONKAI 値 | 音名 | fnum_data(FM) | psg_tune_data(PSG) |
|---|---|---|---|
| 0 | C | 0x026A | 0x0EE8 |
| 1 | C# (D-) | 0x028F | 0x0E12 |
| 2 | D | 0x02B6 | 0x0D48 |
| 3 | D# (E-) | 0x02DF | 0x0C89 |
| 4 | E | 0x030B | 0x0BD5 |
| 5 | F | 0x0339 | 0x0B2B |
| 6 | F# (G-) | 0x036A | 0x0A8A |
| 7 | G | 0x039E | 0x09F3 |
| 8 | G# (A-) | 0x03D5 | 0x0964 |
| 9 | A | 0x0410 | 0x08DD |
| 10 | A# (B-) | 0x044E | 0x085E |
| 11 | B | 0x048F | 0x07E6 |
| 12-14 | (未使用) | - | - |
| 15 (0x0F) | 休符 | (FNUM = 0) | (FNUM = 0) |

PMD.ASM L7925 `fnum_data`、 L7940 `psg_tune_data` 由来。

FM の発音時:
- BLOCK = OCT bits を再配置(`ror al,1; and ch,38h`)
- F-NUMBER = `fnum_data[ONKAI × 2]`
- 最終 `[fnum] = (BLOCK << 8) | F-NUMBER`

#### 5-1-2. 音長 byte

音程 byte の直後に **1 byte の音長(length)** が続く:

```
.m バイナリ:
+--------+--------+
| 音程    | 音長   |
| (1B)   | (1B)   |
+--------+--------+
```

PMD.ASM `mp2`(L1101)で `lodsb` → `mov leng[di], al` され、 各 part の
残り tick として cycle 毎に減算される。

つまり opcode 0x00〜0x7F の **1 ノートは 2 byte 単位**(音程 + 音長)。

### 5-2. opcode 0x80(part end / loop)

PMD.ASM `mp15`(L1088):

```
mp15:   dec     si                ; 0x80 を読み戻す
        mov     [di], si          ; 現在位置を更新せずに part 停止
        mov     loopcheck[di], 3  ; loop check = 3 (= part 終了)
        mov     onkai[di], -1
        mov     bx, partloop[di]
        test    bx, bx
        jz      mpexit            ; partloop 設定なしなら終了
        mov     si, bx            ; "L" loop set 済なら loop 戻り
        mov     loopcheck[di], 1
        jmp     mp1
```

つまり opcode 0x80 = **part END / loop マーカー**。 partloop[di](L コマンド
で設定)があれば loop 戻り、 なければ part 終了。

empty part(MML body 全くない) では byte 0 から `0x80` 1 byte で
即座に終了 → 「演奏しない」。

### 5-3. opcode 0x81〜0xB0(out_of_commands → 終了処理)

`commands`(L1713) → `command00`(L1724) で:

```
command00:
    cmp     al, com_end       ; com_end = 0xB1
    jc      out_of_commands   ; al < 0xB1 なら part END
```

つまり 0x81〜0xB0 は **個別の opcode 機能を持たない**。 全て
`out_of_commands` ルートで「無効 opcode → 即 part 終了」 として扱われる。

PMD MML には「`r` 休符 + 音長」 は 0x0F 音程 + 音長で表現されるため、
0x81〜0xB0 は事実上の予約領域(将来拡張用)と考えられる。

### 5-4. 制御コマンド(opcode 0xB1〜0xFF)

§4 の dispatch table 完全マップ + handler 別引数 byte 数表で網羅済。

### 5-5. .m バイナリ走査の擬似コード

```
si = part_offset_table[part]
while True:
    al = read_byte(si)
    si += 1
    if al < 0x80:
        # 音程
        leng = read_byte(si)
        si += 1
        # OCT = (al >> 4) & 0x07
        # ONKAI = al & 0x0F
        # ONKAI == 0x0F なら休符
        play_note(part, OCT, ONKAI, leng)
    elif al == 0x80:
        # part 終了 / loop 戻り
        if partloop[part]:
            si = partloop[part]
        else:
            break
    elif al < 0xB1:
        # out_of_commands → 終了
        break
    else:
        # 制御コマンド (dispatch table)
        handler = dispatch_table[part_kind][0xFF - al]
        handler(si)  # handler が必要な byte を消費
```

これで Phase 2 driver(Z80 フルスクラッチ)の **メインループ実装の
青写真** が確定。

### 5-6. Rhythm part(R part)の 2 段構造

K / R パート関連の処理は他 part(FM/SSG/PCM)と異なり、 **2 段の opcode
解釈**を持つ。 PMD.ASM `rhythmmain`(L1539-1670)の解析より:

#### 5-6-1. R part body(11 番目の part)

R part body 自体は通常の part body と似た構造だが、 **opcode 0x00〜0x7F の
意味が「R 番号(rhythm pattern index)」**:

| opcode | 意味 |
|---|---|
| 0x00〜0x7F | R 番号 = `radtbl[al]` 経由で rhythm pattern body にジャンプ |
| 0x80 | part end / loop 戻り(通常 part と同じ) |
| 0x81〜0xB0 | out_of_commands(終了) |
| 0xB1〜0xFF | cmdtblr の handler |

R 番号を踏むと、 `[radtbl + al × 2]` で 2 byte LE の pattern offset を
取得し、 `[rhyadr] = mmlbuf + offset` を設定して rhythm pattern body の
解釈を開始する(`re00` ルート、 L1577)。

#### 5-6-2. rhythm pattern body(radtbl が指す各 R# pattern)

各 R# pattern は別の opcode 体系を持つ:

| opcode | 意味 | byte 数 |
|---|---|---|
| 0x00〜0x7F | rest(休符)+ 音長 | 2 byte |
| 0x80〜0xBF | shot(rhythm trigger 14 bit bitmap)+ 音長 | 3 byte |
| 0xC0〜0xFE | command shot(bit 6 set、 commandsr 経由) | 可変 |
| 0xFF | pattern 終端 → R part body に戻る | 1 byte |

#### 5-6-3. shot opcode(0x80〜0xBF)の bitmap 構造

bit 7 set + bit 6 clear のとき、 shot 処理(`rhy_shot`、 L1616):

```
rhythmon:
    test    al, 01000000b    ; bit 6 = command 分岐
    jz      rhy_shot
    ... (commandsr ルート)

rhy_shot:
    mov     ah, al           ; 上位 byte = 現 byte
    mov     al, [bx]         ; 下位 byte = 続く 1 byte
    inc     bx
    and     ax, 03FFFh       ; 上位 2 bit を mask、 14 bit 値
    mov     [kshot_dat], ax  ; 14 bit rhythm trigger bitmap
```

kshot_dat = 14 bit、 各 bit が rhythm channel の trigger mask に対応。

#### 5-6-3-1. kshot_dat 14 bit → rhythm channel mapping(rhydat L8014)

PMD V4.8s OPNA built-in rhythm の rhydat 構造 11 entry × 3 byte:

| bit | rhydat index | rhythm 音 | OPNA register | KEYON bit |
|---|---|---|---|---|
| 0 | rhydat[0] | バス(BD) | 0x18 | 0x01 |
| 1 | rhydat[1] | スネア(SD) | 0x19 | 0x02 |
| 2 | rhydat[2] | 太鼓 LOW | 0x1C | 0x10 |
| 3 | rhydat[3] | 太鼓 MID | 0x1C | 0x10 |
| 4 | rhydat[4] | 太鼓 HIGH | 0x1C | 0x10 |
| 5 | rhydat[5] | 拍子木(RIM) | 0x1D | 0x20 |
| 6 | rhydat[6] | クラップ | 0x19 | 0x02 |
| 7 | rhydat[7] | C ハイハット | 0x1B | 0x88 |
| 8 | rhydat[8] | O ハイハット | 0x1A | 0x04 |
| 9 | rhydat[9] | シンバル | 0x1A | 0x04 |
| 10 | rhydat[10] | RIDE シンバル | 0x1A | 0x04 |
| 11-13 | (拡張) | PPSDRV / KP_rhythm 拡張用 | - | - |

各 rhydat entry は 3 byte: `[port (= 0x18+ch)][PAN | VOLUME][KEYON bit]`。

`rhy_shot` ルーチンの `rsb2lp`(L1641)で 14 bit を逐次 ror チェックし、
bit 立った channel ごとに rhydat 参照 → register 書込 → keyon 発行。

PMDNEO(YM2610/B)では OPNA built-in rhythm 非搭載のため、 この 11 ch
mapping は **ADPCM-A 6 ch + ADPCM-B 1 ch + 拡張**で代替設計する必要あり
(設計書 §1-8 で扱う)。

#### 5-6-4. radtbl(rhythm address table)の構造

`.m` ファイル byte 23-24(m_buf header の最後 2 byte)が radtbl の
file offset を示す。 radtbl 自体は:

```
radtbl[0] = R0 pattern offset  (2 byte LE、 mmlbuf 相対)
radtbl[1] = R1 pattern offset
radtbl[2] = R2 pattern offset
...
```

R 番号の数は MML から決まる(.m に明示記録なし、 末端は次の領域で判定)。

#### 5-6-5. rhythm pattern 解釈 擬似コード

```
[bx] = current rhythm pattern position ([rhyadr])
while True:
    al = read_byte(bx); bx += 1
    if al == 0xFF:
        # pattern 終端、 R part body に戻る
        break_to_R_part_body()
        continue
    if al & 0x80:
        # shot or command
        if al & 0x40:
            # command shot (commandsr)
            handler = cmdtblr[0xFF - al]
            handler(bx)
        else:
            # rhythm shot
            ah = al
            al = read_byte(bx); bx += 1
            kshot_dat = ((ah << 8) | al) & 0x3FFF
            trigger_rhythm_channels(kshot_dat)
            leng = read_byte(bx); bx += 1
            wait(leng)
    else:
        # rest
        kshot_dat = 0
        leng = read_byte(bx); bx += 1
        wait(leng)
```

これで rhythm pattern body の解釈ロジックも Phase 2 driver 実装に
落とし込める。

### 5-7. 音色データ(prgdat / tondat)の format

PMD.ASM `neiroset_main`(L5159) と `toneadr_calc`(L5274) の解析より、
音色データは 2 種類の経路がある。

#### 5-7-1. 音色データ access 経路

```
toneadr_calc:
    if [prg_flg] != 0 OR di == part_e:
        # prgdat 経路 (.m 内蔵)
        bx = [prgdat_adr]
        if di == part_e: bx = [prgdat_adr2]
        loop:
            if [bx] == tone_number: jump gpd_exit
            bx += 26
        gpd_exit:
            bx += 1   # 番号 byte を skip、 残り 25 byte が音色データ
    else:
        # tondat 経路 (外部音色 file = .FF / .OPM 等)
        bx = [tondat] + tone_number × 32
```

つまり:

- **prgdat 経路**(`.m` 内蔵モード): 26 byte / entry、 番号 byte 1 + 音色 25 byte
- **tondat 経路**(外部音色ファイル): 32 byte / entry、 番号は index で直接

#### 5-7-2. 音色データ 1 entry の field 配置

prgdat 経路の場合:

| offset | byte | 内容 |
|---|---|---|
| 0 | 1 | tone_number(検索 key) |
| 1-4 | 4 | DT / ML × 4 op (bit 7=0、 bit 6-4=DT、 bit 3-0=ML) |
| 5-8 | 4 | TL × 4 op (bit 6-0=TL、 bit 7=0) |
| 9-12 | 4 | KS / AR × 4 op (bit 7-6=KS、 bit 4-0=AR) |
| 13-16 | 4 | AM / DR × 4 op (bit 7=AM、 bit 4-0=DR) |
| 17-20 | 4 | SR × 4 op (bit 4-0=SR) |
| 21-24 | 4 | RR / SL × 4 op (bit 7-4=SL、 bit 3-0=RR) |
| 25 | 1 | ALG / FB (bit 5-3=FB、 bit 2-0=ALG、 bit 6 = SSG-EG 領域?) |

合計 26 byte。

tondat 経路の場合:

- byte 0-3: DT / ML × 4 op
- byte 4-7: TL × 4 op
- byte 8-11: KS / AR × 4 op
- byte 12-15: AM / DR × 4 op
- byte 16-19: SR × 4 op
- byte 20-23: RR / SL × 4 op
- byte 24: ALG / FB
- byte 25-31: padding / 拡張 field(SSG-EG 等)

合計 32 byte。

PMD.ASM `neiroset_main` の register 書込ループで:
- `mov dl, 24[bx]` → ALG/FB(register 0xB0+ch)
- `mov cx, 4; ns01: ...; add dh, 4` → DT/ML, TL, KS/AR, ... を operator 順に書込

OPN/OPNA/OPNB の register 0x30〜0x9F(operator parameter)に対応。

#### 5-7-3. operator 順序(YM2610/B register slot 順)

PMD.ASM `neiroset_main`(L5159) の書込ループ:

```
mov  dh, 0x30 - 1
add  dh, [partb]            ; dh = DT/ML 開始 register

mov  cx, 4    ; DT/ML loop
ns01:
    mov  dl, [bx]; inc bx   ; .m 内 1 byte 読込
    rol  al, 1
    jnc  ns_ns
    call opnset
ns_ns:
    add  dh, 4              ; register +4 = 次 slot
    loop ns01
```

dh は `+4` で進むので、 register 書込は 0x30 → 0x34 → 0x38 → 0x3C
**slot 1 → slot 2 → slot 3 → slot 4** の順。

YM2610 / YM2608 / YM2151 等 OPNX 系の register 上の slot 番号 と OP 番号
の対応は:

| register slot | OP 番号(MML 上) | 役割(典型 ALG=4 時) |
|---|---|---|
| slot 1 | OP1 | modulator 1(M1) |
| slot 2 | OP3 | modulator 2(M2) |
| slot 3 | OP2 | carrier 1(C1) |
| slot 4 | OP4 | carrier 2(C2) |

つまり **.m バイナリ内格納順は YM2610 register slot 順(1, 2, 3, 4)
= OP 番号順では(OP1, OP3, OP2, OP4)** という固有順序。

各 parameter block の格納:

| .m offset | register | 内容 | 格納順 |
|---|---|---|---|
| 1-4 | 0x30〜0x3C | DT / ML | OP1, OP3, OP2, OP4 |
| 5-8 | 0x40〜0x4C | TL | OP1, OP3, OP2, OP4 |
| 9-12 | 0x50〜0x5C | KS / AR | OP1, OP3, OP2, OP4 |
| 13-16 | 0x60〜0x6C | AM / DR | OP1, OP3, OP2, OP4 |
| 17-20 | 0x70〜0x7C | SR | OP1, OP3, OP2, OP4 |
| 21-24 | 0x80〜0x8C | RR / SL | OP1, OP3, OP2, OP4 |
| 25 | 0xB0 | ALG / FB | (ch 単位) |

PMDNEO(YM2610/B)も同じ register layout のため、 この固有順序を
そのまま採用する。

#### 5-7-4. PMDNEO 設計への含意

- prgdat 経路の 26 byte / entry format をそのまま採用可能
- ただし PMDNEO は OPNB(YM2610/B) なので、 SSG-EG bit の扱いを v3 で要確認
- 音色データを `.mn` ファイルに内蔵する場合、 prgdat_adr 経路で参照

---

## 6. v2 までで完了した解析と残課題

### 6-1. v2 完了項目

- ✅ `.m` 全体構造(m_start + m_buf header + part body + rhythm + prgdat)
- ✅ 11 part offset table の解読
- ✅ rhythm address table offset / prgdat_adr の格納位置
- ✅ SAMPLE.M(1142 byte)完全 byte map
- ✅ dispatch table 全 79 entry × 3 種(cmdtbl/cmdtblp/cmdtblr) 完全マップ
- ✅ jump0〜jump16(N byte skip プレースホルダ)の意味解明
- ✅ dispatch ループ(command00) routine 解読
- ✅ 0xC0 sub-dispatch(comtbl0c0h) 構造解明
- ✅ handler 別引数 byte 数 ~75 個判明(rhythm 系含む)
- ✅ opcode 0x00〜0x7F = 音程 + 音長(2 byte 単位、 OCT 4 bit + ONKAI 4 bit)
- ✅ opcode 0x80 = part end / loop マーカー
- ✅ opcode 0x81〜0xB0 = out_of_commands(終了処理)
- ✅ Phase 2 driver メインループ擬似コード(§5-5)
- ✅ Rhythm part 2 段構造(R part body + radtbl + rhythm pattern body)解明(§5-6)
- ✅ kshot_dat 14 bit → rhythm channel mapping(rhydat 11 entry)解明(§5-6-3-1)
- ✅ 音色データ format(prgdat 26 byte / tondat 32 byte 経路)解明(§5-7)
- ✅ 音色データ operator 順序(register slot 順 = OP1, OP3, OP2, OP4)確定(§5-7-3)
- ✅ comtbl0c0h sub-handler 11 個の引数 byte 数(全て 1 byte)解明(§4-5-1)

### 6-2. v3 で精緻化する課題

1. **SAMPLE.M file byte 1108〜1141 の rhythm addr table 実体解析**。
2. **SAMPLE2.M / SSGEG_S.M との比較解析**(複数 R パターン / 拡張機能例)。
3. **comt(tempo)の 251 以上 mode 解析**(comt_sp0/sp1/sp2 分岐)。
4. **音色データ SSG-EG bit 配置**: 拡張 envelope generator の register field。
5. **kshot_dat 上位 3 bit(bit 11-13)の PPSDRV / KP_rhythm 拡張動作詳細**(rhydat 11 entry を超えた範囲の挙動)。

---

## 7. PMDNEO 設計への含意

### 7-1. 確定事項(Phase 2 driver 実装で使う)

- `.m` 構造: `m_start (1 byte) + m_buf`、 m_buf header 24 byte
- 11 part offset table(各 LE 16-bit、 mmlbuf 相対)
- rhythm address table offset(2 byte LE)
- option prgdat_adr(2 byte LE、 part A offset != 24 のみ存在)
- 各 part body 先頭 0x80 で empty 判定
- opcode 0x00〜0x7F = 音程(OCT 4 bit + ONKAI 4 bit)+ 音長(1 byte) の 2 byte 単位
- opcode 0x80 = part end / loop 戻り
- opcode 0x81〜0xB0 = 無効(out_of_commands → 終了処理)
- opcode 0xB1〜0xFF = dispatch table 3 種類(FM/PCM / PSG / Rhythm)
- jumpN entry = N byte 引数 skip(プレースホルダ)
- 0xC0 = part mask + 2 段 dispatch(comtbl0c0h)

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

[v2 解析完了 — dispatch table 完全マップ + handler 別引数 byte 数 + opcode 0x00〜0xFF 解釈ルール確定 + Phase 2 driver メインループ擬似コード確立。 v3 残課題は §6-2 参照]
