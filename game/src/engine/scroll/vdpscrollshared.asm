;------------------------------------------------------------------------------------------
; VDP Scroll updater shared memory/macros (since only one is active at a time)
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Update flags
; ----------------
    BIT_CONST.VDP_SCROLL_UPDATE_FOREGROUND_H   0
    BIT_CONST.VDP_SCROLL_UPDATE_FOREGROUND_V   1
    BIT_CONST.VDP_SCROLL_UPDATE_BACKGROUND_H   2
    BIT_CONST.VDP_SCROLL_UPDATE_BACKGROUND_V   3


;-------------------------------------------------
; Shared memory storage
; ----------------
    DEFINE_VAR FAST
        VAR.l   vssBackgroundScrollValueUpdateAddress
        VAR.l   vssBackgroundScrollValueTableAddress
        VAR.w   vssBackgroundScrollValueCameraOffset
        VAR.l   vssForegroundScrollValueUpdateAddress
        VAR.l   vssForegroundScrollValueTableAddress
        VAR.w   vssForegroundScrollValueCameraOffset
        VAR.b   vssUpdateFlags
    DEFINE_VAR_END

    DEFINE_VAR SLOW
        VAR.w   vdpScrollBuffer, 512                                ; Shared scroll value table buffer
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize the scroll values for the specified scroll updater configuration
; ----------------
; Input:
; - a0: Viewport
; - a1: ScrollConfiguration
; Uses: Uses: d0-d7/a2-a6
VDP_SCROLL_UPDATER_INIT Macro config, scrollValueTableOffset
        PUSHM   a0-a1

        lea     sc\config\ScrollUpdaterConfiguration(a1), a2        ; a2 = Scroll updater configuration address
        move.w  svucCamera(a2), d0                                  ; d0 = Viewport camera offset

        ; Store scroll updater camera offset for later use
        move.w  d0, vss\config\ScrollValueCameraOffset

        ; Get scroll value update init routine parameters
        lea     (a0, d0), a0                                        ; a0 = Camera address
        lea     vdpScrollBuffer + \scrollValueTableOffset, a1       ; a1 = Scroll table address

        ; Store scroll value table address for later use
        move.l  a1, vss\config\ScrollValueTableAddress

        move.l  svucUpdater(a2), a2                                 ; a2 = scroll updater address

        ; Store scroll value updater update routine address for later use
        move.l  svuUpdate(a2), vss\config\ScrollValueUpdateAddress

        ; Call scroll value updater: init(a0, a1)
        move.l  svuInit(a2), a2                                     ; a2 = scroll updater init subroutine address
        jsr     (a2)

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
VDP_SCROLL_UPDATER_UPDATE Macro
        PUSHL   a0

        move.w  vssBackgroundScrollValueCameraOffset, d0
        lea     (a0, d0), a0                                            ; a0 = Camera address
        move.l  vssBackgroundScrollValueTableAddress, a1                ; a1 = Scroll table address
        move.l  vssBackgroundScrollValueUpdateAddress, a2               ; a2 = Scroll value update routine address

        ; Call background scroll value updater: update(a0, a1)
        jsr     (a2)

        add.w   d0, d0
        add.w   d0, d0
        move.w  d0, vssUpdateFlags

        move.l  (sp), a0                                                ; a0 = viewport address
        move.w  vssForegroundScrollValueCameraOffset, d0
        lea     (a0, d0), a0                                            ; a0 = Camera address
        move.l  vssForegroundScrollValueTableAddress, a1                ; a1 = Scroll table address
        move.l  vssForegroundScrollValueUpdateAddress, a2               ; a2 = Scroll value update routine address

        ; Call foreground scroll value updater: update(a0, a1)
        jsr     (a2)

        POPL    a0

        move.w  vssUpdateFlags, d1
        or.w    d1, d0
        move.w  d0, vssUpdateFlags
    Endm


;-------------------------------------------------
; Read update flags into the specified target location
; ----------------
VDP_SCROLL_UPDATE_FLAGS_GET Macro target
        move.w  vssUpdateFlags, \target
    Endm
