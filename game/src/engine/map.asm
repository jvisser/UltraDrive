;------------------------------------------------------------------------------------------
; Map type definition and loading
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT MapDirectory
        STRUCT_MEMBER.w count
        STRUCT_MEMBER.b maps                                    ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroupMap
        STRUCT_MEMBER.w stride
        STRUCT_MEMBER.w width                                   ; Granularity = 8x8 chunks or 1024x1024 pixels
        STRUCT_MEMBER.w height
        STRUCT_MEMBER.w groupCount
        STRUCT_MEMBER.l containersTableAddress                  ; MapObjectGroup*[height][width] indexed by CHUNK_REF_OBJECT_GROUP_IDX
        STRUCT_MEMBER.l containersBaseAddress
        STRUCT_MEMBER.l groupsBaseAddress
        STRUCT_MEMBER.b rowOffsetTable                          ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroup
        STRUCT_MEMBER.b flagNumber                              ; Each object group has a unique flag number in the active viewport
        STRUCT_MEMBER.b objectCount
        STRUCT_MEMBER.b transferableObjectCount
        STRUCT_MEMBER.b totalObjectCount
        STRUCT_MEMBER.w stateOffset                             ; Offset into the map's allocated state array for this group
        STRUCT_MEMBER.b objectDescriptors                       ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapHeader
        STRUCT_MEMBER.l foregroundAddress
        STRUCT_MEMBER.l backgroundAddress
        STRUCT_MEMBER.l tilesetAddress
        STRUCT_MEMBER.w stateSize
        STRUCT_MEMBER.l objectGroupMapAddress
        STRUCT_MEMBER.l viewportConfigurationAddress
    DEFINE_STRUCT_END

    DEFINE_STRUCT Map
        STRUCT_MEMBER.w width
        STRUCT_MEMBER.w stride
        STRUCT_MEMBER.w height
        STRUCT_MEMBER.w widthPatterns
        STRUCT_MEMBER.w heightPatterns
        STRUCT_MEMBER.w widthPixels
        STRUCT_MEMBER.w heightPixels
        STRUCT_MEMBER.l dataAddress                             ; Uncompressed
        STRUCT_MEMBER.b rowOffsetTable                          ; Marker
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
            move.w  MapDirectory_count(a0), d1
            cmp.w   d1, d0
            bge     .invalidMapIndex

            add.w   d0, d0
            add.w   d0, d0
            move.l  MapDirectory_maps(a0, d0), a0
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
        movea.l MapHeader_tilesetAddress(a0), a0
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
