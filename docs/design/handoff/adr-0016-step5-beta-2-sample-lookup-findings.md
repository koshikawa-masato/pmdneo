# ADR-0016 step 5 β-2 sample lookup + β-3 verify infrastructure finding

- 起票日: 2026-05-12 (= 6th session β-3)
- 起票者: Claude Code
- 関連: β-1 commit b3b1683、 β-2a commit 0029034、 β-2b commit 93bfc3d、 ADR-0019 §決定 6 sub-sprint β、 議題 5

## 概要

**β-3 は検証 infrastructure commit** (= driver 実装変更なし)。 β-2 (= sub-sprint β-2a + β-2b) で成立した「`@<n>` → comat_pcm → PART_OFF_INSTRUMENT → adpcma_keyon_simple → sample table lookup → ADPCM-A start/stop register」 chain を **regression test 化**。

driver 変更なし、 既存挙動を **固定 verify** するのみ。 α-3 verify-l-part-alpha-trace-gate.sh の派生で sample 差分軸を加えた構造。

## β chain 完成 (= β-3 で固定する対象)

```
L body @<n> (= 0xFF nn)
  ↓ commandsp → comat → comat_pcm           (β-2a、 commit 0029034)
  ↓ PART_OFF_INSTRUMENT(ix) = n
  ↓ adpcma_keyon_simple                       (β-2b、 commit 93bfc3d)
  ↓ adpcma_ch_sample_ptr_table[n] 引き
  ↓ reg 0x10/0x18/0x20/0x28 = sample n の addr
```

これにより MML 上の `@0` と `@1` が ADPCM-A の **異なる sample addr** として chip register に届く chain が確立。 β-3 でこれを fixture-driven verify として固定。

## verify script

### 場所

`src/test-fixtures/step5/verify-l-part-beta-sample-lookup.sh`

### 使い方

```bash
bash src/test-fixtures/step5/verify-l-part-beta-sample-lookup.sh
```

### Exit code

| code | 意味 |
|---|---|
| 0 | PASS (= 全 6 gate 通過) |
| 1 | verify fail (= gate 落ち、 出力で fail gate 明示) |
| 2 | infra fail (= build / MAME / trace file missing 等) |

### 動作

1. sample A (= l-part-sample-a.mml、 `L @0 o4 l1 c`) build + MAME trace
2. sample B (= l-part-sample-b.mml、 `L @1 o4 l1 c`) build + MAME trace
3. 動的に各 trace から PART_OFF_INSTRUMENT / ADPCM-A reg 値を抽出
4. 6 段階 gate を逐次確認
5. exit code を返す

### robust 化 (= user 規律遵守)

- expected 値は **trace から動的取得** (= sample A trace の値を取得、 sample B と比較)
- hardcode 禁止
- build / linker / samples.inc 変動でも追従

## 6 段階 trace gate 詳細

### gate 1: sample A build + trace

- build-poc.sh で sample A 用 `.MN` を ROM embed
- MAME headless で trace 取得 (= ymfm-trace + z80-mem-trace)
- 自動化 (= infra fail 時 exit 2)

### gate 2: sample B build + trace

- 同様、 sample B 用

### gate 3: PART_OFF_INSTRUMENT 差分

- **source**: z80-mem-trace (= 0xFAFF への write)
- **判定**: sample A `0x00` ≠ sample B `0x01`
- **意義**: comat_pcm 経路 (= β-2a) が動いている直接証拠

### gate 4: reg 0x10 (start LSB) 差分

- **source**: ymfm-trace port B reg `110`
- **判定**: sample A `0x00` ≠ sample B `0x04` (= bd vs sd 起点 addr 差)
- **意義**: voice index 引き (= β-2b) が動いている直接証拠

### gate 5: reg 0x20 (stop LSB) 差分

- **source**: ymfm-trace port B reg `120`
- **判定**: sample A `0x03` ≠ sample B `0x06` (= bd vs sd 終点 addr 差)
- **意義**: gate 4 と並列、 sample 範囲全体が反映されている確認

### gate 6: 同一性検証

