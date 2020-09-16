;------------------------------------------------------------------------------------------
; Program layout
;------------------------------------------------------------------------------------------

    Org 0

    Section S_VECTOR_TABLE
    Section S_HEADER
    Section S_PROGRAM
    Section S_RODATA
    Section S_DEBUG

    Section S_PROGRAM

SECTION_START macro
        Pushs
        Section \1
    endm
    
SECTION_END macro
        Pops
    endm
