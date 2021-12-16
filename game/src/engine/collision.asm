;------------------------------------------------------------------------------------------
; General collision detection system.
;
; Allows for the specification of collision types and their interactions with other types (ie what can collide with what).
;
; The snapshot system makes it easy to implement interaction hierarchies of grouped objects. Children can interact with their parents groups but siblings groups can not interact with each other for example.
;
; Setup:
;   Determine collision types required for the specific use case.
;   - Specify collision types with DEFINE_COLLISION_TYPES
;   - Create collision meta data for each type using the DEFINE_COLLISION_TYPE_METADATA* macros
;       - Specify element type (AABB or Point)
;       - Specify incoming and outgoing type relations
;       - Specify collision handler routine
;
; Usage:
;   - Call CollisionInit once
;   - Call CollisionReset at the start of each frame/update unit
;   - For each collidable object:
;       - Allocate collision element using the COLLISION_ALLOCATE_ELEMENT macro or CollisionAllocateElement subroutine
;       - Populate members
;       - Call CollisionCheck on element
;
; Performance considerations:
;   Insertion order does have an impact on performance.
;   For example:
;       There is one instance of player that interacts with many bullets. Adding all the bullets first will have more opportunities for loop optimizations.
;------------------------------------------------------------------------------------------

; Public API:
;   Setup macros:
;   - DEFINE_COLLISION_TYPES
;   - DEFINE_COLLISION_TYPE_METADATA
;       - COLLISION_TYPE_DEPENDENCIES
;       - COLLISION_TYPE_DEPENDENTS
;   - DEFINE_COLLISION_TYPE_METADATA_END
;   Subroutines/Macros:
;   - COLLISION_ALLOCATE_ELEMENT
;   - CollisionInit
;   - CollisionReset
;   - CollisionAllocateElement
;   - CollisionCheck
;   - CollisionCreateSnapshotBefore
;   - CollisionCreateSnapshotAfter
;   - CollisionRestoreSnapshot


;-------------------------------------------------
; Collision detection constants
; ----------------
COLLISION_ELEMENT_TYPE_AABB     Equ 0
COLLISION_ELEMENT_TYPE_POINT    Equ 1                                   ; TODO: Implement


;-------------------------------------------------
; Collision detection structures
; ----------------
    DEFINE_STRUCT CollisionTypeMetadata
        STRUCT_MEMBER.w typeId                                          ; Sequential type id starting at 0
        STRUCT_MEMBER.w elementTypeId                                   ; AABB or point
        STRUCT_MEMBER.l handlerAddress                                  ; Address of subroutine handling the collision. Must preserve d6-d7/a0-a6.
        STRUCT_MEMBER.w dependencyMask                                  ; Combined typeMask of all dependencies (ie what collisions are we interested in)
        STRUCT_MEMBER.w dependentsMask                                  ; Combined typeMask of all dependents (types that are interested in this type)
        STRUCT_MEMBER.w relations                                       ; Marker. List of related type metadata (short pointers) as defined by outgoingTypeRelationsMask and incomingTypeRelationsMask terminated by NULL.
    DEFINE_STRUCT_END

    DEFINE_STRUCT CollisionElement
        STRUCT_MEMBER.w metadata                                        ; Pointer to CollisionTypeMetadata
    DEFINE_STRUCT_END

    DEFINE_STRUCT PointCollisionElement, CollisionElement
        STRUCT_MEMBER.w x
        STRUCT_MEMBER.w y
    DEFINE_STRUCT_END

    DEFINE_STRUCT AABBCollisionElement, CollisionElement
        STRUCT_MEMBER.w minX
        STRUCT_MEMBER.w minY
        STRUCT_MEMBER.w maxX
        STRUCT_MEMBER.w maxY
    DEFINE_STRUCT_END

    DEFINE_STRUCT CollisionElementLink
        STRUCT_MEMBER.w next                                            ; Next CollisionElementLink
        ; Data follows immediately after next
    DEFINE_STRUCT_END

    DEFINE_STRUCT CollisionState
        STRUCT_MEMBER.w freeMemory                                      ; Pointer to the first free memory
        STRUCT_MEMBER.w typeHeadArray                                   ; Map<CollisionType, CollisionElementLink>
    DEFINE_STRUCT_END


