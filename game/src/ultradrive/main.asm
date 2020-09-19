;------------------------------------------------------------------------------------------
; Main entry point
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Main program entry point
; ----------------
Main:
        DEBUG_MSG 'UltraDrive Started!'

        jsr VDPEnableDisplay

    .mainLoop:
        jsr     VDPVSyncWait

        lea     ioDeviceState1, a0
        jsr     IOUpdateDeviceState

        bra.s   .mainLoop
