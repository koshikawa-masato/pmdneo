# Surge XT `.fxp` bridge investigation (= ADR-0033 §決定 27 ξ/π ο/π 調査報告)

- 状態: **investigation findings + factory acquisition validated** (= 23rd session ο1 + π)
- 関連 ADR: ADR-0033 §決定 25 / §決定 26 / §決定 27 (= λ/μ/ν/ξ/π)
- 関連 commit: f6f8c9f (= ξ) / 1b5f20c (= ο1) / 本 commit (= π)
- scope: §決定 27 (1) AI 役割 (= ξ で 4 軸 / π で 5 軸 = template acquisition 追加) の feasibility 確認 + spike 設計 + factory template 実 acquisition

---

## 1. 調査目的 (= ξ scope-in 5 件の根拠 evidence 化)

§決定 27 ξ で AI/toolchain による `.fxp` template-based bridge を scope-in 化したが、
実装可能性 (= feasibility) の evidence が ADR 内に存在しない。 本 doc で:

- VST2 FXP container format の bytewise spec
- Surge XT の `.fxp` 内部 chunk 構造 (= FPCh custom chunk)
- template + parameter allowlist patching 方式の実装可能性
- 「bridge, not full synthesizer patch compiler」 の technical 境界

を literal 化し、 ο 以降の bridge 実装に進める基盤を作る。

## 2. VST2 FXP container format (= 外殻 28 byte header literal)

VST2 preset (`.fxp`) は Steinberg VST2 SDK 由来の bank/preset container。
`vstfxstore.h` 定義の big-endian binary layout:

```text
offset  size  field              description
------  ----  -----------------  ----------------------------------------
 0       4    chunkMagic         ASCII "CcnK" (= literal、 file 識別子)
 4       4    byteSize           uint32 BE = total chunk size 残部 (= 8 byte 以降の bytes)
 8       4    fxMagic            ASCII "FxCk" | "FPCh" | "FxBk" | "FBCh"
12       4    version            uint32 BE = format version (= 通常 1)
16       4    idUint             uint32 BE = plugin unique ID (= Surge XT 固有値)
20       4    fxVersion          uint32 BE = patch version
24       4    count              uint32 BE = parameter count (FxCk) or program count (FxBk)
28      ...   <chunk body>       fxMagic に応じた構造
```

### `fxMagic` 4 種の body 構造

| fxMagic | meaning | body layout |
|---------|---------|-------------|
| `FxCk` | FXP simple params | `programName` 28B + `params[count]` (= 各 float32 BE) |
| `FPCh` | **FXP custom chunk** | `programName` 28B + `chunkByteSize` 4B + `patchChunk[chunkByteSize]` raw |
| `FxBk` | FXB bank (programs) | `future[128]` + `programs[count]` (= each FXP-like) |
| `FBCh` | FXB custom chunk | `future[128]` + `chunkByteSize` 4B + `bankChunk[chunkByteSize]` raw |

### Surge XT は `FPCh` で確定

Surge XT は wavetable / scene state / modulation matrix 等の複雑な内部 state を持つ
ため、 単純 float array (= FxCk) では収まらず、 `FPCh` (custom chunk) を採用。
これは Surge GitHub issue #6627 で「FXP header を捨てて XML/JSON にしたい」 議論が
ある事実から逆算的に確定 (= 現在は FXP header + custom chunk 構造)。

evidence:
- vst2-preset-parser/index.js (= CharlesHolbrow、 binary parser spec literal)
- Surge issue #6627 (= 現状 FXP container 利用 + base64 wavetable encode 提案)
- KVR Audio thread t=136183 (= VST2 fxp/fxb 4 種 chunkMagic 確認)

## 3. Surge XT FPCh custom chunk の中身 (= 推定)

`patchChunk` (= FPCh の body) の中身は Surge XT 内部仕様。 issue #6627 で「XML/JSON
にすれば text 編集可能」 議論があるため、 **現状は XML or binary blob** と推定。
正確な構造は Surge source (= github.com/surge-synthesizer/surge) の `src/common/SurgePatch.cpp`
等の `loadXMLPatch` / `streamXMLPatchState` ロジックを読まないと確定しない。

ο1 段階 (= 本 doc) では **「chunk 内部は未解析、 template + parameter byte offset で識別可能」**
の仮説で進める = full reverse engineering を回避し、 template `.fxp` の specific byte
offset を patching する方式 (= bridge, not compiler) で十分。

### 推定 chunk 内容 (= 仮説)

- XML root element (= `<patch>` or `<surgePatch>` 等)
- scene A / B section (= 2 scene parallel)
- per-scene: 3 osc + 2 filter + AEG/FEG + 6 LFO + waveshaper + FX
- modulation matrix entries
- wavetable references (= 多分 index、 別 directory 参照)
- patch metadata (= name / category / author / tags)

具体 schema 確定は ο 以降の sub-sprint (= 実 template `.fxp` を 越川氏 hand-on で
作成後の binary inspection で diff 観察) に分離。

## 4. Bridge architecture proposal (= 「bridge, not full synthesizer patch compiler」)

### 4.1 役割境界 (= §決定 27 (1) AI 役割 2 軸 literal)

```text
入力:
  - template `.fxp`               (= 越川氏 hand-on で 1 度のみ作成、 全 6 drum 共通 base)
  - `template.fxp.provenance.yaml` (= 変更禁止領域 literal + hash + version 等)
  - `parameter-allowlist.yaml`    (= touch 可能 parameter literal list)
  - drum-specific `patch-spec.yaml` (= e.g. 2608_bd.patch-spec.yaml)

処理:
  1. template `.fxp` を read-binary
  2. VST2 header parse (= 28 byte literal)
  3. FPCh `patchChunk` 領域 locate (= byte offset 60 + chunkByteSize 4 byte 後)
  4. parameter allowlist + patch-spec の値を chunk 内 specific byte offset へ patch
  5. byteSize fields の再計算 (= header byteSize + FPCh chunkByteSize)
  6. 出力 `.fxp` の write-binary

出力:
  - `<drum>.fxp` (= drum-specific patch、 candidate 扱い)
```

### 4.2 「bridge, not compiler」 制約 literal

- AI/toolchain は **template `.fxp` の binary を直接 patch** する (= byte 単位の overwrite)
- AI/toolchain は **Surge XT FPCh chunk format を full parse しない** (= XML/binary 内部構造を理解しない)
- AI/toolchain は **template `.fxp` の 変更禁止領域 (= VST2 header + 一部 chunk 領域) を touch しない**
- AI/toolchain が touch するのは **`parameter-allowlist.yaml` で literal に enumerate された byte offset / parameter のみ**
- byte offset → parameter 名 mapping は **越川氏 hand-on で template 作成 + binary diff 観察で確定** (= AI 推測で増やさない)

### 4.3 parameter allowlist の構造 (= 提案)

```yaml
# parameter-allowlist.yaml の構造提案
allowed_parameters:
  - name: amp_envelope_decay
    byte_offset: 0x1234   # template `.fxp` 内の specific offset
    byte_size: 4
    encoding: float32_be
    valid_range: [0.0, 1.0]
    surge_xt_param_id: "a_amp_env_decay"
    notes: "AHDSR decay segment、 0.0 = 0ms / 1.0 = ~10 sec"
  - name: osc1_pitch
    ...
prohibited_byte_ranges:
  - range: [0, 28]
    reason: "VST2 header、 §決定 27 ξ scope-out 整合"
  - range: [28, 56]
    reason: "programName field、 別軸 (= drum name) で AI が string 書換、 byte 範囲不変"
  - ...
```

実 byte offset は **template `.fxp` 作成後の binary diff** で確定 (= 越川氏 hand-on 経由)。
ο1 段階では schema のみ literal 化、 actual values は pending。

## 5. fxp2wav-surge 接続点 (= §決定 25 spike track 1 経路)

§決定 25 ι' で fxp2wav-surge = required external producer (= PMDNEO 外部 spike) 認定。
bridge 出力 `.fxp` は fxp2wav-surge 経由で `.wav` render。

接続点:
```text
PMDNEO ξ bridge tool                  fxp2wav-surge (= external)
-----------------                     ---------------------------
2608_bd.fxp (= candidate output)  →   --input X.fxp \
                                       --note D2 --velocity 100 \
                                       --duration 800ms \
                                       --sample-rate 44100 \
                                       --output X.wav
                                          ↓
                                       2608_bd.wav (= candidate)
```

fxp2wav-surge CLI 仕様は §決定 25 spike 成立後確定。 §決定 27 (6) workflow step 3
で AI/toolchain orchestrated render として 1-command 化が目標。

## 6. Feasibility assessment (= 4 risk axes)

