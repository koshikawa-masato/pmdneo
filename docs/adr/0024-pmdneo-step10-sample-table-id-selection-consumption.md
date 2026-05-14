# ADR-0024: PMDNEO step 10 sample_table_id selection consumption (= identity → playback selection、 中間 routine 経由 pointer 返却、 id=0x00 only-accept + sentinel silent、 keyon path 最小変更)

- 状態: **Draft** (= 2026-05-14 11th session 起票、 δ 完了統合で Accepted 移行予定)
- 起票日: 2026-05-14
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 (= 改造実装 sprint 作業計画、 step 10 = runtime resolver consumption 段階)、 ADR-0019 (= step 5 §決定 3 で `.PNE` parser を「次 sprint へ分離」 と接続点予約、 §決定 4 sample addr 引き build-time embed 維持)、 ADR-0021 (= step 7 `.PNE` asset pipeline + `.MN` filename embed)、 ADR-0022 (= step 8 runtime filename observation 成立)、 ADR-0023 (= step 9 filename → sample_table_id resolver、 §決定 11「playback decision に使用しない」 contract は本 ADR §決定 7 で解除)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)、 `docs/design/pne_binary_layout.md` (= `.PNE` format 仕様)

## 背景

step 9 (= ADR-0023) 完了 (= 2026-05-13 10th session、 commit `3355885`) で runtime `.PNE` filename → `sample_table_id` resolver が成立した。 driver は SRAM 0xFD20-0xFD2F の filename string と hand-written directory を比較し、 一致した entry の `sample_table_id` (= 1 byte index) を 0xFD32 に保存する。 ADR-0023 §決定 11 で「step 9 内で `sample_table_id` は playback decision に使用しない」 と literal 固定され、 sample lookup / keyon / volume / pan / freq の dispatch 経路は完全不変に保たれた。

ADR-0023 Accepted 後の重要境界に明記された通り、 step 9 時点では:

- `driver_pne_sample_table_id` (= 0xFD32) は **保存されるが consume されない** runtime state
- sample table addr は依然 build-time `samples.inc` 経由で固定埋込 (= ADR-0019 §決定 3 / ADR-0022 §決定 8 / ADR-0023 §決定 10 維持)
- `adpcma_keyon_simple` / `adpcma_ch_sample_ptr_table` は不変、 既存 voice index 引きで再生
- mismatch (= 0xFD32 == 0xFF) でも playback 動作は変えない (= ADR-0023 §決定 8 整合)

step 10 はこの境界の **「保存される」 から「playback selection に効かせる」 段階への 1 段延伸** を担う。 0xFD32 を初めて playback path が consume する sprint であり、 ADR-0023 §決定 11 の literal contract が解除される sprint である。

ただし「runtime resolver consumption sprint」 と素朴に定義すると scope が肥大化する (= sample addr 引き + selected pointer state + keyon refactor + mismatch silent flag + multi-table + bank switching を同時に触る)。 11th session 冒頭の壁打ち (= 4 論点) で以下の方針整理が確定:

- **sample_table_id は中間 routine 経由で sample header pointer に変換するに留める** (= 論点 1 / A2 採用)
- **selected pointer runtime state は持たない** (= state cache なし、 都度解決)
- **keyon path は最小変更で routine call 経由に差替えるのみ** (= 論点 4 / 4-A 採用)
- **id=0x00 only-accept、 それ以外は 0x0000 sentinel で silent** (= 論点 2 / 2-C 採用)
- **silent flag / runtime state 追加 / multi-table / bank switching は scope-out**
- **「動いているものを壊さない」 規律 (= step 5/6/7/8/9 で確立) を継続遵守**

これに基づき step 10 を **「sample_table_id selection consumption sprint」** として定義する。 中間 routine の追加と keyon path への call insertion により、 0xFD32 が playback selection に effective になる最小成立形である。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 step 10 着手前に方針を ADR として独立起票する。

### 11th session 冒頭壁打ちでの 4 論点方針確定

ADR-0024 起票前に user 主導で 4 論点の壁打ちが行われ、 step 10 の出口像が以下に固定された。

**論点 0: sample_table_id 消費責務 = A2 中間 routine 経由 pointer 返却**

`sample_table_id` を playback path が consume する経路の責務分担:

