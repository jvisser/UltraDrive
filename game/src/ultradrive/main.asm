;------------------------------------------------------------------------------------------
; Main entry point
;------------------------------------------------------------------------------------------

Palette:
    dc.w $0000, $02c6, $08ce, $0000, $0eee, $0aa8, $0a42, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
Back:
    dc.w $0e00, $00e0, $000e, $0ee0, $00ee, $0e0e, $0e06, $060c, $00c4, $008a, $0b20, $0aa0, $0000, $0000, $0000, $0000

PaletteDMATransfer:
    VDP_DEFINE_STATIC_DMA_CRAM_TRANSFER Palette, 0, CRAM_SIZE_WORD

;-------------------------------------------------
; Main program entry point
; ----------------
Main:
        DEBUG_MSG 'UltraDrive Started!'

        VDP_DMA_TRANSFER PaletteDMATransfer

        jsr     VDPEnableDisplay

        ; Write to CRAM entry 0
        VDP_SET_REG vdpRegIncr, 0
        move.l #VDP_CMD_AS_CRAM_WRITE, MEM_VDP_CTRL

    .mainLoop:
        jsr     VDPVSyncWait
        jsr     IOUpdateDeviceState

        ; Change color
        moveq   #11, d0
        moveq   #0, d1
        move.w  ioDeviceState1, d2

    .findButton:
        btst.l  d1, d2
        beq     .pressFound
        addq    #1, d1
        dbra    d0, .findButton
        bra     .mainLoop
    .pressFound:
        add.w   d1, d1
        lea     Back, a0
        lea     MEM_VDP_DATA, a1
        move.w (a0, d1), (a1)

        bra     .mainLoop
