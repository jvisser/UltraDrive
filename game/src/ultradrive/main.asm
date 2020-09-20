;------------------------------------------------------------------------------------------
; Main entry point
;------------------------------------------------------------------------------------------

Palette:
    dc.w $0000, $02c6, $08ce, $0000, $0eee, $0aa8, $0a42, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000

PaletteDMATransfer:
    VDP_DEFINE_STATIC_DMA_CRAM_TRANSFER Palette, 0, CRAM_SIZE_WORD

;-------------------------------------------------
; Main program entry point
; ----------------
Main:
        DEBUG_MSG 'UltraDrive Started!'

        VDP_DMA_TRANSFER PaletteDMATransfer

        jsr     VDPEnableDisplay

    .mainLoop:
        jsr     VDPVSyncWait

        lea     ioDeviceState1, a0
        jsr     IOUpdateDeviceState

        bra.s   .mainLoop