- A1 (= adpcma_keyon_simple 直接引き): keyon path に resolver logic が入りすぎる、 ch 軸拡張時に重複コード化 risk
- A2 (= **採用**): 中間 routine が sample addr pointer を返す。 keyon は呼出 + pointer 受領で責務分離、 解決 logic 集約、 将来 A3 へ移行する場合も中間 routine 内部で state cache 化すればよい
- A3 (= selected pointer runtime state 化): 解決 1 回で済むが、 invalidation 規律 + mismatch pointer 設計 + 二重管理 consistency 担保が増える

A2 採用根拠: 責務分離が最も clean、 keyon path は「voice index → sample addr を得る」 だけに近い形を維持、 Step 11+ で state cache 化する余地を残す。

**論点 1: id=0x00 canonical table = 1-A 既存 adpcma_ch_sample_ptr_table 再利用**

id=0x00 を「最初の selected table」 とみなした時の table base:

- 1-A (= **採用**): 既存 `adpcma_ch_sample_ptr_table` をそのまま id=0x00 selected table として再利用 (= identity 採用)
- 1-B (= 新規 table 並置): id=0x00 用に別 table を作成、 既存と並置
- 1-C (= rename): 既存 table を `pne_sample_pointer_table_default` 等に改名

1-A 採用根拠: Step 5/8 で確立した build-time mapping を維持、 sample data / `samples.inc` / VROM / register write 完全不変、 step 10 差分を「中間 routine 経由で pointer を得る」 1 点に絞れる、 future multi-table 化は別 table 追加で naturally extends。 ただし trivial verify 防止のため「中間 routine を本当に通ったか」 を trace / memory / PC gate で primary 確認する必要。

**論点 2: accept rule = 2-C id=0x00 only-accept、 unknown は silent**

mismatch (= id=0xFF) + unknown id に対する振舞い:

- 2-A (= mismatch only skip): id=0xFF だけ silent、 他 unknown id は未定義
- 2-B (= fallback): id 値を実質無視して常に既存 table を返却 (= Step 9 以前挙動温存)
- 2-C (= **採用**): id=0x00 only-accept、 それ以外 (= 0xFF + 全 unknown) は silent 単一 rule

2-C 採用根拠: 「accept する id を明示列挙、 それ以外は silent」 という fail-fast contract、 Step 11 で他 id を入れた際に必ず routine 改修が要るので未定義動作を防げる、 mismatch を audio で literal 確認可能。 Step 9 以前の挙動から audio が変わるが、 これは identity resolution を playback selection に反映する **意図的仕様変更** であり regression ではない (= 本 ADR §決定 7)。

silent 実現手段: **sentinel pointer 0x0000** (= 中間 routine の return convention 内で完結)。 flag-based silent は別 sprint へ分離 (= runtime state 増を Step 10 では避ける)。

**論点 3: 中間 routine 返り値 = 3-B DE 返却**

中間 routine の sample addr pointer 返却 register:

- 3-A (= HL 返却): Z80 慣習、 ただし caller で `ex de,hl` 等の翻訳が要る
- 3-B (= **採用**): DE 返却
- 3-C (= HL/DE 両 setup): over-engineering、 不採用

3-B 採用根拠: 既存 `adpcma_keyon_simple` (= L2741) は sample addr pointer を **DE で保持** し `inc de` で進める register convention、 routine return を DE にすれば call 後そのまま既存 inc de path に接続可能、 `ex de,hl` 等の register 翻訳 instruction が増えない。 Step 11 で複数 caller が出た段階で HL 統一 refactor を別 sprint で起票するのが clean。

**論点 4: adpcma_keyon_simple 変更範囲 = 4-A 最小変更**

keyon path への手入れ範囲:

- 4-A (= **採用**): 既存 table 引き部分 (= L2748-2755) を routine call + sentinel check に置換、 voice >= 6 check (= L2747) と register write 群 (= L2757 以降) は不変
- 4-B (= accept check 集約): voice >= 6 check も routine 側に移管
- 4-C (= 大規模 refactor): keyon path 全体を複数 routine 化、 ADR-0019 予告分も同時実施

4-A 採用根拠: Step 10 の核は「中間 routine 経由 selection」 1 点、 keyon path の他責務 (= voice >= 6 check / register write 群) は不変が望ましい、 trace primary gate の接続点を 1 つに絞ると「resolver call を本当に通った」 を PC / memory trace で確認しやすい、 regression risk 最小。 4-B の利点 (= id 拡張時 routine 1 箇所改修) は実質的に 4-A でも得られる。 4-C は user 規律「parser / resolver / playback を同時に触りすぎない」 と明確に conflict。

