# -*- makefile -*-
# TODO tool to generate those fields 
# TODO move the build name outside of this makefile

BUILDDIR?=build
ROM?=$(BUILDDIR)/rom

# ROM name
GAMEROM=samsho

# program ROM
PROMSIZE=1048576
PROM1=$(ROM)/045-p1.p1
# For 2MB PROM, define PROM2 and its targets in your makefile
# PROM2=
# use variable PROM2SIZE to build PROM2 as a banked ROM, i.e
# the concatenation of all the banked ELF files built in your
# project. By default, PROM2 only contains the higher half of
# the 2MB code segment build from your ELF file.
# PROM2SIZE=4194304
PROM2=$(ROM)/045-pg2.sp2

# sprite ROM
CROMSIZE=2097152
CROM1=$(ROM)/045-c1.c1
# use variable CROMxSIZE to customize the size of a particular ROM
# by default, CROMSIZE value is used for every CROM
# CROM2SIZE=1048576
CROM2=$(ROM)/045-c2.c2
CROM3=$(ROM)/045-c3.c3
CROM4=$(ROM)/045-c4.c4
CROM5SIZE=1048576
CROM5=$(ROM)/045-c51.c5
CROM6SIZE=1048576
CROM6=$(ROM)/045-c61.c6

# fixed tile ROM
SROMSIZE=131072
SROM1=$(ROM)/045-s1.s1

# sound driver ROM
MROMSIZE=131072
MROM1=$(ROM)/045-m1.m1

# sound FX ROM
VROMSIZE=2097152
VROM1=$(ROM)/045-v1.v1
VROM2=$(ROM)/045-v2.v2
# use variable VROMTEMPLATE below to build your music and SFX
# assets with vromtool instead of defining dependencies manually
# in makefile. Se build.mk for more details
# VROMTEMPLATE=$(ROM)/202-vX.vX
