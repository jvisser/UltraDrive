;------------------------------------------------------------------------------------------
; Compiled tilesets
;------------------------------------------------------------------------------------------

    Include './engine/include/tileset.inc'

;-------------------------------------------------
; Macros
; ----------------
ALLOC_VIEW_PORT_ANIMATION_GROUP_STATE Macro
VIEWPORT_ANIMATION_GROUP_STATE_ADDRESS = VIEWPORT_ANIMATION_GROUP_STATE_ADDRESS + SIZE_WORD
    Endm


;-------------------------------------------------
; Tilesets data
; ----------------
    SECTION_START S_RODATA

[# th:each="tileset : ${tilesets}"
    th:with="tilesetName=${#strings.capitalize(tileset.name)},
             maxModuleSize=${0x6c00},
             collisionBlockListName=${#strings.capitalize(tileset.collisionBlockList.name)},
             animationsByScheduler=${#collection.groupBy({'animationScheduler'}, tileset.animations)},
             videoAnimations=${#collection.groupOf({'videoRefresh'}, animationsByScheduler)},
             viewportAnimationsByCamera=${
                #collection.ensureGroups({{'background'}, {'foreground'}},
                    #collection.groupBy({'animationCamera'},
                        #collection.groupOf({'viewport'}, animationsByScheduler)))}"]

VIEWPORT_ANIMATION_GROUP_STATE_ADDRESS = tilesetViewportAnimationGroupStates

    ;-------------------------------------------------
    ; Tileset [(${tilesetName})] header
    ; ----------------
    Even

    ; struct Tileset
    Tileset[(${tilesetName})]:
        ; .chunksCount
        dc.w [(${tileset.chunkTileset.size})]
        ; .blocksCount
        dc.w [(${tileset.blockTileset.size})]
        ; .patternCount
        dc.w [(${tileset.patternAllocation.size})]
        ; .patternSectionCount
        dc.w [(${tileset.patternAllocation.patternAllocationAreas.size})]
        ; .animationsCount
        dc.w [(${videoAnimations.size})]
        ; .blockMetaDataAddress
        dc.l BlockMetaData[(${collisionBlockListName})]
        ; .blockMetaDataMappingTableAddress
        dc.l Tileset[(${tilesetName})]BlockMetaDataMapping
        ; .chunksAddress
        dc.l Tileset[(${tilesetName})]ChunkData
        ; .blocksAddress
        dc.l Tileset[(${tilesetName})]BlockData
        ; .patternSectionsTableAddress
        dc.l Tileset[(${tilesetName})]PatternSectionsTable
        ; .paletteAddress
        dc.l Tileset[(${tilesetName})]PaletteData
        ; .alternativePaletteAddress
        dc.l [(${tileset.properties['waterColor'] != null ? ('Tileset' + tilesetName + 'AlternativePaletteData') : ('NULL')})]
        ; .colorTransitionTableAddress
        dc.l [(${tileset.properties['colorTransitionTable'] != null ? ('Tileset' + tilesetName + 'ColorTransitionTable') : ('NULL')})]
        ; .animationsTableAddress
        dc.l Tileset[(${tilesetName})]AnimationsTable
        ; .viewportBackgroundAnimationsAddress
        dc.l Tileset[(${tilesetName})]ViewportAnimationTableBackground
        ; .viewportForegroundAnimationsAddress
        dc.l Tileset[(${tilesetName})]ViewportAnimationTableForeground
        [# th:with="mainAllocation=${tileset.patternAllocation.getAllocationArea('Main')}"]
            ; .vramFreeAreaMin
            dc.w [(${#format.format('$%04x', (mainAllocation.patternBaseId + mainAllocation.totalPatternAllocationSize) * 32)})]
            ; .vramFreeAreaMax
            dc.w [(${#format.format('$%04x', (mainAllocation.size - mainAllocation.totalPatternAllocationSize) * 32)})]
        [/]

    Even

    ;-------------------------------------------------
    ; Tileset [(${tilesetName})] palette ([(${tileset.palette.size})] colors)
    ; ----------------

    ; struct TilesetPalette
    Tileset[(${tilesetName})]PaletteData:
        ; .paletteDMATransferCommandList
        VDP_DMA_DEFINE_CRAM_TRANSFER_COMMAND_LIST Tileset[(${tilesetName})]PaletteColors, 0, [(${tileset.palette.size})]
        ; .colors
        Tileset[(${tilesetName})]PaletteColors:
            [# th:each="color : ${#format.formatArray('dc.w ', ', ', 16, '$%04x', tileset.palette)}" ]
                [(${color})]
            [/]

    Even


    [# th:if="${tileset.properties['waterColor'] != null}" th:with="alternativePaletteTargetColor=${tileset.properties['waterColor']}"]
        ;-------------------------------------------------
        ; Tileset [(${tilesetName})] alternative palette ([(${tileset.palette.size})] colors)
        ; ----------------
        ; struct TilesetPalette
        Tileset[(${tilesetName})]AlternativePaletteData:
            ; .paletteDMATransferCommandList
            VDP_DMA_DEFINE_CRAM_TRANSFER_COMMAND_LIST Tileset[(${tilesetName})]AlternativePaletteColors, 0, [(${tileset.palette.size})]
            ; .colors
            Tileset[(${tilesetName})]AlternativePaletteColors:
                [# th:each="color : ${#format.formatArray('dc.w ', ', ', 16, '$%04x', tileset.palette.blend(#convert.tilesetColor(alternativePaletteTargetColor), 0.5f))}" ]
                    [(${color})]
                [/]

        Even
    [/]


    [# th:if="${tileset.properties['colorTransitionTable'] != null}" th:with="colorTransitionTable=${#convert.yaml(#file.asString(tileset.properties['colorTransitionTable']))['colorTransition']}"]

        ;-------------------------------------------------
        ; Tileset [(${tilesetName})] color transition table
        ; ----------------
        ; struct TilesetColorTransitionTable
        Tileset[(${tilesetName})]ColorTransitionTable:
            ; .count
            dc.w    [(${colorTransitionTable.size})]
            ; .paletteColorOffsets
            [# th:each="paletteOffset : ${#format.formatArray('dc.w ', ', ', 16, '$%04x', colorTransitionTable.{#this * 2})}" ]
                [(${paletteOffset})]
            [/]

        Even
    [/]


    ;-------------------------------------------------
    ; Tileset [(${tilesetName})] chunk/block data
    ; ----------------

    ; Compressed chunk data
    [# th:with="compressionResult=${#comper.compress(#byteBE.from(#collection.flatten(tileset.chunkTileset)))}" ]
    Tileset[(${tilesetName})]ChunkData:
        ; uncompressedSize=[(${compressionResult.uncompressedSize})], compressedSize=[(${compressionResult.compressedSize})], ratio=[(${compressionResult.compressionRatio})]
        [# th:each="compressedPatternData : ${#format.formatArray('dc.b ', ', ', 16, '$%02x', compressionResult)}" ]
            [(${compressedPatternData})]
        [/]
    [/]

    Even

    ; Compressed block data
    [# th:with="compressionResult=${#comper.compress(#byteBE.from(#collection.flatten(tileset.blockTileset)))}" ]
    Tileset[(${tilesetName})]BlockData:
        ; uncompressedSize=[(${compressionResult.uncompressedSize})], compressedSize=[(${compressionResult.compressedSize})], ratio=[(${compressionResult.compressionRatio})]
        [# th:each="compressedPatternData : ${#format.formatArray('dc.b ', ', ', 16, '$%02x', compressionResult)}" ]
            [(${compressedPatternData})]
        [/]
    [/]

    Even

    ;-------------------------------------------------
    ; Tileset [(${tilesetName})] static pattern data
    ; ----------------

    ; Compressed pattern data per configured VRAM allocation area
    Tileset[(${tilesetName})]PatternSectionsTable:
    [# th:each="allocation : ${tileset.patternAllocation.patternAllocationAreas}" ]
        dc.l Tileset[(${tilesetName})]PatternSection[(${allocation.id})]
    [/]

    [# th:each="allocation : ${tileset.patternAllocation.patternAllocationAreas}"]

        Even

        ; Pattern allocation: [(${allocation.id})]

        ; struct TilesetPatternSection
        Tileset[(${tilesetName})]PatternSection[(${allocation.id})]:
            ; .moduleCount
            dc.w [(${#format.format('$%04x', ((allocation.allocatedPatternSize * 32) / maxModuleSize) + (((allocation.allocatedPatternSize * 32) % maxModuleSize) != 0 ? 1 : 0))})]

            ; .modules
            [# th:if="${allocation.allocatedPatternSize > 0}" th:each="module, iter : ${#collection.group(maxModuleSize, #byteBE.from(#collection.flatten(allocation.patterns)))}"]
                ; Module [(${iter.index})]
                [# th:with="compressionResult=${#comper.compress(module)}, moduleOffset=${iter.index * maxModuleSize}"]
                    ; .patternCompressedSize (uncompressedSize=[(${compressionResult.uncompressedSize})], compressedSize=[(${compressionResult.compressedSize})], ratio=[(${compressionResult.compressionRatio})])
                    dc.w [(${compressionResult.compressedSize})]

                    ; .patternDMATransferCommandList
                    VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST tilesetPatternDecompressionBuffer, [(${allocation.patternBaseId * 32 + moduleOffset})], [(${module.size / 2})]

                    ; .patternData
                    [# th:each="compressedPatternData : ${#format.formatArray('dc.b ', ', ', 16, '$%02x', compressionResult)}" ]
                        [(${compressedPatternData})]
                    [/]
                [/]
            [/]
    [/]

    ;-------------------------------------------------
    ; Tileset [(${tilesetName})] animation data
    ; ----------------

    Even

    ; Timer based animations
    Tileset[(${tilesetName})]AnimationsTable:
        [# th:each="animation : ${videoAnimations}"]
            dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]
        [/]

    Even

    ; Timer based animation definitions
    [# th:each="animation : ${videoAnimations}"]
        ; struct TilesetAnimation ([(${animation.animationId})])
        Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]:
            ; .animationFrameCount
            dc.w [(${animation.frameCount})]
            ; .animationFrameTransferListAddress
            dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameList
            ; .animationInitialTrigger
            dc.w [(${animation.properties['animationInitialTrigger']})]
            ; .animationTriggerInterval
            dc.w [(${animation.properties['animationTriggerInterval']})]
            ; .animationFrameInterval
            dc.w [(${animation.properties['animationFrameInterval']})]
    [/]

    ; Viewport based animation definitions
    [# th:each="viewportCameraKey : ${viewportAnimationsByCamera.keySet()}"
        th:with="viewportCamera=${#strings.capitalize(viewportCameraKey.{^ true}[0])},
                 viewportAnimationGroups=${#collection.groupBy({'animationShift', 'animationAxis'}, viewportAnimationsByCamera[viewportCameraKey]).values()}"]

        ; struct TilesetViewportAnimations
        Tileset[(${tilesetName})]ViewportAnimationTable[(${viewportCamera})]:
            ; .animationsGroupCount
            dc.w [(${viewportAnimationGroups.size})]
            ; .animationsGroupStateAddress
            dc.w $\$VIEWPORT_ANIMATION_GROUP_STATE_ADDRESS
            ; .animationsGroupTable
            [# th:each="animationGroup, iter : ${viewportAnimationGroups}" th:with="animationGroupProperties=${animationGroup[0].properties}"]
                dc.l Tileset[(${tilesetName})]ViewportAnimationGroup[(${viewportCamera})][(${iter.index})]
            [/]

            [# th:each="animationGroup, iter : ${viewportAnimationGroups}" th:with="animationGroupProperties=${animationGroup[0].properties}"]

                Even

                ALLOC_VIEW_PORT_ANIMATION_GROUP_STATE

                ; struct TilesetViewportAnimationGroup
                Tileset[(${tilesetName})]ViewportAnimationGroup[(${viewportCamera})][(${iter.index})]:
                    ; .cameraProperty
                    dc.w Camera_[(${#strings.toLowerCase(animationGroupProperties['animationAxis'])})]
                    ; .shift
                    dc.w [(${animationGroupProperties['animationShift']})]
                    ; .animationCount
                    dc.w [(${animationGroup.size})]
                    ; .animationsTable
                    [# th:each="animation : ${animationGroup}"]
                        ; struct TilesetAnimationBase ([(${animation.animationId})])
                        ; .animationFrameCount (For viewport animations this will act as the frame index mask so it will be: frameCount - 1)
                        dc.w [(${#format.format('$%02x', animation.frameCount - 1)})]
                        ; .animationFrameTransferListAddress
                        dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameList
                    [/]
            [/]
    [/]

    ; Per animation frame DMA transfers definitions
    [# th:each="animation : ${tileset.animations}"]

        Even

        ; [(${animation.animationId})] frame DMA transfer list
        Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameList:
        [# th:each="animationFrameRef : ${animation.animationFrameReferences}"]
            dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameTransfer[(${animationFrameRef.animationFrame.frameId})]
        [/]

        Even

        ; [(${animation.animationId})] frame DMA transfer definitions
        [# th:each="animationFrameRef : ${#sets.toSet(animation.animationFrameReferences)}"]
        Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameTransfer[(${animationFrameRef.animationFrame.frameId})]:
            VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST Tileset[(${tilesetName})]AnimationFrame[(${animationFrameRef.animationFrame.frameId})]Data, [(${animation.patternBaseId * 32})], [(${animation.size * 16})]
        [/]
    [/]

    Even

    ; Animation frame data
    [# th:each="animationFrame : ${tileset.animationFrames}"]
        Tileset[(${tilesetName})]AnimationFrame[(${animationFrame.frameId})]Data:
        [# th:each="patternLine : ${#format.formatArray('dc.l ', ', ', 8, '$%08x', #collection.flatten(animationFrame.patterns))}"]
            [(${patternLine})]
        [/]
    [/]

    ;-------------------------------------------------
    ; Tileset [(${tilesetName})] block meta data mapping
    ; ----------------

    ; blockId -> blockMetaDataId mapping
    Tileset[(${tilesetName})]BlockMetaDataMapping:
        [# th:each="collisionId : ${#format.formatArray('dc.w ', ', ', 16, '$%04x', tileset.blockTileset.tiles.{#this.collisionId})}"]
            [(${collisionId})]
        [/]

    Even

[/]

;-------------------------------------------------
; Tileset block meta data
; ----------------

; Block meta data
[# th:each="collisionblocklist : ${collisionblocklists}" th:with="collisionBlockListName=${#strings.capitalize(collisionblocklist.name)}"]

    ; struct BlockMetaData
    BlockMetaData[(${collisionBlockListName})]:
        ; .blockCollisionTableAddress
        dc.l BlockMetaDataCollision[(${collisionBlockListName})]
        ; .blockAngleTableAddress
        dc.l BlockMetaDataAngle[(${collisionBlockListName})]

    ; Collision height fields
    BlockMetaDataCollision[(${collisionBlockListName})]:
        [# th:each="collisionFields : ${#format.formatArray('dc.b ', ', ', 16, '%02d', #collection.flatten(collisionblocklist))}"]
            [(${collisionFields})]
        [/]

    ; Angles
    BlockMetaDataAngle[(${collisionBlockListName})]:
        [# th:each="collisionblock : ${collisionblocklist}"]
            dc.b    [(${@@round((collisionblock.angle / 360) * 256)})]    ; [(${#format.format('%f', collisionblock.angle)})]
        [/]

    Even
[/]

    SECTION_END

    Purge ALLOC_VIEW_PORT_ANIMATION_GROUP_STATE
