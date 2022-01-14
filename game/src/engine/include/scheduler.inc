;------------------------------------------------------------------------------------------
; Main engine scheduler...
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_SCHEDULER_INC))
__ENGINE_SCHEDULER_INC Equ 1

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

    EndIf
