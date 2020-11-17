;------------------------------------------------------------------------------------------
; Engine initialization
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Initialize engine components
; ----------------
EngineInit:
        jsr ViewportLibraryInit
        jsr DefaultViewportTrackerInit
        jsr EngineSchedulerInit
        rts


;-------------------------------------------------
; No operations handler
; ----------------
NoOperation:
    rts
