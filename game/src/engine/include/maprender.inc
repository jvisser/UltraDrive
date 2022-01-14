;------------------------------------------------------------------------------------------
; Map rendering macros
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_MAPRENDER_INC))
__ENGINE_MAPRENDER_INC Equ 1

;-------------------------------------------------
; Reset the renderer (inline)
; ----------------
MAP_RENDER_RESET Macros
    move.w  #mapRenderBuffer, mapCurrentRenderBuffer

    EndIf
