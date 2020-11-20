;------------------------------------------------------------------------------------------
; Viewport. Manages background and foreground plane
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport structures
; ----------------
    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    viewportBackground
        STRUCT_MEMBER.Camera    viewportForeground
        STRUCT_MEMBER.l         viewportFinalizeHandler         ; Called after viewport finalization
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
; Force movement callback for the specified camera to be called
; ----------------
; Uses: d0-d7/a0-a6 (Unknown due to delegation)
VIEWPORT_FORCE_MOVEMENT_CALLBACK Macro camera
    lea     (viewport + \camera), a0
    move.l  camMoveCallback(a0), a1
    jsr     (a1)
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
; - a1: Viewport finalize handler. Can be null.
; - a2: Address of background tracker. If null streamingBackgroundTracker will be used.
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
ViewportInit:

        ; Set viewport finalize handler
        cmpa.w  #0, a1
        bne     .finalizeHandlerSupplied
        lea     _ViewportFinalize, a1
    .finalizeHandlerSupplied:
        move.l a1, (viewport + viewportFinalizeHandler)

        ; Set background tracker
        move.l  backgroundTrackerAddress(a0), a2            ; a2 = background tracker address
        move.l  a2, (viewport + viewportTracker)

        ; Initialize foreground plane camera
        PUSHL   a0
        move.l  #VDP_PLANE_A, d2
        movea.l mapForegroundAddress(a0), a1
        lea     (viewport + viewportForeground), a0
        jsr     CameraInit
        POPL    a0

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
        jsr     CameraRenderView
        rts


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
        MAP_RESET_RENDERER

        ; Finalize foreground camera
        lea     (viewport + viewportForeground), a0
        jsr     CameraFinalize

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
        jsr     (a2)

        ; Call viewport finalize handler
        lea     (viewport + viewportForeground), a0
        move.l  (viewport + viewportFinalizeHandler), a1
        jmp     (a1)


;-------------------------------------------------
; Default finalize handler. Updates the VDP scroll values for the foreground camera
; ----------------
; Input:
; - a0: Foreground camera
_ViewportFinalize:
        tst.l   camLastXDisplacement(a0)
        beq     .noMovement

        ; Update VDP scroll values if there was camera movement
        VDP_TASK_QUEUE_ADD #_ViewportCommit, a0

    .noMovement:
        rts


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
