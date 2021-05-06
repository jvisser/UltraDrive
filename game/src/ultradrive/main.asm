;------------------------------------------------------------------------------------------
; Main entry point.
;------------------------------------------------------------------------------------------

    DEFINE_VAR FAST
        VAR.l spriteAddr
        VAR.Player player
    DEFINE_VAR_END


;-------------------------------------------------
; Player init and sprite creation
; ----------------
_InitPlayer:
        lea     player, a0
        move.w  (viewport + viewportForeground + camX), d0
        move.w  (viewport + viewportForeground + camY), d1
        addi.l  #320/2, d0
        addi.l  #224/2, d1
        jsr     PlayerInit

        ; Create player placeholder sprite (Until we have sprite engine)
PLAYER_SPRITE_TILE Equ 1000 ; Use Tileset.tsVramFreeAreaMin
        moveq   #1, d0
        jsr     VDPSpriteAlloc
        move.l  a0, spriteAddr
        move.w  #PLAYER_SPRITE_TILE, vdpSpriteAttr3(a0)
        move.b  #VDP_SPRITE_SIZE_V4 | VDP_SPRITE_SIZE_H2, vdpSpriteSize(a0)

        ; Upload sprite patterns (15*31)
        VDP_ADDR_SET WRITE, VRAM, (PLAYER_SPRITE_TILE * $20), $2
        Rept    4*8-1
            move.l  #$55555555, MEM_VDP_DATA
        Endr
        move.l  #0, MEM_VDP_DATA
        Rept    4*8-1
            move.l  #$55555550, MEM_VDP_DATA
        Endr
        move.l  #0, MEM_VDP_DATA
        rts


;-------------------------------------------------
; Player control and sprite update
; ----------------
_UpdatePlayer:
        lea     player, a0
        jsr     PlayerUpdate
        jsr     ViewportFinalize

        ; Update player placeholder sprite
        move.w  (player + entityX), d0
        move.w  (player + entityY), d1
        sub.w   (viewport + viewportForeground + camX), d0
        sub.w   (viewport + viewportForeground + camY), d1
        add.w   #128 - 7, d0
        add.w   #128 - 15, d1

        movea.l  spriteAddr, a1
        move.w  d0, vdpSpriteX(a1)
        move.w  d1, vdpSpriteY(a1)

        jsr     VDPSpriteCommit
        rts


;-------------------------------------------------
; Run manually triggered tileset animations if the A button is pressed
; ----------------
_UpdateManualTilesetAnimations:
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

        DEBUG_MSG 'Map renderer initialized'

        moveq   #0, d0
        jsr     MapLoadDirectoryIndex

        DEBUG_MSG 'Map at index 0 loaded'

        moveq   #0, d0
        moveq   #0, d1
        jsr     ViewportInitAngle
        jsr     ViewportInit
        VIEWPORT_TRACK_ENTITY #player

        DEBUG_MSG 'Viewport initialized'

        jsr     _InitPlayer

        DEBUG_MSG 'Player initialized'

        jsr     VDPEnableDisplay

        DEBUG_MSG 'UltraDrive Started!'

        jsr     OSResetStatistics

    .mainLoop:

            PROFILE_FRAME_TIME $000e

            PROFILE_CPU_START

            jsr     ViewportUpdateAngle

            bsr     _UpdatePlayer
            bsr     _UpdateManualTilesetAnimations

            PROFILE_CPU_END

            PROFILE_FRAME_TIME_END

            jsr     OSNextFrameReadyWait

        bra     .mainLoop
