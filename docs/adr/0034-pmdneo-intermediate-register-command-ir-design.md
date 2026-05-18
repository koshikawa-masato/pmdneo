# ADR-0034: Intermediate Register Command Data (IR) — design consolidation (= 軸 1-6 ratify 統合 / IR は compiler / WebApp intermediate / JSON canonical / 3 層 hybrid / FM3Mode ChipEvent + FMTone 共用 / sample reference のみ lightweight handle / `.NEO` は candidate container, not runtime replacement)

- 状態: **Draft** (= 2026-05-17 24th session 起票、 6 軸 ratify を `docs/design/intermediate_register_command.md` §17 で literal 記録済、 本 ADR は §17 を ADR layer に昇格 + Accepted 移行は IR implementation 着手前の別 session 最終確認時、 driver / fixture / verify script / runtime semantics 完全不変 doc-only ADR)
- 起票日: 2026-05-17
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR: ADR-0019 (= step 5 ADPCM-A 6ch native path、 IR の `adpcm_a:1-6` / Part L-Q mapping の前提)、 ADR-0021 (= step 7 `.PNE` asset pipeline + `.mn` filename embed、 IR の sample_refs / packFile / runtime path 維持の前提)、 ADR-0023 (= step 9 `.PNE` filename → sample_table_id resolver、 IR の sampleRef → `.PNE` slot 解決の前提)、 ADR-0024 (= step 10 sample_table_id selection consumption)、 ADR-0025 (= step 11 multi-table proof)、 ADR-0026-ADR-0031 (= step 12-17 K/R drum kind expansion full 6 drum completion、 IR の `rhythm_kr` no-op + `adpcm_a:1-6` path 確立の前提)、 ADR-0032 (= step 18 simultaneous trigger semantics proof、 IR の ChipEvent: ADPCMATrigger semantics の前提)、 ADR-0033 (= rhythm sample provenance、 IR の sample provenance を IR layer に持ち込まない判断の根拠、 別 branch `wip-pmddotnet-opnb-extension` で pending retain 中)
- 関連設計書: `docs/design/intermediate_register_command.md` (= IR design draft v0.2、 6 軸 ratify を §17 で literal 記録)、 `docs/design/reference_intermediate_register_command.md` (= 詳細参考資料、 X 検索 + 海外ツール調査)、 `docs/design/PMDNEO_DESIGN.md` (= Phase 1-4 計画、 IR は WebApp / build pipeline 段階で導入想定)

## 背景

PMDNEO は Phase 3-4 で MML エディタ + WAV → ADPCM コンバータ + 音色エディタ + ビルド + プレビューを WebApp として実装する計画 (= CLAUDE.md「WebApp フロントエンド」 section、 PMDNEO_DESIGN.md §6)。 また Phase 2 で MewMML / PMD / mdx 等の MML 方言からの import を視野に入れている。

これらを実現するには、 MML 方言入力を OPNB 向けの共通表現に正規化し、 `.mn` (= Z80 driver 楽曲 binary) と `.PNE` (= ADPCM-A sample pack) を生成する前段の中間表現が必要になる。 reference doc §1 で示されるように、 既存の中間データ事例 (= PMD 形式自体 / MewMML save state / Furnace Tracker / mml2vgm) はいずれも FM register に近い形式または abstract event + register write の hybrid を採用しており、 同じ pattern を PMDNEO の compiler intermediate に適用するのが妥当な選択肢として浮上した。

23rd session までで Codex により design draft v0.2 が起票され (= `docs/design/intermediate_register_command.md` + `docs/design/reference_intermediate_register_command.md`、 commit 86d7eb2)、 16 section + reference 7 section にわたって構造定義が行われた。 ただし Codex 判断は提案であり、 採否は越川氏 (= 著作権者) が握る (= CLAUDE.md「記憶は AI に、 判断は自分が握る」 中核原則)。

24th session 冒頭で越川氏は 6 軸の壁打ちを指示:

1. これは runtime format か、 compiler intermediate format か
2. binary first か text first か
3. register command と abstract event の境界
4. FM3 拡張音色をどこで表現するか
5. ADPCM / rhythm sample / external asset reference の扱い
6. `.NEO` container versioning と互換性

