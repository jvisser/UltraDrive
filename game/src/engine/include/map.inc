;------------------------------------------------------------------------------------------
; Map type definition and loading
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_MAP_INC))
__ENGINE_MAP_INC Equ 1

    Include './common/include/constants.inc'
    Include './common/include/linkedlist.inc'

    Include './system/include/memory.inc'

    Include './engine/include/object.inc'

;-------------------------------------------------
; Chunk reference structure (16 bit)
; ----------------
    BIT_MASK.CHUNK_REF_INDEX            0,  8
    BIT_CONST.CHUNK_REF_OVERLAY         8                                       ; Does the chunk have an overlay chunk?
    BIT_CONST.CHUNK_REF_COLLISION       9                                       ; Does the chunk contain any collision data?
    BIT_CONST.CHUNK_REF_EMPTY           10                                      ; Does the chunk contain any graphics data?
    BIT_MASK.CHUNK_REF_ORIENTATION      11, 2
    BIT_CONST.CHUNK_REF_HFLIP           11
    BIT_CONST.CHUNK_REF_VFLIP           12
    BIT_MASK.CHUNK_REF_OBJECT_GROUP_IDX 13, 3                                   ; Index into the local MapMetadataContainer group offset table (used to resolve the associated MapObjectGroup)


;-------------------------------------------------
; Map state flags
; ----------------
    BIT_CONST.MAP_STATE_OVERLAY         0


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
; Map structures
; ----------------
    DEFINE_STRUCT MapDirectory
        STRUCT_MEMBER.w count
        STRUCT_MEMBER.b maps                                                    ; Marker
    DEFINE_STRUCT_END

    ; Map header for a loadable map with references to the background/foreground map's and the used tileset
    DEFINE_STRUCT MapHeader
        STRUCT_MEMBER.l foregroundAddress
        STRUCT_MEMBER.l backgroundAddress
        STRUCT_MEMBER.l tilesetAddress
        STRUCT_MEMBER.w stateSize
        STRUCT_MEMBER.l metadataMapAddress
        STRUCT_MEMBER.l objectTypeTableAddress
        STRUCT_MEMBER.l viewportConfigurationAddress
    DEFINE_STRUCT_END

    ; Map structure containing the chunk references data
    DEFINE_STRUCT Map
        STRUCT_MEMBER.w width
        STRUCT_MEMBER.w stride
        STRUCT_MEMBER.w height
        STRUCT_MEMBER.w widthPatterns
        STRUCT_MEMBER.w heightPatterns
        STRUCT_MEMBER.w widthPixels
        STRUCT_MEMBER.w heightPixels
        STRUCT_MEMBER.l dataAddress                                             ; Uncompressed
        STRUCT_MEMBER.b rowOffsetTable                                          ; Marker
    DEFINE_STRUCT_END

    ; Metadata map per 8x8 chunks or 1024x1024 pixels
    DEFINE_STRUCT MapMetadataMap
        STRUCT_MEMBER.w stride
        STRUCT_MEMBER.w width
        STRUCT_MEMBER.w height
        STRUCT_MEMBER.w objectGroupContainerCount
        STRUCT_MEMBER.w objectGroupCount
        STRUCT_MEMBER.w objectContainerFlagCount
        STRUCT_MEMBER.w maxObjectGroupsInView
        STRUCT_MEMBER.w maxObjectNodesInView
        STRUCT_MEMBER.w metadataContainerCount
        STRUCT_MEMBER.l metadataContainersTableAddress
        STRUCT_MEMBER.l objectGroupsBaseAddress
        STRUCT_MEMBER.l objectGroupContainersBaseAddress
        STRUCT_MEMBER.b rowOffsetTable                                          ; Marker
    DEFINE_STRUCT_END

    ; Chunk overlay data struct for MapMetadataContainer
    DEFINE_STRUCT MapOverlay
        STRUCT_MEMBER.b rowOffsetTable, 8
        STRUCT_MEMBER.w chunkReferences
    DEFINE_STRUCT_END

    ; Meta data container for a single 8x8 chunk part of the map
    DEFINE_STRUCT MapMetadataContainer
        STRUCT_MEMBER.w stateOffset                                             ; Offset into the maps state array
        STRUCT_MEMBER.w objectGroupOffsetTableOffset                            ; Relative offset to object group offset table
        STRUCT_MEMBER.w overlayOffset                                           ; Relative offset to MapOverlay data
    DEFINE_STRUCT_END

    ; Spatial object hierarchy node. Does not contain objects in the map definition but its runtime state (MapObjectGroupContainerState) can contain objects (only objects marked as transferable).
    DEFINE_STRUCT MapObjectGroupContainer
        STRUCT_MEMBER.w stateOffset                                             ; Offset to MapObjectGroupContainerState for MapObjectGroupContainer
        STRUCT_MEMBER.w parentOffset
        ; flagNumber implementation details:
        ; - MapObjectGroupContainer: Unique in the active viewport only for a single map layer (Base or Overlay).
        ; - MapObjectGroup: Unique in the active viewport across all layers (Base and Overlay).
        STRUCT_MEMBER.b flagNumber
    DEFINE_STRUCT_END

    ; Spatial object hierarchy leaf node. Contains the actual map object definitions.
    DEFINE_STRUCT MapObjectGroup, MapObjectGroupContainer
        STRUCT_MEMBER.b objectCount
        STRUCT_MEMBER.b transferableObjectCount
        STRUCT_MEMBER.b totalObjectCount
        STRUCT_MEMBER.b objectDescriptors                                       ; Marker
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Map object structures
    ; ----------------
    DEFINE_STRUCT MapObjectType, ObjectType
        ; Type methods (called once at load time for each object type used in the map)
        STRUCT_MEMBER.l loadResources                                           ; loadResources()
        STRUCT_MEMBER.l releaseResources                                        ; releaseResources()

        ; Instance methods

        ; Must initialize the object instance according to the object descriptor without any side effects
        STRUCT_MEMBER.l init                                                    ; init(MapObjectDescriptor*, ObjectState*, ObjectContainerState*) must preserve d6-d7/a0-a4
        STRUCT_MEMBER.l update                                                  ; update(MapObjectDescriptor*, ObjectState*) must preserve d7/a2-a5
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectDescriptor
        STRUCT_MEMBER.w type                                                    ; Address of object type
        STRUCT_MEMBER.b size                                                    ; Size of the descriptor in bytes
        STRUCT_MEMBER.b flags
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapStatefulObjectDescriptor, MapObjectDescriptor
        STRUCT_MEMBER.w stateOffset                                             ; Offset into the maps state area
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Map runtime structures
    ; ----------------
    DEFINE_STRUCT MapMetadataContainerState
    DEFINE_STRUCT_END

    ; Runtime state for MapObjectGroupContainer. Contains lists for active/inactive transferable objects + parent container state address
    DEFINE_STRUCT MapObjectGroupContainerState
        STRUCT_MEMBER.w activeObjectsHead                                       ; MapObjectLink.next ptr
        STRUCT_MEMBER.w inactiveObjectsHead                                     ; MapObjectLink.next ptr
        STRUCT_MEMBER.w parent                                                  ; MapObjectGroupContainerState state adddress of parent
    DEFINE_STRUCT_END

    ; Transferable object state envelope
    DEFINE_STRUCT MapObjectLink, LinkedList
        STRUCT_MEMBER.l objectDescriptor                                        ; Address of the linked objects MapObjectDescriptor
        STRUCT_MEMBER.w objectGroupState                                        ; Address of the MapObjectGroupContainerState state this link is part of
    DEFINE_STRUCT_END

    ; Represents an isolated set of branches of the maps object group hierarchy. Typically based on whichs branches are visible in the active viewport.
    DEFINE_STRUCT MapObjectGroupNode
        STRUCT_MEMBER.w nextSibling                                             ; MapObjectGroupNode
        STRUCT_MEMBER.w firstChild                                              ; MapObjectGroupNode
        STRUCT_MEMBER.l group                                                   ; MapObjectGroup address for leaf nodes else MapObjectGroupContainer address
    DEFINE_STRUCT_END