;-------------------------------------------------
; Collision detection internal variables
; ----------------
    DEFINE_VAR SHORT
        VAR.w collisionAllocationBaseAddress
    DEFINE_VAR_END


;-------------------------------------------------
; Define all the collision types.
; NB: The list order also determines the order of processing between collisions types.
; ----------------
; Input:
; - types: List of collision type names
; Output:
; - COLLISION_TYPE_[type]: Type id constant
; - COLLISION_STATE_SIZE: Size in bytes of collision state
; - COLLISION_TYPE_COUNT: Number of collision types
DEFINE_COLLISION_TYPES Macro types
        Local TYPE_ID

COLLISION_STATE_SIZE Equ ((narg + 1) * SIZE_WORD)
COLLISION_TYPE_COUNT Equ (narg)

        SECTION_START S_PROGRAM
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
        SECTION_END

        SECTION_START S_PROGRAM_SHORT
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
        SECTION_END

        Rept (COLLISION_TYPE_COUNT >> 1)
                SECTION_START S_PROGRAM
                    move.l  d7, (a6)+
                SECTION_END

                SECTION_START S_PROGRAM_SHORT
                    move.l  (a5)+, (a6)+
                SECTION_END
        Endr
        Rept (COLLISION_TYPE_COUNT & 1)
                SECTION_START S_PROGRAM
                    move.w  d7, (a6)+
                SECTION_END

                SECTION_START S_PROGRAM_SHORT
                    move.w  (a5)+, (a6)+
                SECTION_END
        Endr
        SECTION_START S_PROGRAM
            rts
        SECTION_END
        SECTION_START S_PROGRAM_SHORT
            rts
        SECTION_END

TYPE_ID = 0
        SECTION_START S_RODATA_SHORT
            collisionStateSize:
                dc.w COLLISION_STATE_SIZE
            CollisionTypeMetadataTable:
        SECTION_END

            Rept narg
COLLISION_TYPE_\1    Equ  \#TYPE_ID
                SECTION_START S_RODATA_SHORT
                    dc.w \1\CollisionTypeMetadata
                SECTION_END
TYPE_ID = TYPE_ID + 1
                Shift
            Endr
    Endm


;-------------------------------------------------
; Start collision type metadata block for the specified type
; ----------------
; Input:
; - type: Type as defined by DEFINE_COLLISION_TYPES
; - collisionElementType: Either AABB or POINT
; - handlerAddress: Optional address of the subroutine handling the collision
; Output:
; - [type]CollisionTypeMetadata: Address of the meta data (short addressable)
DEFINE_COLLISION_TYPE_METADATA Macro type, collisionElementType, handlerAddress
    Local TYPE_ID
        If (strcmp('\collisionElementType', 'POINT'))
            Inform 3, 'POINT collision element type not (yet) supported'
        EndIf
TYPE_ID Equ COLLISION_TYPE_\type
        SECTION_START S_RODATA_SHORT
        _\#TYPE_ID\CollisionTypeMetadata:

        ; struct CollisionType
        \type\CollisionTypeMetadata:
            ; .typeId
            dc.w COLLISION_TYPE_\type
            ; .elementTypeId
            dc.w COLLISION_ELEMENT_TYPE_\collisionElementType
            If (narg<3)
                dc.l NoOperation
            Else
                ; .handlerAddress
                dc.l \handlerAddress
            Endif
    Endm


;-------------------------------------------------
; Define outgoing type relations
; ----------------
; Input:
; - types: List of collision type names as defined by DEFINE_COLLISION_TYPES
COLLISION_TYPE_DEPENDENCIES Macro types
DEPENDENCY_COLLISION_MASK = 0
        Rept narg
DEPENDENCY_COLLISION_MASK = DEPENDENCY_COLLISION_MASK | (1 << (COLLISION_TYPE_\1\))
            Shift
        Endr
        ; .dependencyMask
        dc.w DEPENDENCY_COLLISION_MASK
    Endm


;-------------------------------------------------
; Define incoming type relations
; ----------------
; Input:
; - types: List of collision type names as defined by DEFINE_COLLISION_TYPES
COLLISION_TYPE_DEPENDENTS Macro typeIds
DEPENDENTS_COLLISION_MASK = 0
        Rept narg
