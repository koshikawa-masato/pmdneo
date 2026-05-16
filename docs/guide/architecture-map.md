# PMDNEO 構成マップ

この文書は、PMDNEO の主要な部品とデータの流れを説明します。

詳しい仕様は設計書を参照してください。この文書では、全体のつながりを理解することを優先します。

## 全体像

PMDNEO の基本的な流れは次の通りです。

```text
MML
  |
  v
PMDDotNET ベースのコンパイラ
  |
  v
.MN 曲データ  +  .PNE サンプルパック
  |
  v
NEOGEO ROM
  |
  v
Z80 サウンドドライバ
  |
  v
YM2610 / YM2610B
  |
  v
音
```

## 主要な部品

| 部品 | 主な場所 | 役割 |
|---|---|---|
| MML コンパイラ | `vendor/PMDDotNET/` | MML を曲データへ変換する |
| PMDNEO ドライバ | `src/driver/` | NEOGEO の Z80 上で曲を再生する |
| テスト用 MML | `src/test-fixtures/` | 検証用の小さな曲データを置く |
| ビルドスクリプト | `scripts/` | ROM 生成や検証を補助する |
| ADPCM 資産 | `assets/` | サンプルパックや音声素材を置く |
| 設計資料 | `docs/design/` | 現在有効な設計を説明する |
| ADR | `docs/adr/` | 判断経緯や作業ログを残す |

## 曲データの役割

PMDNEO では、曲データとして `.MN` を使います。

`.MN` は、既存 PMD の `.M` 形式を尊重しつつ、PMDNEO に必要な拡張を後ろに足す方針です。

この方針により、既存形式との関係を保ちながら、ADPCM-A 6ch などの PMDNEO 固有機能を扱えるようにします。

詳しくは [`.MN` 仕様](../design/mn_binary_layout.md) を参照してください。

## サンプルパックの役割

ADPCM-A の音声素材は `.PNE` にまとめます。

`.PNE` は、PMDNEO 用の ADPCM-A サンプルパックです。複数のサンプルをまとめ、ドライバが使いやすい形で配置するための形式です。

詳しくは [`.PNE` 仕様](../design/pne_binary_layout.md) を参照してください。

## Z80 ドライバの役割

Z80 ドライバは、曲データを読み、YM2610/YM2610B のレジスタへ値を書きます。

主な領域は次の通りです。

| ファイル | 役割 |
|---|---|
| `src/driver/standalone_test.s` | 現在の検証で中心になるドライバ入口 |
| `src/driver/PMDNEO.s` | PMDNEO ドライバ本体の入口候補 |
| `src/driver/ADPCMA_DRV.inc` | ADPCM-A 関連処理 |
| `src/driver/ADPCMB_DRV.inc` | ADPCM-B 関連処理 |
| `src/driver/WORKAREA.inc` | 作業領域定義 |
| `src/driver/REGMAP.inc` | レジスタ定義 |

歴史的な理由により、すべてのファイルが常に同じ重要度ではありません。現在どの経路が本線かは、設計書と直近の ADR を確認してください。

## 検証の流れ

PMDNEO では、単にビルドできるだけでは完了にしません。

主に次の方法で確認します。

```text
ビルドできる
  |
  v
曲データやROMが期待通り
  |
  v
trace でレジスタ書き込みを確認
  |
  v
MAME で録音
  |
  v
必要に応じて人が試聴
```

検証の考え方は [検証ガイド](verification-guide.md) を参照してください。

## ADR と設計書の関係

設計書は、現在有効な構造や仕様を説明します。

ADR は、なぜその判断になったか、どの案を採用しなかったか、どう検証したかを記録します。

PMDNEO では、ADR が AI 協働用の高密度ログも兼ねています。そのため、初めて読む場合は設計書やこのガイドから入り、必要になったときだけ ADR を読むのが現実的です。
