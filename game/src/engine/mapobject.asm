;------------------------------------------------------------------------------------------
; Map object handling
;
; Public API's:
; - MapUpdateObjects
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'

    Include './engine/include/map.inc'

;-------------------------------------------------
; Map object state
; ----------------
    DEFINE_VAR SHORT
        VAR.w mapNodeCache
    DEFINE_VAR_END


;-------------------------------------------------
; Run the specified object type resource handler for all object types used in the map
; ----------------
; Uses: d0-d7/a0-a6
_RUN_OBJECT_TYPE_RESOURCE_ROUTINE Macro routine
        MAP_GET_OBJECT_TYPE_TABLE a0

        move.w  (a0)+, d0
        beq.s   .noObjectTypes\@

    .objectTypeLoop\@:

            movea.w d0, a1
            movea.l \routine\(a1), a1

            PUSHL   a0
            jsr     (a1)
            POPL    a0

            move.w  (a0)+, d0
            bne     .objectTypeLoop\@
    .noObjectTypes\@:
    Endm


;-------------------------------------------------
; Load resources for all object types used
; ----------------
; Uses: d0-d7/a0-a6
MapLoadObjectResources:
        _RUN_OBJECT_TYPE_RESOURCE_ROUTINE MapObjectType_loadResources
        rts


;-------------------------------------------------
; Release resources for all object types used
; ----------------
; Uses: d0-d7/a0-a6
MapReleaseObjectResources:
        _RUN_OBJECT_TYPE_RESOURCE_ROUTINE MapObjectType_releaseResources
        rts


