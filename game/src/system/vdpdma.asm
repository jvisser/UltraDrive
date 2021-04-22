;------------------------------------------------------------------------------------------
; VDP DMA structures/subroutines and macros
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; DMA structures
; ----------------
    DEFINE_STRUCT VDPDMATransfer
        STRUCT_MEMBER.w dmaDataStride
        STRUCT_MEMBER.w dmaLength
        STRUCT_MEMBER.l dmaSource
        STRUCT_MEMBER.l dmaTarget
    DEFINE_STRUCT_END

    DEFINE_STRUCT VDPDMACommandListBase
        STRUCT_MEMBER.w vdpRegAutoInc
        STRUCT_MEMBER.w vdpRegDMALengthHigh
        STRUCT_MEMBER.w vdpRegDMALengthLow
    DEFINE_STRUCT_END

    DEFINE_STRUCT VDPDMATransferCommandListBase, EXTENDS, VDPDMACommandListBase
        STRUCT_MEMBER.w vdpRegDMASourceMid
        STRUCT_MEMBER.w vdpRegDMASourceLow
    DEFINE_STRUCT_END

    DEFINE_STRUCT VDPDMATransferCommandList, EXTENDS, VDPDMATransferCommandListBase
        STRUCT_MEMBER.w vdpRegDMASourceHigh
        STRUCT_MEMBER.l vdpAddrDMATransferDestination
    DEFINE_STRUCT_END

    DEFINE_STRUCT VDPDMACopyCommandList, EXTENDS, VDPDMATransferCommandListBase
        STRUCT_MEMBER.l vdpAddrDMACopyDestination
    DEFINE_STRUCT_END
    
    DEFINE_STRUCT VDPDMAFillCommandList, EXTENDS, VDPDMACommandListBase
        STRUCT_MEMBER.l vdpAddrDMAFillDestination        
    DEFINE_STRUCT_END


;-------------------------------------------------
; Store VDPDMACommandListBase
; ----------------
_VDP_DMA_DEFINE_COMMAND_LIST Macro length, dataStride
        If (strcmp('\dataStride', ''))
            dc.w VDP_CMD_RS_AUTO_INC + $02
        Else
            dc.w VDP_CMD_RS_AUTO_INC + ((\dataStride) & $ff)
        EndIf
        dc.w VDP_CMD_RS_DMA_LEN_H + (((\length) & $ff00) >> 8)
        dc.w VDP_CMD_RS_DMA_LEN_L + ((\length) & $ff)
    Endm


;-------------------------------------------------
; Store VDPDMATransferCommandList target independent register values
; ----------------
_VDP_DMA_DEFINE_TRANSFER_COMMAND_LIST Macro source, length, dataStride
        _VDP_DMA_DEFINE_COMMAND_LIST \length, \dataStride
        
        dc.w VDP_CMD_RS_DMA_SRC_H + ((((\source) >> 1)& $7f0000) >> 16)
        dc.w VDP_CMD_RS_DMA_SRC_M + ((((\source) >> 1)& $ff00) >> 8)
        dc.w VDP_CMD_RS_DMA_SRC_L + (((\source) >> 1) & $ff)
    Endm


;-------------------------------------------------
; Store VRAM DMA target address set command
; ----------------
VDP_DMA_DEFINE_VRAM_TARGET_AS Macro target
        dc.l VDP_CMD_AS_VRAM_WRITE | VDP_CMD_AS_DMA | (((\target) & $3fff) << 16) | (((\target) & $c000) >> 14)
    Endm


;-------------------------------------------------
; Create static VDPDMATransferCommandList data block for VRAM transfer
; ----------------
VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST Macro source, target, length, dataStride
        _VDP_DMA_DEFINE_TRANSFER_COMMAND_LIST \source, \length, \dataStride
        VDP_DMA_DEFINE_VRAM_TARGET_AS \target
    Endm


;-------------------------------------------------
; Create static VDPDMATransferCommandList data block for CRAM transfer
; ----------------
VDP_DMA_DEFINE_CRAM_TRANSFER_COMMAND_LIST Macro source, target, length, dataStride
        _VDP_DMA_DEFINE_TRANSFER_COMMAND_LIST \source, \length, \dataStride
        dc.l VDP_CMD_AS_CRAM_WRITE | VDP_CMD_AS_DMA | ((\target) << 16)
    Endm


