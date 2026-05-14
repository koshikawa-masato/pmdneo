# ADR-0024 step 10 α handoff: ADR-0024 起票 + `pmdneo_select_sample_pointer` routine 単体実装 (= dead code 状態、 call insertion 未挿入)

- 日付: 2026-05-14 (= 11th session、 α 着手)
- 対応 ADR: [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) §決定 8 α
- 関連 commit: 本 handoff doc を含む α 着手 commit

## α scope (= 1 commit + 1 push)

> **重要境界 (= future contributor 向け短文明記)**: Step 10 α 時点では `sample_table_id` (= 0xFD32) は **playback path にまだ影響しない**。 routine は存在するが driver 内のどこからも呼出されない (= dead code)、 id=0x00 / 0xFF の違いはまだ音に現れない。 β で `adpcma_keyon_simple` への call insertion により selection semantics が initial に playback path に反映される。

- `docs/adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md` 起票 (= Draft 章 1-5 全章記述、 Annex は δ で追記)
- `src/driver/standalone_test.s` 内に `pmdneo_select_sample_pointer` routine を新規追加
- 配置: step 9 β で追加した `pmdneo_resolve_sample_table_id` 直後 (= L2947 `resolve_mismatch:` の ret 直後)、 `rhythm_main:` 直前 (= step 9 routine と隣接配置、 resolve / select の責務隣接で readability 確保)
- routine 単体実装:
  - 入力 A = voice index、 memory read `driver_pne_sample_table_id` (= 0xFD32)
  - id == 0x00 path: voice * 2 → `adpcma_ch_sample_ptr_table` 引き → DE = sample header pointer
  - id != 0x00 path: DE = 0x0000 sentinel (= silent)
  - clobber A, HL / preserve BC, IX, IY
- `adpcma_keyon_simple` への call insertion は **しない** (= β scope)
- routine は **存在するが未参照** の状態で閉じる
- playback path (= `adpcma_keyon_simple` 等) は完全不変

## 実装差分

### routine 実装 (= `standalone_test.s` L2950-3013)

```asm
;;; ----------------------------------------------------------------
;;; ADR-0024 step 10 α: pmdneo_select_sample_pointer
;;;
;;; ADR-0024 §決定 1/4 整合: 中間 routine 経由 pointer 返却 (= A2 採用)
;;; α scope: routine 単体実装 (= dead code 状態、 keyon 未接続)。
;;;          β で adpcma_keyon_simple から call insertion。
;;;
;;; ADR-0024 §決定 2 (= 1-A 採用): id=0x00 canonical table は既存
;;;          adpcma_ch_sample_ptr_table を再利用。
;;; ADR-0024 §決定 3 (= 2-C 採用): id=0x00 only-accept、 それ以外 (= 0xFF
;;;          + 全 unknown) は 0x0000 sentinel で silent。
;;; ADR-0024 §決定 4 整合: ABI = 入力 A + 0xFD32 read、 出力 DE = pointer
;;;          or 0x0000、 clobber A/HL、 preserve BC/IX/IY。
;;; ADR-0024 §決定 5 整合: voice >= 6 range check は呼出側責務、 routine
;;;          内で実施しない (= 二重 check を持たせない)。
;;; ADR-0024 §決定 7: ADR-0023 §決定 11「playback decision に使用しない」
;;;          contract は step 10 で解除。 本 routine の β call insertion で
;;;          0xFD32 が playback selection に effective になる。
pmdneo_select_sample_pointer:
        ld      l, a                            ; L = voice index
        ld      a, (driver_pne_sample_table_id) ; A = 0xFD32
        or      a
        jr      nz, select_unknown_id           ; id != 0x00 → silent sentinel
        ;; id == 0x00 path: voice index で adpcma_ch_sample_ptr_table 引き
        ld      h, #0
        add     hl, hl                          ; HL = voice * 2
        ld      de, #adpcma_ch_sample_ptr_table
        add     hl, de                          ; HL = sample ptr table entry addr
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                         ; DE = sample header pointer
        ret

select_unknown_id:
        ld      de, #0x0000
        ret
```

#### 設計判断

