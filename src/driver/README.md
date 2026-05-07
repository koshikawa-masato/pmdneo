# PMDNEO driver source

## 概要

NEOGEO (YM2610/B) 用 PMD 互換サウンドドライバの Z80 source。 PMD V4.8s
の Z80 化 + ADPCM-A 6ch 拡張を統合した単一 binary。

設計書:

- [設計書 1: `.mn` binary layout 仕様](../../docs/design/mn_binary_layout.md)
- [設計書 2: PPZ → ADPCM-A 翻訳 mapping](../../docs/design/ppz_to_adpcma_mapping.md)
- [設計書 3: Phase 2 driver 実装計画](../../docs/design/phase2_driver_plan.md)

## ファイル構成

| file | 役割 | 完成 phase |
|---|---|---|
| `PMDNEO.ASM` | build top (flag 設定 + include 列) | SubA (本 commit) |
| `PMD_Z80.ASM` | PMD V4.8s の Z80 化 base driver | SubB-F |
| `ADPCMB_DRV.ASM` | ADPCM-B 1ch driver | SubE |
| `ADPCMA_DRV.ASM` | ADPCM-A 6ch driver (Phase 3 用 stub) | Phase 3 |
| `KR_STUB.INC` | K/R 内蔵 rhythm no-op stub (PMD ファミリ「未対応 cmd スルー」 思想) | SubA (本 commit、 完成) |
| `IRQ.INC` | TIMER-B IRQ handler + sound command 受付 (nullsound 系統) | SubA (本 commit、 stub) |
| `REGMAP.INC` | YM2610/B register 定数定義 | SubA (本 commit、 全 register 帯) |
| `WORKAREA.INC` | per-part workarea offset 定数 + 領域 (BSS) | SubA (本 commit、 暫定 size) |

## build 構造 (PMD V4.8s 流儀踏襲)

PMD V4.8s の `PMDPPZ.ASM (16 行) → include PMD.ASM` 流儀を Z80 化:

```
PMDNEO.ASM (top)
  ├── flag 設定 (neogeo / adpcmb / adpcma / ym2610b)
  ├── include WORKAREA.INC
  ├── include REGMAP.INC
  ├── include IRQ.INC
  ├── include KR_STUB.INC
  ├── include PMD_Z80.ASM
  ├── (if adpcmb) include ADPCMB_DRV.ASM
  └── (if adpcma) include ADPCMA_DRV.ASM
```

Phase 2 SubA では `adpcma = 0` で組む (= ADPCMA_DRV.ASM は include されず、
file は配置のみ)。

## Sub-phase 進行 (設計書 3 §8)

- **SubA** (本 commit): skeleton 配置 + sdasz80 でビルド通る silent ROM
- **SubB**: SSG 3ch dispatch (commandsp / cmdtblp / fnumset PSG / volset PSG)
- **SubC**: FM 6ch dispatch (commands / cmdtbl / 音色 set)
- **SubD**: K/R no-op stub の cmdtblr 連結
- **SubE**: ADPCM-B 1ch dispatch (ADPCMB_DRV.ASM 完成)
- **SubF**: 統合 (tempo / fade / loop / mask、 長尺楽曲 audio gate)

各 Sub-phase 完了時に audio gate test (= 設計書 3 §7 Step 1-5) を経て
push、 user 聴感確認。

## ビルド経路

Phase 2 SubA 段階では本 driver source を build する経路は **未整備**
(= ngdevkit-examples/00-template の M68K-only build 流儀を Z80 driver
build に拡張する作業は別 task)。 SubA で skeleton を配置した後、 別 task
で:

- 06-sound-adpcma の build 経路 (= user_commands.s を Z80 source として
  組み込む方式) を解析
- pmdneo の PoC build を 06-sound-adpcma 流儀に切替えて、 src/driver/ の
  Z80 source を組み込む

を実施する。

## ライセンス

GPL-3.0 (PMDNEO 本体ソフトウェアと同一)。 PMD V4.8s 公式 source
(vendor/pmd48s/、 GPL-3.0) と PMDDotNET (kuma4649氏作、 GPL-3.0) の
read-only 参照テンプレートとして翻訳した内容を含む。
