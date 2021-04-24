;------------------------------------------------------------------------------------------
; Scrolls both planes based on the camera positions using linescroll mode for the horizontal scrolling.
; Applying parallax scrolling to the background plane.
; Only supports 224 line mode atm.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Line scroll structures
; ----------------
    DEFINE_STRUCT LineVDPScrollUpdaterPlaneState
        STRUCT_MEMBER.w     lsuLineHorizontalScroll, 224            ; NB: Horizontal scroll values must be negated by the ScrollValueUpdater for performance reasons
        STRUCT_MEMBER.w     lsuPlaneVerticalScroll
    DEFINE_STRUCT_END

    DEFINE_STRUCT LineVDPScrollUpdaterState
        STRUCT_MEMBER.LineVDPScrollUpdaterPlaneState lvsusPlaneB
        STRUCT_MEMBER.LineVDPScrollUpdaterPlaneState lvsusPlaneA
    DEFINE_STRUCT_END

    ; struct VDPScrollUpdater
    lineVDPScrollUpdater:
        ; .vdpsuInit
        dc.l _LineVDPScrollUpdaterInit
        ; .vdpsuUpdate
        dc.l _LineVDPScrollUpdaterUpdate

LS_LINE_BUFFER_SIZE Equ 224 * 2


;-------------------------------------------------
; PlaneVDPScrollUpdaterState address alias
; ----------------
lineVDPScrollUpdaterState Equ vdpScrollBuffer


;-------------------------------------------------
; Pre defined DMA tranfer command lists for line scroll tables
; ----------------

    lsPlaneBHScrollDMATransferCommandList:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST (lineVDPScrollUpdaterState + lvsusPlaneB + lsuLineHorizontalScroll), VDP_HSCROLL_ADDR + SIZE_WORD, LS_LINE_BUFFER_SIZE / SIZE_WORD, SIZE_WORD * 2


    lsPlaneAHScrollDMATransferCommandList:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST (lineVDPScrollUpdaterState + lvsusPlaneA + lsuLineHorizontalScroll), VDP_HSCROLL_ADDR, LS_LINE_BUFFER_SIZE / SIZE_WORD, SIZE_WORD * 2


;-------------------------------------------------
; Support routine for scroll value updater implementations.
; Fill specified 224 word line scroll buffer with a single value
; ----------------
; Input:
; - d0: Value to fill buffer with
; - a0: 224 line scroll buffer address
; Uses: d0-d1/a0-a6
LineScrollBufferFill:
        lea     LS_LINE_BUFFER_SIZE(a0), a0
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
; Setup buffers and correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
_LineVDPScrollUpdaterInit:
        ; Enable vertical plane scroll mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_VSCROLL_CELL
        ; Enable horizontal line scroll mode
        VDP_REG_SET_BIT_FIELD vdpRegMode3, MODE3_HSCROLL_MASK, MODE3_HSCROLL_LINE

        ; Initialize scroll values
        VDP_SCROLL_UPDATER_INIT Background, lvsusPlaneB
        VDP_SCROLL_UPDATER_INIT Foreground, lvsusPlaneA

        ; Setup VDP vertical scroll
        bsr     _LineVDPScrollUpdaterCommitVScroll

        ; Setup VDP horizontal scroll
        VDP_DMA_TRANSFER_COMMAND_LIST lsPlaneBHScrollDMATransferCommandList
        VDP_DMA_TRANSFER_COMMAND_LIST lsPlaneAHScrollDMATransferCommandList
        rts


;-------------------------------------------------
; Calculate line scroll tables and schedule them for DMA transfer and register scroll commit handler for vertical scroll update
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a0-a6
_LineVDPScrollUpdaterUpdate:
        VDP_SCROLL_UPDATER_UPDATE

        move.w  d0, d1
        andi.w  #VDP_SCROLL_UPDATE_BACKGROUND_V_MASK | VDP_SCROLL_UPDATE_FOREGROUND_V_MASK, d1
        beq     .noVerticalMovement

            VDP_TASK_QUEUE_ADD #_LineVDPScrollUpdaterCommitVScroll, a0

    .noVerticalMovement:

        move.w  d0, d1

        btst    #VDP_SCROLL_UPDATE_BACKGROUND_H, d1
        beq     .noBackgroundHScroll

            VDP_DMA_QUEUE_ADD_COMMAND_LIST lsPlaneBHScrollDMATransferCommandList

    .noBackgroundHScroll:

        btst    #VDP_SCROLL_UPDATE_FOREGROUND_H, d1
        beq     .noForegroundHScroll

            VDP_DMA_QUEUE_ADD_COMMAND_LIST lsPlaneAHScrollDMATransferCommandList

    .noForegroundHScroll:
        rts


;-------------------------------------------------
; Update vertical scroll values
; ----------------
; Input:
; - a0: Viewport
_LineVDPScrollUpdaterCommitVScroll:

        VDP_ADDR_SET WRITE, VSRAM, $00, SIZE_WORD

        ; Update vertical scroll
        move.w  lineVDPScrollUpdaterState + lvsusPlaneA + lsuPlaneVerticalScroll, MEM_VDP_DATA
        move.w  lineVDPScrollUpdaterState + lvsusPlaneB + lsuPlaneVerticalScroll, MEM_VDP_DATA
        rts
