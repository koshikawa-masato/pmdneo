# PMDNEO COVERAGE DASHBOARD

PMDNEO の MML 実装状況と driver 機能実装状況を NEOGEO retro design で
視覚化する単一 HTML page。

## 目的

- MML opcode (V4.8s 仕様) × (manual / compile.py / driver) の coverage を
  matrix で一覧
- driver feature × channel (FM 6 / SSG 3 / ADPCM-A 6 / ADPCM-B 1 = 計 16 ch)
  の実装状況を heatmap で一覧
- Phase 1〜4 roadmap の進捗を panel で表示

## 起動方法

### 方法 A: 単純な browser 直接開き

```
open docs/dashboard/index.html
```

(macOS / Linux + GUI)

ただし一部 browser は `file://` 配下の `fetch()` を block するため、 data.json
の読み込みに失敗する場合がある。 その場合は方法 B を使う。

### 方法 B: ローカル http server

```
cd docs/dashboard && python3 -m http.server 8765
```

その後 `http://localhost:8765/` を browser で開く。

## file 構成

```
docs/dashboard/
├── index.html   ← Tailwind CDN + Alpine.js + custom CSS (= retro design)
├── data.json    ← MML opcode + driver feature + Phase の coverage data
└── README.md    ← 本 file (= 編集規律 + data schema 説明)
```

## data schema (= `data.json`)

### meta

| key | 内容 |
|---|---|
| `title` | 表示 title |
| `subtitle` | 副題 |
| `lastUpdated` | YYYY-MM-DD |
| `schemaVersion` | data.json schema version (= 例 `0.1.0-skeleton`) |
| `fillStatus` | data fill 進捗 description |
| `repoUrl` | repo URL |

### legend

cell の状態 5 種 = `implemented` / `partial` / `not_implemented` / `n_a` / `tbd`。
各々 `label` / `symbol` / `color` を持つ。

### mmlOpcodes

```
columns: [ { key, label, ref }, ... ]    ← MANUAL / COMPILER / DRIVER 3 軸
rows:    [ { opcode, name, category, manual, compiler, driver }, ... ]
```

`category` は CSS class で色分けされる (= voice / pitch / rhythm / volume / spatial / flow / ssg)。
各 row の `manual` / `compiler` / `driver` 値は legend の key (= `implemented` 等) を入れる。

### driverFeatures

```
channels: [ { key, label, group }, ... ]  ← FM/SSG/ADPCM-A/ADPCM-B 計 16 ch
features: [ { key, label, scope }, ... ]  ← VOICE/TL/AR/.../FADE
matrix: {
  "<channel.key>": { "<feature.key>": "<legend key>" },
  _default: "tbd",
  _note: "..."
}
```

`scope` は CSV (= 例 `"FM,SSG"`) で対象 group を絞る。 channel の group が scope
に含まれない場合、 cell は自動的に `n_a` 扱い。

### phases

Phase 1〜4 のサマリ。 各々 `id` / `label` / `status` / `note`。

## 更新規律 (= 軽量、 ADR 起票しない)

1. **編集は wip-dashboard-coverage 系 branch + 単独 PR で集約 branch に merge**
   (= ADR-0041 §決定 3 流儀に倣う、 ただし driver / runtime 不変なら ADR は不要)
2. **driver / compile.py の実装状況を変えた sprint で本 dashboard も同時 update**
   が推奨 (= ただし手動 maintain、 強制ではない)
3. **`data.json` の schema 変更は `schemaVersion` を bump** (= 0.1.x → 0.2.0 等)
4. **cell 値の根拠は短く `_note` field に literal 記入可** (= 例: ADR-XXXX §Y
   による) — schema には未定義だが future extension

## 既知の限界 + 後続 sprint 候補

- 現状 fill = skeleton (= ほぼ全 cell TBD)。 後続 sprint で:
  - manual / compile.py / driver source を 1 行 1 行突き合わせて fill
  - script 化 (= `scripts/build-dashboard-data.py` で driver/manual から auto 抽出)
- ADR network graph view (= D3.js force-directed) は別 page で将来追加候補
- sprint timeline / PR chain view は dashboard scope-out (= 既存
  `docs/parallel-axes-dashboard.md` で別 view)

## ドキュメント統治 (= CLAUDE.md §ドキュメント統治) との position

本 dashboard は **人間向け公開 docs** 寄りの可視化レイヤ。 ground truth は
`docs/adr/` 配下の AI協働用 ADR + driver / compile.py source。 dashboard 自身は
派生物であり、 dashboard の cell 値を理由に既存 ADR を解釈変更するのは禁止。

逆に ADR の literal が変わった場合、 dashboard の data.json を追従させる
(= dashboard は ADR follower)。