## 決定

### 決定 1: step 10 を「sample_table_id selection consumption sprint」 として定義 (= A2 採用)

step 10 の最終 deliverable boundary を **A2 (= 中間 routine 経由 pointer 返却)** とする。 driver は `driver_pne_sample_table_id` (= 0xFD32) と voice index を入力に sample header pointer を返す中間 routine `pmdneo_select_sample_pointer` を新規追加し、 `adpcma_keyon_simple` から call insertion することで 0xFD32 が playback selection に effective になることを目的とする。

#### 補足: step 10 = identity resolution を playback selection に反映する最初の sprint、 ただし selected pointer state cache は持たない

step 10 は **0xFD32 を playback path が初めて consume する sprint** であり、 ADR-0023 §決定 11 の literal contract が解除される。 ただし selected pointer の runtime state cache (= A3 相当) は持たず、 都度解決 (= 中間 routine 内で directory addr 引き) を行う。 これにより runtime state は 0xFD32 (= 1 byte) のみで完結し、 invalidation 規律 / mismatch pointer 設計 / 二重管理 consistency 担保の負荷を Step 11+ に分離する。

future contributor が「step 10 完了で selected pointer が state 化されている」 と誤解しないよう本決定で literal に固定。

### 決定 2: id=0x00 canonical table = 既存 adpcma_ch_sample_ptr_table を再利用 (= 1-A 採用)

id=0x00 を「最初の selected table」 とみなした時の table base は **既存 `adpcma_ch_sample_ptr_table`** をそのまま再利用する。 sample data / `samples.inc` / VROM / register write / build-time mapping は完全不変。 中間 routine は id=0x00 を判定したら既存 table addr を返却するのみ。

#### 採用根拠

- Step 5/8 で確立した build-time mapping を維持、 step 10 差分を「中間 routine 経由」 1 点に絞れる
- regression risk 最小、 既存 step5.PNE audio fixture が match path で byte-identical 再現する想定
- future multi-table 化は別 table 追加で naturally extends、 既存 table は id=0x00 default として残る
- table rename / 新規 table 並置は Step 10 段階では over-engineering、 別 micro-sprint へ分離

#### trivial verify 防止規律

候補 1-A は「中間 routine 経由」 と「直接 table 読み」 が物理的に同じ data を参照するため、 resolver を本当に通っているか確認しないと trivial verify (= 既存 path で false PASS) risk が出る。 step 10 では以下を primary gate に組込む:

- 中間 routine 通過の **PC trace** 確認 (= MAME debugscript / breakpoint で routine entry を観測)
- 中間 routine 内部 read の **memory trace** 確認 (= 0xFD32 read instruction を trace に乗せる)
- step 9 で確立した memory inspection primary gate を流用

### 決定 3: accept rule = id=0x00 only-accept、 unknown id は silent (= 2-C 採用)

中間 routine `pmdneo_select_sample_pointer` の accept rule:

- `driver_pne_sample_table_id` (= 0xFD32) == 0x00 → `adpcma_ch_sample_ptr_table` base を返却
- それ以外 (= 0xFF + 全 unknown id) → **0x0000 sentinel** を返却

caller (= `adpcma_keyon_simple`) は受領 pointer が 0x0000 ならば keyon を skip する。 silent flag / 別 runtime state は追加しない。

#### 採用根拠

- 「accept する id を明示列挙、 それ以外は silent」 という fail-fast contract、 Step 11 で他 id を入れる際に必ず routine 改修が要るので未定義動作を防げる
- mismatch を audio で literal 確認可能 (= match path audible / mismatch path silent の 2 fixture で primary gate 構成)
- runtime state は 0xFD32 のまま、 silent 実現を sentinel pointer 0x0000 で表現することで Step 10 段階の state 増を回避
- flag-based silent は別 sprint (= 候補 D) へ分離、 将来の拡張余地として ADR-0024 内に保留明記

#### Step 9 以前との挙動差 (= 意図的仕様変更)

