;------------------------------------------------------------------------------------------
; VDP Task queue. Tasks that need to be executed during vertical blanking period
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; VDP Task queue constants
; ----------------
VDP_TASK_QUEUE_SIZE Equ 32


;-------------------------------------------------
; VDP Task queue data
; ----------------
    DEFINE_VAR FAST
        VAR.l   vdpTaskQueue,                VDP_TASK_QUEUE_SIZE
        VAR.w   vdpTaskQueueCurrentEntry
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize the VDP task queue
; ----------------
; Uses: a1
VDPTaskQueueInit:
    move.w  #vdpTaskQueue, vdpTaskQueueCurrentEntry
    rts


;-------------------------------------------------
; Queue VDP Task job (inline)
; ----------------
; Uses: a1
VDP_TASK_QUEUE_JOB Macro jobAddress
            OS_LOCK

            movea.w vdpTaskQueueCurrentEntry, a1
            cmpa.w  #vdpTaskQueue + vdpTaskQueue_Size, a1
            beq     .vdpTaskQueueFull\@

            move.l  \jobAddress, (a1)+
            move.w  a1, vdpTaskQueueCurrentEntry

            If def(debug)
                    bra .vpdTaskQueueDone\@

                .vdpTaskQueueFull\@:
                    DEBUG_MSG 'VDP Task Queue full'

                .vpdTaskQueueDone\@:
            Else
                .vdpTaskQueueFull\@:
            Endif

            OS_UNLOCK
    Endm


;-------------------------------------------------
; Queue a VDP job
; ----------------
; Input:
; - a0: Address of the job callback
; Uses: a1
VDPTaskQueueJob:
        VDP_TASK_QUEUE_JOB a0
        rts


;-------------------------------------------------
; Process the VDP task queue.
; ----------------
; Uses: d0-d7/a0-a6
VDPTaskQueueProcess:
        OS_LOCK

        lea     vdpTaskQueue, a0
        move.w  vdpTaskQueueCurrentEntry, a1
        cmpa    a0, a1
        beq     .vdpTaskTransferComplete        ; Nothing to transfer

        move.w  a0, vdpTaskQueueCurrentEntry

    .vdpTaskLoop:
        move.l  (a0)+, a3

        PUSHM   a0-a1
        jsr     (a3)
        POPM    a0-a1

        cmpa    a0, a1
        bne .vdpTaskLoop

    .vdpTaskTransferComplete:

        OS_UNLOCK
        rts
