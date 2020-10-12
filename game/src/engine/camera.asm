;------------------------------------------------------------------------------------------
; Camera system
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT Camera
        STRUCT_MEMBER.w camX
        STRUCT_MEMBER.w camY
        STRUCT_MEMBER.w camPlaneRow
        STRUCT_MEMBER.w camPlaneColumn
        STRUCT_MEMBER.w camMinX             ; When camX goes below camMinX decrease camPlaneColumn and render column at (camPlaneColumn & (vdpPlaneWidthCells - 1)) for map column (camMinX >> 3).
        STRUCT_MEMBER.w camMaxX             ; When camX goes beyond camMaxX increase camPlaneColumn and render column at (camPlaneColumn & (vdpPlaneWidthCells - 1)) for map column (camMinX >> 3).
        STRUCT_MEMBER.w camMinY             ; When camY goes below camMinY decrease camPlaneRow and render row at (camPlaneRow & (vdpPlaneHeightCells - 1)) for map column (camMinY >> 3).
        STRUCT_MEMBER.w camMaxY             ; When camY goes beyond camMaxY increase camPlaneRow and render row at (planeRow & (vdpPlaneHeightCells - 1)) for map column (camMaxY >> 3).
        STRUCT_MEMBER.l camScrollUpdate     ; Sub routine to update the hardware (VDP) scroll position (should preserve d0-d3)
        STRUCT_MEMBER.w camScrollX
        STRUCT_MEMBER.w camScrollY
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.Camera camera
    DEFINE_VAR_END



;-------------------------------------------------
; Initialize camera to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: Address of scroll update routine. If null the default will be used (update first entry of horizontal/vertical scroll ram)
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
CameraInit:
_VIEWPORT_CLAMP Macro component, mapSize, screenSize
                tst.w   \component
                bpl     .positive\@
                moveq   #0, \component
                bra     .clipDone\@
            .positive\@:
                move.w  \mapSize(a2), d7
                sub.w   \screenSize(a3), d7
                cmp.w   d7, \component
                blt     .clipDone\@
                move.w  d7, \component
            .clipDone\@:
        Endm

        lea     camera, a1
        movea.l loadedMap, a2
        lea     vdpMetrics, a3

        ; Clamp viewport to map
        _VIEWPORT_CLAMP d0, mapWidthPixels,  vdpScreenWidth
        _VIEWPORT_CLAMP d1, mapHeightPixels, vdpScreenHeight

        move.w  d0, d2
        move.w  d1, d3
        moveq   #0, d4

        move.w  d0, camX(a1)
        move.w  d1, camY(a1)
        move.w  d4, camPlaneRow(a1)
        move.w  d4, camPlaneColumn(a1)

        ; Set scroll update routine
        cmpa.w  #0, a0
        bne     .scrollHandlerSupplied
        lea     _CameraDefaultScrollUpdate, a0
    .scrollHandlerSupplied:
        move.l  a0, camScrollUpdate(a1)

        ; Clamp vpd plane to map
        _VIEWPORT_CLAMP d0, mapWidthPixels,  vdpPlaneWidth
        _VIEWPORT_CLAMP d1, mapHeightPixels, vdpPlaneHeight
        move.w  d2, d5              ; Store relative distance to viewport in d5,d6
        move.w  d3, d6
        sub.w   d0, d5
        sub.w   d1, d6
        move.w  d0, d2
        move.w  d1, d3

        ; Calculate camera min position
        andi.w  #~PATTERN_MASK, d0
        andi.w  #~PATTERN_MASK, d1
        move.w  d0, camMinX(a1)
        move.w  d1, camMinY(a1)

        ; Calculate camera max position
        add.w   vdpPlaneWidth(a3), d0
        add.w   vdpPlaneHeight(a3), d1
        subq.w  #1, d0
        subq.w  #1, d1
        move.w  d0, camMaxX(a1)
        move.w  d1, camMaxY(a1)

        ; Update scroll
        move.w  d2, d0
        move.w  d3, d1
        andi.w  #PATTERN_MASK, d0
        andi.w  #PATTERN_MASK, d1
        add.w   d5, d0              ; Adjust for plane clamp
        add.w   d6, d1
        move.w  d0, camScrollX(a1)
        move.w  d1, camScrollY(a1)
        jsr     (a0)

        ; Render map at camera position
        lsr.w   #PATTERN_SHIFT, d2  ; Calculate map position in (8 pixel) columns and rows
        lsr.w   #PATTERN_SHIFT, d3
        move.w  d2, d0
        move.w  d3, d1
        move.l  #PLANE_A, d2
        jsr     MapRender

        Purge _VIEWPORT_CLAMP
        rts


;-------------------------------------------------
; Default hardware scroll camera update handler
; ----------------
; Input:
; - d0: Horizontal scroll
; - d1: Vertical scroll
; Uses: d0-d1
_CameraDefaultScrollUpdate:
        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, HSCROLL_ADDR
        neg.w   d0
        move.w  d0, (MEM_VDP_DATA)

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00
        move.w  d1, (MEM_VDP_DATA)
        rts
