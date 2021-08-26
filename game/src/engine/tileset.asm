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
    BIT_MASK.CHUNK_REF_INDEX            0,  8
    BIT_CONST.CHUNK_REF_RESERVED        8
    BIT_CONST.CHUNK_REF_COLLISION       9
    BIT_CONST.CHUNK_REF_EMPTY           10                                          ; Chunk contains no graphic data
    BIT_MASK.CHUNK_REF_ORIENTATION      11, 2
    BIT_CONST.CHUNK_REF_HFLIP           11
    BIT_CONST.CHUNK_REF_VFLIP           12
    BIT_MASK.CHUNK_REF_OBJECT_GROUP_IDX 13, 3

    ; Block reference structure
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
        
    DEFINE_STRUCT TilesetAnimation, EXTENDS, TilesetAnimationBase
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
        move.l  Tileset_blockMetaDataMappingTableAddress(a0), tilesetMetaDataMapping
        move.l  Tileset_blockMetaDataAddress(a0), a6
        move.l  BlockMetaData_blockCollisionTableAddress(a6), tilesetCollisionData
        move.l  BlockMetaData_blockAngleTableAddress(a6), tilesetAngleData
        movea.l a0, a6

        ; Decompress and move patterns into VRAM.
        ; This must be done before loading the chunks/blocks as the RAM space
        ; for chunks/blocks will be used as the decompressesion buffer.
        movea.l Tileset_patternSectionsTableAddress(a6), a5
        move.w  Tileset_patternSectionCount(a6), d6
        bsr     _TilesetLoadPatternSections

        ; Decompress chunks into RAM
        movea.l Tileset_chunksAddress(a6), a0
        lea     chunkTable, a1
        jsr     ComperDecompress

        ; Decompress blocks into RAM
        movea.l Tileset_blocksAddress(a6), a0
        lea     blockTable, a1
        jsr     ComperDecompress

        ; Load animations
        movea.l Tileset_animationsTableAddress(a6), a5
        move.w  Tileset_animationsCount(a6), d6
        beq     .noAnimations
        bsr     _TilesetLoadAnimations
    .noAnimations:

        ; Load palette
        movea.l Tileset_paletteAddress(a6), a0
        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE a0
        
        ; Install viewport movement handlers last
        jmp _TilesetInstallViewportMovementHandlers


;-------------------------------------------------
; Unload the tileset
; ----------------
TilesetUnload:
        ENGINE_SCHEDULER_DISABLE SCHEDULER_TILESET

        ; Uninstall foreground/background camera handlers
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Viewport_background
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Viewport_foreground

        ; Clear tileset address
        move.l  #NULL, loadedTileset
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
        movea.l (a5)+, a0                                                           ; a0 = Current pattern section address
        move.w  TilesetPatternSection_moduleCount(a0), d7                           ; d7 = Number of compressed modules
        beq    .nextSection                                                         ; No modules in this section then proceed to the next

        lea     TilesetPatternSection_modules(a0), a3                               ; a3 = Current compressed module address
        subq.w  #1, d7

    .loadPatternModuleLoop:
        lea     TilesetPatternModule_patternData(a3), a0
        lea     blockTable, a1
        jsr     ComperDecompress

        VDP_DMA_TRANSFER_COMMAND_LIST TilesetPatternModule_patternDMATransferCommandList(a3)

        ; Next module
        move.w  TilesetPatternModule_patternCompressedSize(a3), d0
        addi.w  #TilesetPatternModule_patternData, d0
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
        movea.l (a5)+, a4                                                           ; a4 = Animation address

        ; Schedule animation
        move.w  TilesetAnimation_animationInitialTrigger(a4), TilesetAnimationSchedule_trigger(a3)
        move.l  #_TilesetAnimationStart, TilesetAnimationSchedule_triggerCallback(a3)
        move.l  a4, TilesetAnimationSchedule_animation(a3)
        adda.w  #TilesetAnimationSchedule_Size, a3

        ; Transfer animation frames
        movea.l TilesetAnimationBase_animationFrameTransferListAddress(a4), a0 ; a0 = Animation frame transfer list address
        movea.l (a0), a0                                                            ; a0 = VDPDMATransferCommandList address for first animation frame

        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE a0

        dbra    d6, .loadAnimationFrameLoop

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
        VIEWPORT_INSTALL_MOVEMENT_CALLBACK Viewport_background, _TilesetCameraMove, Tileset_viewportBackgroundAnimationsAddress(a6)
        VIEWPORT_INSTALL_MOVEMENT_CALLBACK Viewport_foreground, _TilesetCameraMove, Tileset_viewportForegroundAnimationsAddress(a6)
        rts


