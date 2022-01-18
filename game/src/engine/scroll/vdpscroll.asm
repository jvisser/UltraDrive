;------------------------------------------------------------------------------------------
; VDP Scroll updater state
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'

    Include './engine/include/vdpscroll.inc'

;-------------------------------------------------
; VDPScrollUpdater state (shared memory)
; ----------------
    DEFINE_VAR SHORT
        VAR.VDPScrollUpdaterState   vsusHorizontalVDPScrollUpdaterState
        VAR.VDPScrollUpdaterState   vsusVerticalVDPScrollUpdaterState
    DEFINE_VAR_END
