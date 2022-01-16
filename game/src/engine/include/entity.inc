;------------------------------------------------------------------------------------------
; Entity base class
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_ENTITY_INC))
__ENGINE_ENTITY_INC Equ 1

    Include './system/include/memory.inc'

;-------------------------------------------------
; Entity structure
; ----------------
    DEFINE_STRUCT Entity
        STRUCT_MEMBER.w x
        STRUCT_MEMBER.w y
    DEFINE_STRUCT_END

    EndIf
