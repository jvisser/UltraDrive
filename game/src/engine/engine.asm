;------------------------------------------------------------------------------------------
; Engine initialization
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Initialize engine components
; ----------------
EngineInit:
        jsr ViewportLibraryInit
        jsr StreamingBackgroundTrackerInit
        jsr EngineSchedulerInit
        rts


;-------------------------------------------------
; No operations handler
; ----------------
NoOperation:
    rts
