# PPZ8 → ADPCM-A 6ch 翻訳 mapping 表

	位置付け: PMDNEO Phase 2 driver 着手前 設計書 3 種の 2 番目 (= 翻訳指針)
	参照: [`mn_binary_layout.md`](mn_binary_layout.md) (`.mn` binary layout 仕様、 完成済)
	参照: [`analysis_m_data_structure.md`](analysis_m_data_structure.md) (`.m` 解析 v3 完了)
	状態: draft 進行中 (§0-§2 完成、 §3 以降は段階的に追記)

---

## 0. 位置付け

### 0-1. なぜ PPZ → ADPCM-A 翻訳テンプレートを採るか

PMDNEO の ADPCM-A 6ch 駆動部分は、 PMD V4.8s 公式の **PPZ8 拡張機構**を
read-only 参照テンプレートとして書き換える形で実装する。 この戦略の
合理性:

1. **PPZ8 = OPNA 外部 PCM 4-8 ch / ADPCM-A = OPNB 内蔵 PCM 6 ch** という
   構造的類似 — どちらも「FM/SSG の主要 chip に対して、 別経路の任意
   PCM 音源を複数 ch 追加」 する役割で、 part 単位 dispatch、 sample
   番号と part の対応、 volume / pan / frequency 制御モデルが直接対応
2. **既存実装が完成形** — PMDPPZ.ASM (16 行) + PPZDRV.ASM (865 行) +
   PMD.ASM 内 `if ppz` 29 箇所が動作実証済の build 構造
3. **C# port も揃っている** — PMDDotNET の PPZDRV.cs (1135 行) +
   PPZ8em.cs (535 行) + PPZChannelWork.cs (30 行) が読み解き済の状態で
   read-only 参照可能
4. **`.mn` binary layout が PPZ8 と独立** — `.mn` は PPZ8 sub-part 拡張
   ではなく後方拡張 part 流儀を採るため、 翻訳時に「.mz の binary
   ロード経路」 は無視できる、 純粋に driver 内部構造のみ翻訳すれば良い

### 0-2. PMD ファミリ「未対応 cmd スルー」 思想の継承

設計書 1 §1 でも触れた通り、 PMD ファミリ全体 (PMD / PMDB2 / PMDPPZ /
PMD86) は **「対応していない data を読んでも暴走せず、 対応範囲だけ
通す」** 設計思想で互換性を担保している。 PMDNEO もこの思想を継承する:

- driver は知らない opcode を踏んでも si pointer を正しく進めて引数 byte
  を消費し、 chip 書込は出さない
- K/R 内蔵 rhythm cmd (rhykey / rhyvs / rpnset / rmsvs / rmsvs_sft /
  rhyvs_sft / pdrswitch) は no-op stub として実装、 引数 byte 数は
  analysis_m_data_structure.md §4-7-8 で確定済
- ADPCM-A 6ch を持たない PMD/PMDB2/PMDPPZ の駆動 cmd を将来 PMDNEO 上で
  踏んでも暴走しないよう、 対応範囲外は同じ思想でスルー

これにより既存 OPNA `.m`/`.m2` の楽曲資産が PMDNEO driver 上で安全に
再生される (FM/SSG/ADPCM-B 鳴る、 K/R 部分のみ無音)。

---

## 1. 翻訳の総原則

### 1-1. PPZ8 4-8 ch → ADPCM-A 6 ch の対応

| 項目 | PPZ8 (PMDPPZ) | ADPCM-A (PMDNEO) |
|---|---|---|
| chip | 外付け PCM 専用 chip (PC-9801-86 等) | YM2610/B 内蔵 ADPCM-A 機構 |
| channel 数 | 4-8 ch (build flag で可変) | **固定 6 ch** |
| sample 周波数 | 任意 (32bit `srcFrequency` で指定) | **固定 18.5 kHz** |
| sample format | 4bit ADPCM (PVI 圧縮) / PCM 展開済 (PZI) | 4bit ADPCM-A 専用 format |
| volume | 0-15 (chip 側で減衰) | 0-31 (register 0x08-0x0D 下位 5 bit) |
| pan | 0-9 (連続) | 4 値 (LR ともに on/off の 2x2) |
| Loop | 任意 loop point 設定可 (opcode 0x0E) | **loop なし**(one-shot 専用) |
| sample table | 外部 `.PZI` file | 外部 `.PNE` file (`.mn` 末尾に filename embed) |
| chip 駆動経路 | INT 7fh (TSR の resident driver 呼出) | Z80 直接 register 書込 |
| MML letter | Part J を sub-part 化 (`#PCMEF` で E,F... extend) | **Part L/M/N/O/P/Q を独立 part 化** |
| dispatch table | cmdtblz (PPZDRV.ASM 内) | cmdtbla (新設、 ADPCMA_DRV.ASM 内、 §6 で確定) |

### 1-2. INT 7fh 間接呼出 → Z80 直接 call への書換指針

PMD V4.8s は PC-98 環境で **PPZ8 driver (= PPZ8.COM) が TSR として常駐**
している前提で、 PMD 本体は INT 7fh 経由で常駐 driver を呼び出す:

```asm
; PPZ8 chip 駆動の典型 pattern (PMD.ASM L252):
ppz8_call:
    cmp   [ppz_call_seg], 0    ; segment valid check
    jz    not_ppz_call
    int   ppz_vec               ; → PPZ8 resident driver (INT 7fh)
not_ppz_call:
```

