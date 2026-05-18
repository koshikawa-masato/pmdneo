# PR Draft: IR design + JSON Schema v0.1 + MML → IR minimal exporter spike

## 1. Overview

この branch (`wip-intermediate-register-command`) は、 PMDNEO の **Intermediate Register Command Data (IR)** を compiler / WebApp 内部の正規化形式として設計し、 JSON Schema v0.1 を ratify、 MML → IR の minimal exporter spike まで成立させたものです。

IR は Z80 driver が直接読む runtime format ではなく、 build / authoring / WebApp / diagnostics のための中間表現として位置づけます。 runtime は引き続き `.mn` + `.PNE` を使用し、 driver / fixture / verify script (= legacy step5-18 系) / runtime semantics は完全不変です。

24th session の 13 commit (= ADR / design doc / schema / examples / validator / spike + 本 PR_DRAFT) で構成され、 全 commit が doc / helper / spike-only。 compiler 本体 / WebApp / driver / `.NEO` / `.mn` / `.PNE` 生成 path は touch しません。

## 2. Branch / Scope

- **branch**: `wip-intermediate-register-command`
- **base**: `wip-pmddotnet-opnb-extension` (= commit `b9d0f2f`)
- **latest commit**: 本 PR_DRAFT commit
- **runtime / driver**: 完全不変 (= 全 commit doc / helper / spike-only)
- **並走 branch**: `wip-pmddotnet-opnb-extension` (= ADR-0033 BD synth chain、 pending / non-blocking research track として retain)

## 3. Decisions (= ADR-0034 §決定 1-6 ratify)

| 軸 | 決定 | 詳細 |
|---|---|---|
| 1 | IR は compiler / WebApp intermediate format | Z80 driver runtime ではない、 runtime は `.mn` + `.PNE` 維持 (= §決定 1) |
| 2 | IR canonical serialization は JSON | binary IR chunk は scope-out、 future ADR (= §決定 2) |
| 3 | 3 層 hybrid 構造 | SemanticEvent / ChipEvent / RawRegisterWrite、 LFO / portamento は別軸温存 (= §決定 3) |
| 4 | FM3 拡張音色 = FM3Mode ChipEvent + FMTone 共用 | FM3 は「tone 分岐」 ではなく「chip mode + operator frequency control」 (= §決定 4) |
| 5 | sample_refs は lightweight reference | IR は asset container ではない、 license / provenance は `.PNE` / `.NEO` 側 (= §決定 5) |
| 6 | `.NEO` は candidate container, not runtime replacement | WebApp / builder / archive 用、 chunk 候補は記録のみ (= §決定 6) |

詳細は `docs/adr/0034-pmdneo-intermediate-register-command-ir-design.md` + `docs/design/intermediate_register_command.md` §17-1 から §17-6。

## 4. What's Included

### 成果物

- **ADR-0034**: `docs/adr/0034-pmdneo-intermediate-register-command-ir-design.md` (= Draft、 233 行、 §決定 1-6 + 設計責務まとめ + scope-out 14 件 + Annex A/B)
- **IR design notes**: `docs/design/intermediate_register_command.md` v0.2 (= 16 section + §17 user ratification log 6 件 entry)
- **IR reference**: `docs/design/reference_intermediate_register_command.md` (= X 検索 + 海外ツール調査の参考資料)
- **JSON Schema v0.1**: `docs/design/intermediate-register-command/ir-schema-v0.1.schema.json` (= draft-2020-12 dialect、 6 fully validated event types = Note / Rest / Tempo / ToneSelect / ADPCMATrigger / RawRegisterWrite)
- **positive examples (= 3 件)**: `examples/{minimal-fm-note,adpcma-trigger,raw-register-write}.ir.json`
- **negative examples (= 6 件)**: `examples/invalid/{bad-magic,unknown-event-type,invalid-channel-kind,raw-register-out-of-range,missing-required-field,zero-duration-rest}.ir.json`
- **validator script**: `scripts/validate-ir-schema.py` (= positive + negative dual-mode、 4 exit code: 0 / 64 / 65 / 66)
- **MML → IR spike**: `scripts/mml-to-ir-spike.py` + `spike-fixtures/tiny-melody.mml` (= tiny PMD-flavored subset、 6 event 生成)
- **README**: `docs/design/intermediate-register-command/README.md` (= 構成 / 検証 command / spike section / scope)
- **PR_DRAFT** (= 本 file): `docs/design/intermediate-register-command/PR_DRAFT.md`

