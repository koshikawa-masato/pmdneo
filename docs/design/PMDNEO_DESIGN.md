# PMDNEO 設計書

	2026-05-07 起票
	著作権者: 越川将人 (M.Koshikawa.)
	ライセンス方針: 本文書末尾参照
	書式: PMDMML.MAN(V4.8s 公式マニュアル)準拠

---

## 概要

PMDNEO は、 NEOGEO で動作する単体のサウンドドライバである。 Neo-Sisters
専用に開発された PMDAES と異なり、 スタンドアロンで基本的な BIOS と独自の
サウンド再生プレイヤーをセットにすることで、 誰しもが NEOGEO で OPNB
(YM2610/B) サウンドを鳴らせる MML ベースの書式データをコンパイルする環境を
提供する。

KAJA(梶原正裕氏)が PMD V4.8s で公式にソース公開された厚い気持ちと、 同氏
の精神を継承する PMDDotNET(kuma4649氏作、 GPL-3.0)を基盤に、 V4.8s 系の
MML 文法上位互換を保ちつつ OPNB(YM2610/B) 専用の Z80 driver をフルスクラッチ
で新規開発する。 PMD88(PC-88 V3.9) との互換性は明示的に捨てる(§1-2-1 参照)。

---

## 章構成

1. プロジェクト位置付け (本章)
2. 段階的進化計画(機能カバレッジ型 Phase)
3. 各 Phase のゴール / deliverable / 完了基準
4. 互換性維持戦略
5. ドキュメント構造
6. 既存資産の位置付け

---

# §1 プロジェクト位置付け

## §1-1 PMDNEO とは

NEOGEO で動作する単体のサウンドドライバ + 楽曲コンパイル環境。

	定義(一行): NEOGEO で OPNB サウンドを鳴らせる MML ベースの書式データを
	         コンパイルする環境を、 誰でも使えるよう提供する単体サウンド
	         ドライバ。

PMDAES(旧 Neo-Sisters専用ドライバ、 ngdevkit に embedded)と異なる点:

- スタンドアロン(楽曲側 ROM に縛られず、 PMDNEO 単独で動作)
- 基本的な BIOS(IPL 相当)を独自実装(NEOGEO 純正 BIOS 上で動作)
- 独自のサウンド再生プレイヤーをセット

## §1-2 動機・背景

- KAJA(梶原正裕氏)による PMD V4.8s 公式ソース公開の精神を継承
- PMDDotNET(kuma4649氏、 GPL-3.0)を基盤に OPNB 仕様化することで、 NEOGEO
  homebrew 環境に PMD 系 MML 文化を持ち込む
- Neo-Sisters 専用 PMDAES の経験を一般化し、 誰でも使える形に再構成

### §1-2-1 PMD88 互換放棄の方針(2026-05-07 確定)

PMDNEO は PMD88(PC-88 V3.9) との互換性を明示的に捨てる。

過去 PMDAES → R2 sprint v1 偽完了 → R2 v2 redesign 偽完了 → B案撤回 という
3段階の失敗の根本原因は「Z80 が共通だから PMD88 driver を流用できる」 という
思い込みだった。 実際には Z80 はただの実装言語であり、 chip 仕様
(panel B 構成、 ADPCM、 内蔵リズム音源 vs ADPCM-A 等) に最適化された driver
設計が必要。

PMDNEO の役割分担:

- **driver(Z80 binary)**: フルスクラッチで新規開発、 PMD88 V3.9 / V4.8s
  driver は起点にしない。 NEOGEO OPNB 専用設計
- **mc compiler**: PMDDotNET(V4.8s 系の .NET 移植) を改良して OPNB 拡張、
  出力は OPNB 準拠の `.mn`(§1-8 参照)
- **MML 文法**: PMDDotNET ベースのため自然と V4.8s 系の文法を上位互換で継承

### §1-2-2 OPNA / OPNB chip 互換性の活用

YM2608(OPNA) と YM2610(OPNB)/YM2610B はほぼ同等のチップで、 違いは:

- ADPCM-A 6ch ↔ 内蔵リズム音源(BD/SD/CYM/HH/TOM/RIM、 ROM固定)
- FM ch 数(YM2610 無印は4ch、 OPNA / YM2610B は6ch)

レジスタ仕様は完全互換で、 同じ driver code が全 chip で動作可能。
A/D ch にデータを書いても破綻せず、 アナログ出力されないだけ。

参照: https://asmpwx.seesaa.net/article/202005article_4.html

PMDNEO 設計含意:

- driver は **YM2610B 仕様(FM 6ch dispatch)で書く**。 同 driver code が
  OPNA / YM2610 / YM2610B 全環境で動作可能
- 楽曲制作者の **A/D 使わない自己規律** = 一般 NEOGEO 環境(YM2610 無印 +
  AES/AES+) で全 ch 鳴る = 実用上必須(YM2610B 実チップ入手困難のため)
- ADPCM-A 6ch は OPNB 専用機能、 内蔵リズム音源(K/R)は OPNA 専用機能
- PMDNEO は **OPNB 専用にとどめ、 K/R(OPNA 内蔵リズム)は実装しない**方針(2026-05-07 確定)

## §1-3 ターゲット利用者

PMDNEO の主要な利用者像は次の通り:

