;------------------------------------------------------------------------------------------
; Collision types
;------------------------------------------------------------------------------------------

    DEFINE_COLLISION_TYPES &
        Player,            &
        Enemy,             &
        HurtPlayer,        &
        HurtEnemy

    ; Player collision type metadata
    DEFINE_COLLISION_TYPE_METADATA Player, AABB, _HandleCollision
            COLLISION_TYPE_DEPENDENCIES                             &
                HurtPlayer
            COLLISION_TYPE_DEPENDENTS
    DEFINE_COLLISION_TYPE_METADATA_END

    ; Enemy collision type metadata
    DEFINE_COLLISION_TYPE_METADATA Enemy, AABB, _HandleCollision
            COLLISION_TYPE_DEPENDENCIES                             &
                HurtEnemy
            COLLISION_TYPE_DEPENDENTS
    DEFINE_COLLISION_TYPE_METADATA_END

    ; Hurt player collision type metadata
    DEFINE_COLLISION_TYPE_METADATA HurtPlayer, AABB
            COLLISION_TYPE_DEPENDENCIES
            COLLISION_TYPE_DEPENDENTS                               &
                Player
    DEFINE_COLLISION_TYPE_METADATA_END

    ; Hurt enemy collision type metadata
    DEFINE_COLLISION_TYPE_METADATA HurtEnemy, AABB
            COLLISION_TYPE_DEPENDENCIES
            COLLISION_TYPE_DEPENDENTS                               &
                Enemy
    DEFINE_COLLISION_TYPE_METADATA_END


;-------------------------------------------------
; Game specific collision elements
; ----------------
    DEFINE_STRUCT HandlerCollisionElement, AABBCollisionElement
        STRUCT_MEMBER.w data
        STRUCT_MEMBER.l handler         ; Must preserve a0-a5
    DEFINE_STRUCT_END

    DEFINE_STRUCT HurtCollisionElement, AABBCollisionElement
        STRUCT_MEMBER.w damage
    DEFINE_STRUCT_END


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
    movea.l HandlerCollisionElement_handler(a0), a6
    jsr     (a6)
    POPL   a6
    rts