;-------------------------------------------------
; Create static VDPDMATransferCommandList data block for VSRAM transfer
; ----------------
VDP_DMA_DEFINE_VSRAM_TRANSFER_COMMAND_LIST Macro source, target, length, dataStride
        _VDP_DMA_DEFINE_TRANSFER_COMMAND_LIST \source, \length, \dataStride
        dc.l VDP_CMD_AS_VSRAM_WRITE | VDP_CMD_AS_DMA | ((\target) << 16)
    Endm


;-------------------------------------------------
; Create static VDPDMAFillCommandList data block for VRAM fill without the fill value
; ----------------
VDP_DMA_DEFINE_VRAM_FILL_COMMAND_LIST Macro target, length, dataStride
        _VDP_DMA_DEFINE_COMMAND_LIST \length, \dataStride
        VDP_DMA_DEFINE_VRAM_TARGET_AS \target
    Endm


;-------------------------------------------------
; Create static VDPDMACopyCommandList data block for VRAM copy
; ----------------
VDP_DMA_DEFINE_VRAM_COPY_COMMAND_LIST Macro source, target, length, dataStride
        _VDP_DMA_DEFINE_COMMAND_LIST \length, \dataStride
        dc.w VDP_CMD_RS_DMA_SRC_M + ((((\source) >> 1)& $ff00) >> 8)
        dc.w VDP_CMD_RS_DMA_SRC_L + (((\source) >> 1) & $ff)
        VDP_DMA_DEFINE_VRAM_TARGET_AS \target
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer for 68000->VRAM transfer
; ----------------
VDP_DMA_DEFINE_VRAM_TRANSFER Macro source, target, length, dataStride
        If (narg = 4)
            dc.w \dataStride
        Else
            dc.w 2
        EndIf
        dc.w \length
        dc.l ((\source) >> 1) & $7fffff
        dc.l VDP_CMD_AS_VRAM_WRITE | VDP_CMD_AS_DMA | (((\target) & $3fff) << 16) | (((\target) & $c000) >> 14)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer for 68000->CRAM transfer
; ----------------
VDP_DMA_DEFINE_CRAM_TRANSFER Macro source, target, length, dataStride
        If (narg = 4)
            dc.w \dataStride
        Else
            dc.w 2
        EndIf
        dc.w \length
        dc.l ((\source) >> 1) & $7fffff
        dc.l VDP_CMD_AS_CRAM_WRITE | VDP_CMD_AS_DMA | ((\target) << 16)
    Endm


;-------------------------------------------------
; Create static VDPDMATransfer for 68000->VSRAM transfer
; ----------------
VDP_DMA_DEFINE_VSRAM_TRANSFER Macro source, target, length, dataStride
        If (narg = 4)
            dc.w \dataStride
        Else
            dc.w 2
        EndIf
        dc.w \length
        dc.l ((\source) >> 1) & $7fffff
        dc.l VDP_CMD_AS_VSRAM_WRITE | VDP_CMD_AS_DMA | ((\target) << 16)
    Endm


;-------------------------------------------------
; Start a DMA transfer for the specified VDPDMATransferCommandList
; Uses: a0-a1
; ----------------
VDP_DMA_TRANSFER_COMMAND_LIST Macro vdpDMATransferCommandList
        If (~strcmp('\vdpDMATransferCommandList', 'a0'))
            lea     \vdpDMATransferCommandList, a0
        EndIf

        lea     MEM_VDP_CTRL, a1
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.w  (a0)+, (a1)
    Endm


;-------------------------------------------------
; Start a DMA fill operation for the specified VDPDMAFillCommandList with the given fill value
; Uses: a0-a1
; ----------------
VDP_DMA_FILL_COMMAND_LIST Macro vdpDMAFillCommandList, value
        If (~strcmp('\vdpDMAFillCommandList', 'a0'))
            lea     \vdpDMAFillCommandList, a0
        EndIf

        lea     MEM_VDP_CTRL, a1
        move.w  #VDP_CMD_RS_DMA_SRC_H | DMA_SRC_H_FILL, (a1)
        move.w  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  \value, MEM_VDP_DATA
    Endm


;-------------------------------------------------
; Start a DMA copy operation for the specified VDPDMACopyCommandList
; Uses: a0-a1
; ----------------
VDP_DMA_COPY_COMMAND_LIST Macro vdpDMACopyCommandList
        If (~strcmp('\vdpDMACopyCommandList', 'a0'))
            lea     \vdpDMACopyCommandList, a0
        EndIf

        lea     MEM_VDP_CTRL, a1
        move.w  #VDP_CMD_RS_DMA_SRC_H | DMA_SRC_H_COPY, (a1)
        move.w  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.w  (a0)+, (a1)
    Endm
