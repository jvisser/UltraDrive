;------------------------------------------------------------------------------------------
; Configurable plane scroll value updater applicable to both horizontal and vertical vdp plane scroll updaters depending on the configuration used.
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'

    Include './engine/include/camera.inc'

;-------------------------------------------------
; Plane scroll camera ScrollValueUpdater structs
; ----------------

    ;-------------------------------------------------
    ; Plane scroll camera specific configuration
    ; ----------------
    DEFINE_STRUCT PlaneScrollCameraConfiguration
        STRUCT_MEMBER.b     cameraProperty              ; Camera property to base scroll value on
        STRUCT_MEMBER.b     cameraValueShift            ; Number of bits to shift the camera property value before using
    DEFINE_STRUCT_END


    ;-------------------------------------------------
    ; Plane scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    planeScrollCamera:
        ; .init
        dc.l _PlaneScrollCameraInit
        ; .update
        dc.l _PlaneScrollCameraUpdate


    ;-------------------------------------------------
    ; Predefined configurations
    ; ----------------

    ; struct PlaneScrollCameraConfiguration
    planeHorizontalScrollCameraConfig:
        ; .cameraProperty
        dc.b    Camera_x
        ; .cameraValueShift
        dc.b    0

    ; struct PlaneScrollCameraConfiguration
    planeVerticalScrollCameraConfig:
        ; .cameraProperty
        dc.b    Camera_y
        ; .cameraValueShift
        dc.b    0

    ; struct PlaneScrollCameraConfiguration
    planeHorizontalScrollCameraHalfSpeedConfig:
        ; .cameraProperty
        dc.b    Camera_x
        ; .cameraValueShift
        dc.b    1

    ; struct PlaneScrollCameraConfiguration
    planeVerticalScrollCameraHalfSpeedConfig:
        ; .cameraProperty
        dc.b    Camera_y
        ; .cameraValueShift
        dc.b    1

    ; struct PlaneScrollCameraConfiguration
    planeHorizontalScrollCameraQuarterSpeedConfig:
        ; .cameraProperty
        dc.b    Camera_x
        ; .cameraValueShift
        dc.b    2

    ; struct PlaneScrollCameraConfiguration
    planeVerticalScrollCameraQuarterSpeedConfig:
        ; .cameraProperty
        dc.b    Camera_y
        ; .cameraValueShift
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
        move.b  PlaneScrollCameraConfiguration_cameraProperty(a2), d0
        move.w  (a0, d0), d0
        move.b  PlaneScrollCameraConfiguration_cameraValueShift(a2), d1
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

        move.b  PlaneScrollCameraConfiguration_cameraProperty(a2), d1
        move.w  (a0, d1), d1
        move.b  PlaneScrollCameraConfiguration_cameraValueShift(a2), d2
        lsr.w   d2, d1
        cmp.w   (a1), d1
        beq.s   .noMovement

            move.w  d1, (a1)
            moveq   #1, d0

    .noMovement:
        rts
