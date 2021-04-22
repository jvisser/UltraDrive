;------------------------------------------------------------------------------------------
; Default background tracker implementation. Scrolls at a rate of the ratio between the background and foreground maps.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Default background tracker structures
; ----------------
    DEFINE_VAR FAST
        VAR.b dbtLockX                                          ; Lock horizontal movement
        VAR.b dbtLockY                                          ; Lock vertical movement
        VAR.w dbtXScale                                         ; Ratios fractional part (16:16 fixedpoint)
        VAR.w dbtYScale
    DEFINE_VAR_END

    ; struct BackgroundTracker
    defaultBackgroundTracker:
        ; .btInit
        dc.l _DefaultBackgroundTrackerInit
        ; .btSync
        dc.l _DefaultBackgroundTrackerSync


;-------------------------------------------------
; Default background tracker init implementation. Calculates the ratio between the back/foreground maps. And initializes the background camera.
; ----------------
; Input:
; - a0: Background camera to initialize
; - a1: Background map address
; - a2: Foreground camera
; - d0: Background camera plane id
; Uses: d0-d7/a0-a6
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
        move.w  d2, dbtXScale
        move.w  d3, dbtYScale

        ; Update initial camera position
        moveq   #0, d0
        move.b   mapLockHorizontal(a1), dbtLockX
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
        move.b   mapLockVertical(a1), dbtLockY
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
; Uses: d0-d1
_DefaultBackgroundTrackerSync:
_MOVE_CAMERA_COMPONENT Macro result, position, displacement, scale, lock
                moveq   #0, \result
                tst.b   \lock
                bne     .noMovement\@
                move.w  \scale, \result
                muls    \position(a1), \result
                swap    \result
                sub.w   \position(a0), \result
                sub.w   \displacement(a0), \result
            .noMovement\@:
        Endm

        _MOVE_CAMERA_COMPONENT d0, camX, camXDisplacement, dbtXScale, dbtLockX
        _MOVE_CAMERA_COMPONENT d1, camY, camXDisplacement, dbtYScale, dbtLockY

        CAMERA_MOVE d0, d1

        Purge _MOVE_CAMERA_COMPONENT
        rts
