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

## ビルド手順

pmdneo repo root から:

```bash
cd vendor/ngdevkit-examples/00-template
make
```

ROM が `build/rom/` 配下に生成される (puzzledp 系の cart name で出力、 これは
ngdevkit デフォルトのプレースホルダ命名)。

## 起動確認

```bash
make gngeo
```

ngdevkit-gngeo が起動して「PMDNEO Phase 1 PoC」 ロゴ画面が表示されれば成功。

## 完了基準

- ngdevkit-gngeo で ROM 認識 + 起動画面表示 + 動作不良なし
- user 通読確認 (audio gate は無音 PoC のため不要)

## 後続作業

Phase 1 (α) + (δ) 完了済 (2026-05 現在)。 次は Phase 2 driver 実装着手:

- src/driver/ skeleton 起こし (= 別 plan、 設計書 3 [phase2_driver_plan.md](design/phase2_driver_plan.md) 参照)
- Sub-phase A → SubF の段階的 driver 実装

## ライセンス

PMDNEO 本体と同じく **GPL-3.0**。 ベース ngdevkit-examples (GPL-3.0) と互換。