24th session で 6 軸を順次壁打ち、 全 6 軸を Codex 判断 ratify (= 各軸とも option 1 採用) で確定し、 `docs/design/intermediate_register_command.md` §17 ADR 起票候補事項 (user ratification log) に 6 件の entry (= §17-1 から §17-6) として literal 記録した (= commit chain d036697 / a6405b8 / e1c915c / 976c530 / b1e7e2e / e846baf)。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 6 軸 ratify を ADR layer に昇格して独立記録する。 本 ADR は §17 user ratification log を ADR layer で正式に位置づけ、 将来の IR implementation (= 別 sprint) で本 ADR が ground truth として参照される構造を確立する。

なお、 ADR-0033 (= rhythm sample provenance and self-authored migration policy、 BD synth chain 軸) は別 branch `wip-pmddotnet-opnb-extension` で pending / non-blocking research track として retain されており、 本 ADR の sample provenance 議論 (= 決定 5「license / provenance は IR ではなく `.PNE` / `.NEO` 側で扱う」) と独立軸として並走する。 ADR-0033 は別 branch で別 session に再開予定。

## 決定

### 決定 1: IR は compiler / WebApp intermediate format (= 軸 1 ratify)

IR は Z80 driver が直接読む runtime format ではなく、 compiler / WebApp / build pipeline / diagnostics 用の正規化形式として確定する。

- IR は Z80 driver が直接読む runtime format ではない
- runtime は引き続き `.mn` + `.PNE`
- IR は build / authoring / WebApp / diagnostics のための正規化形式
- IR から `.mn` / `.PNE` / diagnostics を生成する
- `.NEO` は archive / WebApp / builder 用 container 候補であり runtime replacement ではない

理由: Z80 driver semantics を巻き込まない / 現行 `.mn` + `.PNE` chain を壊さない / MML 方言差 + WebApp 編集 + 診断 + 将来の変換を IR 側で吸収できる / runtime format にすると scope が大きくなりすぎる。

詳細は `docs/design/intermediate_register_command.md` §17-1 + §0 結論 + §1-2 非責務 + §1-3 生成物との関係 + §16 Codex 判断 採用 1 件目。

### 決定 2: IR canonical serialization は JSON (= 軸 2 ratify)

IR canonical format は JSON。 binary IR chunk は現時点で scope-out。

- IR canonical format は JSON
- schema は JSON Schema で定義する
- YAML は authoring 補助で canonical ではない
- binary chunk は現時点では canonical にしない (= scope-out for now)
- `.NEO` に入れる場合は、 まず JSON UTF-8 payload として IRCM chunk に入れる案を future とする
- binary encoding が必要になった時点で別 ADR / decision として扱う

理由: 決定 1 で runtime efficiency 制約が外れた / Z80 driver は JSON を読まない (= runtime compactness は `.mn` + `.PNE` 側で確保) / WebApp では JSON が最も扱いやすい (= JS native parse) / git diff + review + regression test に向く / diagnostics + schema validation 容易 / binary も同時規格化すると dual maintenance になる。

詳細は `docs/design/intermediate_register_command.md` §17-2 + §15 未決定事項 1 件目 + §15 現時点の推奨。

### 決定 3: 3 層 hybrid (SemanticEvent / ChipEvent / RawRegisterWrite) (= 軸 3 ratify)

IR は 3 層 hybrid 構造を採用する。 標準 event 最小集合は §2-2 のまま。 LFO / portamento は本軸では標準昇格させず別軸として残す。

- SemanticEvent: MML の音楽的意味を保持する層 (= Note / Rest / ToneSelect / Volume / Pan / Tempo / Loop など)
- ChipEvent: OPNB 操作に近い正規化層 (= KeyOn / KeyOff / FMToneLoad / FMFrequency / FM3Mode / ADPCMATrigger / ADPCMBDma など)
- RawRegisterWrite: 低レベル escape hatch (= port / address / data / barrier)
- 同一 tick で複数層 event 共存可、 共通 field `order` で順序保証
- lowering は SemanticEvent → ChipEvent → RawRegisterWrite の段階構造
- importer は SemanticEvent 生成を基本、 必要に応じて ChipEvent / RawRegisterWrite を併用可
- 標準 event 最小集合は §2-2 のまま確定
- LFO / portamento / pitch envelope は標準 SemanticEvent に昇格しない、 importer 実装段階で別 decision として扱う

