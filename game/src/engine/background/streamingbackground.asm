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
        STRUCT_MEMBER.l sbtXSteps, 8                                        ; Increments for each camera displacement (16:16 fixedpoint)
        STRUCT_MEMBER.l sbtYSteps, 8
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.StreamingBackgroundTracker  streamingBackgroundTracker
    DEFINE_VAR_END

    INIT_STRUCT streamingBackgroundTracker
        INIT_STRUCT_MEMBER.btStart     _StreamingBackgroundTrackerStart
        INIT_STRUCT_MEMBER.btSync      _StreamingBackgroundTrackerSync
        INIT_STRUCT_MEMBER.btFinalize  _StreamingBackgroundTrackerFinalize
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the streaming background tracker. Should be called at least once before using.
; ----------------
StreamingBackgroundTrackerInit Equ streamingBackgroundTrackerInit


;-------------------------------------------------
; Streaming background tracker start implementation. Calculates the ratio between the back/foreground maps. And returns the background camera position
; ----------------
; Input:
; - a0: Background map address
; - a1: Foreground camera
; Output:
; - d0: Camera x position
; - d1: Camera y position
; Uses: d0-d5/a2-a3
_StreamingBackgroundTrackerStart:
_FP16_MUL Macro result, multiplierfp16
            move.w  \result, d4
            mulu    \multiplierfp16, d4
            swap    \multiplierfp16
            mulu    \multiplierfp16, \result
            swap    \result
            add.l   d4, \result
        Endm

        moveq   #0, d0
        moveq   #0, d1
        moveq   #0, d2
        moveq   #0, d3

        move.w   (vdpMetrics + vdpScreenWidth), d4
        move.w   (vdpMetrics + vdpScreenHeight), d5

        movea.l camMapAddress(a1), a2
        move.w  mapWidthPixels(a2), d0
        sub.w   d4, d0
        move.w  mapHeightPixels(a2), d1
        sub.w   d5, d1

        move.w  mapWidthPixels(a0), d2
        sub.w   d4, d2
        swap    d2
        move.w  mapHeightPixels(a0), d3
        sub.w   d5, d3
        swap    d3

        ; Calculate maps ratio and displacement steps
        divu    d0, d2
        divu    d1, d3
        move.w  d2, d0
        move.w  d3, d1
        move.l  d0, d2
        move.l  d1, d3
        lea     (streamingBackgroundTracker + sbtXSteps), a2
        lea     (streamingBackgroundTracker + sbtYSteps), a3
        Rept 8
            move.l  d0, (a2)+
            move.l  d1, (a3)+
            add.l   d2, d0
            add.l   d3, d1
        Endr

        ; Update initial camera position
        move.w  camX(a1), d0
        _FP16_MUL d0, d2
        move.l  d0, (streamingBackgroundTracker + sbtX)
        swap    d0                                              ; Expects non fixed point result

        move.w  camY(a1), d1
        _FP16_MUL d1, d3
        move.l  d1, (streamingBackgroundTracker + sbtY)
        swap    d1                                              ; Expects non fixed point result

        Purge _FP16_MUL
        rts


;-------------------------------------------------
; Streaming background tracker sync implementation
; ----------------
; Input:
; - a0: Background camera
; - a1: Foreground camera
_StreamingBackgroundTrackerSync:
_MOVE_CAMERA_COMPONENT Macro result, sourceDisplacement, position, stepTable
                move.w  \sourceDisplacement(a1), \result
                beq     .noMovement\@
                move.w  \result, d2
                bpl     .positive1\@
                neg.w    \result
            .positive1\@:
                subq    #1, \result
                add     \result, \result
                add     \result, \result
                lea     streamingBackgroundTracker, a2
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

        _MOVE_CAMERA_COMPONENT d0, camLastXDisplacement, sbtX, sbtXSteps
        _MOVE_CAMERA_COMPONENT d1, camLastYDisplacement, sbtY, sbtYSteps

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
