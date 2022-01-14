;------------------------------------------------------------------------------------------
; Relative background tracker implementation. Scrolls at a rate of the ratio between the background and foreground maps.
; Provides 3 configurations:
; - relativeHorizontalVerticalBackgroundTrackerConfiguration: Scrolls on both axes
; - relativeHorizontalBackgroundTracker: Scrolls only horizontally
; - relativeVerticalBackgroundTracker: Scrolls only vertically
;------------------------------------------------------------------------------------------

    Include './engine/include/camera.inc'
    Include './engine/include/map.inc'

;-------------------------------------------------
; Relative background tracker structures
; ----------------

    DEFINE_STRUCT RelativeBackgroundTrackerConfiguration
        STRUCT_MEMBER.b lockX
        STRUCT_MEMBER.b lockY
    DEFINE_STRUCT_END

    DEFINE_VAR SHORT
        VAR.w rbtXScale                                                 ; Ratios fractional part (16:16 fixedpoint)
        VAR.w rbtYScale
    DEFINE_VAR_END

    ;-------------------------------------------------
    ; Relative BackgroundTracker definition
    ; ----------------
    ; struct BackgroundTracker
    relativeBackgroundTracker:
        ; .init
        dc.l _RelativeBackgroundTrackerInit
        ; .sync
        dc.l _RelativeBackgroundTrackerSync


    ;-------------------------------------------------
    ; Predefined configurations
    ; ----------------

    ; Tracks both axes
    ; struct RelativeBackgroundTrackerConfiguration
    relativeHorizontalVerticalBackgroundTrackerConfiguration:
        ; .lockX
        dc.b FALSE
        ; .lockY
        dc.b FALSE

    ; Track background only on the horizontal axis. The vertical axis will be locked and have the same size as the background plane height.
    ; struct RelativeBackgroundTrackerConfiguration
    relativeHorizontalBackgroundTrackerConfiguration:
        ; .lockX
        dc.b FALSE
        ; .lockY
        dc.b TRUE

    ; Track background only on the vertical axis. The horizontal axis will be locked and have the same size as the background plane width.
    ; struct RelativeBackgroundTrackerConfiguration
    relativeVerticalBackgroundTrackerConfiguration:
        ; .lockX
        dc.b TRUE
        ; .lockY
        dc.b FALSE


;-------------------------------------------------
; Relative background tracker init implementation. Calculates the ratio between the back/foreground maps. And initializes the background camera.
; ----------------
; Input:
; - a0: Background camera to initialize
; - a1: Background map address
; - a2: Foreground camera
; - a3: RelativeBackgroundTrackerConfiguration
; - d0: Background camera plane id
; Uses: d0-d7/a0-a6
_RelativeBackgroundTrackerInit:
        PUSHL   d0                                                      ; Push plane id for CameraInit

        moveq   #0, d0
        moveq   #0, d1
        moveq   #0, d2
        moveq   #0, d3

        move.w   (vdpMetrics + VDPMetrics_screenWidth), d4
        move.w   (vdpMetrics + VDPMetrics_screenHeight), d5

        movea.l Camera_mapAddress(a2), a4
        move.w  Map_widthPixels(a4), d0
        sub.w   d4, d0
        move.w  Map_heightPixels(a4), d1
        sub.w   d5, d1

        move.w  Map_widthPixels(a1), d2
        sub.w   d4, d2
        swap    d2
        move.w  Map_heightPixels(a1), d3
        sub.w   d5, d3
        swap    d3

        ; Calculate maps ratio and displacement steps (store fractional part)
        divu    d0, d2
        divu    d1, d3
        move.w  d2, rbtXScale
        move.w  d3, rbtYScale

        ; Update initial camera position
        moveq   #0, d0
        tst.b   RelativeBackgroundTrackerConfiguration_lockX(a3)
        bne.s   .horizontallyLocked
        move.w  Camera_x(a2), d0
        mulu    d2, d0
        swap    d0                                                      ; Camera expects non fixed point result
        move.w  (vdpMetrics + VDPMetrics_screenWidth), d2               ; If not locked: set camera width to screen width + 1 pattern for scrolling
        addq.w  #8, d2
        bra.s   .horizontalSetupDone
    .horizontallyLocked:
        move.w  (vdpMetrics + VDPMetrics_planeWidth), d2                ; If locked: set camera width to plane width (= render full plane) to allow for custom scrolling (parallax)
    .horizontalSetupDone:

        moveq   #0, d1
        tst.b   RelativeBackgroundTrackerConfiguration_lockY(a3)
        bne.s   .verticallyLocked
        move.w  Camera_y(a2), d1
        mulu    d3, d1
        swap    d1                                                      ; Camera expects non fixed point result
        move.w  (vdpMetrics + VDPMetrics_screenHeight), d3              ; If not locked: set camera height to screen height + 1 pattern for scrolling
        addq.w  #8, d3
        bra.s   .verticalSetupDone
    .verticallyLocked:
        move.w  (vdpMetrics + VDPMetrics_planeHeight), d3               ; If locked: set camera width to plane height (= render full plane) to allow for custom scrolling (parallax)
    .verticalSetupDone:

        ; Initialize background camera
        POPL    d4                                                      ; d4 = Camera plane id
        jsr     CameraInit
        rts


;-------------------------------------------------
; Relative background tracker sync implementation
; ----------------
; Input:
; - a0: Background camera
; - a1: Foreground camera
; - a2: RelativeBackgroundTrackerConfiguration
; Uses: d0-d1
_RelativeBackgroundTrackerSync:
_MOVE_CAMERA_COMPONENT Macro result, position, displacement, scale, lock
                moveq   #0, \result
                tst.b   \lock(a2)
                bne.s   .noMovement\@
                move.w  \scale, \result
                muls    \position(a1), \result
                swap    \result
                sub.w   \position(a0), \result
                sub.w   \displacement(a0), \result
            .noMovement\@:
        Endm

        _MOVE_CAMERA_COMPONENT d0, Camera_x, Camera_xDisplacement, rbtXScale, RelativeBackgroundTrackerConfiguration_lockX
        _MOVE_CAMERA_COMPONENT d1, Camera_y, Camera_yDisplacement, rbtYScale, RelativeBackgroundTrackerConfiguration_lockY

        CAMERA_MOVE d0, d1

        Purge _MOVE_CAMERA_COMPONENT
        rts
