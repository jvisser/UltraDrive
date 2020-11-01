    SECTION_START S_RODATA

[# th:each="tileset : ${tilesets}" th:with="tilesetName=${#strings.capitalize(tileset.name)}, maxModuleSize=${0x4000}"]

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
        dc.w [(${tileset.animations.size})]
        ; .tsChunksAddress
        dc.l Tileset[(${tilesetName})]ChunkData
        ; .tsBlocksAddress
        dc.l Tileset[(${tilesetName})]BlockData
        ; .tsPatternSectionsTableAddress
        dc.l Tileset[(${tilesetName})]PatternSectionsTable
        ; .tsPaletteAddress
        dc.l Tileset[(${tilesetName})]PaletteData
        ; .tsAnimationsTableAddress
        dc.l Tileset[(${tilesetName})]AnimationsTable
        [# th:with="mainAllocation=${tileset.patternAllocation.getAllocationArea('Main')}"]
        ; .tsVramFreeAreaMin
        dc.w [(${#format.format('$%04X', (mainAllocation.patternBaseId + mainAllocation.totalPatternAllocationSize) * 32)})]
        ; .tsVramFreeAreaMax
        dc.w [(${#format.format('$%04X', (mainAllocation.size - mainAllocation.totalPatternAllocationSize) * 32)})]
        [/]

    Even

    [# th:with="compressionResult=${#comper.compress(#byteBE.from(#collection.flatten(tileset.chunkTileset)))}" ]
    Tileset[(${tilesetName})]ChunkData:
        ; uncompressedSize=[(${compressionResult.uncompressedSize})], compressedSize=[(${compressionResult.compressedSize})], ratio=[(${compressionResult.compressionRatio})]
        [# th:each="compressedPatternData : ${#format.formatArray('dc.b ', ', ', 16, '$%02x', compressionResult)}" ]
            [(${compressedPatternData})]
        [/]
    [/]

    Even

    [# th:with="compressionResult=${#comper.compress(#byteBE.from(#collection.flatten(tileset.blockTileset)))}" ]
    Tileset[(${tilesetName})]BlockData:
        ; uncompressedSize=[(${compressionResult.uncompressedSize})], compressedSize=[(${compressionResult.compressedSize})], ratio=[(${compressionResult.compressionRatio})]
        [# th:each="compressedPatternData : ${#format.formatArray('dc.b ', ', ', 16, '$%02x', compressionResult)}" ]
            [(${compressedPatternData})]
        [/]
    [/]

    Even

    ; struct TilesetPalette
    Tileset[(${tilesetName})]PaletteData:
        ; .tsPaletteDMATransferCommandList
        VDP_DMA_DEFINE_CRAM_COMMAND_LIST Tileset[(${tilesetName})]PaletteColors, 0, 64
        ; .tsColors
        Tileset[(${tilesetName})]PaletteColors:
            [# th:each="color : ${#format.formatArray('dc.w ', ', ', 16, '$%04X', tileset.palette)}" ]
                [(${color})]
            [/]

    Even

    Tileset[(${tilesetName})]PatternSectionsTable:
    [# th:each="allocation : ${tileset.patternAllocation.patternAllocationAreas}" ]
        dc.l Tileset[(${tilesetName})]PatternSection[(${allocation.id})]
    [/]

    [# th:each="allocation : ${tileset.patternAllocation.patternAllocationAreas}"]

        Even

        ; struct TilesetPatternSection
        Tileset[(${tilesetName})]PatternSection[(${allocation.id})]:
            ; .tsModuleCount
            dc.w [(${#format.format('$%04x', ((allocation.allocatedPatternSize * 32) / maxModuleSize) + (((allocation.allocatedPatternSize * 32) % maxModuleSize) != 0 ? 1 : 0))})]

            ; .tsModules
            [# th:if="${allocation.allocatedPatternSize > 0}" th:each="module, iter : ${#collection.group(maxModuleSize, #byteBE.from(#collection.flatten(allocation.patterns)))}"]
                ; Module [(${iter.index})]
                [# th:with="compressionResult=${#comper.compress(module)}, moduleOffset=${iter.index * maxModuleSize}"]
                    ; .tsPatternCompressedSize (uncompressedSize=[(${compressionResult.uncompressedSize})], ratio=[(${compressionResult.compressionRatio})])
                    dc.w [(${compressionResult.compressedSize})]

                    ; .tsPatternDMATransferCommandList
                    VDP_DMA_DEFINE_VRAM_COMMAND_LIST tilesetPatternDecompressionBuffer, [(${allocation.patternBaseId * 32 + moduleOffset})], [(${module.size / 2})]

                    ; .tsPatternData
                    [# th:each="compressedPatternData : ${#format.formatArray('dc.b ', ', ', 16, '$%02x', compressionResult)}" ]
                        [(${compressedPatternData})]
                    [/]
                [/]
            [/]
    [/]

    Even

    Tileset[(${tilesetName})]AnimationsTable:
        [# th:each="animation : ${tileset.animations}"]
            dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]
        [/]

    Even

    [# th:each="animation : ${tileset.animations}"]
        ; struct TilesetAnimation
        Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]:
            ; .tsAnimationFrameTransferListAddress
            dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameList
            ; .tsAnimationFrameCount
            dc.w [(${animation.frameCount})]
            [# th:with="animationActivation=${#convert.yaml(animation.properties['animation_activation'])}"]
                ; .tsAnimationInitialTrigger
                dc.w [(${animationActivation['initialTrigger']})]
                ; .tsAnimationTriggerInterval
                dc.w [(${animationActivation['triggerInterval']})]
                ; .tsAnimationFrameInterval
                dc.w [(${animationActivation['frameInterval']})]
            [/]

        Even

        Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameList:
        [# th:each="animationFrameRef : ${animation.animationFrameReferences}"]
            dc.l Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameTransfer[(${animationFrameRef.animationFrame.frameId})]
        [/]

    [/]

    Even

    [# th:each="animation : ${tileset.animations}"]
        [# th:each="animationFrameRef : ${#sets.toSet(animation.animationFrameReferences)}"]
        Tileset[(${tilesetName})]Animation[(${#strings.capitalize(animation.animationId)})]FrameTransfer[(${animationFrameRef.animationFrame.frameId})]:
            VDP_DMA_DEFINE_VRAM_TRANSFER Tileset[(${tilesetName})]AnimationFrame[(${animationFrameRef.animationFrame.frameId})]Data, [(${animation.patternBaseId * 32})], [(${animation.size * 16})]
        [/]
    [/]

    Even

    [# th:each="animationFrame : ${tileset.animationFrames}"]
        Tileset[(${tilesetName})]AnimationFrame[(${animationFrame.frameId})]Data:
        [# th:each="patternLine : ${#format.formatArray('dc.l ', ', ', 8, '$%08x', #collection.flatten(animationFrame.patterns))}"]
            [(${patternLine})]
        [/]
    [/]

[/]

    SECTION_END
