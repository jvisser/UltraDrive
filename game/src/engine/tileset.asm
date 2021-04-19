;------------------------------------------------------------------------------------------
; Tileset
;------------------------------------------------------------------------------------------

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

tilesetPatternDecompressionBuffer       Equ blockTable


;-------------------------------------------------
; Tile reference structure (16 bit)
; ----------------

    ; Chunk reference structure
    BIT_MASK.CHUNK_REF_INDEX            0,  10                                  ; Not call can be used due to memory constraints
    BIT_CONST.CHUNK_REF_EMPTY           10                                      ; Chunk contains no graphic data
    BIT_MASK.CHUNK_REF_ORIENTATION      11,   2
    BIT_CONST.CHUNK_REF_HFLIP           11
    BIT_CONST.CHUNK_REF_VFLIP           12
    BIT_CONST.CHUNK_REF_COLLISION       13

    ; Block reference structure
    BIT_MASK.BLOCK_REF_INDEX            0,  10
    BIT_CONST.BLOCK_REF_EMPTY           10                                      ; Block contains no graphic data
    BIT_MASK.BLOCK_REF_ORIENTATION      11,   2
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
        STRUCT_MEMBER.w tsChunksCount
        STRUCT_MEMBER.w tsBlocksCount
        STRUCT_MEMBER.w tsPatternCount
        STRUCT_MEMBER.w tsPatternSectionCount
        STRUCT_MEMBER.w tsAnimationsCount
        STRUCT_MEMBER.l tsBlockMetaDataAddress
        STRUCT_MEMBER.l tsBlockMetaDataMappingTableAddress
        STRUCT_MEMBER.l tsChunksAddress                                         ; Compressed
        STRUCT_MEMBER.l tsBlocksAddress                                         ; Compressed
        STRUCT_MEMBER.l tsPatternSectionsTableAddress                           ; Compressed (modular)
        STRUCT_MEMBER.l tsPaletteAddress                                        ; Uncompressed
        STRUCT_MEMBER.l tsAnimationsTableAddress                                ; Uncompressed
        STRUCT_MEMBER.l tsViewportBackgroundAnimationsAddress                   ; Uncompressed
        STRUCT_MEMBER.l tsViewportForegroundAnimationsAddress                   ; Uncompressed
        STRUCT_MEMBER.w tsVramFreeAreaMin
        STRUCT_MEMBER.w tsVramFreeAreaMax
    DEFINE_STRUCT_END

    DEFINE_STRUCT BlockMetaData
        STRUCT_MEMBER.l tsBlockCollisionTableAddress
        STRUCT_MEMBER.l tsBlockAngleTableAddress
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

    DEFINE_STRUCT Chunk
        STRUCT_MEMBER.w tsBlockReferences, CHUNK_ELEMENT_COUNT
    DEFINE_STRUCT_END

    DEFINE_STRUCT Block
        STRUCT_MEMBER.w tsPatternReferences, BLOCK_ELEMENT_COUNT
    DEFINE_STRUCT_END


;-------------------------------------------------
; Tileset animation structures
; ----------------
    DEFINE_STRUCT TilesetAnimationBase
        STRUCT_MEMBER.w tsAnimationFrameCount
        STRUCT_MEMBER.l tsAnimationFrameTransferListAddress
    DEFINE_STRUCT_END
        
    DEFINE_STRUCT TilesetAnimation, EXTENDS, TilesetAnimationBase
        STRUCT_MEMBER.w tsAnimationInitialTrigger
        STRUCT_MEMBER.w tsAnimationTriggerInterval
        STRUCT_MEMBER.w tsAnimationFrameInterval
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetViewportAnimations
        STRUCT_MEMBER.w tsvpAnimationsGroupCount
        STRUCT_MEMBER.w tsvpAnimationsGroupStateAddress
        STRUCT_MEMBER.l tsvpAnimationsGroupTable
    DEFINE_STRUCT_END
    
    DEFINE_STRUCT TilesetViewportAnimationGroup
        STRUCT_MEMBER.w tsvpAnimationGroupCameraProperty
        STRUCT_MEMBER.w tsvpShift
        STRUCT_MEMBER.w tsvpAnimationCount
        STRUCT_MEMBER.w tsvpAnimationsTable
    DEFINE_STRUCT_END

    DEFINE_STRUCT TilesetAnimationSchedule
        STRUCT_MEMBER.w tsAnimationTrigger
        STRUCT_MEMBER.w tsAnimationCurrentFrame
        STRUCT_MEMBER.l tsAnimationTriggerCallback
        STRUCT_MEMBER.l tsAnimation
    DEFINE_STRUCT_END


