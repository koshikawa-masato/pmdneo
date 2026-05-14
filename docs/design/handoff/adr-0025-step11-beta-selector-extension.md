# ADR-0025 step 11 β handoff: selector accept rule 拡張

- 関連 ADR: [ADR-0025](../../adr/0025-pmdneo-step11-multi-table-id-0x01-proof.md) Draft (= 12th session 起票、 status Draft 中)
- sub-sprint: β (= 4 sub-sprint chain の 2 段目、 selector accept rule 拡張)
- commit: 本 commit (= 12th session β 着手で実装)
- 前段: α commit `ead638f` (= data placement only、 driver routine 0 改修)
- 次段: γ (= verify-step11-multi-table.sh 新設 + differential proof literal assert)

## β scope (= user 12th session 指示の literal 限定)

**`β は selector accept rule 拡張 / γ が observable differentiation proof`** (= user handoff 記載要件)

### 実装内容 (= 単一 routine 拡張)

`pmdneo_select_sample_pointer` (= ADR-0024 §決定 4 ABI 維持) に id=0x01 branch を追加。 改修対象は本 routine のみ、 他 driver source は完全不変。

#### 拡張前後の対比 (= structure level)

**拡張前** (= α 完了時 / Step 10 final):
```
pmdneo_select_sample_pointer:
        ld      l, a
        ld      a, (driver_pne_sample_table_id)
        or      a
        jr      nz, select_unknown_id           ; id != 0 → silent
        ;; (id == 0 直結 table A 引き)
        ld      h, #0
        add     hl, hl
        ld      de, #adpcma_ch_sample_ptr_table
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ret

select_unknown_id:
        ld      de, #0x0000
        ret
```

**拡張後** (= β / ADR-0025 §決定 5 整合):
```
pmdneo_select_sample_pointer:
        ld      l, a
        ld      a, (driver_pne_sample_table_id)
        cp      #PNE_SAMPLE_DIRECTORY_ENTRY_COUNT
        jr      nc, select_unknown_id           ; id >= EQU → silent
        or      a
        jr      z, select_table_a               ; id == 0 → table A
        cp      #1
        jr      z, select_table_b               ; id == 1 → table B
        jr      select_unknown_id               ; future: cp #2 / jr z, ... 拡張点

select_table_a:
        ld      h, #0
        add     hl, hl
        ld      de, #adpcma_ch_sample_ptr_table
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ret

select_table_b:
        ld      h, #0
        add     hl, hl
        ld      de, #adpcma_ch_sample_ptr_table_b
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ret

select_unknown_id:
        ld      de, #0x0000
        ret
```

#### 改修要点

| 改修点 | 内容 | ADR-0025 整合 |
|---|---|---|
| EQU 上限判定 | `cp #PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` + `jr nc, select_unknown_id` で id ≥ EQU を sentinel に倒す | §決定 5 / axis 4-e |
| explicit if/jr dispatch | `or a` / `cp #1` で id=0 / id=1 を判定、 fall-through で sentinel | §決定 5 / axis 4-a |
| select_table_a 分離 | id=0x00 path を独立 label 化 (= 既存 table A 引きを保存) | §決定 5 / axis 4-c |
| select_table_b 新規 | id=0x01 path 新規追加、 `adpcma_ch_sample_ptr_table_b` 引き | §決定 5 / axis 4-c |
| `_b` suffix 命名 | label / table 命名で filename `step5b.PNE` と命名軸を揃える | §決定 5 / axis 4-c |
| sentinel 流用 | mismatch / 上限超え / 中間 id 未実装 のいずれも既存 sentinel path に倒す | §決定 5 / axis 4-d |

#### 不変保証 (= β でも改修しない部分)

- ABI = 入力 A + 0xFD32 read、 出力 DE = pointer or 0x0000、 clobber A/HL、 preserve BC/IX/IY (= ADR-0024 §決定 4 維持)
- `adpcma_keyon_simple` keyon path (= ADR-0024 §決定 5 で確立した最終形、 β でも完全不変)
- `pmdneo_resolve_sample_table_id` resolver (= ADR-0023 step 9 で確立、 terminator driven、 完全不変)
- `adpcma_ch_sample_ptr_table` table A (= ADR-0024 §決定 2 / 1-A 再利用維持)
- `adpcma_ch_sample_ptr_table_b` table B (= α で配置済、 β で initial に reachable になる)
- voice >= 6 range check (= keyon 側責務、 routine 内に二重 check を持たせない、 ADR-0024 §決定 5 整合)

