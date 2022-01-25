;------------------------------------------------------------------------------------------
; Random Access Memory (ROM/RAM) constants and variable allocation macros
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_MEMORY_INC))
__SYSTEM_MEMORY_INC Equ 1

    Include './system/include/init.inc'

;-------------------------------------------------
; ROM address ranges
; ----------------
MEM_ROM_START       Equ $00000000
MEM_ROM_END         Equ $003fffff   ; Last addressable byte


;-------------------------------------------------
; RAM address ranges and sizes
; ----------------
MEM_RAM_START       Equ $ffff0000
MEM_RAM_MID         Equ $ffff8000
MEM_RAM_END         Equ $ffffffff   ; Last addressable byte

MEM_RAM_SIZE_BYTE   Equ (MEM_RAM_END - MEM_RAM_START + 1)
MEM_RAM_SIZE_WORD   Equ (MEM_RAM_SIZE_BYTE / SIZE_WORD)
MEM_RAM_SIZE_LONG   Equ (MEM_RAM_SIZE_BYTE / SIZE_LONG)

MEM_RAM_STACK_SIZE  Equ 512


;-------------------------------------------------
; RAM allocation pointers. Grow upward by the size of each defined variable (Auto align according to OPT ae+).
; ----------------
__SHORT_RAM_ALLOCATION_PTR = MEM_RAM_MID     ; Absolute long addressing (OPT ow+)
__LONG_RAM_ALLOCATION_PTR  = MEM_RAM_START   ; Absolute short addressing


;-------------------------------------------------
; Start struct type definition
; ----------------
DEFINE_STRUCT Macro name, base
        Pushp '\name'
        If (narg=2)
            RsSet \base\_Size
        Else
            RsReset
        EndIf
    Endm


;-------------------------------------------------
; Define struct type member
; ----------------
; Input:
; - 0: datatype b/w/l or struct
STRUCT_MEMBER Macro name, elementCount
    Local STRUCT_NAME, MEMBER_NAME
    Popp STRUCT_NAME

MEMBER_NAME Equs '\STRUCT_NAME\_\name'

\MEMBER_NAME\_Struct Equs '\MEMBER_NAME'

    If (strcmp('\0', 'b') | strcmp('\0', 'w') | strcmp('\0', 'l'))
        If (narg=2)
\MEMBER_NAME               Rs.\0 \elementCount
\MEMBER_NAME\_ElementCount Equs '\elementCount'
        Else
\MEMBER_NAME               Rs.\0 1
\MEMBER_NAME\_ElementCount Equs '1'
        EndIf
\MEMBER_NAME\_Size Equs '\0'
    Else
        If (narg=2)
\MEMBER_NAME               Rs.b (\0\_Size * \elementCount)
\MEMBER_NAME\_ElementCount Equs '\0\_Size * \elementCount'
        Else
\MEMBER_NAME               Rs.b \0\_Size
\MEMBER_NAME\_ElementCount Equs '\0\_Size'
        EndIf
\MEMBER_NAME\_Size Equs 'b'
    EndIf
    Pushp '\STRUCT_NAME'
    Endm


;-------------------------------------------------
; End struct type definition. The size of the struct is captured under symbol <structName>_Size
; ----------------
DEFINE_STRUCT_END Macro
        Local STRUCT_NAME
        Popp STRUCT_NAME
\STRUCT_NAME\_Size Equ __rs
    Endm


;-------------------------------------------------
; Start creation of variables
; ----------------
DEFINE_VAR Macro allocationType
        If ~(strcmp('\allocationType', 'SHORT') | strcmp('\allocationType', 'LONG'))
            Inform 3, 'Invalid allocation type \allocationType\. Use either SHORT or LONG'
        EndIf
        Pushp '\allocationType'
        RsSet __\allocationType\_RAM_ALLOCATION_PTR
    Endm


;-------------------------------------------------
; Allocate memory for variable
; ----------------
; Input:
; - 0: datatype (b/w/l) or struct name
; - 1: Variable name
; - 2; Optional: Number of allocations to make
VAR Macro varName
            Local VAR_START, VAR_ADDR, VAR_SIZE
\varName\_Type Equs '\0'
VAR_START = __rs
        If def(\varName)
            Inform 3, 'Variable "\varName\" already defined'
        EndIf
        If (strcmp('\0', 'b') | strcmp('\0', 'w') | strcmp('\0', 'l'))
            If (narg = 2)
\varName Rs.\0 \2
            Else
\varName Rs.\0 1
            EndIf
\varName\_Size Equ (__rs - VAR_START)
        Else
            Rs.w 0  ; Even __rs
            If (narg = 2)
\varName\_Size Equ (\0\_Size * \2)
            Else
\varName\_Size Equ \0\_Size
            EndIf
\varName Rs.b \varName\_Size
        EndIf
        If (def(debug))
VAR_ADDR Equ \varName
VAR_SIZE Equ \varName\_Size
            Inform 0, 'Variable \varName defined: \$VAR_ADDR (size=\#VAR_SIZE)'
        EndIf
    Endm


;-------------------------------------------------
; Marks the end variable creation block
; ----------------
DEFINE_VAR_END Macro
        Local ALLOCATION_TYPE
        Popp  ALLOCATION_TYPE

__\ALLOCATION_TYPE\_RAM_ALLOCATION_PTR = __rs
        If (__SHORT_RAM_ALLOCATION_PTR > 0)
            Inform 3, 'Absolute short addressable RAM allocation overflow at $%h', __SHORT_RAM_ALLOCATION_PTR
        EndIf
        If (__LONG_RAM_ALLOCATION_PTR > MEM_RAM_MID)
            Inform 3, 'Absolute long addressable RAM allocation overflow at $%h', __LONG_RAM_ALLOCATION_PTR
        EndIf
        RsReset
    Endm