| axis | risk level | 評価 |
|------|-----------|------|
| **VST2 container parse** | 低 | 28 byte header literal 既知、 Python `struct` で確実 parse 可 |
| **FPCh chunk locate** | 低 | offset = 60 + 4 byte chunkSize 後、 byte offset 演算のみ |
| **template `.fxp` 内 parameter byte offset 同定** | 中 | 越川氏 hand-on で同一 template から異 parameter 値 patch を Surge XT GUI で複数保存 → binary diff で byte offset 確定 |
| **byteSize 再計算 + write back** | 低 | parameter byte size 不変なら chunkSize / byteSize も不変、 patch のみで OK |

**総合判定: feasibility = HIGH** (= 4 axis 全部 低-中 risk、 spike 実装可能)

## 7. ο spike scope (= 本 commit deliverables)

本 ο commit (= ο1) で deliver する範囲:

- [x] 本 investigation doc (= 1 件、 本 file)
- [x] `template.fxp.provenance.yaml` schema (= placeholder、 pending state)
- [x] `parameter-allowlist.yaml` schema (= placeholder、 pending state)
- [x] `scripts/fxp_template_patch.py` (= 最小 spike、 VST2 header parse + FPCh chunk locate read-only)

**含めない範囲 (= ο 以降に分離):**

- [ ] 実 template `.fxp` 作成 (= 越川氏 hand-on、 別 commit)
- [ ] template から binary diff で parameter byte offset 同定 (= 越川氏 hand-on 後)
- [ ] actual parameter patching 実装 (= byte overwrite + byteSize 再計算)
- [ ] fxp2wav-surge との連携 1-command (= §決定 25 spike track 1 成立後)
- [ ] AI self-analysis 10 項目検査 (= §決定 27 (5) ν 規定、 wav 生成後)

## 8. Open questions (= 越川氏 hand-on / 越川氏 判断 待ち)

1. **template `.fxp` の base patch design**:
   - BD/SD/CYM/HH/TOM/RIM 全部に対応できる「neutral base」 vs drum-specific patch のどちらにするか?
   - 全 6 drum 種で 1 template 共有なら、 base = 中庸 (= neutral OSC + envelope)
   - drum 種ごとに template を分けるなら、 6 template 必要 (= ξ artifact 数膨張)
   - 推奨 = **全 6 drum 1 template 共有 + drum-specific は parameter patching で表現** (= ξ wording 整合)

2. **template `.fxp` の programName**:
   - 「PMDNEO 2608 Template v0」 のような中庸 name で固定?
   - drum-specific patch では programName を AI bridge が書換?

3. **Surge XT GUI で hand-on する範囲**:
   - 全 parameter を一通り触って sound design するか
   - 必要最小限の OSC + envelope のみで base を作るか
   - 推奨 = **必要最小限の base** (= patching allowlist 範囲で全 drum 表現可能な最小 parameter set)

4. **parameter allowlist の確定方法**:
   - Surge XT のどの parameter を「全 drum 共通 patching 対象」 にするか?
   - 提案: OSC pitch / OSC waveform / amp envelope (AHDSR) / filter cutoff / drive / pitch envelope (= §決定 26 (5) + §決定 26 (6) literal 整合)
   - 越川氏 audition で確定

## 9. 次の commit 候補 (= ο 以降の chain)

- **ο2** (= 越川氏 hand-on): `2608_template.fxp` 作成 + provenance fill + Surge XT GUI で 2 種 parameter 値で同 patch 保存 (= binary diff 用 fixture)
- **ο3** (= Claude 側): binary diff で parameter byte offset 同定 + `parameter-allowlist.yaml` fill
- **ο4** (= Claude 側): `scripts/fxp_template_patch.py` を read-only spike から actual patching 実装に拡張
- **ο5** (= Claude 側): `2608_bd.patch-spec.yaml` → `2608_bd.fxp` bridge invoke で初回 .fxp 生成
- **ο6** (= 別 track / §決定 25 spike): fxp2wav-surge CLI 確立
- **ο7** (= Claude 側): `2608_bd.fxp` → fxp2wav-surge render → `2608_bd.wav` candidate
- **ο8** (= Claude 側): AI self-analysis 10 項目 (= ν 規定) + `analysis-report.yaml` 生成
- **ο9** (= 必要時): patch-spec / .fxp 再調整 → step ο4 へ loop
- **ο10** (= 越川氏): rendered audio audition / aesthetic accept
- **ι commit** (= 越川氏 accept 後): `2608_bd_self.adpcma` encode + 並行配置 + ι commit

## 11. π findings (= 2026-05-16 23rd session π、 factory acquisition + XML body confirmed)

