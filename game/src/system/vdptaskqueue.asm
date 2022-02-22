;------------------------------------------------------------------------------------------
; VDP Task queue. Tasks that need to be executed during vertical blanking period
;------------------------------------------------------------------------------------------

    Include './lib/common/include/debug.inc'

    Include './system/include/init.inc'
    Include './system/include/vdptaskqueue.inc'
    Include './system/include/m68k.inc'
    Include './system/include/os.inc'

;-------------------------------------------------
; VDP Task queue constants
; ----------------
VDP_TASK_QUEUE_SIZE Equ 32


;-------------------------------------------------
; VDP Task queue state
; ----------------
    DEFINE_VAR SHORT
        VAR.VDPTask vdpTaskQueue,                VDP_TASK_QUEUE_SIZE
        VAR.w       vdpTaskQueueCurrentEntry
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize the VDP task queue
; ----------------
; Uses: a1
 SYS_INIT VDPTaskQueueInit
    move.w  #vdpTaskQueue, vdpTaskQueueCurrentEntry
    rts


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