| reg | ymfm 表記 | sample A | sample B | 期待 | 役割 |
|---|---|---|---|---|---|
| 0x18 start MSB | 118 | 0x00 | 0x00 | 同一 | sample addr < 1024 byte (= MSB 0) |
| 0x28 stop MSB | 128 | 0x00 | 0x00 | 同一 | 同上 |
| 0x08 vol/pan | 108 | 0xC0 | 0xC0 | 同一 | pan/vol 設定は voice に依存しない |
| 0x00 keyon | 100 | 0x01 | 0x01 | 同一 | ch 0 keyon は voice に依存しない |

reg 0x18/0x28 が両者 `0x00` なのは、 bd/sd の sample addr が ROM 起点近く (= < 1024 byte) で MSB が両方 0 のため。 これは **正常な期待値** (= 機能的差分は LSB のみで十分)。

## β-3 実行結果 (= 2026-05-12 自動 PASS 確認)

```
=== gate 1: sample A (= @0) build + trace ===
  ✅ sample A trace 取得 (wav sha256: c92c737a37a85d29...)

=== gate 2: sample B (= @1) build + trace ===
  ✅ sample B trace 取得 (wav sha256: 4a4b322d88ad968c...)

=== gate 3: PART_OFF_INSTRUMENT 差分 ===
  sample A: 0x00 (= voice 0)
  sample B: 0x01 (= voice 1)
  ✅ 差分検出

=== gate 4: reg 0x10 (start LSB) 差分 ===
  sample A: 0x00 (= bd start LSB)
  sample B: 0x04 (= sd start LSB)
  ✅ 差分検出

=== gate 5: reg 0x20 (stop LSB) 差分 ===
  sample A: 0x03 (= bd stop LSB)
  sample B: 0x06 (= sd stop LSB)
  ✅ 差分検出

=== gate 6: reg 0x18/0x28/0x08/0x00 同一性検証 ===
  ✅ reg 0x18 (start MSB): 両 0x00 同一
  ✅ reg 0x28 (stop MSB): 両 0x00 同一
  ✅ reg 0x08 (vol/pan): 両 0xC0 同一
  ✅ reg 0x00 (keyon): 両 0x01 同一

🎉 PASS (exit 0)
```

## 音声 gate (= 参考情報)

wav sha256:
- sample A: `c92c737a37a85d29e8d421c6b1abc240b6d9f49cdfffaab6ae16446665dd7630`
- sample B: `4a4b322d88ad968c34703d69c6828216c769430e4fd9a53128f821f9c613ace0`

異なる (= `@0` / `@1` で audible 差分発生)。 ただし FM 同居 audio (= α-3 audio finding 経験) で primary gate にしない。 参考情報のみ。

## β 全体完了 (= ADR-0019 §決定 6 sub-sprint β)

| sub | commit | 内容 |
|---|---|---|
| β-0 (= 調査) | (commit なし) | mc compiler `@<n>` semantics 確定、 `0xFF nn` emit 確認 |
| β-1 | `b3b1683` | sample A/B fixture + `.MN` diff fixture-driven 固定 |
| β-2a | `0029034` | PART_OFF_INSTRUMENT field + 0xFF cmd CHIP_TYPE=2 path 追加 |
| β-2b | `93bfc3d` | adpcma_keyon_simple voice index 引き refactor + reg 差分検出 |
| β-3 (= 本 commit) | (本 commit) | verify script + handoff doc (= regression test 化) |

## γ への引継ぎ事項

### γ = ch 軸拡張 (= 議題 5 後段、 議題 6 sub-sprint γ)

α/β で L ch only (= ADPCM-A ch 0) 経路が完成。 γ では M/N/O/P/Q (= ADPCM-A ch 1-5) を順次追加:

1. **MML fixture 拡張**:
   - 例: `L @0 o4 l1 c` + `M @1 o4 l1 c` + ... (= 多 ch 同時 keyon)
   - もしくは「L → M → ... → Q を時系列で順次 keyon」