## β gate 結果 (= user 完了条件 4 件、 minimal proof)

| # | gate | 結果 | 詳細 |
|---|---|---|---|
| 1 | build PASS | ✅ | sdcc / sdasz80 / lkz80 通過、 ROM 生成 |
| 2 | id=0x00 path は既存と同等 | ✅ | step 9 resolver verify 5/5 PASS (= step5.PNE filename → 0xFD32 = 0x00) + step 10 mismatch silent verify 6/6 PASS (= match path keyon 41 / mismatch path 2 / diff 39 / sample setup 156→0)、 step5.PNE runtime register write trace functionally unchanged |
| 3 | id=0x01 path が table B を返せる | ✅ | `.lst` で 4 ラベル全確認: `pmdneo_select_sample_pointer` @ `0x10B7` / `select_table_a` @ `0x10C8` / `select_table_b` @ `0x10D3` / `select_unknown_id` @ `0x10DE`、 select_table_b は `adpcma_ch_sample_ptr_table_b` を `ld de, #` で参照する compiled code を持つ |
| 4 | differential proof は最小 | ✅ | 動的 step5b 差分検証は γ scope (= verify-step11-multi-table.sh で正式 literal value assert)、 β では compile 構造 + step5.PNE regression のみ |

## β 完了時点の重要境界 (= future contributor 向け literal 明記)

- selector は **id=0x00 + id=0x01 の 2 値を accept**、 それ以外 (= mismatch 0xFF + id >= EQU + EQU >= 3 with 中間 id 未実装) は sentinel silent
- ADR-0024 §決定 3 (= id=0x00 only-accept) は本 β で **{0x00, 0x01} accept に拡張**、 ADR-0025 §決定 5 / axis 4-e で「`id >= PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` は sentinel」 と上限規約化
- step5.PNE run (= 0xFD32 = 0x00): table A 引き → 既存挙動完全保存 (= regression 0)
- step5b.PNE run (= 0xFD32 = 0x01): table B 引き → L ch = `adpcma_sample_sd` 引き → SD addr regs write → audible 差分 (= ただし dynamic verify は γ scope)
- ADR-0024 §決定 4 (= 中間 routine ABI) は **完全不変**、 β は internal dispatch のみ拡張
- ADR-0025 §決定 6 / axis 5 の hybrid gate (= L differ + M-Q identical + keyon count identical の 3 観点同時) は **γ で initial に literal 観測**、 β では compile 構造保証まで
- keyon path (= `adpcma_keyon_simple`) は完全不変、 caller 側は β で何も変わらない (= ADR-0024 §決定 5 整合)

「γ が observable differentiation proof」 (= user 整理):
- β = selector code 拡張による「id=0x01 path が table B を返せる」 構造保証
- γ = step5.PNE / step5b.PNE 比較で「L addr regs が実際に differ する / M-Q が identical / keyon count が identical」 を runtime observation で証明 + literal value assert で trivial verify 防止

## 次 sprint (= γ)

**γ scope**: `verify-step11-multi-table.sh` 新設 (= differential proof script、 BD addr literal / SD addr literal 具体値 assert で trivial verify 防止)。

γ 完了時:
- script PASS (= L ch addr regs differ literal + M-Q addr regs identical + keyon count identical の 3 観点同時 + 具体値 assert)
- step 5/6/7/8/9/10 既存 verify script regression 全件確認
- selection differentiation が initial に observable な literal proof として固定

γ gate 8 段 (= ADR-0025 §verify gate 構成 γ gate 参照)。 1 sub = 1 commit + 1 push 規律維持。

## 関連 memory

- `project_pmdneo_step10_complete.md` (= Step 10 完了、 selector ABI 確立、 本 β で ABI 完全保存)
- `project_pmdneo_step11_direction_multi_table.md` (= Step 11 sprint 採用判断、 multi-table id=0x01 proof scope)
- `feedback_trivial_verify_detection_and_correction_commit.md` (= β は code 拡張、 動的 verify は γ で分離する規律)
- `feedback_refactor_gate_register_trace_not_wav.md` (= step5.PNE regression を register trace で担保)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
