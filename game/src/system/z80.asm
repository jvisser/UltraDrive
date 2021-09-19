;------------------------------------------------------------------------------------------
; Z80 sub CPU control
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Z80 68000 interface
; ----------------
MEM_Z80_BUS_REQUEST Equ $a11100
MEM_Z80_RESET       Equ $a11200


;-------------------------------------------------
; Requests the Z80 bus
; ----------------
Z80_REQUEST_BUS Macro
            move.b  #$01, (MEM_Z80_BUS_REQUEST)
    Endm


;-------------------------------------------------
; Requests the Z80 bus and wait until available
; ----------------
Z80_GET_BUS Macro
            move.b  #$01, (MEM_Z80_BUS_REQUEST)
            
        .z80WaitLoop\@:
            btst    #0, (MEM_Z80_BUS_REQUEST)
            bne     .z80WaitLoop\@
    Endm


;-------------------------------------------------
; Requests the Z80 bus and wait until available
; ----------------
Z80_RELEASE Macro
            move.b  #$00, (MEM_Z80_BUS_REQUEST)
    Endm


;-------------------------------------------------
; Assert Z80 reset
; ----------------
Z80_RESET Macro
            move.b #$00, (MEM_Z80_RESET)
    Endm


;-------------------------------------------------
; Cancel Z80 reset
; ----------------
Z80_RESET_CANCEL Macro
            move.b #$01, (MEM_Z80_RESET)
    Endm


;-------------------------------------------------
; Start Z80 (Cancel reset and request bus)
; ----------------
Z80Init:
        Z80_RESET_CANCEL
        Z80_GET_BUS
        rts
