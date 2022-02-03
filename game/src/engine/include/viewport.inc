;------------------------------------------------------------------------------------------
; Viewport structures / macros.
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_VIEW_PORT_INC))
__ENGINE_VIEW_PORT_INC Equ 1

    Include './system/include/memory.inc'

    Include './engine/include/camera.inc'

;-------------------------------------------------
; Viewport constants
; ----------------
VIEWPORT_ACTIVE_AREA_SIZE_H     Equ 320/4
VIEWPORT_ACTIVE_AREA_SIZE_V     Equ 224/4


;-------------------------------------------------
; Viewport flags
; ----------------
    BIT_CONST.VIEWPORT_DIRTY    0


;-------------------------------------------------
; Viewport structures
; ----------------
    DEFINE_STRUCT ViewportConfiguration
        STRUCT_MEMBER.l                     backgroundTracker                   ; Used to update the background camera position
        STRUCT_MEMBER.l                     backgroundTrackerConfiguration      ; Background tracker configuration address (if any)
        STRUCT_MEMBER.ScrollConfiguration   horizontalScrollConfiguration       ; Used to update horizontal VDP scroll values
        STRUCT_MEMBER.ScrollConfiguration   verticalScrollConfiguration         ; Used to update vertical VDP scroll values
    DEFINE_STRUCT_END

    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    background
        STRUCT_MEMBER.Camera    foreground
        STRUCT_MEMBER.l         backgroundTracker                               ; Used to update the background camera
        STRUCT_MEMBER.l         backgroundTrackerConfiguration
        STRUCT_MEMBER.l         horizontalVDPScrollUpdater                      ; Used to update the horizontal VDP scroll values
        STRUCT_MEMBER.l         verticalVDPScrollUpdater                        ; Used to update the vertical VDP scroll values
        STRUCT_MEMBER.w         trackingEntity                                  ; Entity to keep in view
        STRUCT_MEMBER.l         foregroundMovementCallback
        STRUCT_MEMBER.w         subChunkId                                      ; Used to detect viewport chunk changes on movement
        STRUCT_MEMBER.l         activeObjectGroupConfigurationId                ; Current object group configuration used to detect object group configuration changes
        STRUCT_MEMBER.l         activeObjectGroups, 13                          ; Null terminated array containing the active object groups
        STRUCT_MEMBER.w         chunkRefCache, 12                               ; Cache of all chunks references in view (foreground). Used as the basis for rendering the foreground. Can be dynamically patched to alter the appearance of the map.
        STRUCT_MEMBER.w         chunkRefCacheStride                             ; Number of bytes per row in the chunk reference cache
        STRUCT_MEMBER.b         flags
    DEFINE_STRUCT_END


;-------------------------------------------------
; Install movement callback and camera data for the specified camera
; ----------------
VIEWPORT_INSTALL_MOVEMENT_CALLBACK Macro camera, callback, cameraData
        If (strcmp('\camera', 'foreground'))
            move.l  #\callback, (viewport + Viewport_foregroundMovementCallback)
        Else
            move.l  #\callback, (viewport + Viewport_\camera + Camera_moveCallback)
        EndIf
        move.l  \cameraData, (viewport + Viewport_\camera + Camera_data)
    Endm


;-------------------------------------------------
; Restore the default movement callback for the specified camera
; ----------------
VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Macro camera
        If (strcmp('\camera', 'foreground'))
            move.l  #NoOperation, (viewport + Viewport_foregroundMovementCallback)
        Else
            move.l  #NoOperation, (viewport + Viewport_\camera + Camera_moveCallback)
        EndIf
    Endm


;-------------------------------------------------
; Start tracking the specified entity
; ----------------
VIEWPORT_TRACK_ENTITY Macros entity
        move.w  \entity, (viewport + Viewport_trackingEntity)


;-------------------------------------------------
; Stop entity tracking
; ----------------
VIEWPORT_TRACK_ENTITY_END Macros
        clr.w  (viewport + Viewport_trackingEntity)


;-------------------------------------------------
; Get viewport X position
; ----------------
VIEWPORT_GET_X Macros target
    move.w  (viewport + Viewport_foreground + Camera_x), \target


;-------------------------------------------------
; Get viewport Y position
; ----------------
VIEWPORT_GET_Y Macros target
    move.w  (viewport + Viewport_foreground + Camera_y), \target


;-------------------------------------------------
; Set viewport flag
; ----------------
VIEWPORT_SET_FLAG Macros flag
    bset    #\flag, (viewport + Viewport_flags)


;-------------------------------------------------
; Clear viewport flag
; ----------------
VIEWPORT_RESET_FLAG Macros flag
    bclr    #\flag, (viewport + Viewport_flags)


;-------------------------------------------------
; Create default viewport configuration using plane based scrolling and relative background implementation
; ----------------
DEFINE_RELATIVE_BACKGROUND_VIEWPORT_CONFIG Macro
        ; .backgroundTracker
        dc.l relativeBackgroundTracker
        ; .backgroundTrackerConfiguration
        dc.l relativeHorizontalVerticalBackgroundTrackerConfiguration
        ; .horizontalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l planeHorizontalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_background
                ; .updaterData
                dc.l planeHorizontalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeHorizontalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
        ; .verticalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l planeVerticalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_background
                ; .updaterData
                dc.l planeVerticalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeVerticalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
    Endm


;-------------------------------------------------
; Create a viewport configuration with a static background that scrolls as a rate relative to the foreground camera. Effectively making the background repeat infinitely.
; Speed can be ommitted to scroll at the same speed as the foreground or have one of the following values:
; - HalfSpeed: Half speed of the foreground camera movement.
; - QuarterSpeed: Quarter speed of the foreground camera movement.
; ----------------
DEFINE_TILING_BACKGROUND_VIEWPORT_CONFIG Macro speed
        ; .backgroundTracker
        dc.l staticBackgroundTracker
        ; .backgroundTrackerConfiguration
        dc.l NULL
        ; .horizontalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l planeHorizontalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeHorizontalScrollCamera\speed\Config
                ; .updater
                dc.l planeScrollCamera
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeHorizontalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
        ; .verticalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l planeVerticalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeVerticalScrollCamera\speed\Config
                ; .updater
                dc.l planeScrollCamera
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeVerticalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
    Endm


;-------------------------------------------------
; Create a viewport configuration with a static background that rotates and translates according to the specified RotateScrollCameraConfiguration
; ----------------
DEFINE_ROTATING_BACKGROUND_VIEWPORT_CONFIG Macro config
        ; .backgroundTracker
        dc.l staticBackgroundTracker
        ; .backgroundTrackerConfiguration
        dc.l NULL
        ; .horizontalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l lineHorizontalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_background
                ; .updaterData
                dc.l \config
                ; .updater
                dc.l rotateHorizontalLineScroll
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l lineHorizontalScrollCameraConfig
                ; .updater
                dc.l multiScrollCamera
        ; .verticalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l cellVerticalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_background
                ; .updaterData
                dc.l \config
                ; .updater
                dc.l rotateVerticalCellScroll
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l cellVerticalScrollCameraConfig
                ; .updater
                dc.l multiScrollCamera
    Endm

    EndIf
