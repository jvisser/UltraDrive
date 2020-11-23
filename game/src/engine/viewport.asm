;------------------------------------------------------------------------------------------
; Viewport. Manages background and foreground plane
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport structures
; ----------------
    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    viewportBackground
        STRUCT_MEMBER.Camera    viewportForeground
        STRUCT_MEMBER.l         viewportTracker                 ; Used to update the background camera
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
; Initialize the viewport library with defaults. Called on engine init.
; ----------------
ViewportLibraryInit:
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK viewportBackground
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK viewportForeground
        rts


;-------------------------------------------------
; Initialize the viewport to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: MapHeader to associate with viewport
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
ViewportInit:

        ; Initialize foreground plane camera
        PUSHL   a0
        move.l  #VDP_PLANE_A, d2
        movea.l mapForegroundAddress(a0), a1
        lea     (viewport + viewportForeground), a0
        jsr     CameraInit
        POPL    a0

        ; Set background tracker
        move.l  backgroundTrackerAddress(a0), a2            ; a2 = background tracker address
        move.l  a2, (viewport + viewportTracker)

        ; Let background tracker calculate the background camera position based on the background map and foreground camera
        PUSHL   a0
        movea.l mapBackgroundAddress(a0), a0
        lea     (viewport + viewportForeground), a1
        movea.l btStart(a2), a2
        jsr     (a2)
        POPL    a0

        ; Initialize background plane camera
        move.l  #VDP_PLANE_B, d2
        movea.l mapBackgroundAddress(a0), a1
        lea     (viewport + viewportBackground), a0
        jsr     CameraInit

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

        ; Finalize foreground camera
        lea     (viewport + viewportForeground), a0
        jsr     CameraFinalize

        ; If camera changed update VDP scroll
        tst.l   camLastXDisplacement(a0)
        beq     .noMovement
        VDP_TASK_QUEUE_ADD #_ViewportCommit, a0
    .noMovement:

        ; Let the background tracker update the background camera
        movea.l (viewport + viewportTracker), a2
        movea.l btSync(a2), a2
        lea     (viewport + viewportBackground), a0
        lea     (viewport + viewportForeground), a1
        jsr     (a2)

        ; Finalize background camera
        lea     (viewport + viewportBackground), a0
        jsr     CameraFinalize

        ; Finalize the background tracker
        movea.l (viewport + viewportTracker), a2
        movea.l btFinalize(a2), a2
        jmp     (a2)
        

;-------------------------------------------------
; Default commit handler. Assumes plane based scolling and updates scroll values accordingly.
; ----------------
; Input:
; - a0: Foreground camera
; Uses: d0
_ViewportCommit:

        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR
        move.w  camX(a0), d0
        neg.w   d0
        move.w  d0, (MEM_VDP_DATA)

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00
        move.w  camY(a0), d0
        move.w  d0, (MEM_VDP_DATA)
        rts
