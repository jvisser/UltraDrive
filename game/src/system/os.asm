;------------------------------------------------------------------------------------------
; Basic OS. Handles all mandatory tasks (updating VDP state and reading IO state for use by the main program loop)
;------------------------------------------------------------------------------------------

VBlankInterrupt Equ OSPrepareNextFrame
OSInit          Equ osContextInit


;-------------------------------------------------
; OS Context
; ----------------
    DEFINE_STRUCT OSContext
        STRUCT_MEMBER.l frameCounter
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.OSContext osContext
    DEFINE_VAR_END

    INIT_STRUCT osContext
        INIT_STRUCT_MEMBER.frameCounter 0
    INIT_STRUCT_END


;-------------------------------------------------
; Prepare for next frame (Vint handler)
; ----------------
OSPrepareNextFrame:
        PUSH_CONTEXT

        addq.l  #1, (osContext + frameCounter)

        jsr     VDPDMAQueueFlush
        jsr     VDPTaskQueueProcess
        jsr     IOUpdateDeviceState

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
; Wait until next frame is ready to be processed
; ----------------
; Uses: d0
OSNextFrameReadyWait:
        move.l  (osContext + frameCounter), d0

    .waitNextFrameLoop:
        cmp.l  (osContext + frameCounter), d0
        beq     .waitNextFrameLoop
        rts
