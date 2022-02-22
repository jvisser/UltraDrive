;------------------------------------------------------------------------------------------
; 16.16 fixed point macros
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_FP16_INC))
__ENGINE_FP16_INC Equ 1

;-------------------------------------------------
; Convert a 16 bit integer to a 16.16 fixed point number
; ----------------
INT_TO_FP16 Macro int
        swap    \int
        clr.w   \int
    Endm


;-------------------------------------------------
; Convert a 16.16 fixed point number to a 16 bit integer (does not round)
; ----------------
FP16_TO_INT Macro int
        swap    \int
    Endm


;-------------------------------------------------
; Multiply a 16 bit unsigned integer with a 16.16 unsigned fixed point number
; ----------------
; Uses: d6 it not specified otherwise
FP16_MUL_UINT Macro multiplicand, multiplierfp16, scratch
            Local __SCRATCH
            If (narg=2)
__SCRATCH Equr d6
            Else
__SCRATCH Equr \scratch
            EndIf
            move.w  \multiplicand, __SCRATCH
            mulu    \multiplierfp16, __SCRATCH
            swap    \multiplierfp16
            mulu    \multiplierfp16, \multiplicand
            swap    \multiplicand
            add.l   __SCRATCH, \multiplicand
        Endm

    EndIf