;-------------------------------------------------
; Initialize all object related stuff in the map
; ----------------
; Uses: d0-d7/a0-a6
MapInitObjects:
        ; Init addresses
        MAP_GET_STATE a3                                                        ; a3 = Map state base
        MAP_GET_METADATA_MAP a4

        ; Allocate object node cache
        move.w  MapMetadataMap_maxObjectNodesInView(a4), d0
        mulu    #MapObjectGroupNode_Size, d0
        jsr     MemoryAllocate
        move.w  a0, mapNodeCache

        ;-------------------------------------------------
        ; Initialize all MapObjectGroupContainer's
        ; ----------------

        movea.l MapMetadataMap_objectGroupContainersBaseAddress(a4), a5         ; a5 = MapObjectGroupContainer base address
        movea.l a5, a6
        PUSHL   a5                                                              ; Store MapObjectGroupContainer's base address on the stack
        adda.w  #-32768, a5                                                     ; MapMetadataMap.objectGroupContainersBaseAddress is stored adjusted for 64k addressing using signed values, revert this here as we are using direct addressing instead of indexed
        move.w  MapMetadataMap_objectGroupContainerCount(a4), d0
        subq.w  #1, d0
    .objectContainerLoop:

            ; Calculate parent container state address
            moveq   #0, d1
            tst.b   MapObjectGroupContainer_flagNumber(a5)
            beq.s   .noParent

                move.w  MapObjectGroupContainer_parentOffset(a5), d1
                move.w  MapObjectGroupContainer_stateOffset(a6, d1), d1         ; d1 = this.parent.stateOffset
                add.w   a3, d1                                                  ; d1 = this.parent state address
        .noParent:

            ; Init state for MapObjectGroupContainer
            move.w  MapObjectGroupContainer_stateOffset(a5), d2
            ; Reset group state links (activeObjectsHead/inactiveObjectsHead)
            clr.l   MapObjectGroupContainerState_activeObjectsHead(a3, d2)
            ; Set container state's parent address to the container's associated parent container state
            move.w  d1, MapObjectGroupContainerState_parent(a3, d2)      ; Write parent address

            adda.w  #MapObjectGroupContainer_Size, a5

        dbra    d0, .objectContainerLoop

        ;-------------------------------------------------
        ; Initialize all MapObjectGroup's
        ; ----------------

        move.w  MapMetadataMap_objectGroupCount(a4), d7                         ; d7 = Object group counter
        beq     .noObjects

            movea.l MapMetadataMap_objectGroupsBaseAddress(a4), a0              ; a0 = Current group/object ObjectDescriptor
            adda.w  #-32768, a0                                                 ; MapMetadataMap.objectGroupsBaseAddress is stored adjusted for 64k addressing using signed values, revert this here as we are using direct addressing instead of indexed

            subq.w  #1, d7
        .objectGroupLoop:

                ;-------------------------------------------------
                ; Initialize state for the current MapObjectGroup
                ; ----------------

                move.w  MapObjectGroupContainer_stateOffset(a0), d0
                lea     (a3, d0), a2                                            ; a2 = MapObjectGroup's MapObjectGroupContainerState address
                ; Reset group state links (activeObjectsHead/inactiveObjectsHead)
                clr.l   MapObjectGroupContainerState_activeObjectsHead(a2)
                ; Set group state parent address to the groups's associated parent container state
                PEEKL   a4
                adda.w  MapObjectGroupContainer_parentOffset(a0), a4            ; a4 = MapObjectGroupContainer address
                move.w  MapObjectGroupContainer_stateOffset(a4), d6
                lea     (a3, d6), a4                                            ; a4 = MapObjectGroupContainer's MapObjectGroupContainerState address
                move.w  a4, MapObjectGroupContainerState_parent(a2)

                ;-------------------------------------------------
                ; Initialize all object instances in the current MapObjectGroup
                ; ----------------

                move.b  MapObjectGroup_totalObjectCount(a0), d6
                addq.w  #MapObjectGroup_objectDescriptors, a0                   ; a0 = Current MapObjectDescriptor address for current group
                ext.w   d6                                                      ; d6 = Object counter
                beq.s   .emptyGroup

                subq.w  #1, d6
            .objectLoop:

                    btst    #MODF_TRANSFERABLE, MapObjectDescriptor_flags(a0)
                    beq.s   .notTransferable

                        move.w  MapStatefulObjectDescriptor_stateOffset(a0), d1
                        lea     -MapObjectLink_Size(a3, d1), a5                 ; a5 = MapObjectLink address for current transferable object
                        LINKED_LIST_INIT (a5)
                        move.l  a0, MapObjectLink_objectDescriptor(a5)
                        move.w  a2, MapObjectLink_objectGroupState(a5)

                        btst    #MODF_ENABLED, MapObjectDescriptor_flags(a0)
                        beq.s   .notEnabled

                            ; Link enabled
                            lea     MapObjectGroupContainerState_activeObjectsHead(a2), a4 ; a4 = Active transferable object list head
                            bra.s   .linkObject
                    .notEnabled:

                            ; Link disabled
                            lea     MapObjectGroupContainerState_inactiveObjectsHead(a2), a4 ; a4 = Inactive transferable object list head

                    .linkObject:

                    LINKED_LIST_INSERT_AFTER a4, a5, a6

                .notTransferable:

                    ; Call Object.init(MapObjectDescriptor*, ObjectState*, ObjectContainerState*)
                    movea.w MapObjectDescriptor_type(a0), a5
                    movea.l MapObjectType_init(a5), a5
                    move.w  MapStatefulObjectDescriptor_stateOffset(a0), d0     ; d0 = State offset
                    lea     (a3, d0), a1                                        ; a1 = State address
                    jsr     (a5)

                    ; Next object
                    move.b  MapObjectDescriptor_size(a0), d0
                    ext.w   d0
                    adda.w  d0, a0                                              ; a0 = Next MapObjectDescriptor address
                dbra    d6, .objectLoop

            .emptyGroup:

            dbra    d7, .objectGroupLoop
    .noObjects:

        ; Restore stack
        POPL
        rts


