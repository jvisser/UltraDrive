;------------------------------------------------------------------------------------------
; VDP Task queue. Tasks that need to be executed during vertical blanking period
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; VDP Task queue constants
; ----------------
VDP_TASK_QUEUE_SIZE Equ 32


;-------------------------------------------------
; VDP Task queue structures
; ----------------
    DEFINE_STRUCT VDPTask
        STRUCT_MEMBER.l task
        STRUCT_MEMBER.l taskData
    DEFINE_STRUCT_END

    DEFINE_VAR SHORT
        VAR.VDPTask vdpTaskQueue,                VDP_TASK_QUEUE_SIZE
        VAR.w       vdpTaskQueueCurrentEntry
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize the VDP task queue
; ----------------
; Uses: a1
VDPTaskQueueInit:
    move.w  #vdpTaskQueue, vdpTaskQueueCurrentEntry
    rts


;-------------------------------------------------
; Queue VDP Task (inline)
; ----------------
; Uses: a6
VDP_TASK_QUEUE_ADD Macro jobAddress, jobData
            OS_LOCK

            movea.w vdpTaskQueueCurrentEntry, a6
            cmpa.w  #vdpTaskQueue + vdpTaskQueue_Size, a6
            beq     .vdpTaskQueueFull\@

            move.l  \jobAddress, (a6)+
            If (narg = 1)
                addq.l  #SIZE_LONG, a6
            Else
                move.l  \jobData, (a6)+
            EndIf
            move.w  a6, vdpTaskQueueCurrentEntry

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
; Queue a VDP task
; ----------------
; Input:
; - a0: Address of the job callback
; - a1: Data address to associate with the job
; Uses: a1
VDPTaskQueueAdd:
        VDP_TASK_QUEUE_ADD a0, a1
        rts


;-------------------------------------------------
; Process the VDP task queue.
; ----------------
; Uses: d0-d7/a0-a6 (Unknown due to delegation)
VDPTaskQueueProcess:
        OS_LOCK

        lea     vdpTaskQueue, a1
        move.w  vdpTaskQueueCurrentEntry, a2
        cmpa    a1, a2
        beq     .vdpTaskTransferComplete        ; Nothing to transfer

        move.w  a1, vdpTaskQueueCurrentEntry

    .vdpTaskLoop:
        move.l  (a1)+, a3
        move.l  (a1)+, a0

        PUSHL   a1
        PUSHL   a2
        jsr     (a3)
        POPL    a2
        POPL    a1

        cmpa    a1, a2
        bne .vdpTaskLoop

    .vdpTaskTransferComplete:

        OS_UNLOCK
        rts