- NEOGEO homebrew 作家(自作 ROM に音楽を載せたい人)
- MML 作曲経験者(PMD V4.8s / V4.8 改訂版 等の経験者)
- WAV 素材から ADPCM-A サンプルを作って NEOGEO 上で鳴らしたい人

利用者は PC / Mac の WebApp だけで完結し、 IPL / driver / プレイヤー /
ROM ビルドフローは PMDNEO 側が全部用意する。

## §1-4 ターゲットハードウェア

PMDNEO がターゲットとするハードウェア:

| 環境 | 想定用途 | 優先度 |
|---|---|---|
| MAME (エミュレータ) | 開発・テスト・配布で多用、 fmgen 等 OPNB エミュ対応済 | 主戦場 |
| AES+ (現代の同人ハード) | 実機相当の動作環境 | 主戦場 |
| AES (元祖SNK NEOGEO家庭用) | 対象外 | - |
| MVS (アーケード基板) | 対象外 | - |

画面エミュレートは MAME ベースを WebApp に組み込む形で実現する。

## §1-5 システム構成

### §1-5-1 PMDNEO ROM(NEOGEO カートリッジ ROM)

PMDNEO ROM は次のコンポーネントから構成される:

	IPL (起動コード)
	  ↓
	起動画面ロゴ表示
	  ↓
	サウンドドライバ (Z80 + OPNB(YM2610/B))
	  ↓
	再生プレイヤー
	  ↓
	楽曲データ領域

ROM 内コンポーネント詳細:

- IPL: PC-88 の IPL 相当の最小限初期化(サウンド・テキスト・グラフィック
  の初期化のみ)。 越川将人氏が新規作成するオリジナル。
- 起動画面: ngdevkit ロゴ風の独自起動画面。 純正 NEOGEO ロゴは AES /
  AES+ 上で表示しない(SNK ライセンスの関係)。
- サウンドドライバ: OPNB(YM2610/B)を駆動する Z80 ドライバ。 PMDDotNET 派生
  の MMLコンパイラ出力 binary を解釈する。
- 再生プレイヤー: 楽曲選択 / 再生制御の最小限 UI。 V1 と V2 で機能段階
  あり(後述§1-7)。
- 楽曲データ領域: WebApp で生成された楽曲 binary + ADPCM-A サンプル。

### §1-5-2 WebApp(楽曲制作環境)

WebApp は PC / Mac のブラウザで動作し、 楽曲制作・コンパイル・ROM 出力
の全工程をカバーする:

	[利用者ブラウザ]                          [VPS サーバ]
	+----------------------------+        +----------------+
	| MML エディタ              |        | PMDNEO本体ソース|
	| プレビュー (MAMEベース)    | <----> | IPL バイナリ    |
	| WAV→ADPCM-A/Bコンバータ   |        | MMLコンパイラ   |
	| FM/SSG音色エディタ        |        | (PMDDotNET派生) |
	| ビルド + 即時プレビュー    |        | ROM テンプレ    |
	| リリースファイル生成      |        +----------------+
	|                            |
	| [クライアント側のみ保持]  |
	| ・MMLデータ                |
	| ・ADPCMデータ              |
	| ・NEOGEO.ZIP(ユーザー自前) |
	+----------------------------+

データフロー方針:

- サーバはコピーライトの関係で「渡してはいけない情報」(PMDNEO本体実装、
  IPL バイナリ等)を提供
- ユーザー著作物(MMLデータ、 ADPCM データ、 NEOGEO.ZIP)はクライアント側
  のみで保持。 サーバには送信せず、 サーバには保存しない
- = zero-knowledge 寄りの設計、 ユーザーデータ漏洩リスク回避

## §1-6 起動シーケンス

	1. NEOGEO 起動 → 純正BIOS(ユーザー用意)
	2. カートリッジ ROM 起動
	3. PMDNEO IPL → ハードウェア最小初期化
	   (サウンド・テキスト・グラフィック)
	4. 起動画面ロゴ表示(ngdevkit風、 純正NEOGEOロゴ非表示)
	5. サウンドドライバ初期化(OPNB レジスタ初期値設定)
	6. 再生プレイヤー起動(V1: 楽曲選択UI)
	7. 楽曲データ読み込み → 再生

## §1-7 再生プレイヤーの段階

- V1: 楽曲名表示、 楽曲選択再生(最小機能)
- V2: レベルメーター、 ミュート機能(機能追加版)

開発順序: V1 でしばらく運用 → WebApp 公開後の改変期間で V2 を実装。

## §1-8 ファイル形式

### §1-8-1 拡張子一覧(PMD ファミリ + PMDNEO)

| 拡張子 | 種別 | 用途 |
|---|---|---|
| `.m` | 曲データ | PMD用の曲データ |
| `.m2` | 曲データ | PMDB2 / PMD86用の曲データ |
| `.mz` | 曲データ | PMDPPZ用の曲データ |
| **`.mn`** | 曲データ | **PMDNEO 用の曲データ**(本プロジェクトで新規定義) |
| `.PPS` | PCMデータ | PPSDRV用のPCMデータ |
| `.PPC` | PCMデータ | PMDB2用のPCMデータ |
| `.P86` | PCMデータ | PMD86用のPCMデータ |
| `.PVI` | PCMデータ | FMP用のPCMデータ |
| `.PZI` | PCMデータ | PMDPPZ用のPCMデータ |
| **`.PNE`** | PCMデータ | **PMDNEO 用のPCMデータ**(ADPCM-A サンプルパック、 本プロジェクトで新規定義) |

