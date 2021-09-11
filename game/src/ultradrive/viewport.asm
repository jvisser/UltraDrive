;------------------------------------------------------------------------------------------
; Custom viewport configurations and support functions
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport controllers
; ----------------

;-------------------------------------------------
; Static background scrolls at 1/4 the rate of the foreground
; ----------------
tilingBackgroundViewportConfiguration:
    DEFINE_TILING_BACKGROUND_VIEWPORT_CONFIG QuarterSpeed


;-------------------------------------------------
; Static rotating background
; ----------------
rotatingBackgroundViewportConfiguration:
    DEFINE_ROTATING_BACKGROUND_VIEWPORT_CONFIG rotateScrollConfiguration

    DEFINE_VAR SHORT
        VAR.w                           currentRotationAngle
        VAR.RotateScrollPosition        rotationPosition
    DEFINE_VAR_END

    rotateScrollConfiguration:
        dc.l    rotationPosition
        dc.l    horizontalViewportAngleTable
        dc.l    verticalViewportAngleTable

    horizontalViewportAngleTable:
        DEFINE_ROTATE_SCROLL_CENTER_HORIZONTAL_ANGLE_TABLE

    verticalViewportAngleTable:
        DEFINE_ROTATE_SCROLL_CENTER_VERTICAL_ANGLE_TABLE

    ;-------------------------------------------------
    ; Setup default values for rotationPosition
    ; ----------------
    ViewportInitAngle:
            moveq   #0, d0
            move.w  d0, (rotationPosition + RotateScrollPosition_angle)
            move.w  d0, (rotationPosition + RotateScrollPosition_horizontalOffset)
            move.w  d0, (rotationPosition + RotateScrollPosition_verticalOffset)
            rts

    ;-------------------------------------------------
    ; Next viewport angle
    ; ----------------
    ViewportUpdateAngle:
            move.w  currentRotationAngle, d0
            addq    #1, d0
            move.w  d0, currentRotationAngle

            andi.w  #$ff, d0
            add     d0, d0
            lea     Sin.w, a0
            move.w  (a0, d0), d0
            asr.w   #3, d0
            addi.w  #32, d0
            move.w  d0, rotationPosition + RotateScrollPosition_angle
            rts
