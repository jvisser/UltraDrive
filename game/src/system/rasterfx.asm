;------------------------------------------------------------------------------------------
; Raster effect support. Provides lifecycle management through struct RasterEffect.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Raster effect structs
; ----------------
    DEFINE_STRUCT RasterEffectConfiguration
        STRUCT_MEMBER.l rfxcEffectAddress                           ; Address of the RasterEffect
        STRUCT_MEMBER.l rfxcEffectDataAddress                       ; Address of the data passed to raster effect routines
    DEFINE_STRUCT_END

    DEFINE_STRUCT RasterEffect
        STRUCT_MEMBER.l rfxSetupFrame                               ; Prepare the next frame, last thing called before starting the next frame. Setup the VDP etc.
        STRUCT_MEMBER.l rfxPrepareNextFrame                         ; Preprocessing for next frame, can be called during active display. Should not access the VDP directly and should not affect the hblank handler for the current frame.
        STRUCT_MEMBER.l rfxResetFrame                               ; Last resort. Called just before rfxSetupFrame if rfxPrepareNextFrame was not called (frameskip case). Always called in vertical blank period, so safe to do VDP operations. Can not use the DMA Queue.
        STRUCT_MEMBER.l rfxInit                                     ; Init state and return hblank handler address
        STRUCT_MEMBER.l rfxDestroy                                  ; Restore system state
    DEFINE_STRUCT_END

    DEFINE_STRUCT RasterEffectHBlankJump
        STRUCT_MEMBER.w rfxbjInstrJmp                               ; 68k jmp instruction
        STRUCT_MEMBER.l rfxbjInstrJmpAddress                        ; 32 bit target address
        STRUCT_MEMBER.l rfxbjInstrJmpParam                          ; Parameter space
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Variables
    ; ----------------
    DEFINE_VAR FAST
        VAR.l                       rasterEffect
        VAR.l                       rasterEffectData
        VAR.w                       rasterEffectPrepared
        VAR.w                       rasterEffectMemoryPool, 16      ; 16 words of raster effects shared memory (only one can be active at a time)
        VAR.RasterEffectHBlankJump  rasterEffectJump
    DEFINE_VAR_END


;-------------------------------------------------
; Patch address for 68k vector table
; ----------------
HBlankInterruptHandler Equ rasterEffectJump


;-------------------------------------------------
; Called by SysInit
; ----------------
RasterEffectsInit:
        clr.l   rasterEffect

        ; Write: rte
        move.w  #$4e73, (rasterEffectJump + rfxbjInstrJmp)
        rts


;-------------------------------------------------
; Install a raster effect
; ----------------
; Input:
; - a0: RasterEffectConfiguration address
RasterEffectInstall:
        OS_LOCK

        ; Store raster effect addresses
        movea.l rfxcEffectAddress(a0), a1
        movea.l rfxcEffectDataAddress(a0), a0
        move.l  a1, rasterEffect
        move.l  a0, rasterEffectData
        clr.w   rasterEffectPrepared

        PUSHL a0

            ; rfxInit(rfxcEffectDataAddress)
            movea.l rfxInit(a1), a2
            jsr     (a2)

            ; Register returned hblank handler (a0)
            VDP_TASK_QUEUE_ADD #_RasterEffectInstallHBlank, a0

        POPL a0

        ; Run rfxPrepareNextFrame
        bsr _RasterEffectPrepareNextFrame

        OS_UNLOCK
        rts


;-------------------------------------------------
; Uninstall currently installer raster effect
; ----------------
RasterEffectUninstall:
        tst.l   rasterEffect
        beq     .noRasterEffect

            VDP_TASK_QUEUE_ADD #_RasterEffectUninstallHBlank

    .noRasterEffect:
        rts


;-------------------------------------------------
; Generate raster effect callback call
; ----------------
_RASTEREFFECT_CALL Macro func
        tst.l   rasterEffect
        beq     .noRasterEffect\@

            movea.l rasterEffect, a1
            movea.l \func(a1), a1
            movea.l rasterEffectData, a0

            jsr     (a1)

    .noRasterEffect\@:
    Endm


;-------------------------------------------------
; Install horizontal blank interrupt handler
; ----------------
; Input:
; - a0: hblank interrupt handler address
_RasterEffectInstallHBlank:
        ; Write: "jmp __SkipFirstHBlank_HACK.l"
        move.w  #$4ef9, (rasterEffectJump + rfxbjInstrJmp)
        move.l  #__SkipFirstHBlank_HACK, (rasterEffectJump + rfxbjInstrJmpAddress)
        move.l  a0, (rasterEffectJump + rfxbjInstrJmpParam)

        ; Enable horizontal interrupts but set interval at invalid value (to be set by rastereffect itself through rfxSetupFrame)
        VDP_REG_SET         vdpRegHRate, $ff
        VDP_REG_SET_BITS    vdpRegMode1, MODE1_HBLANK_ENABLE
        rts

        ; For some reason enabling the hblank interrupt from within the vblank interrupt handler will immediately trigger a hblank after the vblank interrupt handler returns even when VDP register 10 (h interrupt interval) is set to $FF (at system start).
        ; When enabling hblank interrupts from active display everything works as expected. Could not find any documentation on this behavior.
        ; TODO: Find a better way to deal with this
        __SkipFirstHBlank_HACK:
            ; Patch jump address to the actual raster effect hblank handler
            move.l  (rasterEffectJump + rfxbjInstrJmpParam), (rasterEffectJump + rfxbjInstrJmpAddress)
            rte


;-------------------------------------------------
; Uninstall horizontal blank interrupt handler
; ----------------
_RasterEffectUninstallHBlank
        ; Disable horizontal interrupts
        VDP_REG_RESET_BITS  vdpRegMode1, MODE1_HBLANK_ENABLE
        VDP_REG_SET         vdpRegHRate, $ff

        ; Write: rte
        move.w  #$4e73, (rasterEffectJump + rfxbjInstrJmp)

        ; Call rfxDestroy
        _RASTEREFFECT_CALL rfxDestroy

        ; Clear reference
        clr.l   rasterEffect
        rts


;-------------------------------------------------
; Internal function called by OSNextFrameReadyWait
; ----------------
_RasterEffectPrepareNextFrame:
        _RASTEREFFECT_CALL rfxPrepareNextFrame
        move.w  #1, rasterEffectPrepared
        rts


;-------------------------------------------------
; Internal function called by OSPrepareNextFrame
; ----------------
_RasterEffectSetupFrame:
        tst.w   rasterEffectPrepared
        bne     .framePrepared

        ; If rfxPrepareNextFrame was not called before rfxSetupFrame call rfxResetFrame first
        _RASTEREFFECT_CALL rfxResetFrame

    .framePrepared:
        _RASTEREFFECT_CALL rfxSetupFrame

        clr.w   rasterEffectPrepared
        rts


Purge _RASTEREFFECT_CALL