### commit chain (= 13 commit、 全 doc / helper / spike-only)

| # | commit | 内容 |
|---|---|---|
| 1 | `86d7eb2` | IR design notes 2 件 add (= Codex draft v0.2) |
| 2 | `d036697` | §17-1 軸 1 ratify (= compiler / WebApp intermediate) |
| 3 | `a6405b8` | §17-2 軸 2 ratify (= JSON canonical) |
| 4 | `e1c915c` | §17-3 軸 3 ratify (= 3 層 hybrid) |
| 5 | `976c530` | §17-4 軸 4 ratify (= FM3Mode + FMTone 共用) |
| 6 | `b1e7e2e` | §17-5 軸 5 ratify (= sample reference lightweight handle) |
| 7 | `e846baf` | §17-6 軸 6 ratify (= `.NEO` candidate container) |
| 8 | `3d60039` | ADR-0034 起票 Draft |
| 9 | `88d3cd9` | IR schema v0.1 + 3 positive examples |
| 10 | `0cbe4a0` | IR schema validation helper |
| 11 | `61ef89a` | negative fixtures 5 件 + validator dual-mode |
| 12 | `2864ac4` | MML → IR minimal exporter spike |
| 13 | `5d24c46` | PR_DRAFT.md 追加 |
| 14 | (本 commit) | PR #3 review fix (= validator 0-match exit_arg / Note + Rest duration minimum 1 + zero-duration-rest fixture / spike docstring tick 規約) |

## 5. Scope Out

本 PR には以下を **含めない** (= 24th session user 指示遵守):

- compiler 本体実装
- WebApp 実装
- runtime / driver source 改修
- `.NEO` container 実装
- `.mn` / `.PNE` 生成 path 改修
- binary IR encoder
- full PMD parser (= spike は tiny subset のみ)
- automated CI 化
- YAML serialization
- ADPCM-A / ADPCM-B sample pack 実装
- importer (= MewMML / PMD / mdx / MUCOM88 / FMP7 → IR)
- LFO / portamento / pitch envelope の標準 SemanticEvent 昇格

これらは ADR-0034 §scope-out 14 件 + 各 §17-N ratify の scope-out 明記と整合。

## 6. Verification

repo root で実行:

### 6-1. schema positive validation (= 3 examples)

```bash
python3 scripts/validate-ir-schema.py
```

期待: `Valid examples: 3/3 passed` + exit 0

### 6-2. schema positive + negative validation (= 3 + 5 examples)

```bash
python3 scripts/validate-ir-schema.py \
  --invalid-examples 'docs/design/intermediate-register-command/examples/invalid/*.ir.json'
```

期待: `Valid examples: 3/3 passed` + `Invalid fixtures: 6/6 correctly rejected` + exit 0

### 6-3. MML → IR spike + validation

```bash
python3 scripts/mml-to-ir-spike.py \
  docs/design/intermediate-register-command/spike-fixtures/tiny-melody.mml \
  --output /tmp/tiny-melody.ir.json

python3 scripts/validate-ir-schema.py --examples /tmp/tiny-melody.ir.json
```

期待: spike が `[OK] wrote 6 events to /tmp/tiny-melody.ir.json` + validator が `Valid examples: 1/1 passed` + exit 0

### 検証 summary (= 期待 result)

| test | expected |
|---|---|
| positive 3/3 | PASS |
| invalid 6/6 | correctly rejected |
| spike output 1/1 | PASS |

## 7. Key Files

