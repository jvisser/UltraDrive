;------------------------------------------------------------------------------------------
; VDP DMA queue
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; DMA queue constants
; ----------------
VDP_DMA_QUEUE_SIZE Equ 32


;-------------------------------------------------
; DMA queue data
; ----------------
    DEFINE_VAR FAST
        VAR.VDPDMATransferCommandList   vdpDMAQueue,                VDP_DMA_QUEUE_SIZE
        VAR.w                           vdpDMAQueueCurrentEntry
    DEFINE_VAR_END


;-------------------------------------------------
; Queue DMA job by ref to static/predefined VDPDMATransfer
; ----------------
; Uses: d0/a0-a1
VDP_DMA_QUEUE_ADD Macro dmaTransfer
            OS_LOCK

            movea.w vdpDMAQueueCurrentEntry, a1
            cmpa.w  #vdpDMAQueue + vdpDMAQueue_Size, a1
            beq     .dmaQueueFull\@

            If (~strcmp('\dmaTransfer', 'a0'))
                lea     \dmaTransfer, a0
            EndIf

            ; Write data stride
            move.b  dmaDataStride + 1(a0), vdpRegAutoInc + 1(a1)

            ; Write DMA source. Use vdpRegDMALengthLow as overflow area for high byte (will be overwritten in next step)
            move.l  dmaSource(a0), d0
            movep.l d0, vdpRegDMALengthLow + 1(a1)

            ; Write DMA length in words
            move.w  dmaLength(a0), d0
            movep.w d0, vdpRegDMALengthHigh + 1(a1)

            ; Write DMA target
            move.l  dmaTarget(a0), vdpAddrDMATransferDestination(a1)

            ; Next entry
            addi.w  #VDPDMATransferCommandList_Size, a1
            move.w  a1, vdpDMAQueueCurrentEntry

            If def(debug)
                    bra .dmaQueueDone\@

                .dmaQueueFull\@:
                    DEBUG_MSG 'DMA Queue full'

                .dmaQueueDone\@:
            Else
                .dmaQueueFull\@:
            Endif

            OS_UNLOCK
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
; Queue a DMA job
; ----------------
; Input:
; - a0: Address of the VDPDMATransfer instance to queue
; Uses: d0/a0-a1
VDPDMAQueueAdd:
        VDP_DMA_QUEUE_ADD a0
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
        beq     .dmaTransferComplete        ; Nothing to transfer

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
