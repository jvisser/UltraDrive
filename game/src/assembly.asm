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
    Include './system/memory.asm'
    Include './system/exception.asm'
    Include './system/controller.asm'
    Include './system/vdpcmd.asm'
    Include './system/vdp.asm'
    Include './system/init.asm'


    ;-------------------------------------------------
    ; Engine
    ; ----------------
    ; TODO
    

    ;-------------------------------------------------
    ; Game
    ; ----------------
    Include 'ultradrive/metadata.asm'
    Include 'ultradrive/main.asm'


    ; Produce ROM header once all symbols have been resolved
    Include './system/m68kvector.asm'
    Include './system/segaheader.asm'

RomImageEnd

    SECTION_ALLOCATION_REPORT

    MEMORY_ALLOCATION_REPORT

    End
