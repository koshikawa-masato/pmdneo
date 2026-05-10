# PMDNEO MML ひな形 (= templates/)

user が MML を**直接編集して試す**ためのひな形集。 SAMPLE2.MML 流儀ベース。

## 使い方

1. ひな形を直接編集 (= 新 cmd 入れたい所に追記)
2. build:
   ```bash
   MML_INPUTS=templates/01-blank.mml PMDNEO_SONG=0 bash scripts/build-poc.sh
   ```
   ※ `templates/foo.mml` 形式で path 指定 OK
3. audio gate:
   ```bash
   bash scripts/run-mame.sh --gamerom lastbld2 --trace --wavwrite --wavwrite-seconds 10
   ```
4. 結果を Claude に伝える (= 「templates/04-voice-switch.mml で voice 1 がノイズ」 等)

## ひな形一覧

| file | 用途 |
|------|------|
| `01-blank.mml` | 全 part empty + tempo + voice 1 種、 user が note 入れる起点 |
| `02-single-note.mml` | 1 part 1 note (= AI 機械解析向け、 cmd 効果単発検証) |
| `03-pan-test.mml` | BCEF 各 1 note 順次 (= PAN R/L 検証単音 fixture) |
| `04-voice-switch.mml` | 同 ch 同 note voice 切替 (= voice 倍音比較) |
| `05-loop-test.mml` | `[/]` `:` `L` ループ動作検証 |
| `sample2-base.mml` | SAMPLE2.MML UTF-8 翻訳 (= 完走目標 reference) |

## user → AI 共働ルール

- **user 編集**: 新 cmd 入れたい所に追記、 期待動作を inline コメントで併記
- **AI 実装**: 新 cmd 未実装なら driver + compile.py 拡張 (= ひな形が build 通るまで)
- **AI 解析**: build → audio 録音 → WAV/trace 機械解析 → 「変更/期待/実測」 3 要素表で報告
- **user 判定**: 大局判定 OK / 微妙 / NG、 言語化困難なら「もどかしい」 表明 OK (= AI 側で構造化質問補助)

## 新 cmd 実装サイクル例

例 `E` (= envelope) cmd:
1. user: `templates/01-blank.mml` の B part に `E0,1,2,3 c d e f` 追記、 「E で envelope 制御を試したい」 と Claude に伝える
2. Claude: `E` cmd 未実装と判定、 ADR-0003 で byte code 予約 + driver routine + compile.py parse 実装 (= 1 sprint)
3. Claude: build + audio gate + 解析 → 3 要素表で報告
4. user: 大局判定、 OK なら commit / 違和感あれば構造化質問で詳細詰める

## 注意

- `test01.mml` 〜 `test08.mml` は **AI 側 fixture** (= regression baseline、 byte-identical 維持対象)、 user は触らない
- `templates/` は **user 編集領域**、 自由に試行
- 個人創作 (= 楽曲) は別 dir (= songs/private/ 等、 .gitignore) を別途検討
