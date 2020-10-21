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
    Section S_HEADER        ; sega ROM header
    Section S_FASTDATA      ; .fastdata (absolute short addressable)
    Section S_PROGRAM       ; .text
    Section S_RODATA        ; .rodata
    Section S_DATA          ; .data
    Section S_DEBUG         ; .debug

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
        SECTION_INFO S_FASTDATA,        SECTION_BASE
        SECTION_INFO S_PROGRAM,         SECTION_BASE
        SECTION_INFO S_RODATA,          SECTION_BASE
        SECTION_INFO S_DATA,            SECTION_BASE
        SECTION_INFO S_DEBUG,           SECTION_BASE
        Inform 0, ''
    Endm