DEPENDENTS_COLLISION_MASK = DEPENDENTS_COLLISION_MASK | (1 << (COLLISION_TYPE_\1\))
            Shift
        Endr
        ; .dependentsMask
        dc.w DEPENDENTS_COLLISION_MASK
    Endm


;-------------------------------------------------
; End collision type metadata block
; ----------------
DEFINE_COLLISION_TYPE_METADATA_END Macro
COLLISION_RELATION_MASK = (DEPENDENCY_COLLISION_MASK | DEPENDENTS_COLLISION_MASK)
CURRENT_COLLISION_TYPE = 0
        Rept 16
            If (COLLISION_RELATION_MASK & (1 << CURRENT_COLLISION_TYPE))
                ; .relations
                dc.w _\#CURRENT_COLLISION_TYPE\CollisionTypeMetadata
            EndIf
CURRENT_COLLISION_TYPE = CURRENT_COLLISION_TYPE + 1
        Endr
        dc.w NULL                 ; list terminator
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
COLLISION_ALLOCATE_ELEMENT Macro size, result, scratch, scratch2
        movea.w collisionAllocationBaseAddress, \scratch
        movea.w CollisionState_freeMemory(\scratch), \result
        addq.w  #CollisionElementLink_Size, \result
        movea.l \result, \scratch2
        adda.w  \size, \scratch2
        move.w  \scratch2, CollisionState_freeMemory(\scratch)
    Endm


;-------------------------------------------------
; Allocate memory for collision elements/links and snapshots.
; ----------------
; Input:
; - d0: Size in bytes of memory to allocate
; Uses: d0/d7/a0-a1/a6
CollisionInit:
        ; Allocate collision system memory
        jsr     MemoryAllocate
        move.w  a0, collisionAllocationBaseAddress

        ; NB: Fall through to CollisionReset


;-------------------------------------------------
; Clear collision state
; ----------------
; Uses: d7/a0/a6
CollisionReset:
        ; Clear state
        movea.w collisionAllocationBaseAddress, a0
        movea.l a0, a6
        jsr     _CollisionClearState

        ; a6 will be the first free memory address now. Store.
        move.w  a6, CollisionState_freeMemory(a0)
        rts


;-------------------------------------------------
; Allocate memory for collision element of specified size
; ----------------
; Input:
; - d0: Size in bytes of memory to allocate
; Output:
; - a0: Address of allocated element memory
; Uses:
; - a0-a2
CollisionAllocateElement:
        COLLISION_ALLOCATE_ELEMENT d0, a0, a1, a2
        rts