;-------------------------------------------------
; Build MapObjectGroupNode hierarchy from the given MapObjectGroup leaf nodes
; ----------------
; Input:
; - a0: Address of null terminated array of MapObjectGroup pointers (leaf nodes)
; Output:
; - a0: Address of the root MapObjectGroupNode instance or NULL of no leaf nodes are specified
; Uses: d4-d7/a0-a6
MapBuildObjectGroupHierarchy:

        MAP_GET_METADATA_MAP a6

        ; Array of allocated MapObjectGroupNode pointers indexed by flagNumber
        move.w  MapMetadataMap_objectContainerFlagCount(a6), d4
        movea.l sp, a5
        add.w   d4, d4
        suba.w  d4, sp                                                          ; sp/a7 = MapObjectGroupNode pointer array
        move.w  a5, -(sp)                                                       ; Store previous stack value

        move.l  MapMetadataMap_objectGroupContainersBaseAddress(a6), a6         ; a6 = MapObjectGroupContainer map base address
        move.w  mapNodeCache, a5                                                ; a5 = currently allocated MapObjectGroupNode

        moveq   #0, d5                                                          ; d5 = #0

        ; Write NULL as the default value for the root node
        move.w  d5, SIZE_WORD(sp)

        moveq   #0, d7                                                          ; d7 = bitset indicating currently allocated MapObjectGroupContainer MapObjectGroupNode's
    .leafNodeLoop:
        move.l  (a0)+, d4
        beq.s   .done

            movea.l d4, a4                                                      ; a4 = current MapObjectGroupContainer

            ; Allocate leaf node
            movea.l a5, a1                                                      ; a1 = MapObjectGroupNode
            adda.w  #MapObjectGroupNode_Size, a5                                ; a5 = next node allocation pointer

            ; Init node
            move.l  d5, MapObjectGroupNode_nextSibling(a1)
            move.l  a4, MapObjectGroupNode_group(a1)

            ; Allocate MapObjectGroupNode branch
        .findRootLoop:

                ; Get or allocate MapObjectGroupNode for parent
                move.w  MapObjectGroupContainer_parentOffset(a4), d4
                lea     (a6, d4), a3                                            ; a3 = address of parent MapObjectGroupContainer
                move.b  MapObjectGroupContainer_flagNumber(a3), d6              ; d6 = MapObjectGroupContainer.flagNumber
                ext.w   d6
                bset    d6, d7
                beq.s   .allocateNode
                    ; Node has been allocated retreive from cache
                    add.w   d6, d6
                    movea.w SIZE_WORD(sp, d6), a2                               ; a2 = MapObjectGroupNode

                    move.w  d5, d6                                              ; Mark as done. If allocated it means the whole branch is already allocated.
                    bra.s   .nodeReady
            .allocateNode:
                    ; Allocate new node
                    movea.l a5, a2                                              ; a2 = MapObjectGroupNode
                    adda.w  #MapObjectGroupNode_Size, a5                        ; a5 = next node allocation pointer

                    ; Store node pointer in cache
                    add.w   d6, d6
                    move.w  a2, SIZE_WORD(sp, d6)

                    ; Init node
                    move.l  d5, MapObjectGroupNode_nextSibling(a2)
                    move.l  a3, MapObjectGroupNode_group(a2)
            .nodeReady:

                ; a2 = parent node
                ; a1 = child node

                move.w  MapObjectGroupNode_firstChild(a2), MapObjectGroupNode_nextSibling(a1)
                move.w  a1, MapObjectGroupNode_firstChild(a2)

                ; Is the branch completed, then move on to the next leaf node
                tst.b   d6
                beq.s   .leafNodeLoop

                ; Next parent node
                movea.l a2, a1
                movea.l a3, a4
                bra.s   .findRootLoop
    .done:

        ; Retreive the root node address
        movea.w  SIZE_WORD(sp), a0

        ; Restore stack
        movea.w (sp), sp
        rts


