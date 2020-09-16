;------------------------------------------------------------------------------------------
; System physical memory map and variable allocation macros
;------------------------------------------------------------------------------------------

MEM_ROM_START   equ $00000000
MEM_ROM_END     equ $003fffff
                
MEM_RAM_START   equ $ffff0000
MEM_RAM_MID     equ $ffff8000
MEM_RAM_END     equ $ffffffff
                

; RAM allocation pointers. Grow upward by the size of each defined variable (Auto align according to OPT ae+).
FAST_RAM_ALLOCATION_PTR set MEM_RAM_MID     ; Can use absolute short addressing (OPT ow+)
SLOW_RAM_ALLOCATION_PTR set MEM_RAM_START   ; Can not use absolute short addressing


;-------------------------------------------------
; Start creation of variables in fast/absolute short addressable upper half of RAM
; ----------------
; Parameters: None
DEFINE_FAST_VAR macro 
    rsset FAST_RAM_ALLOCATION_PTR
    endm


;-------------------------------------------------
; Marks the end of fast addressable variable creation block
; ----------------
; Parameters: None
DEFINE_FAST_VAR_END macro
FAST_RAM_ALLOCATION_PTR set __rs
    rsreset
    endm

    
;-------------------------------------------------
; Start creation of variables in slow/absolute long addressable lower half of RAM
; ----------------
; Parameters: None
DEFINE_SLOW_VAR macro 
    rsset SLOW_RAM_ALLOCATION_PTR
    endm


;-------------------------------------------------
; Marks the end of slow addressable variable creation block
; ----------------
; Parameters: None
DEFINE_SLOW_VAR_END macro
SLOW_RAM_ALLOCATION_PTR set __rs
    rsreset
    endm
