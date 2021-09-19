;------------------------------------------------------------------------------------------
; Provides (limited) screen rotation scroll value updaters for horizontal line and vertical cell scroll modes for a SNES Mode7 like effect.
;
; Ignores the camera positions due to:
;   - Compensating vertical column scroll positions based on the horizontal camera position causes jittering due to the 16 pixel increments.
; Thus only really usable for static backgrounds/foregrounds
;
; Provides the following convenience macros for producing scroll tables for common scenarios:
; - DEFINE_ROTATE_SCROLL_CENTER_HORIZONTAL_ANGLE_TABLE
; - DEFINE_ROTATE_SCROLL_TOP_HORIZONTAL_ANGLE_TABLE
; - DEFINE_ROTATE_SCROLL_CENTER_VERTICAL_ANGLE_TABLE
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Rotate  ScrollValueUpdater
; ----------------

    ;-------------------------------------------------
    ; Rotate scroll camera specific configuration
    ; ----------------

    DEFINE_STRUCT RotateScrollAngleEntry
        STRUCT_MEMBER.l     base                                ; Base scroll value
        STRUCT_MEMBER.l     increment                           ; Increment used to calculate subsequent values
    DEFINE_STRUCT_END

    DEFINE_STRUCT RotateScrollPosition
        STRUCT_MEMBER.w     angle                               ; Angle
        STRUCT_MEMBER.w     horizontalOffset                    ; Additional horizontal scroll to apply
        STRUCT_MEMBER.w     verticalOffset                      ; Additional vertical scroll to apply
    DEFINE_STRUCT_END

    DEFINE_STRUCT RotateScrollConfiguration
        STRUCT_MEMBER.l     anglePosition                       ; Address of the RotateScrollPosition to use
        STRUCT_MEMBER.l     horizontalScrollTableAddress        ; Address of the horizontal RotateScrollAngleEntry[64] table
        STRUCT_MEMBER.l     verticalScrollTableAddress          ; Address of the vertical RotateScrollAngleEntry[64] table
    DEFINE_STRUCT_END

    ; Used for change detection
    DEFINE_STRUCT RotateScrollState
        STRUCT_MEMBER.w     lastAngle
        STRUCT_MEMBER.w     lastOffset
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Rotate horizontal line scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    rotateHorizontalLineScroll:
        ; .nit
        dc.l _RotateHorizontalLineScrollInit
        ; .update
        dc.l _RotateHorizontalLineScrollUpdate

    ;-------------------------------------------------
    ; Rotate vertical cell scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    rotateVerticalCellScroll:
        ; .init
        dc.l _RotateVerticalCellScrollInit
        ; .update
        dc.l _RotateVerticalCellScrollUpdate


;-------------------------------------------------
; Init horizontal rotation line scroll values
; ----------------
; Input:
; - a0:  address
; - a1: Scroll table address
; - a2: RotateScrollConfiguration address
; Output:
; - a0: Pointer to allocated value updater state
_RotateHorizontalLineScrollInit:

        ; Load RotateScrollPosition address from RotateScrollConfiguration
        movea.l RotateScrollConfiguration_anglePosition(a2), a3                                               ; a3 = RotateScrollPosition

        ; Calculate the scroll table for specified angle
        bsr _RotateHorizontalLineCalculateScrollValues

        ; Allocate value updater state for change detection
        MEMORY_ALLOCATE RotateScrollState_Size, a0, a1

        ; Store scroll values
        move.w  RotateScrollPosition_horizontalOffset(a3), RotateScrollState_lastOffset(a0)
        move.w  RotateScrollPosition_angle(a3), RotateScrollState_lastAngle(a0)
        rts


;-------------------------------------------------
; Update horizontal rotation line scroll values on changes and return flag indicating that values have been updated.
; ----------------
; Input:
; - a0:  address
; - a1: Scroll table address
; - a2: RotateScrollConfiguration address
; - a3: RotateScrollState address
; Output:
; - d0: 1 if values have been updated, 0 otherwise
_RotateHorizontalLineScrollUpdate:
        moveq   #0, d0

        ; Load RotateScrollPosition address from RotateScrollConfiguration
        movea.l RotateScrollConfiguration_anglePosition(a2), a4                                               ; a4 = RotateScrollPosition

        move.w  RotateScrollPosition_angle(a4), d1
        cmp.w   RotateScrollState_lastAngle(a3), d1
        beq.s   .noAngleChange

            ; Update last state
            move.w  RotateScrollPosition_horizontalOffset(a4), RotateScrollState_lastOffset(a3)
            move.w  d1, RotateScrollState_lastAngle(a3)

            ; Recalculate all values
            movea.l a4, a3
            bsr     _RotateHorizontalLineCalculateScrollValues
            moveq   #1, d0
            rts

    .noAngleChange:
        move.w  RotateScrollState_lastOffset(a3), d2
        sub.w   RotateScrollPosition_horizontalOffset(a4), d2
        beq.s   .noOffsetChange

            ; Update last state
            move.w  RotateScrollPosition_horizontalOffset(a4), RotateScrollState_lastOffset(a3)

            ; Offset table by horizontal position change
            move.w  #6, d1

    .scrollValueOffsetLoop:
                Rept 32
                    add.w   d2, (a1)+
                Endr
            dbra    d1, .scrollValueOffsetLoop

            moveq   #1, d0
    .noOffsetChange:
        rts


