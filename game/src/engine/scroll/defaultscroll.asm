;------------------------------------------------------------------------------------------
; Default scroll handler. Updates the VDP scroll values for both cameras. Uses plane scrolling.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Default scrollHandler structures
; ----------------
    DEFINE_VAR FAST
        VAR.ScrollHandler  defaultScrollHandler
    DEFINE_VAR_END

    INIT_STRUCT defaultScrollHandler
        INIT_STRUCT_MEMBER.shInit   _DefaultScrollHandlerInit
        INIT_STRUCT_MEMBER.shUpdate _DefaultScrollHandlerUpdate
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the default scroll handler. Called on engine init.
; ----------------
DefaultScrollHandlerInit Equ defaultScrollHandlerInit


;-------------------------------------------------
; Setup the correct VDP scrolling mode
; ----------------
_DefaultScrollHandlerInit:
        ; Enable plane scrolling mode (clear scroll mode bits)
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_HSCROLL_MASK
        rts


;-------------------------------------------------
; Register scroll commit handler if there was any camera movement
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a6
_DefaultScrollHandlerUpdate:
        move.l  viewportBackground + camLastXDisplacement(a0), d0       ; d0 = [back X displacement]:[back Y displacement]
        move.l  viewportForeground + camLastXDisplacement(a0), d1       ; d1 = [front X displacement]:[front Y displacement]
        or.l    d0, d1
        beq     .noMovement
        
        ; Update VDP scroll values
        VDP_TASK_QUEUE_ADD #_DefaultScrollHandlerCommit, a0
        
    .noMovement:
        rts


;-------------------------------------------------
; Commit viewport scroll values to the VDP
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a1
_DefaultScrollHandlerCommit:
        move.l  viewportForeground + camX(a0), d0       ; d0 = [front X]:[front Y]
        move.l  viewportBackground + camX(a0), d1       ; d1 = [back X]:[back Y]
        
        ; Auto increment to 2
        VDP_REG_SET vdpRegIncr, SIZE_WORD

        lea     MEM_VDP_DATA, a1

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00
        move.w  d0, (a1)
        move.w  d1, (a1)
        
        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR
        swap    d0
        swap    d1
        neg.w   d0
        neg.w   d1
        move.w  d0, (a1)
        move.w  d1, (a1)
        rts
