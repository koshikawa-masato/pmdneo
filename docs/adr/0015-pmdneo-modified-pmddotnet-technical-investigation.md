# ADR-0015: PMDDotNET 改造 技術調査 sprint — 改造 PMDNEO.ASM 設計のための作業計画

- 状態: Proposed (= 軸 1 + 軸 2 完了、 軸 3-5 未着手、 結果は段階的に追記)
- 起票日: 2026-05-11
- 軸 1 完了日: 2026-05-12
- 軸 2 完了日: 2026-05-12 (= develop 資産 で実装済の確認、 ADR-0015 起票時の前提見直し含む)
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

### 軸 4: mc compiler 改造範囲特定

**目的**: `vendor/PMDDotNET/PMDDotNETConsole/` (= C# 移植版 mc compiler) を OPNB 対応にする改造範囲を特定。

**作業内容**:
- mc compiler の OPNA 出力経路を読解 (= 例 `mc.cs` 内の voice 定義 → register layout 変換ロジック)
- OPNB 出力分岐の挿入候補箇所を特定 (= build flag or runtime flag で OPNB mode 化)
- .M format 内に OPNB 識別子 / metadata を追加するか、 driver 側で吸収するかの設計判断
- 同 .M format (= 同一 MD5) 保証のため、 OPNB 用 .M は別 file 出力か同 file format 内で flag 切替か

**期待成果**: 「mc compiler 改造箇所 list」 + 「.M format design 決定」 (= OPNA / OPNB 識別の方法)。

### 軸 5: 改造規模見積もり最終化

**目的**: 軸 1-4 の調査結果を踏まえ、 改造規模を最終確定し ADR-0016 (= 改造着手) 起票準備。

**作業内容**:
- 100-150 件 if 分岐の具体的内訳 (= 軸 2 の neogeo / 軸 3 の opnb の合計)
- 各 if 分岐の影響範囲 (= 数行 vs 数十行 vs 数百行)
- 作業順序の選択肢 (= 例「先に NEOGEO 環境移植 → 次に OPNB chip 移植」 vs 「先に OPNB chip 移植 → 次に NEOGEO 環境移植」)
- 段階的検証経路 (= 例「NEOGEO 環境 + OPNA mock で実機動作 → OPNB 切替」 が可能かの判定)
- mc compiler 改造のタイミング (= driver と並行 or 後)

**期待成果**: ADR-0016 (= 改造着手 sprint の作業計画) を書き起こせる程度の改造規模 + 着手順序 + 段階的検証方針の確定。

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
