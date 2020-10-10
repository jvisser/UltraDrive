;------------------------------------------------------------------------------------------
; Main entry point
;------------------------------------------------------------------------------------------

_SCROLL_IF Macro up, down, var
            btst    #\down, d2
            bne     .noDown\@
            addq    #2, \var
            bra     .done\@
        .noDown\@:

            btst    #\up, d2
            bne     .done\@
            subq    #2, \var

        .done\@:
    Endm

;-------------------------------------------------
; Main program entry point
; ----------------
Main:
        DEBUG_MSG 'UltraDrive Started!'

        move.w  #PLANE_SIZE_H64_V64, d0
        jsr VDPSetPlaneSize

        lea MapVilage_map1, a0
        jsr MapLoad

        moveq   #0, d0
        moveq   #0, d1
        move.l  #PLANE_A, d2
        jsr MapRender

        VDP_ADDR_SET WRITE, CRAM, $00, $00
        move.w #$b20, (MEM_VDP_DATA)

        jsr VDPEnableDisplay

        moveq   #0, d4
        moveq   #0, d5
    .mainLoop:
        jsr     VDPVSyncWait
        jsr     VDPDMAQueueFlush
        jsr     IOUpdateDeviceState

        move.w  ioDeviceState1, d2

        _SCROLL_IF 0, 1, d4
        _SCROLL_IF 3, 2, d5

        VDP_ADDR_SET WRITE, VSRAM, $00, $00
        move.w d4, (MEM_VDP_DATA)

        VDP_ADDR_SET WRITE, VRAM, $b800, $02
        move.w d5, (MEM_VDP_DATA)

        bra     .mainLoop
