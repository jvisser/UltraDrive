;------------------------------------------------------------------------------------------
; Background tracker. Updates the background based on viewport changes.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport tracker structures
; ----------------
    DEFINE_STRUCT BackgroundTracker
        STRUCT_MEMBER.l btStart                ; Calculates the initial background camera position based on the background map and foreground camera
        STRUCT_MEMBER.l btSync                 ; Sync the background camera with the foreground camera
        STRUCT_MEMBER.l btFinalize             ; Finalize the tracker for the current frame
    DEFINE_STRUCT_END

