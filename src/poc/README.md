# Phase 1 PoC - NEOGEO ROM ビルドフロー検証

## 目的

PMDNEO の Phase 1 (α) ROM ビルドフロー検証用の dummy ROM。

- 起動画面に「PMDNEO Phase 1 PoC」 を表示
- sound driver は dummy(busy loop、 無音)
- Phase 2 でフルスクラッチ driver に置換、 Phase 3+ で ADPCM 対応
- 詳細: [`docs/design/PMDNEO_DESIGN.md §2-2`](../../docs/design/PMDNEO_DESIGN.md)

## ベース

- `ngdevkit-examples/00-template` (GPL-3.0、 Damien Ciabrini氏作)
- 本 PoC は `main.c` のみ改造、 build フローは ngdevkit-examples の親 Makefile に依存

## ビルド前提

- macOS native + brew で ngdevkit 一式インストール済(`/opt/homebrew/opt/ngdevkit/`)
- `ngdevkit-examples` repo を別途 clone(本 PoC は `~/Projects/neo-sisters/vendor/ngdevkit-examples/` を参照)
- `~/Downloads/neogeo.zip`(MAME 用 純正BIOS romset)が用意済

## ビルド手順

### 1. ngdevkit-examples の 00-template に PoC main.c を上書き

```bash
cd ~/Projects/neo-sisters/vendor/ngdevkit-examples/00-template
cp /Users/koshikawamasato/Projects/pmdneo/src/poc/main.c main.c
```

### 2. build

```bash
make
```

ROM が `build/rom/` 配下に生成される(puzzledp 系の cart name で出力、 これは
ngdevkit デフォルト)。

### 3. ngdevkit-gngeo で起動確認

```bash
make gngeo
```

ngdevkit-gngeo が起動して「PMDNEO Phase 1 PoC」 ロゴ画面が表示される。

## 完了基準

- ngdevkit-gngeo で ROM 認識 + 起動画面表示 + 動作不良なし
- user 通読確認(audio gate は無音 PoC のため不要)

## 後続作業

Phase 1 (α) 完了後:

- vendor 取り込み: `pmdneo/vendor/ngdevkit-examples/` に独立配置(現状は外部依存)
- ROM ビルドフローの pmdneo repo 内自己完結化
- Phase 2 で `src/driver/` を新規起こし、 dummy busy loop driver をフルスクラッチ
  driver に置換

並行で Phase 1 (δ) `.m` フォーマット解析が `docs/spec/m_format.md` に文書化される。

## ライセンス

PMDNEO 本体と同じく **GPL-3.0**。 ベース ngdevkit-examples (GPL-3.0) と互換。
