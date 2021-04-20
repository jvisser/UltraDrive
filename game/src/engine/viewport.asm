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
    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    viewportBackground
        STRUCT_MEMBER.Camera    viewportForeground
        STRUCT_MEMBER.l         viewportBackgroundTracker       ; Used to update the background camera
        STRUCT_MEMBER.l         viewportScrollHandlerAddress    ; Used to update the VDP scroll values
        STRUCT_MEMBER.w         viewportTrackingEntity          ; Entity to keep in view
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
VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Macro camera
        move.l  #NoOperation, (viewport + \camera + camMoveCallback)
    Endm


;-------------------------------------------------
; Start tracking the specified entity
; ----------------
VIEWPORT_TRACK_ENTITY Macro entity
        move.w  \entity, (viewport + viewportTrackingEntity)
    Endm


;-------------------------------------------------
; Stop entity tracking
; ----------------
VIEWPORT_TRACK_ENTITY_END Macro
        move.w  #0, (viewport + viewportTrackingEntity)
    Endm


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
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
ViewportInit:

        VIEWPORT_TRACK_ENTITY_END

        ; Initialize foreground plane camera
        MAP_GET a1
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
        move.l  mapBackgroundTrackerAddress(a1), a3
        move.l  a3, (viewport + viewportBackgroundTracker)
        movea.l btInit(a3), a3
        lea     (viewport + viewportBackground), a0
        movea.l mapBackgroundAddress(a1), a1
        lea     (viewport + viewportForeground), a2
        move.l  #VDP_PLANE_B, d0
        jsr     (a3)

        ; Initialize scroll handler
        MAP_GET a1
        move.l  mapScrollHandlerAddress(a1), a1
        move.l  a1, (viewport + viewportScrollHandlerAddress)
        move.l  shInit(a1), a1
        lea     viewport, a0
        jsr     (a1)

        ; Force initial update of scroll values
        move.l  (viewport + viewportScrollHandlerAddress), a1
        move.l  shUpdate(a1), a1
        lea     viewport, a0
        jsr     (a1)

        ; Render views
        lea     (viewport + viewportBackground), a0
        jsr     CameraRenderView
        lea     (viewport + viewportForeground), a0
        jmp     CameraRenderView


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
        movea.l (viewport + viewportBackgroundTracker), a2
        movea.l btSync(a2), a2
        lea     (viewport + viewportBackground), a0
        lea     (viewport + viewportForeground), a1
        jsr     (a2)

        ; Finalize background camera
        lea     (viewport + viewportBackground), a0
        jsr     CameraFinalize

        ; Update scrolling
        move.l  (viewport + viewportScrollHandlerAddress), a2
        move.l  shUpdate(a2), a2
        lea     viewport, a0
        jmp     (a2)


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
