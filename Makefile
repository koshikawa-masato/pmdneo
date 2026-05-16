# PMDNEO Makefile — drum sample pipeline 作業者向け入口
#
# ADR-0033 §決定 21 4 系統 canonical pipeline の Makefile 軽量 stub。
# 23rd session sub-sprint α ζ interface fixation = drum-* prefix grouped public targets。
#
# 規律 (= 23rd session ζ 軸転換 literal):
#   Makefile = 作業者向け入口 (= 公開 entry point)
#   Makefile ≠ script 名の写像 (= 内部実装差し替え時も target 名固定)
#   wav_to_adpcma.sh = 低レベル変換、 Makefile 直下に露出しない (= drum-build 内部で呼ばれる)
#   drum-* prefix grouping = 後の `.pne` / `.neo` asset pipeline と naming consistency
#
# 4 target = 作業者の 4 操作軸:
#   drum-sources  - 現存 drum sample 棚卸し (= read-only inventory)
#   drum-build    - source wav → adpcma 6 件 + samples.inc 一括生成
#   drum-verify   - reproducibility gate (= byte-identical sha256 検証)
#   drum-clean    - generated artifact 削除 (= source wav は保持)
#
# 内部対応 (= ADR-0033 §決定 21 4 系統 script):
#   drum-sources  → scripts/forensic-drum-samples.sh (= 23rd session δ 完成 ✓)
#   drum-build    → scripts/build_drum_samples.sh    (= 23rd session ε interface stub、 中身は sub-sprint γ)
#                   ↳ 内部で scripts/wav_to_adpcma.sh を 6 回 invoke
#   drum-verify   → scripts/verify-drum-samples.sh   (= 23rd session ε interface stub、 中身は sub-sprint γ/δ)
#   drum-clean    → 23rd session ζ interface stub、 中身は sub-sprint δ rebuild path 確立後
#
# 現状動作 (= 23rd session ζ 時点):
#   drum-sources  : 動く (= forensic inventory 完成)
#   drum-build    : not-implemented exit 2 (= source wav 不在、 sub-sprint β 完了が前提)
#   drum-verify   : not-implemented exit 2 (= 同上 + manifest 不在)
#   drum-clean    : not-implemented exit 2 (= rebuild path 確立前は temporary fixture 保護、 §決定 11 整合)
#
# canonical default paths (= ADR-0033 §決定 23):
#   source wav directory: assets/drum_samples/synth/
#   generated adpcma:     assets/sounds/adpcma/2608_*.adpcma
#   generated samples.inc: assets/samples.inc
#
# reference:
#   docs/adr/0033-pmdneo-rhythm-sample-provenance-and-self-authored-migration-policy.md
#     §決定 17 (= scripts canonical) / §決定 20 (= sha256 canonical) / §決定 21 (= 4 系統 target)
#     §決定 23 (= filename = drum identity / directory = kit identity) / §Annex A-5 / §Annex A-7

.PHONY: help drum-sources drum-build drum-verify drum-clean

# canonical default paths (override 可能: make drum-build SOURCE_WAV_DIR=assets/drum_samples/acoustic/)
SOURCE_WAV_DIR ?= assets/drum_samples/synth/
MANIFEST_FILE  ?= assets/drum_samples/synth/manifest.sha256

help:
	@echo "PMDNEO drum sample pipeline (= ADR-0033 §決定 21):"
	@echo ""
	@echo "  make drum-sources    現存 drum sample 棚卸し (= forensic inventory、 read-only)"
	@echo "  make drum-build      source wav → adpcma 6 件 + samples.inc 一括生成"
	@echo "  make drum-verify     reproducibility gate (= byte-identical sha256 検証)"
	@echo "  make drum-clean      generated artifact 削除 (= source wav は保持)"
	@echo ""
	@echo "current status (= 23rd session ζ 時点、 sub-sprint α 進行中):"
	@echo "  drum-sources  ✓ 動く (= forensic inventory 完成、 commit 326c88b)"
	@echo "  drum-build    ☐ stub (= source wav 不在、 sub-sprint β 完了が前提)"
	@echo "  drum-verify   ☐ stub (= 同上 + manifest 不在、 sub-sprint γ/δ で実装)"
	@echo "  drum-clean    ☐ stub (= rebuild path 確立後の安全な clean、 sub-sprint δ で実装)"
	@echo ""
	@echo "override:"
	@echo "  SOURCE_WAV_DIR  (= default: $(SOURCE_WAV_DIR))"
	@echo "  MANIFEST_FILE   (= default: $(MANIFEST_FILE))"
	@echo ""
	@echo "see also:"
	@echo "  scripts/forensic-drum-samples.sh    - read-only inventory"
	@echo "  scripts/wav_to_adpcma.sh            - one-file converter (= drum-build 内部 invoke)"
	@echo "  scripts/build_drum_samples.sh       - orchestration"
	@echo "  scripts/verify-drum-samples.sh      - reproducibility gate"

drum-sources:
	@./scripts/forensic-drum-samples.sh

drum-build:
	@./scripts/build_drum_samples.sh "$(SOURCE_WAV_DIR)"

drum-verify:
	@./scripts/verify-drum-samples.sh "$(SOURCE_WAV_DIR)" "$(MANIFEST_FILE)"

drum-clean:
	@echo "drum-clean: ADR-0033 §決定 21 4 系統 4 件目 (= ζ 軸転換時新規) interface stub."
	@echo ""
	@echo "[not-implemented] rebuild path 確立後に有効化します。"
	@echo ""
	@echo "理由 (= ADR-0033 §決定 11 + §Annex A-5-5 finding 2 連動):"
	@echo "  23rd session 時点 = adpcma 6 件は temporary fixture (= unknown 起源、 段階 3 完了まで暫定許容)。"
	@echo "  source wav 不在 + build_drum_samples.sh stub 状態で削除すると、 driver が build できなくなる。"
	@echo "  drum-clean は sub-sprint δ (= 段階 1 完了統合) で「source wav → adpcma rebuild path 確立済」 が"
	@echo "  前提条件で有効化される。"
	@echo ""
	@echo "対象 (= 将来 sub-sprint δ 実装時の削除候補):"
	@echo "  assets/sounds/adpcma/*.adpcma   (= 6 件、 rebuild 可能なので削除安全)"
	@echo "  assets/samples.inc              (= build-time generated 派生物)"
	@echo "non-対象 (= 削除しない):"
	@echo "  assets/drum_samples/synth/*.wav (= source wav、 source-of-truth)"
	@echo "  assets/sounds/adpcma/*-roundtrip.wav (= 段階 3 完了後に削除判断)"
	@exit 2
