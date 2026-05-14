# ADR-0024 step 10 β handoff: `adpcma_keyon_simple` への `call pmdneo_select_sample_pointer` insertion + DE sentinel check (= match path 接続、 sample_table_id が initial に playback selection に effective)

- 日付: 2026-05-14 (= 11th session、 β 着手)
- 対応 ADR: [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) §決定 5 / §決定 8 β
- 関連 commit: 本 handoff doc を含む β 着手 commit

## β scope (= 1 commit + 1 push)

> **重要境界 (= future contributor 向け短文明記)**: Step 10 β で `sample_table_id` (= 0xFD32) が **initial に playback selection に effective** になる。 ADR-0023 §決定 11 contract (= sample_table_id は playback decision に使用しない) は本 commit で **解除** される (= ADR-0024 §決定 7)。 ただし match path は既存 chip register writes と byte-identical を維持、 mismatch silent の audio 検証は γ scope。

- `src/driver/standalone_test.s` の `adpcma_keyon_simple` (= L2741、 0x0FA7) で voice 引き 8 命令を `call pmdneo_select_sample_pointer` + DE sentinel check に置換
- 改修範囲: L2748-2755 (= 8 行 = 11 byte 命令列) → call + sentinel check 1 行 (= 4 行 = 6 byte 命令列)、 voice >= 6 check (= L2745-2747) と register write 群 (= L2757 以降) は完全不変
- `pmdneo_select_sample_pointer` (= α で追加) が初めて driver から呼出される (= dead code 状態解除)
- α 時点の routine 内部 logic は完全不変 (= α/β 切り分けによる trivial verify 防止)
- match fixture (= l-q-rhythm-song.mml + PMDDOTNET_MODE=B) で既存 audio 完全再現
- mismatch path の audio silent 検証は γ scope (= 本 commit では verify infra 拡張のみ最小限)

## 実装差分

### `adpcma_keyon_simple` 改修 (= `standalone_test.s` L2741-2773)

#### 改修前 (= step 9 δ baseline)

```asm
adpcma_keyon_simple:
        and     #0x07                   ; A = ch index (0-7 mask)
        ld      b, a                    ; B = ch index (= reg base 計算用、 preserve)
        ;; β-2b: voice index で sample table 引き
        ld      a, PART_OFF_INSTRUMENT(ix)
        cp      #6                      ; voice >= 6 は範囲外
        ret     nc                      ; → keyon skip (= 誤 sample 鳴動より安全)
        ld      l, a                    ; ← L2748 削除対象
        ld      h, #0
        add     hl, hl                  ; HL = voice * 2
        ld      de, #adpcma_ch_sample_ptr_table
        add     hl, de                  ; HL = sample ptr table entry (voice 引き)
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                 ; DE = sample addr pointer ← L2755 削除対象

        ld      a, #0x10                ; L2757 以降は完全不変
        ...
```

#### 改修後 (= step 10 β)

```asm
adpcma_keyon_simple:
        and     #0x07                   ; A = ch index (0-7 mask)
        ld      b, a                    ; B = ch index (= reg base 計算用、 preserve)
        ;; ADR-0016 step 5 β-2b 由来 + ADR-0024 step 10 β refactor:
        ;; voice index range check (= 4-A 採用、 routine 内では二重 check しない)
        ld      a, PART_OFF_INSTRUMENT(ix)
        cp      #6                      ; voice >= 6 は範囲外
        ret     nc                      ; → keyon skip (= 誤 sample 鳴動より安全)
        ;; --- ADR-0024 step 10 β: 中間 routine 経由で sample header pointer 取得 ---
        ;; A = voice index (= L2745-2747 で setup + range check 済)
        ;; B = ch index (= preserve、 pmdneo_select_sample_pointer は BC preserve)
        ;; 出力 DE = sample header pointer (= id == 0x00 + voice valid) or 0x0000 sentinel
        ;;        既存 inc de path (= L2757 以降) はそのまま接続可 (= 3-B DE 返却整合)
        ;; ADR-0024 §決定 3 (= 2-C): id != 0x00 → DE = 0x0000 → keyon skip (= mismatch silent)
        ;; ADR-0024 §決定 7: ADR-0023 §決定 11 contract 解除、 本 call で initial effective
        ;;        (= step 10 で sample_table_id が initial に playback selection に効く)
        call    pmdneo_select_sample_pointer
        ld      a, d
        or      e
        ret     z                       ; DE == 0x0000 → mismatch / unknown id keyon skip

        ld      a, #0x10                ; 既存 register write path、 L2757 以降は完全不変
        ...
```

