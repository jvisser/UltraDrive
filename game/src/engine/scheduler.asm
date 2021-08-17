;------------------------------------------------------------------------------------------
; Main engine scheduler. Calls subsystem schedulers if enabled.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Generic scheduler constants
; ----------------
SCHEDULER_COUNT            Equ 1


;-------------------------------------------------
; Subsystem scheduler identifiers
; ----------------
SCHEDULER_TILESET          Equ $80
SCHEDULER_ALL              Equ SCHEDULER_TILESET


;-------------------------------------------------
; Scheduler state
; ----------------
    DEFINE_VAR FAST
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
; Enable the specified scheduler
; NB: Should only be used by engine subsystems. Use the mask macros to temporarily disable subsystems
; ----------------
ENGINE_SCHEDULER_ENABLE Macros schedulerId
    ori.b  #\schedulerId, engineSchedulerFlags


;-------------------------------------------------
; Disable the specified scheduler.
; NB: Should only be used by engine subsystems. Use the mask macros to temporarily disable subsystems
; ----------------
ENGINE_SCHEDULER_DISABLE Macros schedulerId
    andi.b  #~\schedulerId & $ff, engineSchedulerFlags


;-------------------------------------------------
; Mask the specified scheduler (disable it)
; ----------------
ENGINE_SCHEDULER_MASK Macros schedulerId
    andi.b   #~\schedulerId & $ff, engineSchedulerMask


;-------------------------------------------------
; Unmask the specified scheduler
; ----------------
ENGINE_SCHEDULER_UNMASK Macros schedulerId
    ori.b    #\schedulerId, engineSchedulerMask


;-------------------------------------------------
; Initialize the engine state scheduler
; ----------------
EngineSchedulerInit:
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
        bcc     .subSystemDisabled

        PUSHM   d0-d1/a0
        movea.l (a0), a0
        jsr     (a0)
        POPM    d0-d1/a0

    .subSystemDisabled:
        addq.l  #SIZE_LONG, a0
        dbra    d0, .updateSubSystemLoop
        rts
