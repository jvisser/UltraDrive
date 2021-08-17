;------------------------------------------------------------------------------------------
; Compiled map
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Macros
; ----------------
ALLOC_OBJECT_STATE Macro objectName
ALLOC_OBJECT_STATE_OFFSET = ALLOC_OBJECT_STATE_OFFSET + \objectName\ObjectTypeSize
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
                ; struct MapObjectGroup
                MapObjectGroup[(${objectGroup.id})][(${mapName})]:
                    ; .mapogFlagNumber
                    dc.b [(${objectGroup.flagNumber})]
                    ; .mapogObjectCount
                    dc.b [(${objectGroup.size})]
                    ; .mapogObjectStateOffset
                    dc.w $\$ALLOC_OBJECT_STATE_OFFSET
                    ; .mapogObjectSpawnData
                    [# th:each="object : ${objectGroup.objects}"]
                        ; struct ObjectSpawnData (type = [(${object.name})])
                        MapObject[(${object.id})][(${mapName})]:
                            ; .osdTypeOffset
                            dc.w [(${object.name})]ObjectTypeOffset
                            ; .osdX
                            dc.w [(${object.x})]
                            ; .osdY
                            dc.w [(${object.y})]

                        ALLOC_OBJECT_STATE [(${object.name})]

                        Even
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
            ; .mapObjectStateSize
            dc.w $\$ALLOC_OBJECT_STATE_OFFSET
            ; .mapObjectGroupMapAddress
            dc.l MapObjectGroupMap[(${mapName})]
            ; .mapViewportConfigurationAddress
            dc.l [(${#strings.unCapitalize(map.properties.getOrDefault('viewportConfiguration', map.properties['background'].properties.getOrDefault('viewportConfiguration', 'default')))})]ViewportConfiguration

            If def(debug)
                Inform 0, 'Total object allocation size for map [(${mapName})] = \#ALLOC_OBJECT_STATE_OFFSET bytes'
            EndIf

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
