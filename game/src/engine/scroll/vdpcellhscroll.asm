;------------------------------------------------------------------------------------------
; Horizontal cell scroll updater. Updates the horizontal VDP scroll values for both cameras.
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'
    Include './system/include/vdp.inc'

    Include './engine/include/vdpscroll.inc'

;-------------------------------------------------
; Line scroll structures
; ----------------
    DEFINE_STRUCT CellHorizontalVDPScrollUpdaterPlaneState
        STRUCT_MEMBER.w     hcsuCellHorizontalScroll, 28        ; NB: Horizontal scroll values must be negated by the ScrollValueUpdater for performance reasons
    DEFINE_STRUCT_END

    DEFINE_VAR SHORT
        VAR.l chsPlaneBScrollDMATransferCommandListAddress
        VAR.l chsPlaneAScrollDMATransferCommandListAddress
    DEFINE_VAR_END

    ;-------------------------------------------------
    ; Horizontal cell VDPScrollUpdater
    ; ----------------
    ; struct VDPScrollUpdater
    cellHorizontalVDPScrollUpdater:
        ; .init
        dc.l _CellHorizontalVDPScrollUpdaterInit
        ; .update
        dc.l _CellHorizontalVDPScrollUpdaterUpdate

CHS_LINE_BUFFER_SIZE Equ CellHorizontalVDPScrollUpdaterPlaneState_Size

    chsPlaneBScrollDMATransferCommandListTemplate:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST 0, VDP_HSCROLL_ADDR + SIZE_WORD, CHS_LINE_BUFFER_SIZE / SIZE_WORD, SIZE_WORD * 16

    chsPlaneAScrollDMATransferCommandListTemplate:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST 0, VDP_HSCROLL_ADDR, CHS_LINE_BUFFER_SIZE / SIZE_WORD, SIZE_WORD * 16


;-------------------------------------------------
; Setup buffers and correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
; - a1: Scroll configuration
_CellHorizontalVDPScrollUpdaterInit:
        ; Enable horizontal cell scroll mode
        VDP_REG_SET_BIT_FIELD vdpRegMode3, MODE3_HSCROLL_MASK, MODE3_HSCROLL_CELL

        ; Initialize background
        VDP_SCROLL_DMA_UPDATER_INIT                         &
            Horizontal,                                     &
            background,                                     &
            CellHorizontalVDPScrollUpdaterPlaneState,       &
            chsPlaneBScrollDMATransferCommandListTemplate,  &
            chsPlaneBScrollDMATransferCommandListAddress

        ; Initialize foreground
        VDP_SCROLL_DMA_UPDATER_INIT                         &
            Horizontal,                                     &
            foreground,                                     &
            CellHorizontalVDPScrollUpdaterPlaneState,       &
            chsPlaneAScrollDMATransferCommandListTemplate,  &
            chsPlaneAScrollDMATransferCommandListAddress
        rts


;-------------------------------------------------
; Calculate cell scroll tables and schedule them for DMA transfer
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a0-a6
_CellHorizontalVDPScrollUpdaterUpdate:
        VDP_SCROLL_DMA_UPDATER_UPDATE                       &
            Horizontal,                                     &
            chsPlaneBScrollDMATransferCommandListAddress,   &
            chsPlaneAScrollDMATransferCommandListAddress
        rts

