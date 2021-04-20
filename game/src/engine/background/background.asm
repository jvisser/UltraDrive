;------------------------------------------------------------------------------------------
; Initialization code and shared macros for background trackers
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; One time initialization. Called by engine init.
; ----------------
BackgroundInit:
        jsr     DefaultBackgroundTrackerInit
        rts