PMDNEO 命名規則:

- 曲データ: `.m` 系(小文字、 1〜2文字、 末尾識別子)に倣って `.mn`(n = NEO)
- PCM データ: `.PXX` 系(大文字、 3文字)に倣って `.PNE`(NE = NEO)

(参考: PMDB2.COM、 PMD86.COM はいずれも PC-98 用 x86 アーキテクチャ実行
ファイル。 違いは OPNA ボードの ADPCM 用 DRAM 搭載有無で、 PMDB2 が DRAM
搭載ボードでネイティブ ADPCM 駆動、 PMD86 が DRAM なしで PC-98 PCM 出力
経路によるリアルタイム変換。 PMD V4.8s 公式の Z80 binary は存在しない)

### §1-8-2 `.mn`(PMDNEO 曲データ)の仕様

- mc compiler(PMDDotNET 改良版) が出力する楽曲 binary
- V4.8s `.m` の dispatch table 構造を可能な限り維持(V4.8s 系ツールとの
  部分相互運用を意識) + OPNB 専用 dispatch entry 拡張
- driver(PMDNEO 専用 Z80 binary) が解釈して OPNB(YM2610/B)を駆動する

#### 設計方針: OPNA バイナリ互換 + PMDPPZ 風後方拡張

`.mn` の binary layout は **OPNA 標準 `.m` と完全互換のベース**を温存し、
PMDPPZ の `.mz` が PPZ8 拡張を後方領域に追加する流儀をそのまま踏襲する:

- 前 26 byte header(11 part offset table + rhythm address table offset
  + prgdat_adr)を `.m` と同じ位置に配置
- K/R パート関連の workarea / アドレス指定領域も OPNA layout 通り確保
  (driver 側で K/R 解釈 routine は no-op stub 化、 chip 書込なし)
- ADPCM-A 6ch 用の拡張 part offset / sample table 等は **header 後方に
  PMDPPZ 風の追加領域として並べる**(具体 layout は PMDDotNET の `.mz`
  実装を実体参照で確定)

#### 互換性の効用

この設計により:

- **既存 OPNA `.m` を PMDNEO driver でそのまま再生可能** (FM 6ch / SSG 3ch
  / ADPCM-B 1ch は鳴る、 K/R 内蔵 rhythm 部分は無音、 誤動作なし)
- mc compiler の OPNA 出力経路は無改造で温存できる(.mn 出力は ADPCM-A
  関連の追加処理だけ)
- PMD V4.8s 系の楽曲資産を PMDNEO 環境に取り込みやすくなる(homebrew
  プロジェクトとしての裾野拡大)

詳細な binary 構造解析は [`analysis_m_data_structure.md`](analysis_m_data_structure.md) (`.m` 解析、 v3 完了) を参照。

### §1-8-3 `.PNE`(PMDNEO ADPCM-A サンプルパック)の仕様

- 内容: ADPCM-A 4bit 18.5kHz Mono の複数サンプルをまとめたもの
- 容量上限: NEOGEO のサウンドROM容量限界(=V-ROM 物理上限)に準拠
- ヘッダ仕様: 既存 PMD 流のサンプルパック構造(`.P86` / `.PPC` を参考)を
  踏襲
- MML 側の参照: `#PNEFile "filename.PNE"` で指定(V4.8s `#コマンド` 系
  と同パターン)
- 使い回し: `.PPC` / `.P86` と同じく、 楽曲間で同じパックを共有可能

### §1-8-4 PMDNEO の入力 / 出力

- **入力(楽曲制作者)**: MML ソース(V4.8s 文法上位互換) + `.PNE` サンプル
  パック + WAV 素材(WebApp で `.PNE` に変換)
- **mc compiler 出力**: `.mn`(楽曲 binary)
- **driver が解釈**: `.mn` + `.PNE` を読み込んで OPNB(YM2610/B)を駆動
- **WebApp 最終出力**: NEOGEO ROM(MAME 用 zip / 実機用生 ROM)

## §1-9 ライセンス方針

### §1-9-1 PMDNEO 本体ソフトウェア

	driver / プレイヤー / WebApp / ビルドスクリプト = GPL-3.0

	著作権者: 越川将人(本名表記、 著作権は放棄しない)
	コピーレフト精神に従い、 ソース公開・派生物継続を保障する。

### §1-9-2 IPL

	配布形式: バイナリのみ(ソース非公開)
	ライセンス: 越川将人の独自ライセンス
	  - 逆アセンブル禁止
	  - 改変禁止
	  - 転載・別用途使用禁止
	  - PMDNEO 構築用途のみ使用可

### §1-9-3 ユーザーが WebApp で生成した楽曲ROM

	著作権: 楽曲作成者(ユーザー)に帰属
	WebApp 作成者(越川将人)の権利主張: なし
	WebApp 作成者の損害・賠償責任: 負わない

### §1-9-4 ライセンス組み合わせの法的整理

