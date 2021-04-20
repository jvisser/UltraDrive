;------------------------------------------------------------------------------------------
; Main binary assembly
;------------------------------------------------------------------------------------------

; TODO: Move macros to separate files due to M68K expanding macros in a single pass :/ (or just switch to a better/modern assembler)

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
    Include './system/z80.asm'
    Include './system/io.asm'
    Include './system/vdpcmd.asm'
    Include './system/vdp.asm'
    Include './system/exception.asm'
    Include './system/os.asm'
    Include './system/vdpdma.asm'
    Include './system/vdptaskqueue.asm'
    Include './system/vdpdmaqueue.asm'
    Include './system/vdpsprite.asm'
    Include './system/init.asm'


    ;-------------------------------------------------
    ; Engine
    ; ----------------
    Include './engine/engine.asm'
    Include './engine/fp16.asm'
    Include './engine/scheduler.asm'
    Include './engine/trigtable.asm'
    Include './engine/comper.asm'
    Include './engine/map.asm'
    Include './engine/camera.asm'
    Include './engine/maprender.asm'
    Include './engine/viewport.asm'
    Include './engine/tileset.asm'
    Include './engine/mapcollision.asm'
    Include './engine/backgroundtracker.asm'
    Include './engine/background/background.asm'
    Include './engine/background/defaultbackground.asm'
    Include './engine/background/staticbackground.asm'
    Include './engine/scrollhandler.asm'
    Include './engine/scroll/scroll.asm'
    Include './engine/scroll/defaultscroll.asm'
    Include './engine/scroll/tilingscroll.asm'
    Include './engine/entity.asm'


    ;-------------------------------------------------
    ; Game
    ; ----------------
    ; Assets
    Include 'ultradrive/assets/tilesets.asm'
    Include 'ultradrive/assets/maps.asm'

    ; Code
    Include 'ultradrive/metadata.asm'
    Include 'ultradrive/player.asm'
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