- Step 9 までは mismatch (= 0xFD32 == 0xFF) でも playback path は既存 build-time table から鳴る (= ADR-0023 §決定 8 / §決定 11 整合)
- Step 10 から mismatch / unknown id は keyon skip で silent
- これは regression ではなく、 **identity resolution を playback selection に反映する意図的仕様変更**

本決定により ADR-0023 §決定 11 (= Step 9 内で sample_table_id は playback decision に使用しない) の literal contract は Step 10 で **解除** される (= 本 ADR §決定 7)。

### 決定 4: 中間 routine ABI (= 入力 voice index + 0xFD32 read / 出力 DE = pointer or 0x0000 sentinel)

新規 routine `pmdneo_select_sample_pointer` の ABI を以下に固定:

| field | 内容 |
|---|---|
| 入力 A | voice index (= 0..5 想定、 6 以上の range check は呼出側で実施) |
| 入力 (memory) | `driver_pne_sample_table_id` (= 0xFD32、 1 byte read) |
| 出力 DE | sample header pointer (= id=0x00 + voice valid 時、 `adpcma_ch_sample_ptr_table[voice]` 経由 entry addr) または 0x0000 (= silent sentinel) |
| clobber | A, HL (= 必要最小限、 BC は preserve) |
| preserve | BC, IX, IY |

#### routine 擬似コード

```
pmdneo_select_sample_pointer:
    ; 入力: A = voice index
    ; 出力: DE = sample header pointer or 0x0000
    ld      hl, #driver_pne_sample_table_id
    cp      a, (hl)                         ; 注: 実際は ld a,(0xFD32) → cp #0x00 等で展開
    ; id == 0x00 判定:
    push    af                              ; voice index 退避
    ld      a, (driver_pne_sample_table_id)
    or      a                               ; A == 0 → match
    jr      nz, select_unknown_id
    ;; id == 0x00 path: voice index で adpcma_ch_sample_ptr_table 引き
    pop     af                              ; voice index 復帰
    ;; (voice valid range check は呼出側責務、 routine 内では実施しない)
    ld      l, a
    ld      h, #0
    add     hl, hl                          ; HL = voice * 2
    ld      de, #adpcma_ch_sample_ptr_table
    add     hl, de                          ; HL = sample ptr table entry
    ld      e, (hl)
    inc     hl
    ld      d, (hl)                         ; DE = sample header pointer
    ret

select_unknown_id:
    ;; id != 0x00: 0x0000 sentinel 返却
    pop     af                              ; voice index 復帰 (= discard)
    ld      de, #0x0000
    ret
```

#### ABI 設計根拠

- DE 返却: 既存 `adpcma_keyon_simple` (= L2741) が sample addr pointer を DE で保持し `inc de` で進める register convention に整合、 call 後そのまま既存 inc de path に接続可能
- BC preserve: caller `adpcma_keyon_simple` が B = ch index を preserve するため、 routine 内で B を clobber しない設計 (= 既存 keyon path との接続最小化)
- voice range check 不実施: 既存 `adpcma_keyon_simple` L2747 で voice >= 6 ret skip が確立済、 routine 内に二重 check を持たせない (= 4-A 採用の責務分担に整合)
- HL clobber 許容: routine 内で table 引き計算に必須、 caller 側で必要な HL は call 前に push/pop or memory save

### 決定 5: adpcma_keyon_simple は最小変更 (= 4-A 採用)

`adpcma_keyon_simple` の改修範囲:

- **変更**: L2748-2755 (= voice * 2 → `adpcma_ch_sample_ptr_table` 引き → DE setup の部分) を `call pmdneo_select_sample_pointer` + DE 0x0000 sentinel check + `ret z` に置換
- **不変**: L2745 voice index load、 L2747 voice >= 6 check、 L2757 以降の register write 群、 vol/pan/keyon path

#### 改修後の擬似コード

```
adpcma_keyon_simple:
        and     #0x07                   ; A = ch index (0-7 mask)
        ld      b, a                    ; B = ch index (preserve)
        ld      a, PART_OFF_INSTRUMENT(ix)
        cp      #6                      ; voice >= 6 は範囲外
        ret     nc                      ; → keyon skip
        ;; --- step 10 差分: 中間 routine 経由で DE = sample header pointer 取得 ---
        call    pmdneo_select_sample_pointer
        ;; DE == 0x0000 sentinel test
        ld      a, d
        or      e
        ret     z                       ; → mismatch / unknown id keyon skip
        ;; --- 以下既存 register write path (= L2757+) ---
        ld      a, #0x10
        add     a, b
        ...
```

