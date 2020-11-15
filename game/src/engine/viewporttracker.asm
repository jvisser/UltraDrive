;------------------------------------------------------------------------------------------
; Viewport background camera tracker
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport tracker structures
; ----------------
    DEFINE_STRUCT ViewportTracker
        STRUCT_MEMBER.l vptStart                ; Calculates the initial background camera position based on the background map and foreground camera
        STRUCT_MEMBER.l vptSync                 ; Sync the background camera with the foreground camera
        STRUCT_MEMBER.l vptFinalize             ; Finalize the tracker for the current frame
    DEFINE_STRUCT_END

    DEFINE_STRUCT DefaultViewportTracker, EXTENDS, ViewportTracker
        STRUCT_MEMBER.l dvptX                  ; Current X in (16:16 fixedpoint)
        STRUCT_MEMBER.l dvptY                  ; Current Y in (16:16 fixedpoint)
        STRUCT_MEMBER.l dvptXSteps, 8          ; Increments for each camera displacement (16:16 fixedpoint)
        STRUCT_MEMBER.l dvptYSteps, 8
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.DefaultViewportTracker  defaultViewportTracker
    DEFINE_VAR_END

    INIT_STRUCT defaultViewportTracker
        INIT_STRUCT_MEMBER.vptStart     DefaultViewportTrackerStart
        INIT_STRUCT_MEMBER.vptSync      DefaultViewportTrackerSync
        INIT_STRUCT_MEMBER.vptFinalize  DefaultViewportTrackerFinalize
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the default tracker. Should be called at least once before using the default tracker
; ----------------
DefaultViewportTrackerInit Equ defaultViewportTrackerInit


;-------------------------------------------------
; Default viewport tracker start implementation. Calculates the ratio between the back/foreground maps. And returns the background camera position
; ----------------
; Input:
; - a0: Background map address
; - a1: Foreground camera
; Output:
; - d0: Camera x position
; - d1: Camera y position
; Uses: d0-d5/a2-a3
DefaultViewportTrackerStart:
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
        lea     (defaultViewportTracker + dvptXSteps), a2
        lea     (defaultViewportTracker + dvptYSteps), a3
        Rept 8
            move.l  d0, (a2)+
            move.l  d1, (a3)+
            add.l   d2, d0
            add.l   d3, d1
        Endr

        ; Update initial camera position
        move.w  camX(a1), d0
        _FP16_MUL d0, d2
        move.l  d0, (defaultViewportTracker + dvptX)
        swap    d0                                              ; Expects non fixed point result

        move.w  camY(a1), d1
        _FP16_MUL d1, d3
        move.l  d1, (defaultViewportTracker + dvptY)
        swap    d1                                              ; Expects non fixed point result

        Purge _FP16_MUL
        rts


;-------------------------------------------------
; Default viewport tracker sync implementation
; ----------------
; Input:
; - a0: Background camera
; - a1: Foreground camera
DefaultViewportTrackerSync:
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
                lea     defaultViewportTracker, a2
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

        _MOVE_CAMERA_COMPONENT d0, camLastXDisplacement, dvptX, dvptXSteps
        _MOVE_CAMERA_COMPONENT d1, camLastYDisplacement, dvptY, dvptYSteps

        CAMERA_MOVE d0, d1

        Purge _MOVE_CAMERA_COMPONENT
        rts


;-------------------------------------------------
; If there was camera movement update VDP
; ----------------
; Input:
; - a0: Background camera
DefaultViewportTrackerFinalize:
        tst.l   camLastXDisplacement(a0)
        beq     .noMovement

        ; Update VDP scroll values if there was camera movement
        VDP_TASK_QUEUE_ADD #_DefaultViewportTrackerCommit, a0

    .noMovement:
        rts


;-------------------------------------------------
; Commit scroll to VDP
; ----------------
; Input:
; - a0: Background camera
_DefaultViewportTrackerCommit:

        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR + 2
        move.w  camX(a0), d0
        neg.w   d0
        move.w  d0, (MEM_VDP_DATA)

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $02
        move.w  camY(a0), d1
        move.w  d1, (MEM_VDP_DATA)
        rts
