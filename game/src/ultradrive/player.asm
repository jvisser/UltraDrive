;------------------------------------------------------------------------------------------
; Player state machine
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Player constants
; ----------------
PLAYER_EXTENTS_X        Equ     7
PLAYER_EXTENTS_Y        Equ     15
PLAYER_EXTENTS_WALL_X   Equ     7
PLAYER_EXTENTS_WALL_Y   Equ     7


;-------------------------------------------------
; Player structure
; ----------------
    DEFINE_STRUCT Player, Entity
        STRUCT_MEMBER.l stateHandler
        STRUCT_MEMBER.l stateChangeFrameNumber
        STRUCT_MEMBER.l xSpeed
        STRUCT_MEMBER.l ySpeed
        STRUCT_MEMBER.l groundSpeed
        STRUCT_MEMBER.w angle
    DEFINE_STRUCT_END


;-------------------------------------------------
; Initialize player
; ----------------
; Input:
; - a0: player
; - d0: x position
; - d1: y position
PlayerInit:
        ; Convert position to 16.16 fixed point
        move.w  d0, Entity_x(a0)
        move.w  d1, Entity_y(a0)

        ; TODO: Check ground sensors to find floor if any: walk, else air
        move.l  #PlayerStateWalk, Player_stateHandler(a0)
        rts


;-------------------------------------------------
; Update the player based on its current state
; ----------------
; Input:
; - a0: player
PlayerUpdate:
        movea.l Player_stateHandler(a0), a1
        jmp (a1)


;-------------------------------------------------
; TODO: Implement
; ----------------
PlayerStateJump:
PlayerStateDoubleJump:
PlayerStateAir:
PlayerStateWalk:
PlayerStateRun:
PlayerStateCrouch:
PlayerStateSlide:
PlayerStateWallRun:
PlayerStateWallSlide:
PlayerStateWallJump:
PlayerStateLedgeHang:
PlayerStateLedgeClimb:


;-------------------------------------------------
; Test collision detection code
; ----------------
PlayerStateTestCollision:
_MOVE_IF Macro up, down, var, disp, speed
                moveq   #0, \disp
                btst    #\down, d6
                bne.s   .noDown\@
                move.w  \speed, \disp
                bra.s   .done\@
            .noDown\@:

                btst    #\up, d6
                bne.s   .done\@
                move.w  \speed, \disp
                neg.w   \disp

            .done\@:
                add.w    \disp, \var
        Endm

        IO_GET_DEVICE_STATE IO_PORT_1, d6

        MAP_GET a0
        movea.l MapHeader_foregroundAddress(a0), a0
        move.w  (player + Entity_x), d0
        move.w  (player + Entity_y), d1

        ; If button C is pressed move at max speed
        btst    #MD_PAD_C, d6
        beq     .moveFast
        moveq   #1, d4
        bra.s   .moveSpeedDone
    .moveFast:
        moveq   #8, d4
    .moveSpeedDone:

        _MOVE_IF MD_PAD_LEFT, MD_PAD_RIGHT, d0, d2, d4
        _MOVE_IF MD_PAD_UP,   MD_PAD_DOWN,  d1, d3, d4

        ; If button B is pressed skip collision detection
        btst    #MD_PAD_B, d6
        beq     .collisionDone

        ; Right wall collision detection
        tst.w   d2
        bmi.s .skipRight
            PUSHW   d2
            PUSHW   d3
            add.w   #PLAYER_EXTENTS_WALL_X, d0
            sub.w   #PLAYER_EXTENTS_WALL_Y, d1
            jsr     MapCollisionFindRightWall
            add.w   #PLAYER_EXTENTS_WALL_Y * 2, d1
            jsr     MapCollisionFindRightWall
            sub.w   #PLAYER_EXTENTS_WALL_Y, d1
            jsr     MapCollisionFindRightWall
            sub.w   #PLAYER_EXTENTS_WALL_X,  d0
            POPW    d3
            POPW    d2
            bra.s   .wallDone
    .skipRight:

        ; Left wall collision detection
        beq .skipLeft
            PUSHW   d2
            PUSHW   d3
            sub.w   #PLAYER_EXTENTS_WALL_X, d0
            sub.w   #PLAYER_EXTENTS_WALL_Y, d1
            jsr     MapCollisionFindLeftWall
            add.w   #PLAYER_EXTENTS_WALL_Y * 2, d1
            jsr     MapCollisionFindLeftWall
            sub.w   #PLAYER_EXTENTS_WALL_Y, d1
            jsr     MapCollisionFindLeftWall
            add.w   #PLAYER_EXTENTS_WALL_X,  d0
            POPW    d3
            POPW    d2
    .skipLeft:

    .wallDone:

        ; Floor collision detection
        tst.w   d3
        bmi.s   .skipFloor
        PUSHW   d3
        sub.w   #PLAYER_EXTENTS_X, d0
        add.w   #PLAYER_EXTENTS_Y, d1
        jsr     MapCollisionFindFloor
        add.w   #PLAYER_EXTENTS_X * 2, d0
        jsr     MapCollisionFindFloor
        sub.w   #PLAYER_EXTENTS_X, d0
        sub.w   #PLAYER_EXTENTS_Y, d1
        POPW    d3
    .skipFloor:

        ; Ceiling collision detection
        sub.w   #PLAYER_EXTENTS_X, d0
        sub.w   #PLAYER_EXTENTS_Y, d1
        jsr     MapCollisionFindCeiling
        add.w   #PLAYER_EXTENTS_X * 2, d0
        jsr     MapCollisionFindCeiling
        sub.w   #PLAYER_EXTENTS_X, d0
        add.w   #PLAYER_EXTENTS_Y, d1

    .collisionDone:

        ; Update player coordinates
        move.w  d0, (player + Entity_x)
        move.w  d1, (player + Entity_y)

        ; Do collision check
        COLLISION_ALLOCATE_ELEMENT          &
            #HurtCollisionElement_Size,     &
            a0, a2, a3

        moveq   #PLAYER_EXTENTS_X, d2
        moveq   #PLAYER_EXTENTS_Y, d3
        sub.w   d2, d0
        sub.w   d3, d1
        add.w   d2, d2
        add.w   d3, d3
        add.w   d0, d2
        add.w   d1, d3
        move.w  #HurtEnemyCollisionTypeMetadata, CollisionElement_metadata(a0)
        move.w  d0, AABBCollisionElement_minX(a0)
        move.w  d1, AABBCollisionElement_minY(a0)
        move.w  d2, AABBCollisionElement_maxX(a0)
        move.w  d3, AABBCollisionElement_maxY(a0)
        move.w  #10, HurtCollisionElement_damage(a0)
        jsr     CollisionCheck

        Purge _MOVE_IF
        rts