差分: 中間 routine call (= 3 byte) + DE 0x0000 test (= 3 byte) + ret z (= 1 byte) = **計 7 byte の挿入**、 既存 table 引き code (= 8 byte 程度) を置換。

#### 採用根拠

- step 10 差分を「routine call + sentinel check」 の 2 点に絞り、 trace primary gate との接続点を最小化
- 既存 register write 群 (= L2757-2818) 完全不変で、 match path での byte-identical 再現が直接確認可能
- voice >= 6 check は keyon 側責務として残し、 routine 内に二重 check を持たせない (= SoC 整合)
- regression risk 最小、 既存 step5.PNE audio fixture が match path で byte-identical 再現する想定

### 決定 6: selected pointer runtime state は持たない

step 10 では以下を **すべて不採用**、 Step 11+ scope に保留:

- `driver_pne_selected_sample_table_ptr` (= 0xFD33-0xFD34 等の 2 byte pointer state)
- pointer cache routine (= 解決 1 回だけ、 keyon は state 読むだけ)
- pointer invalidation 規律 (= いつ更新するか / mismatch 時 pointer 値 / `.MN` reload 時 invalidate)
- silent flag (= 別 runtime state で silent 化指示)

#### 採用根拠

- step 10 は「identity → selection」 段階であり、 「dynamic asset management」 ではない (= 11th session 冒頭壁打ち user 整理)
- runtime state を 0xFD32 (= 1 byte) のままに保つことで Step 9 の memory layout 不変、 Step 11+ で必要に応じて 0xFD33+ に extends
- 中間 routine 内部での都度解決は性能的に許容 (= keyon は 1 楽曲あたり数十 Hz 程度、 directory 1 entry compare は数十 cycle)
- 将来 A3 (= state cache) に移行する場合も、 中間 routine の internal cache 化で抽象境界を維持できる

### 決定 7: ADR-0023 §決定 11 contract は step 10 で解除

ADR-0023 §決定 11「Step 9 内で `sample_table_id` は playback decision に使用しない」 の literal contract は **step 10 で解除** される。 step 10 完了後の挙動:

- `driver_pne_sample_table_id` (= 0xFD32) は中間 routine `pmdneo_select_sample_pointer` から **read** される
- 0xFD32 == 0x00 → 既存 `adpcma_ch_sample_ptr_table` 経由 sample header pointer 返却
- 0xFD32 != 0x00 → 0x0000 sentinel 返却 → `adpcma_keyon_simple` で keyon skip (= silent)
- Step 9 以前の挙動 (= mismatch でも build-time table で再生) からの **意図的仕様変更**

#### Step 9 → Step 10 挙動差 (= regression ではない)

ADR-0023 §決定 8「mismatch でも playback 動作は変えない」 と本 ADR §決定 3「mismatch silent」 は表面的に矛盾するが、 これは sprint boundary を跨いだ **段階的仕様進化** であり regression ではない:

- ADR-0023 §決定 8: step 9 完了時点での挙動 (= identity resolution のみ実装、 playback selection 未接続)
- ADR-0024 §決定 3: step 10 完了時点での挙動 (= identity が playback selection に effective)

future contributor 向けに、 mismatch silent 化は ADR-0024 で明示的に導入されたことを literal に固定。 ADR-0023 §決定 11 の解除も同様、 本 ADR §決定 7 で明文化する。

### 決定 8: sub-sprint 分割 = α/β/γ/δ 4 段

step 10 を **α / β / γ / δ の 4 sub-sprint 構造** で進める。 「作る」 と「接続する」 を分けることで trivial verify (= ADR-0016 step 3c-2 / V-1 / W-1 / W-3 で検出された false PASS、 ADR-0023 でも sub α/β で分離) を防ぐ。

