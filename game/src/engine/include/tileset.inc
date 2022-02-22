;------------------------------------------------------------------------------------------
; Tileset
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_TILESET_INC))
__ENGINE_TILESET_INC Equ 1

    Include './lib/common/include/constants.inc'

    Include './system/include/memory.inc'

;-------------------------------------------------
; Tileset constants
; ----------------
TILESET_MAX_ANIMATIONS                  Equ 8
TILESET_MAX_VIEWPORT_ANIMATION_GROUPS   Equ 16

CHUNK_DIMENSION                         Equ 8                                   ; Chunk dimension in blocks
CHUNK_ELEMENT_COUNT                     Equ CHUNK_DIMENSION * CHUNK_DIMENSION
CHUNK_ROW_STRIDE                        Equ CHUNK_DIMENSION * SIZE_WORD
CHUNK_SIZE                              Equ CHUNK_DIMENSION * CHUNK_ROW_STRIDE

BLOCK_DIMENSION                         Equ 2                                   ; Block dimension in patterns
BLOCK_ELEMENT_COUNT                     Equ BLOCK_DIMENSION * BLOCK_DIMENSION
BLOCK_ROW_STRIDE                        Equ BLOCK_DIMENSION * SIZE_WORD
BLOCK_SIZE                              Equ BLOCK_DIMENSION * BLOCK_ROW_STRIDE

CHUNK_TABLE_SIZE                        Equ 192                                 ; Chunk RAM buffer size
BLOCK_TABLE_SIZE                        Equ 384                                 ; Block RAM buffer size


;-------------------------------------------------
; Block reference structure (16 bit)
; ----------------
    BIT_MASK.BLOCK_REF_INDEX            0,  10
    BIT_CONST.BLOCK_REF_EMPTY           10                                          ; Block contains no graphic data
    BIT_MASK.BLOCK_REF_ORIENTATION      11, 2
    BIT_CONST.BLOCK_REF_HFLIP           11
    BIT_CONST.BLOCK_REF_VFLIP           12
    BIT_CONST.BLOCK_REF_SOLID_TOP       13
    BIT_CONST.BLOCK_REF_SOLID_LRB       14
    BIT_MASK.BLOCK_REF_SOLIDITY         13, 2
    BIT_MASK.BLOCK_REF_PRIORITY         15, 1


;-------------------------------------------------
; Tileset main structures
; ----------------

    ; Tileset header
    DEFINE_STRUCT Tileset
        STRUCT_MEMBER.w chunksCount
        STRUCT_MEMBER.w blocksCount
        STRUCT_MEMBER.w patternCount
        STRUCT_MEMBER.w patternSectionCount
        STRUCT_MEMBER.w animationsCount
        STRUCT_MEMBER.l blockMetaDataAddress
        STRUCT_MEMBER.l blockMetaDataMappingTableAddress
        STRUCT_MEMBER.l chunksAddress                                               ; Compressed
        STRUCT_MEMBER.l blocksAddress                                               ; Compressed
        STRUCT_MEMBER.l patternSectionsTableAddress                                 ; Compressed (modular)
        STRUCT_MEMBER.l paletteAddress                                              ; Uncompressed
        STRUCT_MEMBER.l alternativePaletteAddress                                   ; Uncompressed
        STRUCT_MEMBER.l colorTransitionTableAddress                                 ; Uncompressed
        STRUCT_MEMBER.l animationsTableAddress                                      ; Uncompressed
        STRUCT_MEMBER.l viewportBackgroundAnimationsAddress                         ; Uncompressed
        STRUCT_MEMBER.l viewportForegroundAnimationsAddress                         ; Uncompressed
        STRUCT_MEMBER.w vramFreeAreaMin
        STRUCT_MEMBER.w vramFreeAreaMax
    DEFINE_STRUCT_END

    DEFINE_STRUCT BlockMetaData
        STRUCT_MEMBER.l blockCollisionTableAddress
        STRUCT_MEMBER.l blockAngleTableAddress
    DEFINE_STRUCT_END

    ; Patterns can be loaded to different areas in VRAM to efficiently fill gaps between VDP objects.
    DEFINE_STRUCT TilesetPatternSection
        STRUCT_MEMBER.w moduleCount
        STRUCT_MEMBER.l modules
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetPatternModule
        STRUCT_MEMBER.w                         patternCompressedSize
        STRUCT_MEMBER.VDPDMATransferCommandList patternDMATransferCommandList
        STRUCT_MEMBER.w                         patternData
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetPalette
        STRUCT_MEMBER.VDPDMATransferCommandList paletteDMATransferCommandList
        STRUCT_MEMBER.w                         colors
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetColorTransitionTable
        STRUCT_MEMBER.w                         count
        STRUCT_MEMBER.w                         paletteColorOffsets
    DEFINE_STRUCT_END

    DEFINE_STRUCT Chunk
        STRUCT_MEMBER.w blockReferences, CHUNK_ELEMENT_COUNT
    DEFINE_STRUCT_END

    DEFINE_STRUCT Block
        STRUCT_MEMBER.w patternReferences, BLOCK_ELEMENT_COUNT
    DEFINE_STRUCT_END


;-------------------------------------------------
; Tileset animation structures
; ----------------
    DEFINE_STRUCT TilesetAnimationBase
        STRUCT_MEMBER.w animationFrameCount
        STRUCT_MEMBER.l animationFrameTransferListAddress
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetAnimation, TilesetAnimationBase
        STRUCT_MEMBER.w animationInitialTrigger
        STRUCT_MEMBER.w animationTriggerInterval
        STRUCT_MEMBER.w animationFrameInterval
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetViewportAnimations
        STRUCT_MEMBER.w animationsGroupCount
        STRUCT_MEMBER.w animationsGroupStateAddress
        STRUCT_MEMBER.l animationsGroupTable
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetViewportAnimationGroup
        STRUCT_MEMBER.w cameraProperty
        STRUCT_MEMBER.w shift
        STRUCT_MEMBER.w animationCount
        STRUCT_MEMBER.w animationsTable
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetAnimationSchedule
        STRUCT_MEMBER.w trigger
        STRUCT_MEMBER.w currentFrame
        STRUCT_MEMBER.l triggerCallback
        STRUCT_MEMBER.l animation
    DEFINE_STRUCT_END


;-------------------------------------------------
; Get tileset address
; ----------------
TILESET_GET Macros target
        move.l loadedTileset, \target


;-------------------------------------------------
; Get block meta data mapping for current tileset
; ----------------
TILESET_GET_META_DATA_MAPPING Macros target
        move.l tilesetMetaDataMapping, \target


;-------------------------------------------------
; Get tileset block collision data base address
; ----------------
TILESET_GET_COLLISION_DATA Macros target
        move.l tilesetCollisionData, \target


;-------------------------------------------------
; Get tileset block angle data base address
; ----------------
TILESET_GET_ANGLE_DATA Macros target
        move.l tilesetCollisionData, \target

    EndIf
