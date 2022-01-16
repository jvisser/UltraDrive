;------------------------------------------------------------------------------------------
; VDP DMA queue
;
; Public macros:
; - VDP_DMA_QUEUE_ADD_COMMAND_LIST
; - VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT
; - VDP_DMA_QUEUE_ADD
; - VDP_DMA_QUEUE_ADD_INDIRECT
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_VDP_DMA_QUEUE_INC))
__SYSTEM_VDP_DMA_QUEUE_INC Equ 1

    Include './system/include/os.inc'
    Include './system/include/vdp.inc'

;-------------------------------------------------
; Private: Queue job by VDPDMATransferCommandList
; ----------------
; Uses: a0-a1
__VDP_DMA_QUEUE_ADD_COMMAND_LIST Macro dmaTransferCommandList
            OS_LOCK

            movea.w vdpDMAQueueCurrentEntry, a1
            cmpa.w  #vdpDMAQueue + vdpDMAQueue_Size, a1
            beq.s   .dmaQueueFull\@

            __LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS \dmaTransferCommandList

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
__LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS Macro dmaTransferCommandList
            lea \dmaTransferCommandList, a0
        Endm

        __VDP_DMA_QUEUE_ADD_COMMAND_LIST \dmaTransferCommandList

        Purge __LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS
    Endm


;-------------------------------------------------
; Queue a DMA transfer for the specified VDPDMATransferCommandList of which the address is stored in vdpDMATransferCommandList
; ----------------
; Uses: a0-a1
VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT Macro dmaTransferCommandList
__LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS Macro dmaTransferCommandList
            If (~strcmp('\dmaTransferCommandList', 'a0'))
                movea.l \dmaTransferCommandList, a0
            EndIf
        Endm

        __VDP_DMA_QUEUE_ADD_COMMAND_LIST \dmaTransferCommandList

        Purge __LOAD_DMA_TRANSFER_COMMAND_LIST_ADDRESS
    Endm


;-------------------------------------------------
; Private: Queue DMA job by VDPDMATransfer
; ----------------
; Uses: d0/a0-a1
__VDP_DMA_QUEUE_ADD Macro dmaTransfer
            OS_LOCK

            movea.w vdpDMAQueueCurrentEntry, a1
            cmpa.w  #vdpDMAQueue + vdpDMAQueue_Size, a1
            beq.s   .dmaQueueFull\@

            __LOAD_DMA_TRANSFER_ADDRESS \dmaTransfer

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
__LOAD_DMA_TRANSFER_ADDRESS Macro dmaTransfer
            lea \dmaTransfer, a0
        Endm

        __VDP_DMA_QUEUE_ADD \dmaTransfer

        Purge __LOAD_DMA_TRANSFER_ADDRESS
    Endm


;-------------------------------------------------
; Queue a DMA transfer for the specified VDPDMATransfer of which the address is stored in dmaTransfer
; ----------------
VDP_DMA_QUEUE_ADD_INDIRECT Macro dmaTransfer
__LOAD_DMA_TRANSFER_ADDRESS Macro dmaTransfer
            If (~strcmp('\dmaTransfer', 'a0'))
                movea.l \dmaTransfer, a0
            EndIf
        Endm

        __VDP_DMA_QUEUE_ADD \dmaTransfer

        Purge __LOAD_DMA_TRANSFER_ADDRESS
    Endm

    EndIf
