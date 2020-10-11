;------------------------------------------------------------------------------------------
; Constants support macros
;------------------------------------------------------------------------------------------

BIT_CONST Macro bitNumber
\0          Equ      \bitNumber
\0\_MASK    Equ     (1 << \bitNumber)
    Endm


BIT_MASK  Macro bitNumber, numberOfBits
\0\_SHIFT   Equ     \bitNumber
\0\_MASK    Equ     (((1 << \numberOfBits) - 1) << bitNumber)
    Endm
