;------------------------------------------------------------------------------------------
; VDP Task queue. Tasks that need to be executed during vertical blanking period
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_VDP_TASK_QUEUE_INC))
__SYSTEM_VDP_TASK_QUEUE_INC Equ 1

    Include './lib/common/include/debug.inc'

    Include './system/include/memory.inc'
    Include './system/include/os.inc'

;-------------------------------------------------
; VDP Task queue structures
; ----------------
    DEFINE_STRUCT VDPTask
        STRUCT_MEMBER.l task
        STRUCT_MEMBER.l taskData
    DEFINE_STRUCT_END


;-------------------------------------------------
; Queue VDP Task
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
                    bra.s .vpdTaskQueueDone\@

                .vdpTaskQueueFull\@:
                    DEBUG_MSG 'VDP Task Queue full'

                .vpdTaskQueueDone\@:
            Else
                .vdpTaskQueueFull\@:
            Endif

            OS_UNLOCK
    Endm

    EndIf