NEOGEO Z80 環境ではこの間接呼出を採れない (= TSR 機構なし、 INT vector
は Z80 IRQ vector で別目的)。 PMDNEO では **PPZ8 driver 機能を本体に
直接組み込む**:

```asm
; PMDNEO の対応する pattern:
adpcma_call:
    ld    a, opcode
    ; 引数を register に積む
    call  adpcma_driver_dispatch   ; 同一 binary 内の Z80 直接 call
```

関数呼出規約 (= どの register を opcode/引数に使うか) は §3-4 で確定。

### 1-3. 4-8 ch → 6 ch 削減ルール

PPZ8 の part10a〜part10h (= 8 個の per-channel workarea) を ADPCM-A の
part10a〜part10f (= 6 個) に縮約。 part10a-f を ADPCM-A ch 0-5 (=
新規 letter L/M/N/O/P/Q) に直結させる:

| PPZ8 part | PMDNEO part | letter | ADPCM-A ch |
|---|---|---|---|
| part10a | part10a | L | 0 |
| part10b | part10b | M | 1 |
| part10c | part10c | N | 2 |
| part10d | part10d | O | 3 |
| part10e | part10e | P | 4 |
| part10f | part10f | Q | 5 |
| part10g | (削除) | — | — |
| part10h | (削除) | — | — |

PPZ8 の上位 2 ch (part10g/h) に当たる routine は削除。 ループ count や
mask register 等で「8 ch 前提」 のリテラル (= 8) は「6」 に置換する。

### 1-4. 翻訳粒度の原則

PMD.ASM 内 `if ppz` 全 29 箇所 (§2 で網羅)、 PPZDRV.ASM 全 routine
(§3 で棚卸) を:

- **rename only**: literal `ppz` → `adpcma`、 `ppz_voldown` → `adpcma_voldown` 等の単純置換
- **redesign**: 内容書換 (chip 駆動 / channel 数 / mode 切替)
- **削除**: PPZ8 specific の機能で ADPCM-A に該当なし

の 3 種に分類する。 削除したものは「PMD ファミリ未対応 cmd スルー」 思想
で driver 側で no-op 化 (= 引数だけ消費して ret) する場合と、 完全に
省く場合がある (詳細は §3 で確定)。

---

## 2. PMD.ASM 内 `if ppz` 全 29 箇所の翻訳指針

実体調査の結果、 PMD.ASM 内の行頭 `if ppz` / `ifndef ppz` は全 **29 箇所**。 plan agent の予測 35 箇所より少なかった (= 推定が組合せ条件 `if board2*ppz` 等を含めていた)。

### 2-1. 全 29 箇所の役割分類表

| 行 | 役割 | 翻訳分類 |
|---|---|---|
| L36 | flag 既定値 `ppz=0` (未定義時) | **rename only**: `adpcma=0` に翻訳 |
| L252 | `_ppz` macro 本体 (INT 7fh 経由 far call) | **redesign**: Z80 直接 call へ書換、 §1-2 参照 |
| L475 | PPZ8 初期化 (INT 7fh × 3) | **redesign**: YM2610/B ADPCM-A 初期化に書換 |
| L703 | voldown コピー (`[_ppz_voldown]` → `[ppz_voldown]`) | **rename only**: `adpcma_voldown` |
| L967 | 8ch sequence 駆動 (`ppzmain` × 8 ch loop) | **redesign**: 6ch (part10a-f) loop に縮約 |
| L1732 | command 実行後の `_ppz` IRQ 呼出 | **redesign**: L252 と連動、 IRQ 呼出を直接 call に |
| L6907 | melody on (-1 のとき 6 byte skip = PPZ parts 用) | **redesign**: ADPCM-A 6 part 対応 skip 量に変更 |
| L6940 | melody off (同上) | **redesign**: L6907 と連動 |
| L6970 | part mask 上限 (`if ppz: 16+8 / else: 16`) | **redesign**: `16+6` に変更 (ADPCM-A 6 ch 分) |
| L7016 | part mask check (`ppz` の場合 `dec ah; jz pm_ppz`) | **redesign**: L7085 と連動 |
| L7085 | `pm_ppz` (PPZ part mask + ademu 分岐) | **redesign**: `pm_adpcma` (ADPCM-A part mask) に書換、 ademu 分岐は削除 |
| L7471 | `ppzint` コメント (= 全部 commented out) | **削除** |
| L7495 | `int5_flag` check コメント (= commented out) | **削除** |
| L7513 | mask check コメント (= commented out) | **削除** |
| L7614 | maskreset check コメント (= commented out) | **削除** |
| L8306 | part10a-h offset table (8 entry) | **redesign**: part10a-f (6 entry) に縮約 |
| L8340 | part10a-h workarea 確保 (8 part 分) | **redesign**: part10a-f (6 part 分) に縮約 |
| L9005 | `ppz8_check` call + INT 7fh 経由 init | **redesign**: ADPCM-A 初期化 routine に書換 (L475 と連動) |
| L9106 | `ppz8_check` 実装 | **redesign**: ADPCM-A は内蔵機構なので presence check 不要 (= 常に true) |
| L9548 | print PPZ8 voldown message | **redesign**: print ADPCM-A voldown |
| L9642 | print PPZ8 使用判定 message | **redesign**: print ADPCM-A 使用判定 (常に有効) |
| L9799 | `ppz8_check` + 常駐削除 (driver 終了処理) | **redesign**: ADPCM-A driver 終了処理 (NEOGEO では何もしない) |
| L10165 | `pushf/cli` (= 周辺 IRQ 同期) | **redesign**: NEOGEO Z80 環境の IRQ 同期に書換 |
| L10173 | `ppz8_check` + FIFO interrupt 停止 | **redesign**: ADPCM-A interrupt 停止 routine |
| L10201 | `ppz8_check` + INT 7fh init (再) | **redesign**: L9005 と連動 |
| L10591 | message "PPZ8(INT7FH) 対応" | **redesign**: "ADPCM-A 対応" message |
| L10654 | message "/DZn PPZ8 voldown 設定" | **redesign**: "/DAn ADPCM-A voldown" 等 |
| L10675 | message "/Z(-) PPZ8 対応有無" | **redesign**: "/A(-) ADPCM-A 対応有無" |
| L10702 | `changemes_3z` = "PPZ8 voldown" | **redesign**: `changemes_3a` |

