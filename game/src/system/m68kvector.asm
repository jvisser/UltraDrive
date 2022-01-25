;------------------------------------------------------------------------------------------
; 68000 vector table
;------------------------------------------------------------------------------------------

DEFAULT_EXCEPTION_HANDLER Macro handler
        If ~def(\handler)
                Inform 0, 'Exception handler "%s" not defined, using default handler', '\handler'
\handler Equ Exception
        EndIf
    Endm


    SECTION_START S_VECTOR_TABLE

    DEFAULT_EXCEPTION_HANDLER ExternalInterruptHandler          ; Controller port pin 6 (Lightgun/serial comms etc)
    DEFAULT_EXCEPTION_HANDLER HBlankInterruptHandler
    DEFAULT_EXCEPTION_HANDLER VBlankInterruptHandler

Vector68k:
    dc.l   $00000000                        ; Initial stack pointer value
    dc.l   Boot                             ; Start of program
    dc.l   Exception                        ; Bus error
    dc.l   Exception                        ; Address error
    dc.l   Exception                        ; Illegal instruction
    dc.l   Exception                        ; Division by zero
    dc.l   Exception                        ; CHK exception
    dc.l   Exception                        ; TRAPV exception
    dc.l   Exception                        ; Privilege violation
    dc.l   Exception                        ; TRACE exception
    dc.l   Exception                        ; Line-A emulator
    dc.l   Exception                        ; Line-F emulator
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Spurious exception
    dc.l   Exception                        ; IRQ level 1
    dc.l   ExternalInterruptHandler         ; IRQ level 2
    dc.l   Exception                        ; IRQ level 3
    dc.l   HBlankInterruptHandler           ; IRQ level 4 (horizontal retrace interrupt)
    dc.l   Exception                        ; IRQ level 5
    dc.l   VBlankInterruptHandler           ; IRQ level 6 (vertical retrace interrupt)
    dc.l   Exception                        ; IRQ level 7
    dc.l   _SIG_OSKill                      ; TRAP #00 exception
    dc.l   Exception                        ; TRAP #01 exception
    dc.l   Exception                        ; TRAP #02 exception
    dc.l   Exception                        ; TRAP #03 exception
    dc.l   Exception                        ; TRAP #04 exception
    dc.l   Exception                        ; TRAP #05 exception
    dc.l   Exception                        ; TRAP #06 exception
    dc.l   Exception                        ; TRAP #07 exception
    dc.l   Exception                        ; TRAP #08 exception
    dc.l   Exception                        ; TRAP #09 exception
    dc.l   Exception                        ; TRAP #10 exception
    dc.l   Exception                        ; TRAP #11 exception
    dc.l   Exception                        ; TRAP #12 exception
    dc.l   Exception                        ; TRAP #13 exception
    dc.l   Exception                        ; TRAP #14 exception
    dc.l   Exception                        ; TRAP #15 exception
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)
    dc.l   Exception                        ; Unused (reserved)

    SECTION_END
