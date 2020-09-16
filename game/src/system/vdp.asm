;------------------------------------------------------------------------------------------
; VDP
;------------------------------------------------------------------------------------------

MEM_REG_VERSION equ $00a10000
MEM_TMSS        equ $00a14000   ; TradeMark security system

MEM_VDP_DATA    equ $00c00000
MEM_VDP_CTRL    equ $00c00004


;-------------------------------------------------
; Initialize the VDP for use
; ----------------
; Parameters: None
VDPInit:
        bsr VDPUnlockTMSS

        bsr VDPInitRegisters

        bsr VDPClearVRAM
        bsr VDPClearVSRAM
        bsr VDPClearCRAM

        rts


;-------------------------------------------------
; Unlock VDP by TradeMark Security System protocol
; ----------------
; Parameters: None
VDPUnlockTMSS:

        rts


;-------------------------------------------------
; Write initial VDP register values
; ----------------
; Parameters: None
VDPInitRegisters:

        rts


;-------------------------------------------------
; Clear Main VRAM
; ----------------
; Parameters: None
VDPClearVRAM:
        rts


;-------------------------------------------------
; Clear Vertical Scroll RAM (VSRAM)
; ----------------
; Parameters: None
VDPClearVSRAM:
        rts


;-------------------------------------------------
; Clear Color RAM (CRAM)
; ----------------
; Parameters: None
VDPClearCRAM:
        rts
