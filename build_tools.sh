#!/bin/bash

set -e

# Build tools
mvn package -f ./tools/mapconvert/pom.xml