;-------------------------------------------------
; Tileset variables
; ----------------
    DEFINE_VAR SLOW
        VAR.Block   blockTable,     BLOCK_TABLE_SIZE
        VAR.Chunk   chunkTable,     CHUNK_TABLE_SIZE
    DEFINE_VAR_END

    DEFINE_VAR FAST
        VAR.l                           loadedTileset
        VAR.l                           tilesetCollisionData
        VAR.l                           tilesetAngleData
        VAR.l                           tilesetMetaDataMapping
        VAR.w                           tilesetViewportAnimationGroupStates, TILESET_MAX_VIEWPORT_ANIMATION_GROUPS
        VAR.TilesetAnimationSchedule    tilesetAnimationSchedules,           TILESET_MAX_ANIMATIONS
    DEFINE_VAR_END


;-------------------------------------------------
; Get block meta data mapping for current tileset
; ----------------
TILESET_GET_META_DATA_MAPPING Macro target
        movea.l tilesetMetaDataMapping, \target
    Endm


;-------------------------------------------------
; Get tileset block collision data base address
; ----------------
TILESET_GET_COLLISION_DATA Macro target
        movea.l tilesetCollisionData, \target
    Endm


;-------------------------------------------------
; Get tileset block angle data base address
; ----------------
TILESET_GET_ANGLE_DATA Macro target
        movea.l tilesetCollisionData, \target
    Endm


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
        move.l  a0, loadedTileset
        move.l  tsBlockMetaDataMappingTableAddress(a0), tilesetMetaDataMapping
        move.l  tsBlockMetaDataAddress(a0), a6
        move.l  tsBlockCollisionTableAddress(a6), tilesetCollisionData
        move.l  tsBlockAngleTableAddress(a6), tilesetAngleData
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

        ; TODO: This is not allowed according to the Sega manual: DMA Transfer code running from ROM and the source of the DMA trigger command word in ROM. But it works on my MD1 no TMSS!?
        ; Load palette
        movea.l tsPaletteAddress(a6), a0
        VDP_DMA_TRANSFER_COMMAND_LIST a0
        
        ; Install viewport movement handlers last
        jmp _TilesetInstallViewportMovementHandlers


;-------------------------------------------------
; Unload the tileset
; ----------------
TilesetUnload:
        ENGINE_SCHEDULER_DISABLE SCHEDULER_TILESET

        ; Uninstall foreground/background camera handlers
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK viewportBackground
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK viewportForeground

        ; Clear tileset address
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

    .loadAnimationFrameLoop:
        movea.l (a5)+, a4                                   ; a4 = Animation address

        ; Schedule animation
        move.w  tsAnimationInitialTrigger(a4), tsAnimationTrigger(a3)
        move.l  #_TilesetAnimationStart, tsAnimationTriggerCallback(a3)
        move.l  a4, tsAnimation(a3)
        adda.w  #TilesetAnimationSchedule_Size, a3

        ; Animation frame transfers are stored in DMA queueable VDPDMATransfer format instead of VDPDMATransferCommandList format
        ; So we use the DMA queue to transfer the initial animation frame for all animations
        movea.l tsAnimationFrameTransferListAddress(a4), a0 ; a0 = Animation frame transfer list address
        movea.l (a0), a0                                    ; a0 = VDPDMATransfer address for first animation frame
        jsr     VDPDMAQueueAdd
        dbra    d6, .loadAnimationFrameLoop

        ; Transfer animation frames to VRAM
        jsr     VDPDMAQueueFlush

        ; Enable animation ticker
        ENGINE_SCHEDULER_ENABLE SCHEDULER_TILESET
        rts


