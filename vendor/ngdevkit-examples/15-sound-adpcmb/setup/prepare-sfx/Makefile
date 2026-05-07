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


TARGETS=beat dance

all: $(TARGETS:%=../../assets/%.wav)

include ../../config.mk

# Note: the original sound FX for this demo are mp3-encoded and need to get
# cropped to a specific time window for being used in the demo, hence these
# prepare steps.
# Remember that this is just specific to this demo, you do not need to run
# any prepare steps for your own project, you can just push ready-to-use .wav
# assets in your ./assets directory
#

# trim and convert input sounds to expected format
../../assets/beat.wav: sfx/hip-hop-beat-n2-49252.mp3
	$(SOX) -V1 $< -c 1 $@ reverse trim 0 2.290 reverse pad 0 0.41 speed 0.996555118

../../assets/dance.wav: sfx/insect-dance-loop-93865.mp3
	$(SOX) -V1 $< -c 1 $@ reverse trim 0 3.37 reverse speed 0.999802215


clean distclean:
	rm -f $(TARGETS:%=../../assets/%.wav)
