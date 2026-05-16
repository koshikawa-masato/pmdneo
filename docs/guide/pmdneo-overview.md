# PMDNEO の概要

この文書は、PMDNEO を初めて読む人のための入口です。

詳しい設計や判断履歴は、既存の設計書や ADR に残しています。この文書では、まず全体像を短く説明します。

## PMDNEO とは

PMDNEO は、NEOGEO で PMD 系の MML を鳴らすためのサウンドドライバと制作環境です。

PMD は、かつて PC-98 などで使われた MML 音楽環境です。PMDNEO はその文化を、NEOGEO の音源である YM2610/YM2610B 向けに持ち込むことを目指しています。

PMDNEO では、次のものを扱います。

- PMD 系 MML
- PMDDotNET を基にした MML コンパイル経路
- NEOGEO 上で動く Z80 サウンドドライバ
- YM2610/YM2610B の FM、SSG、ADPCM-A、ADPCM-B
- MAME を使った動作確認
- 将来の WebApp 制作環境

## 何を作っているか

PMDNEO は、大きく分けて次の部品で構成されます。

| 部品 | 役割 |
|---|---|
| MML コンパイラ | PMD 系 MML を曲データへ変換する |
| `.MN` 曲データ | PMDNEO 用の曲データ形式 |
| `.PNE` サンプルパック | ADPCM-A サンプルをまとめる形式 |
| Z80 ドライバ | NEOGEO のサウンド CPU 上で曲を再生する |
| MAME 検証環境 | 実行結果を trace や録音で確認する |
| WebApp | 将来の制作、変換、プレビュー環境 |

## PMDDotNET との関係

PMDNEO は、PMDDotNET を重要な基盤として使います。

PMDDotNET は、PMD の .NET 移植版です。PMDNEO では、PMDDotNET の MML 解釈や既存の PMD 文法を尊重しながら、NEOGEO 向けに必要な拡張を加えます。

PMDNEO の方針は、PMD 文化を壊さずに、出力先を OPNB、つまり YM2610/YM2610B の世界へ広げることです。

## NEOGEO との関係

NEOGEO では、音を鳴らすために Z80 CPU と YM2610/YM2610B 音源を使います。

PMDNEO のドライバは、この Z80 側で動きます。MML から作った曲データを読み、YM2610/YM2610B のレジスタへ書き込むことで音を鳴らします。

開発中の確認には、主に MAME を使います。

## ファイル形式

PMDNEO では、主に次の形式を扱います。

| 形式 | 意味 |
|---|---|
| `.M` | 既存 PMD 系の曲データ |
| `.MN` | PMDNEO 用の曲データ |
| `.PNE` | PMDNEO 用の ADPCM-A サンプルパック |
| `.MML` | 人が書く楽曲テキスト |

詳しい仕様は、次を参照してください。

- [`.M` 仕様](../spec/m_format.md)
- [`.MN` 仕様](../design/mn_binary_layout.md)
- [`.PNE` 仕様](../design/pne_binary_layout.md)

## ドキュメントの読み方

PMDNEO の既存 ADR には、AI と開発を継続するための高密度な記録が多く含まれています。

そのため、最初から ADR を全部読む必要はありません。

最初は次の順で読むのがおすすめです。

1. この文書
2. [構成マップ](architecture-map.md)
3. [開発の進め方](development-workflow.md)
4. [検証ガイド](verification-guide.md)
5. 必要に応じて [ADR の読み方](adr-reading-guide.md)

## 重要な考え方

PMDNEO では、設計判断を文書に残すことを重視しています。

ただし、文書には2種類あります。

- AI と開発を進めるための高密度な記録
- 人が読むための平易な説明

既存の ADR は主に前者です。今後は、この `docs/guide/` に後者を増やしていきます。
