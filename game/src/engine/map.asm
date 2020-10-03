;------------------------------------------------------------------------------------------
; Map scrolling
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT Map
        STRUCT_MEMBER.w width
        STRUCT_MEMBER.l height
        STRUCT_MEMBER.l mapDataAddress
        STRUCT_MEMBER.l tilesetAddress
        STRUCT_MEMBER.l rowOffsetTable
    DEFINE_STRUCT_END
