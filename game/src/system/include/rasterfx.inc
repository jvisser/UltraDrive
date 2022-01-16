;------------------------------------------------------------------------------------------
; Raster effect constants typedefs
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_RASTER_FX_INC))
__SYSTEM_RASTER_FX_INC Equ 1

    Include './system/include/memory.inc'

;-------------------------------------------------
; Raster effect structs
; ----------------
    DEFINE_STRUCT RasterEffectConfiguration
        STRUCT_MEMBER.l effectAddress                               ; Address of the RasterEffect
        STRUCT_MEMBER.l effectDataAddress                           ; Address of the data passed to raster effect routines
    DEFINE_STRUCT_END

    DEFINE_STRUCT RasterEffect
        STRUCT_MEMBER.l setupFrame                                  ; Prepare the next frame, last thing called before starting the next frame. Setup the VDP etc.
        STRUCT_MEMBER.l prepareNextFrame                            ; Preprocessing for next frame, can be called during active display. Should not access the VDP directly and should not affect the hblank handler for the current frame.
        STRUCT_MEMBER.l resetFrame                                  ; Last resort. Called just before setupFrame if prepareNextFrame was not called (frameskip case). Always called in vertical blank period, so safe to do VDP operations. Can not use the DMA Queue.
        STRUCT_MEMBER.l init                                        ; Init state and return hblank handler address
        STRUCT_MEMBER.l destroy                                     ; Restore system state
    DEFINE_STRUCT_END

    DEFINE_STRUCT RasterEffectHBlankJump
        STRUCT_MEMBER.w instrJmp                                    ; 68k jmp instruction
        STRUCT_MEMBER.l instrJmpAddress                             ; 32 bit target address
        STRUCT_MEMBER.l instrJmpParam                               ; Parameter space
    DEFINE_STRUCT_END


;-------------------------------------------------
; Patch address for 68k vector table
; ----------------
HBlankInterruptHandler Equ rasterEffectJump

    EndIf

