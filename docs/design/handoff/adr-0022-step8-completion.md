# ADR-0022 step 8 ε 完了統合: runtime `.PNE` filename observation sprint 完了 + Accepted 移行

- 日付: 2026-05-13 (= 9th session、 γ 着手で完了統合)
- 対応 ADR: [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md)
- 関連 commit: 本 handoff doc を含む γ 完了統合 commit
- 前段: [α handoff](adr-0022-step8-alpha-mn-filename-adr-read.md) / [β handoff](adr-0022-step8-beta-filename-string-copy.md)

## 完了統合 sum-up

ADR-0022 step 8 を α/β/γ 3 sub-sprint で完走、 「runtime `.PNE` filename observation」 として成立。 build-time contract (= Step 7 で `.MN` に filename embed) が runtime-visible state (= driver SRAM 0xFD20-0xFD31 に filename string + address 保持) まで 1 段延伸完了。

### α/β/γ で達成した状態

```
Z80 SRAM after song init (= PMDNEO mode .MN load 完了):
  0xFD20-0xFD29: 's', 't', 'e', 'p', '5', '.', 'P', 'N', 'E', NUL  (= filename string)
  0xFD2A-0xFD2F: untouched (= 6 byte 余剰、 通常 contract で overflow 不通過)
  0xFD30-0xFD31: 0xA4, 0x00 (= pne_filename_adr LE u16 = 0x00A4、 m_buf-relative)
```

`.MN` 内 filename embed が driver の runtime state として観測可能になった。 ただし resolver / bank resolve / `.PNE` runtime parse / multi-`.PNE` 切替には踏み込んでいない (= ADR-0022 §決定 2 / 8 厳守)。

## 全体完了判定 9 項目達成状況

