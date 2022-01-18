;------------------------------------------------------------------------------------------
; VDP DMA queue
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

    Include './common/include/debug.inc'

    Include './system/include/vdpdmaqueue.inc'
    Include './system/include/os.inc'

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
        VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT.l a0
        rts


;-------------------------------------------------
; Queue a DMA job by VDPDMATransfer
; ----------------
; Input:
; - a0: Address of the VDPDMATransfer instance to queue
; Uses: d0/a0-a1
VDPDMAQueueAdd:
        VDP_DMA_QUEUE_ADD_INDIRECT.l a0
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
