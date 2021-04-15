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
        STRUCT_MEMBER.b tbtLockX                                            ; Lock horizontal movement
        STRUCT_MEMBER.b tbtLockY                                            ; Lock vertical movement
        STRUCT_MEMBER.w tbtLastX                                            ; Previous X
        STRUCT_MEMBER.w tbtLastY                                            ; Previous Y
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.TilingBackgroundTracker  tilingBackgroundTracker
    DEFINE_VAR_END

    INIT_STRUCT tilingBackgroundTracker
        INIT_STRUCT_MEMBER.btInit      _TilingBackgroundTrackerInit
        INIT_STRUCT_MEMBER.btSync      _TilingBackgroundTrackerSync
        INIT_STRUCT_MEMBER.btFinalize  _TilingBackgroundTrackerFinalize
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the tiling background tracker. Should be called at least once before using.
; ----------------
TilingBackgroundTrackerInit Equ tilingBackgroundTrackerInit


;-------------------------------------------------
; Init background camera position based on the foreground camera position
; ----------------
; Input:
; - a0: Background camera to initialize
; - a1: Background map address
; - a2: Foreground camera
; - d0: Background camera plane id
; Uses: d0-d5/a2-a3
_TilingBackgroundTrackerInit:
        move.b   mapLockHorizontal(a1), (tilingBackgroundTracker + tbtLockX)
        move.b   mapLockVertical(a1), (tilingBackgroundTracker + tbtLockY)
        move.w  #0, (tilingBackgroundTracker + tbtX)
        move.w  #0, (tilingBackgroundTracker + tbtY)

        ; Force update of scroll values on next screen refresh
        VDP_TASK_QUEUE_ADD #_TilingBackgroundTrackerCommit, a0

        ; Calculate initial scrolling positions
        move.l  d0, d4                                              ; d4 = plane id for CameraInit
        exg     a1, a2
        jsr     _TilingBackgroundTrackerSync
        exg     a1, a2
        
        ; Initialize the camera
        move.w  (tilingBackgroundTracker + tbtX), d0
        move.w  (tilingBackgroundTracker + tbtY), d1
        move.w  (vdpMetrics + vdpPlaneWidth), d2                    ; Always let camera match plane dimensions to full plane gets rendered
        move.w  (vdpMetrics + vdpPlaneHeight), d3
        jsr     CameraInit
        rts


;-------------------------------------------------
; Sync scroll to the foreground map
; ----------------
; Input:
; - a0: Background camera
; - a1: Foreground camera
; Uses: d0
_TilingBackgroundTrackerSync

        ; Update horizontal scroll
        tst.b   (tilingBackgroundTracker + tbtLockX)
        bne     .horizontallyLocked
        move.w  camX(a1), d0
        lsr.w   #TILING_BACKGROUND_TRACKER_SHIFT, d0
        move.w  d0, (tilingBackgroundTracker + tbtX)
    .horizontallyLocked:

        ; Update vertical scroll
        tst.b   (tilingBackgroundTracker + tbtLockY)
        bne     .verticallyLocked
        move.w  camY(a1), d0
        lsr.w   #TILING_BACKGROUND_TRACKER_SHIFT, d0
        move.w  d0, (tilingBackgroundTracker + tbtY)
    .verticallyLocked:
        rts


;-------------------------------------------------
; Write new scroll values to the VDP if there is a change
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