;-------------------------------------------------
; Recalculate all horizontal scroll values
; ----------------
; Input:
; - a0:  address
; - a1: Scroll table address
; - a2: RotateScrollConfiguration address
; - a3: RotateScrollPosition address
_RotateHorizontalLineCalculateScrollValues:
        ; Calculate RotateScrollAngleEntry offset
        move.w  RotateScrollPosition_angle(a3), d0
        lsl.w   #3, d0
        movea.l RotateScrollConfiguration_horizontalScrollTableAddress(a2), a4

        ; Get angle increment
        move.l  RotateScrollAngleEntry_increment(a4, d0), d1

        ; Calculate scroll base
        move.l  RotateScrollAngleEntry_base(a4, d0), d2

        ; Add horizontal offset from configuration
        moveq   #0, d3
        move.w  RotateScrollPosition_horizontalOffset(a3), d3
        neg.w   d3
        swap    d3
        add.l   d3, d2

        ; Update scroll table
        moveq   #15, d3

    .scrollValueLoop:
            Rept 14
                add.l   d1, d2
                swap    d2
                move.w  d2, (a1)+
                swap    d2
            Endr
        dbra    d3, .scrollValueLoop
        rts


;-------------------------------------------------
; Init vertical rotation cell scroll values
; ----------------
; Input:
; - a0:  address
; - a1: Scroll table address
; - a2: RotateScrollConfiguration address
; Output:
; - a0: Pointer to allocated value updater state
_RotateVerticalCellScrollInit:

        ; Load RotateScrollPosition address from RotateScrollConfiguration
        movea.l RotateScrollConfiguration_anglePosition(a2), a3                                               ; a3 = RotateScrollPosition

        ; Calculate the scroll table for specified angle
        bsr _RotateVerticalCellCalculateScrollValues

        ; Allocate value updater state for change detection
        MEMORY_ALLOCATE RotateScrollState_Size, a0, a1

        ; Store scroll values
        move.w  RotateScrollPosition_verticalOffset(a3), RotateScrollState_lastOffset(a0)
        move.w  RotateScrollPosition_angle(a3), RotateScrollState_lastAngle(a0)
        rts


;-------------------------------------------------
; Update vertical rotation cell scroll values on changes and return flag indicating that values have been updated.
; ----------------
; Input:
; - a0:  address
; - a1: Scroll table address
; - a2: RotateScrollConfiguration address
; - a3: RotateScrollState address
; Output:
; - d0: 1 if values have been updated, 0 otherwise
_RotateVerticalCellScrollUpdate:
        moveq   #0, d0

        ; Load RotateScrollPosition address from RotateScrollConfiguration
        movea.l RotateScrollConfiguration_anglePosition(a2), a4                                               ; a4 = RotateScrollPosition

        move.w  RotateScrollPosition_angle(a4), d1
        cmp.w   RotateScrollState_lastAngle(a3), d1
        beq.s   .noAngleChange

            ; Update last state
            move.w  RotateScrollPosition_verticalOffset(a4), RotateScrollState_lastOffset(a3)
            move.w  d1, RotateScrollState_lastAngle(a3)

            ; Recalculate all values
            movea.l a4, a3
            bsr     _RotateVerticalCellCalculateScrollValues
            moveq   #1, d0
            rts

    .noAngleChange:
        move.w  RotateScrollPosition_verticalOffset(a4), d2
        sub.w   RotateScrollState_lastOffset(a3), d2
        beq.s   .noOffsetChange

            ; Update last state
            move.w  RotateScrollPosition_verticalOffset(a4), RotateScrollState_lastOffset(a3)

            ; Offset table by horizontal position change
            Rept 20
                add.w   d2, (a1)+
            Endr

            moveq   #1, d0
    .noOffsetChange:
        rts


