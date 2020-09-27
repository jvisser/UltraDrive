;------------------------------------------------------------------------------------------
; Basic operating system control
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Vertical blank interupt handler
; ----------------
VBlankInterrupt:
        movem.l d0-d1/a0-a2, -(sp)

        jsr     VDPDMAFlushQueue
        jsr     IOUpdateDeviceState

        movem.l (sp)+, d0-d1/a0-a2
        rte
