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
            cmpi.b  #$01, (MEM_Z80_BUS_REQUEST)
            bne.s   .z80WaitLoop\@
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
            ; Z80 RESET is active low
            move.b #$00, (MEM_Z80_RESET)
    Endm


;-------------------------------------------------
; Cancel Z80 reset
; ----------------
Z80_RESET Macro
            ; Z80 RESET is active low
            move.b #$01, (MEM_Z80_RESET)
    Endm
