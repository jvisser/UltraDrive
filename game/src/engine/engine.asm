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


;-------------------------------------------------
; No operations handler
; ----------------
NoOperation:
    rts
