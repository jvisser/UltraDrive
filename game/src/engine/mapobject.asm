;------------------------------------------------------------------------------------------
; Map object handling
;------------------------------------------------------------------------------------------
; Public API's:
; - MapUpdateObjects
; - MAP_TRANSFERABLE_OBJECT_QUEUE_STATE_CHANGE


;-------------------------------------------------
; Map object constants
; ----------------
MAP_TRANSFERABLE_STATE_CHANGE_QUEUE_ALLOCATION_SIZE Equ (64*SIZE_WORD)

; MAP_TRANSFERABLE_OBJECT_QUEUE_STATE_CHANGE state change parameters
MAP_OBJECT_STATE_CHANGE_ATTACH              Equ (_MapAttachTransferableObject - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_ATTACH_FLOOR        Equ (_MapAttachTransferableObjectFloor - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_ACTIVATE            Equ (_MapActivateTransferableObject - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_DEACTIVATE          Equ (_MapDeactivateTransferableObject - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_ACTIVATE_GLOBAL     Equ (_MapActivateTransferableObjectGlobal - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_DEACTIVATE_GLOBAL   Equ (_MapDeactivateTransferableObjectGlobal - _MapProcessObjectStateChangesBaseOffset)


;-------------------------------------------------
; Map object descriptor flags
; ----------------
    BIT_CONST.MODF_ENABLED       0
    BIT_CONST.MODF_ACTIVE        1
    BIT_CONST.MODF_TRANSFERABLE  2
    BIT_MASK.MODF_ORIENTATION    6, 2
    BIT_CONST.MODF_HFLIP         6
    BIT_CONST.MODF_VFLIP         7


;-------------------------------------------------
; Map object structures
; ----------------
    DEFINE_STRUCT MapObjectType, ObjectType
        STRUCT_MEMBER.l init                                                    ; init(MapObjectDescriptor*, ObjectState*) must preserve d6-d7/a0-a4
        STRUCT_MEMBER.l update                                                  ; update(MapObjectDescriptor*, ObjectState*) must preserve d6-d7/a3-a6
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectDescriptor
        STRUCT_MEMBER.w type                                                    ; Address of object type
        STRUCT_MEMBER.b size                                                    ; Size of the descriptor in bytes
        STRUCT_MEMBER.b flags
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapStatefulObjectDescriptor, MapObjectDescriptor
        STRUCT_MEMBER.w stateOffset                                             ; Offset into the maps state area
    DEFINE_STRUCT_END

    ; Appended after the object descriptor if the object type is marked as positional (in the map editor)
    DEFINE_STRUCT MapObjectPosition
        STRUCT_MEMBER.w x
        STRUCT_MEMBER.w y
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectLink, LinkedList
        STRUCT_MEMBER.l objectDescriptorAddress                                 ; Address of the linked objects MapObjectDescriptor
        STRUCT_MEMBER.w objectGroupStateAddress                                 ; Address of the MapObjectGroupState state this link is part of
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroupState
        STRUCT_MEMBER.w activeObjectsHead                                       ; LinkedList.next ptr
        STRUCT_MEMBER.w inactiveObjectsHead                                     ; LinkedList.next ptr
    DEFINE_STRUCT_END


;-------------------------------------------------
; Map object state
; ----------------
    DEFINE_VAR SHORT
        VAR.w                   mapTransferableStateChangeQueueAddress
        VAR.w                   mapTransferableStateChangeQueueCount
        VAR.w                   mapStateAddress
        VAR.w                   mapActiveObjectGroupCount
        VAR.w                   mapActiveObjectGroupSubChunkId
        VAR.l                   mapActiveObjectGroups, 12
        VAR.MapObjectGroupState mapGlobalObjectGroupState
    DEFINE_VAR_END


;-------------------------------------------------
; Queue object state change.
; This macros is to be used within MapObjectType.update() to prevent concurrent modifications to the object update list while updating;
;
; TODO: Add bounds check
; ----------------
; Input:
; - stateChange: MAP_OBJECT_STATE_CHANGE_* representing the change requested
; - objectStateAddress: Object state address
; - scratch: Address register to use as scratch register
; - param1: Optional state change specific parameter 1
; - param2: Optional state change specific parameter 2
MAP_TRANSFERABLE_OBJECT_QUEUE_STATE_CHANGE Macro stateChange, objectStateAddress, scratch, param1, param2
        movea.w mapTransferableStateChangeQueueAddress, \scratch
        If (narg>4)
            move.w  \param2, (\scratch)+
        EndIf
        If (narg>3)
            move.w  \param1, (\scratch)+
        EndIf
        move.w  \objectStateAddress, (\scratch)+
        move.w  #\stateChange, (\scratch)+
        move.w  \scratch, mapTransferableStateChangeQueueAddress
        addq.w  #1, mapTransferableStateChangeQueueCount
    Endm


;-------------------------------------------------
; Reset group state
; ----------------
_RESET_GROUP_STATE Macro state
        clr.l \state
    Endm


;-------------------------------------------------
; Calculate sub chunk id (as divided in 64x32 parts)
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: result, scratch
; Output:
; - result: sub chunk id
_CALCULATE_SUB_CHUNK_ID Macro result, scratch
        move.w  d0, \result
        move.w  d1, \scratch
        add.w   \result, \result
        andi.w  #$80, \result
        andi.w  #$60, \scratch
        or.w    \scratch, \result
    Endm


;-------------------------------------------------
; Setup initial active groups and sub chunk id based on view position
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
MapInitActiveObjectGroups:
    _CALCULATE_SUB_CHUNK_ID d2, d3

    move.w  d2, mapActiveObjectGroupSubChunkId
    bra.s   _MapUpdateActiveObjectGroups


;-------------------------------------------------
; Update active object groups based on view position. Only updates when new chunks of the map (potentially) become visible.
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
MapUpdateActiveObjectGroups:
        _CALCULATE_SUB_CHUNK_ID d2, d3

        move.w  mapActiveObjectGroupSubChunkId, d3
        eor.w   d2, d3
        bne.s   .updateActiveObjectGroups
            rts

    .updateActiveObjectGroups:
        move.w  d2, mapActiveObjectGroupSubChunkId

        ; NB: Fall through to _MapUpdateActiveObjectGroups


;-------------------------------------------------
; Update active object groups based on view
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
_MapUpdateActiveObjectGroups:
        clr.w   mapActiveObjectGroupCount

        ; Get number of columns in view
        moveq   #3, d2
        btst    #6, d0
        seq     d3
        ext.w   d3
        add.w   d3, d2                                                          ; d2 = number of columns - 1

        ; Get number of rows in view
        moveq   #2, d3
        move.w  d1, d4
        andi.w  #$0060, d4
        seq     d4
        ext.w   d4
        add.w   d4, d3                                                          ; d3 = number of rows - 1

        ; Convert pixel coordinates to chunk coordinates
        lsr.w   #7, d0                                                          ; d0 = horizontal chunk coordinate
        lsr.w   #7, d1                                                          ; d1 = vertical chunk coordinate

        ; Get pointers
        MAP_GET a0
        movea.l MapHeader_objectGroupMapAddress(a0), a1                         ; a1 = objectGroupMapAddress
        movea.l MapObjectGroupMap_containersTableAddress(a1), a2                ; a2 = containersTableAddress
        movea.l MapObjectGroupMap_containersBaseAddress(a1), a3                 ; a3 = containersBaseAddress
        movea.l MapObjectGroupMap_groupsBaseAddress(a1), a4                     ; a4 = groupsBaseAddress
        lea     mapActiveObjectGroups, a5                                       ; a5 = mapActiveObjectGroups
        movea.l MapHeader_foregroundAddress(a0), a0
        move.w  Map_stride(a0), d4
        subq.w  #SIZE_WORD, d4
        sub.w   d2, d4
        sub.w   d2, d4                                                          ; d4 map stride - number of columns in view
        move.w  d1, d5
        add.w   d5, d5
        move.w  Map_rowOffsetTable(a0, d5), d5                                  ; d5 = map row offset of top visible row
        movea.l Map_dataAddress(a0), a0
        adda.w  d5, a0
        move.w  d0, d6
        add.w   d6, d6
        adda.w  d6, a0                                                          ; a0 = address of top left coordinate of first chunk in viewport

        moveq   #0, d6                                                          ; d6 = accumulated group flags
    .rowLoop:

        swap    d4
        move.w  d2, d4                                                          ; d4 = number of columns - 1
        move.w  d0, d5                                                          ; d5 = horizontal chunk coordinate
        .colLoop:

            ; Load object container address
            move.w  d1, d7
            lsr.w   #3, d7
            add.w   d7, d7
            move.w  MapObjectGroupMap_rowOffsetTable(a1, d7), a6                ; a6 = container table vertical offset
            move.w  d5, d7
            lsr.w   #3, d7
            add.w   d7, d7
            add.w   a6, d7                                                      ; d7 = container offset
            move.w  (a2, d7), d7                                                ; d7 = containersTableAddress[d7] (= container offset into containersBaseAddress)
            lea     (a3, d7), a6                                                ; a6 = containersBaseAddress[d7] (= container address)

            ; Load object group from container
            move.w  (a0)+, d7                                                   ; d7 = chunk ref
            andi.w  #CHUNK_REF_OBJECT_GROUP_IDX_MASK, d7
            rol.w   #3, d7                                                      ; d7 = container group id
            beq.s   .emptyObjectGroup

                subq.w  #1, d7                                                  ; d7 = container group index
                add.w   d7, d7
                move.w  (a6, d7), d7                                            ; d7 = object group offset
                lea     (a4, d7), a6                                            ; a6 = object group address

                ; Check if new group
                move.b  MapObjectGroup_flagNumber(a6), d7
                bset    d7, d6
                bne.s   .objectGroupAlreadyActive

                    addq.w #1, mapActiveObjectGroupCount

                    ; Add to active group list
                    move.l  a6, (a5)+

            .objectGroupAlreadyActive:

        .emptyObjectGroup:

            addq.w  #1, d5
            dbra    d4, .colLoop

        swap    d4
        adda.w  d4, a0
        addq.w  #1, d1
        dbra    d3, .rowLoop
        rts


;-------------------------------------------------
; Initialize all objects in the map
; ----------------
; Uses: d0-d7/a0-a6
MapInitObjects:
        ; Allocate object state change queue
        move.w  #MAP_TRANSFERABLE_STATE_CHANGE_QUEUE_ALLOCATION_SIZE, d0
        jsr     MemoryAllocate
        move.w  a0, mapTransferableStateChangeQueueAddress
        clr.w   mapTransferableStateChangeQueueCount

        ; Clear global group state
        _RESET_GROUP_STATE mapGlobalObjectGroupState

        ; Allocate object state area
        MAP_GET a4
        move.w  MapHeader_stateSize(a4), d0
        jsr     MemoryAllocate
        move.w  a0, mapStateAddress

        ; Init addresses and loop counters
        movea.l a0, a3                                                          ; a3 = Map state base
        movea.l MapHeader_objectGroupMapAddress(a4), a4
        movea.l MapObjectGroupMap_groupsBaseAddress(a4), a0                     ; a0 = Current group/object ObjectDescriptor
        move.w  MapObjectGroupMap_groupCount(a4), d7                            ; d7 = Object group counter
        beq     .noObjects

        ; Loop over all groups and objects and call Object.init()
        subq.w  #1, d7
    .objectGroupLoop:

            ; Init group state (reset links)
            move.w  MapObjectGroup_stateOffset(a0), d0
            lea     (a3, d0), a4                                                ; a4 = MapObjectGroupState address
            _RESET_GROUP_STATE (a4)

            move.b  MapObjectGroup_totalObjectCount(a0), d6
            addq.w  #MapObjectGroup_objectDescriptors, a0                       ; a0 = Current MapObjectDescriptor address for current group
            beq.s   .emptyGroup
            ext.w   d6                                                          ; d6 = Object counter

            subq.w  #1, d6
        .objectLoop:

                btst    #MODF_TRANSFERABLE, MapObjectDescriptor_flags(a0)
                beq.s   .notTransferable

                    move.w  MapStatefulObjectDescriptor_stateOffset(a0), d1
                    lea     -MapObjectLink_Size(a3, d1), a5                     ; a5 = MapObjectLink address for current transferable object
                    LINKED_LIST_INIT (a5)
                    move.l  a0, MapObjectLink_objectDescriptorAddress(a5)
                    move.w  a4, MapObjectLink_objectGroupStateAddress(a5)

                    btst    #MODF_ENABLED, MapObjectDescriptor_flags(a0)
                    beq.s   .notEnabled

                        ; Link enabled
                        lea     MapObjectGroupState_activeObjectsHead(a4), a2   ; a2 = Active transferable object list head
                        bra.s   .linkObject
                .notEnabled:

                        ; Link disabled
                        lea MapObjectGroupState_inactiveObjectsHead(a4), a2     ; a2 = Inactive transferable object list head

                .linkObject:

                LINKED_LIST_INSERT_AFTER a2, a5, a6

            .notTransferable:

                ; Call Object.init(MapObjectDescriptor*, ObjectState*)
                movea.w MapObjectDescriptor_type(a0), a5
                movea.l MapObjectType_init(a5), a5
                move.w  MapStatefulObjectDescriptor_stateOffset(a0), d0         ; d0 = State offset
                lea     (a3, d0), a1                                            ; a1 = State address
                jsr     (a5)

                ; Next object
                move.b  MapObjectDescriptor_size(a0), d0
                ext.w   d0
                adda.w  d0, a0                                                  ; a0 = Next MapObjectDescriptor address
            dbra    d6, .objectLoop

        .emptyGroup:

        dbra    d7, .objectGroupLoop
    .noObjects:
        rts


;-------------------------------------------------
; Update all currently active objects.
; Tests collisions against the current/caller collision state.
; Restores the collisions state to that of the caller. This means collision elements added after the call to MapUpdateObjects will not interact with map objects.
; ----------------
; Uses: d0-d7/a0-a6
MapUpdateObjects:

;-------------------------------------------------
; Update transferable object list.
; Input:
; - d0: MapObjectLink address
; ----------------
; Uses: d0/d7/a0/a5-a6
_PROCESS_TRANSFERABLE_OBJECTS Macro
        .transferableObjectLoop\@:
            movea.w d0, a6                                                      ; a6 = address of transferable object's MapObjectLink
            move.l  MapObjectLink_objectDescriptorAddress(a6), a0               ; a0 = MapStatefulObjectDescriptor address
            move.w  MapStatefulObjectDescriptor_stateOffset(a0), d0
            lea     (a4, d0), a1                                                ; a1 = ObjectState address (undefined if not based on MapStatefulObjectDescriptor)

            ; Call Object.update(MapObjectDescriptor*, ObjectState*)
            movea.w MapObjectDescriptor_type(a0), a5
            movea.l MapObjectType_update(a5), a5
            jsr     (a5)

            ; Process next transferable object
            move.w  LinkedList_next(a6), d0
            bne     .transferableObjectLoop\@
    Endm

        ;-------------------------------------------------
        ; Start of MapUpdateObjects
        ; ----------------
        move.w  mapActiveObjectGroupCount, d7
        bne.s   .activeGroups
            rts

    .activeGroups:

        ; Create collision snapshot of caller collision state and store snapshot ptr on the stack
        jsr     CollisionCreateSnapshotBefore
        PUSHW   a0

        ; Load addresses
        lea     mapActiveObjectGroups, a3
        movea.w mapStateAddress, a4

        ; Update global objects
        move.w  mapGlobalObjectGroupState + MapObjectGroupState_activeObjectsHead, d0
        beq.s   .noGlobalTransferableObjects

            _PROCESS_TRANSFERABLE_OBJECTS

    .noGlobalTransferableObjects:

        ; Create collision snapshot containing all global objects and store snapshot pointer on the stack
        PUSHW   a4
        jsr     CollisionCreateSnapshotAfter
        POPW    a4
        PUSHW   a0

        ; Update group local objects
        subq.w  #1, d7
    .activeGroupLoop:

            movea.l (a3), a5                                                    ; a5 = Current active group

            move.w  MapObjectGroup_stateOffset(a5), d0
            move.w  MapObjectGroupState_activeObjectsHead(a4, d0), d0           ; d0 = address of transferable object's MapObjectLink
            beq.s   .noTransferableObjects

                _PROCESS_TRANSFERABLE_OBJECTS

        .noTransferableObjects:
            movea.l (a3)+, a5                                                   ; a5 = Current active group

            move.b  MapObjectGroup_objectCount(a5), d6
            beq.s   .noObjects
                addq.w  #MapObjectGroup_objectDescriptors, a5                   ; a5 = Current non transferable object descriptor

                ext.w   d6
                subq.w  #1, d6
            .objectLoop:

                ; Call Object.update(MapObjectDescriptor*, ObjectState*)
                movea.l a5, a0                                                  ; a0 = Current object descriptor
                move.w  MapStatefulObjectDescriptor_stateOffset(a5), d0
                lea     (a4, d0), a1                                            ; a1 = ObjectState address (undefined if not based on MapStatefulObjectDescriptor)
                movea.w MapObjectDescriptor_type(a0), a6
                movea.l MapObjectType_update(a6), a6
                jsr     (a6)

                ; Process next object
                move.b  MapObjectDescriptor_size(a5), d0
                ext.w   d0
                adda.w  d0, a5                                                  ; a5 = Next MapObjectDescriptor address

                dbra d6, .objectLoop

        .noObjects:

            ; Restore global object collision state for next group to test against
            PEEKW   a0
            jsr     CollisionRestoreSnapshot

        dbra    d7, .activeGroupLoop

        ; Free global object collision state snapshot ptr stack space
        POPW

        ; Restore collision state to caller state
        POPW    a0
        jsr     CollisionRestoreSnapshot

        Purge _PROCESS_TRANSFERABLE_OBJECTS

        ; NB: Fall through to _MapProcessTransferableObjectStateChangeQueue


;-------------------------------------------------
; Process transferable state changes
; ----------------
_MapProcessTransferableObjectStateChangeQueue:
        move.w  mapTransferableStateChangeQueueCount, d4
        beq.s   .noStateChanges
            movea.w  mapTransferableStateChangeQueueAddress, a5
            subq.w  #1, d4
        .stateChangeLoop:
            move.w  -(a5), d0
            movea.w -(a5), a0
            jsr     _MapProcessObjectStateChangesBaseOffset(pc, d0)
            dbra    d4, .stateChangeLoop
        move.w  a5, mapTransferableStateChangeQueueAddress
        clr.w   mapTransferableStateChangeQueueCount
    .noStateChanges:
        rts


_MapProcessObjectStateChangesBaseOffset:


;-------------------------------------------------
; Transfer the object to the active object list of the object group at the specified coordinates. If no group is found the object will be attached to the global group.
; NB: This only works for Objects created from MapObjectDescriptor's flagged as MODF_TRANSFERABLE
;
; TODO: Add support for ceilings (ie search down instead of up)
; ----------------
; Input:
; - d0: x position
; - d1: y position
; - a0: ObjectState address
;
; - Any macro parameter to also check the chunk above for a local group if no local group is found
; Uses: d0-d3/a1-a4
_MAP_ATTACH_OBJECT Macro

        ; Convert pixel coordinates to chunk coordinates
        lsr.w   #7, d0
        lsr.w   #7, d1

        MAP_GET a1
        movea.l MapHeader_foregroundAddress(a1), a2                             ; a2 = foreground map
        movea.l Map_dataAddress(a2), a3                                         ; a3 = map data

        ; Get chunk offset
        add.w   d1, d1                                                          ; d1 = map row offset table offset
        move.w  Map_rowOffsetTable(a2, d1), d2
        add.w   d0, d2
        add.w   d0, d2                                                          ; d2 = row chunk offset

        ; Read chunk ref object group id
        move.w  (a3, d2), d3
        andi.w  #CHUNK_REF_OBJECT_GROUP_IDX_MASK, d3                            ; d3 = chunk object group id
        bne.s   .objectGroupFound\@

            If (narg=1)

                ; No object group found, look one chunk up (slope case)
                tst.w   d1
                beq.s   .linkToGlobalGroup\@

                    sub.w   Map_stride(a2), d2                                  ; d2 = chunk offset
                    move.w  (a3, d2), d3
                    andi.w  #CHUNK_REF_OBJECT_GROUP_IDX_MASK, d3                ; d3 = chunk object group id
                    bne.s   .objectGroupFound\@

            EndIf

        .linkToGlobalGroup\@:
            ; Link to global group
            lea     (mapGlobalObjectGroupState + MapObjectGroupState_activeObjectsHead), a2
            bra.s   .linkObjectToGroup\@

    .objectGroupFound\@:
        rol.w   #4, d3                                                          ; d3 = container local group offset
        subq.w  #2, d3

        movea.l MapHeader_objectGroupMapAddress(a1), a2                         ; a2 = object group map
        movea.l MapObjectGroupMap_containersTableAddress(a2), a1
        movea.l MapObjectGroupMap_containersBaseAddress(a2), a3
        movea.l MapObjectGroupMap_groupsBaseAddress(a2), a4

        ; Get MapObjectGroup
        lsr.w   #3, d0
        add.w   d0, d0
        lsr.w   #4, d1
        add.w   d1, d1
        move.w  MapObjectGroupMap_rowOffsetTable(a2, d1), d1
        add.w   d0, d1                                                          ; d1 = container table offset
        move.w  (a1, d1), d0                                                    ; d0 = container offset
        add.w   d3, d0                                                          ; d0 = container group offset
        move.w  (a3, d0), d0                                                    ; d0 = object group offset
        move.w  MapObjectGroup_stateOffset(a4, d0), d0                          ; d0 = MapObjectGroup.stateOffset

        ; Get group state address
        movea.w mapStateAddress, a2
        lea     MapObjectGroupState_activeObjectsHead(a2, d0), a2               ; a2 = MapObjectGroupState.activeObjectsHead address
    .linkObjectToGroup\@:

        ; Transfer object from its current group to the found group if different (unlink/link)
        suba.w  #MapObjectLink_Size, a0
        cmpa.w  MapObjectLink_objectGroupStateAddress(a0), a2
        beq.s   .sameGroup\@

            move.w  a2, MapObjectLink_objectGroupStateAddress(a0)

            LINKED_LIST_REMOVE a0, a3
            LINKED_LIST_INSERT_AFTER a2, a0, a3

    .sameGroup\@:
    Endm


;-------------------------------------------------
; Transfer the object to the active object list of the object group at the specified coordinates.
; If still no group is found the object will be attached to the global group.
;
; NB: This only works for Objects created from MapObjectDescriptor's flagged as MODF_TRANSFERABLE
; ----------------
; Input:
; - a0: ObjectState address
; - a5: Object transition queue top containing parameters
; Uses: d0-d3/a1-a4
_MapAttachTransferableObject:
        move.w  -(a5), d0       ; x position
        move.w  -(a5), d1       ; y position

        _MAP_ATTACH_OBJECT
        rts


;-------------------------------------------------
; Transfer the object to the active object list of the object group at the specified coordinates.
; If no group is found the chunk above it is checked for a group (floor case)
; If still no group is found the object will be attached to the global group.
;
; NB: This only works for Objects created from MapObjectDescriptor's flagged as MODF_TRANSFERABLE
; ----------------
; Input:
; - a0: ObjectState address
; - a5: Object transition queue top containing parameters
; Uses: d0-d3/a1-a4
_MapAttachTransferableObjectFloor:
        move.w  -(a5), d0       ; x position
        move.w  -(a5), d1       ; y position

        _MAP_ATTACH_OBJECT FLOOR
        rts

    Purge _MAP_ATTACH_OBJECT


;-------------------------------------------------
; Transfer the object to the active object list of the object group (parent)
; ----------------
; Input:
; - a0: ObjectState address
; Uses: a1-a3
_MapActivateTransferableObject:
        lea     -MapObjectLink_Size(a0), a1                                     ; a1 = MapObjectLink address
        movea.w MapObjectLink_objectGroupStateAddress(a1), a2                   ; a2 = MapObjectGroupState_inactiveObjectsHead address

        LINKED_LIST_REMOVE a1, a3
        LINKED_LIST_INSERT_AFTER a2, a1, a3
        rts


;-------------------------------------------------
; Transfer the object to the inactive object list of the object group (parent)
; ----------------
; Input:
; - a0: ObjectState address
; Uses: a1-a3
_MapDeactivateTransferableObject:
        lea     -MapObjectLink_Size(a0), a1                                     ; a1 = MapObjectLink address
        movea.w MapObjectLink_objectGroupStateAddress(a1), a2
        addq.w  #MapObjectGroupState_inactiveObjectsHead, a2                    ; a2 = MapObjectGroupState_inactiveObjectsHead address

        LINKED_LIST_REMOVE a1, a3
        LINKED_LIST_INSERT_AFTER a2, a1, a3
        rts


;-------------------------------------------------
; Transfer the object to the active object list of the global object group
; ----------------
; Input:
; - a0: ObjectState address
; Uses: a1-a3
_MapActivateTransferableObjectGlobal:
        lea     mapGlobalObjectGroupState + MapObjectGroupState_activeObjectsHead, a1
        lea     -MapObjectLink_Size(a0), a2

        LINKED_LIST_REMOVE a2, a3
        LINKED_LIST_INSERT_AFTER a1, a2, a3
        rts


;-------------------------------------------------
; Transfer the object to the inactive object list of the global object group
; ----------------
; Input:
; - a0: ObjectState address
; Uses: a1-a3
_MapDeactivateTransferableObjectGlobal:
        lea     mapGlobalObjectGroupState + MapObjectGroupState_inactiveObjectsHead, a1
        lea     -MapObjectLink_Size(a0), a2

        LINKED_LIST_REMOVE a2, a3
        LINKED_LIST_INSERT_AFTER a1, a2, a3
        rts


    ; Cleanup
    Purge _RESET_GROUP_STATE
    Purge _CALCULATE_SUB_CHUNK_ID
