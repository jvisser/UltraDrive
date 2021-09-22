;------------------------------------------------------------------------------------------
; Main entry point.
;------------------------------------------------------------------------------------------

    DEFINE_VAR SHORT
        VAR.l spriteAddr
        VAR.Player player
    DEFINE_VAR_END


;-------------------------------------------------
; Player init and sprite creation
; ----------------
_InitPlayer:
        lea     player, a0
        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1
        addi.l  #320/2, d0
        addi.l  #224/2, d1
        jsr     PlayerInit

        ; Create player placeholder sprite (Until we have sprite engine)
PLAYER_SPRITE_TILE Equ 1000 ; Use Tileset.vramFreeAreaMin
        moveq   #1, d0
        jsr     VDPSpriteAlloc
        move.l  a0, spriteAddr
        move.w  #PLAYER_SPRITE_TILE, VDPSprite_attr(a0)
        move.b  #VDP_SPRITE_SIZE_V4 | VDP_SPRITE_SIZE_H2, VDPSprite_size(a0)

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
        move.w  (player + Entity_x), d0
        move.w  (player + Entity_y), d1
        sub.w   (viewport + Viewport_foreground + Camera_x), d0
        sub.w   (viewport + Viewport_foreground + Camera_y), d1
        add.w   #128 - PLAYER_EXTENTS_X, d0
        add.w   #128 - PLAYER_EXTENTS_Y, d1

        movea.l  spriteAddr, a1
        move.w  d0, VDPSprite_x(a1)
        move.w  d1, VDPSprite_y(a1)
        rts


;-------------------------------------------------
; Run manually triggered tileset animations if the A button is pressed
; ----------------
_UpdateManualTilesetAnimations:
        IO_GET_DEVICE_STATE IO_PORT_1, d2

        btst    #MD_PAD_A, d2
        bne.s   .noPadA
        PUSHW   d0
        PUSHW   d1
        jsr     TilesetScheduleManualAnimations
        POPW    d1
        POPW    d0
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

        jsr     ViewportInitAngle
        moveq   #0, d0
        moveq   #0, d1
        movea.l #NULL, a0
        jsr     ViewportInit
        VIEWPORT_TRACK_ENTITY #player

        DEBUG_MSG 'Viewport initialized'

        jsr     _InitPlayer

        DEBUG_MSG 'Player initialized'

        jsr     VDPEnableDisplay

        ; Only enable water effect for specialized test map
        If def(MapHeaderCastle_map4)
            jsr WaterEffectInit

            DEBUG_MSG 'Water effects enabled'
        EndIf

        ; Allocate 1280 byte buffer for collision elements
        move.w  #1280, d0
        jsr     CollisionInit

        jsr     OSResetStatistics

        DEBUG_MSG 'UltraDrive Started!'

    .mainLoop:
            If ~def(MapHeaderCastle_map4)
                PROFILE_FRAME_TIME $000e
            EndIf

            ;PROFILE_CPU_START

            ; Reset
            moveq   #0, d0
            jsr     VDPSpriteUnlinkAfter
            jsr     CollisionReset

            ; Only update angle for specialized test map
            If def(MapHeaderCastle_map3)
                jsr     ViewportUpdateAngle
            EndIf

            ; Only update water level for specialized test map
            If def(MapHeaderCastle_map4)
                jsr WaterEffectUpdate
            EndIf

            bsr     _UpdatePlayer
            bsr     _UpdateManualTilesetAnimations

            jsr     MapUpdateObjects

            jsr     VDPSpriteCommit

            ;PROFILE_CPU_END

            If ~def(MapHeaderCastle_map4)
                PROFILE_FRAME_TIME_END
            EndIf

            jsr     OSNextFrameReadyWait

        bra     .mainLoop
