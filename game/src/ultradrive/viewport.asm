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
    DEFINE_ROTATING_BACKGROUND_VIEWPORT_CONFIG rotationConfiguration

    DEFINE_VAR FAST
        VAR.w                           currentRotationAngle
        VAR.RotateScrollConfiguration   rotationConfiguration
    DEFINE_VAR_END

    INIT_STRUCT rotationConfiguration
        INIT_STRUCT_MEMBER.rsccHorizontalOffset                 0
        INIT_STRUCT_MEMBER.rsccVerticalOffset                   0
        INIT_STRUCT_MEMBER.rsccAngle                            0
        INIT_STRUCT_MEMBER.rsccHorizontalScrollTableAddress     horizontalViewportAngleTable
        INIT_STRUCT_MEMBER.rsccVerticalScrollTableAddress       verticalViewportAngleTable
    INIT_STRUCT_END

    Even

    horizontalViewportAngleTable:
        DEFINE_ROTATE_SCROLL_CENTER_HORIZONTAL_ANGLE_TABLE

    verticalViewportAngleTable:
        DEFINE_ROTATE_SCROLL_CENTER_VERTICAL_ANGLE_TABLE

    ;-------------------------------------------------
    ; Setup default values for rotationConfiguration
    ; ----------------
ViewportInitAngle Equ rotationConfigurationInit

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
            move.b  d0, rotationConfiguration + rsccAngle
            rts
