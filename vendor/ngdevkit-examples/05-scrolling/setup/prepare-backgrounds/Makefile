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

# This makefile is called by the main makefile to prepare/preprocess
# the input graphics for this demo into a form suitable for compilation


TARGETS=back forest front

all: $(TARGETS:%=../../assets/%.gif)

include ../../config.mk

# Note: the original art for this demo need to get cropped to a specific size
# for being used in the demo, hence these prepare steps.
# Remember you do not need to run any prepare steps for your project, just
# push the ready-to-use .gif assets in your ./assets directory
#

../../assets/back.gif: gfx/country-platform-back.png
	$(CONVERT) $^ -crop 384x144+0+16 +repage $@

../../assets/forest.gif: gfx/country-platform-forest.png
	$(CONVERT) $^ $^ $^ +append -crop 480x144+0+80 +repage -background black -flatten $@

../../assets/front.gif: gfx/country-platform-tiles-example.png
	$(CONVERT) $^ $^ +append -crop 384x144+0+80 +repage -background black -flatten $@


clean distclean:
	rm -f $(TARGETS:%=../../assets/%.gif)
