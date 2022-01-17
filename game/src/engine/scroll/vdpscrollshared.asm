;------------------------------------------------------------------------------------------
; VDP Scroll updater shared memory/macros (since only one is active at a time)
;------------------------------------------------------------------------------------------

    Include './common/include/constants.inc'

    Include './system/include/memory.inc'

    Include './engine/include/vdpscroll.inc'

;-------------------------------------------------
; VDPScrollUpdater state (shared memory)
; ----------------
    DEFINE_VAR SHORT
        VAR.VDPScrollUpdaterState   vsusHorizontalVDPScrollUpdaterState
        VAR.VDPScrollUpdaterState   vsusVerticalVDPScrollUpdaterState
    DEFINE_VAR_END


;-------------------------------------------------
; Support routine for horizontal line scroll value updater implementations.
; Fills the specified 224 word scroll buffer with a single value
; The value gets negated before being written to allow symmetric scroll value interpretation for both vertical and horizontal scroll values at higher level code.
; ----------------
; Input:
; - d0: Value to fill buffer with
; - a0: 224 word scroll buffer address
; Uses: d0-d1/a0-a6
ScrollBufferFill224:
        lea     224 * SIZE_WORD(a0), a0
        neg.w   d0
        move.w  d0, d2
        swap    d0
        move.w  d2, d0
        move.l  d0, d1
        move.l  d0, d2
        move.l  d0, d3
        move.l  d0, d4
        move.l  d0, d5
        move.l  d0, d6
        move.l  d0, d7
        movea.l d0, a1
        movea.l d0, a2
        movea.l d0, a3
        movea.l d0, a4
        movea.l d0, a5
        movea.l d0, a6
        Rept 224 / 28
            movem.l d0-d7/a1-a6, -(a0)
        Endr
        rts


;-------------------------------------------------
; Support routine for horizontal cell scroll value updater implementations.
; Fills the specified 28 word scroll buffer with a single value.
; The value gets negated before being written to allow symmetric scroll value interpretation for both vertical and horizontal scroll values at higher level code.
; ----------------
; Input:
; - d0: Value to fill buffer with
; - a0: 28 word scroll buffer address
; Uses: d0-d1/a0-a6
ScrollBufferFill28:
        neg.w   d0
        move.w  d0, d2
        swap    d0
        move.w  d2, d0
        Rept 14
            move.l d0, (a0)+
        Endr
        rts


;-------------------------------------------------
; Support routine for vertical scroll value updater implementations.
; Fills the specified 20 word scroll buffer with a single value
; ----------------
; Input:
; - d0: Value to fill buffer with
; - a0: 20 word scroll buffer address
; Uses: d0-d1/a0-a6
ScrollBufferFill20:
        move.w  d0, d2
        swap    d0
        move.w  d2, d0
        Rept 10
            move.l d0, (a0)+
        Endr
        rts
