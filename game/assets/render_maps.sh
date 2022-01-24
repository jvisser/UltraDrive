#!/bin/bash

set -e

# Render maps to PNG images
java -jar '../../tools/mapconvert/target/MapConvert.jar'    \
        -m './map/maps/playfield'                           \
        -o './out/map'                                      \
        -f './map/objecttypes.xml'                          \
        -i                                                  \
        -r