| sub | 範囲 | primary gate |
|---|---|---|
| α | ADR-0024 起票 (= Draft 章 1-5 全章記述、 Annex は δ で追記) + `pmdneo_select_sample_pointer` routine 単体実装 (= dead code 状態、 keyon 未接続) | build PASS + step5.PNE register write trace byte-identical (= dead code 確認) + ROM binary diff が新規 routine 領域内のみ + routine symbol 存在確認 |
| β | `adpcma_keyon_simple` への call insertion + DE 0x0000 sentinel check (= match path 接続、 既存 audio 再現確認) | build PASS + step5.PNE register write trace byte-identical (= match path で挙動不変) + 中間 routine 通過 PC trace 確認 (= trivial verify 防止 primary gate) |
| γ | mismatch fixture audio verify (= driver 不変、 verify infra 中心) | 0xFD32 = 0xFF state で keyon → ADPCM-A keyon register (= 0x00) write 不発生、 0x10-0x28 register write 不発生、 audio silent 確認 |
| δ | regression verify (= step 5/6/7/8/9 既存 26 gate 全 PASS) + audible 確認 (= silent-bcef fixture user 試聴) + ADR-0024 Accepted 移行 + handoff doc + memory 更新 | mismatch primary gate PASS + match path byte-identical + 全 sub primary gate PASS + 既存 verify regression PASS + audible OK |

#### α 時点での重要境界 (= future contributor 向け短文明記)

**Step 10 α 時点では `sample_table_id` (= 0xFD32) は playback path にまだ影響しない**。 `pmdneo_select_sample_pointer` routine は ROM に存在するが driver 内のどこからも呼出されない (= dead code)、 id=0x00 / 0xFF の違いはまだ音に現れない。 β の `adpcma_keyon_simple` への call insertion により selection semantics が initial に playback path に反映される (= ADR-0023 §決定 11 contract 解除は β で初めて effective、 本 ADR §決定 7 整合)。

α 完了時点で:

- ADR-0023 §決定 11 (= sample_table_id は playback decision に使用しない) は **依然有効**
- 0xFD32 は依然「保存されるが consume されない」 runtime state
- match path / mismatch path どちらも routine が呼ばれず、 既存 chip register write pattern は step 9 完了時 (= commit `3355885`) と byte-identical

**1 sub = 1 commit + 1 push 規律** (= `feedback_push_per_commit` / `feedback_post_commit_push_report_format`) を維持。 各 commit で user 都度レビュー待ち。

#### 分割根拠

- α は「routine を作る」 だけで call 未挿入 → trivial verify (= 既存 path で false PASS) を detect しやすい dead code 段階
- β で初めて call が挿入され primary gate が「実 selection 動作」 を捕捉、 match path での byte-identical を確認
- γ で mismatch silent path を初めて verify (= driver 不変で verify infra 拡張のみ、 ROM patch approach も検討)
- δ で既存 verify infra と統合し regression を保証、 audible 試聴で user 都度レビュー完了

## scope-in / scope-out 明示

### scope-in (= step 10 本 sprint 範囲)

- `pmdneo_select_sample_pointer` routine 新規追加 (= α)
- routine ABI 確定: 入力 voice index + 0xFD32 read、 出力 DE = pointer or 0x0000 sentinel、 clobber A/HL、 preserve BC/IX/IY (= α)
- `adpcma_keyon_simple` への call insertion + DE 0x0000 sentinel check + ret z (= β)
- match path での既存 audio 再現確認 (= step5.PNE fixture で byte-identical) (= β)
- 中間 routine 通過 PC trace 確認 (= trivial verify 防止) (= β)
- mismatch fixture audio verify (= 0xFD32 = 0xFF 状態で keyon register write 不発生 + silent 確認) (= γ)
- step 5/6/7/8/9 既存 verify script 全件 regression 再確認 (= δ)
- MAME 試聴で audible regression なし最終確認 (= δ、 silent-bcef fixture 流用)
- step 10 完了統合 handoff doc + ADR-0024 Accepted 移行 (= δ)

### scope-out (= step 10 範囲外、 後続 sprint で扱う)

