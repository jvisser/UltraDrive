;------------------------------------------------------------------------------------------
; Some default AABB collision element implementations
;------------------------------------------------------------------------------------------

    If (~def(__LIB_GAME_COLLISION_ELEMENTS_INC))
__LIB_GAME_COLLISION_ELEMENTS_INC Equ 1

    Include './lib/common/include/geometry.inc'

    Include './system/include/memory.inc'

    DEFINE_STRUCT PlayerCollisionElement, Rectangle
        STRUCT_MEMBER.w player
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectCollisionElement, Rectangle
        STRUCT_MEMBER.w objectType
        STRUCT_MEMBER.w objectInstance
    DEFINE_STRUCT_END

    DEFINE_STRUCT HurtCollisionElement, Rectangle
        STRUCT_MEMBER.w damage
    DEFINE_STRUCT_END

    EndIf
