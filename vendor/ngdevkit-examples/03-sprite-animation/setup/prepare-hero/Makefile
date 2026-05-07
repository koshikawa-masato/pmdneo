# Copyright (c) 2018 Damien Ciabrini
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

# This makefile is called by the main makefile to prepare/preprocess
# the input graphics for this demo into a form suitable for compilation

# TODO bail out if undefined
BUILDDIR?=build

all: ../../assets/all.gif

include ../../config.mk


# the original files for this demo need to get their transparent color fixed
%.gif: gfx/spr_m_traveler_%_anim.gif
	cp $< $@ ; \
	printf "\xff\x00\xff" | dd of=$@ bs=1 seek=13 count=3 conv=notrunc status=none

# we want all the sprites to share the same palette, so for simplicity
# in this demo we merge all the frames into a single file with imagemagick
../../assets/all.gif: idle.gif walk.gif
	$(CONVERT) $^ -coalesce -append +repage xc:'#ff00ff[64x1024!]' -compose dstover -compose dstover -fill '#00ffff' -opaque '#000100' -fill '#00ffff' -opaque '#000000' -fill '#181818' -opaque '#00ffff' -fill '#000000' -opaque '#ff00ff' -composite $@

all.c1 all.c2: all.gif
	$(TILETOOL) --sprite -c $< -o $@ $(@:%.c1=%).c2

sprite.pal: all.gif
	$(PALTOOL) $< -o $@

clean distclean:
	rm -f ../../assets/all.gif *.gif
