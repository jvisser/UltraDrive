;------------------------------------------------------------------------------------------
; Vertical plane scroll updater. Updates the horizontal VDP scroll values for both cameras.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; VPlane VDPScrollUpdater state structure
; ----------------

    DEFINE_STRUCT PlaneVerticalVDPScrollUpdaterState
        STRUCT_MEMBER.w scrollValue
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Vertical plane VDPScrollUpdater
    ; ----------------
    ; struct VDPScrollUpdater
    planeVerticalVDPScrollUpdater:
        ; .init
        dc.l _PlaneVerticalVDPScrollUpdaterInit
        ; .update
        dc.l _PlaneVerticalVDPScrollUpdaterUpdate


;-------------------------------------------------
; Setup the correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
; - a1: Scroll configuration
_PlaneVerticalVDPScrollUpdaterInit:
        ; Enable vertical vplane scroll mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_VSCROLL_CELL

        ; Initialize scroll values
        VDP_SCROLL_UPDATER_INIT Vertical, background, PlaneVerticalVDPScrollUpdaterState
        VDP_SCROLL_UPDATER_INIT Vertical, foreground, PlaneVerticalVDPScrollUpdaterState

        ; Setup VDP
        bsr     _VPlaneVDPScrollUpdaterCommit
        rts


;-------------------------------------------------
; Register scroll commit handler if there was any camera movement
; ----------------
; Input:
; - a0: Viewport
; Uses: all
_PlaneVerticalVDPScrollUpdaterUpdate:
        VDP_SCROLL_UPDATER_UPDATE Vertical

        ; Update VDP if any scroll values have changed
        beq .noMovement

            ; Update VDP scroll values
            VDP_TASK_QUEUE_ADD #_VPlaneVDPScrollUpdaterCommit, a0

    .noMovement:
        rts


;-------------------------------------------------
; Commit viewport scroll values to the VDP
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a1-a2
_VPlaneVDPScrollUpdaterCommit:
        VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS Vertical, foreground, a1
        VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS Vertical, background, a2

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00, SIZE_WORD
        
        move.w  (a1), MEM_VDP_DATA
        move.w  (a2), MEM_VDP_DATA
        rts