### 2-2. 翻訳分類の集計

| 分類 | 箇所数 | 主要作業 |
|---|---|---|
| rename only | 2 (L36, L703) | trivial、 grep + sed 一括置換 |
| 削除 | 4 (L7471, L7495, L7513, L7614) | 全部 commented-out コードのため除去 |
| redesign | 23 | 内容書換、 Z80 化、 6ch 縮約、 message 書換 |
| **合計** | **29** | |

redesign 23 箇所のうち、 大半は **同じ pattern の繰り返し**:

- **chip 駆動経路の置換**(INT 7fh → Z80 直接 call): L252, L475, L1732, L9005, L10173, L10201 — 共通の Z80 直接 call wrapper を 1 つ作れば連動して解決
- **8ch → 6ch 縮約**: L967, L8306, L8340, L6970 — `cx, 8` → `cx, 6` 等の literal 書換
- **message 書換**: L9548, L9642, L9799, L10591, L10654, L10675, L10702 — text のみ書換、 ロジック影響なし

実質的に **新たに redesign する独立作業は 7-8 箇所**程度。 残りは pattern の繰り返し or message 書換。

### 2-3. 代表的な翻訳例

#### L252 (`_ppz` macro 本体)

```asm
; 翻訳前 (PMD V4.8s)
if ppz
    cmp  [ppz_call_seg], 2
    jc   exit
    call dword ptr [ppz_call_ofs]
exit:
endif
```

```asm
; 翻訳後 (PMDNEO Z80)
if adpcma
    ; segment 不要 (= 同一 binary 内)、 直接 call
    call adpcma_dispatch
endif
```

#### L967 (8ch sequence 駆動)

```asm
; 翻訳前 (PMD V4.8s、 8ch loop)
if ppz
    mov   di, offset part10a
    mov   [partb], 0
    call  ppzmain
    mov   di, offset part10b
    mov   [partb], 1
    call  ppzmain
    ; ... part10c〜part10h まで 8 回繰り返し
endif
```

```asm
; 翻訳後 (PMDNEO Z80、 6ch loop)
if adpcma
    ld    ix, part10a
    ld    a, 0
    ld    [partb], a
    call  adpcma_main
    ld    ix, part10b
    ld    a, 1
    ld    [partb], a
    call  adpcma_main
    ; ... part10c〜part10f まで 6 回繰り返し (8ch から 2ch 削減)
endif
```

(Z80 では di → ix に置換、 mov → ld、 register 規約は §3-4 で確定)

#### L7085 (`pm_ppz` part mask)

```asm
; 翻訳前 (PMD V4.8s)
if ppz
pm_ppz:
if ademu
    cmp  al, 7
    jnz  pmppz_exec
    cmp  [adpcm_emulate], 1
    ; ...(ADPCM emulate mode 分岐)
endif
pmppz_exec:
    ; ...(PPZ part mask 処理)
endif
```

```asm
; 翻訳後 (PMDNEO Z80、 ademu 削除)
if adpcma
pm_adpcma:
    ; (ademu 分岐は完全削除、 ADPCM-A は emulation 不要)
    ; (ADPCM-A part mask 処理、 6ch 対応)
    ; ...
endif
```

(ademu = ADPCM emulation mode は PMD V4.8s で PPZ8 を ADPCM RAM の代わり
に使う際の特殊機能。 PMDNEO は ADPCM-A と ADPCM-B が独立の chip 機構
として存在するため、 emulation mode は不要 → 完全削除)

---

---

## 3. PPZDRV.ASM 865 行 → ADPCMA_DRV.ASM 翻訳マッピング

PPZDRV.ASM 内の全 label は **76 個** (主要 entry point + 内部 sub-label)。
主要 entry point は **約 20 個**で、 これを ADPCMA_DRV.ASM の対応 routine
に翻訳する。 残り内部 sub-label は内部実装の詳細なので、 翻訳時には
連動して書き換える。

### 3-1. 主要 entry point の対応表