理由: SemanticEvent を残すことで WebApp 編集 + diagnostics + diff がしやすい / ChipEvent により OPNB への lowering が明確 / RawRegisterWrite により方言差 + 未標準機能を失わず保持 / 2 層化すると importer 側に負担が寄る / register-only は音楽的意味を失いすぎる / LFO 標準化は時期尚早。

詳細は `docs/design/intermediate_register_command.md` §17-3 + §0 結論 + §2-1 + §2-2 + §6 + §7 + §8 + §14。

### 決定 4: FM3Mode ChipEvent + FMTone 共用 (= 軸 4 ratify)

FM3 拡張音色は FM3Mode ChipEvent + FMTone 共用で表現する。 FM3 は「tone structure の分岐」 ではなく「chip mode + operator frequency control」 として扱う。

- tone 構造は通常の `FMTone` を共用 (= FM3 専用 tone 構造は新設しない)
- FM3 mode の有効化 / 無効化は `ChipEvent: FM3Mode` として表現
- operator 別 pitch / block / fnum は `FM3Mode` 側で保持
- lowering 時に `FM3Mode` から register `0x27` + `0xA8-0xAE` 系へ展開
- RawRegisterWrite だけにはしない、 SemanticEvent にも置かない
- IR005 validation 維持 + 拡張候補 (= operator 別 fnum / block 欠落検出、 FM3Mode 有効 tick の ordering rule) を IR010 以降で具体化想定

**wording 規律**: docs / ADR / コード注釈で FM3 を「tone structure の分岐」 と表現しない、 「chip mode + operator frequency control」 と統一する。

理由: FM3 拡張は OPNB register 操作に近いので ChipEvent が自然 / FMTone 共用で tone import + WebApp UI が単純 / FM3 専用 tone は dual maintenance / RawRegisterWrite だけは validation 弱化 / SemanticEvent 配置は音楽的意味と chip mode 操作が混ざる。

詳細は `docs/design/intermediate_register_command.md` §17-4 + §7-4 + §9-2 + §13 + §16 Codex 判断 採用 4 件目 + reference doc §3 FM3 拡張モード詳細 (= `0x27` bit 6-7 + `0xA8-0xAE`)。

### 決定 5: sample reference のみ、 lightweight handle (= 軸 5 ratify)

IR は sample 実体を持たず、 sample reference のみ。

- IR は sample 実体を持たない
- sample_refs 構造は §10 の設計を維持 (= `sampleRef` / `kind` / `packFile` / `slot` / `name` / `sourceUri`)
- ADPCM-A trigger は `ChipEvent: ADPCMATrigger`
- ADPCM-B DMA / streaming 系は `ChipEvent: ADPCMBDma`
- K/R は現時点では no-op stub / IR004 warning 扱いを維持
- IR008 / IR009 validation 維持

**wording 規律**: IR sample_refs は「参照解決のための lightweight handle」 であり asset provenance の source-of-truth ではない。 docs / ADR / コード注釈で master record として表現しない。

scope-out / future decision:

- ADPCM-B `.PNE` 統合 vs 別 format は §15-5 のまま別 decision (= ADPCM-B 実装段階判断)
- K/R rhythm → ADPCM-A 6ch lowering 置換は別 decision (= Step 12-17 path 流用候補)
- license / provenance 詳細構造化は IR ではなく `.PNE` / `.NEO` 側で扱う
- ADR-0033 sample provenance 詳細を IR に直接持ち込まない

理由: IR は compiler / WebApp intermediate であり asset container ではない / sample 実体 + provenance を IR に持たせると責務が膨らむ / `.PNE` / `.NEO` 側が asset 実体 + provenance 扱いに自然 / ADPCM-B + K/R lowering は実装段階で別判断が安全。

詳細は `docs/design/intermediate_register_command.md` §17-5 + §3-2 + §4-1 + §7-5 + §7-6 + §10 + §13 + §14。

### 決定 6: `.NEO` は candidate container, not runtime replacement (= 軸 6 ratify)

`.NEO` は WebApp / builder / archive 用 container 候補として概念 fix。 正式採用 + spec 詳細は WebApp / builder 実装段階の別 decision として温存。

