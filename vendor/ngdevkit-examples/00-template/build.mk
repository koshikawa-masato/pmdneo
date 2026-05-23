# -*- makefile -*-
# Copyright (c) 2018-2025 Damien Ciabrini
# This file is part of ngdevkit
#
# ngdevkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# ngdevkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ngdevkit.  If not, see <http://www.gnu.org/licenses/>.



define err
	$(error $(1) unset, do not call this makefile directly)
endef
BUILDDIR?=$(call err,BUILDDIR)
ROM?=$(call err,ROM)


# A cartrige is made of one or several chips, as defined in rom.mk
# add all possible dependencies below (undefined chips are just ignored)
CART?=$(ROM)/$(GAMEROM).zip
$(CART): $(PROM1) $(PROM2)
$(CART): $(MROM1)
$(CART): $(CROM1) $(CROM2) $(CROM3) $(CROM4) $(CROM5) $(CROM6) $(CROM7) $(CROM8)
$(CART): $(SROM1)
$(CART): $(VROM1) $(VROM2) $(VROM3) $(VROM4)

# for convenience, we ensure than the initial `make` always builds the
# generated files _before_ the cartridge target, even with parallel builds
# (NOTE: do not use .WAIT yet as it's only available starting GNU Make 4.4)
cart:
	@ if [ ! -f $(BUILDDIR)/.generated ]; then $(MAKE) $(BUILDDIR)/.generated; fi && \
	$(MAKE) --no-print-directory $(CART)

$(CART):
	cd $(ROM) && for i in `ls -1 | grep -v -e \.bin -e \.zip`; do ln -nsf $$i $${i%.*}.bin; done; \
	printf "===\nhttps://github.com/dciabrin/ngdevkit\n===" | zip -qz $(GAMEROM).zip `ls -1 | grep -v -e \.zip`

$(BUILDDIR) $(ROM):
	mkdir -p $@ && touch $@

.PHONY: cart


# -----------------------------------
# Build rules for pre-processing assets before build
#
# This target triggers the generation of assets that must be present prior
# to building the project (including custom generate targets)
$(BUILDDIR)/.generated: | $(SRCDIRS:%=$(BUILDDIR)/%)
	find setup -mindepth 1 -maxdepth 1 -type d -print | xargs -r -n1 $(MAKE) -C
	echo $(CUSTOM_GENERATE_TARGETS) | xargs -r $(MAKE)
	touch $@

$(SRCDIRS:%=$(BUILDDIR)/%): | $(BUILDDIR)
	find $(@:$(BUILDDIR)/%=%) -type d -exec mkdir -p $(BUILDDIR)/{} \; -exec touch $(BUILDDIR)/{} \;

# This target can be use to regenerate all assets manually
generate:
	$(MAKE) -B $(BUILDDIR)/.generated

.PHONY: generate $(CUSTOM_GENERATE_TARGETS)


# -----------------------------------
# Build rules for program ROM

