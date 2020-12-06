;------------------------------------------------------------------------------------------
; Player state machine
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Player structure
; ----------------
    DEFINE_STRUCT Player, EXTENDS, Entity
        STRUCT_MEMBER.l playerStateChangeFrameNumber
        STRUCT_MEMBER.l playerStateHandler
        STRUCT_MEMBER.l playerState ; TODO: Global/state specific data?
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.Player player
    DEFINE_VAR_END


PlayerInit:
        ; TODO: determine initial state (grounded/air) based on sensors at specified position

        move.w  (viewport + viewportForeground + camX), d0
        move.w  (viewport + viewportForeground + camY), d1
        addi.l  #320/2, d0
        addi.l  #224/2, d1
        ext.l   d0
        swap    d0
        move.l  d0, (player + entityX)
        ext.l   d1
        swap    d1
        move.l  d1, (player + entityY)
        rts


PlayerUpdate:
        bsr     PlayerStateEthereal
        rts


PlayerStateEthereal:
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

; TODO: State transition
; - Setup
; - Animation (timed/delayed but cancelable by interaction)
; TODO: Different states have different:
; - Dimensions
; - Sensors

PlayerStateAir:
    ; If within jump timer and jump button still pressed from initial jump dec y
    ; Else add gravity acceleration to ysp (if ysp < max)) and atmospheric drag to xsp

    ; If not jumping and double jump available and jump button pressed
        ; Initiate another jump

    ; If going up
        ; Check ceiling + wall sensor
    ; Else if going down
        ; Check floor sensors
            ; Switch to PlayerStateGrounded if touch
            ; Else
                ; Check ledge ground sensor, if detects
                    ; Check wall. If detects switch to PlayerStateWallHang
                ; If both wall sensors detect wall
                    ; Reset xsp
                    ; If dpad pressed in direction switch to PlayerStateWallSlide (this resets double jump slot/counter)
        rts


PlayerStateGrounded:
    ; move or jump or switch to ground slide
    ; find floor, but how far below in case of slope?
        rts


PlayerStateGroundSlide:
PlayerStateWallSlide:
PlayerStateWallHang:
PlayerStateWallClimb:
