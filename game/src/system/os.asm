;------------------------------------------------------------------------------------------
; Basic OS. Handles all mandatory tasks (updating VDP state and reading IO state for use by the main program loop)
;------------------------------------------------------------------------------------------

VBlankInterrupt Equ OSPrepareNextFrame
OSInit          Equ osContextInit


;-------------------------------------------------
; OS Context
; ----------------
    DEFINE_STRUCT OSContext
        STRUCT_MEMBER.w frameReady
        STRUCT_MEMBER.l framesProcessed
        STRUCT_MEMBER.l framesSkipped
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.OSContext osContext
    DEFINE_VAR_END

    INIT_STRUCT osContext
        INIT_STRUCT_MEMBER.frameReady      0
        INIT_STRUCT_MEMBER.framesProcessed 0
        INIT_STRUCT_MEMBER.framesSkipped   0
    INIT_STRUCT_END


;-------------------------------------------------
; Prepare for next frame (Vint handler)
; ----------------
OSPrepareNextFrame:
        PUSH_CONTEXT

        tst.w   (osContext + frameReady)
        beq     .notReady

        clr.w   (osContext + frameReady)
        addq.l  #1, (osContext + framesProcessed)

        jsr     VDPDMAQueueFlush
        jsr     VDPTaskQueueProcess
        jsr     IOUpdateDeviceState

        bra     .done

    .notReady:
        DEBUG_MSG 'Frame skipped!'

        addq.l  #1, (osContext + framesSkipped)

    .done:

        POP_CONTEXT
        rte


;-------------------------------------------------
; Lock OS when accessing shared resources between main program and OS
; ----------------
OS_LOCK Macros
    M68K_DISABLE_INT


;-------------------------------------------------
; Unlock OS when accessing shared resources between main program and OS
; ----------------
OS_UNLOCK Macros
    M68K_ENABLE_INT


;-------------------------------------------------
; Reset frame processing statistics
; ----------------
; Uses: d0
OSResetStatistics:
        OS_LOCK

        moveq   #0, d0
        move.l  d0, (osContext + framesProcessed)
        move.l  d0, (osContext + framesSkipped)

        OS_UNLOCK
        rts


;-------------------------------------------------
; Wait until next frame is ready to be processed
; ----------------
; Uses: d0
OSNextFrameReadyWait:
        OS_LOCK

        ; Mark frame as ready for processing
        move.w   #1, (osContext + frameReady)

        ; Wait until processed
        move.l  (osContext + framesProcessed), d0

        OS_UNLOCK

    .waitNextFrameLoop:
        cmp.l  (osContext + framesProcessed), d0
        beq     .waitNextFrameLoop
        rts
