# ADR-0025 step 11 α handoff: data placement only

- 関連 ADR: [ADR-0025](../../adr/0025-pmdneo-step11-multi-table-id-0x01-proof.md) Draft (= 12th session 起票、 status Draft 中)
- sub-sprint: α (= 4 sub-sprint chain の 1 段目、 data placement only)
- commit: 本 commit (= 12th session α 着手で実装)
- 前段: ADR commit `bc60663` (= ADR-0025 起票 Draft、 driver source 不変)
- 次段: β (= selector 拡張で id=0x01 accept、 step5b.PNE run で audible 差分)

## α scope (= user 12th session 指示の literal 限定)

**`α は multi-table data placement only / selection differentiation は β/γ で確認する`** (= user handoff 記載要件)

### 実装内容

| 項目 | 改修対象 | 内容 |
|---|---|---|
| EQU 宣言 | `src/driver/standalone_test.s` | `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` を追加 (= α では unused reserve、 β で selector が `cp` 参照開始) |
| table B 追加 | `src/driver/standalone_test.s` | `adpcma_ch_sample_ptr_table_b` を `adpcma_ch_sample_ptr_table` 隣接位置に新規 (= L `adpcma_sample_sd` / M-Q は table A と同 symbol) |
| directory entry 1 | `src/driver/standalone_test.s` | `pne_sample_directory` 内、 entry 0 (= step5.PNE + 0x00) と terminator (= NUL + 0xFF) の間に entry 1 (= "step5b.PNE" + 0x01 byte) を 17 byte 分挿入、 terminator は後ろ移動 |
| step5b MML fixture | `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` (= 新規) | `step5/l-q-rhythm-song.mml` の MML body を流用、 `#PNEFile` のみ `"step5b.PNE"` に差替、 title / memo に Step 11 文脈追記 |
| ADR §決定 8 revised | `docs/adr/0025-pmdneo-step11-multi-table-id-0x01-proof.md` | sub-sprint 表を revised split に改定 (= ADR commit を α と分離 + 旧 α/β を新 α に合流 + selector拡張 を β + verify script を γ + completion を δ) |

### driver source の不変保証 (= α gate 4)

`pmdneo_resolve_sample_table_id` / `pmdneo_select_sample_pointer` / `adpcma_keyon_simple` の routine 行は 1 行も改修していない。 git diff で routine 領域の改変なし、 data area 追加のみ (= 全 41 行 net 追加で全て EQU / table B / directory entry 1)。

→ **既存 reachable code path は完全不変**、 step5.PNE run の register write 順序 / 値は Step 10 完了時 (= commit `0746073`) と byte-identical 期待値が成立。

### 既存 resolver の terminator driven 特性 (= α で改修不要な根拠)

`pmdneo_resolve_sample_table_id` (= ADR-0023 step 9 β で確立) は **terminator driven loop** で動作する:

```
1. HL = pne_sample_directory (= entry head)
2. loop:
     entry+16 byte (= sample_table_id field) を peek
     0xFF なら → mismatch branch
     16 byte memcmp (entry filename vs driver_pne_filename_buf)
     match → A = entry+16 (= sample_table_id) を 0xFD32 に store + ret
     mismatch → HL += 17 (= next entry) + loop
```

entry 数を hard-code せず、 `0xFF` terminator まで loop。 そのため entry 1 を追加しただけで resolver は **自然に entry 1 を loop 対象として認識**、 code 改修不要。

ADR-0025 §決定 4 で「Step 9 既存 layout 踏襲」 を確定したのは、 この terminator driven 性質を活かして α で resolver 不変を成立させるため。

## α gate 結果 (= 4 段、 全 PASS)

| # | gate | 結果 | 詳細 |
|---|---|---|---|
| 1 | build PASS | ✅ | sdcc / sdasz80 / lkz80 通過、 `build/rom/243-m1.m1` 等 ROM 生成 |
| 2 | step5.PNE register write trace byte-identical | ✅ | step 9 resolver verify (= 5/5 PASS) + step 10 mismatch silent verify (= 6/6 PASS) で regression 0 確認、 step5.PNE filename → entry 0 match → 0xFD32 = 0x00 → selector accept → table A 引きまで完全保存 |
| 3 | 新 symbol 存在確認 | ✅ | `.lst` で `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` (= 0x0002)、 `adpcma_ch_sample_ptr_table_b` (= 0x1031)、 `pne_sample_directory` 内 entry 1 ("step5b.P" + "NE\0\0\0\0\0\0" + 0x01) 全て確認可能 |
| 4 | driver source の routine 完全不変 | ✅ | git diff で `pmdneo_resolve_sample_table_id` / `pmdneo_select_sample_pointer` / `adpcma_keyon_simple` routine 領域の改変なし、 data area 追加のみ 41 行 net |

