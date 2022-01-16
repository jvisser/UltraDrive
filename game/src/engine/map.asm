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
        VAR.w                   mapStateAddress
        VAR.MapObjectGroupState mapGlobalObjectGroupState
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

        ; Allocate map state area
        PUSHL   a0
        move.w  MapHeader_stateSize(a0), d0
        jsr     MemoryAllocate
        move.w  a0, mapStateAddress
        POPL    a0

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
MapUnload:
        ; Release tileset
        jsr     TilesetUnload

        ; Release object resources
        jsr     MapReleaseObjectResources

        ; Reset map pointer
        move.l  #NULL, mapLoadedMap
        rts
