# ADR-0003: PMD MML cmd byte code 割当規約 (= PMDNEO 独自拡張 + PMD V4.8s 互換)

- 状態: Accepted
- 起票日: 2026-05-10
- 起票者: 越川将人 (M.Koshikawa)
- 関連: Phase 9a (= comq)、 Phase 9c (= §5 volume cmd 群一括実装)、 ADR-0002

## 背景

PMD V4.8s 本家 driver (= PMD_Z80.inc) の cmdtblp は 79 entry の byte code → routine table。 PMDNEO の自作 driver (= standalone_test.s) は dispatch 共通化 refactor (= ADR-0002) 完了後、 commandsp 拡張で各 cmd を実装中。

ただし PMD V4.8s 本家 cmdtblp に entry 不在の cmd (= V (= §5-2 大文字) 等) は **PMDNEO 独自 byte code 割当が必要**。 一方、 entry あり の cmd (= q (= 0xFE)、 q2 (= 0xC4)、 q3 (= 0xB3)、 q4 (= 0xB1)、 ) (= 0xF4)、 ( (= 0xF3) 等) は **PMD 本家流儀踏襲** が原則。

本 ADR で PMDNEO の byte code 割当規約を確定する。

## 規約

### 原則 1: PMD V4.8s 本家流儀踏襲

PMD_Z80.inc cmdtblp に entry ある cmd は **同 byte code を使用**。 PMD 本家楽曲互換性確保のため。

### 原則 2: 本家未定義 cmd は PMDNEO 独自割当 + ADR 記録

cmdtblp に entry 不在の cmd は PMDNEO 独自 byte code を選択、 本 ADR (= or 後続 ADR) に追記。 衝突回避のため **PMD 本家 jump1 entry (= 未定義 fallback)** を選んだ byte を優先利用。

### 原則 3: byte code 範囲

- **0xFF**: PMD 本家で `@N` (voice 切替)、 PMDNEO 未実装 (= 後続 phase 対応)
- **0xF0-0xFE**: PMD 本家で多用 (= cmt/comv/comq/comstloop/comedloop 等)、 衝突注意
- **0xC0-0xEF**: PMD 本家で 中頻度使用、 jump1 entry (= 未定義 fallback) も多数あり、 PMDNEO 独自割当の主 候補
- **0xB0-0xBF**: PMD 本家で 低頻度使用、 jump1 entry あり

## 実装済 byte code 一覧 (= 2026-05-10 develop)

### PMD 本家流儀踏襲 (= 原則 1)

| byte | cmd | routine | PMD MML §| 状態 |
|------|-----|---------|----------|------|
| 0xFC | t (tempo) | comt | §3-1 | ✓ Phase 5c |
| 0xFD | v (volume 大雑把) | comv | §5-1 | ✓ Phase 9c (= v→V 変換 拡張済) |
| 0xFE | q (gate 数値1) | comq | §4-13 | ✓ Phase 9a |
| 0xC4 | q2 (= q 数値2 random 上限) | comq2 | §4-13 | ✓ Phase 9b |
| 0xB3 | q3 (= q 数値3 最低保証 中間) | comq3 | §4-13 | ✓ Phase 9b |
| 0xB1 | q4 (= q 数値3 最低保証) | comq4 | §4-13 | ✓ Phase 9b |
| 0xF4 | ) (volume up 1 回) | comvolup | §5-5 | ✓ Phase 9c |
| 0xF3 | ( (volume down 1 回) | comvoldown | §5-5 | ✓ Phase 9c |
| 0xF9 | [ (loop start) | comstloop | §3-2 | ✓ Phase 5b |
| 0xF8 | ] (loop end) | comedloop | §3-2 | ✓ Phase 5b |

### PMDNEO 独自割当 (= 原則 2)

| byte | cmd | routine | PMD MML §| 状態 | 備考 |
|------|-----|---------|----------|------|------|
| **0xCC** | V (volume 細かい) | comV | §5-2 | ✓ Phase 9c | 本家 detune_extend と同 byte、 PMDNEO 未実装で衝突なし |
| **0xDE** | v+ (= V level shift +) | comvshift_up | §5-3a | ✓ Phase 9c | 本家 vol_one_up_psg と同 byte、 別意味で PMDNEO 独自 |
| **0xDD** | v- (= V level shift -) | comvshift_down | §5-3a | ✓ Phase 9c | 同 |
| **0xDB** | v) (= v level shift +) | comvscale_up | §5-3b | ✓ Phase 9c | 本家未定義 (= jump1) を流用 |
| **0xDA** | v( (= v level shift -) | comvscale_down | §5-3b | ✓ Phase 9c | 同 |

## 後続候補 (= 未実装、 規約準拠で割当予定)

### PMD 本家流儀踏襲 (= 0xFB / 0xFA / 0xF7 / 0xF6 等の cmdtblp entry あり)

| byte | cmd | routine | PMD MML §| 後続 phase |
|------|-----|---------|----------|----------|
| 0xFB | & (tie) | comtie | §3-2 | Phase 11+ |
| 0xFA | D (detune) | comd | §6-2 | Phase 12+ |
| 0xF7 | : (exit loop) | comexloop | §3-2 | Phase 11+ |
| 0xF6 | L (loop set) | comlopset | §3-2 | Phase 11+ |
| 0xF5 | _ (transpose) | comshift | §6-3 | Phase 11+ |
| 0xF2 | M (LFO) | lfoset | §9 | Phase 12+ |
| 0xF1 | * (LFO switch) | lfoswitch | §9 | Phase 12+ |
| 0xF0 | E (SSG envelope) | psgenvset | §6-1-2 | Phase 11+ |
| 0xEF | y (direct LSI write) | comy | §13 | 任意 phase |
| 0xEE | w (PSG noise) | psgnoise | §6-1-3 | Phase 12+ |

### PMDNEO 独自割当候補 (= 本家未定義)

| 想定 cmd | 候補 byte (jump1 entry) |
|---------|------------------------|
| #PCMVolume header | 未定 |
| #FM3Extend slot 別 | 未定 |
| 内部 opcode (= MVPM v3 拡張) | 未定 |

## 衝突回避ルール

PMDNEO 独自 byte code を新規割当する際:

1. PMD V4.8s cmdtblp で **未使用 (= jump1 entry) byte** を優先選択
2. 既 PMDNEO 実装済 byte と衝突しない
3. 本 ADR に追記 + commit message で記録

## 関連

- 設計書: `docs/design/dispatch_unification.md` (= dispatch 共通化、 commandsp 経路)
- 設計書: `docs/design/pmdneo_self_contained_driver.md` 8 章 (= chip access protocol、 後続 update 候補)
- ADR-0002: dispatch 共通化 refactor (= 本 ADR の前提)
- 公開報告書: https://koshikawa-masato.github.io/pmdneo/pmdmml-coverage.html (= 142 件 base 進捗)
- memory `feedback_official_spec_doc_grep_authority.md` (= 公式 spec doc 参照規律)
- PMD V4.8s 本家: vendor/pmd48s/PMDMML.MAN
