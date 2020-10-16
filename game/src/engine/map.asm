;------------------------------------------------------------------------------------------
; Map loading and rendering routines
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT Map
        STRUCT_MEMBER.w mapWidth
        STRUCT_MEMBER.w mapHeight
        STRUCT_MEMBER.w mapWidthPatterns
        STRUCT_MEMBER.w mapHeightPatterns
        STRUCT_MEMBER.w mapWidthPixels
        STRUCT_MEMBER.w mapHeightPixels
        STRUCT_MEMBER.l mapDataAddress      ; Uncompressed
        STRUCT_MEMBER.l mapTilesetAddress
        STRUCT_MEMBER.b mapRowOffsetTable
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.l               loadedMap
        VAR.w               mapRowBuffer,               64 + 2 ; 2 word of overflow space. NB: Assumes scrollable plane side will never be 128.
        VAR.w               mapColumnBuffer,            64 + 2
        VAR.VDPDMATransfer  mapRowBufferDMATransfer
        VAR.VDPDMATransfer  mapColumnBufferDMATransfer
    DEFINE_VAR_END


;-------------------------------------------------
; Should be called at least once before using the map library or any time the VDP plane size changes
; ----------------
MapInit:
        move.w  (vdpMetrics + vdpPlaneWidthPatterns), d1
        move.w  (vdpMetrics + vdpPlaneHeightPatterns), d0

        move.w  #2, (mapRowBufferDMATransfer + dmaDataStride)
        move.w  d1, (mapRowBufferDMATransfer + dmaLength)
        move.l  #((mapRowBuffer + SIZE_WORD) >> 1) & $7fffff, (mapRowBufferDMATransfer + dmaSource)

        add.w   d1, d1
        move.w  d1, (mapColumnBufferDMATransfer + dmaDataStride)
        move.w  d0, (mapColumnBufferDMATransfer + dmaLength)
        move.l  #((mapColumnBuffer + SIZE_WORD) >> 1) & $7fffff, (mapColumnBufferDMATransfer + dmaSource)
        rts


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
        movea.l mapTilesetAddress(a0), a0
        jsr     TilesetLoad
        rts


;-------------------------------------------------
; Render the map to the specified VDP background plane VRAM address.
; ----------------
; Input:
; - d0: Top map coorinate (in 8 pixel rows)
; - d1: Left map coordinate (in 8 pixel columns)
; - d2: Plane id
; Uses: d0-d7/a0-a6
MapRender:
        move.w  (vdpMetrics + vdpPlaneHeightPatterns), d3
        subq.w  #1, d3

    .rowLoop:
        PUSHM   d0-d3

        bsr     MapRenderRow
        jsr     VDPDMAQueueFlush        ; TODO: Use direct DMA

        POPM    d0-d3

        addq.w  #1, d0

        dbra    d3, .rowLoop
        rts


;-------------------------------------------------
; Render a single row of the map at the specified plane row
; ----------------
; Input:
; - d0: Map row
; - d1: Map start column
; - d2: Plane id
; Uses: d0-d7/a0-a6
MapRenderRow:
        move.w d0, d6

        ; Queue DMA transfer
        move.w  (vdpMetrics + vdpPlaneHeightPatterns), d4
        subq.w  #1, d4
        and.w   d4, d0
        moveq   #0, d5
        move.w  (vdpMetrics + vdpPlaneWidthShift), d5
        lsl.w   d5, d0
        move.w  d0, d5
        andi.w  #$3fff, d5
        rol.l   #2, d0
        swap    d5
        swap    d0
        or.w    d0, d5
        or.w    #VDP_CMD_AS_DMA, d5
        add.l   d2, d5
        move.l  d5, (mapRowBufferDMATransfer + dmaTarget)

        VDP_DMA_QUEUE_JOB mapRowBufferDMATransfer

        move.w d6, d0

        ; NB: Fall through to _MapRenderRowBuffer


