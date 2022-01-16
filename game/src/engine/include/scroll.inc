;------------------------------------------------------------------------------------------
; Scroll structures.
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_SCROLL_INC))
__ENGINE_SCROLL_INC Equ 1

    Include './system/include/memory.inc'

;-------------------------------------------------
; Handles transfering the scroll values to the VDP
; ----------------
    DEFINE_STRUCT VDPScrollUpdater
        STRUCT_MEMBER.l     init                                    ; Init VDP scroll mode
        STRUCT_MEMBER.l     update                                  ; Update VDP scroll values
    DEFINE_STRUCT_END


;-------------------------------------------------
; Handles updating the plane/cell/line scroll tables for the viewport
; ----------------
    DEFINE_STRUCT ScrollValueUpdater
        STRUCT_MEMBER.l     init                                    ; Init scroll table
        STRUCT_MEMBER.l     update                                  ; Update scroll table (returns non zero if the table data has been updated)
    DEFINE_STRUCT_END


;-------------------------------------------------
; Binds the ScrollValueUpdater to a specific viewport camera and ScrollValueUpdater specific configuration data
; ----------------
    DEFINE_STRUCT ScrollValueUpdaterConfiguration
        STRUCT_MEMBER.w     camera                                  ; Camera used to derive scroll values from
        STRUCT_MEMBER.l     updaterData                             ; ScrollValueUpdater specific data
        STRUCT_MEMBER.l     updater                                 ; ScrollValueUpdater
    DEFINE_STRUCT_END


;-------------------------------------------------
; Scroll configuration, combines VDPScrollUpdater and scroll value updaters to ensure sensible configurations
; ----------------
    DEFINE_STRUCT ScrollConfiguration
        STRUCT_MEMBER.l                                 vdpScrollUpdaterAddress
        STRUCT_MEMBER.ScrollValueUpdaterConfiguration   backgroundScrollUpdaterConfiguration
        STRUCT_MEMBER.ScrollValueUpdaterConfiguration   foregroundScrollUpdaterConfiguration
    DEFINE_STRUCT_END

    EndIf