- `.NEO` は runtime format ではない
- Z80 driver は `.NEO` を読まない
- runtime は引き続き `.mn` + `.PNE`
- `.NEO` は WebApp / builder / archive / diagnostics 用 container 候補
- chunk 候補は記録するが、 正式採用はまだしない
- chunk 候補: `META` / `IRCM` / `MN  ` / `PNE ` / `DIAG`
- IRCM は決定 2 に従い JSON UTF-8 payload 想定 (= binary IR chunk は future decision)

**wording 規律**: docs / ADR / コード注釈で `.NEO` を "candidate container, not runtime replacement" として表現する。 runtime format / driver readable container として表現しない。

scope-out / future decision:

- `.NEO` を正式配布 format にするか
- magic / version field / chunk extension policy
- forward compatibility policy
- license / provenance metadata の配置 (= `.NEO` META chunk vs `.PNE` directory entry の選択)
- WebApp 内部 package vs 外部 archive format

理由: `.NEO` の正式採用は WebApp / builder 実装段階で判断する方が安全 / 先に container を固めすぎると IR + `.mn` + `.PNE` の設計変更に弱くなる / runtime path に入れないことで driver semantics を守れる / 将来に備え chunk 候補と役割だけは記録しておく価値あり。

詳細は `docs/design/intermediate_register_command.md` §17-6 + §11 + §15 未決定事項 2 件目 + §16 Codex 判断 要検討 1 件目 + reference doc §4。

## 設計責務まとめ (= ADR ratify 後の前提)

決定 1-6 を統合した IR / `.mn` / `.PNE` / `.NEO` の責務:

| 観点 | IR | `.mn` | `.PNE` | `.NEO` |
|---|---|---|---|---|
| 位置づけ | compiler / WebApp intermediate (= 決定 1) | runtime 楽曲 binary | runtime ADPCM-A sample pack | candidate container (= 決定 6) |
| Z80 driver 読込 | しない (= 決定 1) | する | する | しない (= 決定 6) |
| serialization | JSON canonical (= 決定 2) | binary | binary | chunk container 案 (未確定) |
| sample 実体 | 持たない (= 決定 5) | 持たない | 持つ | 含む可 (= PNE chunk 経由) |
| sample provenance | sourceUri のみ (= 決定 5) | なし | directory entry 候補 (= ADR-0021 系) | META chunk 候補 (= 決定 6) |
| 3 層 event | 含む (= 決定 3) | 該当なし | 該当なし | IRCM chunk 内 (= JSON UTF-8 payload) |
| FM3 拡張 | FM3Mode ChipEvent (= 決定 4) | register write 列 | 該当なし | IRCM chunk 内 |
| 既存 PMDNEO ADR 関連 | 本 ADR (= ADR-0034) | ADR-0019 / 0021 / 0022 / 0023 系 | ADR-0019 / 0021 / 0033 系 | 本 ADR + 将来 ADR |

## scope-out / future decision 集約

本 ADR scope-out (= future decision 対象):

- LFO / portamento / pitch envelope の標準 SemanticEvent 昇格条件 (= 決定 3、 §15 未決定 4 件目、 importer 実装段階)
- binary IR chunk 採用 (= 決定 2、 §15 未決定 1 件目)
- ADPCM-B `.PNE` 統合 vs 別 format (= 決定 5、 §15 未決定 5 件目、 ADPCM-B 実装段階)
- K/R rhythm → ADPCM-A 6ch lowering 置換 (= 決定 5、 Step 12-17 path 流用候補)
- license / provenance 詳細構造化 (= 決定 5 + 決定 6、 `.PNE` / `.NEO` 側で扱う)
- `.NEO` 正式採用範囲 (= 決定 6、 §15 未決定 2 件目)
- `.NEO` magic / version / chunk extension / forward-compat policy (= 決定 6)
- WebApp 内部 package vs 外部 archive format (= 決定 6)
- IR validation rules IR010 以降の具体化 (= 決定 4 拡張 validation 候補)
- mdx / OPM tone 変換品質基準 (= §16 要検討 3 件目)
- loop nest 許可 (= §15 未決定 3 件目)
- IR → register trace の出力仕様詳細 (= §14-3)
- importer 実装 (= MewMML / PMD / mdx / MUCOM88 / FMP7、 §12)
- ADR-0033 sample provenance and self-authored migration policy (= 別 branch retain、 IR layer に直接持ち込まない)

