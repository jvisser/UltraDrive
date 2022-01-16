;------------------------------------------------------------------------------------------
; Background structures
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_BACKGROUND_INC))
__ENGINE_BACKGROUND_INC Equ 1

    Include './system/include/memory.inc'

;-------------------------------------------------
; Responsible for updating the background camera for the viewport.
; ----------------
    DEFINE_STRUCT BackgroundTracker
        STRUCT_MEMBER.l init                ; Initialize the background camera
        STRUCT_MEMBER.l sync                ; Sync the background camera with the foreground camera
    DEFINE_STRUCT_END

    EndIf
