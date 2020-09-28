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
        VAR.l       loadedTileset
        VAR.Block   blockTable,     BLOCK_TABLE_SIZE
        VAR.Chunk   chunkTable,     CHUNK_TABLE_SIZE
    DEFINE_VAR_END
