;------------------------------------------------------------------------------------------
; Background tracker. Updates the background camera based on foreground camera changes.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Background tracker base structure
; ----------------
    DEFINE_STRUCT BackgroundTracker
        STRUCT_MEMBER.l btInit                 ; Initialize the background camera
        STRUCT_MEMBER.l btSync                 ; Sync the background camera with the foreground camera
    DEFINE_STRUCT_END