;-------------------------------------------------
; Map state change types
; ----------------
; Transfer the object to the active object list of the object group at the specified coordinates. If no MapObjectGroup is found the transfer is canceled.
MAP_STATE_CHANGE_OBJECT_ATTACH              Equ (0 * 6) ; Params: Transferable object state address, x, y
; Transfer the object to its parent group's active object list
MAP_STATE_CHANGE_OBJECT_ASCENT              Equ (1 * 6) ; Params: Transferable object state
; Transfer the object to the active object list of its object group
MAP_STATE_CHANGE_OBJECT_ACTIVATE            Equ (2 * 6) ; Params: Transferable object state
; Transfer the object to the inactive object list of its object group
MAP_STATE_CHANGE_OBJECT_DEACTIVATE          Equ (3 * 6) ; Params: Transferable object state


;-------------------------------------------------
; Queue map state change event
; ----------------
; Input:
; - stateChange: MAP_STATE_CHANGE_* representing the change requested
; - scratch: Address register to use as scratch register
; - param1: Optional state change specific parameter 1 (word)
; - param2: Optional state change specific parameter 2 (word)
; - param3: Optional state change specific parameter 3 (word)
MAP_STATE_CHANGE Macro stateChange, scratch, param1, param2, param3
        ; TODO: Add bounds check
        movea.w mapStateChangeQueueAddress, \scratch
        If (narg>4)
            move.w  \param3, (\scratch)+
        EndIf
        If (narg>3)
            move.w  \param2, (\scratch)+
        EndIf
        If (narg>2)
            move.w  \param1, (\scratch)+
        EndIf
        move.w  #\stateChange, (\scratch)+
        move.w  \scratch, mapStateChangeQueueAddress
        addq.w  #1, mapStateChangeQueueCount
    Endm