ο1 から π への軸転換 (= 越川氏 hand-on engineering 接点ゼロ化) の根拠を実測 evidence で literal 化:

### 11.1 Surge XT factory `.fxp` 取得経路確定

Surge XT 1.3.4 install (= Homebrew cask) は system-wide data を以下 path に配置:

```text
/Library/Application Support/Surge XT/
├── patches_factory/        ← factory presets (= 637 件、 17 category)
│   ├── Basses/
│   ├── ...
│   ├── Templates/          ← Init patches 11 件
│   │   ├── Init Sine.fxp        ← 31538 byte、 sha256 0366cc1057...
│   │   ├── Init Saw.fxp         ← 31343 byte
│   │   ├── Init Modern.fxp      ← 31442 byte
│   │   ├── Init Square.fxp      ← 31424 byte
│   │   ├── Init FM2.fxp         ← 31451 byte
│   │   ├── Init Sine.fxp        ← ★ 採用: 全 6 drum 共通 neutral carrier
│   │   ├── Init Wavetable.fxp   ← 425435 byte (= wavetable 入り、 過剰)
│   │   ├── Init Experimental.fxp ← 163246 byte (= 過剰)
│   │   └── ... (= 他)
│   └── ...
├── fx_presets/
├── modulator_presets/
├── patches_3rdparty/
├── wavetables/
└── ...

~/Documents/Surge XT/         ← user data area
├── Patches/                  ← user patches (= 空)
├── SurgePatches.db           ← patch index database
└── SurgeXTUserDefaults.xml   ← user defaults
```

**「Templates」 directory が公式 init patch 集** = Surge Synth Team が neutral 開始 state として
提供する 11 件 Init patch。 越川氏 hand-on で「neutral template を最初から作る」 必要なし =
**factory CC0 acquisition で代替可能**。

### 11.2 license 確定 = CC0

Surge XT factory Templates/Init Sine.fxp の内部 XML `<meta>` element:

```xml
<meta name="Init Sine" category="Templates" comment=""
      author="Surge Synth Team"
      license="Licensed under the maximally permissive CC0 license">
  <tags />
</meta>
```

CC0 = public domain dedication、 attribution 不要、 改変 + 再配布 + 商用利用 全自由。
PMDNEO GPL-3.0 narrative と完全整合、 §決定 1 (= 越川氏 100% 著作物方針) とも矛盾なし
(= template は sound design asset ではなく neutral carrier、 「越川氏 著作物」 主張対象ではない)。

### 11.3 chunk 内部構造確定 = sub3 magic + binary header + XML + trailing binary

Init Sine.fxp の FPCh chunk (= 31478 byte) 内部 layout:

```text
chunk offset  size       content
------------  ---------  ---------------------------------------------------------
[0, 4)        4 byte     "sub3" magic (= Surge XT internal chunk format marker)
[4, 32)       28 byte    binary header (= version + padding + 内部 metadata)
[32, 31470)   31438 byte XML body (= <?xml ?> <patch revision="22"> ... </patch>)
[31470, 31478) 8 byte    trailing binary (= 用途未確定、 推定 checksum or padding)
```

XML body 構造 (= 越川氏 hand-on engineering を完全に冷凍する key finding):

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<patch revision="22">
  <meta name="..." category="..." comment="..." author="..." license="...">
    <tags />
  </meta>
  <parameters>
    <volume_FX1 type="2" value="1.00000000000000" />
    <volume_FX2 type="2" value="1.00000000000000" />
    <volume_FX3 type="2" value="1.00000000000000" />
    <volume_FX4 type="2" value="1.00000000000000" />
    <volume type="2" value="-9.68199920654297" />
    <scene_active type="0" value="0" />
    <scenemode type="0" value="0" />
    <splitkey type="0" value="60" />
    ...
    <a_pitch type="2" value="0.00000000000000" extend_range="0" />
    <a_portamento type="2" value="..." />
    ... (= 数百 parameter element)
  </parameters>
  ...
  <customcontroller>...</customcontroller>
  <lfobanklabels />
  <modwheel s0="0" s1="0" />
  <compatability>
    <correctlyTunedCombFilter v="1" />
  </compatability>
  <dawExtraState populated="0" />