;-------------------------------------------------
; Recalculate all vertical scroll values
; ----------------
; Input:
; - a0:  address
; - a1: Scroll table address
; - a2: RotateScrollConfiguration address
; - a3: RotateScrollPosition address
_RotateVerticalCellCalculateScrollValues:
        ; Calculate RotateScrollAngleEntry offset
        move.w  RotateScrollPosition_angle(a3), d0
        lsl.w   #3, d0
        movea.l RotateScrollConfiguration_verticalScrollTableAddress(a2), a4

        ; Get angle increment
        move.l  RotateScrollAngleEntry_increment(a4, d0), d1

        ; Calculate scroll base
        move.l  RotateScrollAngleEntry_base(a4, d0), d2

        ; Add horizontal offset from configuration
        moveq   #0, d3
        move.w  RotateScrollPosition_verticalOffset(a3), d3
        swap    d3
        add.l   d3, d2

        ; Calculate
        Rept 20
            add.l   d1, d2
            swap    d2
            move.w  d2, (a1)+
            swap    d2
        Endr
        rts


    ;-------------------------------------------------
    ; Macro to generate angle tables where the rotation point is at the center of the screen for the rotateHorizontalLineScroll ScrollValueUpdater.
    ; 64 positions represent angles between -30 to +30
    ; ----------------
DEFINE_ROTATE_SCROLL_CENTER_HORIZONTAL_ANGLE_TABLE Macro
        ; RotateScrollAngleEntry[64]
        dc.l $001cfcdc, $ffffbdbf, $001c1a08, $ffffbfc5, $001b36ba, $ffffc1cd, $001a52f4, $ffffc3d5
        dc.l $00196ebb, $ffffc5df, $00188a12, $ffffc7e9, $0017a4fd, $ffffc9f5, $0016bf81, $ffffcc02
        dc.l $0015d9a1, $ffffce0f, $0014f361, $ffffd01d, $00140cc5, $ffffd22c, $001325d1, $ffffd43c
        dc.l $00123e89, $ffffd64d, $001156f2, $ffffd85e, $00106f0e, $ffffda70, $000f86e2, $ffffdc83
        dc.l $000e9e72, $ffffde96, $000db5c2, $ffffe0aa, $000cccd5, $ffffe2bf, $000be3b1, $ffffe4d3
        dc.l $000afa58, $ffffe6e9, $000a10d0, $ffffe8ff, $0009271b, $ffffeb15, $00083d3e, $ffffed2b
        dc.l $0007533d, $ffffef42, $0006691b, $fffff159, $00057ede, $fffff371, $00049488, $fffff588
        dc.l $0003aa1f, $fffff7a0, $0002bfa5, $fffff9b8, $0001d51f, $fffffbd0, $0000ea91, $fffffde8
        dc.l $00000000, $00000000, $ffff156f, $00000218, $fffe2ae1, $00000430, $fffd405b, $00000648
        dc.l $fffc55e1, $00000860, $fffb6b78, $00000a78, $fffa8122, $00000c8f, $fff996e5, $00000ea7
        dc.l $fff8acc3, $000010be, $fff7c2c2, $000012d5, $fff6d8e5, $000014eb, $fff5ef30, $00001701
        dc.l $fff505a8, $00001917, $fff41c4f, $00001b2d, $fff3332b, $00001d41, $fff24a3e, $00001f56
        dc.l $fff1618e, $0000216a, $fff0791e, $0000237d, $ffef90f2, $00002590, $ffeea90e, $000027a2
        dc.l $ffedc177, $000029b3, $ffecda2f, $00002bc4, $ffebf33b, $00002dd4, $ffeb0c9f, $00002fe3
        dc.l $ffea265f, $000031f1, $ffe9407f, $000033fe, $ffe85b03, $0000360b, $ffe775ee, $00003817
        dc.l $ffe69145, $00003a21, $ffe5ad0c, $00003c2b, $ffe4c946, $00003e33, $ffe3e5f8, $0000403b
    Endm


    ;-------------------------------------------------
    ; Macro to generate angle tables where the rotation point is at the top of the screen for the rotateHorizontalLineScroll ScrollValueUpdater.
    ; 64 positions represent angles between -30 to +30
    ; ----------------
