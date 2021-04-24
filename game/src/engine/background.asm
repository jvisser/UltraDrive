;------------------------------------------------------------------------------------------
; Background support code.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Responsible for updating the background camera for the viewport.
; ----------------
    DEFINE_STRUCT BackgroundTracker
        STRUCT_MEMBER.l btInit                 ; Initialize the background camera
        STRUCT_MEMBER.l btSync                 ; Sync the background camera with the foreground camera
    DEFINE_STRUCT_END
