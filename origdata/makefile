# Set shell to bash instead of sh allow for brace expansion
SHELL=/bin/bash

DEST=../data
SRC=.

.PHONY: default
default: all ;

SPRITES=building
SHEET_FILES=$(patsubst %,$(DEST)/%.png,$(SPRITES))

$(SHEET_FILES): $(DEST)/%.png: ../data/%.aseprite
	aseprite --ignore-layer Template -b $< --sheet $@

../data/tileset.png: $(DEST)/%.png: $(SRC)/%.svg
	inkscape --export-png=$@ $<

.PHONY: all
all: $(SHEET_FILES) ../data/tileset.png