;------------------------------------------------------------------------------------------
; Scrolls both planes based on the camera positions using linescroll mode for the horizontal scrolling.
; Applying parallax scrolling to the background plane.
; Only supports 224 line mode atm.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Line scroll structures
; ----------------
    DEFINE_VAR SLOW
        VAR.w lsPlaneBHScroll, 224          ; Background line scroll buffer
        VAR.w lsPlaneAHScroll, 224          ; Foreground line scroll buffer
    DEFINE_VAR_END

    ; struct ScrollHandler
    lineScrollHandler:
        ; .shInit
        dc.l _LineScrollHandlerInit
        ; .shUpdate
        dc.l _LineScrollHandlerUpdate

    lsPlaneBHScrollDMATransferCommandList:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST lsPlaneBHScroll, VDP_HSCROLL_ADDR + SIZE_WORD, lsPlaneBHScroll_Size / SIZE_WORD, SIZE_WORD * 2

    lsPlaneAHScrollDMATransferCommandList:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST lsPlaneAHScroll, VDP_HSCROLL_ADDR, lsPlaneAHScroll_Size / SIZE_WORD, SIZE_WORD * 2


LS_LINE_BUFFER_SIZE Equ lsPlaneAHScroll_Size


;-------------------------------------------------
; Set all lines in the line scroll buffer to the camera x position
; ----------------
; Input:
; - a0: viewport
; Uses: d0-d1/a0-a6
_LINE_SCROLL_UPDATE_FIXED_VALUE Macro camera, scrollBuffer, dmaCommandList
        move.w  \camera + camX(a0), d0
        neg.w   d0
        lea     \scrollBuffer\ + \scrollBuffer\_Size, a0
        bsr     _LineScrollHandlerBufferFill
    Endm


;-------------------------------------------------
; Setup buffers and correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
_LineScrollHandlerInit:
        ; Enable vertical plane scrolling mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_VSCROLL_CELL
        ; Enable horizontal line scrolling mode
        VDP_REG_SET_BIT_FIELD vdpRegMode3, MODE3_HSCROLL_MASK, MODE3_HSCROLL_LINE

        ; Setup vertical scroll
        bsr     _LineScrollHandlerCommitVScroll

        ; Setup background horizontal scroll
        PUSHL   a0
        _LINE_SCROLL_UPDATE_FIXED_VALUE viewportBackground, lsPlaneBHScroll
        VDP_DMA_TRANSFER_COMMAND_LIST lsPlaneBHScrollDMATransferCommandList
        POPL    a0

        ; Setup foreground horizontal scroll
        _LINE_SCROLL_UPDATE_FIXED_VALUE viewportForeground, lsPlaneAHScroll
        VDP_DMA_TRANSFER_COMMAND_LIST lsPlaneAHScrollDMATransferCommandList
        rts


;-------------------------------------------------
; Calculate line scroll tables and schedule them for DMA transfer and register scroll commit handler for vertical scroll update
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a0-a6
_LineScrollHandlerUpdate:
        move.l  viewportBackground + camLastXDisplacement(a0), d0       ; d0 = [back X displacement]:[back Y displacement]
        move.l  viewportForeground + camLastXDisplacement(a0), d1       ; d1 = [front X displacement]:[front Y displacement]

        or.w    d0, d1
        beq     .noVerticalMovement

        VDP_TASK_QUEUE_ADD #_LineScrollHandlerCommitVScroll, a0

    .noVerticalMovement:

        swap    d0
        tst.w   d0
        beq     .noBackgroundHScroll

            PUSHL   a0

            ; TODO: Parallax calculations
            _LINE_SCROLL_UPDATE_FIXED_VALUE viewportBackground, lsPlaneBHScroll

            VDP_DMA_QUEUE_ADD_COMMAND_LIST lsPlaneBHScrollDMATransferCommandList

            POPL    a0

    .noBackgroundHScroll:

        swap    d1
        tst.w   d1
        beq .noForegroundHScroll

            _LINE_SCROLL_UPDATE_FIXED_VALUE viewportForeground, lsPlaneAHScroll

            VDP_DMA_QUEUE_ADD_COMMAND_LIST lsPlaneAHScrollDMATransferCommandList

    .noForegroundHScroll:
        rts


;-------------------------------------------------
; Fill specified line scroll buffer with single value
; ----------------
; Input:
; - d0: Value to fill buffer with
; - a0: Line scroll buffer a of b buffer top address
; Uses: d0-d1/a0-a6
_LineScrollHandlerBufferFill:
        move.w  d0, d2
        swap    d0
        move.w  d2, d0
        move.l  d0, d1
        move.l  d0, d2
        move.l  d0, d3
        move.l  d0, d4
        move.l  d0, d5
        move.l  d0, d6
        move.l  d0, d7
        movea.l d0, a1
        movea.l d0, a2
        movea.l d0, a3
        movea.l d0, a4
        movea.l d0, a5
        movea.l d0, a6
        Rept LS_LINE_BUFFER_SIZE / SIZE_WORD / 28
            movem.l d0-d7/a1-a6, -(a0)
        Endr
        rts


;-------------------------------------------------
; Update vertical scroll values
; ----------------
; Input:
; - a0: Viewport
_LineScrollHandlerCommitVScroll:

        move.w  viewportForeground + camY(a0), d0
        move.w  viewportBackground + camY(a0), d1

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00, SIZE_WORD
        move.w  d0, MEM_VDP_DATA
        move.w  d1, MEM_VDP_DATA
        rts
