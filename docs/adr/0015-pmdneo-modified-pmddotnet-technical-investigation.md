# ADR-0015: PMDDotNET 改造 技術調査 sprint — 改造 PMDNEO.ASM 設計のための作業計画

- 状態: Accepted (= 軸 1 + 軸 2 + 軸 3 + 軸 4 + 軸 5 全件完了、 ADR-0016 起票準備完了)
- 起票日: 2026-05-11
- 軸 1 完了日: 2026-05-12
- 軸 2 完了日: 2026-05-12 (= develop 資産 で実装済の確認、 ADR-0015 起票時の前提見直し含む)
- 軸 3 完了日: 2026-05-12 (= ADR-0017 §決定 3 方針で develop 資産前提 redefine、 ADPCM-A/B + OPNA register access 整理)
- 軸 4 完了日: 2026-05-12 (= ADR-0017 §決定 3 方針で develop 資産前提 redefine、 mc compiler 改造箇所 185-360 行 + 設計判断 4 件確定)
- 軸 5 完了日: 2026-05-12 (= ADR-0017 §決定 3 方針で develop 資産前提 redefine、 合計 335-660 行 + 着手順序 (B) mc compiler 先 + 5 step 段階的検証経路 確定)
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0013 (= 同 .M 2 経路比較 路線へ切替)、 ADR-0014 (= ADR-0006 sprint 成果のカテゴリ別判断 + PMDPPZ 流儀発見)

## 背景

ADR-0013/0014 で次の路線が確定した:

- 検証経路: 同 .M (= 同一 MD5) 2 経路比較
- PMDNEO 本体 driver: PMD V4.8s 公式 driver (= `vendor/pmd48s/source/pmd48s/PMD.ASM`、 10864 行) を改造、 PMDPPZ 流儀で wrapper file + 条件 assemble 拡張
- 改造規模見込み: 推定 100-150 件 if 分岐 + wrapper file 1 つ = 元の 5-10% 修正
- mc compiler 側も OPNB 出力対応に改造 (= `vendor/PMDDotNET/PMDDotNETConsole`)

ただし「どこに if 分岐を入れるか」 「NEOGEO 環境依存層は具体的にどう書くか」 「mc compiler の OPNB 出力分岐はどこに挟むか」 は未確定。 改造着手 sprint (= 想定 ADR-0016) の前にこれらを技術調査として固定する必要がある。

本 ADR は改造着手に向けた **技術調査 sprint の作業計画** を立てる。 調査結果は本 ADR 自体に段階的に追記し、 完了時に ADR-0016 起票へ移行する。

## 調査範囲 (= 5 軸)

### 軸 1: PMD.ASM 内の chip 別経路特定

**目的**: PMD V4.8s の条件 assemble 構造を把握し、 新規 `neogeo` / `opnb` flag を挿入する場所を見極める。

**作業内容**:
- PMD.ASM 内の `if board2` / `if adpcm` / `if ppz` / `if pcm` / 組合せの全 203 件を分類
- 各分岐の目的 (= 例「ppz が立っている時に PPZDRV を include」、「board2 が立っている時に OPNA register を使う」 等) を読解
- ADPCM 関連 (= adpcm flag、 OPNA 内蔵 ADPCM-B) の register write 経路を特定
- PPZ8 関連 (= ppz flag) の構造を踏襲手本として整理 (= PMDNEO の opnb flag 設計の参考)

**期待成果**: 「PMD.ASM 内の chip / 環境分岐 map」 (= 行番号 + flag + 目的の対応表)。 ADR-0015 に追記 or 別 memory 化。

### 軸 1 完了 (= 2026-05-11 着手、 2026-05-12 全件読了、 全 203 件集計 + ppz 関連 38 件全件 1 件 1 行読解)

#### 全 203 件 flag 別集計

| flag | 件数 | 意味 |
|---|---|---|
| `board2` | 90 | サウンドボード 2 (= OPNA、 PC-9801-86 等) |
| `ppz` | 35 | PPZ8 (= 8ch PCM 拡張、 **PMDPPZ 流儀の手本**) |
| `va` | 22 | VA (= VA1/VA2 機種) |
| `pcm` | 11 | 86PCM (= サウンドボード 86 内蔵 PCM) |
| `board2*adpcm` | 8 | OPNA + 内蔵 ADPCM-B 組合せ |
| `ademu` | 8 | ADPCM emulation (= 内蔵 ADPCM 無い機種用) |
| `board2*pcm` | 7 | OPNA + 86PCM 組合せ |
| `adpcm` | 6 | 内蔵 ADPCM (= 単独) |
| `vsync` | 4 | VSync 関連 timing |
| `sync` | 3 | MIDI sync |
| `pcm+ppz` | 2 | 86PCM + PPZ8 組合せ |
| 各種組合せ | 計 7 | |
| その他 (= `_myname` / `_optnam` / `resmes` / `1`) | 4 | name 系 + 突撃 mix flag |

**全部 PC-9801 環境前提**。 PMDNEO で必要なのは:
- `neogeo` flag (= 新規、 環境移植層): 推定 20-40 件
- `opnb` flag (= 新規、 chip 移植層): 推定 50-80 件
- 不使用 flag (= `va` / `pcm` / `ppz` / 関連組合せ): 計 85 件、 wrapper で立てなければ自動除外

#### PPZ8 拡張 component 別 観察点 (= 7 representative)

PPZ8 拡張 (= ppz 35 件 + 組合せ 3 件) を行範囲で俯瞰、 7 つの representative component に整理:

| # | 行範囲 | component | PMDNEO への対応案 |
|---|---|---|---|
| 1 | 250-258 | `_ppz` macro (= ppz call wrapper) | `_neogeo_main_cpu_recv` macro 等 |
| 2 | 367-369 | `if ppz / include ppzdrv.asm` | `if neogeo / include neogeo-env.asm` + `if opnb / include opnb-driver.asm` |
| 3 | 475-488 | PPZ8 driver 初期化 (= ppz_call_seg 設定 + int 呼出) | NEOGEO sound subsystem 初期化 (= main CPU command 受付 establish) |
| 4 | 703-706 | `_ppz_voldown` 変数 transfer | (= NEOGEO は単 chip、 該当部分薄い) |
| 5 | 6142-6159 | サウンド停止 routine の ppz keyoff loop | OPNB 全 ch keyoff routine (= FM + SSG + ADPCM-A + ADPCM-B) |
| 6 | 7177+ | part_table 拡張 (= PPZ1/2/3 行追加) | OPNB 用 part 配置 (= 既存 PMDDotNET 流儀踏襲、 PPZ 行削除) |
| 7 | 10164+ | /Z option (= PPZ8 CLI 接続 / 切断) | (= 不要、 NEOGEO に CLI なし) |

#### 重要な構造的違い (= PPZ8 と PMDNEO)

- **PPZ8**: 外部 driver (= PPZDRV.ASM) を **間接呼出** する wrapper 構造 (= ppz_call_seg / ppz_vec 経由)
- **PMDNEO**: 自身が driver の本体、 **OPNB register を直接 write** する構造

