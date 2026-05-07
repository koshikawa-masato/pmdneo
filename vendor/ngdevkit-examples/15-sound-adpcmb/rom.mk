# -*- makefile -*-
# TODO tool to generate those fields 
# TODO move the build name outside of this makefile

BUILDDIR?=build
ROM?=$(BUILDDIR)/rom

# ROM name
# Override default to a ROM cartridge layout that supports
# both ADPCM-A and ADPCM-B in the same VROM chip, as all
# the recent carts can demultiplex accesses from the YM2610
# to a common ROM chip.
GAMEROM=lastbld2

# program ROM
PROMSIZE=1048576
PROM1=$(ROM)/243-pg1.p1
PROM2=$(ROM)/243-pg2.sp2
# use variable PROM2SIZE to build PROM2 as a banked ROM, i.e
# the concatenation of all the banked ELF files built in your
# project. By default, PROM2 only contains the higher half of
# the 2MB code segment build from your ELF file.
PROM2SIZE=4194304

# sprite ROM
CROMSIZE=8388608
CROM1=$(ROM)/243-c1.c1
CROM2=$(ROM)/243-c2.c2
# use variable CROMxSIZE to customize the size of a particular ROM
# by default, CROMSIZE value is used for every CROM
# CROM2SIZE=1048576
CROM3=$(ROM)/243-c3.c3
CROM4=$(ROM)/243-c4.c4
CROM5SIZE=8388608
CROM5=$(ROM)/243-c5.c5
CROM6SIZE=8388608
CROM6=$(ROM)/243-c6.c6

# fixed tile ROM
SROMSIZE=131072
SROM1=$(ROM)/243-s1.s1

# sound driver ROM
MROMSIZE=131072
MROM1=$(ROM)/243-m1.m1

# sound FX ROM
VROMSIZE=4194304
VROM1=$(ROM)/243-v1.v1
VROM2=$(ROM)/243-v2.v2
VROM3=$(ROM)/243-v3.v3
VROM4=$(ROM)/243-v4.v4
# define variable VROMTEMPLATE to use vromtool to build VROMs
VROMTEMPLATE=$(ROM)/243-vX.vX
