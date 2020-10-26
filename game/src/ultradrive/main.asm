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
        jsr     EngineInit

        DEBUG_MSG 'Engine initialized'

        jsr     MapInit
        lea     MapHeaderVilage_map1, a0
        jsr     MapLoad

        DEBUG_MSG 'Map loaded'

        move.w  #512, d0
        move.w  #128, d1
        movea.l loadedMap, a0
		movea.w	#0, a1
        movea.w #0, a2
        movea.w #0, a3
        jsr     ViewportInit

        DEBUG_MSG 'Viewport initialized'

        jsr VDPEnableDisplay

        DEBUG_MSG 'UltraDrive Started!'

    .mainLoop:

        PROFILE_FRAME_TIME $000e

        move.w  ioDeviceState1, d2
        moveq   #0, d0
        moveq   #0, d1
        _SCROLL_IF MD_PAD_UP,   MD_PAD_DOWN,    d1
        _SCROLL_IF MD_PAD_LEFT, MD_PAD_RIGHT,   d0

        jsr     ViewportMove
        jsr     ViewportFinalize

        PROFILE_FRAME_TIME_END

        jsr     VDPVSyncWait
        jsr     VDPDMAQueueFlush
        jsr     IOUpdateDeviceState
        jsr     ViewportPrepareNextFrame

        jsr     VDPVSyncEndWait             ; To get more accurate frametime graph

        bra     .mainLoop
