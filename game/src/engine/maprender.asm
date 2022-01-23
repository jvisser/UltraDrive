;------------------------------------------------------------------------------------------
; Map rendering routines (Needs a serious rewrite at some point)
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'
    Include './system/include/vdp.inc'
    Include './system/include/vdpdmaqueue.inc'

    Include './engine/include/map.inc'
    Include './engine/include/tileset.inc'

;-------------------------------------------------
; Map render buffers
; ----------------
    DEFINE_VAR SHORT
        VAR.VDPDMATransfer  mapRowBufferDMATransfer
        VAR.VDPDMATransfer  mapColumnBufferDMATransfer
    DEFINE_VAR_END


;-------------------------------------------------
; Should be called at least once before using the map library or any time the VDP plane size changes
; ----------------
MapRenderInit:
        move.w  (vdpMetrics + VDPMetrics_planeWidthPatterns), d1
        move.w  (vdpMetrics + VDPMetrics_planeHeightPatterns), d0

        move.w  #2, (mapRowBufferDMATransfer + VDPDMATransfer_dataStride)
        move.w  d1, (mapRowBufferDMATransfer + VDPDMATransfer_length)
        move.w  #$007f, (mapRowBufferDMATransfer + VDPDMATransfer_source)

        add.w   d1, d1
        move.w  d1, (mapColumnBufferDMATransfer + VDPDMATransfer_dataStride)
        move.w  d0, (mapColumnBufferDMATransfer + VDPDMATransfer_length)
        move.w  #$007f, (mapColumnBufferDMATransfer + VDPDMATransfer_source)
        rts


;-------------------------------------------------
; Shared macros between row/column renderer
; ----------------

_BUFFER_ACCESS_MODE_WRAPPED     Equ 0
_BUFFER_ACCESS_MODE_CONTINUOUS  Equ 1

_BUFFER_ACCESS_MODE = _BUFFER_ACCESS_MODE_WRAPPED

;-------------------------------------------------
; Render a single pattern to the render buffer
; ----------------
; Input:
; - d0: Buffer mask
; - d1: Buffer offset
; - d4: Pattern reference
; - d3: Orientation flags of chunk + block
_RENDER_PATTERN Macro mode
            eor.w   d3, d4                                          ; orient pattern ref by block + chunk orientation
            swap    d3
            or.w    d3, d4                                          ; Add block priority override
            If (_BUFFER_ACCESS_MODE = _BUFFER_ACCESS_MODE_WRAPPED)
                and.w   d0, d1                                      ; Wrap buffer position
                move.w  d4, (a4, d1)                                ; Write pattern to DMA buffer
                addq.w  #SIZE_WORD, d1
            Else
                move.w  d4, (a4)+                                   ; Write pattern to DMA buffer
            EndIf
    Endm


;-------------------------------------------------
; Render a single fixed value pattern to the render buffer
; ----------------
_RENDER_PATTERN_FIXED Macro value
            If (_BUFFER_ACCESS_MODE = _BUFFER_ACCESS_MODE_WRAPPED)
                and.w   d0, d1                                      ; Wrap buffer position
                move.w  \value, (a4, d1)                            ; Write empty pattern to DMA buffer.
                addq.w  #SIZE_WORD, d1
            Else
                move.w  \value, (a4)+                               ; Write pattern to DMA buffer
            EndIf
    Endm


;-------------------------------------------------
; Render a partial chunk that is empty
; ----------------
_RENDER_PARTIAL_CHUNK_FIXED Macro patternNumber, value
            neg.w   \patternNumber
            andi.w  #$0f, \patternNumber
            subq.w  #1, \patternNumber
            lsl.w   #3, \patternNumber
            jmp     .patternRenderers\@(pc, \patternNumber)

        .patternRenderers\@:
            Rept 15
                _RENDER_PATTERN_FIXED \value
            Endr
    Endm


;-------------------------------------------------
; Render a partial chunk based on the amount of patterns given
; ----------------
_RENDER_PARTIAL_CHUNK Macro start, patternNumber
            If (strcmp('\start', 'START'))
                btst    #0, \patternNumber
                beq.s   .fullBlocks\@

                _RENDER_BLOCK END                                   ; Only render the last pattern of the first block

            ElseIf (strcmp('\start', 'END'))

                PUSHW   \patternNumber                              ; Store for last block

            EndIf

        .fullBlocks\@:
            lsr.w   #1, \patternNumber
            beq     .fullBlocksDone\@
            subq.w  #1, \patternNumber

        .renderBlockLoop\@:
            _RENDER_BLOCK
            dbra \patternNumber, .renderBlockLoop\@

        .fullBlocksDone\@:

        If (strcmp('\start', 'END'))
            POPW   \patternNumber

            btst    #0, \patternNumber
            beq.s   .chunkDone\@

            _RENDER_BLOCK START                                     ; Only render the first pattern of the last block

        EndIf

        .chunkDone\@:
    Endm


