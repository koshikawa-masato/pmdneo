# PMDNEO documentation

この `docs/` は、人が読んで PMDNEO の現在の設計と使い方を理解するための公開資料置き場です。

過去の開発中は、ChatGPT や Codex と長い文脈を共有するために、ADR や handoff に非常に高密度な作業記録を書いていました。あの形式は、AI と開発を継続するために必要な作業台です。

一方で、そのままでは人との共同作業や公開資料の入口としては重すぎます。そのため、AI協働用ADRは継続しつつ、人間向けの平易なガイドを別に作ります。

今後の `docs/` では、次の方針を優先します。

- まず結論を書く
- 1文を短くする
- PMDNEO 固有の作業ログを本文に混ぜすぎない
- 検証ログ、trace、commit列は本文ではなく詳細資料へ分ける
- 「何を決めたか」「なぜそうしたか」「今どう使うか」を中心に書く

## 読む場所

初めて読む場合は、まず `docs/guide/` から入ってください。

| 文書 | 用途 |
|---|---|
| [PMDNEO の概要](guide/pmdneo-overview.md) | PMDNEO が何を作るプロジェクトかを知る |
| [構成マップ](guide/architecture-map.md) | MML、`.MN`、`.PNE`、Z80 ドライバ、MAME 検証の関係を知る |
| [ADR の読み方](guide/adr-reading-guide.md) | 既存 ADR をどう読めばよいかを知る |
| [開発の進め方](guide/development-workflow.md) | 設計、実装、検証、handoff の流れを知る |
| [検証ガイド](guide/verification-guide.md) | byte 比較、trace、MAME 録音、試聴の役割を知る |
| [人が読むためのドキュメント方針](guide/writing-for-humans.md) | 公開 docs の文体方針を知る |
| [ドキュメント分類ルール](guide/document-classification.md) | 公開 docs と内部資料の分け方を知る |

## ディレクトリ

| 場所 | 役割 |
|---|---|
| `docs/design/` | 現在有効な設計資料 |
| `docs/spec/` | ファイル形式やデータ形式の仕様 |
| `docs/adr/` | 設計上の意思決定記録と AI協働用ログ |
| `docs/guide/` | 開発者向けの読み方、書き方、作業方針 |
| `docs/manual/` | 参照用の外部仕様や移植元資料 |

## 内部資料との分離

AI協働用ADRとして必要な作業ログや検証証跡は、これまで通り `docs/adr/` に残してよいです。

ADR にする前の未整理メモ、公開資料へ移す前の下書き、長い一時ログは `internal-docs/` に置きます。

`internal-docs/` は git 管理外です。必要な内容だけを、人が読める形に要約して `docs/` へ移します。

## ADR の扱い

PMDNEO の `docs/adr/00xx-*.md` は、通常の短い ADR だけではありません。

多くの ADR は、Claude Code、ChatGPT、Codex と開発を続けるための AI協働用ログも兼ねています。この運用は今後も継続します。

AI協働用ADRには、壁打ち、判断経緯、verify gate、audio gate、trace、commit chain を含めてよいです。これらを勝手に削除したり短縮したりしません。

人間向けdocsを作る場合は、既存ADRを元資料として保持したまま、別ファイルで短く平易に要約します。
