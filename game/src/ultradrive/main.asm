;------------------------------------------------------------------------------------------
; Main entry point.
;------------------------------------------------------------------------------------------

    DEFINE_VAR FAST
        VAR.w   mode
        VAR.w   x
        VAR.w   y
        VAR.l   spriteAddr
    DEFINE_VAR_END


;-------------------------------------------------
; Increase/decrease var with speed based on up/down condition
; ----------------
_MOVE_IF Macro up, down, var, speed
            btst    #\down, d2
            bne     .noDown\@
            addq    #\speed, \var
            bra     .done\@
        .noDown\@:

            btst    #\up, d2
            bne     .done\@
            subq    #\speed, \var

        .done\@:
    Endm


;-------------------------------------------------
; Create single pixel collision sensor test sprite
; ----------------
CreateCollisionSprite:
        move.w  #0, x
        move.w  #0, y

        moveq   #1, d0
        jsr     VDPSpriteAlloc
        move.l  a0, spriteAddr

        movea.l loadedTileset, a1
        move.w  tsVramFreeAreaMin(a1), d0
        lsr.w   #5, d0
        move.w  d0, vdpSpriteAttr3(a0)
        move.w  #128, vdpSpriteX(a0)
        move.w  #128, vdpSpriteY(a0)
        move.b  #VDP_SPRITE_SIZE_V1 | VDP_SPRITE_SIZE_H1, vdpSpriteSize(a0)

        VDP_ADDR_SET WRITE, VRAM, $0020, $2
        move.l  #$50000000, MEM_VDP_DATA
        move.l  #$00000000, MEM_VDP_DATA
        move.l  #$00000000, MEM_VDP_DATA
        move.l  #$00000000, MEM_VDP_DATA
        move.l  #$00000000, MEM_VDP_DATA
        move.l  #$00000000, MEM_VDP_DATA
        move.l  #$00000000, MEM_VDP_DATA
        move.l  #$00000000, MEM_VDP_DATA
        rts


;-------------------------------------------------
; Move single pixel collision detection test sprite representing collision sensor on screen
; ----------------
UpdateCollisionMode:
        IO_GET_DEVICE_STATE IO_PORT_1, d2

        moveq   #0, d3
        moveq   #0, d4
        _MOVE_IF MD_PAD_LEFT, MD_PAD_RIGHT,   d3, 1
        _MOVE_IF MD_PAD_UP,   MD_PAD_DOWN,    d4, 1
        move.w  d3, d5
        or.w    d4, d5
        beq     .noMovement

        move.w  x, d0
        move.w  y, d1
        add.w   d3, d0
        add.w   d4, d1

        add.w   (viewport + viewportForeground + camX), d0
        add.w   (viewport + viewportForeground + camY), d1

        movea.l  loadedMap, a0
        movea.l  mapForegroundAddress(a0), a0

        tst.w   d3
        bmi     .checkLeftWall
        bgt     .checkRightWall
        bra     .checkWallDone
    .checkLeftWall:
        jsr     MapCollisionFindLeftWall
        bra     .checkWallDone
    .checkRightWall:
        jsr     MapCollisionFindRightWall
    .checkWallDone:

        jsr     MapCollisionFindFloor
        tst.w   d2
        bpl     .floorCollisionFound
        jsr     MapCollisionFindCeiling
    .floorCollisionFound:

        sub.w   (viewport + viewportForeground + camX), d0
        sub.w   (viewport + viewportForeground + camY), d1

        move.w  d0, x
        move.w  d1, y

        movea.l  spriteAddr, a1
        add.w   #128, d0
        add.w   #128, d1
        move.w  d0, vdpSpriteX(a1)
        move.w  d1, vdpSpriteY(a1)

        jsr     VDPSpriteCommit
    .noMovement:
        rts


;-------------------------------------------------
; Scroll the screen based on the directional pad
; ----------------
UpdateScrollMode:
        IO_GET_DEVICE_STATE IO_PORT_1, d2

        moveq   #0, d0
        moveq   #0, d1
        _MOVE_IF MD_PAD_UP,   MD_PAD_DOWN,    d1, 8
        _MOVE_IF MD_PAD_LEFT, MD_PAD_RIGHT,   d0, 8

        jsr     ViewportMove
        jsr     ViewportFinalize
        rts


;-------------------------------------------------
; Run manually triggered tileset animations if the A button is pressed
; ----------------
UpdateManualTilesetAnimations:
        IO_GET_DEVICE_STATE IO_PORT_1, d2

        btst    #MD_PAD_A, d2
        bne     .noPadA
        PUSHM   d0-d1
        jsr     TilesetScheduleManualAnimations
        POPM    d0-d1
    .noPadA:
        rts


;-------------------------------------------------
; Main program entry point
; ----------------
Main:
        jsr     EngineInit

        DEBUG_MSG 'Engine initialized'

        jsr     MapRenderInit
        lea     MapHeaderTest_map1, a0
        jsr     MapLoad

        DEBUG_MSG 'Map loaded'

        move.w  0, d0
        move.w  0, d1
        jsr     ViewportInit

        DEBUG_MSG 'Viewport initialized'

        bsr     CreateCollisionSprite

        DEBUG_MSG 'Sprites created'

        jsr     VDPEnableDisplay

        DEBUG_MSG 'UltraDrive Started!'

        jsr     OSResetStatistics

        move.w  #0, mode
    .mainLoop:

            PROFILE_FRAME_TIME $000e

            ;PROFILE_CPU_START

            ; Switch mode based on C button
            btst    #MD_PAD_C, d2
            bne     .noModeSwitch
            not.w   mode
        .noModeSwitch:

            ; Run mode specific update routine (0 = scroll mode, collision test mode otherwise)
            tst.w   mode
            beq     .scrollMode
            bsr     UpdateCollisionMode
            bra     .modeUpdateDone

        .scrollMode:
            bsr     UpdateScrollMode

        .modeUpdateDone:

            bsr     UpdateManualTilesetAnimations

            ;PROFILE_CPU_END

            PROFILE_FRAME_TIME_END

            jsr     OSNextFrameReadyWait

        bra     .mainLoop