;-------------------------------------------------
; Update all objects in the specified tree depth first.
; Limits collision checks so that only objects in the same branch can collide with each other.
; ----------------
; Input:
; - a0: Address of the root MapObjectGroupNode
; Uses: d0-d7/a0-a6
MapUpdateObjects:
        ; Check if root node available
        move.w  a0, d0
        bne.s   .rootNodeAvailable
            rts
    .rootNodeAvailable:

        MAP_GET_STATE a3
        movea.l a0, a2

        ; RootNode.parent = NULL
        PUSHW   #NULL

        ; Create collision snapshot of caller state
        jsr     CollisionCreateSnapshotBefore
        PUSHW   a0

    .processNode:

        ; Process transferable objects
        movea.l MapObjectGroupNode_group(a2), a4                                ; a4 = MapObjectGroupContainer address
        move.w  MapObjectGroupContainer_stateOffset(a4), d0
        move.w  MapObjectGroupContainerState_activeObjectsHead(a3, d0), d0      ; d0 = MapObjectGroupContainerState.activeObjectsHead
        beq.s   .noTransferableObjects

        .transferableObjectLoop:
            movea.w d0, a5                                                      ; a5 = address of transferable object's MapObjectLink
            move.l  MapObjectLink_objectDescriptor(a5), a0                      ; a0 = MapStatefulObjectDescriptor address
            move.w  MapStatefulObjectDescriptor_stateOffset(a0), d0
            lea     (a3, d0), a1                                                ; a1 = ObjectState address (undefined if not based on MapStatefulObjectDescriptor)

            ; Call Object.update(MapObjectDescriptor*, ObjectState*)
            movea.w MapObjectDescriptor_type(a0), a6
            movea.l MapObjectType_update(a6), a6
            jsr     (a6)

            ; Process next transferable object
            move.w  LinkedList_next(a5), d0
            bne     .transferableObjectLoop

    .noTransferableObjects:

        ; Process non transferables if leaf node (= MapObjectGroup)
        tst.w   MapObjectGroupNode_firstChild(a2)
        bne.s   .branchNode

            move.b  MapObjectGroup_objectCount(a4), d7
            beq.s   .noObjects
                addq.w  #MapObjectGroup_objectDescriptors, a4                   ; a4 = Current non transferable object descriptor

                ext.w   d7
                subq.w  #1, d7
            .objectLoop:

                ; Call Object.update(MapObjectDescriptor*, ObjectState*)
                movea.l a4, a0                                                  ; a0 = Current object descriptor
                move.w  MapStatefulObjectDescriptor_stateOffset(a4), d0
                lea     (a3, d0), a1                                            ; a1 = ObjectState address (undefined if not based on MapStatefulObjectDescriptor)
                movea.w MapObjectDescriptor_type(a0), a6
                movea.l MapObjectType_update(a6), a6
                jsr     (a6)

                ; Process next object
                move.b  MapObjectDescriptor_size(a4), d0
                ext.w   d0
                adda.w  d0, a4                                                  ; a4 = Next MapObjectDescriptor address

                dbra d7, .objectLoop

        .noObjects:

    .branchNode:

        ; Process children
        move.w  MapObjectGroupNode_firstChild(a2), d0
        beq.s   .noChildren

            ; Push parent node onto the stack and load child node into a2
            PUSHW   a2
            movea.w d0, a2

            ; Create collision snapshot of parent state
            jsr     CollisionCreateSnapshotAfter
            PUSHW   a0

            ; Process child node
            bra.s   .processNode
    .noChildren:

        ; Process siblings
    .checkSibling:

        ; Restore collision snapshot
        PEEKW   a0
        jsr     CollisionRestoreSnapshot

        ; Load and process next sibling
        move.w  MapObjectGroupNode_nextSibling(a2), d0
        beq.s   .noSibling
            movea.w d0, a2
            bra.s   .processNode
    .noSibling:

        ; Delete collision snapshot
        POPW

        ; Load parent node
        POPW    d0
        movea.w d0, a2
        bne.s   .checkSibling
        rts


;-------------------------------------------------
; State change handler for: MAP_STATE_CHANGE_OBJECT_ATTACH
; ----------------
; Input:
; - a6: Address of the state change parameter stack
; Uses:
_MapStateChangeAttachTransferableObject:
_LOAD_MAP_METADATA Macro x, y
        MAP_GET_METADATA_MAP a4                                                 ; a4 = meta data map address
        lsr.w   #1, \x
        andi.w  #~3, \x
        lsr.w   #3, \y
        add.w   \y, \y
        add.w   \x, \y
        move.w  MapMetadataMap_rowOffsetTable(a4, \y), \y
        movea.l MapMetadataMap_metadataContainersTableAddress(a4), a1
        movea.l (a1, \y), a1                                                    ; a1 = container address
    Endm

        ; Read parameters
        move.w  -(a6), a0       ; ObjectState
        move.w  -(a6), d0       ; x position
        move.w  -(a6), d1       ; y position

        ; Convert pixel coordinates to chunk coordinates
        lsr.w   #7, d0
        lsr.w   #7, d1

        ; Read chunk ref
        MAP_GET_FOREGROUND_MAP a2                                               ; a2 = foreground map
        move.w  d1, d2
        add.w   d1, d2                                                          ; d1 = map row offset table offset
        move.w  Map_rowOffsetTable(a2, d2), d2
        add.w   d0, d2
        add.w   d0, d2                                                          ; d2 = map chunk offset
        movea.l Map_dataAddress(a2), a3                                         ; a3 = map data
        move.w  (a3, d2), d3                                                    ; d3 = chunk ref

        If (MAP_OVERLAY_ENABLE)
            ; Check overlay
            btst    #CHUNK_REF_OVERLAY, d3
            beq.s   .noOverlay

                ; Check if overlay state enabled
                MAP_TEST_STATE_FLAG MAP_STATE_OVERLAY
                beq.s   .noOverlay

                    move.w  d0, d2
                    move.w  d1, d3

                    _LOAD_MAP_METADATA d2, d3

                    move.w  MapMetadataContainer_overlayOffset(a1), d2
                    lea     (a1, d2), a2                                        ; a2 = MapOverlay address

                    andi.w  #7, d1
                    move.b  MapOverlay_rowOffsetTable(a2, d1), d1
                    ext.w   d1
                    andi.w  #7, d0
                    add.w   d0, d1
                    add.w   d0, d1

                    move.w  MapOverlay_chunkReferences(a2, d1), d3
                    andi.w  #CHUNK_REF_OBJECT_GROUP_IDX_MASK, d3                ; d3 = chunk object group id
                    bne.s   .objectGroupFoundOverlay
                        DEBUG_MSG   'MAP_STATE_CHANGE_OBJECT_ATTACH: No object group found (overlay)'
                        rts
        .noOverlay:
        EndIf

        andi.w  #CHUNK_REF_OBJECT_GROUP_IDX_MASK, d3                            ; d3 = chunk object group id
        bne.s   .objectGroupFound
            DEBUG_MSG   'MAP_STATE_CHANGE_OBJECT_ATTACH: No object group found'
            rts

    .objectGroupFound:

        _LOAD_MAP_METADATA d0, d1

    .objectGroupFoundOverlay:

        rol.w   #4, d3                                                          ; d3 = container local group offset
        subq.w  #2, d3

        ; Get MapObjectGroup offset
        adda.w  MapMetadataContainer_objectGroupOffsetTableOffset(a1), a1       ; a1 = object group offset table address
        move.w  (a1, d3), d0                                                    ; d0 = object group offset

        ; Update MapObjectLink
        movea.l MapMetadataMap_objectGroupsBaseAddress(a4), a3
        move.w  MapObjectGroupContainer_stateOffset(a3, d0), d0                 ; d0 = MapObjectGroup.stateOffset
        MAP_GET_STATE a2
        adda.w  d0, a2                                                          ; a2 = MapObjectGroupState address (= MapObjectGroupState.activeObjectsHead address)
        suba.w  #MapObjectLink_Size, a0                                         ; a0 = MapObjectLink address
        move.w  a2, MapObjectLink_objectGroupState(a0)

        LINKED_LIST_REMOVE a0, a3
        LINKED_LIST_INSERT_AFTER a2, a0, a3
        rts

    Purge _LOAD_MAP_METADATA


