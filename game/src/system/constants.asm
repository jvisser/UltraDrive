;------------------------------------------------------------------------------------------
; System wide constants and support macros
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Constants
; ----------------
TRUE    Equ -1
FALSE   Equ 0


;-------------------------------------------------
; Macros
; ----------------
BIT_CONST Macro bitNumber
\0          Equ      \bitNumber
\0\_MASK    Equ     (1 << \bitNumber)
    Endm


BIT_MASK  Macro bitNumber, numberOfBits
\0\_SHIFT   Equ     \bitNumber
\0\_MASK    Equ     (((1 << \numberOfBits) - 1) << bitNumber)
    Endm
