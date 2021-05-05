;------------------------------------------------------------------------------------------
; Custom viewport configurations and support functions
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport controllers
; ----------------
    DEFINE_VAR FAST
        VAR.w                               currentRotationAngleIndex
        VAR.RotateScrollCameraConfiguration rotationConfiguration
    DEFINE_VAR_END


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


;-------------------------------------------------
; Next viewport angle
; ----------------
ViewportUpdateAngle:
        move.w  currentRotationAngleIndex, d0
        addq    #1, d0
        move.w  d0, currentRotationAngleIndex

        andi.w  #$ff, d0
        add     d0, d0
        lea     Sin, a0
        move.w  (a0, d0), d0
        asr.w   #3, d0
        addi.w  #32, d0
        move.b  d0, rotationConfiguration + rsccAngle
        rts
