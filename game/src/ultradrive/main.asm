;------------------------------------------------------------------------------------------
; Main entry point
;------------------------------------------------------------------------------------------

Back:
    dc.w $0e00, $00e0, $000e, $0ee0, $00ee, $0e0e, $0e06, $060c, $00c4, $008a, $0b20, $0aa0, $0000, $0000, $0000, $0000

;-------------------------------------------------
; Main program entry point
; ----------------
Main:
        DEBUG_MSG 'UltraDrive Started!'

        lea TilesetVilage, a0
        jsr TilesetLoad

    .mainLoop:
        jsr     VDPVSyncWait
        jsr     VDPDMAQueueFlush
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

        M68K_DISABLE_INT

        VDP_ADDR_SET WRITE, CRAM, $00, $00
        move.w (a0, d1), (MEM_VDP_DATA)

        M68K_ENABLE_INT

        bra     .mainLoop
