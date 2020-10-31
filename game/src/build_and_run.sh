#!/bin/bash

set -e

# Compile assets top source
java -jar '../../tools/mapconvert/target/MapConvert.jar'    \
        -m '../assets/map/maps/playfield'                   \
        -t './engine/assets/template'                       \
        -o './ultradrive/assets'                            \
        -f '../assets/map/objecttypes.xml'                  \
        -a './allocation.yaml'                              \
        -r

# Compile source
asm68k //p ./assembly.asm,boot.bin

# Run
blastem -m gen boot.bin