;-------------------------------------------------
; Render the full render buffer
; ----------------
; Input:
; - a0: Number of patterns to render
; - a4: Render buffer
; - d2: Map start row/column (Opposite of rendered dimension)
; Reserved registers: a2-a4
; Required macros:
; - _READ_CHUNK
; - _START_CHUNK
; - _RENDER_BLOCK
_RENDER_BUFFER Macro
            ; Load address registers
            lea     chunkTable, a2
            lea     blockTable, a3

            moveq   #0, d3
            andi.w  #$0f, d2
            beq     .fullChunks\@

            ; ---------------------------------------------
            ; Render first partial chunk

            move.w  d2, d3
            andi.w  #$0e, d3                                        ; d3 = offset of block row/column in chunk
            neg.w   d2
            andi.w  #$0f, d2                                        ; d2 = number of patterns rendered

            _READ_CHUNK
                btst    #CHUNK_REF_EMPTY, d7
                bne     .startChunkEmpty\@

                    _START_CHUNK d3

                    PUSHW   d2                                     ; Store for later use
                    _RENDER_PARTIAL_CHUNK START, d2
                    POPW    d3                                     ; d3 = number of patterns left to render
                    bra     .startChunkDone\@

            .startChunkEmpty\@:
                move.w  d2, d3
                moveq   #0, d4
                _RENDER_PARTIAL_CHUNK_FIXED d2, d4

            .startChunkDone\@:

            ; ---------------------------------------------
            ; Render full chunks

        .fullChunks\@:
            move.w  a0, d2
            sub.w   d3, d2                                          ; d2 = remaining pattern columns

            PUSHW d2                                                ; Store for later use

            lsr.w   #4, d2                                          ; d2 = number of full chunks
            beq     .lastChunk\@

            subq.w  #1, d2
        .fullChunkLoop\@:

_BUFFER_ACCESS_MODE = _BUFFER_ACCESS_MODE_CONTINUOUS

                and.w   d0, d1

                _READ_CHUNK
                    btst    #CHUNK_REF_EMPTY, d7
                    bne     .fullChunkEmpty\@

                    _START_CHUNK
                        PUSHW   a4
                        lea     (a4, d1), a4
                        Rept 8
                            _RENDER_BLOCK
                        Endr
                        POPW    a4
                        bra     .fullChunkDone\@

                .fullChunkEmpty\@:
                    moveq   #0, d3
                    lea     (a4, d1), a5
                    Rept 8
                        move.l  d3, (a5)+
                    Endr

                .fullChunkDone\@:
                    addi.w  #32, d1

            dbra    d2, .fullChunkLoop\@

_BUFFER_ACCESS_MODE = _BUFFER_ACCESS_MODE_WRAPPED

            ; ---------------------------------------------
            ; Render the last partial chunk
    .lastChunk\@:
            POPW d2                                                 ; d2 = number of patterns left to render

            andi.w  #$0f, d2
            beq     .done\@                                         ; Nothing left

            _READ_CHUNK
                btst    #CHUNK_REF_EMPTY, d7
                bne     .endChunkEmpty\@

                _START_CHUNK
                    _RENDER_PARTIAL_CHUNK END, d2
                    bra .done\@

                .endChunkEmpty\@:
                    moveq   #0, d4
                    _RENDER_PARTIAL_CHUNK_FIXED d2, d4
    .done\@:
    Endm


;-------------------------------------------------
; Render a single row of the specified map at the specified plane
; ----------------
; Input:
; - a0: Map address
; - d0: Map row
; - d1: Map start column
; - d2: Width to render
; - d3: Plane id
; Uses: d0-d7/a0-a6
MapRenderRow:
        ; Load address registers
        lea     Map_rowOffsetTable(a0), a1                          ; a1 = row offset table
        movea.l Map_dataAddress(a0), a0                             ; a0 = map data

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

        ; NB: Fall through to MapRenderRowBuffer


