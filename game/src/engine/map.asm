;------------------------------------------------------------------------------------------
; Map type definition and loading
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT MapHeader
        STRUCT_MEMBER.l mapForegroundAddress
        STRUCT_MEMBER.l mapBackgroundAddress
        STRUCT_MEMBER.l mapTilesetAddress
        STRUCT_MEMBER.l backgroundTrackerAddress
    DEFINE_STRUCT_END

    DEFINE_STRUCT Map
        STRUCT_MEMBER.w mapWidth
        STRUCT_MEMBER.w mapHeight
        STRUCT_MEMBER.w mapWidthPatterns
        STRUCT_MEMBER.w mapHeightPatterns
        STRUCT_MEMBER.w mapWidthPixels
        STRUCT_MEMBER.w mapHeightPixels
        STRUCT_MEMBER.l mapDataAddress                          ; Uncompressed
        STRUCT_MEMBER.b mapLockHorizontal
        STRUCT_MEMBER.b mapLockVertical
        STRUCT_MEMBER.b mapRowOffsetTable
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.l               loadedMap                           ; MapHeader
    DEFINE_VAR_END


;-------------------------------------------------
; Load a map and its associated resources
; ----------------
; Input:
; - a0: MapHeader address
; Uses: d0-d7/a0-a6
MapLoad:
        cmpa.l  loadedMap, a0
        bne     .loadMap
        rts ; Map already loaded

    .loadMap:
        move.l  a0, loadedMap

        ; Load associated tileset
        movea.l mapTilesetAddress(a0), a0
        jsr     TilesetLoad
        rts


;-------------------------------------------------
; Unload the map and its associated resources
; ----------------
MapUnload:
        jsr TilesetUnload

        move.l #0, loadedMap
        rts