DEFINE_ROTATE_SCROLL_TOP_HORIZONTAL_ANGLE_TABLE Macro
        ; RotateScrollAngleEntry[64]
        dc.l $ffd80000, $ffffbdbf, $ffd92391, $ffffbfc5, $ffda49cc, $ffffc1cd, $ffdb729c, $ffffc3d5
        dc.l $ffdc9dee, $ffffc5df, $ffddcbac, $ffffc7e9, $ffdefbc3, $ffffc9f5, $ffe02e1d, $ffffcc02
        dc.l $ffe162a5, $ffffce0f, $ffe29947, $ffffd01d, $ffe3d1ec, $ffffd22c, $ffe50c7f, $ffffd43c
        dc.l $ffe648ec, $ffffd64d, $ffe7871c, $ffffd85e, $ffe8c6f9, $ffffda70, $ffea086d, $ffffdc83
        dc.l $ffeb4b63, $ffffde96, $ffec8fc5, $ffffe0aa, $ffedd57b, $ffffe2bf, $ffef1c70, $ffffe4d3
        dc.l $fff0648d, $ffffe6e9, $fff1adbd, $ffffe8ff, $fff2f7e7, $ffffeb15, $fff442f6, $ffffed2b
        dc.l $fff58ed3, $ffffef42, $fff6db68, $fffff159, $fff8289c, $fffff371, $fff9765b, $fffff588
        dc.l $fffac48c, $fffff7a0, $fffc1319, $fffff9b8, $fffd61ea, $fffffbd0, $fffeb0ea, $fffffde8
        dc.l $00000000, $00000000, $00014f16, $00000218, $00029e16, $00000430, $0003ece7, $00000648
        dc.l $00053b74, $00000860, $000689a5, $00000a78, $0007d764, $00000c8f, $00092498, $00000ea7
        dc.l $000a712d, $000010be, $000bbd0a, $000012d5, $000d0819, $000014eb, $000e5243, $00001701
        dc.l $000f9b73, $00001917, $0010e390, $00001b2d, $00122a85, $00001d41, $0013703b, $00001f56
        dc.l $0014b49d, $0000216a, $0015f793, $0000237d, $00173907, $00002590, $001878e4, $000027a2
        dc.l $0019b714, $000029b3, $001af381, $00002bc4, $001c2e14, $00002dd4, $001d66b9, $00002fe3
        dc.l $001e9d5b, $000031f1, $001fd1e3, $000033fe, $0021043d, $0000360b, $00223454, $00003817
        dc.l $00236212, $00003a21, $00248d64, $00003c2b, $0025b634, $00003e33, $0026dc6f, $0000403b
    Endm


    ;-------------------------------------------------
    ; Macro to generate angle tables where the rotation point is at the center for the rotateVerticalCellScroll ScrollValueUpdater.
    ; 64 positions represent angles between -30 to +30
    ; ----------------
    ; RotateScrollAngleEntry[64]
DEFINE_ROTATE_SCROLL_CENTER_VERTICAL_ANGLE_TABLE Macro
        dc.l $0029693a, $fffbdbe1, $00282531, $fffbfc48, $0026e077, $fffc1cc1, $00259b14, $fffc3d4b
        dc.l $0024550b, $fffc5de6, $00230e63, $fffc7e90, $0021c721, $fffc9f4a, $00207f4a, $fffcc013
        dc.l $001f36e6, $fffce0e9, $001dedf8, $fffd01ce, $001ca487, $fffd22c0, $001b5a99, $fffd43be
        dc.l $001a1032, $fffd64c8, $0018c55a, $fffd85de, $00177a14, $fffda6fe, $00162e68, $fffdc829
        dc.l $0014e25a, $fffde95e, $001395f0, $fffe0a9c, $00124931, $fffe2be2, $0010fc22, $fffe4d30
        dc.l $000faec8, $fffe6e86, $000e6129, $fffe8fe3, $000d134b, $fffeb146, $000bc534, $fffed2ae
        dc.l $000a76e9, $fffef41c, $00092870, $ffff158f, $0007d9cf, $ffff3705, $00068b0c, $ffff587f
        dc.l $00053c2c, $ffff79fc, $0003ed35, $ffff9b7b, $00029e2d, $ffffbcfc, $00014f19, $ffffde7e
        dc.l $00000000, $00000000, $fffeb0e7, $00002182, $fffd61d3, $00004304, $fffc12cb, $00006485
        dc.l $fffac3d4, $00008604, $fff974f4, $0000a781, $fff82631, $0000c8fb, $fff6d790, $0000ea71
        dc.l $fff58917, $00010be4, $fff43acc, $00012d52, $fff2ecb5, $00014eba, $fff19ed7, $0001701d
        dc.l $fff05138, $0001917a, $ffef03de, $0001b2d0, $ffedb6cf, $0001d41e, $ffec6a10, $0001f564
        dc.l $ffeb1da6, $000216a2, $ffe9d198, $000237d7, $ffe885ec, $00025902, $ffe73aa6, $00027a22
        dc.l $ffe5efce, $00029b38, $ffe4a567, $0002bc42, $ffe35b79, $0002dd40, $ffe21208, $0002fe32
        dc.l $ffe0c91a, $00031f17, $ffdf80b6, $00033fed, $ffde38df, $000360b6, $ffdcf19d, $00038170
        dc.l $ffdbaaf5, $0003a21a, $ffda64ec, $0003c2b5, $ffd91f89, $0003e33f, $ffd7dacf, $000403b8
    Endm