#### 命令数差分

| 区分 | 改修前 byte | 改修後 byte | 差分 |
|---|---|---|---|
| L2748-2755 旧 voice 引き 8 行 | 11 byte | 6 byte | **-5 byte** |
| L2757 以降 register write 群 | 不変 | 不変 | 0 |

これにより `pmdneo_resolve_sample_table_id` 等 downstream routine addr は -5 byte shift:

| symbol | step 9 δ baseline addr | step 10 β addr |
|---|---|---|
| `adpcma_keyon_simple` | 0x0FA7 | 0x0FA7 (= unchanged) |
| 中の `call pmdneo_select_sample_pointer` | (不存在) | 0x0FB0 (= 旧 ld l,a 位置) |
| `pmdneo_resolve_sample_table_id` | 0x1070 | 0x106B |
| `resolve_mismatch` | 0x1099 | 0x1094 |
| `pmdneo_select_sample_pointer` (= α 追加) | 0x109F | 0x109A |

### `verify-step9-resolver.sh` の DIRECTORY_OFFSET dynamic 化 (= β 副作用 maintenance)

β の keyon path 短縮で directory addr が 5 byte shift (= step 9 0x104E → step 10 β 0x1049)。 verify-step9-resolver.sh の hardcoded `DIRECTORY_OFFSET=0x104E` が stale 化するため、 `.lst` から dynamic に読出す形に修正:

```bash
LST_PATH="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [[ ! -f "$LST_PATH" ]]; then
    echo "  [FAIL] infra: .lst not found ($LST_PATH)"
    exit 2
fi
DIRECTORY_OFFSET="0x$(awk '/pne_sample_directory:/ {print $1; exit}' "$LST_PATH")"
if [[ -z "$DIRECTORY_OFFSET" || "$DIRECTORY_OFFSET" == "0x" ]]; then
    echo "  [FAIL] infra: pne_sample_directory addr not found in .lst"
    exit 2
fi
```

これは β code change の副作用 maintenance であり、 driver 改修と同一 commit に含める (= β scope 内、 別 commit 分離は無意味な churn)。 future driver 改修で再び directory addr が shift しても dynamic に追従。

#### 設計判断