- **L = voice index 退避**: 入力 A を直接 0xFD32 read で上書きする前に L に保存。 後段の HL = voice * 2 計算で L 下位 byte を再利用するため、 push/pop 不要で stack 使用ゼロ
- **id 判定 `or a`**: A == 0 → Z set、 zero/non-zero 判定が 1 命令 1 byte で済む典型 Z80 idiom
- **HL 再利用**: id == 0x00 判定後、 H に 0 を書き L はすでに voice index なので、 `ld h, #0` + `add hl, hl` で HL = voice * 2 が直接出来上がる (= L の 2 重 load 不要)
- **DE pointer 返却**: 既存 `adpcma_keyon_simple` (= L2741、 0x0FA7) が DE で sample header pointer を保持し `inc de` で進める register convention に整合 (= ADR-0024 §決定 4)
- **clobber 最小**: A, HL のみ、 BC は preserve (= caller `adpcma_keyon_simple` の B = ch index を call 後そのまま使える)
- **voice range check 不実施**: ADR-0024 §決定 5 整合、 `adpcma_keyon_simple` L2747 で voice >= 6 ret skip 実施済前提 (= 4-A 採用の責務分担、 routine 内に二重 check を持たせない)

## 動作確認 (= α 完了条件 4 件)

### 条件 1: build PASS ✅

`bash scripts/build-poc.sh` で「=== build 完了 ===」 表示。 sdasz80 / sdldz80 / sdobjcopy / vromtool.py すべて PASS。

### 条件 2: routine symbol 存在 + 配置確認 ✅

`build/standalone_test.lst` 確認:

| symbol | addr | 内容 |
|---|---|---|
| `pmdneo_resolve_sample_table_id` (= step 9 β) | 0x1070 | step 9 既存 routine、 unchanged |
| `pmdneo_select_sample_pointer` (= step 10 α) | **0x109F** | 新規 routine entry |
| `select_unknown_id` (= step 10 α) | **0x10B1** | sentinel path entry |
| `rhythm_main` | 0x10B5 (= +22 byte shift) | step 9 β 時点では 0x109F、 routine 追加で shift |

routine size = 0x10B5 - 0x109F = **22 byte** (= match path 18 byte + sentinel path 4 byte)。

22 byte は妥当 size (= id 判定 + voice 引き + sentinel branch 込み、 ADR-0024 §決定 4 ABI 範囲内)。

### 条件 3: call insertion されていない (= dead code 確認) ✅

`src/driver/standalone_test.s` 全体に対して `pmdneo_select_sample_pointer` の参照を grep:

- L2950: コメント `;;; ADR-0024 step 10 α: pmdneo_select_sample_pointer`
- L2992: label 定義 `pmdneo_select_sample_pointer:`

→ **call 呼出箇所は 0 件**。 routine は定義されているが、 driver 内のどこからも呼ばれない。

### 条件 4: reachable code 不変 + ROM diff 領域確認 ✅

ROM 内の reachable code 領域 (= 既存 register write 経路) が α 追加で影響を受けていないことを静的論証で確認:

| 対象 routine | 開始 addr | step 10 α 前後 |
|---|---|---|
| `adpcma_keyon_simple` | 0x0FA7 | unchanged (= < 0x109F 新規領域より下) |
| `adpcma_keyoff` 等 既存 routine 群 | < 0x1070 | unchanged |
| `pmdneo_resolve_sample_table_id` (= step 9 β) | 0x1070 | unchanged |
| `pmdneo_select_sample_pointer` (= step 10 α 新規) | **0x109F** | 新規 22 byte 挿入 |
| `rhythm_main` 以降 | +22 byte shift | code 内容自体は不変、 addr のみ shift |

ROM 全体 size = 131072 byte (= 0x20000、 128 KB padded、 step 9 β 完了時と同一)。 routine 追加 22 byte は ROM padding 内に吸収。

#### 静的論証: chip register write pattern = step 9 完了時と byte-identical

- `pmdneo_select_sample_pointer` は **dead code** (= 条件 3 で確認、 call 0 件) で実行されない
- chip register write は `adpcma_keyon_simple` 等 reachable code でのみ発生
- reachable code 領域 (= < 0x109F) は addr / 内容 すべて unchanged (= 条件 4)
- VROM / `samples.inc` / build pipeline は完全不変

→ step5.PNE fixture 等で chip register write trace を取得した場合、 step 9 完了時 (= commit `3355885`) と byte-identical になる。 動的 trace 実行は β で call insertion 後に初めて意味を持つ (= match path register-identical 確認)。

## α scope の重要境界 (= future contributor 向け)

α 時点の `pmdneo_select_sample_pointer` routine は **dead code** であり、 driver 内のどこからも呼出されない。 runtime behavior は完全不変:

- ADR-0023 §決定 11 contract (= sample_table_id は playback decision に使用しない) は **α 時点では依然有効** (= β call insertion で初めて解除される、 ADR-0024 §決定 7)
- 0xFD32 (= `driver_pne_sample_table_id`) は依然「保存されるが consume されない」 状態
- `adpcma_keyon_simple` / `adpcma_ch_sample_ptr_table` / sample lookup / volume / pan / freq は完全不変
- match path / mismatch path どちらも routine が呼ばれない (= step 9 完了時と同一挙動)

α 完了条件で確認したのは:

- routine が ROM に正しく embed されていること (= build PASS + size + address)
- routine が driver 内から呼ばれていないこと (= call insertion 0 件)
- 既存 reachable code 領域 + chip register write pattern が step 9 完了時と byte-identical であること (= dead code なので影響なし)

つまり α 完了は「routine が存在する」 ことのみを保証し、 「routine が期待通り動く」 ことは β scope (= call insertion + match path 確認)。 future contributor が「α で selection 動作確認済」 と誤解しないよう明示。

## scope-out 維持確認

α では以下を一切実装しない:

- call insertion (= `adpcma_keyon_simple` への `call pmdneo_select_sample_pointer` + DE 0x0000 sentinel check) → β scope
- match path での既存 audio 再現確認 (= step5.PNE fixture で byte-identical) → β scope
- 中間 routine 通過 PC trace 確認 (= trivial verify 防止 primary gate) → β scope
- mismatch fixture audio verify (= 0xFD32 = 0xFF state で keyon 不発生) → γ scope
- silent flag / 別 runtime state → step 11+ scope (= ADR-0024 §決定 6)
- selected pointer runtime state 化 → step 11+ scope (= ADR-0024 §決定 6)
- `adpcma_keyon_simple` 全体 refactor → step 11+ scope (= ADR-0024 scope-out)
- `.PNE` binary parse → step 10 範囲外
- multi-`.PNE` switching → step 10 範囲外
- generated directory (= D3) → future scope
- K/R rhythm compat → step 11+ scope

## 既存 path 不変確認

- `assets/samples.inc`: 不変
- VROM: 不変
- `adpcma_ch_sample_ptr_table` / `adpcma_sample_bd` 〜 `adpcma_sample_top`: 不変
- `adpcma_keyon_simple` / `adpcma_keyoff` / `adpcma_volume_hook`: 不変
- L-Q part 6ch playback path: 不変
- step 8 `pmdneo_mn_direct_load_lq_part_addr`: 不変
- step 9 β `pmdneo_resolve_sample_table_id`: 不変 (= α でも β γ δ いずれでも改修しない)
- step 9 α `pne_sample_directory`: 不変
- `.equ` block (= step 9 α で追加した `driver_pne_sample_table_id` 含む): 不変
- `.PNE` converter / vromtool.py / build pipeline: 不変

## 次 step (= β scope)

- `adpcma_keyon_simple` (= L2741、 0x0FA7) の L2748-2755 (= 既存 voice * 2 → `adpcma_ch_sample_ptr_table` 引き → DE setup) を `call pmdneo_select_sample_pointer` + DE 0x0000 sentinel check (= `ld a, d / or e / ret z`) に置換
- voice >= 6 check (= L2747) は不変、 register write 群 (= L2757 以降) は不変
- match path での既存 audio 再現確認 (= step5.PNE fixture で chip register write trace が step 9 完了時と byte-identical)
- 中間 routine 通過 PC trace 確認 (= trivial verify 防止 primary gate、 MAME debugscript 等で `pmdneo_select_sample_pointer` entry 発火を観測)
- β primary gate = 静的論証ではなく **動的 trace 実行** で確認 (= α と異なり call が走るので runtime behavior が初めて検証可能)

## 関連

- [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) §決定 1 (= A2 採用) / §決定 4 (= ABI) / §決定 8 α (= sub-sprint 分割)
- [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 11 (= step 9 内で sample_table_id は playback decision に使用しない、 step 10 で解除)
- [ADR-0023 step 9 β handoff](adr-0023-step9-beta-resolver-routine.md) (= 同パターン dead code routine 単体実装の先例、 静的論証 + symbol 配置確認の流儀踏襲)
- ADR-0024 §決定 6: selected pointer runtime state は step 10 では持たない (= step 11+ scope)
- ADR-0024 §決定 7: ADR-0023 §決定 11 contract は step 10 で解除 (= β call insertion で 0xFD32 が playback selection に effective に)
