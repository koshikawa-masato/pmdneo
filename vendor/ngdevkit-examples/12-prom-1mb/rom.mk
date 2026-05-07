# -*- makefile -*-
# TODO tool to generate those fields 
# TODO move the build name outside of this makefile

BUILDDIR?=build
ROM?=$(BUILDDIR)/rom

# ROM name
GAMEROM=ssideki2

# program ROM
PROMSIZE=1048576
PROM1=$(ROM)/061-p1.p1
# For 2MB PROM, define PROM2 and its targets in your makefile
# PROM2=
# use variable PROM2SIZE to build PROM2 as a banked ROM, i.e
# the concatenation of all the banked ELF files built in your
# project. By default, PROM2 only contains the higher half of
# the 2MB code segment build from your ELF file.
# PROM2SIZE=4194304

# sprite ROM
CROMSIZE=2097152
CROM1=$(ROM)/061-c1-16.c1
CROM2=$(ROM)/061-c2-16.c2
CROM3=$(ROM)/061-c3-16.c3
CROM4=$(ROM)/061-c4-16.c4
# use variable CROMxSIZE to customize the size of a particular ROM
# CROM2SIZE=1048576

# fixed tile ROM
SROMSIZE=131072
SROM1=$(ROM)/061-s1.s1

# sound driver ROM
MROMSIZE=131072
MROM1=$(ROM)/061-m1.m1

# sound FX ROM
VROMSIZE=2097152
VROM1=$(ROM)/061-v1.v1
VROM2=$(ROM)/061-v2.v2
# use variable VROMTEMPLATE below to build your music and SFX
# assets with vromtool instead of defining dependencies manually
# in makefile. Se build.mk for more details
# VROMTEMPLATE=$(ROM)/061-vX.vX
