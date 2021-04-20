;------------------------------------------------------------------------------------------
; Default background tracker implementation. Scrolls at a rate of the ratio between the background and foreground maps.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Default background tracker structures
; ----------------
    DEFINE_STRUCT DefaultBackgroundTracker, EXTENDS, BackgroundTracker
        STRUCT_MEMBER.b sbtLockX                                            ; Lock horizontal movement
        STRUCT_MEMBER.b sbtLockY                                            ; Lock vertical movement
        STRUCT_MEMBER.w sbtXScale                                           ; Ratios fractional part (16:16 fixedpoint)
        STRUCT_MEMBER.w sbtYScale
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.DefaultBackgroundTracker  defaultBackgroundTracker
    DEFINE_VAR_END

    INIT_STRUCT defaultBackgroundTracker
        INIT_STRUCT_MEMBER.btInit      _DefaultBackgroundTrackerInit
        INIT_STRUCT_MEMBER.btSync      _DefaultBackgroundTrackerSync
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the background tracker. Called by engine init.
; ----------------
DefaultBackgroundTrackerInit Equ defaultBackgroundTrackerInit


;-------------------------------------------------
; Default background tracker init implementation. Calculates the ratio between the back/foreground maps. And initializes the background camera.
; ----------------
; Input:
; - a0: Background camera to initialize
; - a1: Background map address
; - a2: Foreground camera
; - d0: Background camera plane id
; Uses: d0-d5/a3-a4
_DefaultBackgroundTrackerInit:
        PUSHL   d0                                              ; Push plane id for CameraInit

        moveq   #0, d0
        moveq   #0, d1
        moveq   #0, d2
        moveq   #0, d3

        move.w   (vdpMetrics + vdpScreenWidth), d4
        move.w   (vdpMetrics + vdpScreenHeight), d5

        movea.l camMapAddress(a2), a3
        move.w  mapWidthPixels(a3), d0
        sub.w   d4, d0
        move.w  mapHeightPixels(a3), d1
        sub.w   d5, d1

        move.w  mapWidthPixels(a1), d2
        sub.w   d4, d2
        swap    d2
        move.w  mapHeightPixels(a1), d3
        sub.w   d5, d3
        swap    d3

        ; Calculate maps ratio and displacement steps (store fractional part)
        divu    d0, d2
        divu    d1, d3
        move.w  d2, (defaultBackgroundTracker + sbtXScale)
        move.w  d3, (defaultBackgroundTracker + sbtYScale)

        ; Update initial camera position
        moveq   #0, d0
        move.b   mapLockHorizontal(a1), (defaultBackgroundTracker + sbtLockX)
        bne     .horizontallyLocked
        move.w  camX(a2), d0
        mulu    d2, d0
        swap    d0                                              ; Camera expects non fixed point result
        move.w  (vdpMetrics + vdpScreenWidth), d2               ; If not locked: set camera width to screen width + 1 pattern for scrolling
        addq.w  #8, d2
        bra     .horizontalSetupDone
    .horizontallyLocked:
        move.w  (vdpMetrics + vdpPlaneWidth), d2                ; If locked: set camera width to plane width (= render full plane) to allow for custom scrolling (parallax)
    .horizontalSetupDone:

        moveq   #0, d1
        move.b   mapLockVertical(a1), (defaultBackgroundTracker + sbtLockY)
        bne     .verticallyLocked
        move.w  camY(a2), d1
        mulu    d3, d1
        swap    d1                                              ; Camera expects non fixed point result
        move.w  (vdpMetrics + vdpScreenHeight), d3              ; If not locked: set camera height to screen height + 1 pattern for scrolling
        addq.w  #8, d3
        bra     .verticalSetupDone
    .verticallyLocked:
        move.w  (vdpMetrics + vdpPlaneHeight), d3               ; If locked: set camera width to plane height (= render full plane) to allow for custom scrolling (parallax)
    .verticalSetupDone:

        ; Initialize background camera
        POPL    d4                                              ; d4 = Camera plane id
        jsr     CameraInit
        rts


;-------------------------------------------------
; Default background tracker sync implementation
; ----------------
; Input:
; - a0: Background camera
; - a1: Foreground camera
; Uses: d0-d3/a2
_DefaultBackgroundTrackerSync:
_MOVE_CAMERA_COMPONENT Macro result, position, displacement, scale, lock
                moveq   #0, \result
                tst.b   \lock(a2)
                bne     .noMovement\@
                move.w  \scale(a2), \result
                muls    \position(a1), \result
                swap    \result
                sub.w   \position(a0), \result
                sub.w   \displacement(a0), \result
            .noMovement\@:
        Endm

        lea defaultBackgroundTracker, a2

        _MOVE_CAMERA_COMPONENT d0, camX, camXDisplacement, sbtXScale, sbtLockX
        _MOVE_CAMERA_COMPONENT d1, camY, camXDisplacement, sbtYScale, sbtLockY

        CAMERA_MOVE d0, d1

        Purge _MOVE_CAMERA_COMPONENT
        rts
