;------------------------------------------------------------------------------------------
; Main entry point
;------------------------------------------------------------------------------------------

_SCROLL_IF Macro up, down, var
            btst    #\down, d2
            bne     .noDown\@
            addq    #8, \var
            bra     .done\@
        .noDown\@:

            btst    #\up, d2
            bne     .done\@
            subq    #8, \var

        .done\@:
    Endm


CreateSprites:
SPRITE_COUNT Equ 8
        move.w  d3, d0
        jsr     VDPSpriteAlloc

        move.w  #128, d1

        subq    #1, d3
    .initSpriteLoop:
        move.w  d4, vdpSpriteVerticalPosition(a0)
        move.w  d4, vdpSpriteHorizontalPosition(a0)
        move.b  #VDP_SPRITE_SIZE_V2 | VDP_SPRITE_SIZE_H2, vdpSpriteSize(a0)
        move.w  #1408, vdpSpriteAttr3(a0)
        addi.w  #16, d4
        addq.w  #VDPSprite_Size, a0
        dbra    d3, .initSpriteLoop
        rts


;-------------------------------------------------
; Main program entry point
; ----------------
Main:
        jsr     EngineInit

        DEBUG_MSG 'Engine initialized'

        jsr     MapInit
        lea     MapHeaderForest_map1, a0
        jsr     MapLoad

        DEBUG_MSG 'Map loaded'

        move.w  0, d0
        move.w  0, d1
        movea.l loadedMap, a0
        movea.w #0, a1
        movea.w #0, a2
        jsr     ViewportInit

        DEBUG_MSG 'Viewport initialized'

        move.w  #4, d3
        move.w  #128, d4
        bsr     CreateSprites
        move.w  #5, d3
        move.w  #128 + 114, d4
        bsr     CreateSprites
        ;jsr     VDPSpriteClear
        ;jsr     VDPSpriteCommit

        DEBUG_MSG 'Sprites created'

        jsr     VDPEnableDisplay

        DEBUG_MSG 'UltraDrive Started!'

        jsr     OSResetStatistics

        ;ENGINE_TICKER_MASK TICKER_TILESET

    .mainLoop:

        PROFILE_FRAME_TIME $000e

        move.w  ioDeviceState1, d2
        moveq   #0, d0
        moveq   #0, d1
        _SCROLL_IF MD_PAD_UP,   MD_PAD_DOWN,    d1
        _SCROLL_IF MD_PAD_LEFT, MD_PAD_RIGHT,   d0

        btst    #MD_PAD_A, d2
        bne     .noPadA
        PUSHM   d0-d1
        jsr     TilesetScheduleManualAnimations
        POPM    d0-d1
    .noPadA:

        jsr     ViewportMove
        jsr     ViewportFinalize

        PROFILE_FRAME_TIME_END

        jsr     OSNextFrameReadyWait

        bra     .mainLoop
