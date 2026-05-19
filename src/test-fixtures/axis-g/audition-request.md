# 軸 G sub-sprint ε integration audition request (= 越川氏 audition 用)

ADR-0048 §決定 8 案 C 経路の ε integration + audition gate。 δ で実装した `.PPC` runtime selection proof が、 同一 MAME 起動内で既存 yaml passthrough 経路 + ADPCM-A 経路と同居して破綻しないことを越川氏 audition で確認するための request 文書です。

## audition 用 wav file

| wav | path | size | 内容 |
|---|---|---|---|
| production | `/tmp/pmdneo-axis-g-production.wav` | 1152048 byte (= 6 秒、 48 kHz stereo) | TEST_MODE_AXIS_G_INT=0 (= production default)、 既存 ADR-0043 yaml passthrough 経路 + ADPCM-A 経路通常運転 |
| audition | `/tmp/pmdneo-axis-g-audition.wav` | 1152048 byte (= 6 秒、 48 kHz stereo) | TEST_MODE_AXIS_G_INT=1 (= ε integration audition build)、 1 秒経過時に `sample_table_id` を 0x80 に切替 → J part 以降の ADPCM-B keyon は `.PPC` 経路で鳴る |

sha256 literal (= audio が違うことの literal 証跡):

```
e48cf7731f0862ccd153c4aee2803f12946667eb1ef8417812137cccee082920  production.wav
f69dd4c38e9ef125e571999e46b9ec1a329dcf318289881cde0abe1f95172934  audition.wav
```

## timeline (= audition wav の中身)

| 時間帯 | ADPCM-A | ADPCM-B |
|---|---|---|
| 0 秒 〜 1 秒 | 既存 song の通常通り L-Q ch (= 6 ch BD/SD/HH/RIM/TOM/TOP 系) | sample_table_id=0x00 (= yaml beat = `adpcmb_sample_beat` literal table) で keyon = 既存 ADR-0043 経路の音 |
| 1 秒以降 〜 6 秒 | 同上 (= ADPCM-A 経路は全期間で song 通り) | sample_table_id=0x80 (= `.PPC` 経路 entry 0) で keyon = 軸 G 新規 `pmdneo_select_adpcmb_ppc_pointer` 経路の音 |

`.PPC` 経路の音は `src/test-fixtures/axis-g/minimum.PPC` の entry 0 が指す ADPCM-B raw byte (= filler の deterministic byte pattern (i & 0x7F)) を decode した音。 aesthetic 評価対象外 (= test fixture 用 filler、 実 PMD V4.8s sample 採用は別 sprint)。

## 確認してほしい点

1. **2 wav の audio に違いがあるか** (= 1 秒以降で audition.wav が production.wav と差がある = sample_table_id 切替が effective)
2. **ADPCM-A 経路が全期間で破綻していないか** (= 軸 G driver 改修で既存 ADPCM-A 経路が壊れていない、 ADR-0048 §決定 8 production-ready 保護)
3. **`.PPC` 経路の音が「鳴っている」 か** (= 1 秒以降の audition.wav で ADPCM-B が silent ではなく何かしらの音が鳴っている = 軸 G 経路 functional)
4. **既存 yaml beat 経路が production.wav で正常か** (= TEST_MODE_AXIS_G_INT=0 で従来通りの音、 軸 C ADR-0043 完成版と同等)

aesthetic 観点 (= 「テンポが速い」 等、 ADR-0043 軸 C δ で literal 化済の future sprint 候補) は本 audition の対象外です。 軸 G ε の audition は「同居 functional + 軸 G 経路で音が出る + 既存経路 byte-identical」 までで十分です。

## 再現手順 (= Codex layer 2 nice-to-have #3 literal、 audition wav の regenerate)

```bash
# production build wav (= TEST_MODE_AXIS_G_INT=0、 既存 default)
bash scripts/run-mame.sh --build --headless --wavwrite --wavwrite-seconds 6
cp /tmp/pmdneo-trace/audio.wav /tmp/pmdneo-axis-g-production.wav

# audition build wav (= TEST_MODE_AXIS_G_INT=1、 ε integration mode)
PMDNEO_AXIS_G_INT=1 bash scripts/run-mame.sh --build --headless --wavwrite --wavwrite-seconds 6
cp /tmp/pmdneo-trace/audio.wav /tmp/pmdneo-axis-g-audition.wav

# sha256 比較 (= 2 wav が異なることを literal 確認)
shasum -a 256 /tmp/pmdneo-axis-g-production.wav /tmp/pmdneo-axis-g-audition.wav

# 視聴 (= macOS afplay)
afplay /tmp/pmdneo-axis-g-production.wav
afplay /tmp/pmdneo-axis-g-audition.wav
```

## audition 結果待ち

越川氏 audition approve (= 「同居 functional + .PPC 経路で音が出ている + 既存経路 byte-identical で破綻していない」) を受領後、 ADR-0048 Draft → Accepted 移行 + ε 完了 section literal + dashboard 軸 G 完了 update + PR2 作成 + merge を主軸が実施します。

audition reject (= 何か破綻していた / 期待と違う音) の場合は driver source 改修 (= test mode block の修正 or selector 経路の見直し) を主軸が実施 + 再 audition request。

## scope-out (= 本 audition 対象外)

- aesthetic 評価 (= テンポ、 音色、 mix balance、 timing artifact 等の趣味判断)
- `.PPC` filler decode 音の音楽的品質 (= test fixture filler のため、 実 sample は別 sprint)
- vendor wav 3 件 (= 永続 untracked retain、 audition 対象外)
- 軸 G ε 以外の sprint 候補 (= 軸 B / 軸 D / 軸 E 等)

## 関連 ADR + memory

- ADR-0048 §決定 8 案 C (= mapping-B 確定 + ROM directory region 設計 + ppc-to-ngdevkit.py 経路)
- ADR-0048 sub-sprint δ 完了 section (= driver 改修 + verify gate 7/7 PASS literal)
- ADR-0041 §決定 4-2 例外 (= user audition は永久 user scope、 主軸単独実装 default の例外)
- memory `feedback_audio_gate_solo_isolation.md` (= audio gate 規律)

ε PR1 (= 本 commit chain) は audition requested 状態で merge され、 audition approve 後の PR2 で ADR-0048 Accepted + ε 完了 section + dashboard sync + 軸 G 完了 を実施します。 PR1 merge では Accepted 化しません (= Codex layer 2 nice-to-have #1 反映、 循環表現回避)。
