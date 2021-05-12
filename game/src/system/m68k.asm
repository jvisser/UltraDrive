;------------------------------------------------------------------------------------------
; 68000 specific code/macros
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Native data types
; ----------------
SIZE_BYTE   Equ 1
SIZE_WORD   Equ 2
SIZE_LONG   Equ 4


;-------------------------------------------------
; Status register bits/bitfields
; ----------------
M68k_SR_CARRY           Equ 0x0001
M68k_SR_OVERFLOW        Equ 0x0002
M68k_SR_ZERO            Equ 0x0004
M68k_SR_NEGATIVE        Equ 0x0008
M68k_SR_EXTEND          Equ 0x0010

M68k_SR_INTERRUPT_MASK  Equ 0x0700

M68k_SR_SUPERVISOR      Equ 0x2000
M68k_SR_TRACE_MODE      Equ 0x8000


;-------------------------------------------------
; Save word onto stack
; ----------------
PUSHW Macro value
        move.w \value, -(sp)
    Endm


;-------------------------------------------------
; Pop word from stack
; ----------------
POPW Macro value
        If (narg = 1)
            move.w (sp)+, \value
        Else
            addq.w  #SIZE_WORD, sp
        EndIf
    Endm


;-------------------------------------------------
; Read top word from stack
; ----------------
PEEKW Macro value
        move.w (sp), \value
    Endm


;-------------------------------------------------
; Push long onto stack
; ----------------
PUSHL Macro value
        move.l \value, -(sp)
    Endm


;-------------------------------------------------
; Pop word from stack
; ----------------
POPL Macro value
        If (narg = 1)
            move.l (sp)+, \value
        Else
            addq.l  #SIZE_LONG, sp
        EndIf
    Endm


;-------------------------------------------------
; Read top word from stack
; ----------------
PEEKL Macro value
        move.l (sp), \value
    Endm


;-------------------------------------------------
; Push multiple full registers onto the stack
; ----------------
PUSHM Macro reglist
        movem.l \_, -(sp)
    Endm


;-------------------------------------------------
; Pop multiple full registers from the stack
; ----------------
POPM Macro reglist
        movem.l (sp)+, \_
    Endm


;-------------------------------------------------
; Push full user mode CPU context from exception handler
; ----------------
PUSH_USER_CONTEXT Macro
        PUSHM   d0-d7/a0-a7
    Endm


;-------------------------------------------------
; Pop full user mode XPU context from exception handler
; ----------------
POP_USER_CONTEXT Macro
        POPM   d0-d7/a0-a7
    Endm


;-------------------------------------------------
; Push full CPU context onto the stack for exception handler
; ----------------
PUSH_CONTEXT Macro
        PUSHW   sr
        PUSHM   d0-d7/a0-a7
    Endm


;-------------------------------------------------
; Pop full CPU context from the stack
; ----------------
POP_CONTEXT Macro
        POPM   d0-d7/a0-a7
        POPW   sr
    Endm


;-------------------------------------------------
; Disables interrupt processing
; ----------------
; Uses: sp|a7/sr
M68K_DISABLE_INT Macro
        PUSHW   sr
        move    #M68k_SR_SUPERVISOR | M68k_SR_INTERRUPT_MASK, sr
    Endm


;-------------------------------------------------
; Restore interrupt processing
; ----------------
M68K_ENABLE_INT Macro
        POPW   sr
    Endm


;-------------------------------------------------
; Stop any further processing
; ----------------
M68K_HALT Macro
        stop #M68k_SR_SUPERVISOR | M68k_SR_INTERRUPT_MASK
    Endm


;-------------------------------------------------
; Init 68000 state
; ----------------
M68KInit:
        move #M68k_SR_SUPERVISOR, sr    ; Allow all interrupts by default
        rts