;-------------------------------------------------
; Check collisions of the specified collision element against its related elements.
; NB: Other elements this element interacts with that are added at a later point will also trigger the collision response for this element.
; ----------------
; Input:
; - a0: Address of the collision element
; Uses:
; - d0-d6/a1-a6
CollisionCheck:
        ; Check collisions against known collision elements
        movea.w CollisionElement_metadata(a0), a1                   ; a1 = collision type metadata
        lea     CollisionTypeMetadata_relations(a1), a2             ; a2 = related collision type metadata
        move.w  collisionAllocationBaseAddress, a3                  ; a3 = current collision state (CollisionState)

        move.w  (a2)+, d0
        beq.s    .collisionCheckDone

        ; Store bounds in d6, d7
        move.l  AABBCollisionElement_minX(a0), d6                   ; d6 = (minX, minY)
        move.l  AABBCollisionElement_maxX(a0), d7                   ; d7 = (maxX, maxY)

        ; Loop over related types
        .relationLoop:
            move.w  d0, a4                                          ; a4 = related element metadata

            move.w  CollisionTypeMetadata_typeId(a4), d1            ; d1 = related element type id
            add.w   d1, d1                                          ; d1 = offset into element type array
            move.w  CollisionState_typeHeadArray(a3, d1), d1        ; d1 = head of the related type element list (CollisionElementLink)
            beq.s   .noRelatedElements

                ; Loop over all element instances of related type
                .relatedElementLoop:

                    movea.w d1, a5                                  ; a5 = head of the related type element list (CollisionElementLink)

                    ; Do AABB collision check
                    lea     CollisionElementLink_Size(a5), a6       ; a6 = related element
                    move.l  AABBCollisionElement_minX(a6), d4       ; d4 = (minX, minY) of related element
                    move.l  AABBCollisionElement_maxX(a6), d5       ; d5 = (maxX, maxY) of related element

                    ; If this.minY > related.maxY: no intersection
                    cmp.w   d5, d6
                    bgt.s   .noCollision

                    ; If this.maxY < related.minY: no intersection
                    cmp.w   d4, d7
                    blt.s   .noCollision

                    ; If this.minX > related.maxX: no intersection
                    swap    d6
                    swap    d5
                    cmp.w   d5, d6
                    bgt.s   .noCollisionMinX

                    ; If this.maxX < related.minX: no intersection
                    swap    d7
                    swap    d4
                    cmp.w   d4, d7
                    blt.s   .noCollisionMaxX

                        ; We have a collision!

                        ; Call related type handler first (its element was registered before this)
                        move.w  CollisionTypeMetadata_typeId(a1), d4
                        move.w  CollisionTypeMetadata_dependencyMask(a4), d5
                        btst    d4, d5
                        beq.s   .noDependent

                            PUSHW   a1
                            PUSHW   a6

                            movea.l a6, a1
                            exg     a0, a1
                            movea.l CollisionTypeMetadata_handlerAddress(a4), a6
                            jsr     (a6)
                            movea.l a1, a0

                            POPW   a6
                            POPW   a1

                    .noDependent:

                        ; Call this type handler
                        move.w  CollisionTypeMetadata_typeId(a4), d4
                        move.w  CollisionTypeMetadata_dependencyMask(a1), d5
                        btst    d4, d5
                        beq.s   .noDependency

                            ; Call type handler
                            PUSHW   a1
                            PUSHW   a5

                            movea.l CollisionTypeMetadata_handlerAddress(a1), a5
                            movea.l a6, a1
                            jsr     (a5)

                            POPW    a5
                            POPW    a1

                    .noDependency:

                .noCollisionMaxX:
                    swap    d7
                .noCollisionMinX:
                    swap    d6
                .noCollision:

                    ; Next related element
                    move.w  CollisionElementLink_next(a5), d1
                    bne     .relatedElementLoop

        .noRelatedElements:

            ; Next type relation
            move.w  (a2)+, d0
            bne     .relationLoop

    .collisionCheckDone:

        ; Register this element
        move.w  CollisionTypeMetadata_typeId(a1), d1            ; d1 = element type id
        add.w   d1, d1                                          ; d1 = offset into element type array
        subq.w  #CollisionElementLink_Size, a0                  ; a0 = element link for this element
        move.w  CollisionState_typeHeadArray(a3, d1), CollisionElementLink_next(a0)
        move.w  a0, CollisionState_typeHeadArray(a3, d1)
        rts


;-------------------------------------------------
; Allocate and populate snapshot with current collision state excluding the snapshot itself
; ----------------
; Output:
; - a0: Address of the snapshot (short addressable)
; Uses:
; - a0/a4-a6
CollisionCreateSnapshotBefore:
        movea.w collisionAllocationBaseAddress, a4
        movea.w CollisionState_freeMemory(a4), a0

        ; Fill snapshot with current state
        movea.w a4, a5
        movea.l a0, a6
        jsr     _CollisionCopyState.w

        ; Update current state free memory pointer
        move.w  a6, CollisionState_freeMemory(a4)
        rts


;-------------------------------------------------
; Allocate and populate snapshot with current collision state including the snapshot itself
; ----------------
; Output:
; - a0: Address of the snapshot (short addressable)
; Uses:
; - a0/a4-a6
CollisionCreateSnapshotAfter:
        movea.w collisionAllocationBaseAddress, a4
        movea.w CollisionState_freeMemory(a4), a0

        ; Fill snapshot with current state
        movea.w a4, a5
        movea.l a0, a6
        jsr     _CollisionCopyState.w

        ; Update current and snapshot state free memory pointer
        move.w  a6, CollisionState_freeMemory(a0)
        move.w  a6, CollisionState_freeMemory(a4)
        rts


;-------------------------------------------------
; Restore collision state snapshot
; ----------------
; Input:
; - a0: Address of the snapshot to restore from
; Uses:
; - a5-a6
CollisionRestoreSnapshot:
        movea.l a0, a5
        movea.w collisionAllocationBaseAddress, a6
        jmp     _CollisionCopyState.w
