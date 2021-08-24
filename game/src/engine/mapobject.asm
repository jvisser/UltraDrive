;------------------------------------------------------------------------------------------
; Map object handling
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map object descriptor flags
; ----------------
    BIT_CONST.MODF_ENABLED       0
    BIT_CONST.MODF_ACTIVE        1
    BIT_CONST.MODF_TRANSFERABLE  2
    BIT_CONST.MODF_HFLIP         6
    BIT_CONST.MODF_VFLIP         7


;-------------------------------------------------
; Map object structures
; ----------------
    DEFINE_STRUCT MapObjectDescriptor, EXTENDS, ObjectDescriptor
        STRUCT_MEMBER.b odSize                                  ; Size of the descriptor in bytes
        STRUCT_MEMBER.b odFlags
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapStatefulObjectDescriptor, EXTENDS, MapObjectDescriptor
        STRUCT_MEMBER.w odStateOffset                           ; Offset into the maps state area
    DEFINE_STRUCT_END

    ; Appended after the object descriptor if the object type is marked as positional (in the map editor)
    DEFINE_STRUCT MapObjectPosition
        STRUCT_MEMBER.w opX                                     ; X position
        STRUCT_MEMBER.w opY                                     ; Y position
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectLink, EXTENDS, LinkedList
        STRUCT_MEMBER.l mapmotObjectDescriptorAddress           ; Address of the linked objects ObjectDescriptor
        STRUCT_MEMBER.w mapmotObjectGroupStateAddress           ; Address of the MapObjectGroupState state this link is part of
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroupState
        STRUCT_MEMBER.w mapogsActiveObjectsHead                 ; LinkedList.next ptr
        STRUCT_MEMBER.w mapogsInactiveObjectsHead               ; LinkedList.next ptr
    DEFINE_STRUCT_END


;-------------------------------------------------
; Map object state
; ----------------
    DEFINE_VAR FAST
        VAR.w               mapStateAddress
        VAR.w               mapActiveObjectGroupCount
        VAR.w               mapActiveObjectGroupSubChunkId
        VAR.l               mapActiveObjectGroups, 12
    DEFINE_VAR_END


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
    bra     _MapUpdateActiveObjectGroups


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
        bne     .updateActiveObjectGroups
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
        add.w   d3, d2                                          ; d2 = number of columns - 1

        ; Get number of rows in view
        moveq   #2, d3
        move.w  d1, d4
        andi.w  #$0060, d4
        seq     d4
        ext.w   d4
        add.w   d4, d3                                          ; d3 = number of rows - 1

        ; Convert pixel coordinates to chunk coordinates
        lsr.w   #7, d0                                          ; d0 = horizontal chunk coordinate
        lsr.w   #7, d1                                          ; d1 = vertical chunk coordinate

        ; Get pointers
        MAP_GET a0
        movea.l mapObjectGroupMapAddress(a0), a1                ; a1 = mapObjectGroupMapAddress
        movea.l mapogmContainersTableAddress(a1), a2            ; a2 = mapogmContainersTableAddress
        movea.l mapogmContainersBaseAddress(a1), a3             ; a3 = mapogmContainersBaseAddress
        movea.l mapogmGroupsBaseAddress(a1), a4                 ; a4 = mapogmGroupsBaseAddress
        lea     mapActiveObjectGroups, a5                       ; a5 = mapActiveObjectGroups
        movea.l mapForegroundAddress(a0), a0
        move.w  mapStride(a0), d4
        subq.w  #SIZE_WORD, d4
        sub.w   d2, d4
        sub.w   d2, d4                                          ; d4 map stride - number of columns in view
        move.w  d1, d5
        add.w   d5, d5
        move.w  mapRowOffsetTable(a0, d5), d5                   ; d5 = map row offset of top visible row
        movea.l mapDataAddress(a0), a0
        adda.w  d5, a0
        move.w  d0, d6
        add.w   d6, d6
        adda.w  d6, a0                                          ; a0 = address of top left coordinate of first chunk in viewport

        moveq   #0, d6                                          ; d6 = accumulated group flags
    .rowLoop:

        swap    d4
        move.w  d2, d4                                          ; d4 = number of columns - 1
        move.w  d0, d5                                          ; d5 = horizontal chunk coordinate
        .colLoop:

            ; Load object container address
            move.w  d1, d7
            lsr.w   #3, d7
            add.w   d7, d7
            move.w  mapogmRowOffsetTable(a1, d7), a6            ; a6 = container table vertical offset
            move.w  d5, d7
            lsr.w   #3, d7
            add.w   d7, d7
            add.w   a6, d7                                      ; d7 = container offset
            move.w  (a2, d7), d7                                ; d7 = mapogmContainersTableAddress[d7] (= container offset into mapogmContainersBaseAddress)
            lea     (a3, d7), a6                                ; a6 = mapogmContainersBaseAddress[d7] (= container address)

            ; Load object group from container
            move.w  (a0)+, d7                                   ; d7 = chunk ref
            rol.w   #3, d7
            andi.w  #7, d7                                      ; d7 = container group id
            beq     .emptyObjectGroup

                subq.w  #1, d7                                  ; d7 = container group index
                add.w   d7, d7
                move.w  (a6, d7), d7                            ; d7 = object group offset
                lea     (a4, d7), a6                            ; a6 = object group address

                ; Check if new group
                move.b  mapogFlagNumber(a6), d7
                bset    d7, d6
                bne     .objectGroupAlreadyActive

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

        ; Allocate object state area and store ptr
        MAP_GET a4
        move.w  mapStateSize(a4), d0
        jsr     MemoryAllocate
        move.w  a0, mapStateAddress

        ; Init addresses and loop counters
        movea.l a0, a3                                          ; a3 = Map state base
        OBJECT_TYPE_TABLE_GET a2                                ; a2 = Type table base address
        movea.l mapObjectGroupMapAddress(a4), a4
        movea.l mapogmGroupsBaseAddress(a4), a0                 ; a0 = Current group/object ObjectDescriptor
        move.w  mapogmGroupsCount(a4), d7                       ; d7 = Object group counter
        beq     .noObjects

        ; Loop over all groups and objects and call Object.otInit()
        subq.w  #1, d7
    .objectGroupLoop:

            ; Init group state (reset links)
            move.w  mapogStateOffset(a0), d0
            lea     (a3, d0), a4                                ; a4 = MapObjectGroupState address
            LINKED_LIST_INIT (a4)

            move.b  mapogTotalObjectCount(a0), d6
            ext.w   d6                                          ; d6 = Object counter
            addq.w  #mapogObjectDescriptors, a0                 ; a0 = Current ObjectDescriptor address for current group

            subq.w  #1, d6
        .objectLoop:

                move.l  a7, d0
                btst    #MODF_TRANSFERABLE, odFlags(a0)
                beq     .notTransferable

                    move.w  odStateOffset(a0), d1
                    lea     -MapObjectLink_Size(a3, d1), a5      ; a5 = MapObjectLink address for current transferable object
                    LINKED_LIST_INIT (a5)
                    move.l  a0, mapmotObjectDescriptorAddress(a5)
                    move.w  a4, mapmotObjectGroupStateAddress(a5)

                    btst    #MODF_ENABLED, odFlags(a0)
                    beq     .notEnabled

                        ; Link enabled
                        lea mapogsActiveObjectsHead(a4), a7     ; a7 = Active transferable object list head
                        bra     .linkObject
                .notEnabled:

                        ; Link disabled
                        lea mapogsInactiveObjectsHead(a4), a7   ; a7 = Inactive transferable object list head

                .linkObject:

                LINKED_LIST_INSERT_AFTER a7, a5, a6

                move.l  d0, a7
            .notTransferable:

                ; Call Object.otInit(ObjectDescriptor*, ObjectState*)
                move.w  odTypeOffset(a0), d0                    ; d7 = Type offset
                movea.l otInit(a2, d0), a5
                move.w  odStateOffset(a0), d0                   ; d7 = State offset
                lea     (a3, d0), a1                            ; a1 = State address
                jsr     (a5)

                ; Next object
                move.b  odSize(a0), d0
                ext.w   d0
                adda.w  d0, a0                                  ; a0 = Next ObjectDescriptor address
            dbra    d6, .objectLoop
        dbra    d7, .objectGroupLoop
    .noObjects:
        rts


