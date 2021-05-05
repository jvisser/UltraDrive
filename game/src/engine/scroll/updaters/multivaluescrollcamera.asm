;------------------------------------------------------------------------------------------
; Configurable multivalue scroll updater used for horizontal cell/line and vertical cell scroll modes depending on the used MultiScrollCameraConfiguration.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Multi Camera ScrollValueUpdater
; ----------------

    ;-------------------------------------------------
    ; Multi scroll camera specific configuration
    ; ----------------
    DEFINE_STRUCT MultiScrollCameraConfiguration
        STRUCT_MEMBER.l     msccBufferUpdateSubRoutineAddress   ; Address of the buffer update routine to use (NB: only gets called when there is a related camera position update)
        STRUCT_MEMBER.b     msccCameraProperty                  ; Camera property to scroll value on
        STRUCT_MEMBER.b     msccCameraChangeProperty            ; Camera property used to detect movement
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Multi scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    multiScrollCamera:
        ; .svuInit
        dc.l _MultiScrollCameraInit
        ; .svuUpdate
        dc.l _MultiScrollCameraUpdate


    ;-------------------------------------------------
    ; Predefined configurations
    ; ----------------

    ; struct MultiScrollCameraConfiguration
    lineHorizontalScrollCameraConfig:
        ; .msccBufferUpdateSubRoutineAddress
        dc.l    ScrollBufferFill224
        ; .msccCameraProperty
        dc.b    camX
        ; .msccCameraChangeProperty
        dc.b    camLastXDisplacement

    ; struct MultiScrollCameraConfiguration
    cellHorizontalScrollCameraConfig:
        ; .msccBufferUpdateSubRoutineAddress
        dc.l    ScrollBufferFill28
        ; .msccCameraProperty
        dc.b    camX
        ; .msccCameraChangeProperty
        dc.b    camLastXDisplacement

    ; struct MultiScrollCameraConfiguration
    cellVerticalScrollCameraConfig:
        ; .msccBufferUpdateSubRoutineAddress
        dc.l    ScrollBufferFill20
        ; .msccCameraProperty
        dc.b    camY
        ; .msccCameraChangeProperty
        dc.b    camLastYDisplacement


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
        move.b  msccCameraProperty(a2), d0
        move.w  (a0, d0), d0
        movea.l a1, a0
        movea.l msccBufferUpdateSubRoutineAddress(a2), a3
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
        move.b  msccCameraChangeProperty(a2), d1
        tst.w   (a0, d1)
        beq     .noMovement

            ; Update  multi buffer
            move.b  msccCameraProperty(a2), d1
            move.w  (a0, d1), d0
            movea.l a1, a0
            movea.l msccBufferUpdateSubRoutineAddress(a2), a3
            jsr     (a3)

            moveq   #1, d0

    .noMovement:
        rts

