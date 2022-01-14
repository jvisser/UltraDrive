;------------------------------------------------------------------------------------------
; VDP DMA queue
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

    Include './common/include/debug.inc'

;-------------------------------------------------
; DMA queue constants
; ----------------
VDP_DMA_QUEUE_SIZE Equ 32


;-------------------------------------------------
; DMA queue data
; ----------------
    DEFINE_VAR SHORT
        VAR.VDPDMATransferCommandList   vdpDMAQueue,                VDP_DMA_QUEUE_SIZE
        VAR.w                           vdpDMAQueueCurrentEntry
    DEFINE_VAR_END


;-------------------------------------------------
; Queue job by VDPDMATransferCommandList
; ----------------
; Uses: a0-a1
_VDP_DMA_QUEUE_ADD_COMMAND_LIST Macro dmaTransferCommandList
            OS_LOCK

            movea.w vdpDMAQueueCurrentEntry, a1
            cmpa.w  #vdpDMAQueue + vdpDMAQueue_Size, a1
            beq.s   .dmaQueueFull\@

            _LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS \dmaTransferCommandList

            move.l  (a0)+, (a1)+
            move.l  (a0)+, (a1)+
            move.l  (a0)+, (a1)+
            move.l  (a0)+, (a1)+

            move.w  a1, vdpDMAQueueCurrentEntry

            If def(debug)
                    bra.s .dmaQueueDone\@

                .dmaQueueFull\@:
                    DEBUG_MSG 'VDP_DMA_QUEUE_ADD_CMD_LIST: DMA Queue full'

                .dmaQueueDone\@:
            Else
                .dmaQueueFull\@:
            Endif
            OS_UNLOCK
    Endm

;-------------------------------------------------
; Queue a DMA transfer for the specified VDPDMATransferCommandList
; ----------------
; Uses: a0-a1
VDP_DMA_QUEUE_ADD_COMMAND_LIST Macro dmaTransferCommandList
_LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS Macro dmaTransferCommandList
            lea \dmaTransferCommandList, a0
        Endm

        _VDP_DMA_QUEUE_ADD_COMMAND_LIST \dmaTransferCommandList

        Purge _LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS
    Endm


;-------------------------------------------------
; Queue a DMA transfer for the specified VDPDMATransferCommandList of which the address is stored in vdpDMATransferCommandList
; ----------------
; Uses: a0-a1
VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT Macro dmaTransferCommandList
_LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS Macro dmaTransferCommandList
            If (~strcmp('\dmaTransferCommandList', 'a0'))
                movea.l \dmaTransferCommandList, a0
            EndIf
        Endm

        _VDP_DMA_QUEUE_ADD_COMMAND_LIST \dmaTransferCommandList

        Purge _LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS
    Endm


;-------------------------------------------------
; Queue DMA job by VDPDMATransfer
; ----------------
; Uses: d0/a0-a1
_VDP_DMA_QUEUE_ADD Macro dmaTransfer
            OS_LOCK

            movea.w vdpDMAQueueCurrentEntry, a1
            cmpa.w  #vdpDMAQueue + vdpDMAQueue_Size, a1
            beq.s   .dmaQueueFull\@

            _LOAD_DMA_TRANSFER_ADDRESS \dmaTransfer

            ; Write data stride
            move.b  VDPDMATransfer_dataStride + 1(a0), VDPDMATransferCommandList_vdpRegAutoInc + 1(a1)

            ; Write DMA source. Use vdpRegDMALengthLow as overflow area for high byte (will be overwritten in next step)
            move.l  VDPDMATransfer_source(a0), d0
            movep.l d0, VDPDMATransferCommandList_vdpRegDMALengthLow + 1(a1)

            ; Write DMA length in words
            move.w  VDPDMATransfer_length(a0), d0
            movep.w d0, VDPDMATransferCommandList_vdpRegDMALengthHigh + 1(a1)

            ; Write DMA target
            move.l  VDPDMATransfer_target(a0), VDPDMATransferCommandList_vdpAddrDMATransferDestination(a1)

            ; Next entry
            addi.w  #VDPDMATransferCommandList_Size, a1
            move.w  a1, vdpDMAQueueCurrentEntry

            If def(debug)
                    bra.s .dmaQueueDone\@

                .dmaQueueFull\@:
                    DEBUG_MSG 'VDP_DMA_QUEUE_ADD: DMA Queue full'

                .dmaQueueDone\@:
            Else
                .dmaQueueFull\@:
            Endif

            OS_UNLOCK
    Endm


