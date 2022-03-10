;------------------------------------------------------------------------------------------
; More opinionated collision type system implementation. Based around types and its observers.
; These collision types can then be composed in specific collision element types.
;
; This is less efficient than having a fixed collision type system but more flexible because of the composition in collision element types.
; This way each collision element producer can create its own configuration based on its specific needs.
;
; The downside is that self referential collision types are not possible using composition of a type and its observer type in the same collision element type.
; These are only supported at the collision type level using DEFINE_COLLISION_TYPE_RELATION.
; As a result this is not supported using this collision type system.
;------------------------------------------------------------------------------------------

    If (~def(__LIB_GAME_COLLISION_TYPES_INC))
__LIB_GAME_COLLISION_TYPES_INC Equ 1

    Include './engine/include/collision.inc'

;-------------------------------------------------
; Collision type graph
; ----------------

    ; Collision types
    DEFINE_COLLISION_TYPES          &
        Player,                     &
        PlayerAware,                &
        Enemy,                      &
        EnemyAware,                 &
        Item,                       &
        ItemAware,                  &
        Actionable,                 &
        ActionableAware,            &
        Barrier,                    &
        BarrierAware,               &
        HurtPlayer,                 &
        HurtPlayerAware,            &
        HurtEnemy,                  &
        HurtEnemyAware,             &
        TransferableObject,         &
        TransferableObjectAware

    ; Collision type relations
    DEFINE_COLLISION_TYPE_RELATION.OUT Player,               {PlayerAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT Enemy,                {EnemyAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT Item,                 {ItemAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT Actionable,           {ActionableAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT Barrier,              {BarrierAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT HurtPlayer,           {HurtPlayerAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT HurtEnemy,            {HurtEnemyAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT TransferableObject,   {TransferableObjectAware}

    EndIf
