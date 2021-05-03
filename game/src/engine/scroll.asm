;------------------------------------------------------------------------------------------
; Scroll support code.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Handles transfering the scroll values to the VDP
; ----------------
    DEFINE_STRUCT VDPScrollUpdater
        STRUCT_MEMBER.l     vdpsuInit                               ; Init VDP scroll mode
        STRUCT_MEMBER.l     vdpsuUpdate                             ; Update VDP scroll values
    DEFINE_STRUCT_END


;-------------------------------------------------
; Handles updating the plane/cell/line scroll tables for the viewport
; ----------------
    DEFINE_STRUCT ScrollValueUpdater
        STRUCT_MEMBER.l     svuInit                                 ; Init scroll table
        STRUCT_MEMBER.l     svuUpdate                               ; Update scroll table (returns non zero if the table data has been updated)
    DEFINE_STRUCT_END


;-------------------------------------------------
; Binds the ScrollValueUpdater to a specific viewport camera and ScrollValueUpdater specific configuration data
; ----------------
    DEFINE_STRUCT ScrollValueUpdaterConfiguration
        STRUCT_MEMBER.w     svucCamera                              ; Camera used to derive scroll values from
        STRUCT_MEMBER.l     svucUpdaterData                         ; ScrollValueUpdater specific data
        STRUCT_MEMBER.l     svucUpdater                             ; ScrollValueUpdater
    DEFINE_STRUCT_END


;-------------------------------------------------
; Scroll configuration, combines VDPScrollUpdater and scroll value updaters to ensure sensible configurations
; ----------------
    DEFINE_STRUCT ScrollConfiguration
        STRUCT_MEMBER.l                                 scVDPScrollUpdaterAddress
        STRUCT_MEMBER.ScrollValueUpdaterConfiguration   scBackgroundScrollUpdaterConfiguration
        STRUCT_MEMBER.ScrollValueUpdaterConfiguration   scForegroundScrollUpdaterConfiguration
    DEFINE_STRUCT_END
