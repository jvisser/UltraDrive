;------------------------------------------------------------------------------------------
; Map loading and rendering routines
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT Map
        STRUCT_MEMBER.w width
        STRUCT_MEMBER.w height
        STRUCT_MEMBER.l mapDataAddress      ; Uncompressed
        STRUCT_MEMBER.l tilesetAddress
        STRUCT_MEMBER.b rowOffsetTable
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.l loadedMap
    DEFINE_VAR_END


;-------------------------------------------------
; Load a map and its associated resources
; ----------------
; Input:
; - a0: Map address
; Uses: d0-d7/a0-a6
MapLoad:
        cmpa.l  loadedMap, a0
        bne     .loadMap
        rts ; Map already loaded

    .loadMap:
        move.l  a0, loadedMap

        ; Load associated tileset
        movea.l tilesetAddress(a0), a0
        jsr     TilesetLoad
        rts


;-------------------------------------------------
; Render the map to the specified VDP background plane VRAM address.
; ----------------
; Input:
; - d0: Left map coordinate (in 8 pixel columns)
; - d1: Top map coorinate (in 8 pixel rows)
; - d2: Plane id
; Uses: d0-d7/a0-a6
MapRender:

        movea.l loadedMap, a0
        movea.l mapDataAddress(a0), a1
        lea     rowOffsetTable(a0), a2
        lea     MEM_VDP_DATA, a3
        lea     chunkTable, a4
        lea     blockTable, a5

        move.l  d2, (MEM_VDP_CTRL)

        move.w  (vdpMetrics + vdpPlaneHeightCells), d3
        subq.w  #1, d3
    .rowLoop:

        movea.l d0, a0
        movea.l d3, a6
        move.w  (vdpMetrics + vdpPlaneWidthCells), d4
        subq.w  #1, d4
    .colLoop:
        ; ----------------------------
        ; Get chunk reference from map

        ; Store map column in d5(low) and chunk local pattern column in (d5)high
        move.w  d0, d5
        andi.w  #$0f, d5
        swap    d5
        move.w  d0, d5
        lsr     #4, d5

        ; Store map row in d6(low) and chunk local pattern row in (d6)high
        move.w  d1, d6
        andi.w  #$0f, d6
        swap    d6
        move.w  d1, d6
        lsr     #4, d6

        ; Fetch chunk reference from map into d7
        move.w  d6, d7
        add.w   d6, d7
        move.w  (a2, d7), d7
        add.w   d5, d7
        add.w   d5, d7
        move.w  (a1, d7), d7

        ; ----------------------------
        ; Get block reference from chunk
        swap    d6
        move.w  d6, d2
        btst    #11, d7
        beq     .chunkNotVFlipped
        not.w   d2
    .chunkNotVFlipped:
        andi.w  #$0e, d2
        lsl.w   #3, d2

        swap    d5
        move.w  d5, d3
        btst    #10, d7
        beq     .chunkNotHFlipped
        not.w   d3
    .chunkNotHFlipped:
        andi.w  #$0e, d3
        add.w   d3, d2          ; d2 = Chunk local block reference address

        move.w  d7, d3          ; Calculate block reference address in chunk table (NB: only 8 of the 10 bits of the tile index are used for chunks)
        lsl.w   #7, d3
        add.w   d2, d3          ; d3 = offset of block reference in chunk table

        move.w  (a4, d3), d3    ; d3 = block reference

        ; ----------------------------
        ; Get pattern reference from block
        eor.w    d3, d7         ; d7 = Combined block and chunk orientation flags

        btst    #11, d7
        beq     .blockNotVFlipped
        not.w   d6
    .blockNotVFlipped:
        andi.w  #1, d6
        add.w   d6, d6
        add.w   d6, d6          ; Pattern row offset

        btst    #10, d7
        beq     .blockNotHFlipped
        not.w   d5
    .blockNotHFlipped:
        andi.w  #1, d5
        add.w   d5, d5          ; Pattern column offset

        add.w   d5, d6          ; d6 = Pattern offset relative to block base address

        move    d3, d5
        andi.w  #$3ff, d5
        lsl.w   #3, d5
        add.w   d6, d5          ; d5 = Offset of pattern reference in chunk table

        move.w  (a5, d5), d5    ; d5 = pattern reference

        ; Reorient pattern reference by chunk and block orientation
        add.w   d7, d7
        andi.w  #$1800, d7
        eor.w   d7, d5

        ; ----------------------------
        ; Write pattern reference to VDP plane
        move.w  d5, (a3)

        addq.w  #1, d0
        dbra    d4, .colLoop

        move.w  a6, d3
        move.w  a0, d0
        addq.w  #1, d1
        dbra    d3, .rowLoop
        rts
