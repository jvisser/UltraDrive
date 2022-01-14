;------------------------------------------------------------------------------------------
; General collision detection system.
;------------------------------------------------------------------------------------------
; Public API:
;   - CollisionInit
;   - CollisionReset
;   - CollisionAllocateElement
;   - CollisionCheck
;   - CollisionCreateSnapshotBefore
;   - CollisionCreateSnapshotAfter
;   - CollisionRestoreSnapshot

    Include './engine/include/collision.inc'

;-------------------------------------------------
; Collision detection internal variables
; ----------------
    DEFINE_VAR SHORT
        VAR.w collisionAllocationBaseAddress
    DEFINE_VAR_END


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
