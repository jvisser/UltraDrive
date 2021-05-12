;------------------------------------------------------------------------------------------
; Water palette swap stuff
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Water effect configuration
; ----------------
    waterRasterEffectConfiguration:
        dc.l    paletteSwapRasterEffect
        dc.l    waterLevel

    ;-------------------------------------------------
    ; Actual water level
    ; ----------------
    DEFINE_VAR FAST
        VAR.w waterLevel
        VAR.w waterLevelBase
        VAR.w waterLevelSineOffset
    DEFINE_VAR_END



;-------------------------------------------------
; Enable water effect
; ----------------
WaterEffectInit:
        move.w  #2 * 128 + 96, waterLevelBase
        move.w  waterLevelBase, waterLevel

        lea waterRasterEffectConfiguration, a0
        jmp RasterEffectInstall


;-------------------------------------------------
; Enable water effect
; ----------------
WaterEffectUpdate:
        IO_GET_DEVICE_STATE IO_PORT_1, d0

        move.w  waterLevelBase, d1

        btst    #MD_PAD_X, d0
        bne     .noWaterLevelUp

            addq.w  #1, d1

        bra     .waterLevelMoveDone
    .noWaterLevelUp:
            btst    #MD_PAD_Y, d0
            bne     .waterLevelMoveDone

            subq.w  #1, d1

    .waterLevelMoveDone:

            move.w  d1, waterLevelBase

            move.w  waterLevelSineOffset, d0
            addq    #1, d0
            move.w  d0, waterLevelSineOffset

            andi.w  #$ff, d0
            add     d0, d0
            lea     Sin.w, a0
            move.w  (a0, d0), d0
            asr.w   #5, d0
            add.w   d0, d1

            move.w  d1, waterLevel
        rts
