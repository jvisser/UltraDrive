;------------------------------------------------------------------------------------------
; Vertical cell scroll updater. Updates the vertical VDP scroll values for both cameras.
; NB: There is a bug in older hardware revisions that causes the first column to have a random scroll value in h40 mode. (0 in h32)
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Line scroll structures
; ----------------
    DEFINE_STRUCT CellVerticalVDPScrollUpdaterPlaneState
        STRUCT_MEMBER.w     vcsuCellVerticalScroll, 20
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.l cvsPlaneBScrollDMATransferCommandListAddress
        VAR.l cvsPlaneAScrollDMATransferCommandListAddress
    DEFINE_VAR_END

    ; struct VDPScrollUpdater
    cellVerticalVDPScrollUpdater:
        ; .vdpsuInit
        dc.l _CellVerticalVDPScrollUpdaterInit
        ; .vdpsuUpdate
        dc.l _CellVerticalVDPScrollUpdaterUpdate

CVS_LINE_BUFFER_SIZE Equ CellVerticalVDPScrollUpdaterPlaneState_Size

    cvsPlaneBScrollDMATransferCommandListTemplate:
        VDP_DMA_DEFINE_VSRAM_TRANSFER_COMMAND_LIST 0, SIZE_WORD, CVS_LINE_BUFFER_SIZE / SIZE_WORD, SIZE_WORD * 2

    cvsPlaneAScrollDMATransferCommandListTemplate:
        VDP_DMA_DEFINE_VSRAM_TRANSFER_COMMAND_LIST 0, 0, CVS_LINE_BUFFER_SIZE / SIZE_WORD, SIZE_WORD * 2


;-------------------------------------------------
; Setup buffers and correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
; - a1: Scroll configuration
_CellVerticalVDPScrollUpdaterInit:
        ; Enable vertical cell scroll mode
        VDP_REG_SET_BITS vdpRegMode3, MODE3_VSCROLL_CELL

        ; Disable column 0 to mask first 2 colum scroll bug some what
        ;VDP_REG_SET_BITS vdpRegMode1, MODE1_DISABLE_COLUMN0

        ; Initialize background
        VDP_SCROLL_DMA_UPDATER_INIT                         &
            Vertical,                                       &
            Background,                                     &
            CellVerticalVDPScrollUpdaterPlaneState,         &
            cvsPlaneBScrollDMATransferCommandListTemplate,  &
            cvsPlaneBScrollDMATransferCommandListAddress

        ; Initialize foreground
        VDP_SCROLL_DMA_UPDATER_INIT                         &
            Vertical,                                       &
            Foreground,                                     &
            CellVerticalVDPScrollUpdaterPlaneState,         &
            cvsPlaneAScrollDMATransferCommandListTemplate,  &
            cvsPlaneAScrollDMATransferCommandListAddress
        rts


;-------------------------------------------------
; Calculate cell scroll tables and schedule them for DMA transfer
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a0-a6
_CellVerticalVDPScrollUpdaterUpdate:
        VDP_SCROLL_DMA_UPDATER_UPDATE                       &
            Vertical,                                       &
            cvsPlaneBScrollDMATransferCommandListAddress,   &
            cvsPlaneAScrollDMATransferCommandListAddress
        rts