;-------------------------------------------------
; Render a single row of the map to the row buffer
; ----------------
; Input:
; - d0: Map row
; - d1: Map start column
; Uses: d0-d7/a0-a6
_MapRenderRowBuffer:
_START_CHUNK Macro colOffset
            ; Get chunk row address
            move.w  (a1)+, d7                                       ; Chunk ref in d7
            move.w  d7, d5
            and.w   #$ff, d5
            lsl.w   #7, d5
            lea     (a2, d5), a5
            swap    d6                                              ; d6 = chunk row offset
            move.w  d6, d5
            btst    #CHUNK_REF_VFLIP, d7
            beq     .fullChunkNotVFlipped\@
            eor.w   #$0070, d5                                      ; Flip chunk row offset

        .fullChunkNotVFlipped\@:
            If (narg = 1)
                add.w  \colOffset, d5
            EndIf
            moveq   #SIZE_WORD, d4
            btst    #CHUNK_REF_HFLIP, d7
            beq     .fullChunkNotHFlipped\@
            neg.w   d4
            eor.w   #$000e, d5                                      ; Flip chunk column offset

        .fullChunkNotHFlipped\@:
            adda.w  d5, a5                                          ; a5 = chunk block address
            swap    d7
            move.w  d4, d7                                          ; d7 = [chunk reference]:[block address increment]
            swap    d6                                              ; d6 = block row index
        Endm

_RENDER_BLOCK Macro
            move.w  (a5), d3                                        ; d3 = block ref
            adda.w  d7, a5
            swap    d7
            move.w  d3, d4
            eor.w   d7, d3                                          ; d3 = current orientation
            swap    d7
            andi.w  #BLOCK_REF_INDEX_MASK, d4
            lsl.w   #3, d4
            move.w  d6, d5
            btst    #BLOCK_REF_VFLIP, d3
            beq     .blockNotVFlipped\@
            eor.w   #$04, d5                                        ; Flip block row offset

        .blockNotVFlipped\@:
            lea     (a3, d4), a6
            adda.w  d5, a6                                          ; a6 = block row address
            move.l  (a6), d4                                        ; d4 = 2 row pattern refs
            btst    #BLOCK_REF_HFLIP, d3
            bne     .blockHFlipped\@
            swap    d4                                              ; Not flipped so swap words (endianess)

        .blockHFlipped\@:
            add.w   d3, d3                                          ; Allign block+chunk orientation flags with pattern orientation flags
            andi.w  #PATTERN_REF_ORIENTATION_MASK, d3

_RENDER_PATTERN Macro
                eor.w   d3, d4                                      ; orient pattern ref by block + chunk orientation
                and.w   d0, d1                                      ; Wrap buffer position
                move.w  d4, (a4, d1)                                ; Write pattern to row DMA buffer
                addq.w  #SIZE_WORD, d1
            Endm

            _RENDER_PATTERN

            swap    d4

            _RENDER_PATTERN

            Purge _RENDER_PATTERN
        Endm

