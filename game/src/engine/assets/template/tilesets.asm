;------------------------------------------------------------------------------------------
; Compiled tilesets
;------------------------------------------------------------------------------------------

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
        ; .tsChunksCount
        dc.w [(${tileset.chunkTileset.size})]
        ; .tsBlocksCount
        dc.w [(${tileset.blockTileset.size})]
        ; .tsPatternCount
        dc.w [(${tileset.patternAllocation.size})]
        ; .tsPatternSectionCount
        dc.w [(${tileset.patternAllocation.patternAllocationAreas.size})]
        ; .tsAnimationsCount
        dc.w [(${videoAnimations.size})]
        ; .tsBlockMetaDataAddress
        dc.l BlockMetaData[(${collisionBlockListName})]
        ; .tsBlockMetaDataMappingTableAddress
        dc.l Tileset[(${tilesetName})]BlockMetaDataMapping
        ; .tsChunksAddress
        dc.l Tileset[(${tilesetName})]ChunkData
        ; .tsBlocksAddress
        dc.l Tileset[(${tilesetName})]BlockData
        ; .tsPatternSectionsTableAddress
        dc.l Tileset[(${tilesetName})]PatternSectionsTable
        ; .tsPaletteAddress
        dc.l Tileset[(${tilesetName})]PaletteData
        ; .tsAlternativePaletteAddress
        dc.l [(${tileset.properties['waterColor'] != null ? ('Tileset' + tilesetName + 'AlternativePaletteData') : ('NULL')})]
        ; .tsColorTransitionTableAddress
        dc.l [(${tileset.properties['colorTransitionTable'] != null ? ('Tileset' + tilesetName + 'ColorTransitionTable') : ('NULL')})]
        ; .tsAnimationsTableAddress
        dc.l Tileset[(${tilesetName})]AnimationsTable
        ; .tsViewportBackgroundAnimationsAddress
        dc.l Tileset[(${tilesetName})]ViewportAnimationTableBackground
        ; .tsViewportForegroundAnimationsAddress
        dc.l Tileset[(${tilesetName})]ViewportAnimationTableForeground
        [# th:with="mainAllocation=${tileset.patternAllocation.getAllocationArea('Main')}"]
            ; .tsVramFreeAreaMin
            dc.w [(${#format.format('$%04x', (mainAllocation.patternBaseId + mainAllocation.totalPatternAllocationSize) * 32)})]
            ; .tsVramFreeAreaMax
            dc.w [(${#format.format('$%04x', (mainAllocation.size - mainAllocation.totalPatternAllocationSize) * 32)})]
        [/]

    Even

    ;-------------------------------------------------
    ; Tileset [(${tilesetName})] palette ([(${tileset.palette.size})] colors)
    ; ----------------

    ; struct TilesetPalette
    Tileset[(${tilesetName})]PaletteData:
        ; .tsPaletteDMATransferCommandList
        VDP_DMA_DEFINE_CRAM_TRANSFER_COMMAND_LIST Tileset[(${tilesetName})]PaletteColors, 0, [(${tileset.palette.size})]
        ; .tsColors
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
            ; .tsPaletteDMATransferCommandList
            VDP_DMA_DEFINE_CRAM_TRANSFER_COMMAND_LIST Tileset[(${tilesetName})]AlternativePaletteColors, 0, [(${tileset.palette.size})]
            ; .tsColors
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
            ; .tscttCount
            dc.w    [(${colorTransitionTable.size})]
            ; .tscttPaletteColorOffsets
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
            ; .tsModuleCount
            dc.w [(${#format.format('$%04x', ((allocation.allocatedPatternSize * 32) / maxModuleSize) + (((allocation.allocatedPatternSize * 32) % maxModuleSize) != 0 ? 1 : 0))})]

            ; .tsModules
            [# th:if="${allocation.allocatedPatternSize > 0}" th:each="module, iter : ${#collection.group(maxModuleSize, #byteBE.from(#collection.flatten(allocation.patterns)))}"]
                ; Module [(${iter.index})]
                [# th:with="compressionResult=${#comper.compress(module)}, moduleOffset=${iter.index * maxModuleSize}"]
                    ; .tsPatternCompressedSize (uncompressedSize=[(${compressionResult.uncompressedSize})], compressedSize=[(${compressionResult.compressedSize})], ratio=[(${compressionResult.compressionRatio})])
                    dc.w [(${compressionResult.compressedSize})]

                    ; .tsPatternDMATransferCommandList
                    VDP_DMA_DEFINE_VRAM_TRANSFER_COMMAND_LIST tilesetPatternDecompressionBuffer, [(${allocation.patternBaseId * 32 + moduleOffset})], [(${module.size / 2})]

                    ; .tsPatternData
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
            ; .tsAnimationFrameCount
            dc.w [(${animation.frameCount})]
            ; .tsAnimationFrameTransferListAddress
            dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameList
            ; .tsAnimationInitialTrigger
            dc.w [(${animation.properties['animationInitialTrigger']})]
            ; .tsAnimationTriggerInterval
            dc.w [(${animation.properties['animationTriggerInterval']})]
            ; .tsAnimationFrameInterval
            dc.w [(${animation.properties['animationFrameInterval']})]
    [/]

    ; Viewport based animation definitions
    [# th:each="viewportCameraKey : ${viewportAnimationsByCamera.keySet()}"
        th:with="viewportCamera=${#strings.capitalize(viewportCameraKey.{^ true}[0])},
                 viewportAnimationGroups=${#collection.groupBy({'animationShift', 'animationAxis'}, viewportAnimationsByCamera[viewportCameraKey]).values()}"]

        ; struct TilesetViewportAnimations
        Tileset[(${tilesetName})]ViewportAnimationTable[(${viewportCamera})]:
            ; .tsvpAnimationsGroupCount
            dc.w [(${viewportAnimationGroups.size})]
            ; .tsvpAnimationsGroupStateAddress
            dc.w $\$VIEWPORT_ANIMATION_GROUP_STATE_ADDRESS
            ; .tsvpAnimationsGroupTable
            [# th:each="animationGroup, iter : ${viewportAnimationGroups}" th:with="animationGroupProperties=${animationGroup[0].properties}"]
                dc.l Tileset[(${tilesetName})]ViewportAnimationGroup[(${viewportCamera})][(${iter.index})]
            [/]

            [# th:each="animationGroup, iter : ${viewportAnimationGroups}" th:with="animationGroupProperties=${animationGroup[0].properties}"]

                Even

                ALLOC_VIEW_PORT_ANIMATION_GROUP_STATE

                ; struct TilesetViewportAnimationGroup
                Tileset[(${tilesetName})]ViewportAnimationGroup[(${viewportCamera})][(${iter.index})]:
                    ; .tsvpAnimationGroupCameraProperty
                    dc.w cam[(${#strings.toUpperCase(animationGroupProperties['animationAxis'])})]
                    ; .tsvpShift
                    dc.w [(${animationGroupProperties['animationShift']})]
                    ; .tsvpAnimationCount
                    dc.w [(${animationGroup.size})]
                    ; .tsvpAnimationsTable
                    [# th:each="animation : ${animationGroup}"]
                        ; struct TilesetAnimationBase ([(${animation.animationId})])
                        ; .tsAnimationFrameCount (For viewport animations this will act as the frame index mask so it will be: frameCount - 1)
                        dc.w [(${#format.format('$%02x', animation.frameCount - 1)})]
                        ; .tsAnimationFrameTransferListAddress
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
        ; .tsBlockCollisionTableAddress
        dc.l BlockMetaDataCollision[(${collisionBlockListName})]
        ; .tsBlockAngleTableAddress
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
