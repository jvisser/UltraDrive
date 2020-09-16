;------------------------------------------------------------------------------------------
; Main binary assembly
;------------------------------------------------------------------------------------------

    Include 'asmopts.asm'
    Include 'layout.asm'
    Include 'metadata.asm'

    ; System
    Include './system/vector68k.asm'
    Include './system/segaheader.asm'
    Include './system/memory.asm'
    Include './system/debug.asm'
    Include './system/exception.asm'
    Include './system/controller.asm'
    Include './system/vdp.asm'
    Include './system/init.asm'


    ; Engine

    
    ; Game
    Include 'ultradrive/main.asm'

RomImageEnd
    End
