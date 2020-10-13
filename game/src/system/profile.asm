;------------------------------------------------------------------------------------------
; Simple profiling macros using the VDP background color to show cruding percentage of frametime
;------------------------------------------------------------------------------------------

PROFILE Macro color
        VDP_ADDR_SET WRITE, CRAM, $00
        move.w  #\color, MEM_VDP_DATA
    Endm


PROFILE_END Macro
        VDP_ADDR_SET WRITE, CRAM, $00
        move.w  #0, MEM_VDP_DATA
    Endm
