;------------------------------------------------------------------------------------------
; Simple profiling macros using the VDP background color to show cruding percentage of frametime
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Show frame time slice by changing the background color
; ----------------
PROFILE_FRAME_TIME Macro color
        VDP_ADDR_SET WRITE, CRAM, $00
        move.w  #\color, MEM_VDP_DATA
    Endm


;-------------------------------------------------
; Set the background color to black
; ----------------
PROFILE_FRAME_TIME_END Macro
        VDP_ADDR_SET WRITE, CRAM, $00
        move.w  #0, MEM_VDP_DATA
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
