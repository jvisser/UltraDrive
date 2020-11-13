;------------------------------------------------------------------------------------------
; Engine initialization
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Initialize engine components
; ----------------
EngineInit:
        jsr ViewportLibraryInit
        jsr DefaultViewportTrackerInit
        jsr EngineTickInit
        rts
