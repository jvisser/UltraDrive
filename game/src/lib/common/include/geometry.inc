;------------------------------------------------------------------------------------------
; Geometric data structs
;------------------------------------------------------------------------------------------

    If (~def(__LIB_COMMON_GEOMETRY_INC))
__LIB_COMMON_GEOMETRY_INC Equ 1

    Include './system/include/memory.inc'

    DEFINE_STRUCT Point
        STRUCT_MEMBER.w x
        STRUCT_MEMBER.w y
    DEFINE_STRUCT_END

    DEFINE_STRUCT Rectangle
        STRUCT_MEMBER.w minX
        STRUCT_MEMBER.w minY
        STRUCT_MEMBER.w maxX
        STRUCT_MEMBER.w maxY
    DEFINE_STRUCT_END

    EndIf
