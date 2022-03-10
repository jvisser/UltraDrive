;------------------------------------------------------------------------------------------
; General AABB collision detection system.
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_COLLISION_INC))
__ENGINE_COLLISION_INC Equ 1

    Include './system/include/memory.inc'

;-------------------------------------------------
; Collision constants
; ----------------
COLLISION_MAX_RELATIONS Equ (SIZE_WORD * 8)


;-------------------------------------------------
; Collision detection structures
; ----------------
    DEFINE_STRUCT CollisionElementType
        STRUCT_MEMBER.w typeMask                                        ; Type mask for the implementing types
        STRUCT_MEMBER.w incomingRelationMask                            ; Combined typeMask of all dependencies (ie what collisions are we interested in)
        STRUCT_MEMBER.w outgoingRelationMask                            ; Combined typeMask of all dependents (types that are interested in this type)
        STRUCT_MEMBER.w allocationSize                                  ; Total size required for allocating an element for this type (including Element_Size, Element type ptr)
        STRUCT_MEMBER.l handler                                         ; handler(*thisElement, *thatElement, incomingTypeMask). Must preserve d2-d7/a0-a6
        ; Offset to the following variable size struct:
        ;   - word relatedCollisionTypeCount - 1
        ;   - word relatedCollisionTypes[relatedCollisionTypeCount]
        ;   - word linkAllocationSize                                   ; Allocation size for all links combined
        ;   - word ownCollisionTypeCount - 1
        ;   - word ownCollisionTypes[ownCollisionTypeCount]
        STRUCT_MEMBER.w relations                                       ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT CollisionElementLink
        STRUCT_MEMBER.w next                                            ; Next CollisionElementLink
        STRUCT_MEMBER.w element                                         ; Short ptr to element
    DEFINE_STRUCT_END

    DEFINE_STRUCT CollisionState
        STRUCT_MEMBER.w freeMemory                                      ; Pointer to the first free memory
        STRUCT_MEMBER.w typeHeadArray                                   ; Map<CollisionType, CollisionElementLink>
    DEFINE_STRUCT_END


; Entering macro hell...


;-------------------------------------------------
; Define all the collision types.
; ----------------
; Input:
; - types: List of collision type names
; Output:
; - COLLISION_TYPE_[type]
; - COLLISION_TYPE_[type]_MASK
; - COLLISION_TYPE_[type]_RELATION_IN
; - COLLISION_TYPE_[type]_RELATION_OUT
DEFINE_COLLISION_TYPES Macro types
        Local TYPE_ID

COLLISION_STATE_SIZE Equ ((narg + 1) * SIZE_WORD)
COLLISION_TYPE_COUNT Equ (narg)

        ; Code generation
        SECTION_START S_PROGRAM_SHORT
            ;-------------------------------------------------
            ; Clear collision state
            ; ----------------
            ; Input:
            ; - a6: Address of the state snapshot to clear
            ; Uses:
            ; - d7/a6
            _CollisionClearState:
                moveq   #0, d7
                move.w  d7, (a6)+       ; CollisionState_freeMemory
                Rept (COLLISION_TYPE_COUNT >> 1)
                    move.l  d7, (a6)+
                Endr
                Rept (COLLISION_TYPE_COUNT & 1)
                    move.w  d7, (a6)+
                Endr
                rts

            ;-------------------------------------------------
            ; Copy collisions state
            ; ----------------
            ; Input:
            ; - a5: Address of the state snapshot to restore from
            ; - a6: Address of the state snapshot to restore to
            ; Uses:
            ; - a5-a6
            _CollisionCopyState:
                move.w  (a5)+, (a6)+    ; CollisionState_freeMemory
                Rept (COLLISION_TYPE_COUNT >> 1)
                    move.l  (a5)+, (a6)+
                Endr
                Rept (COLLISION_TYPE_COUNT & 1)
                    move.w  (a5)+, (a6)+
                Endr
                rts
        SECTION_END

        SECTION_START S_RODATA_SHORT
            collisionStateSize:
                dc.w COLLISION_STATE_SIZE
        SECTION_END

TYPE_ID     = 0
TYPE_MASK   = 0
        Rept narg
