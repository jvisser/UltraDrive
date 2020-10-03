;------------------------------------------------------------------------------------------
; VDP DMA structures/subroutines and macros
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; DMA structures
; ----------------
    DEFINE_STRUCT VDPDMATransfer
        STRUCT_MEMBER.w dmaLength
        STRUCT_MEMBER.l dmaSource
        STRUCT_MEMBER.l dmaTarget
    DEFINE_STRUCT_END

    ; DMA queue entry
    DEFINE_STRUCT VDPDMATransferCommandList
        STRUCT_MEMBER.w vdpRegDMALengthHigh
        STRUCT_MEMBER.w vdpRegDMALengthLow
        STRUCT_MEMBER.w vdpRegDMASourceHigh
        STRUCT_MEMBER.w vdpRegDMASourceMid
        STRUCT_MEMBER.w vdpRegDMASourceLow
        STRUCT_MEMBER.l vdpAddrDMADestination
    DEFINE_STRUCT_END


;-------------------------------------------------
; Store register values
; ----------------
_VDP_DMA_DEFINE_COMMAND_REGS Macro source, length
        dc.w VDP_CMD_RS_DMA_LEN_H + ((\length & $ff00) >> 8)
        dc.w VDP_CMD_RS_DMA_LEN_L + (\length & $ff)
        dc.w VDP_CMD_RS_DMA_SRC_H + (((\source >> 1)& $7f0000) >> 16)
        dc.w VDP_CMD_RS_DMA_SRC_M + (((\source >> 1)& $ff00) >> 8)
        dc.w VDP_CMD_RS_DMA_SRC_L + ((\source >> 1) & $ff)
    Endm


;-------------------------------------------------
; Create static VDPDMATransferCommandList data block for VRAM transfer
; ----------------
VDP_DMA_DEFINE_VRAM_COMMAND_LIST Macro source, target, length
        _VDP_DMA_DEFINE_COMMAND_REGS \source, \length
        dc.l VDP_CMD_AS_VRAM_WRITE | VDP_CMD_AS_DMA | ((\target & $3fff) << 16) | ((\target & $c000) >> 14)
    Endm


;-------------------------------------------------
; Create static VDPDMATransferCommandList data block for CRAM transfer
; ----------------
VDP_DMA_DEFINE_CRAM_COMMAND_LIST Macro source, target, length
        _VDP_DMA_DEFINE_COMMAND_REGS \source, \length
        dc.l VDP_CMD_AS_CRAM_WRITE | VDP_CMD_AS_DMA | (\target << 16)
    Endm


;-------------------------------------------------
; Create static VDPDMATransferCommandList data block for VSRAM transfer
; ----------------
VDP_DMA_DEFINE_VSRAM_COMMAND_LIST Macro source, target, length
        _VDP_DMA_DEFINE_COMMAND_REGS \source, \length
        dc.l VDP_CMD_AS_VSRAM_WRITE | VDP_CMD_AS_DMA | (\target << 16)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer for 68000->VRAM transfer
; ----------------
VDP_DMA_DEFINE_VRAM_TRANSFER Macro source, target, length
        dc.w \length
        dc.l (\source >> 1)
        dc.l VDP_CMD_AS_VRAM_WRITE | VDP_CMD_AS_DMA | ((\target & $3fff) << 16) | ((\target & $c000) >> 14)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer for 68000->CRAM transfer
; ----------------
VDP_DMA_DEFINE_CRAM_TRANSFER Macro source, target, length
        dc.w \length
        dc.l (\source >> 1)
        dc.l VDP_CMD_AS_CRAM_WRITE | VDP_CMD_AS_DMA | (\target << 16)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer for 68000->VSRAM transfer
; ----------------
VDP_DMA_DEFINE_VSRAM_TRANSFER Macro source, target, length
        dc.w \length
        dc.l (\source >> 1)
        dc.l VDP_CMD_AS_VSRAM_WRITE | VDP_CMD_AS_DMA | (\target << 16)
    Endm


;-------------------------------------------------
; Start a DMA transfer for the specified VDPDMATransfer
; Uses: a0-a1
; ----------------
VDP_DMA_TRANSFER_COMMAND_LIST Macro vdpDMATransferCommandList
        If (~strcmp('\vdpDMATransferCommandList', 'a0'))
            lea     vdpDMATransferCommandList, a0
        EndIf

        lea     MEM_VDP_CTRL, a1
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.l  (a0)+, (a1)
    Endm
