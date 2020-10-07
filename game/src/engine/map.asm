;------------------------------------------------------------------------------------------
; Map loading and rendering routines
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT Map
        STRUCT_MEMBER.w width
        STRUCT_MEMBER.w height
        STRUCT_MEMBER.l mapDataAddress      ; Uncompressed
        STRUCT_MEMBER.l tilesetAddress
        STRUCT_MEMBER.l rowOffsetTable
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.l       loadedMap
    DEFINE_VAR_END


;-------------------------------------------------
; Load a map and its associated resources
; ----------------
; Input:
; - a0: Map address
; Uses: d0-d7/a0-a6
MapLoad:
        cmpa.w  loadedMap, a0
        bne     .loadMap
        rts ; Map already loaded

    .loadMap:
        move.l  a0, loadedMap

        ; Load associated tileset
        movea.l tilesetAddress(a0), a0
        jsr     TilesetLoad
        rts


;-------------------------------------------------
; Render the map to the specified VDP background plane VRAM address.
; ----------------
; Input:
; - d0: left 8 pixel column
; - d1: top 8 pixel row
; - d2: Plane id
; Uses:
MapRender:
        rts
