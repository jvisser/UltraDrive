;------------------------------------------------------------------------------------------
; Compiled map
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Macros
; ----------------
ALLOC_OBJECT_GROUP_STATE Macro objectName
ALLOC_OBJECT_STATE_OFFSET = ((ALLOC_OBJECT_STATE_OFFSET + MapObjectGroupState_Size + 1) & -2)
    Endm

ALLOC_OBJECT_LINK_STATE Macro objectName
ALLOC_OBJECT_STATE_OFFSET = ((ALLOC_OBJECT_STATE_OFFSET + MapObjectLink_Size + 1) & -2)
    Endm

ALLOC_OBJECT_STATE Macro objectName
ALLOC_OBJECT_STATE_OFFSET = ((ALLOC_OBJECT_STATE_OFFSET + \objectName\ObjectTypeSize + 1) & -2)
    Endm


;-------------------------------------------------
; Map data
; ----------------
    SECTION_START S_RODATA

        Even

[# th:with="rootMaps=${maps.{? #this.properties['background'] != null}}"]
    ; struct MapDirectory
    MapDirectory:
        ; .mapCount
        dc.w [(${rootMaps.size})]
        [# th:each="map : ${rootMaps}" th:with="mapName=${#strings.capitalize(map.name)}"]
                ; .mapForegroundAddress
                dc.l MapHeader[(${mapName})]
        [/]
[/]

[# th:each="map : ${maps}" th:with="mapName=${#strings.capitalize(map.name)}"]

    Even

    [# th:if="${map.properties['background'] != null}"
        th:with="backgroundMapName=${#strings.capitalize(map.properties['background'].name)},
                objectGroupMap=${map.objectGroupMap}"]

        ; struct MapObjectGroupMap
        MapObjectGroupMap[(${mapName})]:
            ; .mapogmStride
            dc.w [(${objectGroupMap.width})] * SIZE_WORD
            ; .mapogmWidth
            dc.w [(${objectGroupMap.width})]
            ; .mapogmHeight
            dc.w [(${objectGroupMap.height})]
            ; .mapogmGroupsCount
            dc.w [(${objectGroupMap.objectGroups.size})]
            ; .mapogmContainersTableAddress
            dc.l MapObjectGroupContainersTable[(${mapName})]
            ; .mapogmContainersBaseAddress
            dc.l MapObjectGroupContainersBase[(${mapName})]
            ; .mapogmGroupsBaseAddress
            dc.l MapObjectGroupsBase[(${mapName})]
            ; .mapogmRowOffsetTable
            dc.w [# th:each="index, iter : ${#numbers.sequence(0, objectGroupMap.height - 1)}"][(${index * objectGroupMap.width * 2})][# th:if="${!iter.last}"], [/][/]

        Even

        MapObjectGroupContainersTable[(${mapName})]:
            [# th:each="objectGroupContainer : ${objectGroupMap.objectGroupContainers}"]
                dc.w MapObjectGroupContainer[(${objectGroupContainer.id})][(${mapName})] - MapObjectGroupContainersBase[(${mapName})]
            [/]

        Even

        MapObjectGroupContainersBase[(${mapName})]:
            [# th:each="objectGroupContainer : ${objectGroupMap.objectGroupContainers}"]
                MapObjectGroupContainer[(${objectGroupContainer.id})][(${mapName})]:
                [# th:each="objectGroup : ${objectGroupContainer.objectGroups}"]
                    dc.w MapObjectGroup[(${objectGroup.id})][(${mapName})] - MapObjectGroupsBase[(${mapName})]
                [/]
            [/]

        Even

ALLOC_OBJECT_STATE_OFFSET = 0;

        MapObjectGroupsBase[(${mapName})]:
            [# th:each="objectGroup : ${objectGroupMap.objectGroups}"]
                [# th:with="objectsByTransferable=${#collection.ensureGroups({{true}, {false}}, #collection.groupBy({'objectTypeTransferable'}, objectGroup.objects))},
                            staticObjects=${objectsByTransferable[#sets.toSet({false})]},
                            transferableObjects=${objectsByTransferable[#sets.toSet({true})]},
                            objects=${@com.google.common.collect.Iterables@concat(staticObjects, transferableObjects)}"]

                    ; struct MapObjectGroup
                    MapObjectGroup[(${objectGroup.id})][(${mapName})]:
                        ; .mapogFlagNumber
                        dc.b [(${objectGroup.flagNumber})]
                        ; .mapogObjectCount
                        dc.b [(${staticObjects.size})]
                        ; .mapogTransferableObjectCount
                        dc.b [(${transferableObjects.size})]
                        ; .mapogTotalObjectCount
                        dc.b [(${staticObjects.size + transferableObjects.size})]
                        ; .mapogObjectStateOffset
                        dc.w $\$ALLOC_OBJECT_STATE_OFFSET

                        ALLOC_OBJECT_GROUP_STATE

                        Even

                        ; .mapogObjectDescriptors
                        [# th:each="object : ${objects}"]

                            [# th:if="${object.properties['objectTypeTransferable']}"]
                                ALLOC_OBJECT_LINK_STATE
                            [/]

                            ; struct MapObjectDescriptor (type = [(${object.name})])
                            MapObject[(${object.id})][(${mapName})]:
                                ; .odTypeOffset
                                dc.w [(${object.name})]ObjectTypeOffset
                                ; .odSize
                                dc.b MapObject[(${object.id})][(${mapName})]_End - MapObject[(${object.id})][(${mapName})]
                                ; .odFlags
                                dc.b [# th:if="${object.properties['objectTypeTransferable']}"]MODF_TRANSFERABLE_MASK|[/][# th:if="${object.properties['enabled']}"]MODF_ENABLED_MASK|[/][# th:if="${object.properties['active']}"]MODF_ACTIVE_MASK|[/][# th:if="${object.horizontalFlip}"]MODF_HFLIP_MASK|[/][# th:if="${object.verticalFlip}"]MODF_VFLIP_MASK|[/]0

                                ; struct MapStatefulObjectDescriptor
                                If ([(${object.name})]ObjectTypeSize > 0)
                                    ; .odStateOffset
                                    dc.w $\$ALLOC_OBJECT_STATE_OFFSET
                                EndIf

                                [# th:if="${object.properties['objectTypePositional']}"]
                                    ; struct MapObjectPosition
                                        ; .opX
                                        dc.w [(${object.x})]
                                        ; .opY
                                        dc.w [(${object.y})]
                                [/]
                            MapObject[(${object.id})][(${mapName})]_End:

                            ALLOC_OBJECT_STATE [(${object.name})]

                            Even
                        [/]

                [/]

                Even
            [/]

        Even

        ; struct MapHeader
        MapHeader[(${mapName})]:
            ; .mapForegroundAddress
            dc.l Map[(${mapName})]
            ; .mapBackgroundAddress
            dc.l Map[(${backgroundMapName})]
            ; .mapTilesetAddress
            dc.l Tileset[(${#strings.capitalize(map.tileset.name)})]
            ; .mapStateSize
            dc.w $\$ALLOC_OBJECT_STATE_OFFSET
            ; .mapObjectGroupMapAddress
            dc.l MapObjectGroupMap[(${mapName})]
            ; .mapViewportConfigurationAddress
            dc.l [(${#strings.unCapitalize(map.properties.getOrDefault('viewportConfiguration', map.properties['background'].properties.getOrDefault('viewportConfiguration', 'default')))})]ViewportConfiguration

            Inform 0, 'Total object allocation size for map [(${mapName})] = \#ALLOC_OBJECT_STATE_OFFSET bytes'

        Even

    [/]

    ; struct Map
    Map[(${mapName})]:
        ; .mapWidth
        dc.w [(${map.width})]
        ; .mapStride
        dc.w [(${map.width})] * SIZE_WORD
        ; .mapHeight
        dc.w [(${map.height})]
        ; .mapWidthPatterns
        dc.w [(${map.width * 16})]
        ; .mapHeightPatterns
        dc.w [(${map.height * 16})]
        ; .mapWidthPixels
        dc.w [(${map.width * 16 * 8})]
        ; .mapHeightPixels
        dc.w [(${map.height * 16 * 8})]
        ; .mapDataAddress
        dc.l Map[(${mapName})]Data
        ; .mapRowOffsetTable
        dc.w [# th:each="index, iter : ${#numbers.sequence(0, map.height - 1)}"][(${index * map.width * 2})][# th:if="${!iter.last}"], [/][/]

    Even

    Map[(${mapName})]Data:
    [# th:each="chunkReferences : ${#format.formatArray('dc.w ', ', ', map.width, '$%04x', map)}"]
        [(${chunkReferences})]
    [/]

[/]

    SECTION_END
