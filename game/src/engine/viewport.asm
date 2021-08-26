;------------------------------------------------------------------------------------------
; Viewport. Manages background and foreground plane
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport constants
; ----------------
VIEWPORT_ACTIVE_AREA_SIZE_H     Equ 320/4
VIEWPORT_ACTIVE_AREA_SIZE_V     Equ 224/4


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
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.Viewport viewport
    DEFINE_VAR_END


;-------------------------------------------------
; Install movement callback and camera data for the specified camera
; ----------------
VIEWPORT_INSTALL_MOVEMENT_CALLBACK Macro camera, callback, cameraData
        move.l  #\callback, (viewport + \camera + Camera_moveCallback)
        move.l  \cameraData, (viewport + \camera + Camera_data)
    Endm


;-------------------------------------------------
; Restore the default movement callback for the specified camera
; ----------------
VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Macros camera
        move.l  #NoOperation, (viewport + \camera + Camera_moveCallback)


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
; Initialize the viewport library with defaults. Called on engine init.
; ----------------
ViewportEngineInit:
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Viewport_background
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Viewport_foreground
        rts


;-------------------------------------------------
; Initialize the viewport to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: ViewportConfiguration address. If NULL the ViewportConfiguration of the currently loaded map is used.
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
ViewportInit:
_INIT_SCROLL Macro orientation
            PEEKL   a1                                  ; a1 = current viewport configuration address
            lea     ViewportConfiguration_\orientation\ScrollConfiguration(a1), a1
            move.l  ScrollConfiguration_vdpScrollUpdaterAddress(a1), a2
            move.l  a2, (viewport + Viewport_\orientation\VDPScrollUpdater)
            move.l  VDPScrollUpdater_init(a2), a2
            lea     viewport, a0
            jsr     (a2)
        Endm

        VIEWPORT_TRACK_ENTITY_END

        ; Determine which viewport configuration to use and store in local variable
        MAP_GET a1
        cmpa.l  #NULL, a0
        bne     .viewportConfigurationOk
            ; Use map's default viewport configuration if non specified
            movea.l  MapHeader_viewportConfigurationAddress(a1), a0
    .viewportConfigurationOk:
        PUSHL   a0                                      ; Store current viewport configuration address in local variable

        ; Initialize foreground plane camera
        lea     (viewport + Viewport_foreground), a0
        movea.l MapHeader_foregroundAddress(a1), a1
        move.w  (vdpMetrics + VDPMetrics_screenWidth), d2
        addq.w  #8, d2                                  ; Foreground camera width = screen width + 1 pattern for scrolling
        move.w  (vdpMetrics + VDPMetrics_screenHeight), d3
        addq.w  #8, d3                                  ; Foreground camera height = screen height + 1 pattern for scrolling
        move.l  #VDP_PLANE_A, d4

        jsr     CameraInit

        ; Let background tracker initialize the background camera
        MAP_GET a1
        PEEKL   a4                                      ; a4 = current viewport configuration address
        movea.l ViewportConfiguration_backgroundTrackerConfiguration(a4), a3
        move.l  a3, (viewport + Viewport_backgroundTrackerConfiguration)
        movea.l ViewportConfiguration_backgroundTracker(a4), a4
        move.l  a4, (viewport + Viewport_backgroundTracker)
        movea.l BackgroundTracker_init(a4), a4
        lea     (viewport + Viewport_background), a0
        movea.l MapHeader_backgroundAddress(a1), a1
        lea     (viewport + Viewport_foreground), a2
        move.l  #VDP_PLANE_B, d0
        jsr     (a4)

        ; Initialize scroll updaters
        _INIT_SCROLL horizontal
        _INIT_SCROLL vertical

        ; Restore stack (remove local used to save viewport configuration)
        POPL

        ; Init active object groups
        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1
        jsr     MapInitActiveObjectGroups

        ; Render views
        lea     (viewport + Viewport_background), a0
        jsr     CameraRenderView
        lea     (viewport + Viewport_foreground), a0
        jmp     CameraRenderView

        Purge _INIT_SCROLL


;-------------------------------------------------
; Move the viewport by the specified amount
; ----------------
; - d0: Horizontal displacement
; - d1: Vertical displacement
ViewportMove:
        lea     (viewport + Viewport_foreground), a0
        CAMERA_MOVE d0, d1
        rts


;-------------------------------------------------
; Update cameras
; ----------------
; Uses: d0-d7/a0-a6
ViewportFinalize:
_UPDATE_SCROLL Macro orientation
            move.l  (viewport + Viewport_\orientation\VDPScrollUpdater), a2
            move.l  VDPScrollUpdater_update(a2), a2
            lea     viewport, a0
            jsr     (a2)
        Endm

        MAP_RENDER_RESET

        lea     (viewport + Viewport_foreground), a0
        move.w  (viewport + Viewport_trackingEntity), d0
        beq     .noTrackingEntity
        movea.w d0, a1
        bsr     _ViewportEnsureEntityVisible
    .noTrackingEntity:

        ; Finalize foreground camera
        jsr     CameraFinalize

        ; Let the background tracker update the background camera
        movea.l (viewport + Viewport_backgroundTracker), a3
        movea.l BackgroundTracker_sync(a3), a3
        lea     (viewport + Viewport_background), a0
        lea     (viewport + Viewport_foreground), a1
        movea.l (viewport + Viewport_backgroundTrackerConfiguration), a2
        jsr     (a3)

        ; Finalize background camera
        lea     (viewport + Viewport_background), a0
        jsr     CameraFinalize

        ; Update VDP scroll tables
        _UPDATE_SCROLL horizontal
        _UPDATE_SCROLL vertical

        ; Update active object groups
        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1
        jsr     MapUpdateActiveObjectGroups
        rts

        Purge _UPDATE_SCROLL


;-------------------------------------------------
; Ensure the tracking entity is within the viewport bounds
; ----------------
; Input:
; - a0: foreground camera
; - a1: tracking entity
; Uses: d0-d3
_ViewportEnsureEntityVisible
_ENSURE_ACTIVE_AREA Macro screenMetric, activeAreaSize, axis, result
                move.w  (vdpMetrics + \screenMetric), d2
                move.w   #\activeAreaSize, d3
                sub.w   d3, d2
                lsr.w   #1, d2
                move.w  Entity_\axis(a1), \result
                sub.w   Camera_\axis(a0), \result
                sub.w   Camera_\axis\Displacement(a0), \result
                sub.w   d2, \result
                ble     .done\@
                cmp.w   d3, \result
                ble     .ok\@
                sub.w   d3, \result
                bra     .done\@
            .ok\@:
                moveq   #0, \result
            .done\@:
        Endm

        _ENSURE_ACTIVE_AREA VDPMetrics_screenWidth,  VIEWPORT_ACTIVE_AREA_SIZE_H, x, d0
        _ENSURE_ACTIVE_AREA VDPMetrics_screenHeight, VIEWPORT_ACTIVE_AREA_SIZE_V, y, d1

        CAMERA_MOVE d0, d1

        Purge _ENSURE_ACTIVE_AREA
        rts