2. **driver 改修範囲**:
   - 既存 pmdneo_song_main_loop は part 11-16 (= L-Q) を iterate 済 (= α-2 で確認)
   - adpcma_keyon_simple は ch index (= B) を reg base 計算で再利用 (= β-2b で確認)
   - **M-Q part も同じ chain が動くはず** (= 議題 5 「sample lookup 成立後の ch 軸拡張」)
3. **γ verify script 拡張**:
   - β-3 verify-l-part-beta-sample-lookup.sh の派生
   - 各 ch (= L/M/N/O/P/Q) で reg 0x10+ch / 0x18+ch / 0x20+ch / 0x28+ch / 0x08+ch / 0x00 keyon bit を確認
   - ch 軸独立性: ch 0 keyon (= 0x01) と ch 1 keyon (= 0x02) が別 bit で立つ
4. **fixture / verify infra**:
   - β-3 で確立した「動的 trace 抽出 + 差分 / 同一性自動判定」 構造を γ 用に拡張

### β-3 が γ に提供する infrastructure

| 提供物 | γ での再利用 |
|---|---|
| 動的 trace 抽出 logic | ch ごとに 0xFAE0 / 0xFB20 / ... を iterate |
| reg 値差分 / 同一性判定 | 各 ch reg 0x10+ch 等を ch ごと比較 |
| sample A/B 並列 build | M-Q 各 ch 用 fixture 並列 build |
| 6 段階 trace gate 構造 | ch 軸 verify に展開可 |

### γ 注意点 (= β 経験からの教訓)

- **K/R compat 副作用**: γ で M-Q を動かしても K/R rhythm は別経路 (= 議題 2)、 副作用なし継続
- **scope 厳守**: γ では ch 軸のみ、 sample lookup の更なる拡張 (= 同時複数 voice 等) は scope-out
- **audio gate**: FM 同居問題は γ でも継続、 trace primary gate 維持
- **trivial verify 防止**: 各 ch で「voice index → PART_OFF_INSTRUMENT → reg 0x10+ch」 chain が **本当に通っているか** を ch ごと trace 確認

### γ では touch しない範囲

- `.PNE` parser
- samples.inc 構造
- K/R rhythm path
- vol/pan hook (= δ で扱う)

## β-3 完了判定

- ✅ verify script 作成 + 自動 PASS (exit 0)
- ✅ handoff doc 作成 (= 本 doc)
- ✅ driver 実装変更なし (= regression test 化のみ)
- ✅ β-2 chain 全段階 fixture-driven verify 化
- ✅ γ への引継ぎ事項明記

## 関連

- **commit**: β-1 b3b1683 / β-2a 0029034 / β-2b 93bfc3d / β-3 (= 本 commit)
- **ADR**: ADR-0019 §決定 6 sub-sprint β
- **handoff**: 
  - `docs/design/handoff/adr-0016-step5-alpha-1-mn-layout.md` (= α-1 ground truth)
  - `docs/design/handoff/adr-0016-step5-alpha-2-trace-gate-findings.md` (= α-3 trace gate + audio finding)
  - `docs/design/handoff/adr-0016-step5-beta-1-sample-fixture-findings.md` (= β-1 fixture)
- **fixture**:
  - `src/test-fixtures/step5/l-part-minimum.mml` (= α 用 baseline)
  - `src/test-fixtures/step5/l-part-sample-a.mml` (= β 用 @0)
  - `src/test-fixtures/step5/l-part-sample-b.mml` (= β 用 @1)
- **verify script**:
  - `src/test-fixtures/step5/verify-l-part-alpha-trace-gate.sh` (= α-3)
  - `src/test-fixtures/step5/verify-l-part-beta-sample-lookup.sh` (= β-3、 本 commit)
- **memory**: 
  - `project_adr_0016_step5_design_decision_5_verify_sample_first.md` (= 議題 5)
  - `feedback_audio_gate_solo_isolation.md` (= α-3 経験、 β/γ でも適用)

β-3 で sub-sprint β 完全終了。 次は γ (= ch 軸拡張、 M-Q 6 ch 独立 dispatch verify) 着手前 user 擦り合わせ。