;-------------------------------------------------
; Schedule all manual animations (animationTrigger = 0)
; ----------------
; Uses: d0-d1/a0-a1
TilesetScheduleManualAnimations:
        lea     tilesetAnimationSchedules, a0
        move.l  loadedTileset, a1
        move.w  Tileset_animationsCount(a1), d0
        beq     .noAnimations
        subq.w  #1, d0

    .animationLoop:
        move.w  TilesetAnimationSchedule_trigger(a0), d1
        bne     .scheduledAnimation
        move.w  #1, TilesetAnimationSchedule_trigger(a0)

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
        move.w  Tileset_animationsCount(a1), d0

        subq.w  #1, d0
    .animationLoop:
        move.w  TilesetAnimationSchedule_trigger(a0), d1

        ; Skip unscheduled animations
        beq     .nextAnimationTrigger
        subq.w  #1, d1
        beq     .triggerAnimation
        move.w  d1, TilesetAnimationSchedule_trigger(a0)
        bra     .nextAnimationTrigger

    .triggerAnimation:
        ; Call animation trigger
        movea.l TilesetAnimationSchedule_triggerCallback(a0), a1
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
        clr.w   TilesetAnimationSchedule_currentFrame(a0)
        move.l  #_TilesetAnimationFrame, TilesetAnimationSchedule_triggerCallback(a0)

        ; Run the initial frame immediately

        ; NB: Fall through to _TilesetAnimationFrame


;-------------------------------------------------
; Update a single frame of the animation
; ----------------
; Input:
; - a0: Animation schedule
; Uses: d0-d2/a0-a1
_TilesetAnimationFrame:
        movea.l TilesetAnimationSchedule_animation(a0), a1

        ; Update frame counter
        move.w  TilesetAnimationSchedule_currentFrame(a0), d0
        move.w  TilesetAnimationBase_animationFrameCount(a1), d1
        move.w  d0, d2
        addq.w  #1, d0
        cmp.w   d1, d0
        bge .finalAnimationFrame

        ; Schedule next frame
        move.w  TilesetAnimation_animationFrameInterval(a1), TilesetAnimationSchedule_trigger(a0)
        move.w  d0, TilesetAnimationSchedule_currentFrame(a0)
        bra .animationFrameScheduleDone

    .finalAnimationFrame:

        ; Schedule next animation trigger
        move.w  TilesetAnimation_animationTriggerInterval(a1), TilesetAnimationSchedule_trigger(a0)
        move.l  #_TilesetAnimationStart, TilesetAnimationSchedule_triggerCallback(a0)

    .animationFrameScheduleDone:

        ; Queue frame data for transfer to VRAM
        movea.l TilesetAnimationBase_animationFrameTransferListAddress(a1), a1      ; a1 = Animation frame transfer list address
        add.w   d2, d2
        add.w   d2, d2
        movea.l (a1, d2), a0                                                        ; a0 = VDPDMATransferCommandList address for animation frame

        VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT a0
        rts


;-------------------------------------------------
; Called when one of the viewport cameras move. Updates viewport scheduled animations.
; ----------------
; Input:
;- a0: Camera address
_TilesetCameraMove:
        movea.l a0, a6                                                              ; a6 = camera
        movea.l Camera_data(a6), a5                                                 ; a5 = TilesetViewportAnimations
        move.w  TilesetViewportAnimations_animationsGroupCount(a5), d7
        beq     .noAnimations
        
        movea.w TilesetViewportAnimations_animationsGroupStateAddress(a5), a2       ; a2 = group state address
        lea     TilesetViewportAnimations_animationsGroupTable(a5), a3              ; a3 = animation group table address
        
        subq.w  #1, d7
    .animationGroupLoop:
        movea.l  (a3)+, a5                                                          ; a5 = current animation group address
        move.w   (a2)+, d1                                                          ; d1 = current animation group state
        
        move.w  TilesetViewportAnimationGroup_cameraProperty(a5), d2
        move.w  (a6, d2), d2                                                        ; d2 = camera position
        move.w  TilesetViewportAnimationGroup_shift(a5), d3                         ; d3 = camera position shift
        lsr.w   d3, d2                                                              ; d2 = new group state
        cmp.w   d1, d2
        beq     .noGroupChange
        
            ; Update group state
            move.w  d2, -SIZE_WORD(a2)
        
            ; Queue animation frames
            lea     TilesetViewportAnimationGroup_animationsTable(a5), a4           ; a4 = current animation
            move.w  TilesetViewportAnimationGroup_animationCount(a5), d3
            subq.w  #1, d3
        .animationLoop:
        
            ; Determine animation frame index
            move.w  d2, d4
            and.w   TilesetAnimationBase_animationFrameCount(a4), d4                ; d4 = animation frame index (animationFrameCount = frame mask for viewport animation = frameCount - 1)
            
            ; Queue animation frame
            movea.l TilesetAnimationBase_animationFrameTransferListAddress(a4), a0
            add.w   d4, d4
            add.w   d4, d4
            movea.l (a0, d4), a0                                                    ; a0 = VDPDMATransferCommandList address for animation frame

            VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT a0

            addq.l  #TilesetAnimationBase_Size, a4
            dbra    d3, .animationLoop
            
    .noGroupChange:
        dbra    d7, .animationGroupLoop
        
    .noAnimations:
        rts
