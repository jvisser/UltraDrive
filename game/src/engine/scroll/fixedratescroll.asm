;------------------------------------------------------------------------------------------
; Ignores the background camera position and scrolls at a fixed division of the foreground.
; Therefore the background should be static when using this scroll updater handler.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; FixedRate scroll handler constants
; ----------------
FIXED_RATE_SCROLL_HANDLER_SHIFT Equ 2


;-------------------------------------------------
; FixedRate scroll handler structure
; ----------------
    ; struct ScrollHandler
    fixedRateScrollHandler:
        ; .shInit
        dc.l _FixedRateScrollHandlerInit
        ; .shUpdate
        dc.l _FixedRateScrollHandlerUpdate


;-------------------------------------------------
; Setup the correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
_FixedRateScrollHandlerInit:
        ; Enable vertical plane scrolling mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_VSCROLL_CELL
        ; Enable horizontal plane scrolling mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_HSCROLL_MASK

        ; Setup VDP
        bsr     _FixedRateScrollHandlerCommit
        rts


;-------------------------------------------------
; Register scroll commit handler if there was any camera movement
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a6
_FixedRateScrollHandlerUpdate:
        move.l  viewportBackground + camLastXDisplacement(a0), d0       ; d0 = [back X displacement]:[back Y displacement]
        move.l  viewportForeground + camLastXDisplacement(a0), d1       ; d1 = [front X displacement]:[front Y displacement]
        or.l    d0, d1
        beq     .noMovement

        ; Update VDP scroll values
        VDP_TASK_QUEUE_ADD #_FixedRateScrollHandlerCommit, a0

    .noMovement:
        rts


;-------------------------------------------------
; Commit viewport scroll values to the VDP
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a1
_FixedRateScrollHandlerCommit:
        move.w  viewportForeground + camX(a0), d0
        move.w  viewportForeground + camY(a0), d1
        
        ; Auto increment to 2
        VDP_REG_SET vdpRegIncr, SIZE_WORD

        lea     MEM_VDP_DATA, a1

        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR
        neg.w   d0
        move.w  d0, (a1)
        asr.w   #FIXED_RATE_SCROLL_HANDLER_SHIFT, d0
        move.w  d0, (a1)
        
        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00
        move.w  d1, (a1)
        lsr.w   #FIXED_RATE_SCROLL_HANDLER_SHIFT, d1
        move.w  d1, (a1)
        rts
