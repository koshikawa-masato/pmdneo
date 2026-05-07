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

設計書 3 種完成 + Phase 1 PoC ビルドフロー検証済 (2026-05 現在)。 Phase 2
driver 実装着手準備完了。

- Phase 1 (α): NEOGEO ROM ビルドフロー検証完了 (= [docs/poc-build.md](docs/poc-build.md) 参照)
- Phase 1 (δ): `.m` バイナリ format 解析 v3 完了 (= [docs/design/analysis_m_data_structure.md](docs/design/analysis_m_data_structure.md))
- Phase 2 着手前 設計書 3 種完成 (= 計 2296 行):
  - [docs/design/mn_binary_layout.md](docs/design/mn_binary_layout.md) (`.mn` binary layout 仕様)
  - [docs/design/ppz_to_adpcma_mapping.md](docs/design/ppz_to_adpcma_mapping.md) (PPZ → ADPCM-A 翻訳 mapping)
  - [docs/design/phase2_driver_plan.md](docs/design/phase2_driver_plan.md) (Phase 2 driver 実装計画)

全体設計は [docs/design/PMDNEO_DESIGN.md](docs/design/PMDNEO_DESIGN.md) 参照。

## ライセンス

- **PMDNEO 本体ソフトウェア** (driver / プレイヤー / WebApp / ビルドスクリプト): [GPL-3.0](LICENSE)
- **IPL** (NEOGEO ハードウェア対応 binary blob): 別配布、 別ライセンス(逆ASM/改変禁止、 PMDNEO 構築用途のみ使用可)
- **ユーザーが WebApp で生成した楽曲ROM**: 楽曲作成者(ユーザー)に著作権帰属。 PMDNEO 作成者は権利主張せず、 損害・賠償責任も負わない

詳細は [LICENSE](LICENSE) およびドキュメント [docs/design/PMDNEO_DESIGN.md §1-9](docs/design/PMDNEO_DESIGN.md) 参照。

## 著作権者

- 越川将人 (M.Koshikawa.)

## 関連プロジェクト

- [PMDDotNET](https://github.com/kuma4649/PMDDotNET) — PMD の .NET 移植版、 PMDNEO の MML コンパイラ移植のベース(GPL-3.0)
- [ngdevkit](https://github.com/dciabrin/ngdevkit) — NEOGEO homebrew 開発キット、 起動画面ロゴ参考

## ドキュメント

| ドキュメント | 用途 |
|---|---|
| [`docs/design/PMDNEO_DESIGN.md`](docs/design/PMDNEO_DESIGN.md) | 全体設計書(章1-2 完成、 章3 = 設計書 3 種 index 完成、 章4-6 は壁打ち継続) |
| [`docs/design/analysis_m_data_structure.md`](docs/design/analysis_m_data_structure.md) | `.m` バイナリ format 解析 (Phase 1 (δ) v3 完了、 1377 行) |
| [`docs/design/mn_binary_layout.md`](docs/design/mn_binary_layout.md) | `.mn` binary layout 仕様 (Phase 2 着手前 設計書 1) |
| [`docs/design/ppz_to_adpcma_mapping.md`](docs/design/ppz_to_adpcma_mapping.md) | PPZ → ADPCM-A 翻訳 mapping (Phase 2 着手前 設計書 2) |
| [`docs/design/phase2_driver_plan.md`](docs/design/phase2_driver_plan.md) | Phase 2 driver 実装計画 (Phase 2 着手前 設計書 3) |
| [`docs/poc-build.md`](docs/poc-build.md) | Phase 1 PoC ビルド手順 |
| [`docs/manual/PMDMML_MAN_V48s_utf8.txt`](docs/manual/PMDMML_MAN_V48s_utf8.txt) | PMD V4.8s 公式マニュアル(参照、 W コマンド等補完追記済) |
| [`docs/adr/`](docs/adr/) | 設計判断記録(順次起票) |
| [`vendor/pmd48s/`](vendor/pmd48s/) | PMD V4.8s 公式 source(GPL-3.0、 PMDDotNET 移植参照) |
| [`vendor/ngdevkit-examples/`](vendor/ngdevkit-examples/) | ngdevkit-examples (GPL-3.0、 PoC ビルドベース、 [VENDOR_INFO.md](vendor/ngdevkit-examples/VENDOR_INFO.md) 参照) |