;-------------------------------------------------
; Get loaded map address in target
; ----------------
MAP_GET Macros target
        movea.l mapLoadedMap, \target


;-------------------------------------------------
; Get loaded map's MapMetadataMap address in target
; ----------------
MAP_GET_METADATA_MAP Macros target
        movea.l mapMetadataMapAddress, \target


;-------------------------------------------------
; Get loaded map's background map address in target
; ----------------
MAP_GET_BACKGROUND_MAP Macros target
        movea.l mapBackgroundAddress, \target


;-------------------------------------------------
; Get loaded map's foreground map address in target
; ----------------
MAP_GET_FOREGROUND_MAP Macros target
        movea.l mapForegroundAddress, \target


;-------------------------------------------------
; Get loaded map's ObjectTypeTable address in target
; ----------------
MAP_GET_OBJECT_TYPE_TABLE Macros target
        movea.l mapObjectTypeTableAddress, \target


;-------------------------------------------------
; Set map state flag
; ----------------
MAP_SET_STATE_FLAG  Macros flag
        bset    #\flag, mapNewStateFlags


;-------------------------------------------------
; Clear map state flag
; ----------------
MAP_RESET_STATE_FLAG Macros flag
        bclr    #\flag, mapNewStateFlags


;-------------------------------------------------
; Toggle map state flag
; ----------------
MAP_TOGGLE_STATE_FLAG Macros flag
        bchg    #\flag, mapNewStateFlags


;-------------------------------------------------
; Test state flag
; ----------------
MAP_TEST_STATE_FLAG Macros flag
        btst    #\flag, mapStateFlags


;-------------------------------------------------
; Get loaded map's state address in target
; ----------------
MAP_GET_STATE Macros target
        movea.w mapStateAddress, \target

    EndIf
