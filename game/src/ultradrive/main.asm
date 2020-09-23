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

        VDP_STATIC_DMA_TRANSFER PaletteDMATransfer

        VDP_REG_SET_BITS vdpRegMode2, MODE2_DISPLAY_ENABLE

        VDP_ADDR_SET WRITE, CRAM, $00, $00

    .mainLoop:
        jsr     VDPVSyncWait
        jsr     IOUpdateDeviceState

        ; Change color
        moveq   #11, d0     ; Loop counter (12 buttons)
        moveq   #0, d1      ; Current color index
        move.w  ioDeviceState1, d2

    .findButton:
        btst.l  d1, d2
        beq     .pressFound
        addq    #1, d1
        dbra    d0, .findButton
        bra     .mainLoop

    .pressFound:
        lea     Back, a0
        add.w   d1, d1
        move.w (a0, d1), (MEM_VDP_DATA)

        bra     .mainLoop
