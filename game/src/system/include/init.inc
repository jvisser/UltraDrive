;------------------------------------------------------------------------------------------
; Init function/constructor Macros
;------------------------------------------------------------------------------------------

    If (~def(__INIT_INC))
__INIT_INC Equ 1

;-------------------------------------------------
; Prepend to subroutine label to add it to the ctors table to be run at boot time before INIT functions.
; ----------------
SYS_INIT macro function
        SECTION_START S_SYS_CTORS
            dc.l \function
        SECTION_END
        \function:
    Endm

;-------------------------------------------------
; Prepend to subroutine label to add it to the ctors table to be run at boot time.
; ----------------
INIT macro function
        SECTION_START S_CTORS
            dc.l \function
        SECTION_END
        \function:
    Endm

    EndIf