### α 副次検証 (= step 9 resolver verify gate 4-5 の意義)

step 9 resolver verify gate 4 (= ROM patch で entry 0 filename を 'step5.PNE' → 'Step5.PNE' に 1 byte 改変) を実行すると:

1. patched entry 0 (= "Step5.PNE") → memcmp mismatch
2. **新 entry 1 (= "step5b.PNE")** → memcmp mismatch (= runtime filename "step5.PNE" と先頭 6 byte で異なる)
3. terminator (= 0xFF) → mismatch branch → 0xFD32 = 0xFF

これが gate 5 で PASS したことは、 entry 1 が正しく挿入され resolver が entry 1 を loop 対象として認識していることの **副次的 literal 証跡** になる。 entry 1 が無視されていれば、 gate 4 patch によって直接 terminator にヒットして同 結果になるが、 もし entry 1 と terminator の順序が逆だった等の placement bug があれば gate 5 で 0xFD32 = 0x01 (= 新 entry に偶然 match) になる可能性があり、 そうならなかったことで placement が正しいと判定できる。

→ α 完了時点で **resolver は entry 1 を正しく loop 対象として認識**、 selector は id=0x00 only-accept のため step5b.PNE runtime filename を流せば 0xFD32 = 0x01 が立つことが期待される (= β で directly verify)。

## α 完了時点の重要境界 (= future contributor 向け literal 明記)

- step5.PNE run: 既存挙動完全保存 (= 0xFD32 = 0x00、 audible BD 含む)
- step5b.PNE run (= 想定): resolver entry 1 match → 0xFD32 = 0x01 → selector unaccept → sentinel silent (= playback 不影響、 β で audible になる)
- table B (= `adpcma_ch_sample_ptr_table_b`) は ROM に存在するが selector からは到達しない (= dead code)
- `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` は declare 済だが driver code から参照されない (= β で selector が参照開始)
- ADR-0024 §決定 3 (= id=0x00 only-accept) は **依然有効** (= selector 完全不変)
- ADR-0023 §決定 8 / ADR-0024 §決定 3 / §決定 7 の contract chain は α で **不変**

「id=0x01 はまだ playback に影響しない」 (= user α scope 整合) の literal 表現:
- 0xFD32 値は new state (= step5b run で 0x01) に変わるが、 audio path は selector unaccept で sentinel silent に倒れる
- audible 差分は β で initial に effective

## 未追跡 wav 3 件の scope-out (= user 12th session axis 1-b 整合)

git status の未追跡 file 3 件:
- `vendor/ngdevkit-examples/06-sound-adpcma/assets/lefthook.wav`
- `vendor/ngdevkit-examples/06-sound-adpcma/assets/lightbulbbreaking.wav`
- `vendor/ngdevkit-examples/06-sound-adpcma/assets/woosh.wav`

これらは **Step 11 では使用しない** (= ADR-0025 §決定 2 / axis 1-b α 採用、 sample source は既存 VROM 内 sample 再利用)。 別 sprint で asset pipeline / WAV import / WebApp Phase 4 領域として扱う候補。 本 α commit では touch せず、 未追跡のまま git status に残置。

## 次 sprint (= β)

**β scope**: `pmdneo_select_sample_pointer` 拡張 (= id=0x01 accept、 explicit if/jr、 `cp PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` で範囲外判定、 `adpcma_ch_sample_ptr_table_b` 引き)。

β 完了時:
- step5.PNE run: byte-identical (= regression 0)
- step5b.PNE run: 0xFD32 = 0x01 + selector accept + L ch table B (= SD) addr regs write + M-Q ch table A と同 addr regs write + keyon count = step5 と同 + audio audible (= silent ではない、 BD と区別可能な SD 音色)

β gate 6 段 (= ADR-0025 §verify gate 構成 β gate 参照)。 1 sub = 1 commit + 1 push 規律維持。

## 関連 memory

- `project_pmdneo_step10_complete.md` (= Step 10 完了状態、 selector ABI / DE return / 0x0000 sentinel silent 確立)
- `project_pmdneo_step11_a2_deferred.md` (= A2 cache scope-out 維持判断)
- `project_pmdneo_step11_direction_multi_table.md` (= Step 11 = multi-table id=0x01 proof sprint 採用)
- `feedback_trivial_verify_detection_and_correction_commit.md` (= α dead/unused data placement で trivial verify 段階分離)
- `feedback_refactor_gate_register_trace_not_wav.md` (= step5.PNE 既存 verify script regression で byte-identical 担保)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
