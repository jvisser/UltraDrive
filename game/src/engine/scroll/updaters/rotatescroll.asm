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
            dc.l $000ab7cc, $ffffbdbf, $000a12a1, $ffffbfc5, $00097240, $ffffc1cd, $0008d6b5, $ffffc3d5
            dc.l $0008400b, $ffffc5df, $0007ae4c, $ffffc7e9, $00072182, $ffffc9f5, $000699b6, $ffffcc02
            dc.l $000616f2, $ffffce0f, $0005993f, $ffffd01d, $000520a5, $ffffd22c, $0004ad2d, $ffffd43c
            dc.l $00043ede, $ffffd64d, $0003d5c1, $ffffd85e, $000371dc, $ffffda70, $00031336, $ffffdc83
            dc.l $0002b9d6, $ffffde96, $000265c2, $ffffe0aa, $000216ff, $ffffe2bf, $0001cd94, $ffffe4d3
            dc.l $00018984, $ffffe6e9, $00014ad5, $ffffe8ff, $0001118b, $ffffeb15, $0000ddaa, $ffffed2b
            dc.l $0000af35, $ffffef42, $00008630, $fffff159, $0000629d, $fffff371, $00004480, $fffff588
            dc.l $00002bd9, $fffff7a0, $000018ab, $fffff9b8, $00000af7, $fffffbd0, $000002bd, $fffffde8
            dc.l $00000000, $00000000, $000002bd, $00000218, $00000af7, $00000430, $000018ab, $00000648
            dc.l $00002bd9, $00000860, $00004480, $00000a78, $0000629d, $00000c8f, $00008630, $00000ea7
            dc.l $0000af35, $000010be, $0000ddaa, $000012d5, $0001118b, $000014eb, $00014ad5, $00001701
            dc.l $00018984, $00001917, $0001cd94, $00001b2d, $000216ff, $00001d41, $000265c2, $00001f56
            dc.l $0002b9d6, $0000216a, $00031336, $0000237d, $000371dc, $00002590, $0003d5c1, $000027a2
            dc.l $00043ede, $000029b3, $0004ad2d, $00002bc4, $000520a5, $00002dd4, $0005993f, $00002fe3
            dc.l $000616f2, $000031f1, $000699b6, $000033fe, $00072182, $0000360b, $0007ae4c, $00003817
            dc.l $0008400b, $00003a21, $0008d6b5, $00003c2b, $00097240, $00003e33, $000a12a1, $0000403b

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
