;------------------------------------------------------------------------------------------
; Random Access Memory (ROM/RAM) functions and variable allocation macros
;------------------------------------------------------------------------------------------

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
                

;-------------------------------------------------
; RAM allocation pointers. Grow upward by the size of each defined variable (Auto align according to OPT ae+).
; ----------------
__FAST_RAM_ALLOCATION_PTR = MEM_RAM_MID     ; Can use absolute short addressing (OPT ow+)
__SLOW_RAM_ALLOCATION_PTR = MEM_RAM_START   ; Can not use absolute short addressing


;-------------------------------------------------
; Start struct type definition
; ----------------
DEFINE_STRUCT Macro name
        Pushp '\name'
        RsReset
    Endm


;-------------------------------------------------
; Define struct type member
; ----------------
STRUCT_MEMBER Macro size, name
\name       Rs.\size 1
\name\_Size Equs '\size'
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
        If ~(strcmp('\allocationType', 'FAST') | strcmp('\allocationType', 'SLOW'))
            Inform 3, 'Invalid allocation type %s. Use either FAST or SLOW', '\allocationType'
        EndIf
        Pushp '\allocationType'
        RsSet __\allocationType\_RAM_ALLOCATION_PTR
    Endm


;-------------------------------------------------
; Allocate memory for struct
; ----------------
; Input:
; - 1: Struct type name
; - 2: Variable name
; - 3; Optional: Number of allocations to make
STRUCT Macro structName, varName
        If def(\varName)
            Inform 3, 'Variable "%s" already defined', '\varName'
        EndIf
        If (narg = 3)
\varName Rs.b (\structName\_Size * \3)
        Else
\varName Rs.b \structName\_Size
        EndIf
    Endm


;-------------------------------------------------
; Allocate memory for variable
; ----------------
; Input:
; - 1: datatype (b/w/l)
; - 2: Variable name
; - 3; Optional: Number of allocations to make
VAR Macro dataType, varName
        If def(\varName)
            Inform 3, 'Variable "%s" already defined', '\varName'
        EndIf
        If (narg = 3)
\varName Rs.\dataType \3
        Else
\varName Rs.\dataType 1
        EndIf
    Endm


;-------------------------------------------------
; Marks the end variable creation block
; ----------------
DEFINE_VAR_END Macro
        Local ALLOCATION_TYPE
        Popp ALLOCATION_TYPE
__\ALLOCATION_TYPE\_RAM_ALLOCATION_PTR = __rs
        If (__FAST_RAM_ALLOCATION_PTR > 0)
            Inform 3, 'Absolute short addressable RAM allocation overflow at $%h', __FAST_RAM_ALLOCATION_PTR
        EndIf
        If (__SLOW_RAM_ALLOCATION_PTR > MEM_RAM_MID)
            Inform 3, 'Absolute long addressable RAM allocation overflow at $%h', __SLOW_RAM_ALLOCATION_PTR
        EndIf
        RsReset
    Endm


;-------------------------------------------------
; Start structure initialization data
; ----------------
INIT_STRUCT Macro structVarName
        SECTION_START S_DATA

        \structVarName\_InitData:
        Pushp '\structVarName'
        RsReset
    Endm


;-------------------------------------------------
; Store initialization data for member and verify struct offset
; ----------------
INIT_STRUCT_MEMBER Macro structMemberName, value
        If (\structMemberName <> __rs)
            Inform 3, 'Struct member data specified at incorrect offset. Expected $%h but got $%h', \structMemberName, __rs
        EndIf
        Local STRUCT_MEMBER_SIZE

STRUCT_MEMBER_SIZE Equs \structMemberName\_Size
        Rs.\STRUCT_MEMBER_SIZE 1
        dc.\STRUCT_MEMBER_SIZE \value
    Endm


;-------------------------------------------------
; End structure initialization data. Creates a subroutine <structName>Init that can be called to copy the struct data to the target address.
; ----------------
INIT_STRUCT_END Macro
        SECTION_END

        Local STRUCT_VAR_NAME
        Popp STRUCT_VAR_NAME

        \STRUCT_VAR_NAME\Init:
            lea \STRUCT_VAR_NAME\_InitData, a0
            lea \STRUCT_VAR_NAME, a1
            move.w #__rs, d0
            jmp MemCopy
    Endm


;-------------------------------------------------
; Memory allocation report
; ----------------
MEMORY_ALLOCATION_REPORT Macro
        Local SHORT_MEM_BYTES, LONG_MEM_BYTES
_SHORT_MEM_BYTES Equ __FAST_RAM_ALLOCATION_PTR - MEM_RAM_MID
_LONG_MEM_BYTES  Equ __SLOW_RAM_ALLOCATION_PTR - MEM_RAM_START
        Inform 0, '-----------------'
        Inform 0, 'Memory allocation'
        Inform 0, '-----------------'
        Inform 0, 'Absolute short addressable allocation $%h-$%h (%d bytes)', MEM_RAM_MID, __FAST_RAM_ALLOCATION_PTR, _SHORT_MEM_BYTES
        Inform 0, 'Absolute long addressable allocation  $%h-$%h (%d bytes)', MEM_RAM_START, __SLOW_RAM_ALLOCATION_PTR, _LONG_MEM_BYTES
        Inform 0, ''
    Endm


;-------------------------------------------------
; Fill RAM with zero's. This resets the stack so can only be called from top level code (SysInit or Main).
; ----------------
; Uses: d0-d1/a0-a1
MemInit:
_CLR_RAM_LOOP_UNROLL Equ 8

        ; Save return address
        move.l (sp), a1

        moveq   #0, d1
        move.l  d1, a0
        move.w  #(MEM_RAM_SIZE_LONG / _CLR_RAM_LOOP_UNROLL) - 1, d0

    .clearLoop:
        Rept _CLR_RAM_LOOP_UNROLL
            move.l  d1, -(a0)
        Endr
        dbra    d0, .clearLoop

        ; Reset stack pointer and return
        movea.l d1, sp
        jmp (a1)


;-------------------------------------------------
; Copy memory from source to destination
; ----------------
; Input:
; - a0: Source address
; - a1: Destination address
; - d0; Length in bytes
; Uses: d0/a0-a1
MemCopy:
        subq.w  #1, d0

    .copyLoop:
        move.b  (a0)+, (a1)+
        dbra    d0, .copyLoop
        rts