;-------------------------------------------------
; Render a single row of the map to a DMA buffer
; ----------------
; Input: (TODO: Rearange register allocation to align with calling convention)
; - a1: Address of first chunk
; - d0: Map row
; - d1: Map start column
; - d2: Width to render
; Uses: d0-d7/a0-a6
MapRenderRowBuffer:
_READ_CHUNK Macro
            move.w  (a1)+, d7                                       ; Chunk ref in d7
    Endm

_START_CHUNK Macro colOffset
            move.w  d7, d5
            lsl.w   #7, d5
            lea     (a2, d5), a5
            swap    d6                                              ; d6 = chunk row offset
            move.w  d6, d5
            btst    #CHUNK_REF_VFLIP, d7
            beq.s   .chunkNotVFlipped\@
            eor.w   #$0070, d5                                      ; Flip chunk row offset

        .chunkNotVFlipped\@:
            If (narg = 1)
                add.w  \colOffset, d5
            EndIf
            moveq   #SIZE_WORD, d4
            btst    #CHUNK_REF_HFLIP, d7
            beq.s   .chunkNotHFlipped\@
            neg.w   d4
            eor.w   #$000e, d5                                      ; Flip chunk column offset

        .chunkNotHFlipped\@:
            adda.w  d5, a5                                          ; a5 = chunk block address
            swap    d7
            move.w  d4, d7                                          ; d7 = [chunk reference]:[block address increment]
            swap    d6                                              ; d6 = block row index
    Endm

_RENDER_BLOCK Macro position
            move.w  (a5), d3                                        ; d3 = block ref
            adda.w  d7, a5
            btst    #BLOCK_REF_EMPTY, d3
            bne.s   .blockEmpty\@
            move.w  d3, d4
            andi.w  #BLOCK_REF_PRIORITY_MASK, d3
            swap    d3
            move.w  d4, d3
            swap    d7
            eor.w   d7, d3                                          ; d3 = [block priority]:[current orientation]
            swap    d7
            andi.w  #BLOCK_REF_INDEX_MASK, d4
            lsl.w   #3, d4
            add.w   d6, d4
            btst    #BLOCK_REF_VFLIP, d3
            beq.s   .blockNotVFlipped\@
            eor.w   #$04, d4                                        ; Flip block row offset

        .blockNotVFlipped\@:
            move.l  (a3, d4), d4                                    ; d4 = 2 row pattern refs
            btst    #BLOCK_REF_HFLIP, d3
            bne.s   .blockHFlipped\@
            swap    d4                                              ; Not flipped so swap words (endianess)

        .blockHFlipped\@:
            andi.w  #PATTERN_REF_ORIENTATION_MASK, d3

            If ((narg = 0) | strcmp('\position', 'START'))
                _RENDER_PATTERN
                swap    d3
            EndIf

            If ((narg = 0) | strcmp('\position', 'END'))
                swap    d4
                _RENDER_PATTERN
            EndIf
            bra     .blockDone\@

        .blockEmpty\@:
            moveq   #0, d4
            If ((narg = 0) | strcmp('\position', 'START'))
                _RENDER_PATTERN_FIXED d4
            EndIf

            If ((narg = 0) | strcmp('\position', 'END'))
                _RENDER_PATTERN_FIXED d4
            EndIf

        .blockDone\@:
    Endm

        ; ---------------------------------------------------------------------------------------
        ; Start of sub routine _MapRenderRowBuffer
        ; ----------------
        ; Register allocation:
        ; - d0: Buffer mask for looping
        ; - d1: Buffer offset
        ; - d2: Map start column
        ; - a0: width to be rendered
        ; - a1: Address of first chunk in map
        ; - a2: Base address of chunk table
        ; - a3: Base address of block table
        ; - a4: Base address of renderbuffer

        ; ---------------------------------------------------------------------------------------
        ; Setup DMA
        ; ----------------

        ; Save values
        movea.l a1, a6
        move.w  d0, d6

        ; Calculate and set DMA target
        move.w  (vdpMetrics + VDPMetrics_planeHeightPatterns), d4
        subq.w  #1, d4
        and.w   d4, d0
        moveq   #0, d5
        move.w  (vdpMetrics + VDPMetrics_planeWidthShift), d5
        lsl.w   d5, d0
        move.w  d0, d5
        andi.w  #$3fff, d0
        rol.l   #2, d5
        move.w  d0, d5
        swap    d5
        or.w    #VDP_CMD_AS_DMA, d5
        add.l   d3, d5
        move.l  d5, (mapRowBufferDMATransfer + VDPDMATransfer_target)

        ; Allocate buffer memory
        move.w  (vdpMetrics + VDPMetrics_planeWidthPatterns), d0
        add.w   d0, d0
        jsr     MemoryDMAAllocate
        movea.l a0, a4  ; Store buffer address parameter for _MapRenderRowBuffer

        ; Calculate and set DMA source to allocated buffer
        move.w  a0, d5
        asr.w   #1, d5
        move.w  d5, (mapRowBufferDMATransfer + VDPDMATransfer_source + 2)

        ; Queue buffer for transfer
        VDP_DMA_QUEUE_ADD mapRowBufferDMATransfer

        ; Restore values
        movea.l a6, a1
        move.w d6, d0

        ; ---------------------------------------------------------------------------------------
        ; Calculate stuff needed for _RENDER_BUFFER
        ; ----------------

        ; d6 = [chunk row offset]:[block row offset]
        move.w  d0, d6
        andi.w  #$0e, d6
        lsl.w   #3, d6
        swap    d6
        move.w  d0, d6
        andi.w  #$01, d6
        add.w   d6, d6
        add.w   d6, d6

        ; Buffer offset/rotation mask
        movea.w  d2, a0                                             ; a0 = render size
        move.w  d1, d2                                              ; d2 = current map column
        move.w  (vdpMetrics + VDPMetrics_planeWidthPatterns), d0
        subq.w  #1, d0
        add.w   d0, d0                                              ; d0 = buffer mask
        add.w   d1, d1                                              ; d1 = buffer offset

        _RENDER_BUFFER

        Purge _START_CHUNK
        Purge _RENDER_BLOCK
        rts


