;------------------------------------------------------------------------------------------
; Plane scroll value updater that follows the camera.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Plane Camera ScrollValueUpdater
; ----------------

    ; struct ScrollValueUpdater
    planeScrollCamera:
        ; .svuInit
        dc.l _PlaneScrollCameraInit
        ; .svuUpdate
        dc.l _PlaneScrollCameraUpdate


;-------------------------------------------------
; Init scroll values
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
_PlaneScrollCameraInit:
        move.w  camX(a0), psuPlaneHorizontalScroll(a1)
        move.w  camY(a0), psuPlaneVerticalScroll(a1)
        rts


;-------------------------------------------------
; Update scroll values on changes and return flags indicating what values have been updated.
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; Output:
; - d0: VDP_SCROLL_UPDATE_H|VDP_SCROLL_UPDATE_V depending on which values have changed
_PlaneScrollCameraUpdate:
        moveq   #0, d0

        tst.w   camLastXDisplacement(a0)
        beq     .noHorizontalMovement

            ori.w   #VDP_SCROLL_UPDATE_H_MASK, d0
            move.w  camX(a0), psuPlaneHorizontalScroll(a1)

    .noHorizontalMovement:

        tst.w   camLastYDisplacement(a0)
        beq     .noVerticalMovement

            ori.w   #VDP_SCROLL_UPDATE_V_MASK, d0
            move.w  camY(a0), psuPlaneVerticalScroll(a1)

    .noVerticalMovement:
        rts

