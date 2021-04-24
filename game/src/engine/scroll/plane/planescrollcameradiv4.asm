;------------------------------------------------------------------------------------------
; Plane scroll value updater that follows the camera at a quarter of the speed
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Plane CameraDiv4 ScrollValueUpdater
; ----------------

    ; struct ScrollValueUpdater
    planeScrollCameraDiv4:
        ; .svuInit
        dc.l _PlaneScrollCameraDiv4Init
        ; .svuUpdate
        dc.l _PlaneScrollCameraDiv4Update


;-------------------------------------------------
; Init scroll values
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
_PlaneScrollCameraDiv4Init:
        move.w  camX(a0), d0
        lsr.w   #2, d0
        move.w d0, psuPlaneHorizontalScroll(a1)

        move.w  camY(a0), d0
        lsr.w   #2, d0
        move.w d0, psuPlaneVerticalScroll(a1)
        rts


;-------------------------------------------------
; Update scroll values on changes and return flags indicating what values have been updated.
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; Output:
; - d0: VDP_SCROLL_UPDATE_H|VDP_SCROLL_UPDATE_V depending on which values have changed
_PlaneScrollCameraDiv4Update:
        moveq   #0, d0

        move.w  camX(a0), d1
        lsr.w   #2, d1
        cmp.w   psuPlaneHorizontalScroll(a1), d1
        beq     .noHorizontalMovement

            ori.w   #VDP_SCROLL_UPDATE_H_MASK, d0
            move.w  d1, psuPlaneHorizontalScroll(a1)

    .noHorizontalMovement:

        move.w  camY(a0), d1
        lsr.w   #2, d1
        cmp.w   psuPlaneVerticalScroll(a1), d1
        beq     .noVerticalMovement

            ori.w   #VDP_SCROLL_UPDATE_V_MASK, d0
            move.w  d1, psuPlaneVerticalScroll(a1)

    .noVerticalMovement:

        rts