COLLISION_TYPE_\1                       Equ \#TYPE_ID
COLLISION_TYPE_\1\_MASK                 Equ (1 << TYPE_MASK)
COLLISION_TYPE_\1\_RELATION_IN          = 0
COLLISION_TYPE_\1\_RELATION_OUT         = 0

COLLISION_TYPE_\#TYPE_ID\_NAME          Equs '\1'
COLLISION_TYPE_MASK\#TYPE_MASK\_NAME    Equs '\1'

TYPE_ID     = TYPE_ID + 1
TYPE_MASK   = (1 << TYPE_ID)
            Shift
        Endr
    Endm


;-------------------------------------------------
; Specify relation to other types. Can be specified multiple times.
;
; Best practice is to define only one relation per collision type (between sender/receiver).
; This way the handler subroutine can identify the exact relation based on the passed relation mask
; Then let the element type implement multiple collision types to define more complex relations.
;   The exception to this rule is for self referencing collision types.
;   This can not be defined through composition on the element type and must be defined on the collision type itself.
; ----------------
; Input:
; - \0: Relation type: Either IN or OUT
; - type: Collision type for which to define the relations
; - relatedTypes: List of related collision types for with the specified relation type
; Output:
; - COLLISION_TYPE_[type]_RELATION_IN
; - COLLISION_TYPE_[type]_RELATION_OUT
DEFINE_COLLISION_TYPE_RELATION Macro type, relatedTypes
    Local __OPPOSITE_REL
        If (strcmp('\0', 'OUT'))
__OPPOSITE_REL Equs 'IN'
        Else
__OPPOSITE_REL Equs 'OUT'
        EndIf
        Rept narg(relatedTypes)
COLLISION_TYPE_\relatedTypes\_RELATION_\__OPPOSITE_REL = COLLISION_TYPE_\relatedTypes\_RELATION_\__OPPOSITE_REL | (1 << COLLISION_TYPE_\type)
COLLISION_TYPE_\type\_RELATION_\0 = COLLISION_TYPE_\type\_RELATION_\0 | (1 << COLLISION_TYPE_\relatedTypes)
            Shift relatedTypes
        Endr
    Endm


;-------------------------------------------------
; Start collision element type block
; NB: Care must be taken so that all outgoing collision type relations are compatible with the specified data type
; ----------------
; Input:
; - \0: Symbol addressing the element type
; - dataType: The data type of the element instance (Should be based on/structurally compatible with Rectangle)
; - types: The list of collision types this element implements
; - handlerAddress: Optional address of the subroutine handling the collision for incoming connections
DEFINE_COLLISION_ELEMENT_TYPE Macro types, dataType, handlerAddress
    Local __TYPE_RELATION, __TYPE_RELATION_NAME, __TYPES, __TYPE_NAME, __TYPE_COUNT, __RELATION_COUNT, __INDEX, __INCOMING_RELATIONS, __OUTGOING_RELATIONS, __RELATIONS

__TYPE_COUNT            Equ narg(types)
__TYPES                 = 0
__INCOMING_RELATIONS    = 0
__OUTGOING_RELATIONS    = 0
        Rept narg(types)
__TYPES                 = __TYPES | (1 << COLLISION_TYPE_\types)
            Shift types
        Endr

__INDEX = 0;
        Rept COLLISION_MAX_RELATIONS
            If (__TYPES & (1 << __INDEX))
__TYPE_NAME             Equs COLLISION_TYPE_\#__INDEX\_NAME
__INCOMING_RELATIONS    = __INCOMING_RELATIONS | (COLLISION_TYPE_\__TYPE_NAME\_RELATION_IN)
__OUTGOING_RELATIONS    = __OUTGOING_RELATIONS | (COLLISION_TYPE_\__TYPE_NAME\_RELATION_OUT)

__TYPE_RELATION = (COLLISION_TYPE_\__TYPE_NAME\_RELATION_IN) | (COLLISION_TYPE_\__TYPE_NAME\_RELATION_OUT)
                If ((((__TYPE_RELATION & __TYPES) <> 0) & ((__TYPE_RELATION & (1 << __INDEX)) = 0)))
                    ; Collision types can reference themselves directly in the collision type graph. But not by composition of separate sender and receiver collision types in the same collision element type.
                    ; This would cause collision checks for both sides of the relation on the same element which then need to be mitigated etc... it would tank performance in any case. Also it will probably not really be used in real world scenarios?!
                    If ((__TYPE_RELATION & (__TYPE_RELATION - 1)) = 0)