;-------------------------------------------------
; Render a single column of the map at the specified plane
; ----------------
; Input:
; - a0: Map address
; - d0: Map column
; - d1: Map start row
; - d2: Height to render
; - d3: VDP plane id
; Uses: d0-d7/a0-a6
MapRenderColumn:

        ; Load address registers
        moveq   #0, d7
        move.w  Map_width(a0), d7
        lea     Map_rowOffsetTable(a0), a1                           ; a1 = row offset table
        movea.w Map_stride(a0), a6                                   ; a6 = map stride
        movea.l Map_dataAddress(a0), a0                              ; a0 = map data

        ; Store address of first chunk in a1
        move.w  d0, d5
        lsr.w   #4, d5
        move.w  d1, d6
        lsr.w   #4, d6
        add.w   d6, d6
        move.w  (a1, d6), d6
        add.w   d5, d6
        add.w   d5, d6
        lea     (a0, d6), a1                                        ; a1 = address of chunk reference

        ; NB: Fall through to MapRenderColumnBuffer


;-------------------------------------------------
; Render a single column of the map to a DMA buffer
; ----------------
; Input: (TODO: Rearange register allocation to align with calling convention)
; - a1: Address of first chunk
; - a6: Map row stride
; - d0: Map column
; - d1: Map start row
; - d2: Height to render
; Uses: d0-d7/a0-a6
MapRenderColumnBuffer:
_READ_CHUNK Macro
            move.w  (a1), d7                                        ; Chunk ref in d7
            adda.w  a6, a1
    Endm

_START_CHUNK Macro rowOffset
            move.w  d7, d5
            lsl.w   #7, d5
            lea     (a2, d5), a5
            swap    d6                                              ; d6 = chunk column offset
            move.w  d6, d5

            If (narg = 1)
                lsl.w   #3, \rowOffset
                add.w  \rowOffset, d5
            EndIf

            moveq   #CHUNK_ROW_STRIDE, d4
            btst    #CHUNK_REF_VFLIP, d7
            beq.s   .chunkNotVFlipped\@
            eor.w   #$0070, d5                                      ; Flip chunk row offset
            neg.w   d4

        .chunkNotVFlipped\@:
            btst    #CHUNK_REF_HFLIP, d7
            beq.s   .chunkNotHFlipped\@
            eor.w   #$000e, d5                                      ; Flip chunk column offset

        .chunkNotHFlipped\@:
            adda.w  d5, a5                                          ; a5 = chunk block address
            swap    d7
            move.w  d4, d7                                          ; d7 = [chunk reference]:[block address increment]
            swap    d6                                              ; d6 = block column index
    Endm