;-------------------------------------------------
; Install viewport movement handlers for camera scheduled animations
; ----------------
; Input:
; - a6: Tileset address
_TilesetInstallViewportMovementHandlers:
        
        ; Reset viewport animation group states
        lea     tilesetViewportAnimationGroupStates, a0
        move.w  #TILESET_MAX_VIEWPORT_ANIMATION_GROUPS - 1, d0 
    .clrAnimationGroupStatesLoop:
        move.w  #-1, (a0)+
        dbra    d0, .clrAnimationGroupStatesLoop
        
        ; Install camera movement handlers
        VIEWPORT_INSTALL_MOVEMENT_CALLBACK viewportBackground, _TilesetCameraMove, tsViewportBackgroundAnimationsAddress(a6)
        VIEWPORT_INSTALL_MOVEMENT_CALLBACK viewportForeground, _TilesetCameraMove, tsViewportForegroundAnimationsAddress(a6)
        rts


;-------------------------------------------------
; Schedule all manual animations (tsAnimationTrigger = 0)
; ----------------
; Uses: d0-d1/a0-a1
TilesetScheduleManualAnimations:
        lea     tilesetAnimationSchedules, a0
        move.l  loadedTileset, a1
        move.w  tsAnimationsCount(a1), d0
        beq     .noAnimations
        subq.w  #1, d0

    .animationLoop:
        move.w  tsAnimationTrigger(a0), d1
        bne     .scheduledAnimation
        move.w  #1, tsAnimationTrigger(a0)

    .scheduledAnimation:
        adda.w  #TilesetAnimationSchedule_Size, a0
        dbra    d0, .animationLoop

    .noAnimations:
        rts


;-------------------------------------------------
; Animation scheduler
; ----------------
; Uses: d0-d2/a0-a1
TilesetSchedule:
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
        adda.w  #TilesetAnimationSchedule_Size, a0
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
; Uses: d0-d2/a0-a1
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
        VDP_DMA_QUEUE_ADD a0
        rts


;-------------------------------------------------
; Called when one of the viewport cameras move. Updates viewport scheduled animations.
; ----------------
; Input:
;- a0: Camera address
_TilesetCameraMove:
        movea.l a0, a6                                          ; a6 = camera
        movea.l camData(a6), a5                                 ; a5 = TilesetViewportAnimations
        move.w  tsvpAnimationsGroupCount(a5), d7
        beq     .noAnimations
        
        movea.w tsvpAnimationsGroupStateAddress(a5), a2         ; a2 = group state address
        lea     tsvpAnimationsGroupTable(a5), a3                ; a3 = animation group table address
        
        subq.w  #1, d7
    .animationGroupLoop:
        movea.l  (a3)+, a5                                      ; a5 = current animation group address
        move.w   (a2)+, d1                                      ; d1 = current animation group state
        
        move.w  tsvpAnimationGroupCameraProperty(a5), d2
        move.w  (a6, d2), d2                                    ; d2 = camera position
        move.w  tsvpShift(a5), d3                               ; d3 = camera position shift
        lsr.w   d3, d2                                          ; d2 = new group state
        cmp.w   d1, d2
        beq     .noGroupChange
        
            ; Update group state
            move.w  d2, -SIZE_WORD(a2)
        
            ; Queue animation frames
            lea     tsvpAnimationsTable(a5), a4                 ; a4 = current animation
            move.w  tsvpAnimationCount(a5), d3
            subq.w  #1, d3
        .animationLoop:
        
            ; Determine animation frame index
            move.w  d2, d4
            and.w   tsAnimationFrameCount(a4), d4               ; d4 = animation frame index (tsAnimationFrameCount = frame mask for viewport animation = frameCount - 1)
            
            ; Queue animation frame
            movea.l tsAnimationFrameTransferListAddress(a4), a0
            add.w   d4, d4
            add.w   d4, d4
            movea.l (a0, d4), a0
            VDP_DMA_QUEUE_ADD a0
        
            addq.l  #TilesetAnimationBase_Size, a4
            dbra    d3, .animationLoop
            
    .noGroupChange:
        dbra    d7, .animationGroupLoop
        
    .noAnimations:
        rts
