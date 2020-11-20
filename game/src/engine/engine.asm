;------------------------------------------------------------------------------------------
; Engine initialization
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Initialize engine components
; ----------------
EngineInit:
        jsr ViewportLibraryInit
        jsr BackgroundTrackerInit
        jsr EngineSchedulerInit
        rts


;-------------------------------------------------
; No operations handler
; ----------------
NoOperation:
    rts
