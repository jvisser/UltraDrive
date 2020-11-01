;------------------------------------------------------------------------------------------
; Viewport. Manages background and foreground plane 
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport structures
; ----------------
    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    viewportBackground
        STRUCT_MEMBER.Camera    viewportForeground
        STRUCT_MEMBER.l         viewportCommitHandler           ; Called to commit viewport to VDP
        STRUCT_MEMBER.l         viewportFinalizeHandler         ; Called after viewport finalization (can be used to update data required by the commit handler)
        STRUCT_MEMBER.l         viewportTracker                 ; Used to update the background camera
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.Viewport viewport
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize the viewport to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: MapHeader to associate with viewport
; - a1: Address of commit handler. If null the default will be used (update first entry of horizontal/vertical scroll ram)
; - a2: Viewport finalize handler. Can be null.
; - a3: Address of viewport tracker. If null defaultViewportTracker will be used.
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
ViewportInit:
        ; Set commit handler
        cmpa.w  #0, a1
        bne     .commitHandlerSupplied
        lea     ViewportCommitPlaneScroll, a1
    .commitHandlerSupplied:
        move.l  a1, (viewport + viewportCommitHandler)

        ; Set viewport finalize handler
        cmpa.w  #0, a2
        bne     .finalizeHandlerSupplied
        lea     _ViewportDefaultFinalize, a2
    .finalizeHandlerSupplied:
        move.l a2, (viewport + viewportFinalizeHandler)

        ; Set viewport tracker
        cmpa.w  #0, a3
        bne     .viewportTrackerSupplied
        lea     defaultViewportTracker, a3
    .viewportTrackerSupplied:
        move.l  a3, (viewport + viewportTracker)

        ; Initialize foreground plane camera
        PUSHL   a0
        move.l  #VDP_PLANE_A, d2
        movea.l mapForegroundAddress(a0), a1
        lea     (viewport + viewportForeground), a0
        jsr     CameraInit
        POPL    a0

        ; Let viewport tracker calculate the background camera position based on the background map and foreground camera
        PUSHL   a0
        movea.l mapBackgroundAddress(a0), a0
        lea     (viewport + viewportForeground), a1
        movea.l vptStart(a3), a3
        jsr     (a3)
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
; Default commit handler. Assumes plane based scolling and updates scroll values accordingly.
; ----------------
; Uses: d0-d1
ViewportCommitPlaneScroll:
        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR, $02
        move.w  (viewport + viewportForeground + camX), d0
        neg.w   d0
        swap    d0
        move.w  (viewport + viewportBackground + camX), d0
        neg.w   d0
        move.l  d0, (MEM_VDP_DATA)

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00
        move.w  (viewport + viewportForeground + camY), d1
        swap    d1
        move.w  (viewport + viewportBackground + camY), d1
        move.l  d1, (MEM_VDP_DATA)
        rts


;-------------------------------------------------
; Default finalize handler (NOOP)
; ----------------
_ViewportDefaultFinalize:
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

        ; Let viewport tracker update the background camera
        movea.l (viewport + viewportTracker), a2
        movea.l vptSync(a2), a2
        lea     (viewport + viewportBackground), a0
        lea     (viewport + viewportForeground), a1
        jsr     (a2)
        
        ; Finalize background camera
        lea     (viewport + viewportBackground), a0
        jsr     CameraFinalize
        
        ; Add viewport commit handler to VDP task queue
        VDP_TASK_QUEUE_JOB (viewport + viewportCommitHandler)

        ; Call viewport finalize handler
        move.l  viewportFinalizeHandler(a0), a1
        jmp     (a1)
