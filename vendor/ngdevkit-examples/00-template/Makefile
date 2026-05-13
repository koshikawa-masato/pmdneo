# Copyright (c) 2015-2025 Damien Ciabrini
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



all: cart bios

# These are various variables that you might want to customize
# based on your liking or your requirements.
# location of generated and compiled content
BUILDDIR=build
# all directories that contain source to be compiled
SRCDIRS=assets
# default build flags, can be overriden per target
CFLAGS=-I$(BUILDDIR) -std=c99 -fomit-frame-pointer -O2 -g
PMDNEO_FIXTURE?=0
PMDNEO_SONG?=0
CFLAGS+=-DPMDNEO_FIXTURE=$(PMDNEO_FIXTURE) -DPMDNEO_SONG=$(PMDNEO_SONG) $(PMDNEO_EXTRA_CFLAGS)
LDFLAGS=
Z80FLAGS=
Z80LDFLAGS=

# This is an autoconf-generated configuration for your environment
# (ngdevkit path, OS-specific configs...)
include config.mk

# This defines the layout of your game cartridge
# You can customize it to match your requirements
include rom.mk

# SubE-1 (lastbld2 template): VROMTEMPLATE は rom.mk で定義済 (= 243-vX.vX)
# All the generic build targets (68k, Z80, assets, run)
include build.mk

# PMDNEO standalone PoC also consumes the ADPCM-A generated symbols/VROM.
$(STANDALONE_Z80_REL): $(BUILDDIR)/assets/samples.inc
poc: $(BUILDDIR)/assets/samples.inc $(VROM1) poc-cart-zip

# Some default targets for running your project via emulators
include emu.mk



# program ROM: your main program
# Add your dependencies below to compile your sources into an ELF binary
# that is used as the content of the program ROM (referenced by symbol PROM1)
# 
# Note: build rules (%.c -> %.o -> %.elf) are defined in Makefile.build
ELF=$(BUILDDIR)/rom.elf
$(ELF):	$(BUILDDIR)/main.o
$(PROM1): $(ELF)



# fixed tiles ROM: all your 8x8 pixel tiles for the fixed layer
# Add your dependencies below to convert images to fixed tile binary data
# and pack it into the fixed tile ROM (referenced by symbol SROM1)
# 
# By default, this makefile creates a tileset ROM with small and tall
# latin characters for printing ASCII string, and tiles that are
# displayed during the attract mode.
# Note: build rules (%.gif -> %.fix) are defined in Makefile.build
$(SROM1): $(BUILDDIR)/assets/base-srom-text-shadow.fix



# sprite ROM: all your 16x16 pixel tiles for sprites
# Add your dependencies below to convert images to fixed sprite binary data
# and pack it into two separate sprite ROMs that hold odd and even bits of
# color information (referenced by symbols CROM1 and CROM2)
#
# By default, this makefile creates CROMs with tiles for displaying a ngdevkit
# logo during the attract mode.
# Note: build rules (%.gif -> %.c<1,2>) are defined in Makefile.build
$(CROM1): $(BUILDDIR)/assets/base-crom-logo.c1
$(CROM2): $(BUILDDIR)/assets/base-crom-logo.c2



# sound driver ROM: PMDNEO Phase 2 SubA driver (silent stub)
# PMDNEO の Z80 driver source は src/driver/ に配置、 build 時に scripts/build-poc.sh
# で 00-template/ に symlink される (= .gitignore で除外)
# Note: build rules (%.s -> %.o -> %.ihx) are defined in Makefile.build
SOUND_DRIVER=$(BUILDDIR)/pmdneo_driver.ihx
$(MROM1): $(SOUND_DRIVER)

$(SOUND_DRIVER): $(BUILDDIR)/PMDNEO.rel

# PMDNEO.s が include する file 群への依存 (build.mk の %.rel: %.s rule で
# sdasz80 が compile、 cwd 相対の include は scripts/build-poc.sh で symlink される)
$(BUILDDIR)/PMDNEO.rel: PMDNEO.s WORKAREA.inc REGMAP.inc IRQ.inc KR_STUB.inc PMD_Z80.inc ADPCMB_DRV.inc ADPCMA_DRV.inc $(BUILDDIR)/assets/samples.inc



# sound FX ROM: all your ADPCM samples
# Add your dependencies below to convert your samples into suitable
# ADPCM data and pack it into the sound ROM (referenced by symbol VROM1)
#
# Music and SFX assets can be managed with <> rather to generate
# the dependencies automatically.
# By default, no sample is used, so the VROM is empty
# Note: build rules (%.wav-> %.adpcm<a,b>) are defined in Makefile.build
$(VROM1): assets/samples-map-adpcma.yaml assets/samples-map-adpcmb.yaml



# One-time asset preprocessing
# Various assets may have to be processed before they can be used to
# build your ROM, for example:
#   . the ngdevkit assets must be converted to sprite and text tiles
#   . converting your SFX assets from .mp3 into .wav so they can be
#     processed by ngdevkit tools
# To handle these pre-processing requirements, `make` automatically
# runs into all subdirectories under ./setup/, so you get a chance
# to preprocess what you need before anything is built.
#
# Other assets must be processed only once to generate source files
# that gets built into your ROM, for example:
#   . converting your musics from .fur to z80 code and data files
#   . generating make dependencies to pack gfx or sound assets into
#     the right ROM bank based on your input assets
# Those actions can be achieved by creating custom make targets
# that get invoked automatically when added to the variable below.
CUSTOM_GENERATE_TARGETS=generate-sfx

generate-sfx: $(BUILDDIR)/assets/samples.inc

$(BUILDDIR)/assets/samples.inc: assets/samples-map-adpcma.yaml assets/samples-map-adpcmb.yaml
	$(VROMTOOL) --asm -s $(VROMSIZE) $^ -o $(VROM1) -m $@

poc-cart-zip: $(PROM1) $(PROM2) standalone_z80 $(SROM1) $(CROM1) $(CROM2) $(CROM3) $(CROM4) $(CROM5) $(CROM6) $(VROM1)
	cd $(ROM) && for i in `ls -1 | grep -v -e \.bin -e \.zip`; do ln -nsf $$i $${i%.*}.bin; done; \
	rm -f $(notdir $(CART)); \
	printf "===\nhttps://github.com/dciabrin/ngdevkit\n===" | zip -qz $(notdir $(CART)) `ls -1 | grep -e '^243-'`

.PHONY: poc-cart-zip



# a default `clean` target removes .o .elf and .ihx from the builddir
# a default `distclean` target removes the build directory entirely
# you can customize clean up by adding dependencies to those targets
