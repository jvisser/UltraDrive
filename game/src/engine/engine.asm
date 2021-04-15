;------------------------------------------------------------------------------------------
; Engine initialization
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Initialize engine components
; ----------------
EngineInit:
        jsr ViewportEngineInit
        jsr BackgroundInit
        jsr EngineSchedulerInit
        rts
