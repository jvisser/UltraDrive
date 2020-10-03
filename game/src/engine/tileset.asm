;------------------------------------------------------------------------------------------
; Tileset
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Tileset constants
; ----------------
CHUNK_SIZE                          Equ 8                   ; Chunk dimension in blocks
BLOCK_SIZE                          Equ 2                   ; Block dimension in patterns

CHUNK_TABLE_SIZE                    Equ 192                 ; Chunk RAM buffer size
BLOCK_TABLE_SIZE                    Equ 384                 ; Block RAM buffer size

tilesetPatternDecompressionBuffer   Equ blockTable


;-------------------------------------------------
; Tileset structures
; ----------------

    ; Tileset header
    DEFINE_STRUCT Tileset
        STRUCT_MEMBER.w tsChunksCount
        STRUCT_MEMBER.w tsBlocksCount
        STRUCT_MEMBER.w tsPatternCount
        STRUCT_MEMBER.w tsPatternSectionCount
        STRUCT_MEMBER.w tsAnimationsCount
        STRUCT_MEMBER.l tsChunksAddress                     ; Compressed
        STRUCT_MEMBER.l tsBlocksAddress                     ; Compressed
        STRUCT_MEMBER.l tsPatternSectionsTableAddress       ; Compressed (modular)
        STRUCT_MEMBER.l tsPaletteAddress                    ; Uncompressed
        STRUCT_MEMBER.l tsAnimationsTableAddress            ; Uncompressed
        STRUCT_MEMBER.w tsVramFreeAreaMin
        STRUCT_MEMBER.w tsVramFreeAreaMax
    DEFINE_STRUCT_END

    ; Patterns can be loaded to different areas in VRAM to efficiently fill gaps between VDP objects.
    DEFINE_STRUCT TilesetPatternSection
        STRUCT_MEMBER.w tsModuleCount
        STRUCT_MEMBER.l tsModules
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetPatternModule
        STRUCT_MEMBER.w                         tsPatternCompressedSize
        STRUCT_MEMBER.VDPDMATransferCommandList tsPatternDMATransferCommandList
        STRUCT_MEMBER.w                         tsPatternData
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetPalette
        STRUCT_MEMBER.VDPDMATransferCommandList tsPaletteDMATransferCommandList
        STRUCT_MEMBER.w                         tsColors
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetAnimation
        STRUCT_MEMBER.l tsAnimationFrameTransferListAddress
        STRUCT_MEMBER.w tsAnimationFrameCount
        STRUCT_MEMBER.w tsAnimationInitialTrigger
        STRUCT_MEMBER.w tsAnimationTriggerInterval
        STRUCT_MEMBER.w tsAnimationFrameInterval
    DEFINE_STRUCT_END

    DEFINE_STRUCT Chunk
        STRUCT_MEMBER.w tsBlockReferences, CHUNK_SIZE * CHUNK_SIZE
    DEFINE_STRUCT_END

    DEFINE_STRUCT Block
        STRUCT_MEMBER.w tsPatternReferences, BLOCK_SIZE * BLOCK_SIZE
    DEFINE_STRUCT_END

    ; Allocate chunk and block tables
    DEFINE_VAR SLOW
        VAR.Block   blockTable,     BLOCK_TABLE_SIZE
        VAR.Chunk   chunkTable,     CHUNK_TABLE_SIZE
    DEFINE_VAR_END

    DEFINE_VAR FAST
        VAR.l       loadedTileset
    DEFINE_VAR_END


;-------------------------------------------------
; Load tileset into RAM/VRAM
; ----------------
; Input:
; - a0: Tileset address
; Uses: d0-d7/a0-a6
LoadTileset:
        cmpa.w  loadedTileset, a0
        bne     .loadTileset
        rts                                                 ; Already loaded

    .loadTileset:
        movea.l a0, a6

        ; Decompress and move patterns into VRAM.
        ; This must be done before loading the chunks/blocks as the RAM space
        ; for chunks/blocks will be used as the decompressesion buffer.
        movea.l tsPatternSectionsTableAddress(a6), a5
        move.w  tsPatternSectionCount(a6), d6
        subq    #1, d6
    .loadPatternSectionLoop:
        movea.l (a5)+, a0
        bsr     _LoadPatternSection
        dbra    d6, .loadPatternSectionLoop

        ; Decompress chunks into RAM
        movea.l tsChunksAddress(a6), a0
        lea     chunkTable, a1
        jsr     ComperDecompress

        ; Decompress blocks into RAM
        movea.l tsBlocksAddress(a6), a0
        lea     blockTable, a1
        jsr     ComperDecompress

        ; Load initial frames for all animations
        movea.l tsAnimationsTableAddress(a6), a5
        move.w  tsAnimationsCount(a6), d6
        subq    #1, d6
    .loadInitialAnimationFrameLoop:
        ; Animation frame transfers are stored in DMA queueable VDPDMATransfer format instead of VDPDMATransferCommandList format
        ; So we use the DMA queue to transfer the initial animation frame for all animations
        movea.l (a5)+, a4                                   ; a4 = Animation address
        movea.l tsAnimationFrameTransferListAddress(a4), a0 ; a0 = Animation frame transfer list address
        movea.l (a0), a0                                    ; a0 = VDPDMATransfer address for first animation frame
        jsr     VDPDMAQueueJob
        dbra    d6, .loadInitialAnimationFrameLoop
        jsr     VDPDMAQueueFlush

        ; Load palette
        movea.l tsPaletteAddress(a6), a0
        VDP_DMA_TRANSFER_COMMAND_LIST a0

        ; Success
        move.l  a6, loadedTileset
    rts


;-------------------------------------------------
; Load a TilesetPatternSection into VRAM
; ----------------
; Input:
; - a0: Pattern section address
; Uses: d0-d5,d7/a0-a3
_LoadPatternSection:
        move.w  tsModuleCount(a0), d7
        bne     .nonEmpty
        rts                                                 ; No patterns in this section

    .nonEmpty:
        lea     tsModules(a0), a3
        subq.w  #1, d7

    .loadPatternModuleLoop:

        lea     tsPatternData(a3), a0
        lea     blockTable, a1
        jsr     ComperDecompress

        VDP_DMA_TRANSFER_COMMAND_LIST tsPatternDMATransferCommandList(a3)

        ; Next module
        move.w  tsPatternCompressedSize(a3), d0
        addi.w  #tsPatternData, d0
        adda.w  d0, a3

        dbra    d7, .loadPatternModuleLoop
        rts
