#!/bin/bash

set -e

# Render maps to PNG images
java -jar '../../tools/mapconvert/target/MapConvert.jar'    \
        -o './out/map'                                      \
        -f './map/objecttypes.xml'                          \
        -r                                                  \
        -i                                                  \
        './map/maps/playfield'                              \
