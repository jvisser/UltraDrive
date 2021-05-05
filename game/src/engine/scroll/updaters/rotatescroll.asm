;------------------------------------------------------------------------------------------
; Provides (limited) screen rotation scroll value updaters for horizontal line and vertical cell scroll modes for a SNES Mode7 like effect.
; 64 positions represent angles between -30 to +30
;
; Ignores the camera positions due to:
;   - Compensating vertical column scroll positions based on the horizontal camera position causes jittering due to the 16 pixel increments.
; Thus only really usable for static backgrounds/foregrounds
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Rotate Camera ScrollValueUpdater
; ----------------

    ;-------------------------------------------------
    ; Rotate scroll camera specific configuration
    ; ----------------
    DEFINE_STRUCT RotateScrollCameraConfiguration
        STRUCT_MEMBER.w     rsccHorizontalOffset            ; Additional horizontal scroll to apply
        STRUCT_MEMBER.w     rsccVerticalOffset              ; Additional vertical scroll to apply
        STRUCT_MEMBER.b     rsccAngle                       ; Angle
    DEFINE_STRUCT_END

    ; Used for change detection
    DEFINE_STRUCT RotateScrollCameraState
        STRUCT_MEMBER.w     rscsLastOffset
        STRUCT_MEMBER.b     rscsLastAngle
    DEFINE_STRUCT_END

    DEFINE_STRUCT RotateScrollAngleEntry
        STRUCT_MEMBER.l     rsaeBase                        ; Base scroll value
        STRUCT_MEMBER.l     rsaeIncrement                   ; Increment used to calculate subsequent values
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Rotate horizontal line scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    rotateHorizontalLineScrollCamera:
        ; .svuInit
        dc.l _RotateHorizontalLineScrollCameraInit
        ; .svuUpdate
        dc.l _RotateHorizontalLineScrollCameraUpdate

    ;-------------------------------------------------
    ; Rotate vertical cell scroll camera ScrollValueUpdater definition
    ; ----------------
    ; struct ScrollValueUpdater
    rotateVerticalCellScrollCamera:
        ; .svuInit
        dc.l _RotateVerticalCellScrollCameraInit
        ; .svuUpdate
        dc.l _RotateVerticalCellScrollCameraUpdate


;-------------------------------------------------
; Init horizontal rotation line scroll values
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; - a2: RotateScrollCameraConfiguration address
; Output:
; - a0: Pointer to allocated value updater state
_RotateHorizontalLineScrollCameraInit:

        ; Calculate the scroll table for specified angle
        bsr _RotateHorizontalLineCalculateScrollValues

        ; Allocate value updater state for change detection
        VDP_SCROLL_UPDATER_ALLOCATE RotateScrollCameraState_Size, a0, a1

        ; Store scroll values
        move.w  rsccHorizontalOffset(a2), rscsLastOffset(a0)
        move.w  rsccAngle(a2), rscsLastAngle(a0)
        rts


;-------------------------------------------------
; Update horizontal rotation line scroll values on changes and return flag indicating that values have been updated.
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; - a2: RotateScrollCameraConfiguration address
; - a3: RotateScrollCameraState address
; Output:
; - d0: 1 if values have been updated, 0 otherwise
_RotateHorizontalLineScrollCameraUpdate:
        moveq   #0, d0

        move.b  rsccAngle(a2), d1
        cmp.b   rscsLastAngle(a3), d1
        beq     .noAngleChange

            ; Update last state
            move.w  rsccHorizontalOffset(a2), rscsLastOffset(a3)
            move.b  d1, rscsLastAngle(a3)

            ; Recalculate all values
            bsr     _RotateHorizontalLineCalculateScrollValues
            moveq   #1, d0
            rts

    .noAngleChange:
        move.w  rscsLastOffset(a3), d2
        sub.w   rsccHorizontalOffset(a2), d2
        beq     .noOffsetChange

            ; Update last state
            move.w  rsccHorizontalOffset(a2), rscsLastOffset(a3)

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
; - a0: Camera address
; - a1: Scroll table address
; - a2: RotateScrollCameraConfiguration address
_RotateHorizontalLineCalculateScrollValues:
        ; Calculate RotateScrollAngleEntry offset
        moveq   #0, d0
        move.b  rsccAngle(a2), d0
        lsl.w   #3, d0
        lea     rotateHorizontalLineScrollCameraAngleTable.w, a3

        ; Get angle increment
        move.l  rsaeIncrement(a3, d0), d1

        ; Calculate scroll base
        move.l  rsaeBase(a3, d0), d2

        ; Add horizontal offset from configuration
        moveq   #0, d3
        move.w  rsccHorizontalOffset(a2), d3
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
; - a0: Camera address
; - a1: Scroll table address
; - a2: RotateScrollCameraConfiguration address
; Output:
; - a0: Pointer to allocated value updater state
_RotateVerticalCellScrollCameraInit:
        ; Calculate the scroll table for specified angle
        bsr _RotateVerticalCellCalculateScrollValues

        ; Allocate value updater state for change detection
        VDP_SCROLL_UPDATER_ALLOCATE RotateScrollCameraState_Size, a0, a1

        ; Store scroll values
        move.w  rsccVerticalOffset(a2), rscsLastOffset(a0)
        move.w  rsccAngle(a2), rscsLastAngle(a0)
        rts


;-------------------------------------------------
; Update vertical rotation cell scroll values on changes and return flag indicating that values have been updated.
; ----------------
; Input:
; - a0: Camera address
; - a1: Scroll table address
; - a2: RotateScrollCameraConfiguration address
; - a3: RotateScrollCameraState address
; Output:
; - d0: 1 if values have been updated, 0 otherwise
_RotateVerticalCellScrollCameraUpdate:
        moveq   #0, d0

        move.b  rsccAngle(a2), d1
        cmp.b   rscsLastAngle(a3), d1
        beq     .noAngleChange

            ; Update last state
            move.w  rsccVerticalOffset(a2), rscsLastOffset(a3)
            move.b  d1, rscsLastAngle(a3)

            ; Recalculate all values
            bsr     _RotateVerticalCellCalculateScrollValues
            moveq   #1, d0
            rts

    .noAngleChange:
        move.w  rsccVerticalOffset(a2), d2
        sub.w   rscsLastOffset(a3), d2
        beq     .noOffsetChange

            ; Update last state
            move.w  rsccVerticalOffset(a2), rscsLastOffset(a3)

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
; - a0: Camera address
; - a1: Scroll table address
; - a2: RotateScrollCameraConfiguration address
_RotateVerticalCellCalculateScrollValues:
        ; Calculate RotateScrollAngleEntry offset
        moveq   #0, d0
        move.b  rsccAngle(a2), d0
        lsl.w   #3, d0
        lea     rotateVerticalCellScrollCameraAngleTable.w, a3

        ; Get angle increment
        move.l  rsaeIncrement(a3, d0), d1

        ; Calculate scroll base
        move.l  rsaeBase(a3, d0), d2

        ; Add horizontal offset from configuration
        moveq   #0, d3
        move.w  rsccVerticalOffset(a2), d3
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


    SECTION_START S_FASTDATA

        ;-------------------------------------------------
        ; Angle tables for horizontal and vertical updaters.
        ; ----------------
        ; RotateScrollAngleEntry[]
        rotateHorizontalLineScrollCameraAngleTable:
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

        ; RotateScrollAngleEntry[]
        rotateVerticalCellScrollCameraAngleTable:
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

    SECTION_END
