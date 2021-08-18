;------------------------------------------------------------------------------------------
; Object stuff
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Object structures
; ----------------
    DEFINE_STRUCT ObjectSpawnData
        STRUCT_MEMBER.w osdTypeOffset       ; Offset into global ObjectTypeTableBase
        STRUCT_MEMBER.w osdX                ; X position
        STRUCT_MEMBER.w osdY                ; Y position
    DEFINE_STRUCT_END

    DEFINE_STRUCT ObjectState
    DEFINE_STRUCT_END

    DEFINE_STRUCT ObjectType
        STRUCT_MEMBER.w otStateSize
        STRUCT_MEMBER.l otInit              ; otInit(ObjectSpawnData*, ObjectState*) must preserve d6-d7/a0-a2
        STRUCT_MEMBER.l otUpdate            ; otUpdate(ObjectSpawnData*, ObjectState*, ObjectTypeTableBase*) must preserve d6-d7/a0-a4
    DEFINE_STRUCT_END


;-------------------------------------------------
; ObjectType table base
; ----------------
    SECTION_START S_OBJECT_TYPE
        ObjectTypeTableBase:
    SECTION_END


;-------------------------------------------------
; Get address of the object type table base
; ----------------
OBJECT_TYPE_TABLE_GET Macro target
        lea ObjectTypeTableBase, \target
    Endm


;-------------------------------------------------
; Start creation of an ObjectType struct relative to ObjectTypeTableBase
; Creates the following symbols:
; - [name]ObjectTypeSize (constant)
; - [name]ObjectType (label)
; - [name]ObjectTypeOffset (constant) Relative address to ObjectTypeTableBase
; ----------------
; Input:
; - name: type name
; - stateName: name of the struct holding the runtime state
DEFINE_OBJECT_TYPE Macro name, stateName
        If (narg=2)
\name\ObjectTypeSize Equ \stateName\_Size
        Else
\name\ObjectTypeSize Equ 0
        EndIf
        SECTION_START S_OBJECT_TYPE
            \name\ObjectType:
\name\ObjectTypeOffset Equ (\name\ObjectType - ObjectTypeTableBase)
                dc.w \name\ObjectTypeSize
    Endm


;-------------------------------------------------
; End creation of an ObjectType struct relative to ObjectTypeTableBase
; ----------------
DEFINE_OBJECT_TYPE_END Macro
        SECTION_END
    Endm
