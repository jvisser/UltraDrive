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
        STRUCT_MEMBER.w mapogmGroupsCount
        STRUCT_MEMBER.l mapogmContainersTableAddress            ; MapObjectGroup*[mapogmHeight][mapogmWidth] indexed by CHUNK_REF_OBJECT_GROUP_IDX
        STRUCT_MEMBER.l mapogmContainersBaseAddress
        STRUCT_MEMBER.l mapogmGroupsBaseAddress
        STRUCT_MEMBER.b mapogmRowOffsetTable                    ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroup
        STRUCT_MEMBER.b mapogFlagNumber                         ; Each object group has a unique flag number in the active viewport
        STRUCT_MEMBER.b mapogObjectCount
        STRUCT_MEMBER.b mapogTransferableObjectCount
        STRUCT_MEMBER.b mapogTotalObjectCount
        STRUCT_MEMBER.w mapogStateOffset                        ; Offset into the map's allocated state array for this group
        STRUCT_MEMBER.b mapogObjectDescriptors                  ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapHeader
        STRUCT_MEMBER.l mapForegroundAddress
        STRUCT_MEMBER.l mapBackgroundAddress
        STRUCT_MEMBER.l mapTilesetAddress
        STRUCT_MEMBER.w mapStateSize
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

        ; Init objects
        jsr     MapInitObjects
        rts


;-------------------------------------------------
; Unload the map and its associated resources
; ----------------
MapUnload:
        jsr     TilesetUnload

        move.l  #NULL, mapLoadedMap
        rts
