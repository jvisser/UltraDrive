;------------------------------------------------------------------------------------------
; Tileset
;------------------------------------------------------------------------------------------

    Include './system/include/vdp.inc'
    Include './system/include/vdpdmaqueue.inc'

    Include './engine/include/tileset.inc'
    Include './engine/include/scheduler.inc'

;-------------------------------------------------
; Compression algorithm used by tileset
; ----------------
TILESET_COMPRESSION_TYPE Equs 'Comper'


;-------------------------------------------------
; Tileset variables
; ----------------
    DEFINE_VAR LONG
        VAR.Block   blockTable,     BLOCK_TABLE_SIZE
        VAR.Chunk   chunkTable,     CHUNK_TABLE_SIZE
    DEFINE_VAR_END

    DEFINE_VAR SHORT
        VAR.l                           loadedTileset
        VAR.l                           tilesetCollisionData
        VAR.l                           tilesetAngleData
        VAR.l                           tilesetMetaDataMapping
        VAR.w                           tilesetViewportAnimationGroupStates, TILESET_MAX_VIEWPORT_ANIMATION_GROUPS
        VAR.TilesetAnimationSchedule    tilesetAnimationSchedules,           TILESET_MAX_ANIMATIONS
    DEFINE_VAR_END

tilesetPatternDecompressionBuffer       Equ blockTable


;-------------------------------------------------
; Load tileset into RAM/VRAM
; ----------------
; Input:
; - a0: Tileset address
; Uses: d0-d7/a0-a6
TilesetLoad:
        cmpa.l  loadedTileset, a0
        bne.s   .loadTileset
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
        jsr     \TILESET_COMPRESSION_TYPE\Decompress

        ; Decompress blocks into RAM
        movea.l Tileset_blocksAddress(a6), a0
        lea     blockTable, a1
        jsr     \TILESET_COMPRESSION_TYPE\Decompress

        ; Load animations
        movea.l Tileset_animationsTableAddress(a6), a5
        move.w  Tileset_animationsCount(a6), d6
        beq.s   .noAnimations
        bsr     _TilesetLoadAnimations
    .noAnimations:

        ; Load palette
        movea.l Tileset_paletteAddress(a6), a0
        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE.l a0
        
        ; Install viewport movement handlers last
        jmp _TilesetInstallViewportMovementHandlers


;-------------------------------------------------
; Unload the tileset
; ----------------
TilesetUnload:
        ENGINE_SCHEDULER_DISABLE SCHEDULER_TILESET

        ; Uninstall foreground/background camera handlers
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK background
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK foreground

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
        beq.s   .nextSection                                                        ; No modules in this section then proceed to the next

        lea     TilesetPatternSection_modules(a0), a3                               ; a3 = Current compressed module address
        subq.w  #1, d7

    .loadPatternModuleLoop:
        lea     TilesetPatternModule_patternData(a3), a0
        lea     blockTable, a1
        jsr     \TILESET_COMPRESSION_TYPE\Decompress

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

        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE.l a0

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
        VIEWPORT_INSTALL_MOVEMENT_CALLBACK background, _TilesetCameraMove, Tileset_viewportBackgroundAnimationsAddress(a6)
        VIEWPORT_INSTALL_MOVEMENT_CALLBACK foreground, _TilesetCameraMove, Tileset_viewportForegroundAnimationsAddress(a6)
        rts


;-------------------------------------------------
; Schedule all manual animations (animationTrigger = 0)
; ----------------
; Uses: d0-d1/a0-a1
TilesetScheduleManualAnimations:
        lea     tilesetAnimationSchedules, a0
        move.l  loadedTileset, a1
        move.w  Tileset_animationsCount(a1), d0
        beq.s   .noAnimations
        subq.w  #1, d0

    .animationLoop:
        move.w  TilesetAnimationSchedule_trigger(a0), d1
        bne.s   .scheduledAnimation
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
        beq.s   .nextAnimationTrigger
        subq.w  #1, d1
        beq.s   .triggerAnimation
        move.w  d1, TilesetAnimationSchedule_trigger(a0)
        bra.s   .nextAnimationTrigger

    .triggerAnimation:
        ; Call animation trigger
        movea.l TilesetAnimationSchedule_triggerCallback(a0), a1
        PUSHW   d0
        PUSHL   a0
        jsr     (a1)
        POPL    a0
        POPW    d0

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
        bge.s   .finalAnimationFrame

        ; Schedule next frame
        move.w  TilesetAnimation_animationFrameInterval(a1), TilesetAnimationSchedule_trigger(a0)
        move.w  d0, TilesetAnimationSchedule_currentFrame(a0)
        bra.s   .animationFrameScheduleDone

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

        VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT.l a0
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
        beq.s   .noGroupChange
        
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

            VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT.l a0

            addq.l  #TilesetAnimationBase_Size, a4
            dbra    d3, .animationLoop
            
    .noGroupChange:
        dbra    d7, .animationGroupLoop
        
    .noAnimations:
        rts
