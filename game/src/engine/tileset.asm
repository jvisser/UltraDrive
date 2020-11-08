;------------------------------------------------------------------------------------------
; Tileset
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Tileset constants
; ----------------
TILESET_MAX_ANIMATIONS              Equ 8

CHUNK_DIMENSION                     Equ 8                                   ; Chunk dimension in blocks
CHUNK_ELEMENT_COUNT                 Equ CHUNK_DIMENSION * CHUNK_DIMENSION
CHUNK_ROW_STRIDE                    Equ CHUNK_DIMENSION * SIZE_WORD
CHUNK_SIZE                          Equ CHUNK_DIMENSION * CHUNK_ROW_STRIDE

BLOCK_DIMENSION                     Equ 2                                   ; Block dimension in patterns
BLOCK_ELEMENT_COUNT                 Equ BLOCK_DIMENSION * BLOCK_DIMENSION
BLOCK_ROW_STRIDE                    Equ BLOCK_DIMENSION * SIZE_WORD
BLOCK_SIZE                          Equ BLOCK_DIMENSION * BLOCK_ROW_STRIDE

CHUNK_TABLE_SIZE                    Equ 192                                 ; Chunk RAM buffer size
BLOCK_TABLE_SIZE                    Equ 384                                 ; Block RAM buffer size

tilesetPatternDecompressionBuffer   Equ blockTable


;-------------------------------------------------
; Tile reference structure (16 bit)
; ----------------

    ; Chunk reference structure
    BIT_MASK.CHUNK_REF_INDEX        0,  10                                  ; Not call can be used due to memory constraints
    BIT_CONST.CHUNK_REF_EMPTY       10                                      ; Chunk contains no graphic data
    BIT_CONST.CHUNK_REF_HFLIP       11
    BIT_CONST.CHUNK_REF_VFLIP       12
    BIT_CONST.CHUNK_REF_COLLISION   13

    ; Block reference structure
    BIT_MASK.BLOCK_REF_INDEX        0,  10
    BIT_CONST.BLOCK_REF_EMPTY       10                                      ; Block contains no graphic data
    BIT_CONST.BLOCK_REF_HFLIP       11
    BIT_CONST.BLOCK_REF_VFLIP       12
    BIT_MASK.BLOCK_REF_SOLIDITY     13, 2
    BIT_MASK.BLOCK_REF_TYPE         15, 1


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
        STRUCT_MEMBER.w tsBlockReferences, CHUNK_ELEMENT_COUNT
    DEFINE_STRUCT_END

    DEFINE_STRUCT Block
        STRUCT_MEMBER.w tsPatternReferences, BLOCK_ELEMENT_COUNT
    DEFINE_STRUCT_END

    DEFINE_STRUCT AnimationSchedule
        STRUCT_MEMBER.w     tsAnimationTrigger
        STRUCT_MEMBER.w     tsAnimationCurrentFrame
        STRUCT_MEMBER.l     tsAnimationTriggerCallback
        STRUCT_MEMBER.l     tsAnimation
    DEFINE_STRUCT_END

    ; Allocate chunk and block tables
    DEFINE_VAR SLOW
        VAR.Block   blockTable,     BLOCK_TABLE_SIZE
        VAR.Chunk   chunkTable,     CHUNK_TABLE_SIZE
    DEFINE_VAR_END

    DEFINE_VAR FAST
        VAR.l                   loadedTileset
        VAR.AnimationSchedule   tilesetAnimationSchedules, TILESET_MAX_ANIMATIONS
    DEFINE_VAR_END


;-------------------------------------------------
; Load tileset into RAM/VRAM
; ----------------
; Input:
; - a0: Tileset address
; Uses: d0-d7/a0-a6
TilesetLoad:
        cmpa.l  loadedTileset, a0
        bne     .loadTileset
        rts                                 ; Already loaded

    .loadTileset:
        movea.l a0, a6

        ; Decompress and move patterns into VRAM.
        ; This must be done before loading the chunks/blocks as the RAM space
        ; for chunks/blocks will be used as the decompressesion buffer.
        movea.l tsPatternSectionsTableAddress(a6), a5
        move.w  tsPatternSectionCount(a6), d6
        bsr     _TilesetLoadPatternSections

        ; Decompress chunks into RAM
        movea.l tsChunksAddress(a6), a0
        lea     chunkTable, a1
        jsr     ComperDecompress

        ; Decompress blocks into RAM
        movea.l tsBlocksAddress(a6), a0
        lea     blockTable, a1
        jsr     ComperDecompress

        ; Load animations
        movea.l tsAnimationsTableAddress(a6), a5
        move.w  tsAnimationsCount(a6), d6
        beq     .noAnimations
        bsr     _TilesetLoadAnimations
    .noAnimations:

        ; Load palette
        movea.l tsPaletteAddress(a6), a0
        VDP_DMA_TRANSFER_COMMAND_LIST a0

        ; Success
        move.l  a6, loadedTileset
        rts


