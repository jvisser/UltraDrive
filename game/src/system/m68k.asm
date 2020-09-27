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
; Disables interrupt processing
; ----------------
; Uses: sp|a7/sr
M68K_DISABLE_INT Macro
        move sr, -(sp)
        move #M68k_SR_SUPERVISOR | M68k_SR_INTERRUPT_MASK, sr
    Endm


;-------------------------------------------------
; Restore interrupt processing
; ----------------
M68K_ENABLE_INT Macro
        move (sp)+, sr
    Endm


;-------------------------------------------------
; Init 68000 state
; ----------------
M68KInit:
        move #M68k_SR_SUPERVISOR, sr    ; Allow all interrupts by default
        rts
