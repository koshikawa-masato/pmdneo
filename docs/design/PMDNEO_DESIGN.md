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
  出力は OPNB 準拠の `.M`
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

PMDNEO の楽曲制作で扱う主要ファイル形式:

| 形式 | 対応 chip / 仕様 | 役割 |
|---|---|---|
| `.PNE` | PMDNEO 専用 OPNB(YM2610/B) ADPCM-A 4bit 18.5kHz Mono | サンプルパック(複数サンプルをまとめたもの) |
| `.P86` | PMD98 OPNA ボード(PMD86.COM) + PCM | 既存 PMD系互換、 NEOGEO 用には .PNE に変換が必要 |
| `.PB2` | PMD88 OPNA ボード(PMDB2.COM) + ADPCM 4bit 16kHz | 既存 PMD系互換、 同上 |
| MML | PMD V4.8s 互換 + OPNB 拡張 | 楽曲ソース |

`.PNE` の仕様:

- 内容: ADPCM-A 4bit 18.5kHz Mono の複数サンプルをまとめたもの
- 容量上限: NEOGEO のサウンドROM容量限界(=V-ROM 物理上限)に準拠
- ヘッダ仕様: .P86 / .PB2 と同じやり方を踏襲(既存 PMD 流のサンプルパック構造)
- MML 側の参照: `#PNEFile "filename.PNE"` で指定(V4.8s `#コマンド` 系
  と同パターン)
- 使い回し: .PPC / .P86 と同じく、 楽曲間で同じパックを共有可能

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

OPNB 拡張範囲は構想段階(細部未定)。 主な改造ポイント候補:

- 音源チップ仕様差(OPNA → OPNB): 内蔵リズム音源仕様変更、 ADPCM-A 6ch +
  ADPCM-B 1ch、 panel B 構成違いへの対応
- MML パート割当の OPNB 構成への再マッピング
- ROM 出力形式に NEOGEO ROM 形式を新規追加
- NEOGEO 特有機能(ステレオパン、 ADPCM-A サンプルバンク管理 等)対応

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

- **FM/SSG レジスタ仕様完全互換**: 既存 PMDDotNET の出力 .M + 既存 PMD V4.8s
  driver Z80 binary を NEOGEO ROM に組み込んで MAME で再生確認可能。 PoC は
  既存技術組合わせで早期達成
- **MAME OPNB エンジンの動作観察**: K/R command も A/D ch も chip / エミュ
  側で適切に無視される(誤動作なし) = driver は OPNA 流儀の dispatch を
  そのまま出して OK
- **過去の R2 sprint 偽完了反省**: 「Z80 共通だから流用できる」 思い込みで
  失敗した経験から、 driver はフルスクラッチで段階的に置換していく(Phase 1
  PoC → Phase 2 自作driver置換)

各 Phase で動作確認できる粒度を維持し、 R2 sprint で起きた「大きいまま実装
して偽完了」 のパターンを回避する。

## §2-2 Phase 1: PoC(既存技術組合わせ動作確認)

### §2-2-1 ゴール

既存技術(PMDDotNET + 既存 PMD V4.8s driver Z80 binary) を組合わせて、
NEOGEO ROM 上で FM/SSG 楽曲が MAME で再生できる状態を作る。 PMDNEO の実装
方針(YM2610B 仕様 + chip 互換性活用)を実証する。

### §2-2-2 実装範囲

- **compiler 流用**: 既存 PMDDotNET をそのまま使い、 V4.8s OPNA 用 .M を
  出力(改造なし)
- **driver 流用**: 既存 PMD V4.8s driver の Z80 binary を NEOGEO ROM に
  組み込み、 OPNB(MAME)で再生(改造なし)
- **NEOGEO ROM ビルドフロー(最小)**: ngdevkit 等を参考に、 .M + driver
  binary を NEOGEO ROM 形式にパッケージ
- **MAME 再生確認**: ROM を MAME に通して FM/SSG 楽曲を鳴らす

### §2-2-3 完了基準

- 既存 PMD V4.8s 楽曲(FM/SSG のみ) が MAME 上の NEOGEO で再生可能
- K/R / A,D ch の楽曲データが含まれていても誤動作しないことを確認
- driver Z80 binary 流用での動作確認が取れる(= chip 互換性検証完了)

### §2-2-4 規模感

1 週間程度。 既存技術組合わせのため新規実装は ROM ビルドフローのみ。

## §2-3 Phase 2: フルスクラッチ driver の FM/SSG 部分

### §2-3-1 ゴール

PoC で使った既存 PMD V4.8s driver Z80 binary を、 PMDNEO 専用フルスクラッチ
driver(YM2610B 仕様、 OPNB 専用設計)に置換する。 Phase 3 以降の ADPCM-A /
ADPCM-B 拡張のための driver 基盤を確立する。

### §2-3-2 実装範囲

