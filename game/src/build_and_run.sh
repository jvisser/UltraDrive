#!/bin/bash

set -e

# Compile assets to source
java -jar '../../tools/mapconvert/target/MapConvert.jar'    \
        -m "$1"                                             \
        -t './engine/assets/template'                       \
        -o './ultradrive/assets'                            \
        -f '../assets/map/objecttypes.xml'                  \
        -a './ultradrive/config/allocation.yaml'            \
        -r

# Compile source
asm68k //p ./assembly.asm,boot.bin

# Run
blastem -m gen boot.bin