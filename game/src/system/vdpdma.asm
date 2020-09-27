;------------------------------------------------------------------------------------------
; VDP DMA macros/routines
; TODO: Add 128k address boundary check
;
; NB: Length is specified in words
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; DMA queue data
; ----------------
VDP_DMA_QUEUE_SIZE Equ 32

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

    ; Allocate DMA queue
    DEFINE_VAR FAST
        STRUCT  VDPDMATransferCommandList,  vdpDMAQueue, VDP_DMA_QUEUE_SIZE
        VAR.w                               vdpDMAQueueCurrentEntry
    DEFINE_VAR_END


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
; Queue DMA job by ref to static/predefined VDPDMATransfer
; ----------------
; Uses: d0/a0-a1
VDP_DMA_QUEUE_JOB Macro dmaTransfer
            movea.w vdpDMAQueueCurrentEntry, a1
            cmpa.w  #vdpDMAQueue + vdpDMAQueue_Size, a1
            beq     .dmaQueueFull\@

            M68K_DISABLE_INT    ; VInt lock

        If (~strcmp('\dmaTransfer', 'a0'))
            lea     \dmaTransfer, a0
        Endif

            ; Write DMA source. Use vdpRegDMALengthLow as overflow area for high byte (will be overwritten in next step)
            move.l  dmaSource(a0), d0
            movep.l d0, vdpRegDMALengthLow + 1(a1)

            ; Write DMA length in words
            move.w  dmaLength(a0), d0
            movep.w d0, vdpRegDMALengthHigh + 1(a1)

            ; Write DMA target
            move.l  dmaTarget(a0), vdpAddrDMADestination(a1)

            ; Next entry
            addi.w  #VDPDMATransferCommandList_Size, a1
            move.w  a1, vdpDMAQueueCurrentEntry

            M68K_ENABLE_INT

    If def(debug)
            bra .dmaQueueDone\@

        .dmaQueueFull\@:
            DEBUG_MSG 'DMA Queue full'

        .dmaQueueDone\@:
    Else
        .dmaQueueFull\@:
    Endif
    Endm


;-------------------------------------------------
; Initialize the DMA queue
; ----------------
VDPDMAQueueInit:
        lea     vdpDMAQueue, a0
        moveq   #VDP_DMA_QUEUE_SIZE - 1, d0

    .initDMAQueueEntryLoop:

        ; VDPDMATransferCommandList
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
; Queue a job
; ----------------
; Input:
; - a0: Address of the VDPDMATransfer instance to queue
; Uses: d0/a0-a1
VDPDMAQueueJob:
        VDP_DMA_QUEUE_JOB a0
        rts


;-------------------------------------------------
; Flush the DMA queue. Should only be called from the 68000 VInt handler.
; ----------------
; Uses: a0-a2
VDPDMAFlushQueue:
        lea     vdpDMAQueue, a0
        move.w  vdpDMAQueueCurrentEntry, a2
        cmpa    a0, a2
        beq     .dmaTransferComplete        ; Nothing to transfer

        move.w  a0, vdpDMAQueueCurrentEntry

        lea     MEM_VDP_CTRL, a1
        move    #VDP_CMD_RS_AUTO_INC | SIZE_WORD, (a1)

    .dmaTransferLoop:
        move.l  (a0)+, (a1)
        move.l  (a0)+, (a1)
        move.w  (a0)+, (a1)
        move.l  (a0)+, (a1)
        cmpa    a0, a2
        bne .dmaTransferLoop

    .dmaTransferComplete:
        rts
