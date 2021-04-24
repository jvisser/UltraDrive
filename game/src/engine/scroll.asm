;------------------------------------------------------------------------------------------
; Scroll support code.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Constants
; ----------------
    BIT_CONST.VDP_SCROLL_UPDATE_H   0                               ; Indicates horizontal scroll values have changed by scroll value updater
    BIT_CONST.VDP_SCROLL_UPDATE_V   1                               ; Indicates vertical scroll values have changed


;-------------------------------------------------
; Handles updating the VDP scroll values for the viewport.
; ----------------
    DEFINE_STRUCT VDPScrollUpdater
        STRUCT_MEMBER.l     vdpsuInit                               ; Init VDP scroll mode
        STRUCT_MEMBER.l     vdpsuUpdate                             ; Update VDP scroll values
    DEFINE_STRUCT_END


;-------------------------------------------------
; Handles updating the plane/cell/line scroll tables for the viewport background layer
; ----------------
    DEFINE_STRUCT ScrollValueUpdater
        STRUCT_MEMBER.l     svuInit                                 ; Init scroll table
        STRUCT_MEMBER.l     svuUpdate                               ; Update scroll table (returns one of the VDP_SCROLL_UPDATE_* flags to indicate which values have changed)
    DEFINE_STRUCT_END


;-------------------------------------------------
; Binds a specific viewport camera to scroll value updater
; ----------------
    DEFINE_STRUCT ScrollValueUpdaterConfiguration
        STRUCT_MEMBER.w     svucCamera                              ; Camera to bind updater to
        STRUCT_MEMBER.l     svucUpdater                             ; Update scroll table
    DEFINE_STRUCT_END


;-------------------------------------------------
; Scroll configuration, combines VDPScrollUpdater and parallax updaters to ensure sensible configurations
; ----------------
    DEFINE_STRUCT ScrollConfiguration
        STRUCT_MEMBER.l                                 scVDPScrollUpdaterAddress
        STRUCT_MEMBER.ScrollValueUpdaterConfiguration   scBackgroundScrollUpdaterConfiguration
        STRUCT_MEMBER.ScrollValueUpdaterConfiguration   scForegroundScrollUpdaterConfiguration
    DEFINE_STRUCT_END
