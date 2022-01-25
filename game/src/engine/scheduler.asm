;------------------------------------------------------------------------------------------
; Main engine scheduler. Calls subsystem schedulers if enabled.
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'
    Include './system/include/init.inc'

    Include './engine/include/scheduler.inc'

;-------------------------------------------------
; Scheduler state
; ----------------
    DEFINE_VAR SHORT
        VAR.l       engineSchedulerCallbacks,    SCHEDULER_COUNT
        VAR.b       engineSchedulerFlags                             ; Flag set by subsystem to indicate scheduler is enabled
        VAR.b       engineSchedulerMask                              ; Mask set by program to mask which subsystems can execute
    DEFINE_VAR_END

    EngineSchedulers:
        dc.l        TilesetSchedule
        dc.b        0
        dc.b        SCHEDULER_ALL
    EngineSchedulersEnd:


;-------------------------------------------------
; Initialize the engine state scheduler
; ----------------
 INIT EngineSchedulerInit
        lea     EngineSchedulers, a0
        lea     engineSchedulerCallbacks, a1
        move.w  #EngineSchedulersEnd - EngineSchedulers, d0
        jsr     MemoryCopy

        lea     EngineSchedule, a0
        jmp     OSSetFrameProcessedCallback


;-------------------------------------------------
; Update all engine subsystems
; ----------------
; Uses: d0-d7/a0-a6 (Unknown due to delegation)
EngineSchedule:
        move.w  #SCHEDULER_COUNT - 1, d0
        move.b  engineSchedulerFlags, d1
        and.b   engineSchedulerMask, d1
        lea     engineSchedulerCallbacks, a0

    .updateSubSystemLoop:
        add.b   d1, d1
        bcc.s   .subSystemDisabled

        PUSHW   d0
        PUSHW   d1
        PUSHL   a0
        movea.l (a0), a0
        jsr     (a0)
        POPL    a0
        POPW    d1
        POPW    d0

    .subSystemDisabled:
        addq.l  #SIZE_LONG, a0
        dbra    d0, .updateSubSystemLoop
        rts
