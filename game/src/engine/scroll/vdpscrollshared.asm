;------------------------------------------------------------------------------------------
; VDP Scroll updater shared memory/macros (since only one is active at a time)
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Update flags
; ----------------
    BIT_CONST.VDP_SCROLL_UPDATE_FOREGROUND      0
    BIT_CONST.VDP_SCROLL_UPDATE_BACKGROUND      1


;-------------------------------------------------
; VDPScrollUpdater shared memory
; ----------------

    DEFINE_STRUCT VDPScrollUpdaterState
        STRUCT_MEMBER.l   vssBackgroundScrollValueUpdateAddress
        STRUCT_MEMBER.l   vssBackgroundScrollValueTableAddress
        STRUCT_MEMBER.l   vssBackgroundScrollValueStateAddress
        STRUCT_MEMBER.l   vssBackgroundScrollValueConfigurationAddress
        STRUCT_MEMBER.w   vssBackgroundScrollValueCameraOffset

        STRUCT_MEMBER.l   vssForegroundScrollValueUpdateAddress
        STRUCT_MEMBER.l   vssForegroundScrollValueTableAddress
        STRUCT_MEMBER.l   vssForegroundScrollValueStateAddress
        STRUCT_MEMBER.l   vssForegroundScrollValueConfigurationAddress
        STRUCT_MEMBER.w   vssForegroundScrollValueCameraOffset

        STRUCT_MEMBER.b   vssUpdateFlags
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.VDPScrollUpdaterState   vsusHorizontalVDPScrollUpdaterState
        VAR.VDPScrollUpdaterState   vsusVerticalVDPScrollUpdaterState
    DEFINE_VAR_END


;-------------------------------------------------
; Put the address of the specified scroll table in target
; ----------------
VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS Macros orientation, config, target
    move.l  vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueTableAddress, \target


;-------------------------------------------------
; Initialize the scroll values for the specified scroll updater configuration
; ----------------
; Input:
; - a0: Viewport
; - a1: ScrollConfiguration
; Uses: Uses: d0-d7/a2-a6
VDP_SCROLL_UPDATER_INIT Macro orientation, config, scrollTableType
        PUSHM   a0-a1

        lea     sc\config\ScrollUpdaterConfiguration(a1), a3                                                    ; a3 = Scroll updater configuration address

        ; Store scroll value updater configuration for later use
        movea.l svucUpdaterData(a3), a2                                                                         ; a2 = Scroll value updater configuration address
        move.l  a2, vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueConfigurationAddress

        ; Store scroll updater camera offset for later use
        move.w  svucCamera(a3), d0                                                                              ; d0 = Viewport camera offset
        move.w  d0, vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueCameraOffset

        ; Get camera address
        lea     (a0, d0), a0                                                                                    ; a0 = Camera address

        ; Allocate scroll table
        MEMORY_ALLOCATE \scrollTableType\_Size, a1, a4

        ; Store scroll value table address for later use
        move.l  a1, vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueTableAddress

        move.l  svucUpdater(a3), a3                                                                             ; a3 = scroll updater address

        ; Store scroll value updater update routine address for later use
        move.l  svuUpdate(a3), vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueUpdateAddress

        ; Call scroll value updater: init(a0, a1)
        move.l  svuInit(a3), a3                                                                                 ; a3 = scroll updater init subroutine address
        jsr     (a3)

        ; Store address of scroll value updater allocated memory for later use
        move.l  a0, vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueStateAddress

        POPM    a0-a1
    Endm


;-------------------------------------------------
; Initialize the scroll values for the specified scroll updater configuration
; ----------------
; Input:
; - a0: Viewport
; Output:
; - d0: Foreground/Background update flags
; - ccr: Condition codes related to update flags
; Uses: Uses: d0-d7/a2-a6
VDP_SCROLL_UPDATER_UPDATE Macro orientation
_CALL_SCROLL_VALUE_UPDATER Macro orientation, config
            move.w  vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueCameraOffset, d0
            lea     (a0, d0), a0                                                                                ; a0 = Camera address
            move.l  vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueTableAddress, a1             ; a1 = Scroll table address
            move.l  vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueConfigurationAddress, a2     ; a2 = Scroll value updater configuration
            move.l  vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueStateAddress, a3             ; a3 = Scroll value updater state address
            move.l  vsus\orientation\VDPScrollUpdaterState + vss\config\ScrollValueUpdateAddress, a4            ; a3 = Scroll value update routine address

            ; update(a0, a1, a2, a3)
            jsr     (a4)
        Endm

        PUSHL   a0

        ; Call background scroll value updater
        _CALL_SCROLL_VALUE_UPDATER \orientation, Background

        add.w   d0, d0
        move.w  d0, vsus\orientation\VDPScrollUpdaterState + vssUpdateFlags

        PEEKL   a0                                                                                              ; a0 = viewport address

        ; Call foreground scroll value updater
        _CALL_SCROLL_VALUE_UPDATER \orientation, Foreground

        POPL

        move.w  vsus\orientation\VDPScrollUpdaterState + vssUpdateFlags, d1
        or.w    d1, d0
        move.w  d0, vsus\orientation\VDPScrollUpdaterState + vssUpdateFlags

        Purge _CALL_SCROLL_VALUE_UPDATER
    Endm


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
