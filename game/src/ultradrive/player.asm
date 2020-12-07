;------------------------------------------------------------------------------------------
; Player state machine
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Player structure
; ----------------
    DEFINE_STRUCT Player, EXTENDS, Entity
        STRUCT_MEMBER.l playerStateChangeFrameNumber
        STRUCT_MEMBER.l playerStateHandler
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
        INT_TO_FP16 d0
        INT_TO_FP16 d1
        move.l  d0, entityX(a0)
        move.l  d1, entityY(a0)

        ; TODO: determine initial state (grounded/air/crouch) based on sensors at the specified position
        move.l  #PlayerStateEthereal, playerStateHandler(a0)
        rts


;-------------------------------------------------
; Update the player based on its current state
; ----------------
; Input:
; - a0: player
PlayerUpdate:
        movea.l playerStateHandler(a0), a1
        jmp (a1)


;-------------------------------------------------
; Test state. Player had no interaction.
; ----------------
PlayerStateEthereal:
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

        IO_GET_DEVICE_STATE IO_PORT_1, d2

        MAP_GET a0
        movea.l mapForegroundAddress(a0), a0
        move.w  (player + entityX), d0
        move.w  (player + entityY), d1

        _MOVE_IF MD_PAD_LEFT, MD_PAD_RIGHT, d0, 1
        _MOVE_IF MD_PAD_UP,   MD_PAD_DOWN,  d1, 1

        ; Floor collision detection
        sub.w   #7, d0
        add.w   #15, d1
        jsr MapCollisionFindFloor
        add.w   #14, d0
        jsr MapCollisionFindFloor
        sub.w   #7, d0
        sub.w   #15, d1

        ; Ceiling collision detection
        sub.w   #7, d0
        sub.w   #15, d1
        jsr MapCollisionFindCeiling
        add.w   #14, d0
        jsr MapCollisionFindCeiling
        sub.w   #7, d0
        add.w   #15, d1

        ; Update player coordinates
        move.w  d0, (player + entityX)
        move.w  d1, (player + entityY)

        Purge _MOVE_IF
        rts


;-------------------------------------------------
; TODO: Implement
; ----------------
PlayerStateJump:
PlayerStateAir:
PlayerStateWalk:
PlayerStateCrouch:
PlayerStateSlide:
PlayerStateWallSlide:
PlayerStateWallHang:
        rts