;-------------------------------------------------
; Update all currently active objects
; ----------------
; Uses: d0-d7/a0-a6
MapUpdateObjects:
        move.w  mapActiveObjectGroupCount, d7
        bne     .activeGroups
            rts

    .activeGroups:

        ; Load addresses
        OBJECT_TYPE_TABLE_GET a2                                ; a2 = Type table base address
        lea     mapActiveObjectGroups, a3
        movea.w mapStateAddress, a4

        subq.w  #1, d7
    .activeGroupLoop:

            movea.l (a3), a5                                    ; a5 = Current active group

            move.w  mapogStateOffset(a5), d0
            move.w  mapogsActiveObjectsHead(a4, d0), d0         ; d0 = address of transferable object's MapObjectLink
            beq     .noTransferableObjects

        .transferableObjectLoop:
                movea.w d0, a6                                  ; a6 = address of transferable object's MapObjectLink
                move.l  mapmotObjectDescriptorAddress(a6), a0   ; a0 = MapStatefulObjectDescriptor address
                move.w  odStateOffset(a0), d0
                lea     (a4, d0), a1                            ; a1 = ObjectState address (undefined if not based on MapStatefulObjectDescriptor)

                ; Call Object.otUpdate(ObjectDescriptor*, ObjectState*)
                move.w  odTypeOffset(a0), d0
                movea.l otUpdate(a2, d0), a5
                jsr     (a5)

                ; Process next transferable object
                move.w  llNext(a6), d0
                bne     .transferableObjectLoop

        .noTransferableObjects:
            movea.l (a3)+, a5                                   ; a5 = Current active group

            move.b  mapogObjectCount(a5), d6
            beq .noObjects
                addq.w  #mapogObjectDescriptors, a5             ; a5 = Current non transferable object descriptor

                ext.w   d6
                subq.w  #1, d6
            .objectLoop:

                ; Call Object.otUpdate(ObjectDescriptor*, ObjectState*)
                movea.l a5, a0                                  ; a0 = Current object descriptor
                move.w  odStateOffset(a5), d0
                lea     (a4, d0), a1                            ; a1 = ObjectState address (undefined if not based on MapStatefulObjectDescriptor)
                move.w  odTypeOffset(a5), d0
                movea.l otUpdate(a2, d0), a6
                jsr     (a6)

                ; Process next object
                move.b  odSize(a5), d0
                ext.w   d0
                adda.w  d0, a5                                  ; a5 = Next ObjectDescriptor address

                dbra d6, .objectLoop

        .noObjects:

        dbra    d7, .activeGroupLoop
        rts
