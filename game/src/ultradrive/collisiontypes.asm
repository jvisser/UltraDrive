;------------------------------------------------------------------------------------------
; Collision types
;------------------------------------------------------------------------------------------

    Include './engine/include/collision.inc'

    Include './lib/common/include/geometry.inc'

;-------------------------------------------------
; Collision type graph
; ----------------

    ; Collision types
    DEFINE_COLLISION_TYPES &
        Player,            &
        PlayerAware,       &
        Enemy,             &
        EnemyAware,        &
        HurtPlayer,        &
        HurtPlayerAware,   &
        HurtEnemy,         &
        HurtEnemyAware

    ; Collision type relations
    DEFINE_COLLISION_TYPE_RELATION.OUT Player,       {PlayerAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT Enemy,        {Enemy, EnemyAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT HurtPlayer,   {HurtPlayerAware}
    DEFINE_COLLISION_TYPE_RELATION.OUT HurtEnemy,    {HurtEnemyAware}


;-------------------------------------------------
; Collision element type system
; ----------------

    ; AABB collision elements
    DEFINE_STRUCT HandlerCollisionElement, Rectangle
        STRUCT_MEMBER.w data
        STRUCT_MEMBER.l handlerAddress
    DEFINE_STRUCT_END

    DEFINE_STRUCT HurtCollisionElement, Rectangle
        STRUCT_MEMBER.w damage
    DEFINE_STRUCT_END


    ; AABB collision element type information
    DEFINE_COLLISION_ELEMENT_TYPE.PlayerCollisionElementType        {Player, HurtPlayerAware},              &
        HandlerCollisionElement,                                                                            &
        _HandleCollision

    DEFINE_COLLISION_ELEMENT_TYPE.EnemyCollisionElementType         {Enemy, HurtEnemyAware},                &
        HandlerCollisionElement,                                                                            &
        _HandleCollision

    DEFINE_COLLISION_ELEMENT_TYPE.HurtPlayerCollisionElementType    {HurtPlayer},                           &
        HurtCollisionElement                                                                                &

    DEFINE_COLLISION_ELEMENT_TYPE.HurtEnemyCollisionElementType     {HurtEnemy},                            &
        HurtCollisionElement                                                                                &

    DEFINE_COLLISION_ELEMENT_TYPE.HurtAllCollisionElementType       {HurtEnemy, HurtPlayer},                &
        HurtCollisionElement                                                                                &


;-------------------------------------------------
; Dispatch collision handling to the handler specified in the collision element
; ----------------
; Input:
; - a0: Address of this collision element
; - a1: Address of target collision element
; Uses:
; - a0-a3
_HandleCollision:
    PUSHL   a6
    movea.l HandlerCollisionElement_handlerAddress(a0), a6
    jsr     (a6)
    POPL   a6
    rts

