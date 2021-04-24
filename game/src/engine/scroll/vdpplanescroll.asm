;------------------------------------------------------------------------------------------
; Plane scroll updater. Updates the VDP scroll values for both cameras. Uses plane scroll mode for both axes.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Plane VDPScrollUpdater state structure
; ----------------
    DEFINE_STRUCT PlaneVDPScrollUpdaterPlaneState
        STRUCT_MEMBER.w     psuPlaneHorizontalScroll
        STRUCT_MEMBER.w     psuPlaneVerticalScroll
    DEFINE_STRUCT_END

    DEFINE_STRUCT PlaneVDPScrollUpdaterState
        STRUCT_MEMBER.PlaneVDPScrollUpdaterPlaneState pvsusPlaneB
        STRUCT_MEMBER.PlaneVDPScrollUpdaterPlaneState pvsusPlaneA
    DEFINE_STRUCT_END


;-------------------------------------------------
; Plane VDPScrollUpdater
; ----------------

    ; struct VDPScrollUpdater
    planeVDPScrollUpdater:
        ; .vdpsuInit
        dc.l _PlaneVDPScrollUpdaterInit
        ; .vdpsuUpdate
        dc.l _PlaneVDPScrollUpdaterUpdate


;-------------------------------------------------
; PlaneVDPScrollUpdaterState address alias
; ----------------
planeVDPScrollUpdaterState Equ vdpScrollBuffer


;-------------------------------------------------
; Setup the correct VDP scroll state
; ----------------
; Input:
; - a0: Viewport
; - a1: Scroll configuration
_PlaneVDPScrollUpdaterInit:
        ; Enable vertical plane scroll mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_VSCROLL_CELL
        ; Enable horizontal plane scroll mode
        VDP_REG_RESET_BITS vdpRegMode3, MODE3_HSCROLL_MASK

        ; Initialize scroll values
        VDP_SCROLL_UPDATER_INIT Background, pvsusPlaneB
        VDP_SCROLL_UPDATER_INIT Foreground, pvsusPlaneA

        ; Setup VDP
        bsr     _PlaneVDPScrollUpdaterCommit
        rts


;-------------------------------------------------
; Register scroll commit handler if there was any camera movement
; ----------------
; Input:
; - a0: Viewport
; Uses: all
_PlaneVDPScrollUpdaterUpdate:
        VDP_SCROLL_UPDATER_UPDATE

        ; Update VDP if any scroll values have changed
        beq     .noMovement

        ; Update VDP scroll values
        VDP_TASK_QUEUE_ADD #_PlaneVDPScrollUpdaterCommit, a0

    .noMovement:
        rts


;-------------------------------------------------
; Commit viewport scroll values to the VDP
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a1
_PlaneVDPScrollUpdaterCommit:
        move.l  planeVDPScrollUpdaterState + pvsusPlaneA, d0       ; d0 = [front X]:[front Y]
        move.l  planeVDPScrollUpdaterState + pvsusPlaneB, d1       ; d1 = [back X]:[back Y]

        ; Auto increment to 2
        VDP_REG_SET vdpRegIncr, SIZE_WORD

        lea     MEM_VDP_DATA, a1

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00
        move.w  d0, (a1)
        move.w  d1, (a1)

        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR
        swap    d0
        swap    d1
        neg.w   d0
        neg.w   d1
        move.w  d0, (a1)
        move.w  d1, (a1)
        rts