| path | 役割 |
|---|---|
| `docs/adr/0034-pmdneo-intermediate-register-command-ir-design.md` | ADR Draft、 §決定 1-6 + 設計責務 + scope-out + Annex A/B |
| `docs/design/intermediate_register_command.md` | IR design notes v0.2 + §17 ratification log |
| `docs/design/reference_intermediate_register_command.md` | 詳細参考資料 (= X 検索 + 海外ツール調査) |
| `docs/design/intermediate-register-command/ir-schema-v0.1.schema.json` | JSON Schema draft-2020-12 |
| `docs/design/intermediate-register-command/README.md` | 構成 + 検証 command + spike section |
| `docs/design/intermediate-register-command/examples/*.ir.json` | positive examples 3 件 |
| `docs/design/intermediate-register-command/examples/invalid/*.ir.json` | negative fixtures 5 件 |
| `docs/design/intermediate-register-command/spike-fixtures/tiny-melody.mml` | spike fixture |
| `scripts/validate-ir-schema.py` | schema validator (= positive + negative dual-mode) |
| `scripts/mml-to-ir-spike.py` | MML → IR minimal exporter spike |

## 8. Next Work

本 PR merge 後の implementation candidate (= 別 branch / 別 sprint):

- **IR → ChipEvent lowering spike** (= semantic event → chip event の段階的 lowering proof、 scope は本 PR より一段深い)
- **PMD importer spike** (= PMD MML → IR、 #Zenlen → PPQN 変換 + tone import + 多 part 対応、 memory `project_ir_ppqn_vs_pmd_zenlen_distinction` 適用必須)
- **WebApp integration** (= IR を WebApp 編集 / preview / build pipeline と接続、 Phase 3-4)
- **`.NEO` container decision** (= §15-2 別軸温存中、 WebApp / builder 実装段階で正式採用範囲を確定)
- **schema v0.2** (= KeyOn / KeyOff / FMToneLoad / FMFrequency / FM3Mode / ADPCMBDma / Volume / Pan / LoopStart / LoopEnd 追加、 IR010+ validation 拡張、 if/then/else discriminator で oneOf error の inner branch 詳細表示化)

## 関連 ADR / docs

| ADR / doc | 関連 |
|---|---|
| ADR-0019 | Step 5 ADPCM-A 6ch native path (= IR の `adpcm_a:1-6` / Part L-Q mapping 前提) |
| ADR-0021 | Step 7 `.PNE` asset pipeline + `.mn` filename embed (= sample_refs / packFile / runtime path 維持) |
| ADR-0023 | Step 9 `.PNE` filename → sample_table_id resolver |
| ADR-0024 | Step 10 sample_table_id selection consumption |
| ADR-0025 | Step 11 multi-table proof |
| ADR-0026-0031 | Step 12-17 K/R drum kind expansion full 6 drum completion (= `rhythm_kr` no-op + adpcm_a 1-6 path 確立) |
| ADR-0032 | Step 18 simultaneous trigger semantics proof (= ChipEvent: ADPCMATrigger semantics 前提) |
| ADR-0033 | rhythm sample provenance (= IR layer に持ち込まない、 別 branch `wip-pmddotnet-opnb-extension` で pending retain) |
| ADR-0034 | **本 PR の中心 ADR** = IR design consolidation Draft |

## 検証履歴 (= 24th session で実施した検証 evidence)

- schema meta-validation: PASS (= draft-2020-12 として正当、 Python `jsonschema` 4.26.0 で確認)
- positive examples 3 件: 全 PASS (= adpcma-trigger / minimal-fm-note / raw-register-write)
- negative fixtures 5 件: 全 correctly rejected
- spike → schema 連携: PASS (= tiny-melody.mml → 6 events → schema 適合)
- driver / fixture / verify script (= legacy step5-18) / runtime semantics: 完全不変

CLAUDE.md §動作確認義務 = driver / runtime 層を touch する commit が無いため emulator 起動 / 動作確認は不要。 doc / helper / spike-only PR 構成。
