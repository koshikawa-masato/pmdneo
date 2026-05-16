# ADR

ADR は Architecture Decision Record、つまり設計上の意思決定の記録です。

PMDNEO の既存 ADR には、意思決定だけでなく作業ログ、検証証跡、AI 向けの圧縮メモも多く含まれています。

これは失敗ではありません。PMDNEO では、ADR が Claude Code、ChatGPT、Codex と開発を継続するための作業台も兼ねています。

## 今後のADR方針

AI協働用ADRの運用は継続します。

ADR には、必要に応じて次を含めてよいです。

- 何を決めたか
- なぜ決めたか
- 採用案と不採用案
- scope-in / scope-out
- verify gate
- audio gate
- trace 結果
- commit ごとの作業記録
- AI との壁打ち記録

人間向けに読みやすい説明が必要な場合は、既存ADRを短縮するのではなく、`docs/guide/` に別の要約文書を作ります。

## 既存ADRの読み方

初期 ADR は比較的短く、そのまま読めます。

ADR-0026 以降は、PMDNEO の実装検証を進めるために高密度化しています。読むときは、まず冒頭、`## 決定`、`## scope-in / scope-out`、`## 完了判定` を確認してください。

詳細な証跡まで必要な場合だけ、Annex や handoff を参照します。

既存ADRを削除、移動、短縮、全面書き換えする場合は、必ず事前にユーザー確認を取ります。
