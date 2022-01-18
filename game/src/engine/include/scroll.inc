;------------------------------------------------------------------------------------------
; Scroll structures.
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_SCROLL_INC))
__ENGINE_SCROLL_INC Equ 1

    Include './system/include/memory.inc'

;-------------------------------------------------
; Handles updating (through ScrollValueUpdater's) and transfering the scroll values to the VDP for both cameras of the viewport
; ----------------
    DEFINE_STRUCT VDPScrollUpdater
        ; Input:
        ; - a0: Viewport
        ; - a1: ScrollConfiguration address
        STRUCT_MEMBER.l     init                                    ; Init VDP scroll mode
        ; Input:
        ; - a0: Viewport
        STRUCT_MEMBER.l     update                                  ; Update VDP scroll values
    DEFINE_STRUCT_END


;-------------------------------------------------
; Handles updating the plane/cell/line scroll tables for a specific camera
; ----------------
    DEFINE_STRUCT ScrollValueUpdater
        ; Input:
        ; - a0: Camera address
        ; - a1: Scroll table address provided by the underlying VDPScrollUpdater
        ; - a2: Address of ScrollValueUpdater specific configuration (From ScrollValueUpdaterConfiguration.updaterData)
        STRUCT_MEMBER.l     init
        ; Input:
        ; - a0: Camera address
        ; - a1: Scroll table address provided by the underlying VDPScrollUpdater
        ; - a2: Address of ScrollValueUpdater specific configuration (From ScrollValueUpdaterConfiguration.updaterData)
        ; Output:
        ; - d0: 1 if values have been updated, 0 otherwise
        STRUCT_MEMBER.l     update
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