| PPZ8 (PPZDRV.ASM) | 行 | ADPCM-A (ADPCMA_DRV.ASM) | 翻訳種別 | 備考 |
|---|---|---|---|---|
| `ppz8_call` | L4 | `adpcma_call` | redesign | INT 7fh → Z80 直接 call (§1-2) |
| `ppzmain` | L14 | `adpcma_main` | redesign | per-ch sequence main loop、 6ch 化 |
| `commandsz` | L185 | `commandsa` | redesign | dispatch table 経由 |
| `cmdtblz` | L188 | `cmdtbla` | **新規 dispatch table** | §6 で確定 |
| `ppz_extpartset` | L287 | (再検討) | redesign | extend 用、 ADPCM-A は固定 6ch なので不要かも |
| `ppz_mml_part_mask` | L320 | `adpcma_mml_part_mask` | redesign | 0xC0 sub-dispatch |
| `ppzrepeat_set` | L352 | `adpcma_repeat_set` | redesign | loop/repeat |
| `ppz_voicetable_calc` | L392 | `adpcma_sampletable_calc` | redesign | sample table address 計算 (.PNE 経路) |
| `portaz` | L415 | (削除候補) | **削除 or no-op** | ADPCM-A は周波数固定、 portamento 無効 |
| `pansetz` | L475 | `adpcma_panset` | redesign | pan set (LR 2x2 値) |
| `ppz_neiro_reset` | L542 | `adpcma_voice_reset` | redesign | sample 番号変更時の reset |
| `volsetz` | L571 | `adpcma_volset` | redesign | volume set + envelope |
| `keyonz` | L699 | `adpcma_keyon` | redesign | register 0x00 への keyon write |
| `keyoffz` | L720 | `adpcma_keyoff` | redesign | register 0x00 への keyoff write |
| `otodasiz` | L735 | (簡略化) | redesign | ADPCM-A は frequency 固定、 出音は keyon のみで足る |
| `fnumsetz` | L801 | (削除 or 簡略化) | **削除 or 簡略化** | note → frequency 変換、 ADPCM-A 固定 18.5kHz では不要 |

### 3-2. 翻訳種別の集計

| 種別 | 個数 | 主要作業 |
|---|---|---|
| redesign | 12 | 内容書換、 chip register 操作の YM2610/B 対応 |
| 新規 dispatch table | 1 (cmdtbla) | jumpN 未使用 entry の流儀で組む |
| 削除 or no-op | 3 (portaz / fnumsetz / otodasiz の一部) | ADPCM-A が PPZ8 と仕様が違う部分 |
| 再検討 | 1 (ppz_extpartset) | extend は 6ch 固定なので不要かも、 §3-3 で確定 |
| **合計** | **17** | (内部 sub-label 60 個は連動して書換) |

### 3-3. ppz_extpartset の扱い

PPZ8 では `ppz_extpartset` が **8ch 分の part workarea (part10a-h) を
初期化**する routine。 PMD.ASM 内 `if ppz` の L8340 で 8 part workarea
が確保されている前提で、 各 part の data ptr (`address[di]`) を sample
番号 + 演奏開始位置で初期化する。

PMDNEO の ADPCM-A は **固定 6ch**で、 8ch から ch 数は減るだけで構造
自体は変わらない。 ただし、 PPZ8 の `extpartset` は MML から呼び出され
る (= 楽曲ごとに 8ch 中いくつ使うかが MML 側で決まる) のに対し、
PMDNEO の ADPCM-A 6ch は **常に 6ch 全部使える**(= MML 側で extend
宣言不要)。

つまり `ppz_extpartset` の役割は PMDNEO では:

- 案 A: そのまま 6ch 版に翻訳 (`adpcma_extpartset`)、 MML から呼び出し
  可能にして「6ch 中 N ch だけ使う」 を明示できるようにする
- 案 B: 削除、 ADPCM-A 6 part workarea は driver 起動時に常に初期化する
  (= MML 上で extend 宣言不要、 設計 clean)

PMDNEO の design 思想 (= 「ADPCM-A 6ch を独立 part として並べる」) に
照らすと **案 B が自然** (= L/M/N/O/P/Q letter で各 part を直接 MML
記述するため、 extend は不要)。 確定は **user judgment 6 (= ADPCM-A 用
dispatch 拡張の格納位置) と連動**して行う。

### 3-4. INT 7fh → Z80 直接 call の関数呼出規約 (user judgment 4)

PPZDRV.ASM では INT 7fh で driver を呼び出す際、 register 規約は:

```
AL: opcode (= 0x01 PlayPCM, 0x02 StopPCM, 0x07 SetVolume, 0x0B SetFreq, etc.)
DL: channel 番号 (0-7)
DX:CX: 32-bit value (frequency 等)
ES:BX: pointer 戻り値 (= sample table address)
```

NEOGEO Z80 環境ではこれを Z80 register に翻訳する必要。 Z80 の汎用
register は A / B / C / D / E / H / L / IX / IY。 候補:

#### 案 A (推奨): A = opcode、 DE = arg1 (16-bit)、 BC = arg2 (16-bit)、 HL = pointer 戻り値

```asm
; 翻訳例: PlayPCM (PPZ8 opcode 0x01)
ld   a, ADPCMA_OP_PLAY    ; opcode
ld   d, ch                ; channel
ld   e, sample_num        ; sample 番号 (2 byte で 1 引数表現)
call adpcma_dispatch
```

利点:
- A = opcode は Z80 の自然な選択 (jump table index に直結)
- DE = arg1 / BC = arg2 で 16-bit 引数 2 個まで取れる
- HL = 戻り値 ptr で memcpy 系操作に直結

#### 案 B: B = opcode、 DE/HL = 引数

A レジスタは演算で頻繁に潰れるため、 opcode を保持する register として
不適という主張もあり得るが、 dispatch 直後に jump table を引くなら A
を使う方が短い code になる。

#### 案 C: stack 渡し

