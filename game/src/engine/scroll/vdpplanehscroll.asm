;------------------------------------------------------------------------------------------
; Horizontal plane VDPScrollUpdater implementation. Updates the horizontal VDP scroll values for both cameras.
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'
    Include './system/include/vdp.inc'
    Include './system/include/vdptaskqueue.inc'

    Include './engine/include/vdpscroll.inc'

;-------------------------------------------------
; Horizontal plane VDPScrollUpdater structures
; ----------------

    ;-------------------------------------------------
    ; Horizontal plane scroll table/state structure
    ; ----------------
    DEFINE_STRUCT PlaneHorizontalVDPScrollUpdaterState
        STRUCT_MEMBER.w scrollValue
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Horizontal plane VDPScrollUpdater definition
    ; ----------------
    ; struct VDPScrollUpdater
    planeHorizontalVDPScrollUpdater:
        ; .init
        dc.l _PlaneHorizontalVDPScrollUpdaterInit
        ; .update
        dc.l _PlaneHorizontalVDPScrollUpdaterUpdate


;-------------------------------------------------
; Setup the correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
; - a1: Scroll configuration
_PlaneHorizontalVDPScrollUpdaterInit:
        ; Enable horizontal plane scroll mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_HSCROLL_MASK

        ; Initialize scroll values
        VDP_SCROLL_UPDATER_INIT Horizontal, background, PlaneHorizontalVDPScrollUpdaterState
        VDP_SCROLL_UPDATER_INIT Horizontal, foreground, PlaneHorizontalVDPScrollUpdaterState

        ; Setup VDP
        bsr     _HPlaneVDPScrollUpdaterCommit
        rts


;-------------------------------------------------
; Register scroll commit handler if there was any camera movement
; ----------------
; Input:
; - a0: Viewport
; Uses: all
_PlaneHorizontalVDPScrollUpdaterUpdate:
        VDP_SCROLL_UPDATER_UPDATE Horizontal

        ; Update VDP if any scroll values have changed
        beq.s .noMovement

            ; Update VDP scroll values
            VDP_TASK_QUEUE_ADD #_HPlaneVDPScrollUpdaterCommit, a0

    .noMovement:
        rts


;-------------------------------------------------
; Commit viewport scroll values to the VDP
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a1-a2
_HPlaneVDPScrollUpdaterCommit:
        VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS Horizontal, foreground, a1
        VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS Horizontal, background, a2

        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR, SIZE_WORD
        
        move.w  (a1), d0
        move.w  (a2), d1
        neg.w   d0
        neg.w   d1
        move.w  d0, MEM_VDP_DATA
        move.w  d1, MEM_VDP_DATA
        rts
