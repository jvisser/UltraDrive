;------------------------------------------------------------------------------------------
; Engine initialization
;------------------------------------------------------------------------------------------

    Include './engine/include/engine.inc'

;-------------------------------------------------
; Initialize engine components
; ----------------
EngineInit:
        jsr ViewportEngineInit
        jsr EngineSchedulerInit
        rts
