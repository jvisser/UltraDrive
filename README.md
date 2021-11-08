# UltraDrive

Project to learn how to implement a game engine for the [Sega Mega Drive/Genesis](https://en.wikipedia.org/wiki/Sega_Genesis).

## How to run
### Prerequisites
The following tools should be on your PATH
- [BlastEm](https://www.retrodev.com/blastem/) emulator
- [megalink](https://krikzz.com/pub/support/mega-everdrive/pro-series/usb-tool/) (Mega EverDrive PRO)
- ASM68K
- java (>=11)
- maven (>=3)
- sh/bash to run the provided scripts

### Build MapConvert
To build the Tiled map conversion tool run the script `./build_tools.sh`

### Run directly from Tiled
- Open the Tiled project workspace file in `./game/assets/map/`
- Press `alt+r` to compile and run the currently open/focussed map in BlastEm
- Press `alt+d` to compile with debug features enabled and run currently open/focussed map in BlastEm
- Press `alt+x` to compile and run the currently open/focussed map via the Mega EverDrive Pro on real hardware

### Run on real hardware using any flashcard
Create a ROM image `ultradrive.bin` by running the following command from the source root: `asm68k.exe /p .\assembly.asm,ultradrive.bin`.
Put `ultradrive.bin` on the flash card and run from there.

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