;-------------------------------------------------
; State change handler for: MAP_STATE_CHANGE_OBJECT_ASCENT
; ----------------
; Input:
; - a6: Address of the state change parameter stack
; Uses:
_MapStateChangeAscendTransferableObject:
        move.w  -(a6), a0       ; ObjectState

        lea     -MapObjectLink_Size(a0), a1                                     ; a1 = MapObjectLink address
        movea.w MapObjectLink_objectGroupState(a1), a2                          ; a2 = MapObjectGroupContainerState address
        move.w  MapObjectGroupContainerState_parent(a2), d0                     ; d0 = MapObjectGroupContainerState.parent.activeObjectsHead address

        ; Check if parent available
        beq.s .noParent

            movea.w d0, a2                                                      ; a2 = MapObjectGroupContainerState.parent.activeObjectsHead address

            LINKED_LIST_REMOVE a1, a3
            LINKED_LIST_INSERT_AFTER a2, a1, a3

    .noParent:
        rts


;-------------------------------------------------
; State change handler for: MAP_STATE_CHANGE_OBJECT_ACTIVATE
; ----------------
; Input:
; - a6: Address of the state change parameter stack
; Uses: a1-a3
_MapStateChangeActivateTransferableObject:
        move.w  -(a6), a0       ; ObjectState

        lea     -MapObjectLink_Size(a0), a1                                     ; a1 = MapObjectLink address
        movea.w MapObjectLink_objectGroupState(a1), a2                          ; a2 = MapObjectGroupContainerState.activeObjectsHead address

        LINKED_LIST_REMOVE a1, a3
        LINKED_LIST_INSERT_AFTER a2, a1, a3
        rts


;-------------------------------------------------
; State change handler for: MAP_STATE_CHANGE_OBJECT_DEACTIVATE
; ----------------
; Input:
; - a6: Address of the state change parameter stack
; Uses: a1-a3
_MapStateChangeDeactivateTransferableObject:
        move.w  -(a6), a0       ; ObjectState

        lea     -MapObjectLink_Size(a0), a1                                     ; a1 = MapObjectLink address
        movea.w MapObjectLink_objectGroupState(a1), a2
        addq.w  #MapObjectGroupContainerState_inactiveObjectsHead, a2           ; a2 = MapObjectGroupContainerState.inactiveObjectsHead address

        LINKED_LIST_REMOVE a1, a3
        LINKED_LIST_INSERT_AFTER a2, a1, a3
        rts


    ; Cleanup
    Purge _RUN_OBJECT_TYPE_RESOURCE_ROUTINE
