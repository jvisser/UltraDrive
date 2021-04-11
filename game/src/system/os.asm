;------------------------------------------------------------------------------------------
; Basic OS. Handles all mandatory tasks (updating VDP state and reading IO state for use by the main program loop)
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; OS Context
; ----------------
    DEFINE_STRUCT OSContext
        STRUCT_MEMBER.w osFrameReady
        STRUCT_MEMBER.l osFramesProcessed
        STRUCT_MEMBER.l osFramesSkipped
        STRUCT_MEMBER.l osFrameProcessedCallback
        STRUCT_MEMBER.w osLockCount
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.OSContext osContext
    DEFINE_VAR_END

    INIT_STRUCT osContext
        INIT_STRUCT_MEMBER.osFrameReady               0
        INIT_STRUCT_MEMBER.osFramesProcessed          0
        INIT_STRUCT_MEMBER.osFramesSkipped            0
        INIT_STRUCT_MEMBER.osFrameProcessedCallback   NoOperation
        INIT_STRUCT_MEMBER.osLockCount                0
    INIT_STRUCT_END


;-------------------------------------------------
; Aliases
; ----------------
VBlankInterruptHandler  Equ OSPrepareNextFrame
OSInit                  Equ osContextInit


;-------------------------------------------------
; Prepare for next frame (Vint handler)
; ----------------
OSPrepareNextFrame:
        PUSH_CONTEXT

        tst.w   (osContext + osFrameReady)
        beq     .notReady

        clr.w   (osContext + osFrameReady)
        addq.l  #1, (osContext + osFramesProcessed)

        jsr     VDPDMAQueueFlush
        jsr     VDPTaskQueueProcess
        jsr     IOUpdateDeviceState

        movea.l  (osContext + osFrameProcessedCallback), a0
        jsr     (a0)

        bra     .done

    .notReady:
        DEBUG_MSG 'Frame skipped!'

        addq.l  #1, (osContext + osFramesSkipped)

    .done:

        POP_CONTEXT
        rte


;-------------------------------------------------
; Lock OS when accessing shared resources between main program and OS
; ----------------
OS_LOCK Macro
        tst.w (osContext + osLockCount)
        bne .alreadyLocked\@
            M68K_DISABLE_INT
    .alreadyLocked\@:
        addq    #1, (osContext + osLockCount)
    Endm


;-------------------------------------------------
; Unlock OS when accessing shared resources between main program and OS
; ----------------
OS_UNLOCK Macro
        tst.w (osContext + osLockCount)
        beq .alreadyUnlocked\@
            subq #1, (osContext + osLockCount)
            bne .alreadyUnlocked\@
                M68K_ENABLE_INT
    .alreadyUnlocked\@:
    Endm


;-------------------------------------------------
; Kill switch
; ----------------
OS_KILL Macro reason
        DEBUG_MSG \reason
        trap #0
        Endm


;-------------------------------------------------
; Reset frame processing statistics
; ----------------
; Uses: d0
OSResetStatistics:
        OS_LOCK

        moveq   #0, d0
        move.l  d0, (osContext + osFramesProcessed)
        move.l  d0, (osContext + osFramesSkipped)

        OS_UNLOCK
        rts


;-------------------------------------------------
; Set frame processed callback
; ----------------
; Input:
; - a0: Callback address
OSSetFrameProcessedCallback:
        move.l  a0, (osContext + osFrameProcessedCallback)
        rts


;-------------------------------------------------
; Wait until next frame is ready to be processed
; ----------------
; Uses: d0
OSNextFrameReadyWait:
        OS_LOCK

        ; Mark frame as ready for processing
        move.w   #1, (osContext + osFrameReady)

        ; Wait until processed
        move.l  (osContext + osFramesProcessed), d0

        OS_UNLOCK

    .waitNextFrameLoop:
        cmp.l  (osContext + osFramesProcessed), d0
        beq     .waitNextFrameLoop
        rts


;-------------------------------------------------
; OS Kill handler (Trap #0)
; ----------------
_SIG_OSKill:
        DEBUG_MSG 'OSKill signal received'

        ; Blue screen
        VDP_ADDR_SET WRITE, CRAM, $00
        move.w  #$0e00, MEM_VDP_DATA

        M68K_HALT
        rte         ; Unreachable
