;------------------------------------------------------------------------------------------
; Entity base class
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Entity structure
; ----------------
    DEFINE_STRUCT Entity
        STRUCT_MEMBER.l entityX         ; In 16.16 fixed point format
        STRUCT_MEMBER.l entityY
    DEFINE_STRUCT_END