PMD V4.8s と完全に異なる呼出規約。 push/pop が必要で code 量増える。

### 3-5. 8ch → 6ch 縮約の具体ルール (user judgment 5)

PPZ8 の part10a〜part10h (= 8 個) を ADPCM-A の part10a〜part10f (= 6 個)
に縮約。 ch index と letter の対応:

#### 案 A (推奨): part10a-f を素直に L-Q に対応、 part10g/h は完全削除

| PPZ8 part | PMDNEO part | letter | ADPCM-A ch |
|---|---|---|---|
| part10a | part10a | L | 0 |
| part10b | part10b | M | 1 |
| part10c | part10c | N | 2 |
| part10d | part10d | O | 3 |
| part10e | part10e | P | 4 |
| part10f | part10f | Q | 5 |
| part10g | (削除) | — | — |
| part10h | (削除) | — | — |

利点:
- workarea 配置が PPZ8 と最大互換 (= part10a-f の Z80 RAM offset が
  PPZ8 と一致するので、 翻訳時の register/offset 計算が簡単)
- ADPCM-A は ch 0-5 を register address 0x08-0x0D / 0x10-0x15 / 0x20-0x2D
  で直接駆動 (chip 仕様)

#### 案 B: part10a-c, part10e-g を残し、 part10d/h を削除

複雑、 採用理由なし。 案 A 一択。

---

## 4. PMDDotNET 翻訳対応 (Phase 3 mc compiler 改良の準備)

PMDDotNET の C# port は、 Phase 3 で mc compiler を `.mn` 出力対応に
改造する際の **read-only 参照テンプレート**。 既存 OPNA `.m` 出力経路
は無改造で温存し、 `.mn` 出力経路を別実装で追加する流儀で進める。

### 4-1. PPZChannelWork.cs (30 行) → ADPCMAChannelWork.cs

PPZ8 channel state 17 field を ADPCM-A 6ch 用に書き換え。

| PPZ8 field | type | PMDNEO 翻訳 | type | 用途 |
|---|---|---|---|---|
| `loopStartOffset` | int | (削除) | — | ADPCM-A loop 不可 |
| `loopEndOffset` | int | (削除) | — | 同上 |
| `playing` | bool | `playing` | bool | 再生中 flag |
| `pan` | ushort | `pan` | byte | LR 2x2 値 (0/1/2/3) |
| `panL` | double | (削除) | — | ADPCM-A は離散値、 連続 panL 不要 |
| `panR` | double | (削除) | — | 同上 |
| `srcFrequency` | uint | (削除) | — | ADPCM-A 固定 18.5 kHz |
| `volume` | ushort | `volume` | byte | 0-31 (register 下位 5 bit) |
| `frequency` | uint | (削除) | — | 固定 18.5 kHz |
| `_loopStartOffset` | int | (削除) | — | |
| `_loopEndOffset` | int | (削除) | — | |
| `_srcFrequency` | uint | (削除) | — | |
| `bank` | int | `bank` | byte | sample bank 番号 (.PNE 経由) |
| `ptr` | int | (削除) | — | chip 内部で管理 |
| `end` | int | (削除) | — | 同上 |
| `delta` | double | (削除) | — | 同上 |
| `num` | int | `sampleNum` | byte | sample 番号 (chip register 0x10〜) |

PMDNEO の ADPCM-A channel state は **大幅に簡略化** (17 field → 5
field)。 ADPCM-A chip 内部で再生位置 / loop / 周波数を管理するため、
driver 側の per-channel state は最小限で済む。

### 4-2. PPZDRV.cs (1135 行) → ADPCMA_DRV.cs

