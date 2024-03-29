;------------------------------------------------------------------------------------------
; 68000 system exception handlers
;------------------------------------------------------------------------------------------

    Include './lib/common/include/debug.inc'

    Include './system/include/m68k.inc'
    Include './system/include/vdp.inc'

;-------------------------------------------------
; Generic exception handler
; ----------------
Exception:
        DEBUG_MSG 'Unhandled exception!'

        ; Purple screen
        VDP_ADDR_SET WRITE, CRAM, $00
        move.w  #$0e0e, MEM_VDP_DATA

        M68K_HALT
        rte         ; Unreachable
