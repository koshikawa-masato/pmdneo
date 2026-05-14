# ADR-0025 step 11 γ handoff: differential proof verify script 確立

- 関連 ADR: [ADR-0025](../../adr/0025-pmdneo-step11-multi-table-id-0x01-proof.md) Draft (= 12th session 起票)
- sub-sprint: γ (= 4 sub-sprint chain の 3 段目、 verify infra 確立)
- commit: 本 commit
- 前段: β commit `a02a696` (= selector accept rule 拡張で id=0x01 → table B)
- 次段: δ (= 全 12 script regression + user 試聴 + ADR-0025 Accepted 移行 + 完了統合)

## γ scope (= ADR-0025 §決定 6 / axis 5 整合)

**selection differentiation が observable な literal proof の確立**。 β で selector 拡張により id=0x01 → table B の compile 構造は成立、 γ で step5.PNE / step5b.PNE 各 run の register write trace を runtime 比較して「L addr 違う / M-Q 同じ / keyon count 同じ」 の 3 観点同時 + literal value assert で proof 固定。

### 実装内容

| 項目 | 改修対象 | 内容 |
|---|---|---|
| differential proof script 新設 | `src/test-fixtures/step11/verify-step11-multi-table.sh` | step5 / step5b 各 fixture を build + MAME run + trace 比較、 7 gate で literal proof 固定 |
| step5b fixture CRLF 変換 | `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` | α 起票時 LF だったのを CRLF に変換 (= PMDDotNET compile 要件、 memory `feedback_pmddotnet_mml_authoring_rules` 整合) |

### driver source の不変保証

driver source (= `standalone_test.s`) は β commit `a02a696` 完了状態から **完全不変**。 γ は verify infrastructure 新設のみで code 改修なし。

## γ verify script の 7 gate 構造

| # | gate | 検証内容 |
|---|---|---|
| 1 | step5.PNE build + trace | l-q-rhythm-song.mml (= `#PNEFile "step5.PNE"`) で build、 trace 取得 |
| 2 | step5 `0xFD32` = `0x00` | memory inspection で entry 0 match 確認 (= resolver 正しく動作) |
| 3 | step5b.PNE build + trace | l-q-rhythm-song-step5b.mml (= `#PNEFile "step5b.PNE"`) で build、 trace 取得 |
| 4 | step5b `0xFD32` = `0x01` | memory inspection で entry 1 match 確認 (= resolver が新 entry を見て id=0x01 立てた) |
| 5 | L ch addr regs literal value assert | port B reg `0x10/0x18/0x20/0x28` (= L ch start LSB/MSB + stop LSB/MSB) を step5 = BD literal `0x00/0x00/0x03/0x00` / step5b = SD literal `0x04/0x00/0x06/0x00` で具体値 assert。 LSB reg で少なくとも 2 件 differ 必須 (= trivial verify 防止)。 |
| 6 | M-Q ch addr regs identical | port B reg `0x11-0x15/0x19-0x1D/0x21-0x25/0x29-0x2D` (= ch 1-5 で 20 reg) を step5 / step5b で 0 件 differ assert (= 副作用なし証明) |
| 7 | keyon count identical | port B reg `0x00` (= ADPCM-A keyon control) の write count を step5 / step5b で literal 一致 assert (= silent 経路ではない、 別 sample が選ばれた literal proof) |

### gate 5 重要 finding (= MSB reg は偶然同値)

```
reg 0x10 (start_lsb): step5 = 0x00 (BD literal) / step5b = 0x04 (SD literal) — DIFFER
reg 0x18 (start_msb): step5 = 0x00 / step5b = 0x00 (= BD_*_MSB と SD_*_MSB は偶然同値)
reg 0x20 (stop_lsb):  step5 = 0x03 (BD literal) / step5b = 0x06 (SD literal) — DIFFER
reg 0x28 (stop_msb):  step5 = 0x00 / step5b = 0x00 (= 同上)
```

BD と SD はどちらも VROM `0x000-0xFFF` 範囲内に配置されているため、 MSB byte は両方 `0x00`。 これは bug ではなく **sample 配置上の偶然**。 verify script は LSB reg で differ を要求することで differentiation 証拠を担保 (= MSB が同値でも literal assert で具体値を固定するので trivial verify 化しない)。

### gate 7 重要安全装置: keyon count identical

ADR-0025 §決定 6 / axis 5-b で確立した重要安全装置:
- step5 keyon count = `41`
- step5b keyon count = `41`
- Step 10 baseline (= 11th session): match path 41 / mismatch silent 2