</patch>
```

### 11.4 bridge approach 軸転換 = byte offset → XML element name

ο1 設計では「template binary diff で byte offset 同定 → byte overwrite」 を提案。
π findings で **XML body 確認** したため、 **XML element name 軸 patching** に置換可能:

| approach | ο1 提案 (byte offset) | π refinement (XML element name) |
|----------|----------------------|--------------------------------|
| target identification | binary diff で byte offset 同定 | XML element tag name |
| patching method | byte overwrite at specific offset | XML element value attribute 修正 |
| safety check | byte size 一致確認 | XML parse 成功 + schema validation |
| allowlist representation | byte_offset + byte_size | xml_element_name + xml_type |
| 越川氏 hand-on 必要性 | あり (= 2 fixture 保存で binary diff) | **なし** (= XML element 一覧 dump で自動同定可能) |
| chunk size 変動対応 | byte size 不変前提 | byte size 変動時 chunkByteSize + byteSize 再計算 |
| failure mode | byte corruption (= silent) | XML parse error (= 検出容易) |

**π refinement で XML 軸採用** = 越川氏 hand-on を完全削除可能 + safer + cleaner。

### 11.5 越川氏 hand-on engineering 接点ゼロ化

ξ で残っていた「越川氏 template 作成 1 度」 work も π で **AI/toolchain acquisition** に置換:

```text
旧 (ξ): 越川氏 Surge XT GUI → template `.fxp` 保存 → provenance fill
新 (π): AI/toolchain → factory Init Sine.fxp copy → provenance auto-fill from CC0 metadata
```

越川氏 engineering 接点 = **完全にゼロ**、 越川氏 work は **rendered audio aesthetic
audition / accept のみ**。 ν 本質 (= 越川氏 認知負荷を engineering correctness から解放) を
完全貫徹。

### 11.6 π1 commit deliverables (= 本 commit)

- [x] template acquisition 実行 (= `assets/drum_samples/synth/templates/2608_template.fxp`、 31538 byte、 sha256 0366cc10...)
- [x] template.fxp.provenance.yaml 全 fields fill + license narrative + chunk 内部構造 literal
- [x] parameter-allowlist.yaml = XML element name 軸 update + prohibited / allowed XML elements literal
- [x] 本 investigation doc § 11 = π findings literal 化
- [x] ADR-0033 §決定 27 = π refinement (= AI 役割 4 → 5 軸、 越川氏 hand-on engineering ゼロ化)

### 11.7 π2 以降の chain (= ο workflow 11 step 内、 越川氏 hand-on ゼロ前提)

- **π2** (= Claude 主体): scripts/fxp_template_patch.py extract-xml subcommand 実装 (= chunk から XML body 抽出 + pretty print)
- **π3** (= Claude 主体): XML parameter element 一覧 dump + candidate 6 category と照合 → parameter-allowlist.yaml の `allowed_parameters[]` literal 値 fill
- **π4** (= Claude 主体): scripts/fxp_template_patch.py patch subcommand 実装 (= patch-spec + allowlist → XML element value 修正 + chunk 再 pack)
- **π5** (= Claude 主体): `2608_bd.patch-spec.yaml` + `2608_template.fxp` + `parameter-allowlist.yaml` → `2608_bd.fxp` bridge 実行
- **π6** (= 別 track / §決定 25 spike): fxp2wav-surge CLI 確立
- **π7** (= Claude 主体): `2608_bd.fxp` → fxp2wav-surge render → `2608_bd.wav` candidate
- **π8** (= Claude 主体): AI self-analysis 10 項目 + `analysis-report.yaml` 生成
- **π9** (= 必要時): patch-spec / .fxp 再調整 → step π5 へ loop
- **π10** (= **越川氏唯一の hand-on 接点**): rendered audio audition / aesthetic accept
- **ι commit** (= accept 後): `2608_bd_self.adpcma` encode + 並行配置 + commit

## 10. 関連外部資料

- [vst2-preset-parser (CharlesHolbrow)](https://github.com/CharlesHolbrow/vst2-preset-parser) — VST2 binary parser (= MIT、 byte layout literal)
- [KVR Audio thread t=136183](https://www.kvraudio.com/forum/viewtopic.php?t=136183) — VST2 FXP/FXB 4 種 chunkMagic 議論
- [Surge issue #6627](https://github.com/surge-synthesizer/surge/issues/6627) — Surge 現状 FXP 利用確認 + 将来 XML/JSON 移行議論
- [Surge GitHub](https://github.com/surge-synthesizer/surge) — Surge source (= future ο3 で `SurgePatch.cpp` 等 reference 候補、 但し ξ 制約「full RE 最小限」 で深入りしない)
- Steinberg VST2 SDK `vstfxstore.h` (= 一次資料、 ASF SDK retired、 archived mirror 参照)