- selected pointer の runtime state 化 (= A3 相当、 `driver_pne_selected_sample_table_ptr` 等)
- pointer cache routine (= 解決 1 回 + state 読みだけ keyon)
- pointer invalidation 規律 (= いつ更新 / mismatch pointer 値 / `.MN` reload 時 invalidate)
- silent flag (= 別 runtime state で silent 化指示、 flag-based silent)
- `adpcma_keyon_simple` 全体 refactor (= 4-B / 4-C 相当、 ADR-0019 予告の voice load / sample pointer / register write 分離)
- `adpcma_ch_sample_ptr_table` rename (= 1-C 相当、 別 micro-sprint)
- 新規 table 並置 (= 1-B 相当、 multi-table 段階で扱う)
- `.PNE` binary 自体の runtime parse (= header / sample entry / addr table 読込)
- multi-`.PNE` switching (= 楽曲ごと別 `.PNE` 切替)
- ROM bank switching / 動的 sample bank 管理
- 楽曲交換時 ROM rebuild 不要化
- dynamic reload (= 動的 `.PNE` 差替)
- generated directory (= future D3、 別 script / vromtool.py 拡張)
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)
- PMDNEO.s + nullsound integration (= 大規模 sprint)
- 新規 sample 追加 (= WAV → ADPCM-A 変換 UI、 WebApp Phase 4 領域)
- mc compiler / vromtool.py / converter / `samples.inc` 改修
- PPZ compatibility mode
- FM-Towns-style rhythm mode

## 完了判定

### step 10 全体完了判定 (= ADR-0024 Accepted 移行条件)

1. **α**: ADR-0024 draft file 起票 (= 章 1-5 全章記述、 Annex は δ で追記) + commit + push
2. **α**: `pmdneo_select_sample_pointer` routine 単体実装 (= dead code 状態、 keyon 未接続) + commit + push
3. **α**: build PASS + step5.PNE register write trace byte-identical (= dead code 確認) + ROM binary diff が新規 routine 領域内のみ + routine symbol 存在確認
4. **β**: `adpcma_keyon_simple` に `call pmdneo_select_sample_pointer` + DE 0x0000 sentinel check + ret z を insert + commit + push
5. **β**: match path で step5.PNE fixture register write trace byte-identical 確認 (= 既存 audio 再現)
6. **β**: 中間 routine 通過 PC trace 確認 (= trivial verify 防止 primary gate)
7. **γ**: mismatch fixture (= 0xFD32 = 0xFF state) audio verify + commit + push
8. **γ**: keyon register (= 0x00) write 不発生 + register 0x10-0x28 write 不発生 + audio silent 確認
9. **δ**: step 5/6/7/8/9 既存 26 verify script regression 全件 PASS (= 既存 architecture regression なし)
10. **δ**: MAME 試聴で audible regression なし (= silent-bcef fixture で確認)
11. **δ**: step 10 完了統合 handoff doc + ADR-0024 Accepted 移行 + commit + push
12. **δ**: ADR-0023 §決定 11 contract 解除の literal 明記 + memory `project_pmdneo_step10_complete.md` 起票

### sub-sprint 完了判定 (= 個別)

各 sub-sprint の完了判定は handoff doc に記述。 全 sub-sprint で「1 sub = 1 commit + 1 push + user 都度レビュー待ち」 規律を遵守。

## verify gate 構成

### α gate (= dead code 段階、 4 段)

1. **build PASS**: sdcc / sdasz80 / lkz80 通過、 ROM .neo 生成
2. **step5.PNE register write trace byte-identical**: reachable code path 不変 (= routine が dead code として未使用、 既存 path register write 完全一致)
3. **ROM binary diff が新規 routine 領域内のみ**: 既存 reachable code 領域 byte-identical、 diff は `pmdneo_select_sample_pointer` 領域 (= routine size 想定 30-40 byte 程度) のみ
4. **routine symbol 存在確認**: `.lst` / `.map` / symbol dump で `pmdneo_select_sample_pointer` entry point が確認可能

### β gate (= call insertion + match path、 3 段)

1. **build PASS**: 同上
2. **step5.PNE register write trace byte-identical**: match path で既存 audio 再現 (= 0xFD32 = 0x00 で既存 table から pointer 取得、 既存 register write 完全一致)
3. **中間 routine 通過 PC trace 確認** (= trivial verify 防止 primary gate): MAME debugscript / breakpoint で `pmdneo_select_sample_pointer` entry が keyon ごとに発火していることを確認

### γ gate (= mismatch silent path、 3 段)

1. **0xFD32 = 0xFF state 再現**: ROM patch approach (= step 9 δ 流儀) or fixture filename 改変で mismatch 状態を作る
2. **ADPCM-A keyon register (= 0x00) write 不発生**: trace 観察で register 0x00 (= keyon/keyoff control) への bit set write が発生していない
3. **audio silent 確認**: ymfm trace で register 0x10-0x28 write が match path より少ない / 全く起きない、 user 試聴で audible regression なし

