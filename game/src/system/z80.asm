;------------------------------------------------------------------------------------------
; Z80 sub CPU control
;------------------------------------------------------------------------------------------

    Include './system/include/init.inc'
    Include './system/include/z80.inc'

;-------------------------------------------------
; Start Z80 (Cancel reset and request bus)
; ----------------
 SYS_INIT Z80Init
        Z80_RESET_CANCEL
        Z80_GET_BUS
        rts
