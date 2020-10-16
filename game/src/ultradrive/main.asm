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
        jsr     MapInit
        lea     MapVilage_map1, a0
        jsr     MapLoad

        DEBUG_MSG 'Map loaded'

        move    #128-9, d0
        ;move    #0, d0
        move    #1024-340, d0
        ;move    #0, d1
        ;move    #8*10+4, d1
        movea   #0, a0
        jsr     CameraInit

        move    #0, d0
        move    #256, d1
        jsr     CameraMove

        DEBUG_MSG 'Camera initialized'

        jsr VDPEnableDisplay

        DEBUG_MSG 'UltraDrive Started!'

    .mainLoop:

        PROFILE_FRAME_TIME $000e

        move.w  ioDeviceState1, d2
        moveq   #0, d0
        moveq   #0, d1
        _SCROLL_IF MD_PAD_UP,   MD_PAD_DOWN,    d1
        _SCROLL_IF MD_PAD_LEFT, MD_PAD_RIGHT,   d0

        jsr     CameraMove
        jsr     CameraFinalize

        PROFILE_FRAME_TIME_END

        jsr     VDPVSyncWait
        jsr     VDPDMAQueueFlush
        jsr     IOUpdateDeviceState
        jsr     CameraPrepareNextFrame

        bra     .mainLoop
