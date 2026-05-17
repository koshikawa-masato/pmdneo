# Intermediate Register Command Data (IR) — schema + examples

PMDNEO の compiler / WebApp intermediate format。 ADR-0034 (= 24th session ratified、 2026-05-17) で 6 軸決定済。 設計の母体は `../intermediate_register_command.md` (= design notes) + `../reference_intermediate_register_command.md` (= 詳細参考資料)。

## 構成

- `ir-schema-v0.1.schema.json`: JSON Schema draft-2020-12 本体 (= ADR-0034 §決定 1-6 を spec 化)
- `examples/`: schema 適合 example file 群 (= positive fixture)
  - `minimal-fm-note.ir.json`: FM ch 2 で Tempo + ToneSelect + Note + Rest 4 event
  - `adpcma-trigger.ir.json`: ADPCM-A ch 1 で ADPCMATrigger 1 event
  - `raw-register-write.ir.json`: reg 0x27 FM3 mode RawRegisterWrite 1 event
- `examples/invalid/`: schema validation が **失敗する** ことを期待する fixture 群 (= negative fixture)
  - `bad-magic.ir.json`: `metadata.magic` const violation (= "PMDNEO-IR" 以外)
  - `unknown-event-type.ir.json`: events oneOf 不適合 (= semantic / Portamento は v0.1 未定義 type)
  - `invalid-channel-kind.ir.json`: `channelId.kind` enum violation (= "opm" 等は対象外)
  - `raw-register-out-of-range.ir.json`: `RawRegisterWrite.address` / `data` maximum violation (= 256 以上)
  - `missing-required-field.ir.json`: Note event の `duration` 欠落 (= required violation)

## v0.1 で fully validated な event types (= 6 件)

| layer | type | 出典 (= ADR-0034) |
|---|---|---|
| semantic | `Note` | §決定 3 |
| semantic | `Rest` | §決定 3 |
| semantic | `Tempo` | §決定 3 |
| semantic | `ToneSelect` | §決定 3 |
| chip | `ADPCMATrigger` | §決定 5 |
| raw | `RawRegisterWrite` | §決定 3 |

v0.2 以降の event types (= 拡張予定): `KeyOn` / `KeyOff` / `FMToneLoad` / `FMFrequency` / `FM3Mode` (= 軸 4 ratify) / `ADPCMBDma` / `Volume` / `Pan` / `LoopStart` / `LoopEnd` 他。

## 検証 command

repo root で実行。

### positive validation のみ (= default)

```bash
python3 scripts/validate-ir-schema.py
```

実行内容:

1. schema 自身が JSON Schema draft-2020-12 として正当か (= meta-validation)
2. `examples/*.ir.json` 全件が schema に適合するか (= positive validation)

期待 exit: **0** (= 全 positive example が PASS)

### positive + negative validation

```bash
python3 scripts/validate-ir-schema.py \
  --invalid-examples 'docs/design/intermediate-register-command/examples/invalid/*.ir.json'
```

実行内容:

1. 上記 positive validation
2. `examples/invalid/*.ir.json` 全件が schema validation で **失敗する** ことを確認 (= negative validation、 失敗 = PASS、 通過 = FAIL)
3. 各 invalid fixture の representative error (= JSON pointer 式 location + message) を表示

期待 exit: **0** (= 全 invalid fixture が想定通り reject される)

### option

```bash
python3 scripts/validate-ir-schema.py --schema <path> --examples '<glob>' --invalid-examples '<glob>'
```

## exit code

| code | 意味 |
|---|---|
| 0 | all pass |
| 64 | argument error (= file not found / JSON parse error) |
| 65 | schema / data validation fail |
| 66 | runtime error (= unexpected exception / missing dependency) |

## 依存

- Python 3.10+ (= `from __future__ import annotations` + `list[Path]` 型 hint 利用)
- `jsonschema` package (= draft-2020-12 support 必要、 4.18+ 推奨。 開発確認は 4.26.0)

## scope (= ADR-0034 + 24th session user 指示遵守)

- compiler 実装は含まない
- WebApp 実装は含まない
- runtime / driver source は touch しない
- `.NEO` container は作らない
- `.mn` / `.PNE` 生成 path は触らない
- binary IR encoder は作らない
- YAML 版は作らない
