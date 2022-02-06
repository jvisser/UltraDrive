;------------------------------------------------------------------------------------------
; Map loading
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'

    Include './engine/include/map.inc'

;-------------------------------------------------
; Map variables
; ----------------
    DEFINE_VAR SHORT
        VAR.l                   mapLoadedMap                                    ; MapHeader

        ; Cached values for quick access
        VAR.l                   mapMetadataMapAddress
        VAR.l                   mapObjectTypeTableAddress
        VAR.l                   mapForegroundAddress
        VAR.l                   mapBackgroundAddress
    DEFINE_VAR_END


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
            bge.s   .invalidMapIndex

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
        bne.s   .loadMap
            rts ; Map already loaded

    .loadMap:
        move.l  a0, mapLoadedMap

        ; Cache/init values
        move.l  MapHeader_metadataMapAddress(a0), mapMetadataMapAddress
        move.l  MapHeader_objectTypeTableAddress(a0), mapObjectTypeTableAddress
        move.l  MapHeader_foregroundAddress(a0), mapForegroundAddress
        move.l  MapHeader_backgroundAddress(a0), mapBackgroundAddress

        ; Allocate map state area
        jsr     MapInitState

        ; Load associated tileset
        movea.l MapHeader_tilesetAddress(a0), a0
        jsr     TilesetLoad

        ; Load object resources
        jsr     MapLoadObjectResources

        ; Init object instances
        jsr     MapInitObjects
        rts


;-------------------------------------------------
; Unload the map and its associated resources
; ----------------
; Uses: d0-d7/a0-a6
MapUnload:
        ; Release tileset
        jsr     TilesetUnload

        ; Release object resources
        jsr     MapReleaseObjectResources

        ; Reset map pointer
        move.l  #NULL, mapLoadedMap
        rts