| # | 項目 | 達成 | 関連 commit |
|---|---|---|---|
| 1 | α: driver `.MN` parser に `pne_filename_adr` field 読込経路追加 + commit + push | ✅ | `a6c6695` |
| 2 | α: `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) に保存される trace 確認 | ✅ (= z80-mem-trace FD30=A4 / FD31=00 = 0x00A4) | `a6c6695` |
| 3 | β: `pne_filename_adr` follow + filename string copy 実装 + commit + push | ✅ | `6cf30dd` |
| 4 | β: `driver_pne_filename_buf` (= 0xFD20-0xFD2F) の中身が `.MN` filename string と byte-identical | ✅ (= 0xFD20-0xFD29 = `"step5.PNE\0"`) | `6cf30dd` |
| 5 | β: overflow 規約 (= 15 byte copy + byte15 = 0x00 + trace warning) が 16+ byte filename で正しく動作 | ⏸ **β-A 正規 scope-out** (= code path 実装済、 16+ byte fixture verify は future hardening sprint) | `6cf30dd` |
| 6 | γ: filename runtime observation 用 trace script 整備 + commit + push | ✅ (= `verify-step8-filename-observation.sh`、 5 gate) | 本 commit |
| 7 | γ: step 5/6/7 既存 verify script 全件 PASS (= 既存 architecture regression なし) | ✅ (= step 5 γ 6 gate + step 6-a 7 gate + step 7 δ 4 gate + step 7 β-3 4 gate、 計 21 gate) | 本 commit |
| 8 | γ: MAME 試聴で audible regression なし (= step 6 silent-bcef fixture で確認) | ✅ (= user 試聴で OK 受領、 L-Q 6 音 audible + FM 同居なし) | 本 commit |
| 9 | γ: step 8 完了統合 handoff doc + ADR-0022 Accepted 移行 + commit + push | ✅ | 本 commit |

→ **9/9 達成** (= #5 は β-A 採用で正規 scope-out、 残り 8 項目すべて PASS)

## sub-sprint commit chain (= step 8 全 4 commit)

| sub | commit | 内容 |
|---|---|---|
| 起票 | `57b4bad` | docs(adr): step 8 着手前に ADR-0022 起票 — runtime .PNE filename observation sprint (= sub-A 採用) |
| α | `a6c6695` | feat(driver): step 8 α — driver_pne_filename_adr_word read in pmdneo_mn_direct_load_lq_part_addr (= word observation only) |
| β | `6cf30dd` | feat(driver): step 8 β — filename string copy to driver_pne_filename_buf (= β-A 採用、 overflow path 実装) |
| γ | 本 commit | docs(adr): step 8 γ 完了統合 + ADR-0022 Accepted 移行 + verify-step8-filename-observation.sh |

## Accepted 移行根拠

- 完了判定 9 項目中 8 項目 PASS + 1 項目 (= #5 overflow fixture verify) 正規 scope-out (= β-A 採用)
- ADR-0022 §scope-out 全 12 項目 維持確認済 (= 本 handoff doc §scope-out 維持確認)
- step 5/6/7 verify 改修不要で 21 gate 全 PASS (= 既存 architecture 整合性確認)
- α/β の driver 改修は `pmdneo_mn_direct_load_lq_part_addr` 内 +37 line に限局、 既存 logic literal 不変
- `samples.inc` / VROM 4 件 byte-identical 維持 (= step 7 β-3 PASS、 build pipeline 完全不変)
- audible regression なし (= user 試聴 OK + step 6-a 7 gate PASS)

→ ADR-0022 = **Accepted**

## scope-out 維持確認 (= ADR-0022 §決定 2 / 8 + §scope-out)

step 8 終了時点で、 以下の項目は **完全に未実装** であることを明示:

- ❌ filename string → ROM sample table resolve (= sub-B / sub-C 相当、 別 sprint)
- ❌ `.PNE` binary runtime parse (= header / sample entry / addr table)
- ❌ multi-`.PNE` switching (= 楽曲ごと別 `.PNE` 切替)
- ❌ ROM bank switching / 動的 sample bank 管理
- ❌ 楽曲交換時 ROM rebuild 不要化
- ❌ K/R rhythm compatibility 現役接続
- ❌ sample table 再構築 routine
- ❌ asset reload (= 動的 `.PNE` 差替)
- ❌ mc compiler / vromtool.py / converter / `samples.inc` 改修
- ❌ overflow fixture (= 16+ byte filename test、 β-A 採用で γ/future)

→ ADR-0022 §scope-out 全 12 項目 維持。

## Accepted 後の重要境界 (= future contributor 向け明示)

**Step 8 は `.PNE` runtime resolver / parser を実装していない**。 現時点で driver は:

- `.MN` 内 filename string を runtime state として **観測可能** にしているが、 **解決には使っていない**
- sample addr は依然 build-time に `samples.inc` 経由で固定埋込 (= ADR-0019 §決定 3 維持)
- 楽曲交換時は依然 ROM rebuild が必要 (= multi-`.PNE` runtime 切替は未実装)

つまり「driver が filename を読めている」 ことは Step 8 で証明したが、 「filename を runtime 解決に使う」 のは **Step 9 以降の候補**:

- filename → sample table resolve → 動的 bank lookup (= sub-B / sub-C)
- `.PNE` binary 自体の runtime parse (= sample entry / addr table 読込)
- multi-`.PNE` switching (= 楽曲ごと別 `.PNE` runtime 切替、 ROM rebuild 不要化)

`driver_pne_filename_buf` / `driver_pne_filename_adr_word` が現状 **read 用 observation state** に留まっていることを future contributor が誤解しないよう明示。 これは ADR-0022 §決定 8 (= 既存 sample playback path は完全不変) の literal 整合。

## Step 5/6/7/8 全体での役割位置づけ

ADR-0021 で確立した「Step 5/6/7 役割分離 = semantics / listening / source ownership 3 軸独立」 に Step 8 を加えると、 4 軸構成になる:

| Step | 役割 | 主成果 |
|---|---|---|
| 5 | semantics (= どう鳴らすか) | ADPCM-A 6ch native path、 sample lookup / register write / vol/pan |
| 6 | listening (= どう聴くか) | audio isolation、 silent-bcef fixture、 verify infra |
| 7 | source ownership (= どこから持ってくるか) | `.PNE` asset pipeline、 build-time source-of-truth、 `.MN` filename embed |
| 8 | observation (= runtime で何が見えるか) | PNE runtime observation block、 filename string + address の runtime 観測 |

Step 8 は新しい軸 (= observation) として、 Step 7 で確立した build-time contract を **runtime に届ける** 段階。 resolver や parser には踏み込まず、 「contract が runtime まで貫通している」 ことを最初に証明する役割。

## 関連 doc

- [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md) (= 本 sprint の指針)
- [α handoff](adr-0022-step8-alpha-mn-filename-adr-read.md) (= `pne_filename_adr` word observation)
- [β handoff](adr-0022-step8-beta-filename-string-copy.md) (= filename string copy)
- ADR-0019 §決定 3 (= sample addr は build 時 embed + `.PNE` は設計書記述のみ、 Step 8 でも維持)
- ADR-0021 §Accepted 後の重要境界 (= 「runtime resolution は Step 8 以降の候補」 と明記された予約消化)
- `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)

## 次 sprint 候補

ADR-0022 §scope-out のうち未消化:

1. **runtime `.PNE` parser driver 実装** (= sub-B / sub-C 相当、 filename → sample table resolve)
2. **K-R rhythm compatibility 現役接続** (= ADR-0019 §決定 2 micro-sprint 候補、 PMDNEO 機能拡張)
3. **multi-`.PNE` switching** (= 楽曲交換時 ROM rebuild 不要化、 動的 sample bank 管理)
4. **`.PNE` binary runtime parse** (= header / sample entry / addr table)
5. **PMDNEO.s + nullsound integration** (= 大規模 sprint、 driver 二系統統合)
6. **overflow path hardening sprint** (= 16+ byte filename fixture + overflow verify、 β-A scope-out の消化)
7. **new sample 追加** (= WAV → ADPCM-A 変換 UI、 WebApp Phase 4 領域)

step 8 完了で driver は「filename を読める」 状態に達した。 これを「filename を使う」 状態に進めるのが次の自然な候補 (= 1 番)。 ただし PMDNEO 全体の Phase 3 進行は `.PNE` runtime resolver 完成より先に他の要素 (= WebApp UI / IPL / Phase 4 ADPCM-B 等) を進める判断もあり、 user 優先度で選定する。
