# Phase 1 PoC ビルド手順

## 目的

PMDNEO の Phase 1 (α) ROM ビルドフロー検証用の dummy ROM のビルド手順。

- 起動画面に「PMDNEO Phase 1 PoC」 を表示
- sound driver は dummy(busy loop、 無音)
- Phase 2 でフルスクラッチ driver に置換、 Phase 3+ で ADPCM 対応

詳細設計は [docs/design/PMDNEO_DESIGN.md §2-2](design/PMDNEO_DESIGN.md) 参照。

## ベース

- `vendor/ngdevkit-examples/00-template` (GPL-3.0、 Damien Ciabrini氏作)
  - PMDNEO 用に `main.c` を上書き済 (= PMDNEO Phase 1 PoC 表示)
  - 取込履歴 + 改造範囲は [`vendor/ngdevkit-examples/VENDOR_INFO.md`](../vendor/ngdevkit-examples/VENDOR_INFO.md) 参照

## ビルド前提

- macOS native + brew で ngdevkit 一式インストール済 (`/opt/homebrew/opt/ngdevkit/`)
- `~/Downloads/neogeo.zip` (MAME 用 純正BIOS romset) が用意済 (= 起動確認に必要)

ngdevkit がインストールされていない場合の手順は ngdevkit-examples 上流の
[README.md](https://github.com/dciabrin/ngdevkit-examples) 参照。

## 初回セットアップ (1 回のみ)

vendor/ngdevkit-examples の generated file (= build.mk / emu.mk / config.mk)
を生成:

```bash
cd vendor/ngdevkit-examples
autoreconf -i
./configure
```

これで `vendor/ngdevkit-examples/config.mk` + 各 example の build.mk / emu.mk
が生成される (= ngdevkit-examples の build 前提)。

## ビルド手順

pmdneo repo root から `scripts/build-poc.sh` を実行:

```bash
bash scripts/build-poc.sh
```

このスクリプトが:

1. `vendor/ngdevkit-examples/config.mk` を 00-template/ に symlink
2. `src/driver/*.s` + `src/driver/*.inc` (PMDNEO Phase 2 SubA driver source) を
   00-template/ に symlink
3. `cd vendor/ngdevkit-examples/00-template && make`

ROM が `vendor/ngdevkit-examples/00-template/build/rom/` 配下に生成される
(puzzledp 系の cart name で出力、 これは ngdevkit デフォルトのプレースホルダ
命名)。 Phase 2 SubA 段階では sound ROM (`202-m1.m1`) に PMDNEO Phase 2
SubA driver (silent stub) が組み込まれる。

## 起動確認

```bash
cd vendor/ngdevkit-examples/00-template
make gngeo
```

ngdevkit-gngeo が起動して「PMDNEO Phase 1 PoC」 ロゴ画面が表示されれば成功。
sound driver は silent stub のため audio 出力なし (= Phase 2 SubB-F で
段階的に音が出る)。

## 完了基準

- ngdevkit-gngeo で ROM 認識 + 起動画面表示 + 動作不良なし
- user 通読確認 (audio gate は無音 PoC のため不要)

## 後続作業

Phase 1 (α) + (δ) 完了済 (2026-05 現在)。 次は Phase 2 driver 実装着手:

- src/driver/ skeleton 起こし (= 別 plan、 設計書 3 [phase2_driver_plan.md](design/phase2_driver_plan.md) 参照)
- Sub-phase A → SubF の段階的 driver 実装

## ライセンス

PMDNEO 本体と同じく **GPL-3.0**。 ベース ngdevkit-examples (GPL-3.0) と互換。
