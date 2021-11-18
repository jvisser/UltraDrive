;------------------------------------------------------------------------------------------
; Mega Drive system details
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; System related 68000 memory addresses
; ----------------
MEM_REG_VERSION         Equ $00a10001   ; Relates mostly to the JP1-4 configuration on the motherboard
MEM_TMSS                Equ $00a14000   ; TradeMark Security System


;-------------------------------------------------
; System related constants
; ----------------

; Version register details
REG_VERSION_TMSS_MASK   Equ $0f    ; No specifics known about version field than non 0 values having the TMSS module
REG_VERSION_VIDEO_MODE  Equ $40    ; 1 = NTSC (7.67 Mhz clock), 0 = PAL (7.60 Mhz clock)
REG_VERSION_MODE        Equ $80    ; 1 = Domestic model, 0 = Overseas model


;-------------------------------------------------
; Unlock system by TradeMark Security System (TMSS) protocol
; ----------------
; Uses: d0
TMSSUnlock:
        move.b  MEM_REG_VERSION, d0
        andi.b  #REG_VERSION_TMSS_MASK, d0
        beq.s   .noTMSS
        move.l  #'SEGA', MEM_TMSS

    .noTMSS:
        rts
