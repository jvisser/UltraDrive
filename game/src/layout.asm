;------------------------------------------------------------------------------------------
; Program layout. This file MUST be included before any code/data opcodes
;------------------------------------------------------------------------------------------

    ;-------------------------------------------------
    ; Initial address
    ; ----------------
    Org 0

    ;-------------------------------------------------
    ; Order of sections of the ROM image
    ; ----------------
    Section S_VECTOR_TABLE  ; 68000 vector table
    Section S_HEADER        ; Sega ROM header
    Section S_PROGRAM_SHORT ; Program code (absolute short addressable)
    Section S_RODATA_SHORT  ; Read only data (absolute short addressable)
    Section S_SYS_CTORS     ; Table of system init functions executed directly at boot time
    Section S_CTORS         ; Table of init functions executed directly after system init functions
    Section S_PROGRAM       ; Program code
    Section S_RODATA        ; Read only data
    Section S_DATA          ; Variable initialization data
    Section S_DEBUG         ; Debug strings

    ;-------------------------------------------------
    ; Ctor table base addresses
    ; ----------------
    Section S_SYS_CTORS
        __ctors:

    ;-------------------------------------------------
    ; Default section
    ; ----------------
    Section S_PROGRAM


;-------------------------------------------------
; Start a new section, pushing the current section onto the section stack
; ----------------
; Parameters:
; - section: Section name of section to start
SECTION_START Macro section
        Pushs
        Section \section
    Endm

    
;-------------------------------------------------
; Restore previous section
; ----------------
SECTION_END Macro
        Pops
    Endm


;-------------------------------------------------
; Print single section info
; ----------------
SECTION_INFO Macro name, start
        Inform 0, '%s = $%h-$%h (%d bytes)', '\name',  \start, \start + sectsize(\name) - 1, sectsize(\name)
\start = \start + sectsize(\name)
    Endm


;-------------------------------------------------
; Use once at at end of the assembly file
; Terminates the ctors list
; ----------------
LAYOUT_FINALIZE macro
        SECTION_START S_CTORS
            dc.l 0
        SECTION_END
    Endm


;-------------------------------------------------
; Print section allocation report.
; TODO: Get sect/sectend to work
; ----------------
SECTION_ALLOCATION_REPORT Macro
SECTION_BASE = 0
        Inform 0, '------------------'
        Inform 0, 'Section allocation'
        Inform 0, '------------------'
        SECTION_INFO S_VECTOR_TABLE,    SECTION_BASE
        SECTION_INFO S_HEADER,          SECTION_BASE
        SECTION_INFO S_PROGRAM_SHORT,   SECTION_BASE
        SECTION_INFO S_RODATA_SHORT,    SECTION_BASE
        SECTION_INFO S_SYS_CTORS,       SECTION_BASE
        SECTION_INFO S_CTORS,           SECTION_BASE
        SECTION_INFO S_PROGRAM,         SECTION_BASE
        SECTION_INFO S_RODATA,          SECTION_BASE
        SECTION_INFO S_DATA,            SECTION_BASE
        SECTION_INFO S_DEBUG,           SECTION_BASE
        Inform 0, ''
    Endm
