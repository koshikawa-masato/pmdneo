# PMDNEO

NEOGEO で動作する単体のサウンドドライバ + 楽曲コンパイル環境。

KAJA(梶原正裕氏)が PMD V4.8s で公式にソース公開された厚い気持ちと、 同氏の精神を
継承する [PMDDotNET](https://github.com/kuma4649/PMDDotNET) (kuma4649氏作、 GPL-3.0)
を基盤に、 V4.8s 系の MML 文法上位互換を保ちつつ OPNB(YM2610/B) 専用の Z80
driver をフルスクラッチで新規開発し、 NEOGEO homebrew 環境に PMD 系 MML 文化を
持ち込みます。

## 特徴

- NEOGEO で OPNB(YM2610/B) サウンドを鳴らせる単体ドライバ
- ブラウザの WebApp で MML エディタ + コンパイラ + ROM 生成までワンストップ
- WAV → ADPCM-A/B 変換、 FM/SSG 音色エディタ、 MAME ベースのプレビュー機能を内蔵
- ユーザーデータ(MML、 ADPCM、 NEOGEO.ZIP) は zero-knowledge 設計でクライアント側のみ保持

## ターゲットハードウェア

- MAME (エミュレータ)
- AES+ (現代の同人ハード)

元祖 AES、 MVS は対象外です。

## 状態

PMDNEO は、PMDDotNET を基にした MML コンパイル経路と、NEOGEO 向け Z80
サウンドドライバの実装を進めています。

詳しい進捗、設計判断、検証記録は ADR と設計資料に残しています。初めて読む場合は、
まず [ドキュメント入口](docs/README.md) から読んでください。

## ライセンス

- **PMDNEO 本体ソフトウェア** (driver / プレイヤー / WebApp / ビルドスクリプト): [GPL-3.0](LICENSE)
- **IPL** (NEOGEO ハードウェア対応 binary blob): 別配布、 別ライセンス(逆ASM/改変禁止、 PMDNEO 構築用途のみ使用可)
- **ユーザーが WebApp で生成した楽曲ROM**: 楽曲作成者(ユーザー)に著作権帰属。 PMDNEO 作成者は権利主張せず、 損害・賠償責任も負わない

詳細は [LICENSE](LICENSE) を参照してください。

## 著作権者

- 越川将人 (M.Koshikawa.)

## 関連プロジェクト

- [PMDDotNET](https://github.com/kuma4649/PMDDotNET) — PMD の .NET 移植版、 PMDNEO の MML コンパイラ移植のベース(GPL-3.0)
- [ngdevkit](https://github.com/dciabrin/ngdevkit) — NEOGEO homebrew 開発キット、 起動画面ロゴ参考

## ドキュメント

| ドキュメント | 用途 |
|---|---|
| [ドキュメント入口](docs/README.md) | まず読む場所 |
| [PMDNEO の概要](docs/guide/pmdneo-overview.md) | プロジェクトの全体像 |
| [構成マップ](docs/guide/architecture-map.md) | MML、曲データ、ドライバ、検証環境の関係 |
| [開発の進め方](docs/guide/development-workflow.md) | 設計、実装、検証の流れ |
| [検証ガイド](docs/guide/verification-guide.md) | byte 比較、trace、MAME 録音、試聴の考え方 |
| [ADR の読み方](docs/guide/adr-reading-guide.md) | 長い ADR を読むときの入口 |