つまり PMDNEO の `if neogeo` / `if opnb` 分岐は、 PPZ8 流儀をそのまま踏襲できない部分がある:
- macro 化 / include 切替 / 初期化 / 停止 / part table の pattern は流用可能
- **register write 経路の OPNB 化は新規**、 PPZ8 では参考にならない。 むしろ `board2` 90 件のうち「register / port 関連部分」 (= 軸 3 で調査) の方が手本

#### 推定改造規模 (= 軸 1 結果を踏まえた更新)

| 区分 | 推定件数 | 内訳根拠 |
|---|---|---|
| macro / include / 初期化 / 停止 routine | 10-20 件 | PPZ8 流儀踏襲、 PMDPPZ で同等規模 |
| part table / cmd handler 拡張 | 15-25 件 | PPZ8 で 15-20 件、 PMDNEO 同等 |
| register write 経路の OPNB 化 | 50-80 件 | 新規、 board2 90 件のうち register 関連部分が手本 |
| NEOGEO 環境移植 | 20-40 件 | 新規、 軸 2 で具体化 |
| **合計** | **95-165 件** | ADR-0014 で立てた 100-150 件と整合 |

#### ppz 関連 38 件 全件 1 件 1 行 表 (= 軸 1 完了 時、 2026-05-12)

flag 列の `if`/`ifndef` は省略 (= 全件いずれかの conditional assemble)。 入れ子 (= 親条件) は丸括弧で記載。

| # | 行 | flag | 機能 / 役割 |
|---|---|---|---|
| 1 | 36 | `ifndef ppz` | ppz flag default 値 (= 0) 設定。 conditional assemble の入口宣言 |
| 2 | 252 | `ppz` | `_ppz` macro 本体 (= ppz_call_seg 検査 + ppz_call_ofs 経由の遠隔呼出) |
| 3 | 367 | `ppz` (`adpcm` 内側) | `include ppzdrv.asm` (= PPZ8 driver source 取込) |
| 4 | 475 | `ppz` | mstart 内 PPZ8 初期化 (= ppz_vec 経由 接続終了 + ch reset) |
| 5 | 703 | `ppz` | ボリューム調整値 転送 (= `_ppz_voldown` → `ppz_voldown`) |
| 6 | 843 | `ppz+ademu` | PPZ Pan Init (= 8 ch loop で各 ch pan を中央初期化) |
| 7 | 967 | `ppz` | mainloop 内 ppz part 8 ch (= part10a-part10h) を `ppzmain` で順次処理 |
| 8 | 1732 | `ppz` | cmd dispatch 入口で `_ppz` macro 呼出 (= jump table 直前で ppz check) |
| 9 | 6142 | `ppz` | mstop (= サウンド停止) 内 ppz keyoff loop (= 8 ch 全部 keyoff) |
| 10 | 6454 | `ppz` (`board2` 内側) | drv_chk: 構成識別 (= ppz 有無で `al_push` 値分岐 4/5) |
| 11 | 6907 | `ppz` | maskon_all 内 part_table 走査 (= `-1` 検出で Rhythm/Effect skip して PPZ ch 到達) |
| 12 | 6940 | `ppz` | maskoff_all 内 同様の part_table 走査 |
| 13 | 6970 | `ppz` | part_mask 上限 part 数 切替 (= 16+8=24 vs 16) |
| 14 | 7016 | `ppz` | part_mask: PPZ part (= AH=5) 検出 → `pm_ppz` 分岐追加 |
| 15 | 7085 | `ppz` | `pm_ppz` 本体 (= ppz8_call AH=2 で PPZ ch keyoff、 ademu 時の adpcm_emulate 例外含む) |
| 16 | 7178 | `ppz` (`board2` 内側) | part_table 拡張版 定義 (= A-K + 制御 + Effect + PPZ1-PPZ8、 計 24 行) |
| 17 | 7471 | `ppz` | PPZ8 Interrupt Routine 旧 dead code (= 全行 `;;` comment-out、 FMint 内 redirect 構想跡) |
| 18 | 7495 | `ppz` | opnint 入口 ppz 経路分岐 旧 dead code (= 全行 `;;` comment-out) |
| 19 | 7513 | `ppz` | 8259 mask 処理 ppz 分岐 旧 dead code (= 全行 `;;` comment-out) |
| 20 | 7614 | `ppz` | 8259 mask 解除 ppz 分岐 旧 dead code (= 全行 `;;` comment-out) |
| 21 | 8264 | `ppz` (`board2` 内側) | `max_part1` 定義 (= 14+8=22 vs 14、 PPZ8 ch 含む part 総数) |
| 22 | 8306 | `ppz` | `part_data_table` 拡張 (= part10a-part10h dword 8 個追加) |
| 23 | 8340 | `ppz` | `part10a` - `part10h` 領域確保 (= PPZ8 各 ch の partwork 8 個) |
| 24 | 9005 | `ppz` | `ppz8_check` 呼出 + ppz_call_ofs/seg 設定 (= 常駐 PPZ8 driver 検出 + vector 取得) |
| 25 | 9106 | `ppz` | `ppz8_check` 本体 (= INT vector 確認 = `"PPZ8"` 識別子マッチ) |
| 26 | 9250 | `pcm+ppz` (`board2` 内側) | port_check: 86B + PPZ 構成 で check_86b 直結 (= SPB 経路 skip) |
| 27 | 9548 | `ppz` | 設定表示 print: `_ppz_voldown` 値 表示 |
| 28 | 9642 | `ppz` | 設定表示 print: PPZ8 接続有無 表示 |
| 29 | 9799 | `ppz` | resident cut 処理: ppz8_check + 常駐 PPZ8 driver 解除 (= INT 1900h) |
| 30 | 10165 | `ppz` | /Z option (= ppz_reset): pushf + cli 入口 |
| 31 | 10173 | `ppz` | /Z option: PPZ8 接続検出 + FIFO IRQ 停止 + 8 ch keyoff + driver 解除 |
| 32 | 10201 | `ppz` | /Z minus option: PPZ8 接続有効化 + INT vector 設定 |
| 33 | 10549 | `pcm+ppz` (`board2` 内側) | エラーメッセージ "YM2608+PCM 見つからず" 文字列 切替 |
| 34 | 10591 | `ppz` | "PPZ8(INT7FH) 対応" メッセージ 文字列 |
| 35 | 10626 | `ppz` (`board2`/`pcm` 内側) | usage: 実行ファイル名 接尾辞「PPZ」 表示 |
| 36 | 10654 | `ppz` | usage: /DZn (= PPZ8 ボリューム調整) help line |
| 37 | 10675 | `ppz` | usage: /Z(-) (= PPZ8 対応 切替) help line |
| 38 | 10702 | `ppz` | "PPZ8 ボリューム調整値" print msg 文字列 |

#### 38 件読了で見えた追加観察点

