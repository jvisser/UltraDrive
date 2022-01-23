#!/bin/bash

set -e

# Parse parameters
while getopts d:t:m: option
do
    case "${option}"
        in
        d)debug=${OPTARG};;
        t)target=${OPTARG};;
        m)map=${OPTARG};;
    esac
done

if [ -z "$map" ]
    then
        echo 'No map filename provided. Exiting'
        exit 1
fi

# Compile assets to source
java -jar '../../tools/mapconvert/target/MapConvert.jar'    \
        -m "$map"                                           \
        -t './engine/assets/template'                       \
        -s './ultradrive/assets/template'                   \
        -o './ultradrive/assets/generated'                  \
        -f '../assets/map/objecttypes.xml'                  \
        -a './ultradrive/config/vram.yaml'                  \
        -r

# Clean output from previous run
rm -f 'ultradrive-tracelog.json' 'ultradrive.sym.txt'

# Compile source
if [ -z "$debug" ]
    then
    # Normal
    asm68k //p ./assembly.asm,ultradrive.bin,ultradrive.sym
else
    # Debug
    asm68k //p //e "DEBUG='$debug'" ./assembly.asm,ultradrive.bin,ultradrive.sym,ultradrive.lst
fi

# Dump symbols to text file
if command -v 'asm68kdump';
    then
    asm68kdump 'ultradrive.sym' > ultradrive.sym.txt
fi

# Run
case $target in
    "everdrive")
        megalink ultradrive.bin
        ;;
    *)
        blastem -m gen ultradrive.bin
        ;;
esac

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