- **call insertion 位置**: 0x0FB0 (= 旧 ld l,a が在った位置)。 voice index は L2745 で A に load 済、 range check も L2747 で完了、 そのまま call に流せる
- **sentinel test 順序**: call 直後に `ld a, d / or e / ret z`。 既存 register write path に入る前に skip 判定、 silent 化 (= DE == 0x0000) で keyon を完全抑制
- **register convention**: BC preserve (= ch index B 維持)、 DE 出力 (= 3-B 採用)、 これにより既存 inc de path (= L2757 以降) と naturally つながる
- **静的同一性**: id=0x00 の場合、 routine 内部の table 引き logic (= L = voice index、 ld h,#0、 add hl,hl、 ld de,#adpcma_ch_sample_ptr_table、 add hl,de、 ld e,(hl)、 inc hl、 ld d,(hl)) は旧 keyon path の logic と byte-identical (= 同 instruction を別 routine に移植)、 ymfm-trace byte-identical の根拠
- **mismatch silent**: id != 0x00 の場合、 DE = 0x0000 を返し adpcma_keyon_simple で `ret z` skip、 chip 0x10/0x18/0x20/0x28/0x08/0x00 register write が一切発生しない (= γ で audio silent 検証)

## 動作確認 (= β 完了条件 5 件)

### 条件 1: build PASS ✅

`bash scripts/build-poc.sh` で「=== build 完了 ===」 表示。 sdasz80 / sdldz80 / sdobjcopy / vromtool.py すべて PASS。

### 条件 2: 旧 voice 引き path の compiled output からの完全消去 ✅

`build/standalone_test.lst` 0x0FB0-0xFBA 領域で旧 8 命令 (= `ld l,a / ld h,#0 / add hl,hl / ld de,#... / add hl,de / ld e,(hl) / inc hl / ld d,(hl)`) が完全消去、 代わりに新 4 命令 (= `call pmdneo_select_sample_pointer / ld a,d / or e / ret z`、 計 6 byte) のみ。 旧 path 残存ゼロ。

### 条件 3: PC trace primary gate (= routine entry literal 証跡) ✅

match fixture (= l-q-rhythm-song.mml + PMDDOTNET_MODE=B) で 4 秒録音 trace を取得。 z80-mem-trace.tsv で PC=0FB3 (= `call pmdneo_select_sample_pointer` の return-addr push 直後の PC) を count:

- **PC=0FB3 = 78 entries** (= return addr 2 byte push × 39 calls)
- 各 pair の addr/value = FFE9/0F + FFE8/B3 (= return addr 0x0FB3 stack push、 little-endian)

これは `call pmdneo_select_sample_pointer` at 0x0FB0 が **39 回実行** された literal 証跡。 trivial verify 防止 (= 旧 path をたまたま通って byte-identical になる false PASS) を排除。

### 条件 4: ymfm trace byte-identical (= match path、 chip register writes 完全一致) ✅

baseline (= step 9 δ post-commit、 stash 経由) と β で match fixture を同一条件で trace 取得 + 比較:

| 項目 | baseline | β |
|---|---|---|
| ymfm trace 行数 | 2616 | 2616 |
| diff (= write_idx 除外、 port/reg/value 比較) | - | **0 差分** |

`diff <(awk -F'\t' '{print $2"\t"$3"\t"$4}' baseline) <(awk -F'\t' '{print $2"\t"$3"\t"$4}' β)` exit code = 0、 完全一致。 chip register writes は match path で baseline と byte-identical。

#### 静的同一性の理由

match path (= 0xFD32 = 0x00) で:

- 旧 path: `ld l, a / ld h, #0 / add hl, hl / ld de, #adpcma_ch_sample_ptr_table / add hl, de / ld e, (hl) / inc hl / ld d, (hl)` → DE = table[voice]
- 新 path: `call pmdneo_select_sample_pointer` → routine 内で **同一 instruction sequence** を実行 → DE = table[voice]

routine 内部 logic は旧 keyon path の logic を 1:1 移植したものなので、 同 voice index 入力に対して同 DE pointer を返す。 後続の register write path は完全不変。 → ymfm output byte-identical は static に保証され、 動的 trace で実証。

### 条件 5: 0xFD32 = 0x00 (= match value) 維持 ✅

match fixture で z80-mem-trace の 0xFD32 writes:

- 全 6 件 idempotent
- 値: 0x00 (= match)
- PC: 108B (= step 10 β、 baseline PC=1090 から -5 shift、 ADR-0024 §決定 5 §命令数差分整合)

`pmdneo_resolve_sample_table_id` は β でも match path を hit、 0xFD32 = 0x00 を保存。 `pmdneo_select_sample_pointer` (= β 接続) は 0xFD32 を read → 0x00 → adpcma_ch_sample_ptr_table 引き → DE = valid pointer → keyon proceeds。

## β scope の重要境界 (= future contributor 向け)

**Step 10 β 完了時点で `sample_table_id` (= 0xFD32) が initial に playback selection に effective になる**。 ADR-0023 §決定 11 contract (= sample_table_id は playback decision に使用しない) は本 commit で **解除** された (= ADR-0024 §決定 7)。 具体的には:

- `adpcma_keyon_simple` は `pmdneo_select_sample_pointer` 経由で sample header pointer を取得
- 0xFD32 == 0x00 (= match) → 既存 `adpcma_ch_sample_ptr_table` から pointer 取得 → keyon proceeds (= 既存 audio 完全再現)
- 0xFD32 != 0x00 (= mismatch + 全 unknown) → DE = 0x0000 sentinel → adpcma_keyon_simple で `ret z` skip (= chip register writes 一切発生しない、 silent)

ただし β 時点では mismatch silent の **audio 検証は γ scope** に分離。 β commit では match path の byte-identical 保証のみ実証 (= 条件 4)。 mismatch fixture (= 0xFD32 = 0xFF state) での keyon register 0x00 write 不発生確認は γ で別途 verify infra を整備する。

`pmdneo_select_sample_pointer` (= α で dead code 追加) が **本 commit で initial に call される**。 routine 内部 logic は α と完全不変、 β 改修は call insertion (= 1 行 + sentinel test 3 行) のみ。 「作る (= α)」 と「繋ぐ (= β)」 を別 commit に分けた目的は trivial verify (= 既存 path で false PASS) の排除であり、 β 完了で initial に static + dynamic 両軸の verify が確立した。

## scope-out 維持確認

β では以下を一切実装しない:

- mismatch fixture audio verify (= 0xFD32 = 0xFF state で keyon register 不発生確認) → γ scope
- silent flag / 別 runtime state → step 11+ scope (= ADR-0024 §決定 6)
- selected pointer runtime state 化 (= A3) → step 11+ scope
- `adpcma_keyon_simple` 全体 refactor (= 4-B / 4-C) → step 11+ scope
- voice >= 6 check の routine 内部移管 (= 4-B 相当) → step 11+ scope
- `adpcma_ch_sample_ptr_table` rename / 新規 table 並置 (= 1-B / 1-C) → step 11+ scope
- `.PNE` binary runtime parse → step 10 範囲外
- multi-`.PNE` switching → step 10 範囲外
- generated directory (= D3) → future scope
- K/R rhythm compat → step 11+ scope

## 既存 path 不変確認

- `assets/samples.inc`: 不変
- VROM: 不変
- `adpcma_ch_sample_ptr_table` / `adpcma_sample_bd` 〜 `adpcma_sample_top`: 不変
- `adpcma_keyon_simple` の voice >= 6 check (= L2745-2747): 不変
- `adpcma_keyon_simple` の register write 群 (= L2757 以降、 0x10/0x18/0x20/0x28/0x08/0x00): 不変
- `adpcma_keyoff` / `adpcma_volume_hook`: 不変
- L-Q part 6ch playback path: 不変 (= match path で audio 完全再現)
- step 8 `pmdneo_mn_direct_load_lq_part_addr`: 不変
- step 9 β `pmdneo_resolve_sample_table_id`: 不変 (= addr のみ shift、 logic は完全不変)
- step 9 α `pne_sample_directory`: 不変
- step 10 α `pmdneo_select_sample_pointer`: 不変 (= routine 本体 logic は完全不変、 addr のみ shift)
- `.PNE` converter / vromtool.py / build pipeline: 不変

## verify infra 拡張 (= β scope 内)

`verify-step9-resolver.sh` の `DIRECTORY_OFFSET` を `.lst` から dynamic に読出す形に修正 (= β code change による addr shift への耐性化)。 既存 5 gate (= match + mismatch) は β build で全件 PASS:

| gate | 内容 | β 結果 |
|---|---|---|
| 1 | build + trace 取得 | PASS |
| 2 | 0xFD32 への write 6 件検出 | PASS |
| 3 | 0xFD32 = 0x00 (= match、 6 件 idempotent) | PASS |
| 4 | ROM patch ('s' → 'S' at 0x1049) | PASS |
| 5 | 0xFD32 = 0xFF (= mismatch、 6 件 idempotent) | PASS |

注: gate 5 は step 9 resolver の mismatch 動作確認 (= 0xFD32 = 0xFF を保存) で、 step 10 mismatch silent (= keyon register 不発生) の確認は γ scope。

## 次 step (= γ scope)

- mismatch fixture (= 0xFD32 = 0xFF state) で keyon → ADPCM-A keyon register (= 0x00) write 不発生確認
- 0x10-0x28 register write 不発生確認 (= sample 設定も skip される)
- audio silent 確認 (= user 試聴 + ymfm-trace で writes 不発生)
- γ verify infra: ROM patch approach 流用、 or 別 fixture 整備
- 既存 step 9 verify gate 5 (= 0xFD32 = 0xFF 確認) を流用しつつ、 ADPCM-A register write 不発生を追加 gate に

## 関連

- [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) §決定 1 (= A2 採用) / §決定 4 (= ABI DE 返却) / §決定 5 (= 4-A 採用 keyon 最小変更) / §決定 7 (= ADR-0023 §決定 11 解除) / §決定 8 β
- [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 11 (= step 9 内で sample_table_id は playback decision に使用しない、 本 commit で解除)
- [ADR-0024 step 10 α handoff](adr-0024-step10-alpha-routine-implementation.md) (= dead code routine 単体実装、 本 commit で initial call insertion)
- [ADR-0023 step 9 γ handoff](adr-0023-step9-gamma-chain-insertion.md) (= 同パターン chain insertion の先例、 PC trace + memory inspection primary gate の流儀踏襲)
- `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 防止規律、 α/β 分割 + PC trace primary で対応)
- `feedback_refactor_gate_register_trace_not_wav.md` (= refactor 系 gate は ymfm-trace byte-identical、 本 commit で実証)
