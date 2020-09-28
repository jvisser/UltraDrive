;------------------------------------------------------------------------------------------
; Main binary assembly
;------------------------------------------------------------------------------------------

    Include 'asmopts.asm'
    Include 'layout.asm'

    ;-------------------------------------------------
    ; System
    ; ----------------
    Include './system/m68k.asm'
    Include './system/debug.asm'
    Include './system/system.asm'
    Include './system/memory.asm'
    Include './system/exception.asm'
    Include './system/z80.asm'
    Include './system/io.asm'
    Include './system/vdpcmd.asm'
    Include './system/vdp.asm'
    Include './system/vdpdma.asm'
    Include './system/vdpdmaqueue.asm'
    Include './system/init.asm'


    ;-------------------------------------------------
    ; Engine
    ; ----------------
    Include './engine/tileset.asm'
    Include './engine/map.asm'


    ;-------------------------------------------------
    ; Game
    ; ----------------
    ; Assets
    Include 'ultradrive/assets/out/tilesets.asm'

    ; Code
    Include 'ultradrive/metadata.asm'
    Include 'ultradrive/main.asm'


    ; Produce ROM header once all symbols have been resolved
    Include './system/m68kvector.asm'
    Include './system/segaheader.asm'

RomImageEnd

    SECTION_ALLOCATION_REPORT

    MEMORY_ALLOCATION_REPORT

    End