$(BUILDDIR)/%.o: %.cc
	$(M68KGXX) $(NGCFLAGS) $(CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: %.c
	$(M68KGCC) $(NGCFLAGS) $(CFLAGS) -c $< -o $@

%.elf:
	$(M68KGCC) -o $@ $^ $(NGLDFLAGS) $(LDFLAGS)

$(PROM1): | $(ROM)
	$(M68KOBJCOPY) -O binary -S -R .text2 --gap-fill 0xff --pad-to $(PROMSIZE) $< $@ && dd if=$@ of=$@ conv=notrunc,swab status=none

ifdef PROM2SIZE
$(PROM2)_bank%: | $(ROM)
	$(M68KOBJCOPY) -O binary -j .text2 --gap-fill 0xff --pad-to $$((0x200000+$(PROMSIZE))) $< $@ && dd if=$@ of=$@ conv=notrunc,swab status=none

$(PROM2): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(PROM2SIZE) $@
else
$(PROM2): | $(ROM)
	$(M68KOBJCOPY) -O binary -j .text2 --gap-fill 0xff --pad-to $$((0x200000+$(PROMSIZE))) $< $@ && dd if=$@ of=$@ conv=notrunc,swab status=none
endif


# -----------------------------------
# Build rules for sound driver ROM

$(BUILDDIR)/nss/%.rel: $(BUILDDIR)/nss/%.s
	$(Z80SDAS) -g -l -p -u -I$(NGZ80INCLUDEDIR)/nullsound -I$(BUILDDIR) -o $@ $<

$(BUILDDIR)/%.rel: %.s
	$(Z80SDAS) -g -l -p -u -I$(NGZ80INCLUDEDIR)/nullsound -I$(BUILDDIR) -o $@ $<

%.ihx:
	$(Z80SDLD) -b DATA=0xf800 -i $@ $(NGZ80LIBDIR)/nullsound.lib $^

$(MROM1): | $(ROM)
	$(Z80SDOBJCOPY) -I ihex -O binary $< $@ --pad-to $(MROMSIZE)

# PMDNEO nullsound-free PoC, Option A:
# keep the normal nullsound build path intact and add a reversible standalone
# Z80 driver path that writes the active romset M1 directly from standalone_test.
# ADR-0016 step W-3 補正 (= 2026-05-12 4th session):
# V-1 で build top を PMDNEO.s に切替えたが、 PMDNEO.s + IRQ.inc + PMD_Z80.inc
# は nullsound integration 想定の設計途中 (= state_timer_tick_reached が
# nullsound 未定義 + polling loop と nullsound API が不整合)。 一方
# standalone_test.s は nullsound-free PoC として TIMER-B IRQ / NMI command
# dispatch / per-tick driver loop が実際に成立、 W-1 前後の baseline wav も
# standalone_test.s 経路で出ていた。 build top を standalone_test.s に戻し、
# PMDNEO.s 系は将来 nullsound integration sprint 用として保留。
# ADR-0014 §C 「standalone_test.s 凍結」 解釈を見直し (= 凍結ではなく
# nullsound-free driver 本線、 ADPCM-B / J part 実装はここで進める)。
STANDALONE_Z80_SRC?=../../../src/driver/standalone_test.s
STANDALONE_Z80_REL?=$(BUILDDIR)/standalone_test.rel
STANDALONE_Z80_IHX?=$(BUILDDIR)/standalone_test.ihx
STANDALONE_Z80_PREPROCESSED?=$(BUILDDIR)/standalone_test.preprocessed.s

# ADR-0006 §4: chip target (= driver standalone_test.s:32 の .equ を build 時 override)
# ADR-0016 step 3c-2: PMDNEO_USE_PMDDOTNET flag (= pmdneo_load_m の入力 label 切替)
# sdasz80 が -D option 未対応のため sed pre-process で解決。 各 flag を ON にする
# とき `, 0` → `, 1` 置換、 default (= 全 flag OFF) は cp で pass-through。
# (= 空 sed expression は BSD sed が file 名を expr と誤認するため、 cp / sed を切替える)
PMDNEO_CHIP?=ym2610
PMDNEO_USE_PMDDOTNET?=0
TEST_MODE_AXIS_G_INT?=0
TEST_MODE_MUTE_FIXTURE?=0
TEST_MODE_FADE_FIXTURE?=0
TEST_MODE_V2_ENTRY_FIXTURE?=0
TEST_MODE_V2_SONG_FIXTURE?=0
TEST_MODE_AXIS_G_V2_PPC?=0
TEST_MODE_AXIS_G_AUDITION_REVISE?=0
PMDNEO_SED_EXPRS=
ifeq ($(PMDNEO_CHIP),ym2610b)
PMDNEO_SED_EXPRS+=-e 's/PMDNEO_TARGET_CHIP_YM2610B, 0/PMDNEO_TARGET_CHIP_YM2610B, 1/'
endif
ifeq ($(PMDNEO_USE_PMDDOTNET),1)
PMDNEO_SED_EXPRS+=-e 's/PMDNEO_USE_PMDDOTNET, 0/PMDNEO_USE_PMDDOTNET, 1/'
endif
# ADR-0048 §決定 8 案 C ε integration test mode (= audition build 専用、 production は必ず =0)
ifeq ($(TEST_MODE_AXIS_G_INT),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_AXIS_G_INT, 0/TEST_MODE_AXIS_G_INT, 1/'
endif
# ADR-0049 軸 B sprint 5 δ: mute semantics verify 専用 driver-embedded fixture toggle
# (= verify-mute-semantics.sh が PMDNEO_MUTE_FIXTURE=1 で fixture build、 production は必ず =0)
ifeq ($(TEST_MODE_MUTE_FIXTURE),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_MUTE_FIXTURE, 0/TEST_MODE_MUTE_FIXTURE, 1/'
endif
# ADR-0050 軸 B sprint 6 β: fade-out semantics verify 専用 driver-embedded fixture toggle
# (= PMDNEO_FADE_FIXTURE=1 で fixture build、 production は必ず =0)
ifeq ($(TEST_MODE_FADE_FIXTURE),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_FADE_FIXTURE, 0/TEST_MODE_FADE_FIXTURE, 1/'
endif
# ADR-0052 軸 B sprint 1 β: cmd 0x07 v2 entry verify 専用 driver-embedded fixture toggle
# (= PMDNEO_V2_ENTRY_FIXTURE=1 で fixture build、 production は必ず =0)
ifeq ($(TEST_MODE_V2_ENTRY_FIXTURE),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_V2_ENTRY_FIXTURE, 0/TEST_MODE_V2_ENTRY_FIXTURE, 1/'
endif
# ADR-0058 γ 軸 B production-ready roadmap ② γ: v2 song parse + per-part dispatch
# wiring fixture toggle (= PMDNEO_V2_SONG_FIXTURE=1 で fixture build、 production は必ず =0)
ifeq ($(TEST_MODE_V2_SONG_FIXTURE),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_V2_SONG_FIXTURE,     0/TEST_MODE_V2_SONG_FIXTURE,     1/'
endif
# ADR-0048 ζ-β 案 W: 軸 G dynamic supply v2 PPC 経路 fixture toggle (= PMDNEO_AXIS_G_V2_PPC=1 で
# ζ-β fixture build = v2 wrapper bit7 save/restore + lower 7 bit = note byte 由来 PPC entry index、
# production は必ず =0、 ADR-0059 roadmap ③ fixture build (= =0 default) との完全分離)
ifeq ($(TEST_MODE_AXIS_G_V2_PPC),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_AXIS_G_V2_PPC,       0/TEST_MODE_AXIS_G_V2_PPC,       1/'
endif
# ADR-0048 ζ-δ-2 audition fixture revise: audition revise fixture build toggle
# (= PMDNEO_AXIS_G_AUDITION_REVISE=1 で audition revise fixture build = fm_voice_data_audition swap +
# length 0x06/0x30/0x14 fixture swap、 ζ-δ-1 audition reject judgment 受領下、 production は必ず =0)
ifeq ($(TEST_MODE_AXIS_G_AUDITION_REVISE),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_AXIS_G_AUDITION_REVISE, 0/TEST_MODE_AXIS_G_AUDITION_REVISE, 1/'
endif
ifeq ($(strip $(PMDNEO_SED_EXPRS)),)
PMDNEO_PREPROCESS_CMD=cp $< $@
else
PMDNEO_PREPROCESS_CMD=sed $(PMDNEO_SED_EXPRS) $< > $@
endif

$(STANDALONE_Z80_PREPROCESSED): $(STANDALONE_Z80_SRC) | $(BUILDDIR)
	$(PMDNEO_PREPROCESS_CMD)

$(STANDALONE_Z80_REL): $(STANDALONE_Z80_PREPROCESSED) | $(BUILDDIR)
	$(Z80SDAS) $(Z80FLAGS) -g -l -p -u -I$(BUILDDIR) -o $@ $<

# ADR-0016 step W-3 補正: V-1 で nullsound.lib link 追加したが、 standalone_test.s
# は nullsound-free PoC のため衝突 (= nullsound module が cmd_jmptable 参照、
# standalone_test.s に未定義)。 build top を standalone_test.s に戻すと共に
# nullsound.lib link を撤去 (= V-1 前の状態に補正)。
$(STANDALONE_Z80_IHX): $(STANDALONE_Z80_REL)
	$(Z80SDLD) $(Z80LDFLAGS) -b DATA=0xf800 -i $@ $^

standalone_z80: $(STANDALONE_Z80_IHX) | $(ROM)
	$(Z80SDOBJCOPY) -I ihex -O binary $< $(MROM1) --pad-to $(MROMSIZE)

poc: $(PROM1) $(PROM2) standalone_z80

.PHONY: standalone_z80 poc


# -----------------------------------
# Build rules for fixed tiles ROM

$(BUILDDIR)/%.fix: %.gif
	$(TILETOOL) --fix -c $< -o $@

$(SROM1): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(SROMSIZE) $@


# -----------------------------------
# Build rules for sprite tiles ROM

$(BUILDDIR)/%.pal: %.gif
	$(PALTOOL) $< -o $@

$(BUILDDIR)/%.c1 $(BUILDDIR)/%.c2: %.gif
	$(TILETOOL) --sprite -c $< -o $(@:%.c2=%.c1) $(@:%.c1=%.c2)

$(CROM1): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROMSIZE) $@
$(CROM2): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROMSIZE) $@
$(CROM3): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROMSIZE) $@
$(CROM4): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROMSIZE) $@
$(CROM5): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROM5SIZE) $@
$(CROM6): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROM6SIZE) $@
$(CROM7): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROM7SIZE) $@
$(CROM8): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(CROM8SIZE) $@


# -----------------------------------
# Build rules for ADPCM samples ROM

ifdef VROMTEMPLATE
VROMS?=$(shell echo $(VROM1) $(VROM2) $(VROM3) $(VROM4) | wc -w)
$(VROM1) $(VROM2) $(VROM3) $(VROM4): | $(ROM)
	$(VROMTOOL) --roms -s $(VROMSIZE) $^ -o $(VROMTEMPLATE) -n $(VROMS)
else
$(VROM1): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(VROMSIZE) $@
$(VROM2): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(VROMSIZE) $@
$(VROM3): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(VROMSIZE) $@
$(VROM4): | $(ROM)
	echo $^ | xargs -r cat > $@ && $(TRUNCATE) -s $(VROMSIZE) $@
endif

# -----------------------------------
# Build rules for setting up a BIOS ROM for the generated game ROM
# note: by default, use nullbios to avoid any external dependency
BIOSROM?=$(NGSHAREDIR)/neogeo.zip
bios: $(ROM)/$(notdir $(BIOSROM))
$(ROM)/$(notdir $(BIOSROM)): | $(ROM)
	cp $(BIOSROM) $@

.PHONY: bios


# -----------------------------------
# Build rules for housekeeping

clean:
	find . \( -name '*~' -or -name '*.o' -or -name '*.rel' -or -name '*.elf' -or -name '*.ihx' \) -delete

distclean:
	rm -rf build
	$(MAKE) clean
	find setup -mindepth 1 -maxdepth 1 -type d -print | xargs -I{} -r -n1 $(MAKE) -C {} distclean


.PHONY: clean distclean





# nullsound

define asm_label
$(shell echo $(1) | sed -e 's/\.[^.]*//' -e 's/[^a-zA-Z0-9_]/_/g' -e 's/^\([0-9]\)/_\1/g' | tr A-Z a-z)
endef



# --- OS-specific targets ---

# macOS doesn't ship truncate
ifeq ($(shell uname -s), Darwin)
TRUNCATE=$(PYTHON) -c 'import sys;open(sys.argv[3],"a").truncate(int(sys.argv[2]))'
else
TRUNCATE=truncate
endif

# ASSETS=../assets

# for macOS, may interfere with System Integrity Protection
define export_path
$(eval
ifeq ($(shell uname -s), Darwin)
$(1): export DYLD_LIBRARY_PATH=$(NGLIBDIR):$(DYLD_LIBRARY_PATH)
else
$(1): export LD_LIBRARY_PATH=$(NGLIBDIR):$(LD_LIBRARY_PATH)
endif
)
endef

