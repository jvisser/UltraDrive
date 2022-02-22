;------------------------------------------------------------------------------------------
; Configurable multivalue scroll updater used for horizontal cell/line and vertical cell scroll modes depending on the used MultiScrollCameraConfiguration.
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'

    Include './engine/include/camera.inc'

;-------------------------------------------------
; Multi Camera ScrollValueUpdater
; ----------------

    ;-------------------------------------------------
    ; Multi scroll camera specific configuration
    ; ----------------
    DEFINE_STRUCT MultiScrollCameraConfiguration
        STRUCT_MEMBER.l     bufferUpdateSubRoutineAddress       ; Address of the buffer update routine to use (NB: only gets called when there is a related camera position update)
        STRUCT_MEMBER.b     cameraProperty                      ; Camera property to scroll value on
        STRUCT_MEMBER.b     cameraChangeProperty                ; Camera property used to detect movement
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Multi scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    multiScrollCamera:
        ; .init
        dc.l _MultiScrollCameraInit
        ; .update
        dc.l _MultiScrollCameraUpdate


    ;-------------------------------------------------
    ; Predefined configurations
    ; ----------------

    ; struct MultiScrollCameraConfiguration
    lineHorizontalScrollCameraConfig:
        ; .bufferUpdateSubRoutineAddress
        dc.l    _ScrollBufferFill224
        ; .cameraProperty
        dc.b    Camera_x
        ; .cameraChangeProperty
        dc.b    Camera_lastXDisplacement

    ; struct MultiScrollCameraConfiguration
    cellHorizontalScrollCameraConfig:
        ; .bufferUpdateSubRoutineAddress
        dc.l    _ScrollBufferFill28
        ; .cameraProperty
        dc.b    Camera_x
        ; .cameraChangeProperty
        dc.b    Camera_lastXDisplacement

    ; struct MultiScrollCameraConfiguration
    cellVerticalScrollCameraConfig:
        ; .bufferUpdateSubRoutineAddress
        dc.l    _ScrollBufferFill20
        ; .cameraProperty
        dc.b    Camera_y
        ; .cameraChangeProperty
        dc.b    Camera_lastYDisplacement


;-------------------------------------------------
; Init scroll values
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; - a2: MultiScrollCameraConfiguration address
_MultiScrollCameraInit:
        ; Initialize the scroll table
        moveq   #0, d0
        move.b  MultiScrollCameraConfiguration_cameraProperty(a2), d0
        move.w  (a0, d0), d0
        movea.l a1, a0
        movea.l MultiScrollCameraConfiguration_bufferUpdateSubRoutineAddress(a2), a3
        jsr     (a3)
        rts


;-------------------------------------------------
; Update scroll values on changes and return flags indicating what values have been updated.
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; - a2: MultiScrollCameraConfiguration address
; Output:
; - d0: 1 if values have been updated, 0 otherwise
_MultiScrollCameraUpdate:
        moveq   #0, d0

        ; Check for  movement
        moveq   #0, d1
        move.b  MultiScrollCameraConfiguration_cameraChangeProperty(a2), d1
        tst.w   (a0, d1)
        beq.s   .noMovement

            ; Update multi buffer
            move.b  MultiScrollCameraConfiguration_cameraProperty(a2), d1
            move.w  (a0, d1), d0
            movea.l a1, a0
            movea.l MultiScrollCameraConfiguration_bufferUpdateSubRoutineAddress(a2), a3
            jsr     (a3)

            moveq   #1, d0

    .noMovement:
        rts

;-------------------------------------------------
; Support routine for horizontal line scroll value updater implementations.
; Fills the specified 224 word scroll buffer with a single value
; The value gets negated before being written to allow symmetric scroll value interpretation for both vertical and horizontal scroll values at higher level code.
; ----------------
; Input:
; - d0: Value to fill buffer with
; - a0: 224 word scroll buffer address
; Uses: d0-d1/a0-a6
_ScrollBufferFill224:
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
_ScrollBufferFill28:
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
_ScrollBufferFill20:
        move.w  d0, d2
        swap    d0
        move.w  d2, d0
        Rept 10
            move.l d0, (a0)+
        Endr
        rts
