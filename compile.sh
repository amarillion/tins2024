#!/bin/bash

# Enable DMD version
source ~/dlang/dmd-2.094.2/activate

# -L/SUBSYSTEM:WINDOWS:4.0 prevents console window

# Release mode
dmd src/*.d dtwist/src/helix/*.d dtwist/src/helix/util/*.d allegro5/*.d dtwist/src/helix/allegro/*.d -Isrc -L/SUBSYSTEM:WINDOWS:4.0

# Debug mode
# -debug: enable debug conditional code
# -gf: include debugging symbols
# TODO - doesnt produce symbols that gdb understands (See: https://stackoverflow.com/questions/22064817/error-while-trying-to-debug-d-program)
# dmd -debug -gf -m32 src/*.d src/helix/*.d src/helix/util/*.d src/allegro5/*.d src/helix/allegro/*.d -Isrc -L/SUBSYSTEM:WINDOWS:4.0