step5b が mismatch silent path に倒れていれば keyon count = 2 になる。 41 は table B selection が正しく effective である literal 証跡 (= 「同じ回数鳴る、 でも別 sample」)。 これがないと「差分はあるが silent に倒れただけ」 と区別できない。

## γ gate 結果 (= 全 7 gate PASS)

| # | gate | 結果 |
|---|---|---|
| 1 | step5.PNE build + trace | ✅ |
| 2 | step5 `0xFD32` = `0x00` | ✅ (= 6 件 idempotent) |
| 3 | step5b.PNE build + trace | ✅ |
| 4 | step5b `0xFD32` = `0x01` | ✅ (= 6 件 idempotent、 entry 1 match) |
| 5 | L ch addr regs literal assert | ✅ (= step5 BD `0x00/0x00/0x03/0x00` / step5b SD `0x04/0x00/0x06/0x00`、 LSB 2 件 differ) |
| 6 | M-Q ch addr regs identical | ✅ (= 20 reg × ch 1-5 で 0 件 differ) |
| 7 | keyon count identical | ✅ (= step5 41 / step5b 41) |

driver source は β commit 状態から完全不変なので step 9/10 verify script の regression は β commit と同等 PASS 期待。 全 12 script (= step 5-10) regression は δ scope。

## γ で発見された finding (= 後続作業者向け記録)

### finding 1: step5b MML fixture は CRLF 必須 (= α 起票時 LF だった)

α commit `ead638f` で起票した `l-q-rhythm-song-step5b.mml` は LF line terminator だったが、 PMDDotNET compile は **CRLF 必須** (= memory `feedback_pmddotnet_mml_authoring_rules` 整合)。 LF のままだと compile が hang する。 γ で `perl -i -pe 's/\r?\n/\r\n/g'` で CRLF 変換。 α 時点では step5b fixture は build されなかった (= α scope = data placement only) ため発見が γ になった。 future contributor は MML fixture 新規作成時 CRLF を必ず確認すべき。

### finding 2: BD / SD の MSB は偶然同値 (= 0x00)

ADR-0025 §決定 6 / axis 5 で「L ch addr regs differ literal」 を期待していたが、 実装すると MSB reg (= `0x18/0x28`) は両方 `0x00` で differ しない。 これは BD / SD が両方 VROM 0x000-0xFFF 範囲内に配置されているため。 verify script は LSB reg (= `0x10/0x20`) で differ を要求することで対応。 文書化済み (= 本 handoff + script 内 comment)。

### finding 3: macOS /bin/bash 3.2 では `declare -A` 未対応

verify script 初版で `declare -A` (= associative array) を使ったが、 macOS default `/bin/bash` 3.2 では未対応で fail。 case 文に書き換えて bash 3.2 互換にした。 全 verify script は `/bin/bash` でも動く必要がある。

## γ 完了時点の重要境界

- selection differentiation が observable な literal proof として固定 (= `0xFD32` の id 切替で L ch addr が変わり、 副作用なし、 silent ではない)
- step5b.PNE = SD audible path が完成 (= γ wav file で確認可能、 user 試聴は δ で確定)
- driver source は β から完全不変 (= γ scope は verify infra のみ)
- 全 12 script regression は δ scope (= step 5/6/7/8/9/10 既存 verify 全件 serial PASS 確認)

## 次 sprint (= δ)

**δ scope**: 全 12 script regression serial 実行 + user 試聴 (= step5 BD audible / step5b SD audible) + ADR-0025 Accepted 移行 + completion handoff doc + memory `project_pmdneo_step11_complete.md` 起票 + MEMORY.md index 更新。

δ gate (= ADR-0025 §verify gate δ 参照):
- silent-bcef fixture audible regression なし
- step 5/6/7/8/9/10/11 全 12 + 1 = 13 script regression PASS
- user 試聴 OK
- handoff + ADR Accepted + memory

## 関連 memory

- `feedback_pmddotnet_mml_authoring_rules.md` (= CRLF 必須 + #Title header + OPNA part letter、 finding 1 の根拠)
- `feedback_record_unexpected_findings.md` (= finding 1-3 を memory 起票候補)
- `feedback_verify_script_serial_execution.md` (= verify script 群は serial 実行、 δ で適用)
- `feedback_refactor_gate_register_trace_not_wav.md` (= γ proof は register trace 軸、 wav sha256 は使わない)
- `project_pmdneo_step10_complete.md` (= step 10 keyon count baseline = match 41 / mismatch silent 2)
- `project_pmdneo_step11_direction_multi_table.md` (= Step 11 sprint scope 整合)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
