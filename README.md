# UltraDrive

Project to learn how and also how not to implement a game engine for the [Sega Mega Drive/Genesis](https://en.wikipedia.org/wiki/Sega_Genesis).
The program consists of a test case for all implemented features.

The following features have been implemented:
- [Tiled](https://www.mapeditor.org/) map support
  - Very large map support for both foreground and background
  - Reusable tilesets
    - 8x8 meta tiles of 2x2 pattern meta tiles
      - Support for specifying priority at the base pattern level
      - Support for overriding pattern priority at the block (2x2 pattern) level 
    - Collision data (height field + angle)
    - Animations
        - Timer scheduled
        - Manually scheduled
        - Camera movement scheduled
  - Foreground and background map coupling
  - Uses a text template engine for Tiled data conversion
      - As a consequence the map conversion tool can be easily plugged into any project (language independent)
      - Meta tiles and static pattern data are compressed in ROM ([comper](https://github.com/flamewing/mdcomp/blob/master/src/asm/Comper.asm) but [slz](https://plutiedev.com/format-slz) also supported)
- Map collision detection routines
  - floor/ceilings
  - walls
- 3 and 6 button controller support on both controller ports
- Independent camera with map streaming support for foreground and background
    - Background behavior can be configured in the map editor (Tiled)
- Support for raster effects
- Support for all horizontal and vertical scroll modes
- 2 working tilesets

## How to run
### Prerequisites
The following tools should be on your PATH
- [BlastEm](https://www.retrodev.com/blastem/) emulator
- asm68k
- java (>=11)
- maven (>=3)
- sh/bash to run the provided scripts

### Build MapConvert
To build the Tiled map conversion tool run the script `./build_tools.sh`

### Run directly from Tiled
- Open the Tiled project workspace file in `./game/assets/map/`
- Press `alt+r` to compile and run currently open/focussed map in BlastEm
  - This runs the script `./game/src/build_and_run.sh <mapfile>`
- Press `alt+d` to compile with debug features enabled and run currently open/focussed map in BlastEm
  - This runs the script `./game/src/build_and_run.sh <mapfile> GENS`

### Run on real hardware
Create a ROM image `ultradrive.bin` by running the following command from the source root: `asm68k.exe /p .\assembly.asm,ultradrive.bin`.
Put `ultradrive.bin` on a flash card like the Mega EverDrive and run from there.

## Debug build
This adds Gens KMod debug support (Debug message and timers) available in supported emulators.

Run asm68k from the command line in the source root:
`asm68k.exe /p /e "DEBUG='GENS'" .\assembly.asm,ultradrive.bin`

This produces a ROM image `ultradrive.bin` which can be loaded in an emulator that supports the kmod debug protocol.

## Controls
- **dpad**: move player sprite
- **button a**: press to initiate manually triggered tileset animations
- **button b**: hold to disable collision detection
- **button c**: hold to move fast
- **button x**: move water level up
- **button y**: move water level down

## Example
![UltraDrive test map running in BlastEm](ultradrive.gif)