GPL-3.0(派生物全体に GPL を要求)と IPL改変禁止 が同一プロジェクト内で
共存するため、 配布レベルでの切り分けを行う:

- PMDNEO 本体 repo(GPL-3.0): driver / プレイヤー / WebApp / ビルドスク
  リプト のソース公開
- IPL 別配布(GitHub Releases or 独立 repo): バイナリ単体提供、 改変禁止
  ライセンス
- ROM ビルド時: WebApp が IPL バイナリを取得し、 PMDNEO 本体とリンクして
  1 個の ROM 出力
- LICENSE / README で明記: 「IPL は NEOGEO ハードウェア対応用 binary blob
  として位置付け、 PMDNEO 本体 GPL-3.0 とは別ライセンス」

この切り分けにより、 KAJA(梶原)氏のソース公開精神 と PMDDotNET の GPL-3.0
コピーレフト精神 を維持しつつ、 IPL の独自権利保護も実現する。

### §1-9-5 利用範囲

	私用・商用利用ともに認める。 ユーザーが PMDNEO で生成した楽曲ROM の
	配布は完全に自由(GitHub / 個人サイト / 同人イベント / 実機再生 等、
	すべて OK)。

## §1-10 配布形態

### §1-10-1 PMDNEO 本体ソース

GitHub repo で公開、 ライセンス GPL-3.0。 KAJA 梶原氏の精神に従い、 派生
物作成・改変・再配布を保障する場として機能。

### §1-10-2 WebApp

VPS サーバ上で別ホスティング、 専用ドメイン取得。

VPS 構成:

- ホスティング事業者: Sakura VPS(さくらインターネット)
- OS: Ubuntu 24.04 LTS amd64
- リージョン: 大阪第3
- スペック: 2GB RAM、 200GB ストレージ

### §1-10-3 IPL

GitHub Releases または独立 repo でバイナリ単体配布。 ライセンスは独自
(逆ASM/改変禁止、 PMDNEO 構築用途のみ使用可)。

### §1-10-4 ユーザー作成楽曲ROM

ユーザーの自由配布(運営側は関与しない)。

## §1-11 著作権者表記

公式記載で使用する表記:

- 日本語: 越川将人
- 英語: M.Koshikawa.

LICENSE / README / 設計書 / GitHub repo / WebApp UI(英語)等、 すべての
公式記載でこの表記を統一する。

## §1-12 開発技術スタック方針

### §1-12-1 MML コンパイラ

