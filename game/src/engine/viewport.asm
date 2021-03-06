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
        STRUCT_MEMBER.l                     vcBackgroundTracker                 ; Used to update the background camera position
        STRUCT_MEMBER.l                     vcBackgroundTrackerConfiguration    ; Background tracker configuration address (if any)
        STRUCT_MEMBER.ScrollConfiguration   vcHorizontalScrollConfiguration     ; Used to update horizontal VDP scroll values
        STRUCT_MEMBER.ScrollConfiguration   vcVerticalScrollConfiguration       ; Used to update vertical VDP scroll values
    DEFINE_STRUCT_END

    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    viewportBackground
        STRUCT_MEMBER.Camera    viewportForeground
        STRUCT_MEMBER.l         viewportBackgroundTracker                       ; Used to update the background camera
        STRUCT_MEMBER.l         viewportBackgroundTrackerConfiguration
        STRUCT_MEMBER.l         viewportHorizontalVDPScrollUpdater              ; Used to update the horizontal VDP scroll values
        STRUCT_MEMBER.l         viewportVerticalVDPScrollUpdater                ; Used to update the vertical VDP scroll values
        STRUCT_MEMBER.w         viewportTrackingEntity                          ; Entity to keep in view
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.Viewport viewport
    DEFINE_VAR_END


;-------------------------------------------------
; Install movement callback and camera data for the specified camera
; ----------------
VIEWPORT_INSTALL_MOVEMENT_CALLBACK Macro camera, callback, cameraData
        move.l  #\callback, (viewport + \camera + camMoveCallback)
        move.l  \cameraData, (viewport + \camera + camData)
    Endm


;-------------------------------------------------
; Restore the default movement callback for the specified camera
; ----------------
VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Macros camera
        move.l  #NoOperation, (viewport + \camera + camMoveCallback)


;-------------------------------------------------
; Start tracking the specified entity
; ----------------
VIEWPORT_TRACK_ENTITY Macros entity
        move.w  \entity, (viewport + viewportTrackingEntity)


;-------------------------------------------------
; Stop entity tracking
; ----------------
VIEWPORT_TRACK_ENTITY_END Macros
        clr.w  (viewport + viewportTrackingEntity)


;-------------------------------------------------
; Get viewport X position
; ----------------
VIEWPORT_GET_X Macros target
    move.w  (viewport + viewportForeground + camX), \target


;-------------------------------------------------
; Get viewport Y position
; ----------------
VIEWPORT_GET_Y Macros target
    move.w  (viewport + viewportForeground + camY), \target


;-------------------------------------------------
; Initialize the viewport library with defaults. Called on engine init.
; ----------------
ViewportEngineInit:
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK viewportBackground
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK viewportForeground
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
            lea     vc\orientation\ScrollConfiguration(a1), a1
            move.l  scVDPScrollUpdaterAddress(a1), a2
            move.l  a2, (viewport + viewport\orientation\VDPScrollUpdater)
            move.l  vdpsuInit(a2), a2
            lea     viewport, a0
            jsr     (a2)
        Endm

        VIEWPORT_TRACK_ENTITY_END

        VDP_SCROLL_UPDATER_RESET

        ; Determine which viewport configuration to use and store in local variable
        MAP_GET a1
        cmpa.l  #NULL, a0
        bne     .viewportConfigurationOk
            ; Use map's default viewport configuration if non specified
            movea.l  mapViewportConfiguration(a1), a0
    .viewportConfigurationOk:
        PUSHL   a0                                      ; Store current viewport configuration address in local variable

        ; Initialize foreground plane camera
        lea     (viewport + viewportForeground), a0
        movea.l mapForegroundAddress(a1), a1
        move.w  (vdpMetrics + vdpScreenWidth), d2
        addq.w  #8, d2                                  ; Foreground camera width = screen width + 1 pattern for scrolling
        move.w  (vdpMetrics + vdpScreenHeight), d3
        addq.w  #8, d3                                  ; Foreground camera height = screen height + 1 pattern for scrolling
        move.l  #VDP_PLANE_A, d4

        jsr     CameraInit

        ; Let background tracker initialize the background camera
        MAP_GET a1
        PEEKL   a4                                      ; a4 = current viewport configuration address
        movea.l vcBackgroundTrackerConfiguration(a4), a3
        move.l  a3, (viewport + viewportBackgroundTrackerConfiguration)
        movea.l vcBackgroundTracker(a4), a4
        move.l  a4, (viewport + viewportBackgroundTracker)
        movea.l btInit(a4), a4
        lea     (viewport + viewportBackground), a0
        movea.l mapBackgroundAddress(a1), a1
        lea     (viewport + viewportForeground), a2
        move.l  #VDP_PLANE_B, d0
        jsr     (a4)

        ; Initialize scroll updaters
        _INIT_SCROLL Horizontal
        _INIT_SCROLL Vertical

        ; Restore stack (remove local used to save viewport configuration)
        POPL

        ; Render views
        lea     (viewport + viewportBackground), a0
        jsr     CameraRenderView
        lea     (viewport + viewportForeground), a0
        jmp     CameraRenderView

        Purge _INIT_SCROLL


;-------------------------------------------------
; Move the viewport by the specified amount
; ----------------
; - d0: Horizontal displacement
; - d1: Vertical displacement
ViewportMove:
        lea     (viewport + viewportForeground), a0
        CAMERA_MOVE d0, d1
        rts


;-------------------------------------------------
; Update cameras
; ----------------
; Uses: d0-d7/a0-a6
ViewportFinalize:
_UPDATE_SCROLL Macro orientation
            move.l  (viewport + viewport\orientation\VDPScrollUpdater), a2
            move.l  vdpsuUpdate(a2), a2
            lea     viewport, a0
            jsr     (a2)
        Endm

        MAP_RENDER_RESET

        lea     (viewport + viewportForeground), a0
        move.w  (viewport + viewportTrackingEntity), d0
        beq     .noTrackingEntity
        movea.w d0, a1
        bsr     _ViewportEnsureEntityVisible
    .noTrackingEntity:

        ; Finalize foreground camera
        jsr     CameraFinalize

        ; Let the background tracker update the background camera
        movea.l (viewport + viewportBackgroundTracker), a3
        movea.l btSync(a3), a3
        lea     (viewport + viewportBackground), a0
        lea     (viewport + viewportForeground), a1
        movea.l (viewport + viewportBackgroundTrackerConfiguration), a2
        jsr     (a3)

        ; Finalize background camera
        lea     (viewport + viewportBackground), a0
        jsr     CameraFinalize

        ; Update VDP scroll tables
        _UPDATE_SCROLL Horizontal
        _UPDATE_SCROLL Vertical
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
                move.w  entity\axis(a1), \result
                sub.w   cam\axis(a0), \result
                sub.w   cam\axis\Displacement(a0), \result
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

        _ENSURE_ACTIVE_AREA vdpScreenWidth,  VIEWPORT_ACTIVE_AREA_SIZE_H, X, d0
        _ENSURE_ACTIVE_AREA vdpScreenHeight, VIEWPORT_ACTIVE_AREA_SIZE_V, Y, d1

        CAMERA_MOVE d0, d1

        Purge _ENSURE_ACTIVE_AREA
        rts