;-------------------------------------------------
; Queue a DMA transfer for the specified VDPDMATransfer
; ----------------
VDP_DMA_QUEUE_ADD Macro dmaTransfer
_LOAD_DMA_TRANSFER_ADDRESS Macro dmaTransfer
            lea \dmaTransfer, a0
        Endm

        _VDP_DMA_QUEUE_ADD \dmaTransfer

        Purge _LOAD_DMA_TRANSFER_ADDRESS
    Endm


;-------------------------------------------------
; Queue a DMA transfer for the specified VDPDMATransfer of which the address is stored in dmaTransfer
; ----------------
VDP_DMA_QUEUE_ADD_INDIRECT Macro dmaTransfer
_LOAD_DMA_TRANSFER_ADDRESS Macro dmaTransfer
            If (~strcmp('\dmaTransfer', 'a0'))
                movea.l \dmaTransfer, a0
            EndIf
        Endm

        _VDP_DMA_QUEUE_ADD \dmaTransfer

        Purge _LOAD_DMA_TRANSFER_ADDRESS
    Endm


;-------------------------------------------------
; Initialize the DMA queue
; ----------------
VDPDMAQueueInit:
        lea     vdpDMAQueue, a0
        moveq   #VDP_DMA_QUEUE_SIZE - 1, d0

    .initDMAQueueEntryLoop:

        ; VDPDMATransferCommandList
        move.w  #VDP_CMD_RS_AUTO_INC,  (a0)+    ; vdpRegIncr
        move.w  #VDP_CMD_RS_DMA_LEN_H, (a0)+    ; vdpRegDMALengthHigh
        move.w  #VDP_CMD_RS_DMA_LEN_L, (a0)+    ; vdpRegDMALengthLow
        move.w  #VDP_CMD_RS_DMA_SRC_H, (a0)+    ; vdpRegDMASourceHigh
        move.w  #VDP_CMD_RS_DMA_SRC_M, (a0)+    ; vdpRegDMASourceMid
        move.w  #VDP_CMD_RS_DMA_SRC_L, (a0)+    ; vdpRegDMASourceLow
        move.l  #0, (a0)+                       ; vdpAddrDMADestination
        dbra    d0, .initDMAQueueEntryLoop

        move.w  #vdpDMAQueue, vdpDMAQueueCurrentEntry
        rts


;-------------------------------------------------
; Queue a DMA job by VDPDMATransferCommandList
; ----------------
; Input:
; - a0: Address of the VDPDMATransferCommandList instance to queue
; Uses: a0-a1
VDPDMAQueueAddCommandList:
        VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT a0
        rts


;-------------------------------------------------
; Queue a DMA job by VDPDMATransfer
; ----------------
; Input:
; - a0: Address of the VDPDMATransfer instance to queue
; Uses: d0/a0-a1
VDPDMAQueueAdd:
        VDP_DMA_QUEUE_ADD_INDIRECT a0
        rts


;-------------------------------------------------
; Flush the DMA queue.
; ----------------
; Uses: a0-a2
VDPDMAQueueFlush:
        OS_LOCK

        lea     vdpDMAQueue, a0
        move.w  vdpDMAQueueCurrentEntry, a2
        cmpa    a0, a2
        beq.s   .dmaTransferComplete        ; Nothing to transfer

        move.w  a0, vdpDMAQueueCurrentEntry

        lea     MEM_VDP_CTRL, a1

    .dmaTransferLoop:
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.w  (a0)+, (a1)
        cmpa    a0, a2
        bne .dmaTransferLoop

    .dmaTransferComplete:

        OS_UNLOCK
        rts