PMDDotNET の PPZDRV.cs は OPNA driver (PMD.cs) と直接統合 (= INT を
介さない C# method 呼出)。 PMDNEO 用 ADPCMA_DRV.cs も同様の流儀で
PMD.cs に統合する。

| PPZ8 method | role | ADPCM-A 翻訳 | 簡略化 |
|---|---|---|---|
| `ppzmain()` | main loop | `adpcmaMain()` | 6ch loop |
| `init()` | cmdtblz setup | `init()` | cmdtbla setup |
| `ppz_extpartset()` | extend init | (削除) | 6ch 固定で不要 |
| `ppzmain_c_1()` | length/keyoff | `adpcmaMain_c_1()` | 同等 |
| `mp1z()` | data read + cmd | `mp1a()` | 同等 |
| `fnumsetz()` | F-number | (削除 or 簡略化) | 固定周波数 |
| `volsetz()` | volume out | `volseta()` | register 0x08-0x0D |
| `otodasiz()` | freq out | (削除) | 固定 |
| `keyonz()` | keyon | `keyona()` | register 0x00 |
| `keyoffz()` | keyoff | `keyoffa()` | register 0x00 |
| `comAtz()` | @cmd | `comAta()` | sample 番号 + 関連 reset |
| `pansetz()` | pan | `panseta()` | 4 値 LR mapping |
| `portaz()` | porta | (削除) | 周波数固定 |
| `ppzrepeat_set()` | loop | `repeat_seta()` | dispatch 経由の loop |

### 4-3. PPZ8em.cs (535 行) → ADPCMA_em.cs

PMDDotNET は PMD ファミリの C# **エミュレータ**で、 chip emulator
(PPZ8em.cs) は実機 register / sampling routine を C# で再現している。
PMDNEO 用 ADPCMA_em.cs は **YM2610/B ADPCM-A 機構をエミュレート**する。

ただし、 NEOGEO の MAME や Web の YM2610 emulator が既に存在するため、
**ADPCMA_em.cs は新規 emulator として作る必要が薄い**(= MAME の YM2610
を Web に移植する選択肢もあり)。 ADPCMA_em.cs の役割は限定的で、
mc compiler の test / preview 用途のみ。

具体的な実装方針は Phase 3 / Phase 4 で再検討 (= WebApp の chip emulator
選定と一体)。

---

---

## 5. chip 駆動 opcode → YM2610/B ADPCM-A register mapping

### 5-1. YM2610/B ADPCM-A register layout (chip 仕様)

YM2610/B の ADPCM-A は **port B** (= 第 2 register set、 address `0x100`-`0x1FF`
帯) で操作する。 PMDNEO は YM2610B (FM 6ch + ADPCM-A 6ch + ADPCM-B 1ch +
SSG 3ch) を主対象とするが、 YM2610 (= FM 4ch、 A/D mute) でも ADPCM-A 部分は
完全互換。

| address | bit 配置 | 役割 |
|---|---|---|
| **0x00** | bit 7 = Dump、 bit 5-0 = ch flag | Master keyon/dump (write 1 to keyon、 dump bit + ch bit で keyoff) |
| **0x01** | bit 5-0 = 0-63 | Master volume (Total Level、 全 ch 共通) |
| **0x08+ch** | bit 7 = R pan、 bit 6 = L pan、 bit 4-0 = 0-31 | ch 0-5 individual volume + LR pan |
| **0x10+ch** | bit 7-0 (LSB) | ch 0-5 sample start address (256 byte unit、 LSB) |
| **0x18+ch** | bit 7-0 (MSB) | ch 0-5 sample start address (MSB) |
| **0x20+ch** | bit 7-0 (LSB) | ch 0-5 sample end address (256 byte unit、 LSB) |
| **0x28+ch** | bit 7-0 (MSB) | ch 0-5 sample end address (MSB) |

(`ch` は 0-5 の channel index)

### 5-2. PPZ8em opcode → ADPCM-A register 操作 翻訳表

| PPZ8em opcode | role | ADPCM-A 翻訳 routine | YM2610/B register 操作 |
|---|---|---|---|
| 0x00 Initialize | reset all | `adpcma_init` | `0x00 ← 0xBF` (全 ch dump)、 `0x01 ← 0x3F` (max master vol) |
| 0x01 PlayPCM | start play | `adpcma_keyon` | `0x10+ch / 0x18+ch / 0x20+ch / 0x28+ch ← start/end addr`、 `0x00 ← (1 << ch)` で keyon |
| 0x02 StopPCM | stop play | `adpcma_keyoff` | `0x00 ← 0x80 \| (1 << ch)` で dump (= keyoff 相当) |
| 0x03 LoadPcm | sample bank load | (削除) | NEOGEO V-ROM bank 経由でロード、 driver 内 routine 不要 |
| 0x04 ReadStatus | status read | (削除) | ADPCM-A 専用 status register なし、 polling は不要 |
| 0x07 SetVolume | per-ch volume | `adpcma_volset` | `0x08+ch` の bit 4-0 = volume (0-31) |
| 0x0B SetFrequency | freq set | (削除) | ADPCM-A 固定 18.5 kHz、 freq 調整不可 |
| 0x0E SetLoopPoint | loop set | (削除) | ADPCM-A loop 不可、 one-shot 専用 |
| 0x12 StopInterrupt | int stop | (no-op) | NEOGEO Z80 IRQ は YM2610 TIMER-B 経由で別処理 |
| 0x13 SetPan | pan set | `adpcma_panset` | `0x08+ch` の bit 6-7 で LR (LR=00 mute、 LR=01 R only、 LR=10 L only、 LR=11 stereo) |
| 0x15 SetSrcFrequency | src freq | (削除) | 固定 18.5 kHz |
| 0x16 SetAllVolume | all vol | `adpcma_allvolset` | `0x01` で master vol |
| 0x18 SetAdpcmEmu | emulate | (削除) | PMDNEO 不要 (= ADPCM RAM 機構との emulation 切替なし) |
| 0x19 SetReleaseFlag | release flag | (no-op) | NEOGEO 不要 |

### 5-3. 主要 routine の Z80 source skeleton

#### `adpcma_init` (driver 起動時に 1 回)

```asm
adpcma_init:
    ; YM2610/B port B address は 0x06 (status) / 0x07 (data)
    ; ※ NEOGEO Z80 では YM2610 access port は 0x04/0x05 (port A) / 0x06/0x07 (port B)
    ld    de, 0x00BF        ; D = register 0x00、 E = 0xBF (all ch dump)
    call  ym_write_b
    ld    de, 0x013F        ; D = register 0x01、 E = 0x3F (max master vol)
    call  ym_write_b
    ret

ym_write_b:
    ; D = register address (port B)
    ; E = data
    ld    a, d
    out   (0x06), a
    ; chip register write 後 wait (YM2610 仕様: 17 master cycles)
    ; ... wait routine ...
    ld    a, e
    out   (0x07), a
    ; data write 後 wait (83 master cycles)
    ; ... wait routine ...
    ret
```

#### `adpcma_keyon` (sample 番号 + ch を指定して再生開始)

```asm
adpcma_keyon:
    ; A = ch (0-5)
    ; DE = sample table entry pointer (.PNE 内 sample header)
    ; sample header format (.PNE 内): start_addr (4 byte) + end_addr (4 byte)

    push  af
    push  de

    ; ★ start address LSB (register 0x10 + ch)
    ld    a, 0x10
    add   a, c              ; C = ch (引数規約 §3-4 で確定: A = opcode、 BC = arg2)
    ld    d, a
    ld    a, (de)           ; sample header byte 0 = start LSB
    ld    e, a
    call  ym_write_b

    ; (start MSB / end LSB / end MSB を同様に書込)
    ; ...

    ; ★ keyon (register 0x00)
    ld    d, 0x00
    ld    a, 1
    sla   a, c              ; (1 << ch) を作る
    ld    e, a
    call  ym_write_b

    pop   de
    pop   af
    ret
```

(skeleton。 wait routine の挿入、 register 引数規約は §3-4 確定値、 詳細は
設計書 3 で driver 全体の中で確定)

#### `adpcma_keyoff`

```asm
adpcma_keyoff:
    ; A = ch (0-5)
    ld    d, 0x00
    ld    a, 1
    sla   a, c
    or    a, 0x80           ; dump bit
    ld    e, a
    call  ym_write_b
    ret
```

#### `adpcma_volset`

```asm
adpcma_volset:
    ; A = ch (0-5)
    ; B = volume (0-31)
    ; C = pan (0-3)、 bit 0 = R、 bit 1 = L

    ld    a, 0x08
    add   a, c              ; ch
    ld    d, a              ; D = register 0x08+ch

    ld    a, b              ; A = volume
    and   0x1F              ; bit 4-0 のみ
    ld    e, a              ; E = volume の base

    ld    a, c              ; A = pan (0-3)
    sla   a
    sla   a
    sla   a
    sla   a
    sla   a
    sla   a                 ; pan を bit 6-7 にシフト
    or    e
    ld    e, a              ; E = volume + pan
    call  ym_write_b
    ret
```

### 5-4. 削除した PPZ8 機能の取扱い (PMD ファミリ「未対応 cmd スルー」 思想)

PPZ8 specific の機能のうち ADPCM-A に該当しないもの (loop / 任意 freq /
emulate 等) は **driver 側で no-op** とする。 dispatch table の該当 entry は:

- `cmdtbla` (新設) では「ADPCM-A で意味のある opcode のみ」 を含める
- 既存 `cmdtbl` (FM 用) / `cmdtblp` (SSG 用) / `cmdtblr` (rhythm 用) には
  ADPCM-A 用 cmd は含まれない (= 通常 part が ADPCM-A 用 cmd を踏むこと
  はない、 構造上の整合性で防がれる)

つまり「ADPCM-A 専用 cmd を MML 上で書くと L-Q part でのみ有効、 通常
part (A-K) で書いても dispatch table 上で出会わないので chip 書込は出ない」
という構造で、 PMD ファミリ「未対応 cmd スルー」 思想を守る。

### 5-5. Loop / SrcFrequency 削除の代替手段 (user judgment 7)

PPZ8 の `0x0E SetLoopPoint` / `0x15 SetSrcFrequency` は ADPCM-A では
chip 仕様上不可能。 代替手段の選択肢:

#### 案 A (推奨): 完全 no-op、 `.PNE` 生成側でループ展開 / リサンプリング

- driver 内に loop / freq routine を一切持たない
- WebApp の `.PNE` 生成時に WAV → ADPCM-A 変換段階で:
  - ループ希望のサンプルは「ループ部分を repeat した展開済 sample」 として PNE に焼く
  - 周波数調整は 18.5 kHz への resampling で対応
- 利点: driver 実装が clean、 chip register 操作の制限を完全に守る
- 欠点: `.PNE` ファイルサイズが loop 展開分膨らむ

#### 案 B: driver で疑似ループ (= sample end 到達時に再 keyon)

- driver が ADPCM-A の sample end 到達 status を polling し、 keyon を
  再発行
- 欠点: chip status polling 負荷、 polling timing の精度問題、 sample 切れ
  目で短い無音

案 A の方が PMDNEO の design 思想 (= chip 仕様を素直に使う) に整合。

---

## 6. part letter 割当 (L/M/N/O/P/Q) と dispatch entry 拡張

### 6-1. dispatch table の選択 (user judgment 6)

ADPCM-A 6 part が踏む opcode の dispatch table を設計する。 既存 `.m`
の cmdtbl / cmdtblp / cmdtblr は FM/PCM / SSG / Rhythm 用で、 各 79 entry
で構成 (analysis_m_data_structure.md §4 参照)。 ADPCM-A 用は:

#### 案 A (推奨): 新規 dispatch table `cmdtbla` を新設

- ADPCM-A 専用 dispatch table を別途作る
- entry 数は 79 (= 既存と同じ opcode 帯 0xB1-0xFF) もしくは ADPCM-A で
  必要な範囲のみ
- driver は part 番号 11-16 (= L-Q) のとき `cmdtbla` を使う

利点:
- 構造 clean、 ADPCM-A 専用 cmd の追加が容易
- 既存 cmdtbl/cmdtblp/cmdtblr に手を入れない (互換性温存)

#### 案 B: 既存 cmdtbl の jump1 未使用 entry を上書き

- cmdtbl の `jump1` (= 引数 1 byte skip プレースホルダ) を ADPCM-A 用
  cmd で上書き
- 1 つの dispatch table を全 part で共通使用

欠点:
- 既存 OPNA `.m` を PMDNEO で再生する際、 該当 jump1 entry の意味が変わる
- 互換性破壊 risk

案 A が clean。

### 6-2. ADPCM-A part workarea の配置 (user judgment 8)

PMDNEO driver の Z80 RAM workarea で ADPCM-A 6 part の workarea を:

#### 案 A (推奨): OPNA layout 後方拡張領域に直接配置

driver workarea の memory layout:

```
+-----------------------------+
| FM 6 part (A-F)             | base + 0..5
+-----------------------------+
| SSG 3 part (G-I)            | base + 6..8
+-----------------------------+
| ADPCM-B 1 part (J)          | base + 9
+-----------------------------+
| Rhythm 1 part (K=R)         | base + 10 (no-op、 size 縮小可)
+-----------------------------+
| ADPCM-A 6 part (L-Q)        | base + 11..16  ← OPNA 拡張
+-----------------------------+
```

利点:
- OPNA driver の workarea 後方に素直に追加するだけ
- driver の dispatch routine が `partb` (part 番号) を見て一様に処理可能
- per-part workarea size が共通 N byte なら計算が単純 (`base + partb * N`)

#### 案 B: ADPCM-A 用 workarea を別 segment に分ける

利点なし、 dispatch routine の分岐が増える。 採用しない。

### 6-3. part 番号 → workarea offset 対応表

| part 番号 | letter | 音源 | workarea offset (base + N×idx) |
|---|---|---|---|
| 0 | A | FM 1 | +0 |
| 1 | B | FM 2 | +N |
| 2 | C | FM 3 | +2N |
| 3 | D | FM 4 | +3N |
| 4 | E | FM 5 | +4N |
| 5 | F | FM 6 | +5N |
| 6 | G | SSG 1 | +6N |
| 7 | H | SSG 2 | +7N |
| 8 | I | SSG 3 | +8N |
| 9 | J | ADPCM-B | +9N |
| 10 | R (=K) | Rhythm | +10N |
| 11 | L | ADPCM-A 1 | +11N |
| 12 | M | ADPCM-A 2 | +12N |
| 13 | N | ADPCM-A 3 | +13N |
| 14 | O | ADPCM-A 4 | +14N |
| 15 | P | ADPCM-A 5 | +15N |
| 16 | Q | ADPCM-A 6 | +16N |

`N` (= per-part workarea サイズ) は設計書 3 で確定。 K/R workarea
サイズは user judgment 11 (= OPNA 完全互換 / アドレス計算のみ整合) で
決定。

---

## 7. K/R workarea no-op 化と ADPCM-A workarea 後方追加の関係

K/R part (part 番号 10) は OPNA layout 通り workarea を確保する。 ただし:

- chip 駆動 routine は no-op stub (引数 byte 数だけ消費 + ret)
- workarea size は Phase 2 で確定 (user judgment 11) — OPNA 完全互換で
  N byte 確保するか、 ADPCM-A part と同じ N byte で揃えるか

ADPCM-A part (L-Q) の workarea は K/R workarea **の後ろ**に配置する
(§6-3 表参照)。 OPNA `.m` を PMDNEO で再生するとき、 ADPCM-A part の
workarea は touch されない (= empty marker 0x80 を踏んで idle)。

`.mn` を再生するときは、 driver が `.mn` header の extended_data_adr を
読んで ADPCM-A 6 part の MML body 開始位置を知り、 各 part を通常 part
と同じ dispatch ループで駆動する。

---

## 8. 検証計画

### 8-1. PMD.ASM 翻訳指針の照合 (Phase 2 driver 実装中)

- 全 29 箇所の翻訳が表通り行われたか (= grep + sed 一括 + 手動 check)
- 4 箇所の commented-out 行が削除されたか
- redesign 23 箇所のうち、 INT 7fh → Z80 直接 call 置換が 6 箇所に集約
  されたか (= 共通 wrapper 1 つで対応)

### 8-2. PPZDRV.ASM 翻訳指針の照合

- 主要 entry point 17 個の対応 routine が ADPCMA_DRV.ASM に存在
- portaz / fnumsetz / otodasiz の削除 or 簡略化が確認された
- ppz_extpartset が削除された (= 6ch 固定で extend 不要)

### 8-3. chip 駆動の audio gate 検証

設計書 3 の audio gate Step 3 (= ADPCM-B 1ch) と Step 5 (= 統合) の
間に追加の Step として:

- Step 3.5: ADPCM-A 1 ch (Part L のみ) で音が出るか
- Step 4.5: ADPCM-A 6 ch 全部使った楽曲で全 ch 鳴るか

これは設計書 3 で詳細化する。

---

## 9. 残課題

1. ADPCM-B 1ch の register mapping は本書では扱わない (= Phase 2 の
   ベースライン driver で実装、 設計書 3 §4 で詳細化)
2. cmdtbla (新規 ADPCM-A 用 dispatch table) の具体 entry 一覧は設計書 3
   で確定 (= ADPCM-A 用 cmd の opcode 番号割当)
3. `.PNE` 内 sample header format の詳細 (= start_addr / end_addr の
   byte 順序、 instrument table 構造) は設計書 3 で扱う (= mc compiler
   / ROM builder と一体)
4. YM2610 register write の wait routine の cycle 数決定 (= 17 master
   cycles / 83 master cycles の Z80 cycle 換算) は設計書 3 で確定

---

[draft v0.3 — §0-§9 完成。 user judgment 4-8 全て解決済]