### δ gate (= regression + audible、 包括)

- step 5 verify script 全件 PASS (= l-q-tutti-gamma / l-part-alpha-trace-gate / l-part-beta-sample-lookup / l-part-delta-volume-pan / l-q-rhythm-song-integration)
- step 6 verify script 全件 PASS (= silent-bcef-audio-isolation)
- step 7 verify script 全件 PASS (= b1-roundtrip / b3-byte-identical / delta-mn-filename-embed / delta-fix-quote-strip)
- step 8 verify script 全件 PASS (= filename-observation)
- step 9 verify script 全件 PASS (= resolver、 5 gate match + mismatch)
- 新規 step 10 verify script 整備 (= `verify-step10-selection.sh` 等、 α/β/γ gate を script 化)
- audible regression なし最終確認 (= silent-bcef fixture で user 試聴 OK)

## 関連 memory

- `project_pmdneo_step9_complete.md` (= step 9 完了状態、 0xFD32 identity resolver 成立)
- `project_pmdneo_step8_complete.md` (= step 8 完了状態、 runtime filename observation 成立)
- `project_pmdneo_step7_complete.md` (= step 7 完了状態、 `.PNE` asset pipeline 成立)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 Step 10 は「runtime selection」 軸の最初の 1 段)
- `project_pmdneo_step6_complete.md` (= step 6 完了状態、 audio isolation 戦略、 silent-bcef fixture 流用)
- `project_pmdneo_step5_complete.md` (= step 5 完了状態、 ADPCM-A 6ch native path、 既存 keyon path 改修対象)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 step 10 は match path で再採用)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 検出 + 補正 commit 規律、 1-A 採用で特に重要)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除、 silent-bcef fixture 流用)
- `feedback_verify_script_serial_execution.md` (= verify script 群は serial 実行、 δ で適用)
- `project_pne_directory_entry_runtime_fixture_vs_asset_canonical.md` (= asset canonical vs runtime fixture 責務差、 step 9 γ finding 由来、 step 10 でも同 fixture 系列を流用)

## 完了判定達成状況 (= δ で追記)

(= δ 完了統合時に commit hash + verify result + Accepted 移行根拠を Annex として追記)

## 関連 doc

- ADR-0016 §決定 6 (= 全 step 完了後の検証 infra 強化)
- ADR-0019 §決定 3 (= `.PNE` parser 次 sprint 接続点予約)、 §決定 4 (= sample addr は build 時 embed)
- ADR-0021 §Accepted 後の重要境界 (= runtime resolution は Step 8 以降)
- ADR-0022 §Accepted 後の重要境界 (= driver は filename を読めるが解決していない)
- ADR-0023 §決定 11 (= Step 9 内で sample_table_id は playback decision に使用しない、 本 ADR §決定 7 で解除)
- ADR-0023 §Accepted 後の重要境界 (= 0xFD32 は保存されるが consume されない、 本 ADR §決定 1 で consume 開始)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- `docs/design/mn_binary_layout.md` §4-3-3 / §7-2 (= `pne_filename_adr` + filename string embed 仕様)
- `docs/design/pne_binary_layout.md` (= `.PNE` format 仕様、 step 7 α-1 起票)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止 / §「記憶は AI に、 判断は自分が握る」

## 次 sprint 候補

1. **α 着手 (= 本 commit)** (= ADR-0024 起票 + `pmdneo_select_sample_pointer` routine 単体実装、 keyon 未接続 dead code 状態)
2. β 着手 (= `adpcma_keyon_simple` への call insertion + DE 0x0000 sentinel check + match path 確認)
3. γ 着手 (= mismatch fixture audio verify + silent path 確認)
4. δ 着手 (= regression + audible 確認 + 完了統合 + Accepted 移行)
5. **step 11 候補** (= 本 ADR scope-out のうち未消化): selected pointer runtime state 化 (= A3、 cache + invalidation) / silent flag 拡張 (= 別 runtime state) / `adpcma_keyon_simple` 全体 refactor (= 4-B / 4-C) / multi-table 並置 (= 1-B) / `adpcma_ch_sample_ptr_table` rename (= 1-C) / `.PNE` binary runtime parse / multi-`.PNE` switching / generated directory (= D3) migration / K/R rhythm compat micro-sprint
