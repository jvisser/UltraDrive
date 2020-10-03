;------------------------------------------------------------------------------------------
; Map scrolling
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