__TYPE_RELATION_NAME Equs COLLISION_TYPE_MASK\#__TYPE_RELATION\_NAME
                    Else
__TYPE_RELATION_NAME Equs 'one in collision type mask $\$__TYPE_RELATION'
                    EndIf
                    Inform 3, 'Circular collision type dependency found in collision element type "\0" between collision type "\__TYPE_NAME" and collision type "\__TYPE_RELATION_NAME". Self referential collisions must be configured in the collision type graph using DEFINE_COLLISION_TYPE_RELATION. Not at the collision element type level.'
                EndIf
            EndIf
__INDEX = __INDEX + 1;
        Endr

__RELATIONS             = __INCOMING_RELATIONS | __OUTGOING_RELATIONS
__RELATION_COUNT = 0;
__INDEX = 0;
        Rept COLLISION_MAX_RELATIONS
            If (__RELATIONS & (1 << __INDEX))
__RELATION_COUNT = __RELATION_COUNT + 1;
            EndIf
__INDEX = __INDEX + 1;
        Endr

        SECTION_START S_RODATA_SHORT
    \0:
        ; struct CollisionElementType
            ; .typeMask
            dc.w __TYPES
            ; .incomingRelationMask
            dc.w __INCOMING_RELATIONS
            ; .outgoingRelationMask
            dc.w __OUTGOING_RELATIONS
            ; .allocationSize
            dc.w SIZE_WORD + \dataType\_Size
            ; .handler
            If (narg < 3)
                dc.l NoOperation
            Else
                dc.l \handlerAddress
            EndIf
            ; .relations
                ; .relatedCollisionTypeCount
                dc.w __RELATION_COUNT - 1
                ; .relatedCollisionTypes
__INDEX = 0;
                Rept COLLISION_MAX_RELATIONS
                    If (__RELATIONS & (1 << __INDEX))
                        dc.w __INDEX
                    EndIf
__INDEX = __INDEX + 1;
                Endr
                ; .linkAllocationSize
                dc.w __TYPE_COUNT * CollisionElementLink_Size
                ; .ownCollisionTypeCount
                dc.w __TYPE_COUNT - 1
                ; .ownCollisionTypes
__INDEX = 0;
                Rept COLLISION_MAX_RELATIONS
                    If (__TYPES & (1 << __INDEX))
                        dc.w __INDEX
                    EndIf
__INDEX = __INDEX + 1;
                Endr
            SECTION_END
    Endm


;-------------------------------------------------
; Allocate memory from the collision state memory pool
; ----------------
; Input:
; - size: Size in bytes of memory to allocate
; - result: Address register receiving the resuling value
; - scratch; Scratch address register
; - scratch2; Scratch address register
COLLISION_ALLOCATE Macro size, result, scratch, scratch2
        movea.w collisionAllocationBaseAddress, \scratch
        movea.w CollisionState_freeMemory(\scratch), \result
        movea.l \result, \scratch2
        add.w   \size, \scratch2
        move.w  \scratch2, CollisionState_freeMemory(\scratch)
    Endm


;-------------------------------------------------
; Allocate collision element instance
; ----------------
; Input:
; - elementType: Address of the element type
; - result: Address register receiving the resulting element address
; - scratch; Scratch address register
; - scratch2; Scratch address register
; - scratch3; Scratch address register
COLLISION_ALLOCATE_ELEMENT Macro elementType, result, scratch, scratch2, scratch3
        lea     elementType, \scratch3
        movea.w collisionAllocationBaseAddress, \scratch
        movea.w CollisionState_freeMemory(\scratch), \result
        movea.l \result, \scratch2
        add.w   CollisionElementType_allocationSize(\scratch3), \scratch2
        move.w  \scratch3, (\result)+
        move.w  \scratch2, CollisionState_freeMemory(\scratch)
    Endm

    EndIf
