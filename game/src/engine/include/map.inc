;------------------------------------------------------------------------------------------
; Map type definition and loading
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_MAP_INC))
__ENGINE_MAP_INC Equ 1

    Include './common/include/constants.inc'

    Include './system/include/memory.inc'

    Include './engine/include/linkedlist.inc'
    Include './engine/include/object.inc'

;-------------------------------------------------
; Chunk reference structure (16 bit)
; ----------------
    BIT_MASK.CHUNK_REF_INDEX            0,  8
    BIT_CONST.CHUNK_REF_RESERVED        8
    BIT_CONST.CHUNK_REF_COLLISION       9
    BIT_CONST.CHUNK_REF_EMPTY           10                                          ; Chunk contains no graphic data
    BIT_MASK.CHUNK_REF_ORIENTATION      11, 2
    BIT_CONST.CHUNK_REF_HFLIP           11
    BIT_CONST.CHUNK_REF_VFLIP           12
    BIT_MASK.CHUNK_REF_OBJECT_GROUP_IDX 13, 3


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

    DEFINE_STRUCT MapHeader
        STRUCT_MEMBER.l foregroundAddress
        STRUCT_MEMBER.l backgroundAddress
        STRUCT_MEMBER.l tilesetAddress
        STRUCT_MEMBER.w stateSize
        STRUCT_MEMBER.l metadataMapAddress
        STRUCT_MEMBER.l objectTypeTableAddress
        STRUCT_MEMBER.l viewportConfigurationAddress
    DEFINE_STRUCT_END

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

    ; Map metadata per 8x8 chunks or 1024x1024 pixels
    DEFINE_STRUCT MapMetadataMap
        STRUCT_MEMBER.w stride
        STRUCT_MEMBER.w width
        STRUCT_MEMBER.w height
        STRUCT_MEMBER.w groupCount
        STRUCT_MEMBER.l containersTableAddress
        STRUCT_MEMBER.l objectGroupsBaseAddress
        STRUCT_MEMBER.b rowOffsetTable                                          ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapMetadataContainer
        STRUCT_MEMBER.b objectGroupOffsetTable                                  ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroup
        STRUCT_MEMBER.b flagNumber                                              ; Each object group has a unique flag number in the active viewport
        STRUCT_MEMBER.b objectCount
        STRUCT_MEMBER.b transferableObjectCount
        STRUCT_MEMBER.b totalObjectCount
        STRUCT_MEMBER.w stateOffset                                             ; Offset into the map's allocated state array for this group
        STRUCT_MEMBER.b objectDescriptors                                       ; Marker
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectLink, LinkedList
        STRUCT_MEMBER.l objectDescriptorAddress                                 ; Address of the linked objects MapObjectDescriptor
        STRUCT_MEMBER.w objectGroupStateAddress                                 ; Address of the MapObjectGroupState state this link is part of
    DEFINE_STRUCT_END

    DEFINE_STRUCT MapObjectGroupState
        STRUCT_MEMBER.w activeObjectsHead                                       ; MapObjectLink.next ptr
        STRUCT_MEMBER.w inactiveObjectsHead                                     ; MapObjectLink.next ptr
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Map object structures
    ; ----------------
    DEFINE_STRUCT MapObjectType, ObjectType
        ; Type methods (called once for each object type used in the map)
        STRUCT_MEMBER.l loadResources                                           ; loadResources()
        STRUCT_MEMBER.l releaseResources                                        ; releaseResources()

        ; Instance methods
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


;-------------------------------------------------
; Get loaded map address in target
; ----------------
MAP_GET Macros target
        movea.l mapLoadedMap, \target

    EndIf
