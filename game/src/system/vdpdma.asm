;------------------------------------------------------------------------------------------
; VDP DMA structures/subroutines and macros
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; DMA structures
; ----------------
    DEFINE_STRUCT VDPDMATransfer
        STRUCT_MEMBER.w dataStride
        STRUCT_MEMBER.w length
        STRUCT_MEMBER.l source
        STRUCT_MEMBER.l target
    DEFINE_STRUCT_END

    DEFINE_STRUCT VDPDMATransferCommandList
        STRUCT_MEMBER.w vdpRegAutoInc
        STRUCT_MEMBER.w vdpRegDMALengthHigh
        STRUCT_MEMBER.w vdpRegDMALengthLow
        STRUCT_MEMBER.w vdpRegDMASourceHigh
        STRUCT_MEMBER.w vdpRegDMASourceMid
        STRUCT_MEMBER.w vdpRegDMASourceLow
        STRUCT_MEMBER.l vdpAddrDMATransferDestination
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
; Patch the source address in an existing VDPDMACopyCommandList
; ----------------
VDP_DMA_TRANSFER_COMMAND_LIST_PATCH_SOURCE Macro dmaCommandList, source
        andi.l  #$fffffe, \source
        lsl.l   #7, \source
        move.b  VDPDMATransferCommandList_vdpRegDMALengthLow + 1(\dmaCommandList), \source
        ror.l   #8, \source
        movep.l \source, VDPDMATransferCommandList_vdpRegDMALengthLow + 1(\dmaCommandList)
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
        lea     \vdpDMATransferCommandList, a0
        lea     MEM_VDP_CTRL, a1
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.w  (a0)+, (a1)
    Endm


;-------------------------------------------------
; Start a DMA transfer for the specified VDPDMATransferCommandList of which the address is stored in vdpDMATransferCommandList
; Uses: a0-a1
; ----------------
VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT Macro vdpDMATransferCommandList
        If (~strcmp('\vdpDMATransferCommandList', 'a0'))
            movea.l \vdpDMATransferCommandList, a0
        EndIf

        lea     MEM_VDP_CTRL, a1
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.w  (a0)+, (a1)
    Endm


;-------------------------------------------------
; ROM Safe variant of VDP_DMA_TRANSFER_COMMAND_LIST uses stack memory for the dma trigger word write
; Uses: a0-a1
; ----------------
VDP_DMA_TRANSFER_COMMAND_LIST_ROM_SAFE Macro vdpDMATransferCommandList
        lea     \vdpDMATransferCommandList, a0
        lea     MEM_VDP_CTRL, a1
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.w  (a0)+, -(sp)
        move.w  (sp)+, (a1)
    Endm


;-------------------------------------------------
; ROM Safe variant of VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT uses stack memory for the dma trigger word write
; Uses: a0-a1
; ----------------
VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE Macro vdpDMATransferCommandList
        If (~strcmp('\vdpDMATransferCommandList', 'a0'))
            movea.l \vdpDMATransferCommandList, a0
        EndIf

        lea     MEM_VDP_CTRL, a1
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.w  (a0)+, -(sp)
        move.w  (sp)+, (a1)
    Endm