;-------------------------------------------------
; Unload the tileset
; ----------------
TilesetUnload:
        ENGINE_TICKER_DISABLE TICKER_TILESET

        move.l  #0, loadedTileset
        rts


;-------------------------------------------------
; Load all TilesetPatternSections into VRAM
; ----------------
; Input:
; - a5: Pattern section table address
; - d6: Number of pattern sections
; Uses: d0-d7/a0-a3
_TilesetLoadPatternSections:
        subq    #1, d6
    .loadPatternSectionLoop:
        movea.l (a5)+, a0                                   ; a0 = Current pattern section address
        move.w  tsModuleCount(a0), d7                       ; d7 = Number of compressed modules
        beq    .nextSection                                 ; No modules in this section then proceed to the next

        lea     tsModules(a0), a3                           ; a3 = Current compressed module address
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

    .nextSection:
        dbra    d6, .loadPatternSectionLoop
        rts


;-------------------------------------------------
; Load first animation frame of each animation into VRAM and prepare the animation scheduler
; ----------------
; Input:
; - a5: Animation table address
; - d6: Number of animations
; Uses: d0,d6/a0-a1,a3-a5
_TilesetLoadAnimations:
        lea     tilesetAnimationSchedules, a3
        subq    #1, d6

    .loadInitialAnimationFrameLoop:
        movea.l (a5)+, a4                                   ; a4 = Animation address

        ; Schedule animation
        move.w  tsAnimationInitialTrigger(a4), tsAnimationTrigger(a3)
        move.l  #_TilesetAnimationStart, tsAnimationTriggerCallback(a3)
        move.l  a4, tsAnimation(a3)
        adda.w  #AnimationSchedule_Size, a3

        ; Animation frame transfers are stored in DMA queueable VDPDMATransfer format instead of VDPDMATransferCommandList format
        ; So we use the DMA queue to transfer the initial animation frame for all animations
        movea.l tsAnimationFrameTransferListAddress(a4), a0 ; a0 = Animation frame transfer list address
        movea.l (a0), a0                                    ; a0 = VDPDMATransfer address for first animation frame
        jsr     VDPDMAQueueJob
        dbra    d6, .loadInitialAnimationFrameLoop

        ; Transfer animation frames to VRAM
        jsr     VDPDMAQueueFlush

        ; Enable animation ticker
        ENGINE_TICKER_ENABLE TICKER_TILESET
        rts


;-------------------------------------------------
; Animation scheduler
; ----------------
TilesetTick:
        lea     tilesetAnimationSchedules, a0
        move.l  loadedTileset, a1
        move.w  tsAnimationsCount(a1), d0

        subq.w  #1, d0
    .animationLoop:
        move.w  tsAnimationTrigger(a0), d1

        ; Skip unscheduled animations
        beq     .nextAnimationTrigger
        subq.w  #1, d1
        beq     .triggerAnimation
        move.w  d1, tsAnimationTrigger(a0)
        bra     .nextAnimationTrigger

    .triggerAnimation:
        ; Call animation trigger
        movea.l tsAnimationTriggerCallback(a0), a1
        PUSHM    d0/a0
        jsr     (a1)
        POPM    d0/a0

    .nextAnimationTrigger:
        adda.w  #AnimationSchedule_Size, a0
        dbra    d0, .animationLoop
        rts


;-------------------------------------------------
; Initiates animation sequence
; ----------------
; Input:
; - a0: Animation schedule
_TilesetAnimationStart:
        ; Reset the current frame and register animation frame callback
        move.w  #0, tsAnimationCurrentFrame(a0)
        move.l  #_TilesetAnimationFrame, tsAnimationTriggerCallback(a0)

        ; Run the initial frame immediately

        ; NB: Fall through to _TilesetAnimationFrame


;-------------------------------------------------
; Update a single frame of the animation
; ----------------
; Input:
; - a0: Animation schedule
_TilesetAnimationFrame:
        movea.l tsAnimation(a0), a1

        ; Update frame counter
        move.w  tsAnimationCurrentFrame(a0), d0
        move.w  tsAnimationFrameCount(a1), d1
        move.w  d0, d2
        addq.w  #1, d0
        cmp.w   d1, d0
        bge .finalAnimationFrame

        ; Schedule next frame
        move.w  tsAnimationFrameInterval(a1), tsAnimationTrigger(a0)
        move.w  d0, tsAnimationCurrentFrame(a0)
        bra .animationFrameScheduleDone

    .finalAnimationFrame:

        ; Schedule next animation trigger
        move.w  tsAnimationTriggerInterval(a1), tsAnimationTrigger(a0)
        move.l  #_TilesetAnimationStart, tsAnimationTriggerCallback(a0)

    .animationFrameScheduleDone:

        ; Queue frame data for transfer to VRAM
        movea.l tsAnimationFrameTransferListAddress(a1), a1     ; a1 = Animation frame transfer list address
        add.w   d2, d2
        add.w   d2, d2
        movea.l (a1, d2), a0                                    ; a0 = VDPDMATransfer address for animation frame
        VDP_DMA_QUEUE_JOB a0
        rts
