;------------------------------------------------------------------------------------------
; Compiled map
;------------------------------------------------------------------------------------------

    SECTION_START S_RODATA

[# th:each="map : ${maps}" th:with="mapName=${#strings.capitalize(map.name)}"]

    Even

    [# th:if="${map.properties['background'] != null}" th:with="backgroundMapName=${#strings.capitalize(map.properties['background'].name)}"]
        ; struct Map
        MapHeader[(${mapName})]:
            ; .mapForegroundAddress
            dc.l Map[(${mapName})]
            ; .mapBackgroundAddress
            dc.l Map[(${backgroundMapName})]
            ; .mapTilesetAddress
            dc.l Tileset[(${#strings.capitalize(map.tileset.name)})]
            ; .backgroundTrackerAddress
            dc.l [(${#strings.toLowerCase(map.properties.getOrDefault('background_tracker', map.properties['background'].properties['background_tracker']))})]BackgroundTracker
        Even
    [/]

    ; struct Map
    Map[(${mapName})]:
        ; .mapWidth
        dc.w [(${map.width})]
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
