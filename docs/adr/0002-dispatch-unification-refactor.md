# ADR-0002: PMDNEO driver の dispatch 共通化 refactor (= per-chip routine 4 個 → 共通 part_main + chip hook table)

- 状態: Accepted
- 起票日: 2026-05-10
- 起票者: 越川将人 (M.Koshikawa)
- 関連: Phase 9R sprint (= refactor/dispatch-unification branch、 6 commit)、 設計書 `docs/design/dispatch_unification.md`、 公開報告書 https://koshikawa-masato.github.io/pmdneo/

## 背景

### Phase 9-prep failure

2026-05-10 Phase 9-prep (= B-J 8 part init 復活 + tempo 統一 + PAN 設定) を試行、 drum 高速化 + FM/SSG 全 silent で 2 連続 failure。 切り分け試行 (= PAN 削除のみ) でも同症状、 真因不明のまま revert。

### user 根本原因指摘

> FM/SSG/ADPCM-A/ADPCM-B でコマンド別ルートが複雑すぎていませんか?
> BCEFGHIJ KLMNOPQ でシーケンシャルに連続コマンド入れるのが普通なのでは
> 全対応で必要な処理 (l, q, v, M, D, E, W, ! など) は必要なパートだけに流れる処理のように一貫したフローにして簡単にすべき

### 既存 driver の分析

per-chip 主 routine **4 個 separate**:
- fmmain (= line 1554、 47 行)
- pmdneo_psgmain (= line 1602、 60 行)
- adpcmb_main (= line 1663、 155 行)
- adpcma_main (= line 1818、 76 行)

構造は **完全同型** (= LEN check → parse → note/loop/cmd dispatch)、 違いは note 経路の chip 別 helper 呼出のみ:
- FM: fnumset_fm + fm_keyon
- SSG: fnumsetp_ch + pmdneo_psg_keyon
- ADPCM-B: voice setup + adpcmb_keyon
- ADPCM-A: adpcma_keyon_simple

pmdneo_song_main (= line 1326) で chip type 別に 5 fork dispatch (= chip type 別に main 経路 切替)。

## 検討した選択肢

### (A) 既存 4 routine 維持 (= status quo)

- 利点: 既動作確認済、 refactor risk なし
- 欠点: cmd 追加 (= q/Q/v/M/D/E/W/! 等) で 4 routine 全部に分岐追加が必要、 維持コスト高

### (B) chip 別 hook table + 共通 part_main routine (= 採用案)

- per-part 共通 dispatch routine `pmdneo_part_main` 1 個
- chip 別差分は per-part hook fn pointer 4 個 (= keyon/keyoff/fnumset/volumeset)
- pmdneo_song_main は 1 fork (= dispatch 経路集約)
- 利点: cmd 追加が 1 箇所 (= commandsp 拡張) で完結、 dispatch 簡素化、 4 routine の 338 行を共通 routine 53 行 + 12 hook 数行に圧縮
- 欠点: SRAM 8 byte/part 拡張 (= PART_OFF_HOOK_*)、 indirect call cost (= push hl + ret パターン)

### (C) chip type 別 dispatch table (= per-part single fn pointer)

- per-part 1 fn pointer (= chip 別 main routine 全体を pointer)
- 利点: SRAM 増加最小 (= 2 byte/part)
- 欠点: 4 routine 維持必要 (= 共通化なし)、 (A) と本質同じ

## 決定

**(B) 採用** = 共通 part_main + chip hook table 設計。

詳細は `docs/design/dispatch_unification.md` (= 446 行設計書) 参照。

## 実装結果 (= Phase 9R sprint、 6 commit)

| commit | sub-step | 内容 |
|--------|----------|------|
| 4c0fcd1 | R-1 | 設計書起票 |
| ea34859 | R-2/3/4 | 共通 part_main + 12 hook + 共通 indirect call wrapper、 旧 4 routine 削除 |
| 430e50e | R-5a | FM 4 part (= B/C/E/F) init 復活 + hook B 引数 fix + voice setup |
| 9e5f6e6 | R-5b | SSG 3 part (= G/H/I) + voice setup + FM PAN 分離 |
| 9976580 | R-5c | ADPCM-B + beat.wav + 14 part milestone |
| 5badc1a | R-6 | 14 part dispatch milestone 完成宣言 |

## 効果数値

| 項目 | before (= main df4e7b6 系) | after (= develop aebc545) | 差 |
|------|---------------------------|---------------------------|-----|
| 主 routine 数 | 5 個 (= pmdneo_song_main + 4 chip routine + commandsp) | 1 共通 + 12 hook + 1 noop + 4 wrapper + commandsp | dispatch 集約 + 拡張容易化 |
| 主要 routine 行数 | 338 行 (= 4 chip routine 計) | 共通 part_main 53 行 + 12 hook 各 3-5 行 + noop 2 行 = 約 120 行 | 実質 218 行削減 |
| Z80 binary 実 byte | 2,895 byte | 2,954 byte | +59 byte (= +2.04%) |
| SRAM per-part | 64 byte (= ただし 24 byte 既存使用 + 余り) | 64 byte (= +8 byte hook、 既存余り内収納) | layout 内吸収 |
| 14 part 並行 dispatch | 不能 (= B-J 復活で drum 高速化 + FM/SSG silent failure) | **OK** (= audio gate 全 pass、 4 wave で確認) | milestone 達成 |

## 後続効果

Phase 9c (= §5 全 volume cmd 群一括実装) で:
- commandsp 拡張 1 箇所のみで 8 cmd 追加完了
- chip 別差分は volume hook 4 個拡張で完結 (= fm_volume_hook + psg_volume_hook + adpcma_volume_hook + adpcmb_volume_hook)
- 全 chip vol 動的制御可能 (= V cmd で silent / 復活)

これは旧 architecture (= per-chip 4 routine) なら 各 routine に分岐追加 + chip 別 logic 重複で 4 倍 工数 を要した。

## 不変条件

- **Phase 8d-2 baseline (= L part BD nest LOOP audio gate pass)** は refactor 後も同等動作 (= R-3 で verify 済)
- byte-identical 不要、 ただし audio gate verify 必須

## 関連

- 設計書: `docs/design/dispatch_unification.md`
- ADR-0001: PMDNEO 楽曲は YM2610 無印 chip ch 1/4 を不使用とする (= 本 ADR の前提)
- 公開報告書: https://koshikawa-masato.github.io/pmdneo/
- memory `feedback_audio_verify_change_disclosure.md` (= audio gate workflow)
- memory `feedback_publish_information_via_pages.md` (= GitHub Pages 公開規律)
