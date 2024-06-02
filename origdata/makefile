# Set shell to bash instead of sh allow for brace expansion
SHELL=/bin/bash

DEST=../data
SRC=.

.PHONY: default
default: all ;

SPRITES=building locomotive wagon FoleNRaulTrainBoss
SHEET_FILES=$(patsubst %,$(DEST)/%.png,$(SPRITES))

$(SHEET_FILES): $(DEST)/%.png: $(SRC)/%.aseprite
	aseprite --ignore-layer Template -b $< --sheet $@

../data/tileset.png: $(DEST)/%.png: $(SRC)/%.svg
	inkscape --export-png=$@ $<

../data/locomotive-iso.png: ../data/locomotive.png
	./isoConverter.d $< $@
	# Downscale 50% with imagemagick
	convert $@ -resize 50% $@
	
../data/wagon-iso.png: ../data/wagon.png
	./isoConverter.d $< $@
	# Downscale 50% with imagemagick
	convert $@ -resize 50% $@

.PHONY: all
all: $(SHEET_FILES) ../data/tileset.png ../data/locomotive-iso.png ../data/wagon-iso.png