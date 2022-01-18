;------------------------------------------------------------------------------------------
; Horizontal line VDPScrollUpdater implementation. Updates the horizontal VDP scroll values for both cameras.
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'
    Include './system/include/vdp.inc'

    Include './engine/include/vdpscroll.inc'

;-------------------------------------------------
; Horizontal line VDPScrollUpdater structures
; ----------------

    ;-------------------------------------------------
    ; Horizontal line scroll table/state structure
    ; ----------------
    DEFINE_STRUCT LineHorizontalVDPScrollUpdaterPlaneState
        STRUCT_MEMBER.w     hlsuLineHorizontalScroll, 224            ; NB: Horizontal scroll values must be negated by the ScrollValueUpdater for performance reasons
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Horizontal line VDPScrollUpdater definition
    ; ----------------
    ; struct VDPScrollUpdater
    lineHorizontalVDPScrollUpdater:
        ; .init
        dc.l _LineHorizontalVDPScrollUpdaterInit
        ; .update
        dc.l _LineHorizontalVDPScrollUpdaterUpdate

    ;-------------------------------------------------
    ; Horizontal line DMA command list templates
    ; ----------------
    lsPlaneBScrollDMATransferCommandListTemplate:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST 0, VDP_HSCROLL_ADDR + SIZE_WORD, LineHorizontalVDPScrollUpdaterPlaneState_Size / SIZE_WORD, SIZE_WORD * 2

    lsPlaneAScrollDMATransferCommandListTemplate:
        VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST 0, VDP_HSCROLL_ADDR, LineHorizontalVDPScrollUpdaterPlaneState_Size / SIZE_WORD, SIZE_WORD * 2


;-------------------------------------------------
; Setup buffers and correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
; - a1: Scroll configuration
_LineHorizontalVDPScrollUpdaterInit:
        ; Enable horizontal line scroll mode
        VDP_REG_SET_BIT_FIELD vdpRegMode3, MODE3_HSCROLL_MASK, MODE3_HSCROLL_LINE

        ; Initialize background
        VDP_SCROLL_DMA_UPDATER_INIT                         &
            Horizontal,                                     &
            background,                                     &
            LineHorizontalVDPScrollUpdaterPlaneState,       &
            lsPlaneBScrollDMATransferCommandListTemplate

        ; Initialize foreground
        VDP_SCROLL_DMA_UPDATER_INIT                         &
            Horizontal,                                     &
            foreground,                                     &
            LineHorizontalVDPScrollUpdaterPlaneState,       &
            lsPlaneAScrollDMATransferCommandListTemplate
        rts


;-------------------------------------------------
; Calculate line scroll tables and schedule them for DMA transfer
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a0-a6
_LineHorizontalVDPScrollUpdaterUpdate:
        VDP_SCROLL_DMA_UPDATER_UPDATE Horizontal
        rts

