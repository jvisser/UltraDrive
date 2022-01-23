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
        ; .count
        dc.w [(${rootMaps.size})]
        [# th:each="map : ${rootMaps}" th:with="mapName=${#strings.capitalize(map.name)}"]
                ; .foregroundAddress
                dc.l MapHeader[(${mapName})]
        [/]
[/]

[# th:each="map : ${maps}" th:with="mapName=${#strings.capitalize(map.name)}"]

    Even

    [# th:if="${map.properties['background'] != null}"
        th:with="backgroundMapName=${#strings.capitalize(map.properties['background'].name)},
                metadataMap=${map.metadataMap}"]

        ; struct MapMetadataMap
        MapMetadataMap[(${mapName})]:
            ; .stride
            dc.w [(${metadataMap.width})] * SIZE_WORD
            ; .width
            dc.w [(${metadataMap.width})]
            ; .height
            dc.w [(${metadataMap.height})]
            ; .groupCount
            dc.w [(${metadataMap.objectGroups.size})]
            ; .containersTableAddress
            dc.l MapMetadataContainerTable[(${mapName})]
            ; .objectGroupsBaseAddress
            dc.l MapObjectGroupsBase[(${mapName})]
            ; .rowOffsetTable
            dc.w [# th:each="index, iter : ${#numbers.sequence(0, metadataMap.height - 1)}"][(${index * metadataMap.width * 4})][# th:if="${!iter.last}"], [/][/]

        Even

        MapMetadataContainerTable[(${mapName})]:
            [# th:each="metadataContainer : ${metadataMap.metadataContainers}"]
                dc.l MapMetadataContainer[(${metadataContainer.id})][(${mapName})]
            [/]

        Even

        MapMetadataContainerBase[(${mapName})]:
            [# th:each="metadataContainer : ${metadataMap.metadataContainers}"]
                ; struct MapMetadataContainer
                MapMetadataContainer[(${metadataContainer.id})][(${mapName})]:
                    ; .objectGroupOffsetTable
                    [# th:each="objectGroup : ${metadataContainer.objectGroups}"]
                        dc.w MapObjectGroup[(${objectGroup.id})][(${mapName})] - MapObjectGroupsBase[(${mapName})]
                    [/]
            [/]

        Even

ALLOC_OBJECT_STATE_OFFSET = 0;

        MapObjectGroupsBase[(${mapName})]:
            [# th:each="objectGroup : ${metadataMap.objectGroups}"]
                [# th:with="objectsByTransferable=${#collection.ensureGroups({{true}, {false}}, #collection.groupBy({'objectTypeTransferable'}, #lists.sort(objectGroup.objects)))},
                            staticObjects=${objectsByTransferable[#sets.toSet({false})]},
                            transferableObjects=${objectsByTransferable[#sets.toSet({true})]},
                            objects=${@com.google.common.collect.Iterables@concat(staticObjects, transferableObjects)}"]

                    ; struct MapObjectGroup
                    MapObjectGroup[(${objectGroup.id})][(${mapName})]:
                        ; .flagNumber
                        dc.b [(${objectGroup.flagNumber})]
                        ; .objectCount
                        dc.b [(${staticObjects.size})]
                        ; .transferableObjectCount
                        dc.b [(${transferableObjects.size})]
                        ; .totalObjectCount
                        dc.b [(${staticObjects.size + transferableObjects.size})]
                        ; .mapogObjectStateOffset
                        dc.w $\$ALLOC_OBJECT_STATE_OFFSET

                        ALLOC_OBJECT_GROUP_STATE

                        Even

                        ; .objectDescriptors
                        [# th:each="object : ${objects}"]

                            ; Object type = [(${object.name})]
                            MapObject[(${object.id})][(${mapName})]:

                                [# th:block th:replace="objectdescriptor/__${#strings.toLowerCase(object.name)}__.desc"][/]

                            MapObject[(${object.id})][(${mapName})]_End:

                            Even
                        [/]

                [/]

                Even
            [/]

        MapObjectTypeTable[(${mapName})]:
            [# th:each="objectTypeName : ${#sets.toSet(metadataMap.objects.{#this.name})}"]
                dc.w    [(${objectTypeName})]ObjectType
            [/]
            dc.w    NULL

        Even

        ; struct MapHeader
        MapHeader[(${mapName})]:
            ; .foregroundAddress
            dc.l Map[(${mapName})]
            ; .backgroundAddress
            dc.l Map[(${backgroundMapName})]
            ; .tilesetAddress
            dc.l Tileset[(${#strings.capitalize(map.tileset.name)})]
            ; .stateSize
            dc.w $\$ALLOC_OBJECT_STATE_OFFSET
            ; .metadataMapAddress
            dc.l MapMetadataMap[(${mapName})]
            ; .objectTypeTableAddress
            dc.l MapObjectTypeTable[(${mapName})]
            ; .viewportConfigurationAddress
            dc.l [(${#strings.unCapitalize(map.properties.getOrDefault('viewportConfiguration', map.properties['background'].properties.getOrDefault('viewportConfiguration', 'default')))})]ViewportConfiguration

            Inform 0, 'Total RAM allocation size for map [(${mapName})] = \#ALLOC_OBJECT_STATE_OFFSET bytes'

        Even

    [/]

    ; struct Map
    Map[(${mapName})]:
        ; .width
        dc.w [(${map.width})]
        ; .stride
        dc.w [(${map.width})] * SIZE_WORD
        ; .height
        dc.w [(${map.height})]
        ; .widthPatterns
        dc.w [(${map.width * 16})]
        ; .heightPatterns
        dc.w [(${map.height * 16})]
        ; .widthPixels
        dc.w [(${map.width * 16 * 8})]
        ; .heightPixels
        dc.w [(${map.height * 16 * 8})]
        ; .dataAddress
        dc.l Map[(${mapName})]Data
        ; .rowOffsetTable
        dc.w [# th:each="index, iter : ${#numbers.sequence(0, map.height - 1)}"][(${index * map.width * 2})][# th:if="${!iter.last}"], [/][/]

    Even

    Map[(${mapName})]Data:
    [# th:each="chunkReferences : ${#format.formatArray('dc.w ', ', ', 16, '$%04x', map)}"]
        [(${chunkReferences})]
    [/]

[/]

    SECTION_END
