;------------------------------------------------------------------------------------------
; Map type definition and loading
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT MapDirectory
        STRUCT_MEMBER.w mapCount
        STRUCT_MEMBER.b maps                                    ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroupMap
        STRUCT_MEMBER.w mapogmStride
        STRUCT_MEMBER.w mapogmWidth                             ; Granularity = 8x8 chunks or 1024x1024 pixels
        STRUCT_MEMBER.w mapogmHeight
        STRUCT_MEMBER.l mapogmContainersTableAddress            ; *MapObjectGroup[mapogmHeight][mapogmWidth] indexed by CHUNK_REF_OBJECT_GROUP_IDX
        STRUCT_MEMBER.l mapogmContainersBaseAddress
        STRUCT_MEMBER.l mapogmGroupsBaseAddress
        STRUCT_MEMBER.b mapogmRowOffsetTable                    ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroup
        STRUCT_MEMBER.b mapogFlagNumber                         ; Each object group has a unique flag number in the active viewport
        STRUCT_MEMBER.b mapogObjectCount
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapHeader
        STRUCT_MEMBER.l mapForegroundAddress
        STRUCT_MEMBER.l mapBackgroundAddress
        STRUCT_MEMBER.l mapTilesetAddress
        STRUCT_MEMBER.l mapObjectGroupMapAddress
        STRUCT_MEMBER.l mapViewportConfigurationAddress
    DEFINE_STRUCT_END

    DEFINE_STRUCT Map
        STRUCT_MEMBER.w mapWidth
        STRUCT_MEMBER.w mapStride
        STRUCT_MEMBER.w mapHeight
        STRUCT_MEMBER.w mapWidthPatterns
        STRUCT_MEMBER.w mapHeightPatterns
        STRUCT_MEMBER.w mapWidthPixels
        STRUCT_MEMBER.w mapHeightPixels
        STRUCT_MEMBER.l mapDataAddress                          ; Uncompressed
        STRUCT_MEMBER.b mapRowOffsetTable                       ; Marker
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.l               mapLoadedMap                        ; MapHeader
        VAR.w               mapActiveObjectGroupCount
        VAR.w               mapActiveObjectGroupSubChunkId
        VAR.l               mapActiveObjectGroups, 12
    DEFINE_VAR_END


;-------------------------------------------------
; Get loaded map address in target
; ----------------
MAP_GET Macros target
        movea.l mapLoadedMap, \target


;-------------------------------------------------
; Load the map at the specified index in the map directory
; ----------------
; Input:
; - d0: Map directory index
; Uses: d0-d7/a0-a6
MapLoadDirectoryIndex:
            lea     MapDirectory, a0
            move.w  mapCount(a0), d1
            cmp.w   d1, d0
            bge     .invalidMapIndex

            add.w   d0, d0
            add.w   d0, d0
            move.l  maps(a0, d0), a0
            jmp     MapLoad

        .invalidMapIndex:
            OS_KILL 'Invalid map index provided to MapLoadDirectoryIndex'
        rts;


;-------------------------------------------------
; Load a map and its associated resources
; ----------------
; Input:
; - a0: MapHeader address
; Uses: d0-d7/a0-a6
MapLoad:
        cmpa.l  mapLoadedMap, a0
        bne     .loadMap
        rts ; Map already loaded

    .loadMap:
        move.l  a0, mapLoadedMap
        clr.w   mapActiveObjectGroupCount

        ; Load associated tileset
        movea.l mapTilesetAddress(a0), a0
        jsr     TilesetLoad
        rts


;-------------------------------------------------
; Unload the map and its associated resources
; ----------------
MapUnload:
        jsr     TilesetUnload

        move.l  #NULL, mapLoadedMap
        rts


;-------------------------------------------------
; Calculate sub chunk id
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: result, scratch
; Output:
; - result: sub chunk id
_CALCULATE_SUB_CHUNK_ID Macro result, scratch
        move.w  d0, \result
        move.w  d1, \scratch
        add.w   \result, \result
        andi.w  #$80, \result
        andi.w  #$60, \scratch
        or.w    \scratch, \result
    Endm


;-------------------------------------------------
; Update active object groups based on view
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
MapInitActiveObjectGroups:
    _CALCULATE_SUB_CHUNK_ID d2, d3

    move.w  d2, mapActiveObjectGroupSubChunkId
    bra     _MapUpdateActiveObjectGroups


