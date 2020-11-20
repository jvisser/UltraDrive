;------------------------------------------------------------------------------------------
; Tiling background tracker. Treats the background as a single repetitive tile.
; Scrolls at a fixed division of the foreground.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Tiling background constants
; ----------------
TILING_BACKGROUND_TRACKER_SHIFT Equ 2


;-------------------------------------------------
; Tiling background tracker
; ----------------
    DEFINE_STRUCT TilingBackgroundTracker, EXTENDS, BackgroundTracker
        STRUCT_MEMBER.w tbtX                                                ; Current X
        STRUCT_MEMBER.w tbtY                                                ; Current Y
        STRUCT_MEMBER.w tbtLastX                                            ; Previous X
        STRUCT_MEMBER.w tbtLastY                                            ; Previous Y
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.TilingBackgroundTracker  tilingBackgroundTracker
    DEFINE_VAR_END

    INIT_STRUCT tilingBackgroundTracker
        INIT_STRUCT_MEMBER.btStart     _TilingBackgroundTrackerStart
        INIT_STRUCT_MEMBER.btSync      _TilingBackgroundTrackerSync
        INIT_STRUCT_MEMBER.btFinalize  _TilingBackgroundTrackerFinalize
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the tiling background tracker. Should be called at least once before using.
; ----------------
TilingBackgroundTrackerInit Equ tilingBackgroundTrackerInit


;-------------------------------------------------
; Tiling background tracker structures
; ----------------
; Input:
; - a0: Background map address
; - a1: Foreground camera
; Output:
; - d0: Camera x position
; - d1: Camera y position
; Uses: d0-d5/a2-a3
_TilingBackgroundTrackerStart:
        moveq   #0, d0
        moveq   #0, d1
        rts


;-------------------------------------------------
; Tiling background tracker structures
; ----------------
; Input:
; - a0: Background camera
; - a1: Foreground camera
_TilingBackgroundTrackerSync
        move.l  camX(a1), d0
        lsr.w   #TILING_BACKGROUND_TRACKER_SHIFT, d0
        move.w  d0, (tilingBackgroundTracker + tbtY)
        swap    d0
        lsr.w   #TILING_BACKGROUND_TRACKER_SHIFT, d0
        move.w  d0, (tilingBackgroundTracker + tbtX)
        rts


;-------------------------------------------------
; Tiling background tracker structures
; ----------------
; Input:
; - a0: Background camera
; Uses: d0/a2
_TilingBackgroundTrackerFinalize
        move.l  (tilingBackgroundTracker + tbtX), d0
        cmp.l   (tilingBackgroundTracker + tbtLastX), d0
        beq     .noMovement

        ; Store last value
        move.l   d0, (tilingBackgroundTracker + tbtLastX)

        ; Queue VDP scroll update
        VDP_TASK_QUEUE_ADD #_TilingBackgroundTrackerCommit, a0

    .noMovement:
        rts


;-------------------------------------------------
; Commit scroll to VDP
; ----------------
; Input:
; - a0: Background camera
; Uses: d0
_TilingBackgroundTrackerCommit:
        BACKGROUND_UPDATE_VDP_SCROLL (tilingBackgroundTracker + tbtX), (tilingBackgroundTracker + tbtY)
        rts
