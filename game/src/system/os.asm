;------------------------------------------------------------------------------------------
; Basic OS. Handles all mandatory tasks (updating VDP state and reading IO state for use by the main program loop)
;------------------------------------------------------------------------------------------

    Include './common/include/debug.inc'

    Include './system/include/memory.inc'
    Include './system/include/m68k.inc'
    Include './system/include/memory.inc'
    Include './system/include/vdp.inc'
    Include './system/include/os.inc'

;-------------------------------------------------
; OS state
; ----------------
    DEFINE_VAR SHORT
        VAR.OSContext osContext
    DEFINE_VAR_END

    INIT_STRUCT osContext
        INIT_STRUCT_MEMBER.frameReady               0
        INIT_STRUCT_MEMBER.framesProcessed          0
        INIT_STRUCT_MEMBER.framesSkipped            0
        INIT_STRUCT_MEMBER.frameProcessedCallback   NoOperation
        INIT_STRUCT_MEMBER.lockCount                0
    INIT_STRUCT_END


;-------------------------------------------------
; Prepare for next frame (Vint handler)
; ----------------
OSPrepareNextFrame:
        PUSH_USER_CONTEXT

        tst.w   (osContext + OSContext_frameReady)
        beq.s   .notReady

            clr.w   (osContext + OSContext_frameReady)
            addq.l  #1, (osContext + OSContext_framesProcessed)

            ; Update VDP
            jsr     VDPTaskQueueProcess
            jsr     VDPDMAQueueFlush

            ; Call RasterEffect.setupFrame()
            jsr     _RasterEffectSetupFrame

            ; Update input devices
            jsr     IOUpdateDeviceState

            ; Call frame processed callback
            movea.l  (osContext + OSContext_frameProcessedCallback), a0
            jsr     (a0)

        bra.s   .done

    .notReady:
        DEBUG_MSG 'Frame skipped!'

        addq.l  #1, (osContext + OSContext_framesSkipped)

        ; Call RasterEffect.setupFrame(). Always setup raster effects even on frame skip.
        jsr     _RasterEffectSetupFrame
    .done:

        POP_USER_CONTEXT
        rte


;-------------------------------------------------
; Reset frame processing statistics
; ----------------
; Uses: d0
OSResetStatistics:
        OS_LOCK

        moveq   #0, d0
        move.l  d0, (osContext + OSContext_framesProcessed)
        move.l  d0, (osContext + OSContext_framesSkipped)

        OS_UNLOCK
        rts


;-------------------------------------------------
; Set frame processed callback
; ----------------
; Input:
; - a0: Callback address
OSSetFrameProcessedCallback:
        move.l  a0, (osContext + OSContext_frameProcessedCallback)
        rts


;-------------------------------------------------
; Wait until next frame is ready to be processed
; ----------------
OSNextFrameReadyWait:
        ; Call RasterEffect.prepareNextFrame()
        jsr _RasterEffectPrepareNextFrame

        OS_LOCK

        ; Mark frame as ready for processing
        move.w   #1, (osContext + OSContext_frameReady)

        ; Wait until processed
        move.l  (osContext + OSContext_framesProcessed), d0

        OS_UNLOCK

    .waitNextFrameLoop:

        ; Suspend the CPU until the next interrupt, let it cool down a bit.
        stop    #M68k_SR_SUPERVISOR

        cmp.l  (osContext + OSContext_framesProcessed), d0
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
