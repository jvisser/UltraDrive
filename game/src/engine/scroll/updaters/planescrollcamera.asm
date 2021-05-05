;------------------------------------------------------------------------------------------
; Configurable plane scroll value updater applicable to both horizontal and vertical vdp plane scroll updaters depending on the configuration used.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Plane scroll camera ScrollValueUpdater structs
; ----------------

    ;-------------------------------------------------
    ; Plane scroll camera specific configuration
    ; ----------------
    DEFINE_STRUCT PlaneScrollCameraConfiguration
        STRUCT_MEMBER.b     psccCameraProperty              ; Camera property to base scroll value on
        STRUCT_MEMBER.b     psccCameraValueShift            ; Number of bits to shift the camera property value before using
    DEFINE_STRUCT_END


    ;-------------------------------------------------
    ; Plane scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    planeScrollCamera:
        ; .svuInit
        dc.l _PlaneScrollCameraInit
        ; .svuUpdate
        dc.l _PlaneScrollCameraUpdate


    ;-------------------------------------------------
    ; Predefined configurations
    ; ----------------

    ; struct PlaneScrollCameraConfiguration
    planeHorizontalScrollCameraConfig:
        ; .psccCameraProperty
        dc.b    camX
        ; .psccCameraValueShift
        dc.b    0

    ; struct PlaneScrollCameraConfiguration
    planeVerticalScrollCameraConfig:
        ; .psccCameraProperty
        dc.b    camY
        ; .psccCameraValueShift
        dc.b    0

    ; struct PlaneScrollCameraConfiguration
    planeHorizontalScrollCameraHalfSpeedConfig:
        ; .psccCameraProperty
        dc.b    camX
        ; .psccCameraValueShift
        dc.b    1

    ; struct PlaneScrollCameraConfiguration
    planeVerticalScrollCameraHalfSpeedConfig:
        ; .psccCameraProperty
        dc.b    camY
        ; .psccCameraValueShift
        dc.b    1

    ; struct PlaneScrollCameraConfiguration
    planeHorizontalScrollCameraQuarterSpeedConfig:
        ; .psccCameraProperty
        dc.b    camX
        ; .psccCameraValueShift
        dc.b    2

    ; struct PlaneScrollCameraConfiguration
    planeVerticalScrollCameraQuarterSpeedConfig:
        ; .psccCameraProperty
        dc.b    camY
        ; .psccCameraValueShift
        dc.b    2


;-------------------------------------------------
; Init horizontal scroll values
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; - a2: PlaneScrollCameraConfiguration address
_PlaneScrollCameraInit:
        moveq   #0, d0
        move.b  psccCameraProperty(a2), d0
        move.w  (a0, d0), d0
        move.b  psccCameraValueShift(a2), d1
        lsr.w   d1, d0
        move.w  d0, (a1)
        rts


;-------------------------------------------------
; Update scroll values on changes and return flag indicating that values have been updated.
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; - a2: PlaneScrollCameraConfiguration address
; Output:
; - d0: 1 if values have been updated, 0 otherwise
_PlaneScrollCameraUpdate:
        moveq   #0, d0
        moveq   #0, d1

        move.b  psccCameraProperty(a2), d1
        move.w  (a0, d1), d1
        move.b  psccCameraValueShift(a2), d2
        lsr.w   d2, d1
        cmp.w   (a1), d1
        beq     .noMovement

            move.w  d1, (a1)
            moveq   #1, d0

    .noMovement:
        rts
