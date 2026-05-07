# -*- makefile -*-
# TODO tool to generate those fields 
# TODO move the build name outside of this makefile

BUILDDIR?=build
ROM?=$(BUILDDIR)/rom

# ROM name
# Use a ROM that is known to have two P-ROMs
# and the second P-ROM being used for bankswitching.
GAMEROM=pulstar

# program ROM
PROMSIZE=1048576
PROM1=$(ROM)/089-p1.p1
PROM2=$(ROM)/089-p2.sp2
# use variable PROM2SIZE to build PROM2 as a banked ROM, i.e
# the concatenation of all the banked ELF files built in your
# project. By default, PROM2 only contains the higher half of
# the 2MB code segment build from your ELF file.
PROM2SIZE=2097152

# sprite ROM
CROMSIZE=4194304
CROM1=$(ROM)/089-c1.c1
CROM2=$(ROM)/089-c2.c2
# use variable CROMxSIZE to customize the size of a particular ROM
# by default, CROMSIZE value is used for every CROM
# CROM2SIZE=1048576
CROM3=$(ROM)/089-c3.c3
CROM4=$(ROM)/089-c4.c4
CROM5SIZE=4194304
CROM5=$(ROM)/089-c5.c5
CROM6SIZE=4194304
CROM6=$(ROM)/089-c6.c6
CROM7SIZE=2097152
CROM7=$(ROM)/089-c7.c7
CROM8SIZE=2097152
CROM8=$(ROM)/089-c8.c8

# fixed tile ROM
SROMSIZE=131072
SROM1=$(ROM)/089-s1.s1

# sound driver ROM
MROMSIZE=131072
MROM1=$(ROM)/089-m1.m1

# sound FX ROM
VROMSIZE=4194304
VROM1=$(ROM)/089-v1.v1
VROM2=$(ROM)/089-v2.v2
# use variable VROMTEMPLATE below to build your music and SFX
# assets with vromtool instead of defining dependencies manually
# in makefile. Se build.mk for more details
# VROMTEMPLATE=$(ROM)/089-vX.vX
