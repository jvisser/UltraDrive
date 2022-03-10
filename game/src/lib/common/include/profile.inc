;------------------------------------------------------------------------------------------
; Simple profiling macros using the VDP background color to show cruding percentage of frametime
;------------------------------------------------------------------------------------------

    If (~def(__LIB_COMMON_PROFILE_INC))
__LIB_COMMON_PROFILE_INC Equ 1

    Include './system/include/vdp.inc'

;-------------------------------------------------
; Show frame time slice by changing the background color
; ----------------
PROFILE_FRAME_TIME Macro color
        If (def(debug))
            VDP_ADDR_SET WRITE, CRAM, $00
            move.w  #\color, MEM_VDP_DATA
        EndIf
    Endm


;-------------------------------------------------
; Set the background color to black
; ----------------
PROFILE_FRAME_TIME_END Macro
        If (def(debug))
            VDP_ADDR_SET WRITE, CRAM, $00
            move.w  #0, MEM_VDP_DATA            ; Don't use the clr instruction in this case, will cause a freeze die to the weird read-modify-write bus cycle of clr. The read will freeze as the dataport is in write mode.
        EndIf
    Endm


;-------------------------------------------------
; Start profiling CPU time
; ----------------
PROFILE_CPU_START Macro
    DEBUG_START_TIMER
    Endm


;-------------------------------------------------
; Start profiling CPU time and log cycles
; ----------------
PROFILE_CPU_END Macro
    DEBUG_STOP_TIMER
    Endm

    EndIf