- **dead code 4 件 (= #17-20、 7471/7495/7513/7614)** は全行 `;;` comment-out。 PPZ8 を OPN INT 内で受ける構想が試されたが採用されず、 final 仕様は `_ppz` macro を mainloop / cmd dispatch から polling 風に呼ぶ形に決着した跡。 PMDNEO では「OPN INT 経由で OPNB ADPCM 受ける」 案を検討する場合は、 この dead code が「試したが捨てた」 設計理由を遡る素材になる
- **接続検出 + vector 取得 (= #24, #25, #29, #31, #32)** は MS-DOS 常駐 driver (= INT vector への識別子書込) の作法。 NEOGEO では 68000 main CPU からの command 経由になるため **全廃**、 `if neogeo` 側で main CPU 受信 routine に置換
- **part_table 拡張 (= #11, #12, #13, #14, #16)** は PPZ8 の 8 ch 追加を mainloop / mask 処理 / dispatch まで一貫して扱う構造。 PMDNEO ではこの構造をほぼそのまま流用 (= PPZ8 を OPNB ADPCM-A 6 ch + ADPCM-B 1 ch に置換)
- **partwork 8 領域 (= #22, #23)** は PPZ8 8 ch 用の固定 8 領域確保。 PMDNEO では ADPCM-A 6 ch + ADPCM-B 1 ch = 7 領域 で良い (= 1 領域分縮小)
- **CLI option 系 (= #1, #30, #31, #32, #34, #36, #37, #38)** は MS-DOS 常駐 起動時の option 処理。 NEOGEO では **不要**、 全部削除候補

#### 軸 2/3 への引継ぎ事項

- **軸 2 (= NEOGEO 環境) で扱う**: ppz 関連 38 件のうち #24/#25/#29/#31/#32 (= 常駐 driver 接続検出 / vector 取得 / 解除) は、 NEOGEO 環境では「68000 main CPU からの command 受信」 routine に置換える具体例として参考。 ngdevkit examples 読解時に「sound subsystem 起動 + main CPU command 受付 establish」 の対応箇所を特定
- **軸 3 (= OPNB 差分) で扱う**: ppz 関連 38 件のうち part_table / partwork / part_mask 拡張系 (= #11-16, #21-23) は OPNB ADPCM-A 6 ch + ADPCM-B 1 ch を統合する part 構造設計の手本。 また `board2` 90 件のうち「register / port 関連」 部分を抽出、 OPNB register address に置換える具体候補として整理
- **軸 4 (= mc compiler) で扱う**: PPZ8 の partwork 8 領域 (= #22, #23) と OPNA 既存 part 構造 の関係を mc compiler 側で OPNB 用に再写像する必要、 OPNB 識別子 / .M format metadata 設計の前提知識

### 軸 2: NEOGEO 環境依存箇所の特定

**目的**: PC-9801 想定の環境依存層を NEOGEO 環境に置換える具体的箇所を特定。

**作業内容**:
- I/O port (= PC-9801 OPNA は port 0x188-0x18B、 NEOGEO YM2610 は port 0x04-0x05 / 0x06-0x07) の差分整理
- IRQ (= PC-9801 vsync IRQ / timer IRQ、 NEOGEO は別 vector + timing) の差分整理
- memory map (= PC-9801 dos memory vs NEOGEO sound ROM 領域 + RAM 領域) の差分整理
- main CPU 通信 (= PC-9801 では DOS process 通信、 NEOGEO は 68000 から Z80 へ port 経由 command) の追加実装範囲
- `vendor/ngdevkit-examples/` の既存 NEOGEO Z80 sound driver 例を reference として読解

**期待成果**: 「NEOGEO 環境依存層の if neogeo 挿入候補 list」 (= PMD.ASM 内の行 + 既存 PC-9801 code + 必要な NEOGEO code)。

### 軸 2 完了 (= 2026-05-12、 develop 資産 で実装済の確認)

軸 2 着手時、 develop branch (= Phase 12a-4 で停止、 commit `e32e0d3`) に **既に NEOGEO 環境依存層の主要部分が実装済** であることが判明。 ADR-0015 起票時点で本軸の前提が古かった (= develop 資産未参照)。

#### 軸 2 の前提見直し

ADR-0015 起票時の前提 = 「PMD.ASM (= 8086 source) に `if neogeo` flag を挿入して NEOGEO 環境依存箇所を置換える」 だったが、 これは **8086 source 上の改造** を想定していた。

しかし NEOGEO sound subsystem は **Z80 専用** で 8086 は居ない。 develop ではこの mismatch を **PMD V4.8s 8086 source の Z80 化 + nullsound integration** で解決済 (= `PMDNEO.s` + `PMD_Z80.inc` 等で 1 module ずつ Z80 化発展)。

つまり改造 PMDDotNET 路線は次の二段構造:
- mc compiler 側 (= `vendor/PMDDotNET/PMDDotNETConsole`) を OPNB 対応に改造 (= 軸 4)
- driver 側 = develop 上 PMDNEO driver (= PMD V4.8s の Z80 化 + nullsound integration、 既に Phase 2 SubF-1.1 まで進行) を継続発展

#### develop 上 PMDNEO driver 現状 (= 2026-05-12 確認時)

`src/driver/` 内の Z80 driver source 一覧:

| file | 行数 | 役割 / 状態 |
|---|---|---|
| `PMDNEO.s` | 44 | build top (= sdasz80)、 nullsound integration 完了、 cmd_jmptable 実装 (= cmd 02 play_song / 04 fade_out / 05 play_adpcmb_test) |
| `PMD_Z80.inc` | 2206 | PMD V4.8s 8086 source の Z80 化 base、 SubB-1〜SubF-1.1 まで実装進行 (= SSG init / TIMER-B IRQ / FM voice / scale 演奏 / fade) |
| `WORKAREA.inc` | 137 | 17 part 構造 (= FM 6ch + SSG 3ch + ADPCM-B + Rhythm + ADPCM-A 6ch)、 各 part workarea field offset 定義済 |
| `KR_STUB.inc` | 52 | K/R rhythm 7 cmd no-op stub 完成 (= PMD ファミリ「未対応 cmd スルー」 思想 実装) |
| `IRQ.inc` | 117 | TIMER-B IRQ + nullsound cmd 受付経路 完成 |
| `REGMAP.inc` | 19 | nullsound `ports.inc` + `ym2610.inc` 流用 |
| `ADPCMB_DRV.inc` | 49 | 大半 stub だが ADPCM-B keyon/keyoff 一部実装済、 SubE で本実装予定 |
| `ADPCMA_DRV.inc` | 48 | Phase 3 用 stub |
| `standalone_test.s` | 2351 | ADR-0006 sprint 別経路試行産物 (= ADR-0014 で凍結扱い、 本軸対象外) |

#### 軸 2 4 観点の develop 解決状況

| 観点 | ADR-0015 起票時の想定 | develop 上での解決 |
|---|---|---|
| I/O port 差分 | PC-9801 OPNA `0x188-0x18B` → NEOGEO YM2610 `0x04-0x07` の置換 | `REGMAP.inc` で nullsound `ports.inc` + `ym2610.inc` 流用、 PORT_YM2610_STATUS 等の symbolic name で抽象化済 |
| IRQ vector / timing | PC-9801 vsync IRQ + 8259 PIC mask 経路 → NEOGEO 別 vector | `IRQ.inc` で TIMER-B IRQ handler 確立 (= chip 1 ms 周期固定 + sub-tick acc で tempo 可変)、 nullsound NMI 経路と独立動作 |
| 68000 通信 (= main CPU) | PC-9801 DOS process 通信 → 68000 から Z80 へ port 経由 command | nullsound cmd_jmptable 経由で確立 (= 0x320000 書込 → REG_SOUND → cmd 02/04/05 dispatch) |
| memory map | PC-9801 dos memory → NEOGEO sound ROM + RAM | Z80 RAM 0xf800-0xffff に WORKAREA (= 17 part × 64 byte = 1088 byte) + sound ROM 経路 (= sample_m.s 等の include で組込) 確立済 |

#### PMD.ASM 8086 source 上の if 分岐との関係

ADR-0015 軸 1 で集計した PMD.ASM 全 203 件 if 分岐 (= 8086 source 上の chip / 環境分岐) は、 develop の Z80 化 path では **手で Z80 化する際の reference** として有用。 つまり:
- ppz 関連 38 件 (= 軸 1 完了で全件読了済) → develop の `WORKAREA.inc` 17 part 構造 + `KR_STUB.inc` 「未対応 cmd スルー」 が PPZ8 拡張流儀の継承
- board2 90 件 (= 軸 3 で扱う) → develop の `PMD_Z80.inc` 2206 行 + `REGMAP.inc` で OPNA register layout を YM2610/B register layout に対応付け済 (= ADR-0001 既決事項「FM ch1/ch4 不使用」 を WORKAREA 17 part 構造で物理 omit 反映)

#### 軸 2 の残作業 = なし

NEOGEO 環境依存層は develop で実装済、 軸 2 は本 commit で完了とする。

#### 他軸への含意

- **軸 3 (= OPNB 差分)** も同様の見直しが必要: develop の `REGMAP.inc` + `ADPCMA/B_DRV.inc` + `WORKAREA.inc` 17 part 構造 で chip 差分対応の枠組みは既に存在、 残作業は ADPCM-A 6ch 実装 (= Phase 3) 等の具体機能追加。 ADR-0015 §軸 3 は「PMD.ASM 8086 source 上の board2 90 件分析」 を develop driver 側 SubE/Phase 3 等の具体実装計画として再定義する形になる
- **軸 4 (= mc compiler)** は develop driver 側の cmd 規約 + .M format 規約 を base に、 PMDDotNET 側 OPNB 出力対応を組み立てる形に redefine
- **軸 5 (= 改造規模見積もり)** も driver 側 develop 進捗 (= Phase 2 SubF-1.1 まで) を踏まえて見直し必要

ADR-0015 全体の前提見直しは別 ADR で正式化候補 (= ADR-0017 等で develop driver 現状 snapshot + ADR-0015 の前提整理を起票)。

### 軸 3: OPNB chip 差分の特定

**注記 (= 2026-05-12、 ADR-0017 §決定 3)**: 本軸の作業内容は起票時前提 (= 8086 source 上の改造) で書かれている。 develop branch の Z80 化 path (= `REGMAP.inc` + `ADPCMA/B_DRV.inc` + `WORKAREA.inc` 17 part 構造で枠組み済) 前提で **redefine 必要**。 残作業は「ADPCM-A 6ch 本実装 (= Phase 3)」 + 「ADPCM-B 本実装 (= SubE 完成)」 + 「OPNA 既存 board2 90 件のうち未踏襲部分の発掘」 として整理。 詳細は [ADR-0017](0017-pmdneo-develop-driver-snapshot-and-adr-0015-redefine.md) §決定 3 参照。

**目的**: OPNA → OPNB の chip register / 機能差分を整理し、 `if opnb` 挿入候補を特定。

**作業内容**:
- register address 差分 (= OPNA と OPNB は port 番号違うが register layout 似てる)
- ADPCM-A 6 ch 経路 (= OPNA の Rhythm 経路 = `if adpcm` + `if board2` で書かれている、 OPNB ADPCM-A は別系統リソース)
- ADPCM-B 1 ch (= OPNA / OPNB 共通だが、 OPNB は sample bank の memory layout が異なる)
- SSG 3 ch (= OPNA と OPNB はほぼ共通、 base clock 差異のみ)
- FM 4 ch / 6 ch (= YM2610 は 4 ch、 YM2610B は 6 ch、 ADR-0001 既決事項参照)
- ADR-0010 で整理した「YM2610 = YM2610B の ch1/ch4 物理 omit 派生 chip」 の事実は本路線でも継承
- 既存 memory `reference_opna_opnb_chip_comparison.md` (= もし存在すれば) や PMD V4.8s manual を reference

**期待成果**: 「OPNA → OPNB 差分表」 + 「if opnb 挿入候補 list」 (= PMD.ASM 内の行 + 既存 OPNA code + 必要な OPNB code)。

### 軸 3 完了 (= 2026-05-12、 develop 資産前提で redefine 完了)

軸 3 着手時、 ADR-0017 §決定 3 の方針で「develop 資産前提の redefine」 として進めた。 起票時の 8086 source 上 if 分岐挿入 想定は廃止、 develop の Z80 化 path で残作業を整理する形。

#### develop 上 ADPCMA_DRV.inc + ADPCMB_DRV.inc 既存 stub 整理 (= 2026-05-12 確認時)

| file | routine | 入力規約 | 動作 (= 設計書 2/3) | 実装状態 |
|---|---|---|---|---|
| `ADPCMA_DRV.inc` | `adpcma_init` | (なし) | `0x00←0xBF` (= 全 ch dump) + `0x01←0x3F` (= max master vol) | stub (= Phase 3) |
| `ADPCMA_DRV.inc` | `adpcma_keyon` | A=ch / DE=sample table entry | `0x10+ch / 0x18+ch / 0x20+ch / 0x28+ch` 書込 + `0x00←(1<<ch)` で keyon | stub (= Phase 3) |
| `ADPCMA_DRV.inc` | `adpcma_keyoff` | A=ch | `0x00 ← 0x80|(1<<ch)` で dump (= keyoff 相当) | stub (= Phase 3) |
| `ADPCMA_DRV.inc` | `adpcma_volset` / `adpcma_panset` / `adpcma_main` | (未定) | 個別 ch volume / pan、 per-tick processing | stub (= Phase 3) |
| `ADPCMB_DRV.inc` | `adpcmb_keyon` | A=sample 番号 / BC=delta-N / D=pan/vol | `snd_adpcm_b_play` 経由再生 (= `adpcm_b_beat_struct`) | 一部実装済 (= 単発再生のみ、 SubE で本実装) |
| `ADPCMB_DRV.inc` | `adpcmb_keyoff` | (なし) | `0x10 ← 0x01` (= reset bit) | 実装済 (= nullsound `ym2610_write_port_a` 直接呼出) |
| `ADPCMB_DRV.inc` | `adpcmb_volset` / `adpcmb_panset` / `adpcmb_setfreq` | (未定) | `0x1B` 経由 volume / `0x11` 経由 pan / `0x19/0x1A` 経由 delta-N | stub (= SubE) |

#### PMD V4.8s 8086 source の adpcm 関連 22 件 全件 1 件 1 行 表

flag 列の `if`/`ifndef` は省略 (= 全件いずれかの conditional assemble)。 入れ子 (= 親条件) は丸括弧で記載。 軸 1 で既読の 2 件 (= 6455 + 7087) は ppz 関連で同時記録、 ここでは ADPCM 観点で再分類。

| # | 行 | flag | 機能 / 役割 |
|---|---|---|---|
| 1 | 27 | `ifndef adpcm` | adpcm flag default 値 (= 0) 設定 |
| 2 | 30 | `ifndef ademu` | ademu flag default 値 (= 0) 設定 |
| 3 | 360 | `adpcm` (`board2` 内側) | `if ademu / include pcmdrve.asm else include pcmdrv.asm` (= ADPCM driver の include 切替) |
| 4 | 361 | `ademu` (`board2*adpcm` 内側) | ADPCM emulate 用 driver `pcmdrve.asm` を include (= PPZ8 経由 emulate) |
| 5 | 457 | `board2*adpcm` | mstart 内 ADPCM 関連: ademu 時は PPZ8 ch7 control / 非 ademu 時は part10 mask 制御 |
| 6 | 458 | `ademu` (`board2*adpcm` 内側) | ADPCM emulate ON 時の特殊処理 (= PPZ8 経由) |
| 7 | 587 | `adpcm` (`board2` 内側) | data_init 内 part 9 (= OPNA ADPCM) 初期値設定 (= volume 128 / pan center) |
| 8 | 6123 | `adpcm` (`board2` 内側) | mstop 内 ADPCM reset (= `0102h PAN=0` + `0001h PCM RESET`、 ademu 非有効時のみ) |
| 9 | 6455 | `ademu` (`board2*ppz` 内側、 軸 1 既読 #10) | drv_chk 内 al_push 値分岐 (= ppz + ademu 構成識別) |
| 10 | 7063 | `adpcm` (`board2` 内側) | part_mask pm_pcm 内 ADPCM ch 停止 (= ademu 時 PPZ8 ch7 / 非 ademu 時 OPNA reset) |
| 11 | 7064 | `ademu` (`board2*adpcm` 内側) | ADPCM emulate 時の停止 path (= PPZ8 ch7 keyoff) |
| 12 | 7087 | `ademu` (`ppz` 内側、 軸 1 既読 #15) | pm_ppz 内 ADPCM emulate 例外処理 (= ch7 は ADPCM emulate 時 skip) |
| 13 | 8355 | `adpcm` (`board2` 内側) | pcm_table data 領域 (= pcmends/pcmadrs/pcmfilename、 ademu 非有効時のみ) |
| 14 | 8873 | `board2*adpcm` | port_check 内 ADPCM RAM check (= ademu 時 skip / 非 ademu 時 `adpcm_ram_check` 呼出) |
| 15 | 8876 | `ademu` (`board2*adpcm` 内側) | ADPCM emulate 時 RAM check skip + `pcm_gs_flag` セット |
| 16 | 8959 | `board2*adpcm` (`ife ademu` 内側) | 起動メッセージ「ADPCM」 構成表示 (= ademu 非有効時のみ) |
| 17 | 9670 | `board2*adpcm` (`ife ademu` 内側) | 設定表示 print: ADPCM 定義速度 (= `adpcm_wait` 値、 ademu 非有効時のみ) |
| 18 | 10532 | `board2*adpcm` (`ife ademu` 内側) | `include adramchk.asm` (= ADPCM RAM check module、 ademu 非有効時のみ) |
| 19 | 10580 | `board2*adpcm` | エラーメッセージ "+ADPCM" / " only" 文字列定義 |
| 20 | 10631 | `ademu` (`board2`/`pcm` 内側) | usage: 実行ファイル名 接尾辞「E」 (= ADPCM emulate 版) 表示 |
| 21 | 10680 | `board2*adpcm` (`ife ademu` 内側) | usage: `/An` (= ADPCM 定義速度) help line |
| 22 | 10724 | `board2*adpcm` (`ife ademu` 内側) | "ADPCM 定義速度" print msg 文字列 |

#### board2 90 件のうち register / port 関連 集計 (= helper 別)

PMD V4.8s 8086 source の OPNA register / port access は次の 5 系統に集約される。 board2 90 件のうち大半がこれら helper 経由。

| 系統 | 件数 | 関数 / instruction | PMDNEO 置換先 (= develop 資産) |
|---|---|---|---|
| OPNA primary register write helper | 47 呼出 + 1 定義 = 48 件 | `opnset44` (= 6173 行 定義、 入力 DX → bx swap で reg/data) | `ym2610_write_port_a` (= nullsound、 BC 入力規約) |
| OPNA secondary register write helper | 8 呼出 + 1 定義 = 9 件 | `opnset46` (= 6200 行 定義、 board2 限定) | `ym2610_write_port_b` (= nullsound) |
| chip select helper | 26 件 | `sel44` / `sel46` (= chip primary/secondary select、 init 経路) | (= nullsound 不要、 chip 1 つで完結) |
| 直接 port write | 45 件 | `out dx, al` (= init / port_check / IRQ 経路、 主に register select + value 順次出力) | nullsound `ym2610_write_port_a/b` 経由に置換 |
| 直接 port read | 34 件 | `in al, dx` (= status check / port detection) | nullsound status read helper 経由 |

合計: 約 162 件 (= 重複あり)。 board2 関連 90 件はその大半を占める。

#### 主要 helper の置換 規約 (= develop の REGMAP.inc + PMD_Z80.inc 経由)

`opnset44` / `opnset46` は PMD V4.8s OPNA driver の中核 register write helper。 PMDNEO 改造では:

- 入力規約変換: 8086 では DX register に「reg << 8 | data」 形式で 16-bit 値 (= bh = reg、 bl = data)、 Z80 では BC register に「B = reg、 C = data」 形式
- port address: PMD は `fm1_port1` / `fm1_port2` / `fm2_port1` / `fm2_port2` を変数 (= port_check で動的決定) → PMDNEO は YM2610 fixed port `0x04/0x05/0x06/0x07` (= nullsound `ports.inc` 提供)
- ready check: PMD `rdychk` macro → nullsound 提供 helper に置換 (= develop で実装中)

#### 軸 3 redefine 残作業 (= Phase 3 / SubE / 既存実装継続)

| 残作業 | scope | 対応 file / phase | 推定規模 |
|---|---|---|---|
| ADPCM-A 6ch 本実装 | adpcma_init / keyon / keyoff / volset / panset / main 全部 | `ADPCMA_DRV.inc` / Phase 3 | 100-200 行 (= 既存 stub + 設計書 2 §3-§7 ベース) |
| ADPCM-B 本実装 (= SubE 完成) | adpcmb_volset / panset / setfreq + main loop | `ADPCMB_DRV.inc` / SubE | 50-100 行 |
| OPNA → YM2610/B register 経路 完成 | opnset44/46 経由箇所の Z80 化進捗確認 + 残部 | `PMD_Z80.inc` 内、 SubB-F 進行中 | 既存 2206 行に随時追加 |
| board2 90 件のうち 未踏襲部分 発掘 | helper 経由でない 直接 register access (= IRQ vec / port_check / init 経路) | `IRQ.inc` / `PMDNEO.s` / 関連 | 20-30 件 (= 推定) |
| YM2610 vs YM2610B 切替 (= ADR-0001) | FM ch1/ch4 mute (= YM2610) / FM 6ch 全部 (= YM2610B)、 build flag `ym2610b` で切替 | `PMDNEO.s` の `ym2610b = 1` flag (= 既設定済) | 既設定済、 driver 側で部分対応 |

#### 軸 4 / 軸 5 への引継ぎ事項

- **軸 4 (= mc compiler)**: develop driver 側の cmd 規約 (= cmd 02/04/05 + 将来追加) + WORKAREA 17 part 構造 + .M format 仕様 を base に PMDDotNET 側 OPNB 出力対応を組み立てる形 (= ADR-0017 §決定 3 参照)
- **軸 5 (= 改造規模見積もり)**: driver 側 develop 進捗 (= Phase 2 SubF-1.1 まで) + 軸 3 残作業 (= 約 200-400 行 規模 + 90 件中の未踏襲 20-30 件) を合算して再見積もり

### 軸 4: mc compiler 改造範囲特定

**注記 (= 2026-05-12、 ADR-0017 §決定 3)**: 本軸の作業内容は起票時前提 (= 改造前提) で書かれている。 develop driver 側の cmd 規約 (= cmd 02/04/05 + 将来追加) + WORKAREA 17 part 構造 + .M format 仕様 を base に **redefine 必要**。 詳細は [ADR-0017](0017-pmdneo-develop-driver-snapshot-and-adr-0015-redefine.md) §決定 3 参照。

**目的**: `vendor/PMDDotNET/PMDDotNETConsole/` (= C# 移植版 mc compiler) を OPNB 対応にする改造範囲を特定。

**作業内容**:
- mc compiler の OPNA 出力経路を読解 (= 例 `mc.cs` 内の voice 定義 → register layout 変換ロジック)
- OPNB 出力分岐の挿入候補箇所を特定 (= build flag or runtime flag で OPNB mode 化)
- .M format 内に OPNB 識別子 / metadata を追加するか、 driver 側で吸収するかの設計判断
- 同 .M format (= 同一 MD5) 保証のため、 OPNB 用 .M は別 file 出力か同 file format 内で flag 切替か

**期待成果**: 「mc compiler 改造箇所 list」 + 「.M format design 決定」 (= OPNA / OPNB 識別の方法)。

### 軸 4 完了 (= 2026-05-12、 develop 資産前提で redefine 完了)

軸 4 着手時、 ADR-0017 §決定 3 の方針で「develop 資産前提の redefine」 として進めた。 起票時の「build flag or runtime flag で OPNB mode 化」 「.M format 内 OPNB 識別子追加」 想定を、 develop driver 側 cmd 規約 + WORKAREA 17 part 構造 + 設計書 1 (`.mn` binary layout) と統合する形で再定義。 step 4-A 〜 4-E の 5 step に分解して進行。

#### step 4-A: develop driver 側の .M / cmd 規約 抽出 (= 2026-05-12 完了)

`src/driver/PMDNEO.s` (= 44 行) + `IRQ.inc` (= 117 行) + `WORKAREA.inc` (= 137 行) + 設計書 1 (`docs/design/mn_binary_layout.md`、 692 行) §0-§11 を読解。

**cmd 規約** (= nullsound 流儀):

| cmd | 動作 | 入力 param |
|---|---|---|
| 0x00 | unused | なし |
| 0x01 | prepare_for_rom_switch (= nullsound.lib 提供) | なし |
| 0x02 | play_song (= pmdneo_init + test_play_fm_song + polling loop、 ret しない) | なし |
| 0x03 | reset_driver (= nullsound.lib default、 PMDNEO 側で再定義しない) | なし |
| 0x04 | fade_out (= SSG 全 vol 0 + FM 6ch keyoff + ADPCMB keyoff + driver_fade_state=1) | なし |
| 0x05 | play_adpcmb_test (= test_play_adpcmb_beat 1 発、 即 ret) | なし |

cmd は単純 trigger 型、 楽曲 data は `sample_m.s` で driver ROM 埋め込み (= SubB-7)。

**17 part 構造** (= `WORKAREA.inc`):

- A-F = FM 6ch (= 番号 0-5)、 G-I = SSG 3ch (= 6-8)、 J = ADPCM-B (= 9)、 R = Rhythm no-op (= 10)、 L-Q = ADPCM-A 6ch (= 11-16)
- 21 個 of field offset 定義済 (= PART_OFF_ADDR/LOOP/LEN/QDATA 等)
- mmlbuf = SAMPLE.M load 用絶対 address (= `driver_song_base + 1`)

**`.m` / `.mn` format 仕様** (= 設計書 1):

- `.m` = OPNA 標準、 前 26 byte header + 11 part offset table + rhythm addr offset + prgdat_adr
- `.mn` = `.m` 上位互換、 m_start = 0x04 で PMDNEO mode、 後方拡張領域に Part L-Q + .PNE 参照
- m_start = 0x00 → `.m` 互換 mode (= driver 側で extended 領域読まない)
- m_start = 0x04 → PMDNEO mode (= extended_data_adr 解析)
- 同 MML を OPNA / OPNB mode で compile → 前半 bit-by-bit 一致 (= ADR-0013 D1 同 .M 2 経路比較 路線の理論基盤)

#### step 4-B: PMDDotNETConsole 構造把握 (= 2026-05-12 完了)

`vendor/PMDDotNET/PMDDotNETCompiler/` 全 14 file の構造把握 + `mc.cs` (= 10009 行) / `m_seg.cs` (= 26 行) / `mml_seg.cs` (= 370 行) の主要構造を grep。

**改修対象 3 file** (= 設計書 1 §7-1 で既に明示済):

| file | 行数 | 役割 |
|---|---|---|
| `mc.cs` | 10009 | main compile loop + 全 # コマンド handler + part / cmd dispatch |
| `m_seg.cs` | 26 | `.M` binary container (= `m_filename` + `m_start` + `m_buf` + `mbuf_end`) |
| `mml_seg.cs` | 370 | message text + part / cmd table + warning / usage 文字列 |

**part letter 処理経路**:

- `mml_seg.part` = 内部 part 番号 (= 1 〜 N)、 `(char)('A' - 1 + mml_seg.part)` で letter 化
- `partcheck(char al)` (= `mc.cs:3228`) で letter validity チェック、 既存は A-K (= 11 part) 想定
- L-Q 拡張は partcheck の上限変更 + part table 拡張で対応可能

**`.M` binary 出力経路**:

- `m_seg.m_start = (byte)(mml_seg.opl_flg * 2 | mml_seg.x68_flg);` (= `mc.cs:816`)
- 既存 bit 配置: bit 0 = x68_flg、 bit 1 = opl_flg、 **bit 2 以上空き**
- 設計書 1 §3-1 の m_start = 0x04 (= bit 2) PMDNEO mode と整合 → 既存に bit 2 を追加するだけ

**mc compiler の chip mode 切替方式**:

- PMDPPZ.ASM 流儀 (= 16 行 wrapper + 条件 assemble) ではなく、 **1 binary で flag (`opl_flg` / `x68_flg`) 切替方式**
- OPNB 対応も同流儀: 新規 `mml_seg.opnb_flg` + mc.cs / m_seg.cs に if 分岐挿入

#### step 4-C: OPNA → OPNB 出力分岐 設計 (= 2026-05-12 確定)

user 判断 3 件:

| 判断 | 確定 |
|---|---|
| 1. OPNB mode 起動方法 | CLI option `/B` + `mml_seg.opnb_flg` (= 1 binary、 PMDPPZ.ASM 流儀採らず) |
| 2. 既存 OPN mode との関係 | 同 MML で前半 bit-by-bit 一致保証 (= ADR-0013 D1 路線基盤、 設計書 1 §2-1 整合) |
| 3. voice 定義 OPNA/OPNB 差分 | OPNA 完全互換、 `voice_seg.cs` 改修なし |

#### step 4-D: .M format 識別子設計 (= 2026-05-12 確定)

user 判断 1 件:

| 判断 | 確定 |
|---|---|
| 4. `/N` (= OPNA) で L-Q part 検出時 | 警告 + L-Q skip (= ADR-0001 Part A/D 規律と同パターン、 同 MML で `/N` `/B` 両 mode compile 可) |

**出力 format 仕様**:

| MML 内容 | CLI option | 出力拡張子 | m_start bit 2 | driver 解釈 |
|---|---|---|---|---|
| ADPCM-A 不使用 | `/N` (OPNA) | `.M` | 0 | OPNA + PMDNEO 両方 OK |
| ADPCM-A 不使用 | `/B` (OPNB) | `.M` | 0 | OPNA + PMDNEO 両方 OK (= 前半 bit-by-bit 一致) |
| ADPCM-A 使用 | `/N` (OPNA) | `.M` (= warning + L-Q skip) | 0 | OPNA + PMDNEO 両方 OK (= ADPCM-A 部分は無音) |
| ADPCM-A 使用 | `/B` (OPNB) | `.MN` | 1 | PMDNEO のみ |

#### step 4-E: 改造箇所 list 整理 (= 2026-05-12 完了)

**PMDDotNETCompiler/ 改修対象 file 一覧**:

| file | 行数 | 改修内容 | 推定規模 |
|---|---|---|---|
| `mml_seg.cs` | 370 | 新規 `opnb_flg` flag + `pne_filename` field + usage message 更新 (= `/B` 追加) | 30-50 行 |
| `mc.cs` | 10009 | 新規 CLI option `/B` 認識 (= `ReadOption()`、 507 行) + m_start bit 2 追加 (= 816 行) + partcheck で L-Q 受付 + `/N` 時 L-Q 警告 + 新規 `#PNEFile` handler (= `file_name_set` 周辺) + Part L-Q MML body 出力経路 + 後方拡張領域出力 + 出力拡張子 `.MN` 切替 (= 591/593 行) | 150-250 行 |
| `m_seg.cs` | 26 | 新規 `extended_data_adr` field + `pne_filename_adr` field | 5-10 行 |
| `voice_seg.cs` | (未読) | **改修なし** (= 判断 3、 OPNA 完全互換) | 0 行 |
| `compiler.cs` / `lc.cs` / `work.cs` / `err_seg.cs` / `hs_seg.cs` / `fnumdat_seg.cs` | (未読) | 改修必要性次第 (= ADR-0016 で精緻化) | 0-50 行 |

**改造規模 合計**: 185-360 行 (= mc compiler 側)

#### 軸 5 への引継ぎ事項

- mc compiler 改造規模 = **185-360 行**
- driver 側 develop 進捗 (= Phase 2 SubF-1.1 まで) + 軸 3 残作業 (= 約 200-400 行) を合算で軸 5 最終見積もり
- 軸 4 起票時の「if 分岐 100-150 件」 見積もりは PMDPPZ.ASM 流儀前提で算出、 C# binary の mc compiler では「if 分岐数」 ではなく「行数」 ベースで再見積もり必要

### 軸 5: 改造規模見積もり最終化

**注記 (= 2026-05-12、 ADR-0017 §決定 3)**: 本軸の見積もり (= 100-150 件 if 分岐) は起票時前提 (= 8086 source 上の改造) で算出。 driver 側 develop 進捗 (= Phase 2 SubF-1.1 まで) を踏まえて「残実装規模」 として **再見積もり必要**。 詳細は [ADR-0017](0017-pmdneo-develop-driver-snapshot-and-adr-0015-redefine.md) §決定 3 参照。

**目的**: 軸 1-4 の調査結果を踏まえ、 改造規模を最終確定し ADR-0016 (= 改造着手) 起票準備。

**作業内容**:
- 100-150 件 if 分岐の具体的内訳 (= 軸 2 の neogeo / 軸 3 の opnb の合計)
- 各 if 分岐の影響範囲 (= 数行 vs 数十行 vs 数百行)
- 作業順序の選択肢 (= 例「先に NEOGEO 環境移植 → 次に OPNB chip 移植」 vs 「先に OPNB chip 移植 → 次に NEOGEO 環境移植」)
- 段階的検証経路 (= 例「NEOGEO 環境 + OPNA mock で実機動作 → OPNB 切替」 が可能かの判定)
- mc compiler 改造のタイミング (= driver と並行 or 後)

**期待成果**: ADR-0016 (= 改造着手 sprint の作業計画) を書き起こせる程度の改造規模 + 着手順序 + 段階的検証方針の確定。

### 軸 5 完了 (= 2026-05-12、 develop 資産前提で redefine 完了)

軸 5 着手時、 ADR-0017 §決定 3 の方針で「develop 資産前提の redefine」 として進めた。 起票時の「100-150 件 if 分岐の具体的内訳」 は PMDPPZ.ASM 流儀前提だが、 develop の Z80 化 + nullsound integration + mc compiler の C# 1 binary 流儀を踏まえ、 「行数ベースの最終見積もり」 + 「着手順序」 + 「段階的検証経路」 として再定義。

#### step 5-A: 軸 3 + 軸 4 結果統合 (= 2026-05-12 完了)

| 区分 | scope | 推定規模 |
|---|---|---|
| **driver 側 (= 軸 3 残作業)** | | |
| ADPCM-A 6ch 本実装 (= Phase 3) | adpcma_init/keyon/keyoff/volset/panset/main | 100-200 行 |
| ADPCM-B 本実装 (= SubE 完成) | adpcmb_volset/panset/setfreq + main loop | 50-100 行 |
| OPNA → YM2610/B register 経路 完成 | opnset44/46 経由箇所の Z80 化進捗確認 + 残部 | 既存 `PMD_Z80.inc` 2206 行に随時追加 |
| board2 90 件 未踏襲部分 発掘 | helper 非経由 直接 register access | 20-30 件 (= 数十行) |
| **mc compiler 側 (= 軸 4)** | | |
| `mml_seg.cs` | opnb_flg + pne_filename + usage | 30-50 行 |
| `mc.cs` | CLI option `/B` + m_start bit 2 + partcheck L-Q + #PNEFile + L-Q body 出力 + 後方拡張 + 拡張子切替 | 150-250 行 |
| `m_seg.cs` | extended_data_adr + pne_filename_adr | 5-10 行 |
| その他 (= voice_seg / 未読 6 file) | OPNA 互換、 必要次第 | 0-50 行 |
| **合計** | | **約 335-660 行** + 既存 `PMD_Z80.inc` への追加分 |

ADR-0014 (= PMDPPZ 流儀発見) 当時の「100-150 件 if 分岐 = 元の 5-10% 修正」 とは尺度が違う。 develop branch で既に Z80 化 + nullsound integration が Phase 2 SubF-1.1 まで進行しているため、 残作業は「新規 ADPCM 関連 + mc compiler 拡張」 中心。

#### step 5-B: 着手順序 + 段階的検証経路 設計判断 (= 2026-05-12 確定)

**判断 5-1: 着手順序** = (B) **mc compiler 先 + driver 後**

| 候補 | 採否 | 根拠 |
|---|---|---|
| (A) driver 先 + mc compiler 後 | × | ADPCM-A 6ch 楽曲 verify が最終段階に遅延 |
| **(B) mc compiler 先 + driver 後** | **採用** | ADR-0013 D1 (= 同 .M 2 経路比較) 路線の検証基盤を最早期で確立、 任意 MML test 可能 |
| (C) 並行 | × | 開発者 1 人で文脈切替コスト高 |

**判断 5-2: 段階的検証経路 5 step** (= (B) 順序の自然な分解):

| step | 内容 | verify 対象 |
|---|---|---|
| 1 | mc compiler 改造 (= `/B` CLI option + opnb_flg + 関連改修) | 既存 `/N` 出力が無改造で温存される byte 単位互換性 |
| 2 | 同 MML 前半 bit-by-bit 一致 verify | ADPCM-A 不使用 MML を `/N` `/B` 両 compile、 前 26 byte header + part body + prgdat 一致 |
| 3 | driver 既存 .M 再生 verify | mc compiler `/B` 出力 .M (= bit 2 = 0) を driver で再生、 動的 load 経路 |
| 4 | driver SubE 完成 (= ADPCM-B 本実装) | adpcmb_volset/panset/setfreq + main loop、 既存単発再生 → 統合演奏 |
| 5 | driver Phase 3 (= ADPCM-A 6ch 本実装) | mc compiler `/B` + ADPCM-A 使用 MML → `.MN` 出力 → driver で再生 |

step 1-2 は mc compiler sprint、 step 3-5 は driver sprint。 「同 MML 2 経路比較 verify」 (= step 2) を最早期化することで ADR-0013 D1 路線の検証基盤を確立する。

#### step 5-C: ADR-0016 起票準備 (= 2026-05-12 完了)

軸 5 完了で ADR-0015 全体終了 (= 完了判定 §「ADR-0016 を書き起こせる程度に PMD.ASM 内 neogeo/opnb 挿入候補箇所 + mc compiler 改造箇所 + 改造規模 + 着手順序 + 段階的検証方針 が確定」 を満たす、 ただし「PMD.ASM 内 neogeo/opnb 挿入候補箇所」 は ADR-0017 §決定 3 で develop 資産前提に置換済)。

**ADR-0016 起票時の主要引継項目**:

| 項目 | 内容 |
|---|---|
| 路線 | ADR-0017 §決定 4 path A 採択 (= 改造 PMDDotNET 路線、 develop driver 継続発展) |
| 着手順序 | (B) mc compiler 先 + driver 後 (= 判断 5-1) |
| 段階的検証 | 5 step (= 判断 5-2、 step 1-2 mc compiler sprint + step 3-5 driver sprint) |
| 改造規模 | 約 335-660 行 + 既存 `PMD_Z80.inc` 追加分 |
| 改修対象 (driver) | `ADPCMA_DRV.inc` + `ADPCMB_DRV.inc` + `PMD_Z80.inc` 追加 |
| 改修対象 (mc compiler) | `mml_seg.cs` + `mc.cs` + `m_seg.cs` |
| 不要対象 (driver) | `standalone_test.s` (= ADR-0014 凍結) |
| 不要対象 (mc compiler) | `voice_seg.cs` (= 判断 3、 OPNA 完全互換) |

ADR-0016 は別 sprint で起票。 本 ADR-0015 はこれで完了状態 (= Accepted へ移行候補)。

## 調査手法

- **grep + 読解**: PMD.ASM / 関連 ASM file / mc compiler C# source を grep + 行範囲読解
- **memory + ADR-0015 追記**: 調査結果を memory または ADR-0015 本体に段階的に蓄積
- **ngdevkit examples reference**: NEOGEO Z80 sound driver の既存実装例から memory map / IRQ / I/O 規定を借用
- **PMDPPZ.ASM 流儀踏襲**: 既存 PPZ8 拡張の流儀 (= 16 行 wrapper + 35 件の if 分岐) を改造手本として参照
- **commit / push 前に平易な日本語報告**: feedback_explain_in_plain_japanese_before_commit.md 規律遵守

## 期待成果物

調査完了時に以下が揃う:

1. **ADR-0015 本体に各軸の調査結果を追記** (= 行番号 + flag + 目的の対応表、 if 分岐挿入候補 list、 mc compiler 改造箇所 list)
2. **必要に応じて memory 化** (= 例「PMD.ASM 構造調査結果」 memory、 「NEOGEO 環境移植要点」 memory 等)
3. **ADR-0016 起票準備** (= 改造着手 sprint の作業計画、 着手順序、 段階的検証方針)

## 着手順序

```
1. 軸 1: PMD.ASM 構造調査 (= 最優先、 起点)
   ↓
2. 軸 2 + 軸 3 並行 (= NEOGEO 環境 + OPNB 差分、 独立した調査軸)
   ↓
3. 軸 4: mc compiler 改造範囲 (= 軸 3 OPNB 差分結果が前提)
   ↓
4. 軸 5: 改造規模見積もり最終化 (= 軸 1-4 集約)
   ↓
5. ADR-0016 起票
```

軸 1 の調査結果次第で軸 2/3/4 の作業量が変動する可能性あり、 段階ごとに user 壁打ち + 判断仰ぐ。

## 完了判定

ADR-0016 (= 改造着手) を書き起こせる程度に以下が確定した状態:

- PMD.ASM 内の neogeo / opnb 挿入候補箇所 (= 行番号レベル)
- mc compiler の OPNB 出力分岐挿入箇所
- 改造規模 (= if 分岐の具体的数 + 各分岐の影響行数)
- 着手順序 + 段階的検証方針

## 関連 memory

- `project_adr_0013_0014_path_switch.md` (= ADR-0013/0014 路線変更記録 + PMDPPZ 流儀発見)
- `project_pmddotnet_chextend_data_area.md` (= PMDPPZ + FM3Extend data area)
- `project_mame_headless_recording_mode.md` (= MAME 録音 mode、 検証経路で再利用)
- `project_pmd_voice_{tl,ar,dr,ml,alg,fbl}_verified.md` (= PMDDotNET 側 reference 検証結果、 本路線でも有効)
- `feedback_explain_in_plain_japanese_before_commit.md` (= 規律)
- `feedback_branch_strategy.md` (= 規律)

## 次 sprint 候補

1. **軸 1 PMD.ASM 構造調査 着手** (= 本 sprint 最初のステップ)
2. **段階的に軸 2-5 を進行** (= 各軸完了ごとに ADR-0015 追記 + user 報告)
3. **ADR-0015 完了後 ADR-0016 起票** (= 改造着手 sprint の作業計画)
