;------------------------------------------------------------------------------------------
; Main binary assembly
;------------------------------------------------------------------------------------------

    Include 'asmopts.asm'
    Include 'layout.asm'

    ;-------------------------------------------------
    ; System
    ; ----------------
    Include './system/constants.asm'
    Include './system/m68k.asm'
    Include './system/debug.asm'
    Include './system/profile.asm'
    Include './system/system.asm'
    Include './system/memory.asm'
    Include './system/exception.asm'
    Include './system/z80.asm'
    Include './system/io.asm'
    Include './system/os.asm'
    Include './system/vdpcmd.asm'
    Include './system/vdp.asm'
    Include './system/vdpdma.asm'
    Include './system/vdptaskqueue.asm'
    Include './system/vdpdmaqueue.asm'
    Include './system/vdpsprite.asm'
    Include './system/init.asm'


    ;-------------------------------------------------
    ; Engine
    ; ----------------
    Include './engine/engine.asm'
    Include './engine/scheduler.asm'
    Include './engine/trigtable.asm'
    Include './engine/comper.asm'
    Include './engine/map.asm'
    Include './engine/mapcollision.asm'
    Include './engine/maprender.asm'
    Include './engine/camera.asm'
    Include './engine/viewport.asm'
    Include './engine/backgroundtracker.asm'
    Include './engine/background/background.asm'
    Include './engine/background/streamingbackground.asm'
    Include './engine/background/tilingbackground.asm'
    Include './engine/tileset.asm'


    ;-------------------------------------------------
    ; Game
    ; ----------------
    ; Assets
    Include 'ultradrive/assets/tilesets.asm'
    Include 'ultradrive/assets/maps.asm'

    ; Code
    Include 'ultradrive/metadata.asm'
    Include 'ultradrive/main.asm'


    ;-------------------------------------------------
    ; ROM header
    ; ----------------
    ; Produce ROM header once all symbols have been resolved
    Include './system/m68kvector.asm'
    Include './system/segaheader.asm'

RomImageEnd

    SECTION_ALLOCATION_REPORT

    MEMORY_ALLOCATION_REPORT

    End
