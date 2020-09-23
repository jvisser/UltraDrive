;------------------------------------------------------------------------------------------
; VDP DMA macros/routines
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; DMA transfer structure
; ----------------
    DEFINE_STRUCT VDPDMATransfer
        STRUCT_MEMBER.w vdpRegDMALengthHigh
        STRUCT_MEMBER.w vdpRegDMALengthLow
        STRUCT_MEMBER.w vdpRegDMASourceHigh
        STRUCT_MEMBER.w vdpRegDMASourceMid
        STRUCT_MEMBER.w vdpRegDMASourceLow
        STRUCT_MEMBER.l vdpDMATarget
    DEFINE_STRUCT_END


;-------------------------------------------------
; Store register values
; ----------------
_VDP_STATIC_TRANSFER_SETREGS Macro source, length
        dc.w VDP_CMD_RS_DMA_LEN_H + ((\length & $ff00) >> 8)
        dc.w VDP_CMD_RS_DMA_LEN_L + (\length & $ff)
        dc.w VDP_CMD_RS_DMA_SRC_H + (((\source >> 1)& $7f0000) >> 16)
        dc.w VDP_CMD_RS_DMA_SRC_M + (((\source >> 1)& $ff00) >> 8)
        dc.w VDP_CMD_RS_DMA_SRC_L + ((\source >> 1) & $ff)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer data block for VRAM transfer
; ----------------
VDP_DEFINE_STATIC_DMA_VRAM_TRANSFER Macro source, target, length
        _VDP_STATIC_TRANSFER_SETREGS \source, \length
        dc.l VDP_CMD_AS_VRAM_WRITE | VDP_CMD_AS_DMA | ((\target & $3fff) << 16) | ((\target & $c000) >> 14)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer data block for CRAM transfer
; ----------------
VDP_DEFINE_STATIC_DMA_CRAM_TRANSFER Macro source, target, length
        _VDP_STATIC_TRANSFER_SETREGS \source, \length
        dc.l VDP_CMD_AS_CRAM_WRITE | VDP_CMD_AS_DMA | (\target << 16)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer data block for VSRAM transfer
; ----------------
VDP_DEFINE_STATIC_DMA_VSRAM_TRANSFER Macro source, target, length
        _VDP_STATIC_TRANSFER_SETREGS \source, \length
        dc.l VDP_CMD_AS_VSRAM_WRITE | VDP_CMD_AS_DMA | (\target << 16)
    Endm


;-------------------------------------------------
; Start a DMA transfer for the specified VDPDMATransfer
; Uses: a0-a1
; ----------------
VDP_STATIC_DMA_TRANSFER Macro vdpDMATransferBlockAddress
        lea     vdpDMATransferBlockAddress, a0
        lea     MEM_VDP_CTRL, a1
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.l  (a0)+, (a1)
    Endm
