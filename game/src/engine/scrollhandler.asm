;------------------------------------------------------------------------------------------
; Scroll Handler. Handles updating the VDP scroll values for the viewport.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; ScrollHandler structures
; ----------------
    DEFINE_STRUCT ScrollHandler
        STRUCT_MEMBER.l         shInit          ; Init VDP scroll mode
        STRUCT_MEMBER.l         shUpdate        ; Update VDP scroll values
    DEFINE_STRUCT_END