_RENDER_PARTIAL_CHUNK Macro patternNumber
            addq.w  #1, \patternNumber                              ; In case of a partial block just render the whole block (wastes 34 cycles) (space is reserved in the DMA buffer)
            lsr.w   #1, \patternNumber
            subq.w  #1, \patternNumber

        .renderBlockLoop\@:
            _RENDER_BLOCK
            dbra \patternNumber, .renderBlockLoop\@
        Endm

        ; ---------------------------------------------------------------------------------------
        ; Start of sub routine _MapRenderRowBuffer
        ; ----------------

        ; Load address registers
        movea.l loadedMap, a0
        lea     mapRowOffsetTable(a0), a1                           ; a1 = row offset table
        movea.l mapDataAddress(a0), a0                              ; a0 = map data

        ; Store address of first chunk in a1
        move.w  d1, d5
        lsr.w   #4, d5
        move.w  d0, d6
        lsr.w   #4, d6
        add.w   d6, d6
        move.w  (a1, d6), d6
        add.w   d5, d6
        add.w   d5, d6
        lea     (a0, d6), a1                                        ; a1 = address of chunk reference

        ; d6 = [chunk row offset]:[block row offset]
        move.w  d0, d6
        andi.w  #$0e, d6
        lsl.w   #3, d6
        swap    d6
        move.w  d0, d6
        andi.w  #$01, d6
        add.w   d6, d6
        add.w   d6, d6

        ; Load address registers
        lea     chunkTable, a2
        lea     blockTable, a3
        lea     mapRowBuffer, a4

        ; If first block is full adjust DMA buffer offset
        btst    #0, d1
        bne     .initialBlockPartial
        addq.l  #SIZE_WORD, a4

    .initialBlockPartial:

        ; Buffer offset/rotation mask
        move.w  d1, d2                                              ; d2 = current map column
        move.w  (vdpMetrics + vdpPlaneWidthPatterns), d0
        subq.w  #1, d0
        add.w   d0, d0                                              ; d0 = buffer mask
        andi.w  #~1, d1
        add.w   d1, d1                                              ; d1 = buffer offset

        ; Render chunks

        moveq   #0, d3
        andi.w  #$0f, d2
        beq     .fullChunks

            ; ---------------------------------------------
            ; Render first partial chunk

            move.w  d2, d3
            andi.w  #$0e, d3                                        ; d3 = offset of block column in chunk

            _START_CHUNK d3

            neg.w   d2
            andi.w  #$0f, d2                                        ; d2 = number of patterns rendered

            PUSHW   d2                                              ; Store for later use

            _RENDER_PARTIAL_CHUNK d2

            POPW    d3                                              ; d3 = number of patterns left to render

            ; ---------------------------------------------
            ; Render full chunks

        .fullChunks:
            move.w  (vdpMetrics + vdpPlaneWidthPatterns), d2
            sub.w   d3, d2                                          ; d2 = remaining pattern columns

            PUSHW d2                                                ; Store for later use

            lsr.w   #4, d2                                          ; d2 = number of full chunks

            subq.w  #1, d2
        .fullChunkLoop:

                _START_CHUNK

                    _RENDER_BLOCK
                    _RENDER_BLOCK
                    _RENDER_BLOCK
                    _RENDER_BLOCK
                    _RENDER_BLOCK
                    _RENDER_BLOCK
                    _RENDER_BLOCK
                    _RENDER_BLOCK

            dbra d2, .fullChunkLoop

            ; ---------------------------------------------
            ; Render the last partial chunk

            POPW d2                                                 ; d2 = number of patterns left to render

            andi.w  #$0f, d2
            beq     .done                                           ; Nothing left

            _START_CHUNK

                _RENDER_PARTIAL_CHUNK d2

    .done:

        Purge _START_CHUNK
        Purge _RENDER_BLOCK
        Purge _RENDER_PARTIAL_CHUNK
        rts


;-------------------------------------------------
; Render a single column of the map at the specified plane column for VDP plane A
; ----------------
; Input:
; - d0: Map column
; - d1: Map start row
; - d2: VDP plane id
; Uses: d0-d7/a0-a6
MapRenderColumn:
        move.w d0, d6

        ; Queue DMA transfer
        moveq   #0, d5
        move.w  d0, d5
        move.w  (vdpMetrics + vdpPlaneWidthPatterns), d4
        subq.w  #1, d4
        and.w   d4, d5
        add.w   d5, d5
        swap    d5
        or.w    #VDP_CMD_AS_DMA, d5
        add.l   d2, d5
        move.l  d5, (mapColumnBufferDMATransfer + dmaTarget)

        VDP_DMA_QUEUE_JOB mapColumnBufferDMATransfer

        move.w d6, d0

        ; NB: Fall through to _MapRenderColumnBuffer


;-------------------------------------------------
; Render a single row of the map to the row buffer
; ----------------
; Input:
; - d0: Map column
; - d1: Map start row
; Uses: d0-d7/a0-a6
_MapRenderColumnBuffer:
        rts
