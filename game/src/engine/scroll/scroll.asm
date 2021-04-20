;------------------------------------------------------------------------------------------
; Scroll Handler. Handles updating the VDP scroll values for the viewport.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; One time initialization. Called by engine init.
; ----------------
ScrollInit:
        jsr     DefaultScrollHandlerInit
        jsr     TilingScrollHandlerInit
        rts
