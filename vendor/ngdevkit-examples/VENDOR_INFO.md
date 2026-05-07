# vendor/ngdevkit-examples 取込履歴

## 取込元

- 上流 repo: https://github.com/dciabrin/ngdevkit-examples
- 著作: Damien Ciabrini氏 (Copyright (c) 2015-2025)
- license: GPL-3.0 (PMDNEO 本体と同一)
- 取込時の上流 commit: `97a4978b5778e59fafc67ab872815c14d3e883d1` (= "Fix errors and bad links in README.md")
- 取込日: 2026-05-07

## 取込方法

`git archive HEAD | tar -x` で **tracked file のみ** sub-tree として取込
(.git ディレクトリ + build artifact 全て除外、 上流 .gitignore を尊重)。

```bash
cd <upstream-clone>
git archive HEAD | tar -x -C <pmdneo>/vendor/ngdevkit-examples
```

108 KB / 110 file 規模 (= 上流 git tracked file のみ)。

## PMDNEO 側の改造

- `00-template/main.c`: PMDNEO Phase 1 PoC 用 (起動画面に「PMDNEO Phase 1
  PoC」 を表示) に上書き。 上流の `NGDEVKIT TEMPLATE ROM` 表示は捨てた。
  PMDNEO 用 main.c の本体は本 file (= vendor/ngdevkit-examples/00-template/main.c)
  に集約、 src/poc/main.c は削除。

その他の example (01-helloworld 〜 18-memory-card) は **上流のまま**温存
(= 参考実装として読める形を保持、 PoC build には使わない)。 特に `06-sound-adpcma`
/ `15-sound-adpcmb` / `16-sound-music` は Phase 2 driver 実装時の register
操作の参考実装として活用予定。

## 上流追従方針

- 上流の Damien Ciabrini氏は GPL-3.0 で公開、 PMDNEO の派生改造は GPL-3.0
  互換を維持
- 上流に大きな更新があった場合は手動で sub-tree を取り直す (= sub-tree
  merge コマンドや `git subtree pull` ではなく、 `git archive` ベースの
  単純 copy)
- 取り直す際は本 file の「取込時の上流 commit」 + 「取込日」 を更新

## license

ngdevkit-examples は GPL-3.0。 PMDNEO 本体も GPL-3.0 で互換。 上流 license
file は `<example>/LICENSE` に各 example で同梱されているのでそのまま温存。