;-------------------------------------------------
; Update active object groups based on view. Only updates when new chunks of the map become visible.
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
MapUpdateActiveObjectGroups:
        _CALCULATE_SUB_CHUNK_ID d2, d3

        move.w  mapActiveObjectGroupSubChunkId, d3
        eor.w   d2, d3
        bne     .updateActiveObjectGroups
            rts

    .updateActiveObjectGroups:
        move.w  d2, mapActiveObjectGroupSubChunkId

        ; NB: Fall through to _MapUpdateActiveObjectGroups


;-------------------------------------------------
; Update active object groups based on view
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
_MapUpdateActiveObjectGroups:
        clr.w   mapActiveObjectGroupCount

        ; Get number of columns in view
        moveq   #3, d2
        btst    #6, d0
        seq     d3
        ext.w   d3
        add.w   d3, d2                                          ; d2 = number of columns - 1

        ; Get number of rows in view
        moveq   #2, d3
        move.w  d1, d4
        andi.w  #$0060, d4
        seq     d4
        ext.w   d4
        add.w   d4, d3                                          ; d3 = number of rows - 1

        ; Convert pixel coordinates to chunk coordinates
        lsr.w   #7, d0                                          ; d0 = horizontal chunk coordinate
        lsr.w   #7, d1                                          ; d1 = vertical chunk coordinate

        ; Get pointers
        MAP_GET a0
        movea.l mapObjectGroupMapAddress(a0), a1                ; a1 = mapObjectGroupMapAddress
        movea.l mapogmContainersTableAddress(a1), a2            ; a2 = mapogmContainersTableAddress
        movea.l mapogmContainersBaseAddress(a1), a3             ; a3 = mapogmContainersBaseAddress
        movea.l mapogmGroupsBaseAddress(a1), a4                 ; a4 = mapogmGroupsBaseAddress
        lea     mapActiveObjectGroups, a5                       ; a5 = mapActiveObjectGroups
        movea.l mapForegroundAddress(a0), a0
        move.w  mapStride(a0), d4
        subq.w  #SIZE_WORD, d4
        sub.w   d2, d4
        sub.w   d2, d4                                          ; d4 map stride - number of columns in view
        move.w  d1, d5
        add.w   d5, d5
        move.w  mapRowOffsetTable(a0, d5), d5                   ; d5 = map row offset of top visible row
        movea.l mapDataAddress(a0), a0
        adda.w  d5, a0
        move.w  d0, d6
        add.w   d6, d6
        adda.w  d6, a0                                          ; a0 = address of top left coordinate of first chunk in viewport

        moveq   #0, d6                                          ; d6 = accumulated group flags
    .rowLoop:

        swap    d4
        move.w  d2, d4                                          ; d4 = number of columns - 1
        move.w  d0, d5                                          ; d5 = horizontal chunk coordinate
        .colLoop:

            ; Load object container address
            move.w  d1, d7
            lsr.w   #3, d7
            add.w   d7, d7
            move.w  mapogmRowOffsetTable(a1, d7), a6            ; a6 = container table vertical offset
            move.w  d5, d7
            lsr.w   #3, d7
            add.w   d7, d7
            add.w   a6, d7                                      ; d7 = container offset
            move.w  (a2, d7), d7                                ; d7 = mapogmContainersTableAddress[d7] (= container offset into mapogmContainersBaseAddress)
            lea     (a3, d7), a6                                ; a6 = mapogmContainersBaseAddress[d7] (= container address)

            ; Load object group from container
            move.w  (a0)+, d7                                   ; d7 = chunk ref
            rol.w   #3, d7
            andi.w  #7, d7                                      ; d7 = container group id
            beq     .emptyObjectGroup

                subq.w  #1, d7                                  ; d7 = container group index
                add.w   d7, d7
                move.w  (a6, d7), d7                            ; d7 = object group offset
                lea     (a4, d7), a6                            ; a6 = object group address

                ; Check if new group
                move.b  mapogFlagNumber(a6), d7
                bset    d7, d6
                bne     .objectGroupAlreadyActive

                    addq.w #1, mapActiveObjectGroupCount

                    ; Add to active group list
                    move.l  a6, (a5)+

            .objectGroupAlreadyActive:

        .emptyObjectGroup:

            addq.w  #1, d5
            dbra    d4, .colLoop

        swap    d4
        adda.w  d4, a0
        addq.w  #1, d1
        dbra    d3, .rowLoop
        rts