_RENDER_BLOCK Macro position
            move.w  (a5), d3                                        ; d3 = block ref
            adda.w  d7, a5
            btst    #BLOCK_REF_EMPTY, d3
            bne.s   .blockEmpty\@
            move.w  d3, d4
            andi.w  #BLOCK_REF_PRIORITY_MASK, d3
            swap    d3
            move.w  d4, d3
            swap    d7
            eor.w   d7, d3                                          ; d3 = [block priority]:[current orientation]
            swap    d7
            andi.w  #BLOCK_REF_INDEX_MASK, d4
            lsl.w   #3, d4
            add.w   d6, d4
            btst    #BLOCK_REF_HFLIP, d3
            beq.s   .blockNotHFlipped\@
            eor.w   #$02, d4
        .blockNotHFlipped\@:
            move.w  (a3, d4), d5
            move.w  4(a3, d4), d4
            btst    #BLOCK_REF_VFLIP, d3
            bne.s   .blockVFlipped\@
            exg     d4, d5

        .blockVFlipped\@:
            andi.w  #PATTERN_REF_ORIENTATION_MASK, d3

            If ((narg = 0) | strcmp('\position', 'START'))
                _RENDER_PATTERN
                swap    d3
            EndIf

            If ((narg = 0) | strcmp('\position', 'END'))
                move.w  d5, d4
                _RENDER_PATTERN
            EndIf
            bra     .blockDone\@

        .blockEmpty\@:
            moveq   #0, d4
            If ((narg = 0) | strcmp('\position', 'START'))
                _RENDER_PATTERN_FIXED d4
            EndIf

            If ((narg = 0) | strcmp('\position', 'END'))
                _RENDER_PATTERN_FIXED d4
            EndIf

        .blockDone\@:
    Endm

        ; ---------------------------------------------------------------------------------------
        ; Start of sub routine _MapRenderColumnBuffer
        ; ----------------
        ; Register allocation:
        ; - d0: Buffer mask for looping
        ; - d1: Buffer offset
        ; - d2: Map start row
        ; - a0: height to be rendered
        ; - a1: Address of first chunk in map
        ; - a2: Base address of chunk table
        ; - a3: Base address of block table
        ; - a4: Base address of renderbuffer

        ; ---------------------------------------------------------------------------------------
        ; Setup DMA
        ; ----------------
        ; Save values
        movea.l a1, a5
        move.w d0, d6

        ; Calculate and set DMA target
        moveq   #0, d5
        move.w  d0, d5
        move.w  (vdpMetrics + VDPMetrics_planeWidthPatterns), d4
        subq.w  #1, d4
        and.w   d4, d5
        add.w   d5, d5
        swap    d5
        or.w    #VDP_CMD_AS_DMA, d5
        add.l   d3, d5
        move.l  d5, (mapColumnBufferDMATransfer + VDPDMATransfer_target)

        ; Allocate buffer memory
        move.w  (vdpMetrics + VDPMetrics_planeHeightPatterns), d0
        add.w   d0, d0
        jsr     MemoryDMAAllocate
        movea.l a0, a4  ; Store buffer address parameter for _MapRenderColumnBuffer

        ; Calculate and set DMA source to allocated buffer
        move.w  a0, d5
        asr.w   #1, d5
        move.w  d5, (mapColumnBufferDMATransfer + VDPDMATransfer_source + 2)

        ; Queue buffer for transfer
        VDP_DMA_QUEUE_ADD mapColumnBufferDMATransfer

        ; Restore values
        movea.l a5, a1
        move.w d6, d0

        ; ---------------------------------------------------------------------------------------
        ; Calculate stuff needed for _RENDER_BUFFER
        ; ----------------

        ; d6 = [chunk column offset]:[block column offset]
        move.w  d0, d6
        andi.w  #$0e, d6
        swap    d6
        move.w  d0, d6
        andi.w  #$01, d6
        add.w   d6, d6

        ; Buffer offset/rotation mask
        movea.w  d2, a0                                             ; a0 = render size
        move.w  d1, d2                                              ; d2 = current map column
        move.w  (vdpMetrics + VDPMetrics_planeHeightPatterns), d0
        subq.w  #1, d0
        add.w   d0, d0                                              ; d0 = buffer mask
        add.w   d1, d1                                              ; d1 = buffer offset

        _RENDER_BUFFER

        Purge _START_CHUNK
        Purge _RENDER_BLOCK
        rts


    Purge _RENDER_PATTERN
    Purge _RENDER_PARTIAL_CHUNK
    Purge _RENDER_BUFFER