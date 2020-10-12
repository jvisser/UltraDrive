    SECTION_START S_RODATA

[# th:each="map : ${maps}" th:with="mapName=${#strings.capitalize(map.name)}"]

    Even

    ; struct Map
    Map[(${mapName})]:
        ; .width
        dc.w [(${map.width})]
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
        ; .mapDataAddress
        dc.l Map[(${mapName})]Data
        ; .tilesetAddress
        dc.l Tileset[(${#strings.capitalize(map.tileset.name)})]
        ; .rowOffsetTable
        dc.w [# th:each="index, iter : ${#numbers.sequence(0, map.height - 1)}"][(${index * map.width * 2})][# th:if="${!iter.last}"], [/][/]

    Even

    Map[(${mapName})]Data:
    [# th:each="chunkReferences : ${#format.formatArray('dc.w ', ', ', map.width, '$%04x', map)}"]
        [(${chunkReferences})]
    [/]

[/]

    SECTION_END
