#!/bin/bash

set -e

if [ $# -eq 0 ]; 
    then
        echo 'No map filename provided. Exiting'
        exit 1
fi

# Compile assets to source
java -jar '../../tools/mapconvert/target/MapConvert.jar'    \
        -m "$1"                                             \
        -t './engine/assets/template'                       \
        -o './ultradrive/assets'                            \
        -f '../assets/map/objecttypes.xml'                  \
        -a './ultradrive/config/allocation.yaml'            \
        -r

# Compile source
if [ $# -eq 2 ]; 
    then
    # Debug
    asm68k //p //e "DEBUG='$2'" ./assembly.asm,boot.bin
else
    # Normal
    asm68k //p ./assembly.asm,boot.bin
fi

# Run
blastem -m gen boot.bin