- **driver フルスクラッチ実装(FM/SSG 部分)**:
  - .M 解釈ループ(V4.8s 互換 dispatch table 構造)
  - FM 6ch dispatch(YM2610B 仕様)
  - SSG 3ch dispatch
  - TIMER-B IRQ 駆動
  - K/R / A,D 関連 opcode は通常 dispatch(chip 側で無視されるため driver 側で特別処理不要)
- **PMDDotNET 改良(最小)**:
  - 既存 V4.8s OPNA 出力 .M をそのまま使う(Phase 2 では改造なし)
  - Phase 3 以降の OPNB 拡張準備として dispatch entry の調査のみ

### §2-3-3 完了基準

- 自作 driver で MAME 再生、 PoC(Phase 1)と同等動作
- driver は OPNB 専用設計、 PMD88 V3.9 / V4.8s driver からの流用ゼロ
- Phase 3 で ADPCM-A 拡張する準備が整った driver 基盤

### §2-3-4 規模感

数週間。

## §2-4 Phase 3: ADPCM-A 6ch + .PNE + WebApp 連携

### §2-4-1 ゴール

ADPCM-A 6ch を完全新規実装し、 サンプルパック .PNE 形式と WAV→ADPCM-A 変換
を整備する。 WebApp の最小骨格(MML エディタ + ビルド + プレビュー) を立ち
上げ、 ブラウザから 1 ループ通る状態にする。 過去 PMDAES で「K/R command →
ADPCM-A 流用」 で楽していた path は廃棄、 OPNB chip 仕様に合わせて専用
dispatch を新規実装する。

### §2-4-2 実装範囲

- **compiler 拡張(PMDDotNET 改良)**:
  - ADPCM-A 用 dispatch entry 追加
  - .PNE 形式パース、 #PNEFile コマンド実装
  - サンプルバンク管理(複数楽曲での .PNE 共有対応)
- **driver 拡張**:
  - ADPCM-A 6ch dispatch
  - サンプルバンク読み込み(NEOGEO V-ROM 経由)
- **WebApp 最小骨格**:
  - MML エディタ(基本機能)
  - ビルド(MML → .M → ROM 連結)
  - 即時プレビュー(MAME ベース)
  - WAV → ADPCM-A コンバータ(18.5kHz 4bit Mono、 ブラウザ内変換)
  - .PNE 生成 + 管理 UI

### §2-4-3 完了基準

- ADPCM-A サンプル(リズムキット等) を含む楽曲が NEOGEO 上で再生可能
- WebApp で WAV ファイルから .PNE を生成して MML から参照できる
- ブラウザだけで MML 作成 → ビルド → MAME プレビューが通る

### §2-4-4 規模感

1〜2 ヶ月。

## §2-5 Phase 4: ADPCM-B + WebApp 完成 + IPL + プレイヤー V1 + リリース統合

### §2-5-1 ゴール

ADPCM-B(可変サンプリングレート、 delta-T) 対応、 WebApp 全機能完成、 IPL +
プレイヤー V1 実装、 ROM ビルドフローのリリース統合まで完成させる。 PMDNEO
の最初の公開リリース(V1) に到達する。

### §2-5-2 実装範囲

- **driver 拡張**:
  - ADPCM-B 1ch dispatch(可変サンプリングレート)
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

	Phase 1 (PoC) ────────┐
	  │                  │
	  └─→ Phase 2 (フルスクラッチ driver の FM/SSG) ─┐
	        │                                       │
	        └─→ Phase 3 (ADPCM-A + .PNE + WebApp 連携) ─┐
	              │                                    │
	              └─→ Phase 4 (ADPCM-B + WebApp 完成 + IPL + V1 + リリース)

各 Phase は前 Phase の成果に依存する。 Phase 1 で chip 互換性が実証されな
ければ Phase 2 で driver フルスクラッチを始めても基準点が失われる。

WebApp の機能は Phase 3 から本格着手し、 Phase 4 で完成。 Phase 1/2 は
ROM ビルドフローと driver に集中する。

## §2-8 Phase の進化と PMDDotNET の関係

各 Phase で PMDDotNET の改良範囲が広がっていく:

- Phase 1: そのまま使用(改良なし、 既存 V4.8s OPNA .M 出力)
- Phase 2: そのまま使用(改良なし、 driver 側で .M 解釈)
- Phase 3: PMDDotNET にない ADPCM-A 6ch + .PNE 形式 + #PNEFile コマンドを
  新規追加実装、 OPNB 出力 .M に拡張
- Phase 4: ADPCM-B 対応 + ROM 出力部分(NEOGEO 用)を完成

PMDDotNET の OPNB 拡張範囲(§1-12-1) は、 Phase 3 から本格的に手を入れる。
Phase 1/2 では既存 PMDDotNET の OPNA 出力をそのまま使う。

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