本 ADR scope-in (= ratify 確定):

- IR の位置づけ (= 決定 1)
- IR canonical serialization (= 決定 2)
- IR 3 層 hybrid 構造 (= 決定 3)
- FM3 拡張音色の表現方針 (= 決定 4)
- sample reference の最小構造 (= 決定 5)
- `.NEO` の位置づけ (= 決定 6)
- wording 規律 (= 決定 4 / 決定 5 / 決定 6 で「FM3 = chip mode + operator frequency control」 / 「sample_refs = lightweight handle」 / 「`.NEO` = candidate container, not runtime replacement」 の 3 件統一)

## 完了判定

本 ADR は doc-only ADR であり、 driver / fixture / verify script / runtime semantics の変更を含まない。 完了判定は以下:

1. `docs/design/intermediate_register_command.md` §17-1 から §17-6 まで 6 軸 ratify entry が literal 存在 (= 完了)
2. 本 ADR が 6 軸 ratify を ADR layer に literal 統合 (= 完了)
3. 設計責務まとめ表が IR / `.mn` / `.PNE` / `.NEO` の 8 観点で literal 整理 (= 完了)
4. scope-out / future decision 集約が 14 項目以上 literal 列挙 (= 完了)

Accepted 移行条件:

- 越川氏 (= 著作権者) が本 ADR Draft を leave-as-is で受容
- IR implementation 着手前 (= 別 sprint) の最終確認として本 ADR が ground truth として参照される

実装着手は本 ADR Accepted 後の別 sprint。 本 ADR 起票時点では実装に進まない (= 24th session 末 user 直接指示「まだ実装には進まないでください」 遵守)。

## Annex A: 6 軸 ratify log (= §17 reference)

詳細は `docs/design/intermediate_register_command.md` §17 を参照。 本 ADR は §17 entries を ADR layer で要約 + 設計責務まとめ + scope-out 集約として提示する。

各 entry の literal 要約:

- §17-1 軸 1 ratified 2026-05-17: IR の位置づけ = compiler / WebApp intermediate
- §17-2 軸 2 ratified 2026-05-17: IR serialization = JSON canonical、 binary scope-out
- §17-3 軸 3 ratified 2026-05-17: 3 層 hybrid (SemanticEvent / ChipEvent / RawRegisterWrite)、 LFO / portamento 別軸
- §17-4 軸 4 ratified 2026-05-17: FM3Mode ChipEvent + FMTone 共用、 FM3 は tone 分岐ではなく chip mode + operator frequency control
- §17-5 軸 5 ratified 2026-05-17: sample reference のみ、 IR は asset container ではない、 lightweight handle 規律
- §17-6 軸 6 ratified 2026-05-17: `.NEO` は candidate container, not runtime replacement、 §15-2 別軸温存

## Annex B: 関連 commit chain (= 24th session の IR design + 6 軸 ratify chain、 全 commit doc-only)

| commit | 内容 |
|---|---|
| `86d7eb2` | docs: add intermediate register command design notes (= Codex 起票 IR design draft v0.2 + reference doc) |
| `d036697` | docs: §17-1 軸 1 ratify (= compiler / WebApp intermediate) |
| `a6405b8` | docs: §17-2 軸 2 ratify (= JSON canonical、 binary scope-out) |
| `e1c915c` | docs: §17-3 軸 3 ratify (= 3 層 hybrid、 LFO / portamento 別軸温存) |
| `976c530` | docs: §17-4 軸 4 ratify (= FM3Mode ChipEvent + FMTone 共用) |
| `b1e7e2e` | docs: §17-5 軸 5 ratify (= sample reference のみ lightweight handle) |
| `e846baf` | docs: §17-6 軸 6 ratify (= `.NEO` candidate container, not runtime replacement) |
| 本 ADR commit | docs(adr): ADR-0034 起票 Draft (= IR design consolidation、 6 軸 ratify ADR layer 昇格) |

driver / fixture / verify script / runtime semantics 完全不変 (= 24th session 全 commit chain doc-only)。
