# Set shell to bash instead of sh allow for brace expansion
SHELL=/bin/bash

DEST=../data
SRC=.

.PHONY: default
default: all ;

SPRITES=building
SHEET_FILES=$(patsubst %,$(DEST)/%.png,$(SPRITES))

$(SHEET_FILES): $(DEST)/%.png: $(SRC)/%.aseprite
	aseprite --ignore-layer Template -b $< --sheet $@

.PHONY: all
all: $(SHEET_FILES)