PMDDotNET (https://github.com/kuma4649/PMDDotNET、 GPL-3.0) をベースに、
OPNB 仕様への拡張を行う。

#### 実装テンプレート: PMDDotNET の PPZ8 経路を流用

PMDDotNET には PMDPPZ (`.mz`) 経路の完成実装が既に存在する:

| file | 行数 | 役割 |
|---|---|---|
| `PMDDotNETDriver/PPZDRV.cs` | 1135 行 | PPZ8 chip 駆動 driver |
| `PMDDotNETDriver/PPZ8em.cs` | 535 行 | PPZ8 chip emulator |
| `PMDDotNETDriver/PPZChannelWork.cs` | 30 行 | PPZ8 channel workarea 構造 |

PMDNEO の ADPCM-A 6ch 拡張は、 これらの PPZ8 module を **read-only 参照
テンプレート**として ADPCM-A 6ch 用に書き換える形で実装する。 PPZ8 が
OPNA に対して「外部 PCM 機構を 4-8 ch 追加」 する位置づけなのに対し、
ADPCM-A は OPNB の「内蔵 PCM 機構を 6 ch 駆動」 する役割で、 dispatch
構造とパート単位制御モデルが直接対応する。

#### OPNB 拡張範囲

- 音源チップ仕様差(OPNA → OPNB): 内蔵リズム音源廃止 → ADPCM-A 6ch、
  ADPCM RAM → ADPCM-B 1ch、 panel B 構成違いへの対応
- MML パート割当の OPNB 構成への再マッピング(K/R workarea は OPNA layout
  互換で温存、 ADPCM-A は PPZ8 風の拡張 part として後方追加)
- ROM 出力形式に NEOGEO ROM 形式を新規追加
- NEOGEO 特有機能(ステレオパン、 `.PNE` ADPCM-A サンプルバンク管理 等)対応

#### 既存 OPNA 出力経路は無改造で温存

OPNA 用 `.m` 出力経路(現行 PMDDotNET の主経路)は無改造で残し、 `.mn`
出力は **追加経路**として実装する。 これで V4.8s OPNA 楽曲との互換性が
mc compiler レベルで保たれる。

### §1-12-2 IPL

最小限の初期化機能のみ実装(サウンド・テキスト・グラフィック)。 越川将人
が Claude Code とともにオリジナル新規作成。

### §1-12-3 WebApp フロントエンド

VPS 上で動作する公開ホスティング型。 WAV → ADPCM 変換、 MML コンパイル、
ROM 生成、 MAME ベースエミュレータによるプレビュー、 リリースファイル生成
を一気通貫でブラウザ内処理する(zero-knowledge 設計、 サーバ送信なし)。

WebApp の機能:

	- MML エディタ
	- プレビュー(MAME ベース、 ブラウザ内エミュレート)
	- WAV → ADPCM-A / ADPCM-B コンバータ
	- FM / SSG 音色エディタ
	- ビルド(ROM 生成)
	- 簡易ビルド後表示(即時プレビュー)
	- リリース用ファイル生成

## §1-13 章1 で残った未確定事項(章2 以降で詰める)

- AES+ への ROM 焼き手順の詳細
- PMDDotNET OPNB 拡張範囲の細部仕様(構想段階)
- V2 機能の詳細仕様
- WebApp の UI ワイヤーフレーム

これらは章2(段階的進化計画)・章3(各Phaseのゴール)・章5(ドキュメント
構造)で順次詰める。

---

# §2 段階的進化計画

## §2-1 Phase 区切りの根拠

PMDNEO は機能カバレッジ型 4 Phase 構造で進化する。 OPNA / OPNB chip 仕様の
互換性(§1-2-2 参照)を活かし、 PoC で動作確認を早期に取った後、 段階的に
フルスクラッチ実装を積み上げる。

設計判断の根拠:

- **FM/SSG レジスタ仕様完全互換**: OPNA(YM2608) と OPNB(YM2610/B) は FM/SSG
  レジスタが完全互換のため、 OPNA 用 driver の dispatch をそのまま OPNB に
  流せば動く想定 (= chip 互換性活用)。 ただし PMD V4.8s の公式 Z80 binary は
  存在せず(PMD86.COM / PMDB2.COM はいずれも PC-98 用 x86 実行ファイル)、
  Phase 1 PoC の具体構成は再検討中(Q32 議論)
- **MAME OPNB エンジンの動作観察**: K/R command も A/D ch も chip / エミュ
  側で適切に無視される(誤動作なし) = driver は OPNA 流儀の dispatch を
  そのまま出して OK
- **過去の R2 sprint 偽完了反省**: 「Z80 共通だから流用できる」 思い込みで
  失敗した経験から、 driver はフルスクラッチで段階的に置換していく(Phase 1
  PoC → Phase 2 自作driver置換)

各 Phase で動作確認できる粒度を維持し、 R2 sprint で起きた「大きいまま実装
して偽完了」 のパターンを回避する。

## §2-2 Phase 1: PoC(ROM ビルドフロー検証 + `.m` フォーマット解析)

### §2-2-1 ゴール

Phase 2 以降の本格実装の出発点として、 次の 2 点を並行で確立する:

1. **NEOGEO ROM ビルドフロー検証**: ngdevkit 等を参考に、 dummy Z80 driver
   を載せた NEOGEO ROM を MAME で起動できる経路を確立する
2. **`.m` フォーマット解析 + 仕様文書化**: PMDDotNET が出力する V4.8s OPNA
   用 `.m` を byte 単位で解析、 Phase 2 driver 実装の仕様基盤として文書化

PMD V4.8s 公式の Z80 binary は存在しないため(PMD86.COM / PMDB2.COM は
PC-98 用 x86)、 driver 動作確認は Phase 2 以降に持ち越す。 Phase 1 では
driver なしで「動作経路」 と「仕様」 を整える。

### §2-2-2 実装範囲

**(α) NEOGEO ROM ビルドフロー側**:

- ngdevkit のセットアップ + sample 検証
- dummy Z80 driver(busy loop または最小限の init code) を NEOGEO ROM
  Z80 領域に配置
- `.m` データ + dummy driver + `.PNE` 領域(将来用、 当面は 空または dummy)
  を NEOGEO ROM 形式にパッケージするビルドスクリプト
- 起動画面ロゴの最小実装(ngdevkit 風、 純正 NEOGEO ロゴ非使用 = §1-5-1
  方針)
- MAME で ROM 認識 + Z80 起動 + 起動画面表示 + 無音状態の確認

**(δ) `.m` フォーマット解析側**:

- 既存 PMDDotNET で V4.8s OPNA 用 `.m` を出力(改造なし)
- 解析題材: `vendor/pmd48s/SAMPLE.M` / `SAMPLE2.M` / `SSGEG_S.M` 等
- 解析対象:
  - dispatch table 構造(opcode → handler entry)
  - part offset table(各 part の MML body 開始位置)
  - opcode 列(音程・音長・音量・LFO・ADPCM 等の各コマンドの byte 表現)
  - 音色データ領域
  - 末尾付加情報(`#コマンド` の反映等)
- 成果物: `docs/design/analysis_m_data_structure.md`(新規) として仕様書化

### §2-2-3 完了基準

**(α) ROM ビルドフロー側**:

- dummy NEOGEO ROM が MAME で正常起動する(= ROM 認識、 Z80 起動、 起動画面
  表示、 動作不良なし、 純正 NEOGEO ロゴ非表示)
- ビルドスクリプトが GitHub repo で再現実行可能(= 設計書 §1-10 の配布フローの
  最小骨格)
- ngdevkit のサウンド経路を最低限把握できている(Phase 2 driver 実装で再利用)

**(δ) `.m` フォーマット解析側**:

- `docs/design/analysis_m_data_structure.md` に次の項目が文書化されている:
  - `.m` の binary 構造 全体図(m_start + m_buf header 24 byte + part body)
  - dispatch table 3 種類(cmdtbl / cmdtblp / cmdtblr)の opcode → handler
    完全マップ(全 79 entry × 3 種)
  - 各 opcode の byte 列フォーマット(handler 別引数 byte 数 ~75 個判明)
  - part offset table の構造(11 part × 2 byte LE)
  - 音色データ format(prgdat 26 byte / tondat 32 byte 経路、 register
    slot 順 OP1, OP3, OP2, OP4)
  - Rhythm part 2 段構造(R part body + radtbl + rhythm pattern body)
  - opcode 0x00〜0x7F の音程 + 音長解釈(OCT 4 bit + ONKAI 4 bit + 1 byte
    length)
  - 0xC0 sub-dispatch(comtbl0c0h)構造
- Phase 2 で driver を実装する際、 本仕様書を読めば dispatch ループ + 主要
  routine が書ける詳細度

### §2-2-4 規模感

1〜2 週間。 (α) と (δ) は独立して並行進行可能。

- (α) ROM ビルドフロー: 数日〜1 週間(ngdevkit セットアップ含む)
- (δ) `.m` フォーマット解析: 1 週間

両者完了で Phase 2 の出発点(= 動作経路 + 仕様基盤) が揃う。

## §2-3 Phase 2: ベースライン driver(`.m` / `.m2` 100% 再現)

### §2-3-1 ゴール

PMDNEO driver の **ベースライン部分**(OPNA 互換相当 = FM/SSG/ADPCM-B)
を Z80 フルスクラッチで完成させ、 既存 PMDDotNET 出力の OPNA 用 `.m`
(FM/SSG)および `.m2`(FM/SSG + ADPCM RAM = ADPCM-B 1ch)を **100% 再現
する Z80 driver** として動作させる。

Phase 3 で ADPCM-A 6ch 拡張(PPZ → ADPCM-A 置換)を統合する出発点として
完成させる。

vendor/pmd48s/source/pmd48s/PMD.ASM(10864 行 x86 アセンブリ) を仕様書として
読み、 NEOGEO Z80 サブ CPU 用に書き起こす移植作業が中心。

`.m` バイナリの format 解析は Phase 1 (δ) で先行完了済(参照:
[`docs/design/analysis_m_data_structure.md`](analysis_m_data_structure.md)、 v3 完了)。 Phase 2 ではこの仕様基盤を Z80 driver 実装に
落とし込む。

#### 実装パスの構造: PMDPPZ build pattern を踏襲

PMD V4.8s には拡張 module を本体に統合する build 構造が既に組まれている:

```asm
; PMDPPZ.ASM (V4.8s 公式、 16 行のみ)
board2  equ 1     ; OPNA + ADPCM RAM
adpcm   equ 1
ppz     equ 1     ; + PPZ8 拡張
        include PMD.ASM   ; 10864 行 base driver

; → PMDPPZ.COM 出力(OPNA + ADPCM RAM + PPZ8 統合 driver)
```

PMD.ASM 内に `if board2`(YM2608 用)、 `if board2*adpcm`(ADPCM RAM 用)、
`if ppz`(PPZ8 統合用、 約 10 箇所)の conditional 分岐が既に組まれている。
PMDNEO はこの build pattern を翻訳する形で:

```asm
; PMDNEO.ASM (新規、 仮称)
neogeo  equ 1     ; YM2610/B chip flag
adpcma  equ 1     ; ADPCM-A 6ch 拡張(Phase 3 で有効化)
adpcmb  equ 1     ; ADPCM-B 1ch
        include PMD_Z80.ASM   ; PMD.ASM の Z80 化版
```

を Phase 2 で起こす。 Phase 2 段階では `adpcma` を無効化し、
`neogeo + adpcmb` 相当のベースラインを完成させる。

### §2-3-2 実装範囲

- **driver フルスクラッチ実装(ベースライン)**:
  - `.m` / `.m2` 解釈ループ(V4.8s 互換 dispatch table 構造、 擬似コードは
    analysis_m_data_structure.md §5-5 / §5-6-5)
  - dispatch table 3 種類(cmdtbl / cmdtblp / cmdtblr、 各 79 entry)
  - FM 6ch dispatch(YM2610B 仕様、 register slot 順 OP1, OP3, OP2, OP4)
  - SSG 3ch dispatch
  - **ADPCM-B 1ch dispatch**(`.m2` の OPNA ADPCM RAM 経路を YM2610/B 内蔵
    ADPCM-B 機構に対応付け、 J part 駆動)
  - TIMER-B IRQ 駆動
  - **K/R 内蔵 rhythm は no-op stub 化**: workarea / アドレスは OPNA layout
    通り確保し、 rhykey / rhyvs / rpnset / rmsvs / rmsvs_sft / rhyvs_sft /
    pdrswitch の 7 個 handler は引数 byte 数だけ正しく消費する空 handler
    として実装(.m に K/R cmd が残っていても si pointer がずれず、 chip
    側で無音化)
  - A/D ch も chip 側で無視される(YM2610 の場合)前提で driver は通常
    dispatch
- **PMDDotNET 改良(最小)**:
  - 既存 V4.8s OPNA 出力 `.m` / `.m2` をそのまま使う(Phase 2 では改造なし)
  - Phase 3 以降の `.mn` 出力経路追加の準備として PPZ8 経路の構造調査のみ

### §2-3-3 完了基準

- 自作 driver で V4.8s 互換 `.m` / `.m2` の楽曲が MAME 上の NEOGEO で再生可能
- 既存 PMD V4.8s OPNA 楽曲(FM/SSG/ADPCM-B 部分)が **無改変で**鳴る
- driver は OPNB 専用設計、 PMD88 V3.9 / V4.8s driver からの流用ゼロ
- Phase 3 で ADPCM-A 拡張(PPZ → ADPCM-A 置換)する準備が整った driver 基盤

### §2-3-4 規模感

数ヶ月レベル。 PMD.ASM 10864 行 x86 アセンブリを Z80 化する作業が中心。
ただし PMDPPZ build 構造を踏襲することで、 Phase 3 ADPCM-A 統合作業との
分離が clear になり、 全体工数の見通しは改善された。

## §2-4 Phase 3: 拡張差分(PPZ → ADPCM-A 6ch 置換)+ .PNE + WebApp 連携

### §2-4-1 ゴール

Phase 2 で完成した OPNA 互換ベースライン driver に、 **PMDPPZ の PPZ8
拡張機構を ADPCM-A 6ch 用に置換した module** を統合し、 PMDNEO driver
1 本で FM 6ch / SSG 3ch / ADPCM-A 6ch / ADPCM-B 1ch を全て扱える状態を
完成させる。

サンプルパック `.PNE` 形式と WAV → ADPCM-A 変換を整備し、 WebApp の
最小骨格(MML エディタ + ビルド + プレビュー)を立ち上げて、 ブラウザ
から 1 ループ通る状態にする。

過去 PMDAES で「K/R command → ADPCM-A 流用」 で楽していた path は廃棄、
OPNB chip 仕様に合わせて専用 dispatch を新規実装する(.mn は OPNA
バイナリ互換維持で K/R workarea を温存しつつ、 ADPCM-A は PPZ8 風後方
拡張領域として独立確保)。

### §2-4-2 実装範囲

#### 中核作業: PPZ → ADPCM-A 置換

PMD V4.8s 既存の PPZ8 統合 module を、 ADPCM-A 6ch 用に書き換える:

| V4.8s 既存 | PMDNEO 拡張 | 作業内容 |
|---|---|---|
| `PPZDRV.ASM` (865 行) | `ADPCMA_DRV.ASM` 仮称 | PPZ8 chip 駆動 routine を YM2610/B ADPCM-A 6ch register 駆動に書換 + Z80 化 |
| PMD.ASM 内 `if ppz`(L252, L475, L703, L967, L1732 等 約 10 箇所) | `if adpcma` 翻訳版 | 統合点の翻訳(PMD.ASM の Z80 化版に組込) |
| `.PZI` (PPZ8 sample format) | `.PNE` (ADPCM-A sample pack) | sample format の置換 |
| PPZ8 4-8 ch dispatch | ADPCM-A 6 ch dispatch | channel 数 + chip register 違いに合わせて書換 |

PMDDotNET 側でも対応する PPZ8 module(`PPZDRV.cs` 1135 行 / `PPZ8em.cs`
535 行 / `PPZChannelWork.cs` 30 行)を read-only 参照テンプレートとして
ADPCM-A 6ch 用に書き換える。

- **compiler 拡張(PMDDotNET 改良)**:
  - `.mn` 出力経路追加(OPNA `.m` 出力経路は無改造で温存)
  - ADPCM-A 用 dispatch entry を cmdtbl の jump1 未使用 entry に追加
  - `.PNE` 形式パース、 `#PNEFile` コマンド実装
  - サンプルバンク管理(複数楽曲での `.PNE` 共有対応)
- **driver 拡張**:
  - ADPCM-A 6ch dispatch(PPZ8 → ADPCM-A 翻訳済 module を統合)
  - サンプルバンク読み込み(NEOGEO V-ROM 経由)
  - 既存 OPNA 互換ベース(Phase 2 完成)を温存しつつ統合
- **WebApp 最小骨格**:
  - MML エディタ(基本機能)
  - ビルド(MML → `.mn` → ROM 連結)
  - 即時プレビュー(MAME ベース)
  - WAV → ADPCM-A コンバータ(18.5kHz 4bit Mono、 ブラウザ内変換)
  - `.PNE` 生成 + 管理 UI

### §2-4-3 完了基準

- PMDNEO driver 1 本で FM/SSG/ADPCM-A/ADPCM-B を全て駆動できる
- ADPCM-A サンプル(リズムキット等) を含む楽曲が NEOGEO 上で再生可能
- WebApp で WAV ファイルから `.PNE` を生成して MML から参照できる
- ブラウザだけで MML 作成 → ビルド → MAME プレビューが通る

### §2-4-4 規模感

1〜2 ヶ月。 PPZ8 → ADPCM-A 置換は **既存テンプレート(PMDPPZ + PMDDotNET
の PPZ8 module)を read-only 参照しながらの差分翻訳作業**であり、
ゼロから設計する場合より見通しが立ちやすい。

## §2-5 Phase 4: WebApp 完成 + IPL + プレイヤー V1 + リリース統合

### §2-5-1 ゴール

WebApp 全機能完成、 IPL + プレイヤー V1 実装、 ROM ビルドフローのリリース
統合まで完成させる。 PMDNEO の最初の公開リリース(V1) に到達する。

(注: ADPCM-B 1ch は OPNA `.m2` の ADPCM RAM 経路として **Phase 2 の
ベースライン driver で先行実装**するため、 本 Phase での driver 拡張作業
には含まれない。 旧設計では Phase 4 で扱う想定だったが、 「OPNA `.m`/`.m2`
を 100% 再現する Z80 driver」 をベースラインとして据える方針確定により
Phase 2 内に移動した)

### §2-5-2 実装範囲

- **WebApp 全機能**:
  - FM / SSG 音色エディタ(VEDSE 相当)
  - MAME ベース完全プレビュー(FM/SSG/ADPCM-A/ADPCM-B 統合)
  - リリース用ファイル生成(MAME 用 zip + 実機用 ROM)
  - 簡易ビルド後表示
- **IPL(バイナリのみ別配布)**:
  - サウンド・テキスト・グラフィックの最小限初期化
  - 起動画面ロゴ表示(ngdevkit 風、 純正 NEOGEO ロゴ非使用)
- **プレイヤー V1**:
  - 楽曲名表示
  - 楽曲選択再生(最小 UI)
- **VPS インフラ**:
  - Sakura VPS Ubuntu 24.04 LTS 上で WebApp 公開ホスティング
  - 専用ドメイン取得 + SSL 設定
- **配布フロー**:
  - GitHub Releases で IPL バイナリ配布(別ライセンス)
  - PMDNEO 本体 GPL-3.0 ソース公開
  - LICENSE / README 整備

### §2-5-3 完了基準

- 一般ユーザーが WebApp 経由で MML を書いて NEOGEO ROM をリリースできる
- AES+ または MAME で楽曲再生確認(audio gate)
- 公開ホスティングされた WebApp に第三者がアクセスして利用可能
- GitHub repo に PMDNEO 本体ソース + IPL Releases 配布が揃う

### §2-5-4 規模感

2〜3 ヶ月。

## §2-6 Phase 後の継続(V2 以降)

WebApp 公開後の改変期間で V2 機能を順次追加する:

- **プレイヤー V2**: レベルメーター、 ミュート機能等
- **WebApp 改良**: ユーザーフィードバックに応じた UI 改善
- **追加 chip / 機能対応**: 例えば PPZ 拡張等は将来の検討対象(現時点では未定)

V2 はリリース必須ではなく、 V1 公開後の継続開発として位置付ける。

## §2-7 Phase 間の依存関係

	Phase 1 (PoC = ROM ビルドフロー検証 + .m 仕様解析) ──┐
	  │                                                  │
	  └─→ Phase 2 (フルスクラッチ driver の FM/SSG) ─────┐│
	        │                                           ││
	        └─→ Phase 3 (ADPCM-A + .PNE + WebApp 連携) ─┐│
	              │                                    ││
	              └─→ Phase 4 (ADPCM-B + WebApp 完成 + IPL + V1 + リリース)

各 Phase は前 Phase の成果に依存する:

- Phase 1 が ROM ビルドフロー + `.m` 仕様基盤を整えなければ、 Phase 2 で
  フルスクラッチ driver を実装しても動作確認経路と仕様根拠が無い
- Phase 2 が `.m` 解釈 driver を確立しなければ、 Phase 3 で `.PNE` /
  ADPCM-A 拡張をしても基盤が無い
- Phase 3 が WebApp 最小骨格を持たなければ、 Phase 4 で WebApp 完成は遠回り

WebApp の機能は Phase 3 から本格着手し、 Phase 4 で完成。 Phase 1/2 は
ROM ビルドフローと driver に集中する。

## §2-8 Phase の進化と PMDDotNET / driver の関係

各 Phase で PMDDotNET と driver の状態が進化していく:

| Phase | PMDDotNET | driver | 出力 binary |
|---|---|---|---|
| Phase 1 | そのまま使用(改良なし) | dummy(busy loop) | `.m`(V4.8s OPNA 互換) |
| Phase 2 | そのまま使用(改良なし) | フルスクラッチ FM/SSG dispatch | `.m`(V4.8s OPNA 互換) |
| Phase 3 | ADPCM-A 6ch + `.PNE` + `#PNEFile` 拡張 | ADPCM-A 6ch dispatch 追加 | `.mn`(OPNB 拡張版に切替) |
| Phase 4 | ADPCM-B 対応 + NEOGEO ROM 出力 | ADPCM-B 1ch dispatch 追加 | `.mn`(仕様確定) |

PMDDotNET の OPNB 拡張は Phase 3 から本格着手。 Phase 1/2 では既存 PMDDotNET
の V4.8s OPNA 出力 `.m` をそのまま使う。 出力 binary を `.mn` に切替えるのは
Phase 3 のタイミング。

# §3 各 Phase のゴール / deliverable / 完了基準

(章3 以降は次の壁打ちセッションで詰める)

# §4 互換性維持戦略

(章4 以降は次の壁打ちセッションで詰める)

# §5 ドキュメント構造

(章5 以降は次の壁打ちセッションで詰める)

# §6 既存資産の位置付け

(章6 以降は次の壁打ちセッションで詰める)

---

[本設計書は壁打ち式で増補されます。 章1 完成、 章2 以降は壁打ち継続中]
