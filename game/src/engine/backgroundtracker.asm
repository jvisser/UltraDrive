;------------------------------------------------------------------------------------------
; Background tracker. Updates the background based on viewport changes.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Background tracker base structure
; ----------------
    DEFINE_STRUCT BackgroundTracker
        STRUCT_MEMBER.l btInit                 ; Initialize the background camera
        STRUCT_MEMBER.l btSync                 ; Sync the background camera with the foreground camera
        STRUCT_MEMBER.l btFinalize             ; Finalize the tracker for the current frame
    DEFINE_STRUCT_END