;-------------------------------------------------
; Start structure initialization data
; ----------------
INIT_STRUCT Macro structVarName
    Local VAR_TYPE
__FIRST_STRUCT_INIT_MEMBER_OFFSET = -1  ; TODO: Use macro stack
        SECTION_START S_DATA

VAR_TYPE Equs \structVarName\_Type

        \structVarName\_InitData:
        Pushp '\structVarName'
        Pushp '\VAR_TYPE'
        RsReset
    Endm


;-------------------------------------------------
; Store initialization data for member and verify struct offset
; ----------------
; Input:
; - 0: Struct member name
; - 1: Value
INIT_STRUCT_MEMBER Macro value
        Local STRUCT_MEMBER_SIZE, STRUCT_MEMBER_ELEMENT_COUNT, PAD_BYTES, STRUCT_NAME, STRUCT_MEMBER_NAME

        Popp STRUCT_NAME

        ; Record first struct member offset to be initialized. This is the offset the data should be copied to.
        If (__FIRST_STRUCT_INIT_MEMBER_OFFSET = -1)
__FIRST_STRUCT_INIT_MEMBER_OFFSET = \STRUCT_NAME\_\0
            RsSet __FIRST_STRUCT_INIT_MEMBER_OFFSET
        EndIf

        ; Add padding if offsets dont align
        If (\STRUCT_NAME\_\0 > __rs)
PAD_BYTES Equ (\STRUCT_NAME\_\0 - __rs)
            Inform 1, 'Adding %d bytes of padding for struct member \STRUCT_NAME\_\0', PAD_BYTES

            dcb.b PAD_BYTES, $00
            Rs.b  PAD_BYTES
        EndIf

        ; If offset is still not equal to the current offset indicate data alignment error
        If (\STRUCT_NAME\_\0 <> __rs)
            Inform 3, 'Struct member data specified at incorrect offset. Expected $%h but got $%h', \STRUCT_NAME\_\0, __rs
        EndIf

STRUCT_MEMBER_ELEMENT_COUNT Equs \STRUCT_NAME\_\0\_ElementCount
STRUCT_MEMBER_SIZE          Equs \STRUCT_NAME\_\0\_Size

        If (~strcmp('\STRUCT_MEMBER_ELEMENT_COUNT', '1'))
            Inform 3, '\STRUCT_NAME\_\0\: Initialization of array types not supported!'
        EndIf

        Rs.\STRUCT_MEMBER_SIZE \STRUCT_MEMBER_ELEMENT_COUNT
        dc.\STRUCT_MEMBER_SIZE \value

        Pushp '\STRUCT_NAME'
    Endm


;-------------------------------------------------
; End structure initialization data. Creates a subroutine <structName>Init that will be automatically called at startup to initialize the specified struct.
; ----------------
INIT_STRUCT_END Macro
        SECTION_END

        Local STRUCT_VAR_NAME
        Popp  STRUCT_VAR_NAME
        Popp  STRUCT_VAR_NAME

        If (__FIRST_STRUCT_INIT_MEMBER_OFFSET = -1)
            Inform 3, 'Empty struct initialization for \STRUCT_VAR_NAME'
        EndIf

        ;-------------------------------------------------
        ; Create constructor function. Uses: d0/a0-a1
        ; ----------------
        SYS_INIT \STRUCT_VAR_NAME\Init
            lea     \STRUCT_VAR_NAME\_InitData, a0
            lea     \STRUCT_VAR_NAME + __FIRST_STRUCT_INIT_MEMBER_OFFSET, a1
            move.w  #(__rs - __FIRST_STRUCT_INIT_MEMBER_OFFSET), d0
            jmp     MemoryCopy
    Endm


;-------------------------------------------------
; Check for memory allocation overflow OS_KILL (trap 0) if so
; ----------------
    Include './system/include/os.inc'   ; Workaround: include here to prevent circular dep order issues...
__MEMORY_CHECK_OVERFLOW Macro scratch
        If def(debug)
            movea.w memAllocationPointer, \scratch
            cmpa.l  memDMAAllocationPointer, \scratch
            bge.s   .allocOk\@
                OS_KILL 'RAM allocation overflow!'
        .allocOk\@:
        EndIf
    Endm


;-------------------------------------------------
; Allocate memory with a constant size
; ----------------
MEMORY_ALLOCATE Macro bytes, target, scratch
        movea.w  memAllocationPointer, \target
        movea.l \target, \scratch
        adda.w  #(((\bytes) + 1) & $fffe), \scratch
        move.w  \scratch, memAllocationPointer

        __MEMORY_CHECK_OVERFLOW \scratch

    Endm


;-------------------------------------------------
; Memory allocation report
; ----------------
MEMORY_ALLOCATION_REPORT Macro
        Local SHORT_MEM_BYTES, LONG_MEM_BYTES
_SHORT_MEM_BYTES Equ __SHORT_RAM_ALLOCATION_PTR - MEM_RAM_MID
_LONG_MEM_BYTES  Equ __LONG_RAM_ALLOCATION_PTR  - MEM_RAM_START
        Inform 0, '-----------------'
        Inform 0, 'Memory allocation'
        Inform 0, '-----------------'
        Inform 0, 'Absolute short addressable allocation $%h-$%h (%d bytes)', MEM_RAM_MID, __SHORT_RAM_ALLOCATION_PTR, _SHORT_MEM_BYTES
        Inform 0, 'Absolute long addressable allocation  $%h-$%h (%d bytes)', MEM_RAM_START, __LONG_RAM_ALLOCATION_PTR, _LONG_MEM_BYTES
        Inform 0, ''
    Endm

    EndIf
