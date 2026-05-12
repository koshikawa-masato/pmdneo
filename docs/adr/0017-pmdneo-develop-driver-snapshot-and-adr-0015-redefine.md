# ADR-0017: develop branch PMDNEO driver 現状 snapshot + ADR-0015 前提整理

- 状態: Accepted
- 起票日: 2026-05-12
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0013 (= 同 .M 2 経路比較 路線への切替)、 ADR-0014 (= ADR-0006 sprint 成果のカテゴリ別判断)、 ADR-0015 (= PMDDotNET 改造 技術調査 sprint)

## 背景

ADR-0015 軸 1 + 軸 2 完了 (= 2026-05-12、 commit `fd4034b` + `48cfbb6`) の作業中に、 ADR-0013/0014/0015 の文書と develop branch の実体との間に複数の認識ズレがあることが判明した。

具体的には次の 2 点:

1. ADR-0014 §「カテゴリ C: 凍結」 の「自前 driver」 という表現が、 実際は ADR-0006 sprint 産物 (= `standalone_test.s` 等) のみを指していたが、 文書を文字通り読むと develop branch の本格 PMDNEO driver (= `PMDNEO.s` + `PMD_Z80.inc` 等の 9 file) も凍結対象に含まれる解釈になり得た
2. ADR-0015 軸 2 (= NEOGEO 環境調査) の作業内容項目は「PMD.ASM (= 8086 source) 上の if 分岐改造」 を想定していたが、 実際の develop branch では既に PMD V4.8s の Z80 化 + nullsound integration が Phase 2 SubF-1.1 まで実装進行中だった

ADR-0015 軸 2 完了 (= commit `48cfbb6`) で develop 資産現状を §軸 2 末尾に記録することで暫定対処したが、 軸 3/4/5 にも同様の見直しが必要であり、 改造 PMDDotNET 路線全体の前提を整理する必要がある。 本 ADR でこれを正式に確定する。

## 決定

### 決定 1: develop branch PMDNEO driver の正式位置付け

develop branch (= commit `e32e0d3`、 Phase 12a-4 で停止) の `src/driver/` 内 9 file は、 改造 PMDDotNET 路線における **driver 側本体 (= 継続発展対象)** として正式に位置付ける。 凍結対象ではない。

#### develop 上 src/driver/ 9 file 一覧 (= 2026-05-12 確認時)

| file | 行数 | 役割 / 状態 |
|---|---|---|
| `PMDNEO.s` | 44 | build top (= sdasz80)、 nullsound integration 完了、 cmd_jmptable 実装 (= cmd 02 play_song / 04 fade_out / 05 play_adpcmb_test) |
| `PMD_Z80.inc` | 2206 | PMD V4.8s 8086 source の Z80 化 base、 SubB-1〜SubF-1.1 まで実装進行 (= SSG init / TIMER-B IRQ / FM voice / scale 演奏 / fade) |
| `WORKAREA.inc` | 137 | 17 part 構造 (= FM 6ch + SSG 3ch + ADPCM-B + Rhythm + ADPCM-A 6ch)、 各 part workarea field offset 定義済 |
| `KR_STUB.inc` | 52 | K/R rhythm 7 cmd no-op stub 完成 (= PMD ファミリ「未対応 cmd スルー」 思想 実装) |
| `IRQ.inc` | 117 | TIMER-B IRQ + nullsound cmd 受付経路 完成 |
| `REGMAP.inc` | 19 | nullsound `ports.inc` + `ym2610.inc` 流用、 `PORT_YM2610_STATUS` 等の symbolic name で抽象化 |
| `ADPCMB_DRV.inc` | 49 | 大半 stub だが ADPCM-B keyon/keyoff 一部実装済、 SubE で本実装予定 |
| `ADPCMA_DRV.inc` | 48 | Phase 3 用 stub |
| `standalone_test.s` | 2351 | ADR-0006 sprint 別経路試行産物 (= **凍結扱い、 本決定の対象外**、 ADR-0014 カテゴリ C 該当) |

#### Phase 2 Sub-phase 進行 (= driver README より)

- **SubA**: skeleton 配置 + sdasz80 ビルド通る silent ROM (= **完了**)
- **SubB**: SSG 3ch dispatch (= commandsp / cmdtblp / fnumset PSG / volset PSG) (= **完了、 SubB-7 まで進行**)
- **SubC**: FM 6ch dispatch (= commands / cmdtbl / 音色 set) (= **完了、 SubC-3 まで**)
- **SubD**: K/R no-op stub の cmdtblr 連結 (= **KR_STUB.inc 完成**)
- **SubE**: ADPCM-B 1ch dispatch (= ADPCMB_DRV.ASM 完成) (= **着手中、 keyon/keyoff 一部実装**)
- **SubF**: 統合 (= tempo / fade / loop / mask、 長尺楽曲 audio gate) (= **SubF-1.1 fade_out まで**)

### 決定 2: ADR-0014 §「凍結」 範囲の明確化

ADR-0014 §「カテゴリ C: 凍結」 の対象は **ADR-0006 sprint で別経路として試行された産物** (= 主に `standalone_test.s` + ADR-0009/0010/0011 で touch した同 file 内の修正) のみ。

develop branch の本格 PMDNEO driver (= 上記 9 file 中、 `standalone_test.s` 以外の 8 file) は ADR-0014 「凍結」 対象外、 改造 PMDDotNET 路線における driver 側本体として継続発展する。

ADR-0014 文書に本 ADR への参照注記を追加する。

**追加注記 (= 2026-05-12、 ADR-0016 step W-3 補正)**: §決定 1 の表内 `standalone_test.s` 行および §決定 2 の「`standalone_test.s` を凍結対象、 残り 8 file を継続発展対象」 という分類は **ADR-0016 step 3-4 sprint の実装過程で見直し**:

- `standalone_test.s` は **凍結ではなく nullsound-free PoC 本線 driver** (= 独自 Z80 entrypoint + TIMER-B IRQ + NMI command dispatch + per-tick driver loop が成立、 cmd 0x02 で MML song start 動作確認済)
- `PMDNEO.s` + `IRQ.inc` + `PMD_Z80.inc` + 関連 .inc 8 file は **nullsound integration の設計試行、 ただし `state_timer_tick_reached` が nullsound 提供と仮定したが nullsound.lib で未定義** という不整合があり、 build top にしても driver 動作未到達 (= V-1 commit 6813d70 で切替試行 → W-3 commit 464cff1 で撤回)
- 暫定方針: `standalone_test.s` を本線として `step 4-5` (= ADPCM-B / J part / ADPCM-A 6ch) の実装を進める、 nullsound integration (= `PMDNEO.s` + 関連 .inc 完成) は別 sprint として future work

§決定 1 の表内 `standalone_test.s` 行は **「ADR-0006 sprint 別経路試行産物 (= 凍結扱い)」 → 「nullsound-free PoC 本線 driver (= step 4-5 実装はここで進める)」** に解釈を更新。 残り 8 file は **「nullsound integration 試行、 legacy として retain、 将来 sprint で完成」**。

### 決定 3: ADR-0015 §軸 3/4/5 の redefine 方針

ADR-0015 §軸 3/4/5 は起票時前提 (= PMD.ASM 8086 source 上の改造) で書かれているが、 これは develop の Z80 化 path を踏まえた redefine が必要。 各軸の redefine 方針は次:

| 軸 | ADR-0015 起票時の作業内容 | redefine 方針 |
|---|---|---|
| 軸 3 (= OPNB chip 差分) | OPNA → OPNB の register 差分整理 + `if opnb` 挿入候補 list | develop の `REGMAP.inc` + `ADPCMA/B_DRV.inc` + `WORKAREA.inc` 17 part 構造 で枠組み済。 残作業を「ADPCM-A 6ch 本実装 (= Phase 3)」 + 「ADPCM-B 本実装 (= SubE 完成)」 + 「OPNA 既存 board2 90 件のうち未踏襲部分の発掘」 として整理 |
| 軸 4 (= mc compiler 改造) | PMDDotNETConsole の OPNB 出力分岐 + .M format design | develop driver 側の cmd 規約 (= cmd 02/04/05 + 将来追加) + WORKAREA 17 part 構造 + .M format 仕様 を base に PMDDotNET 側 OPNB 出力対応を組み立てる形に再定義 |
| 軸 5 (= 改造規模見積もり) | 100-150 件 if 分岐の具体的内訳 | driver 側 develop 進捗 (= Phase 2 SubF-1.1 まで) を踏まえて、 「残実装規模」 (= SubE 残り + Phase 3 ADPCM-A + 軸 4 mc compiler 改造) として再見積もり |

ADR-0015 文書に各軸の §redefine 注記を追加し、 「本 ADR-0017 §決定 3 参照」 で詳細を委ねる。

### 決定 4: 今後の作業 path 選択肢

ADR-0017 起票後の作業 path は次の選択肢から user 判断で進める (= 1 つ選んで進む形、 並行も可):

- **path A (= ADR-0015 軸 3-5 redefine 継続)**: ADR-0015 §軸 3/4/5 を本 ADR §決定 3 の方針で個別に redefine、 各軸完了ごとに ADR-0015 追記 + commit。 ADR-0015 完了後に ADR-0016 (= 改造実装 sprint 作業計画) 起票
- **path B (= develop 直結 pivot)**: ADR-0015 軸 3-5 を superseded 扱いとし、 develop branch 上 SubE / Phase 3 実装を直接進める形に pivot。 wip-pmddotnet-opnb-extension または develop 起点の新 branch で進行。 ADR-0016 起票時に「path B 選択により ADR-0015 軸 3-5 を skip」 を記録
- **path C (= 並行)**: path A の ADR redefine と path B の develop 実装 を並行進行。 ADR 整理を待たずに driver 側 SubE/Phase 3 を進めつつ、 並行で軸 3-5 redefine 作業

本 ADR-0017 では path 選択を確定せず、 選択肢を整理した状態で完了する。 path 選択は別 sprint で user 判断仰ぐ。

## 完了判定

- 本 ADR (= ADR-0017) 起票 + commit + push (= wip-pmddotnet-opnb-extension)
- ADR-0014 + ADR-0015 への訂正注記追加 (= 本 ADR への参照を含む)

これで develop branch の PMDNEO driver と ADR-0013/0014/0015 の関係が文書として正式に整合される。

## 関連 memory

- `project_pmdneo_develop_driver_snapshot.md` (= develop branch 9 file 詳細 snapshot、 本 ADR §決定 1 と整合)
- `project_adr_0013_0014_path_switch.md` (= ADR-0013/0014 路線変更記録)
- `project_next_session_kickoff.md` (= 次 session 着手 path 選択肢)

## 次 sprint 候補

1. **path A 採用時**: ADR-0015 §軸 3 redefine 着手 (= develop の REGMAP.inc + ADPCMA/B_DRV.inc + WORKAREA.inc 前提で残作業整理)
2. **path B 採用時**: develop 上 SubE 完成 (= ADPCM-B 本実装) または Phase 3 ADPCM-A 6ch 本実装 を wip-pmddotnet-opnb-extension で進行
3. **path C 採用時**: path A + path B を並行で進行、 各 sprint で commit + 報告
