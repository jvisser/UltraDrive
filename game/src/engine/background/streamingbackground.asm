;------------------------------------------------------------------------------------------
; Streaming background tracker implementation. Scrolls at a rate of the ratio between the background and foreground maps.
; Streams in map data as required.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Streaming background tracker structures
; ----------------
    DEFINE_STRUCT StreamingBackgroundTracker, EXTENDS, BackgroundTracker
        STRUCT_MEMBER.l sbtX                                                ; Current X in (16:16 fixedpoint)
        STRUCT_MEMBER.l sbtY                                                ; Current Y in (16:16 fixedpoint)
        STRUCT_MEMBER.b sbtLockX                                            ; Lock horizontal movement
        STRUCT_MEMBER.b sbtLockY                                            ; Lock vertical movement
        STRUCT_MEMBER.l sbtXSteps, 8                                        ; Increments for each camera displacement (16:16 fixedpoint)
        STRUCT_MEMBER.l sbtYSteps, 8
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.StreamingBackgroundTracker  streamingBackgroundTracker
    DEFINE_VAR_END

    INIT_STRUCT streamingBackgroundTracker
        INIT_STRUCT_MEMBER.btInit      _StreamingBackgroundTrackerInit
        INIT_STRUCT_MEMBER.btSync      _StreamingBackgroundTrackerSync
        INIT_STRUCT_MEMBER.btFinalize  _StreamingBackgroundTrackerFinalize
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the streaming background tracker. Should be called at least once before using.
; ----------------
StreamingBackgroundTrackerInit Equ streamingBackgroundTrackerInit


;-------------------------------------------------
; Streaming background tracker init implementation. Calculates the ratio between the back/foreground maps. And initializes the background camera.
; ----------------
; Input:
; - a0: Background camera to initialize
; - a1: Background map address
; - a2: Foreground camera
; - d0: Background camera plane id
; Uses: d0-d5/a3-a4
_StreamingBackgroundTrackerInit:
        PUSHL   d0                                              ; Push plane id for CameraInit

        moveq   #0, d0
        moveq   #0, d1
        moveq   #0, d2
        moveq   #0, d3

        move.w   (vdpMetrics + vdpScreenWidth), d4
        move.w   (vdpMetrics + vdpScreenHeight), d5

        movea.l camMapAddress(a2), a3
        move.w  mapWidthPixels(a3), d0
        sub.w   d4, d0
        move.w  mapHeightPixels(a3), d1
        sub.w   d5, d1

        move.w  mapWidthPixels(a1), d2
        sub.w   d4, d2
        swap    d2
        move.w  mapHeightPixels(a1), d3
        sub.w   d5, d3
        swap    d3

        ; Calculate maps ratio and displacement steps (TODO: Fix result being 0 when ratio >= 1)
        divu    d0, d2
        divu    d1, d3
        move.w  d2, d0
        move.w  d3, d1
        move.l  d0, d2
        move.l  d1, d3
        lea     (streamingBackgroundTracker + sbtXSteps), a3
        lea     (streamingBackgroundTracker + sbtYSteps), a4
        Rept 8
            move.l  d0, (a3)+
            move.l  d1, (a4)+
            add.l   d2, d0
            add.l   d3, d1
        Endr

        ; Update initial camera position
        moveq   #0, d0
        move.b   mapLockHorizontal(a1), (streamingBackgroundTracker + sbtLockX)
        bne     .horizontallyLocked
        move.w  camX(a2), d0
        FP16_MUL_UINT d0, d2
        move.l  d0, (streamingBackgroundTracker + sbtX)
        swap    d0                                              ; Expects non fixed point result
    .horizontallyLocked:

        moveq   #0, d1
        move.b   mapLockVertical(a1), (streamingBackgroundTracker + sbtLockY)
        bne     .verticallyLocked
        move.w  camY(a2), d1
        FP16_MUL_UINT d1, d3
        move.l  d1, (streamingBackgroundTracker + sbtY)
        swap    d1                                              ; Expects non fixed point result
    .verticallyLocked:

        ; Force update of scroll values on next screen refresh
        VDP_TASK_QUEUE_ADD #_StreamingBackgroundTrackerCommit, a0

        ; Initialize background camera
        POPL    d2                                              ; d2 = Camera plane id
        jsr     CameraInit
        rts


;-------------------------------------------------
; Streaming background tracker sync implementation
; ----------------
; Input:
; - a0: Background camera
; - a1: Foreground camera
; Uses: d0-d3/a2
_StreamingBackgroundTrackerSync:
_MOVE_CAMERA_COMPONENT Macro result, sourceDisplacement, position, stepTable, lock
                moveq   #0, \result
                tst.b   \lock(a2)
                bne     .noMovement\@
                move.w  \sourceDisplacement(a1), \result
                beq     .noMovement\@
                move.w  \result, d2
                bpl     .positive1\@
                neg.w    \result
            .positive1\@:
                subq    #1, \result
                add     \result, \result
                add     \result, \result
                move.l  \stepTable(a2, \result), \result
                tst.w   d2
                bpl     .positive2\@
                neg.l   \result
            .positive2\@:
                move.l  \position(a2), d2
                move.l  d2, d3
                add.l   \result, d2
                move.l  d2, \position(a2)
                swap    d2
                swap    d3
                sub.l   d3, d2
                move.w  d2, \result
            .noMovement\@:
        Endm

        lea streamingBackgroundTracker, a2

        _MOVE_CAMERA_COMPONENT d0, camLastXDisplacement, sbtX, sbtXSteps, sbtLockX
        _MOVE_CAMERA_COMPONENT d1, camLastYDisplacement, sbtY, sbtYSteps, sbtLockY

        CAMERA_MOVE d0, d1

        Purge _MOVE_CAMERA_COMPONENT
        rts


;-------------------------------------------------
; If there was camera movement update VDP
; ----------------
; Input:
; - a0: Background camera
; Uses: a2
_StreamingBackgroundTrackerFinalize:
        tst.l   camLastXDisplacement(a0)
        beq     .noMovement

        ; Update VDP scroll values if there was camera movement
        VDP_TASK_QUEUE_ADD #_StreamingBackgroundTrackerCommit, a0

    .noMovement:
        rts


;-------------------------------------------------
; Commit scroll to VDP
; ----------------
; Input:
; - a0: Background camera
; Uses: d0
_StreamingBackgroundTrackerCommit:
        BACKGROUND_UPDATE_VDP_SCROLL camX(a0), camY(a0)
        rts
