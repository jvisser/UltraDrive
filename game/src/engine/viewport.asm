;------------------------------------------------------------------------------------------
; Viewport
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport structures
; ----------------
    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    viewportBackground
        STRUCT_MEMBER.Camera    viewportForeground
        STRUCT_MEMBER.l         viewportCommitHandler
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.Viewport viewport
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize camera to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: MapHeader to associate with viewport
; - a1: Address of commit routine. If null the default will be used (update first entry of horizontal/vertical scroll ram)
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
ViewportInit:
        ; Set scroll update routine
        cmpa.w  #0, a1
        bne     .scrollHandlerSupplied
        lea     _ViewportDefaultCommit, a1
    .scrollHandlerSupplied:
        move.l  a1, (viewport + viewportCommitHandler)

        ; Initialize background plane camera
        PUSHM   d0-d1/a0
        move.l  #VDP_PLANE_B, d2
        movea.l mapBackgroundAddress(a0), a1
        lea     (viewport + viewportBackground), a0
        jsr     CameraInit
        POPM    d0-d1/a0

        ; Initialize foreground plane camera
        move.l  #VDP_PLANE_A, d2
        movea.l mapForegroundAddress(a0), a1
        lea     (viewport + viewportForeground), a0
        jsr     CameraInit
        rts


;-------------------------------------------------
; Default hardware scroll camera update handler
; ----------------
; Uses: d0-d1
_ViewportDefaultCommit:
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
; Move the viewport by the specified amount
; ----------------
; - d0: Horizontal displacement
; - d1: Vertical displacement
ViewportMove:
        lea     (viewport + viewportBackground), a0
        CAMERA_MOVE d0, d1
        lea     (viewport + viewportForeground), a0
        CAMERA_MOVE d0, d1
        rts


;-------------------------------------------------
; Update cameras
; ----------------
; Uses: d0-d7/a0-a6
ViewportFinalize:
        lea     (viewport + viewportBackground), a0
        jsr     CameraFinalize
        lea     (viewport + viewportForeground), a0
        jsr     CameraFinalize
        MAP_RESET_RENDERER
        rts


;-------------------------------------------------
; Prepares the next display frame with the updated camera positions.
; Should be called during vblank only
; ----------------
; Uses: a3
ViewportPrepareNextFrame:
        movea.l (viewport + viewportCommitHandler), a3
        jmp (a3)
