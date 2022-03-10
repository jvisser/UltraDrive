;------------------------------------------------------------------------------------------
; General collision detection system.
;
; Public API:
;   - CollisionInit
;   - CollisionReset
;   - CollisionCheck
;   - CollisionCheckEx
;   - CollisionCreateSnapshotBefore
;   - CollisionCreateSnapshotAfter
;   - CollisionRestoreSnapshot
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'

    Include './engine/include/collision.inc'

    Include './lib/common/include/geometry.inc'

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
        jsr     _CollisionClearState.w

        ; a6 will be the first free memory address now. Store.
        move.w  a6, CollisionState_freeMemory(a0)
        rts


;-------------------------------------------------
; Check collisions of the specified collision element against its related elements.
; ----------------
; Input:
; - a0: Address of the collision element instance
CollisionCheck:
    movea.w -SIZE_WORD(a0), a1                                      ; a1 = element type address for this element

    ; NB: Fall through to CollisionCheckEx


;-------------------------------------------------
; Check collisions of the specified collision element against its related elements.
; ----------------
; Input:
; - a0: Address of the collision element instance
; - a1: Address of the element type for the element to register
; Uses:
; - d0-d7/a2-a6
CollisionCheckEx:
        ; Check collisions against known collision elements
        lea     CollisionElementType_relations(a1), a2              ; a2 = related collision type metadata
        move.w  collisionAllocationBaseAddress, a3                  ; a3 = current collision state (CollisionState)

        ; Store bounds in d6, d7
        move.l  Rectangle_minX(a0), d6                              ; d6 = (minX, minY)
        move.l  Rectangle_maxX(a0), d7                              ; d7 = (maxX, maxY)

        move.w  (a2)+, d3                                           ; d3 = relation loop counter (relatedCollisionTypeCount)

        ; Loop over related types (this assumes at least one relation exists for the types this element implements)
        .relationLoop:

            move.w  (a2)+, d1                                       ; d1 = related element type id
            add.w   d1, d1                                          ; d1 = offset into element type array
            move.w  CollisionState_typeHeadArray(a3, d1), d1        ; d1 = head of the related type element list (CollisionElementLink)
            beq.s   .noRelatedElements

                ; Loop over all element instances of related type
                .relatedElementLoop:

                    movea.w d1, a5                                  ; a5 = head of the related type element list (CollisionElementLink)

                    ; Do AABB collision check
                    movea.w CollisionElementLink_element(a5), a6    ; a6 = related element
                    movea.w -SIZE_WORD(a6), a4                      ; a4 = related element meta data
                    move.l  Rectangle_minX(a6), d4                  ; d4 = (minX, minY) of related element
                    move.l  Rectangle_maxX(a6), d5                  ; d5 = (maxX, maxY) of related element

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
                        move.w  CollisionElementType_typeMask(a1), d0
                        and.w   CollisionElementType_incomingRelationMask(a4), d0
                        beq.s   .noOutgoingRelation

                            PUSHW   a1
                            PUSHW   a6

                            movea.l a6, a1
                            exg     a0, a1
                            movea.l CollisionElementType_handler(a4), a6
                            jsr     (a6)
                            movea.l a1, a0

                            POPW   a6
                            POPW   a1

                    .noOutgoingRelation:

                        ; Call this type handler
                        move.w  CollisionElementType_typeMask(a4), d0
                        and.w   CollisionElementType_incomingRelationMask(a1), d0
                        beq.s   .noIncomingRelation

                            ; Call type handler
                            PUSHW   a1
                            PUSHW   a5

                            movea.l CollisionElementType_handler(a1), a5
                            movea.l a6, a1
                            jsr     (a5)

                            POPW    a5
                            POPW    a1

                    .noIncomingRelation:

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
            dbra    d3, .relationLoop

    .collisionCheckDone:

        ; a2 points to CollisionElementType_linkAllocationSize at this point

        ; Allocate memory for all links
        COLLISION_ALLOCATE (a2)+, a4, a5, a6

        ; Register links for all collision types this element implements
        move.w  (a2)+, d0
    .registerLinkLoop:

            move.w  a0, CollisionElementLink_element(a4)            ; Save element pointer in link
            move.w  (a2)+, d1                                       ; d1 = element type id
            add.w   d1, d1                                          ; d1 = offset into element type array
            move.w  CollisionState_typeHeadArray(a3, d1), CollisionElementLink_next(a4)
            move.w  a4, CollisionState_typeHeadArray(a3, d1)

            ; Next link
            add.w   #CollisionElementLink_Size, a4
        dbra    d0, .registerLinkLoop
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
