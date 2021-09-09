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

rm -f 'ultradrive-tracelog.json' 'ultradrive.sym.txt'

# Compile source
if [ $# -eq 2 ];
    then
    # Debug
    asm68k //p //e "DEBUG='$2'" ./assembly.asm,ultradrive.bin,ultradrive.sym
else
    # Normal
    asm68k //p ./assembly.asm,ultradrive.bin,ultradrive.sym
fi

# Dump symbols to text file
if command -v 'asm68kdump';
    then
    asm68kdump 'ultradrive.sym' > ultradrive.sym.txt
fi

# Run
blastem -m gen ultradrive.bin

# Generate trace log file
if command -v 'md-profiler';
    then
    if [ -e 't' ];
    then
        md-profiler -s 'ultradrive.sym' -i 't' -o 'ultradrive-tracelog.json'
        rm -f 't'
    fi
fi

rm -f 'ultradrive.sym' 