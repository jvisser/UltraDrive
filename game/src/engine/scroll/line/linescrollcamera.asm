;------------------------------------------------------------------------------------------
; Line scroll value updater that follows the camera.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Line Camera ScrollValueUpdater
; ----------------

    ; struct ScrollValueUpdater
    lineScrollCamera:
        ; .svuInit
        dc.l _LineScrollCameraInit
        ; .svuUpdate
        dc.l _LineScrollCameraUpdate


;-------------------------------------------------
; Init scroll values
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
_LineScrollCameraInit:
        ; Initialize the vertical scroll value
        move.w  camY(a0), lsuPlaneVerticalScroll(a1)

        ; Initialize the horizontal scroll value
        move.w  camX(a0), d0
        neg.w   d0
        lea     lsuLineHorizontalScroll(a1), a0
        jsr     LineScrollBufferFill
        rts


;-------------------------------------------------
; Update scroll values on changes and return flags indicating what values have been updated.
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; Output:
; - d0: VDP_SCROLL_UPDATE_H|VDP_SCROLL_UPDATE_V depending on which values have changed
_LineScrollCameraUpdate:
        ; Store update flags on the stack
        PUSHW   #0

        ; Check for vertical movement
        tst.w   camLastYDisplacement(a0)
        beq     .noVerticalMovement

            ori.w   #VDP_SCROLL_UPDATE_V_MASK, (sp)
            move.w  camY(a0), lsuPlaneVerticalScroll(a1)

    .noVerticalMovement:

        ; Check for horizontal movement
        tst.w   camLastXDisplacement(a0)
        beq     .noHorizontalMovement

            ; Update horizontal line buffer
            ori.w    #VDP_SCROLL_UPDATE_H_MASK, (sp)
            move.w  camX(a0), d0
            neg.w   d0
            lea     lsuLineHorizontalScroll(a1), a0
            jsr     LineScrollBufferFill

    .noHorizontalMovement:

        ; Pop update flags from the stack
        POPW    d0
        rts

