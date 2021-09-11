;------------------------------------------------------------------------------------------
; Mega Drive specific rom header meta data format
;------------------------------------------------------------------------------------------

; Pre format composed fields
HEADER_FIELD_COPY_RIGHT_RELEASE_DATE    Equs '(C)\COPYRIGHT_HOLDER\ \#RELEASE_YEAR\.\#RELEASE_MONTH\'
HEADER_FIELD_SERIAL_NUMBER              Equs '\SERIAL_NUMBER\-\REVISION\'

    SECTION_START S_HEADER

RomHeader:
RomHeaderSystemType:
    dc.b  'SEGA MEGA DRIVE '                                        ; Console name
RomHeaderCopyright:
    dc.b  '\HEADER_FIELD_COPY_RIGHT_RELEASE_DATE'                   ; Copyright holder and release date
    dcb.b 16 - strlen('\HEADER_FIELD_COPY_RIGHT_RELEASE_DATE'), ' ' ; Copyright padding
RomHeaderTitleDomestic:
    dc.b  '\TITLE'                                                  ; Domestic name
    dcb.b 48 - strlen('\TITLE'), ' '                                ; Domestic name padding
RomHeaderTitleOverseas:
    dc.b  '\TITLE'                                                  ; International name
    dcb.b 48 - strlen('\TITLE'), ' '                                ; International name padding
RomHeaderSerialNumber:
    dc.b  '\HEADER_FIELD_SERIAL_NUMBER'                             ; Serial number
    dcb.b 14 - strlen('\HEADER_FIELD_SERIAL_NUMBER'), ' '           ; Serial number padding
RomHeaderChecksum:
    dc.w  $0000                                                     ; Checksum
RomHeaderDeviceSupport:
    dc.b  '\DEVICE_SUPPORT'                                         ; Supported devices
    dcb.b 16 - strlen('\DEVICE_SUPPORT'), ' '                       ; Supported devices padding
RomHeaderRomStart:
    dc.l  $00000000                                                 ; Start address of ROM
RomHeaderRomEnd:
    dc.l  RomImageEnd                                               ; End address of ROM
RomHeaderRamStart:
    dc.l  ((__SHORT_RAM_ALLOCATION_PTR + 1) & -2)                   ; Start address of RAM (Used to indicate free RAM in this case, not sure what the original purpose of these fields was (for debugger maybe?))
RomHeaderRamEnd:
    dc.l  MEM_RAM_END - MEM_RAM_STACK_SIZE + 1                      ; End address of RAM
RomHeaderSRAMDescriptor:
    dc.l  $00000000                                                 ; SRAM descriptor
RomHeaderSRAMStart:
    dc.l  $00000000                                                 ; Start address of SRAM
RomHeaderSRAMEnd:
    dc.l  $00000000                                                 ; End address of SRAM
    dcb.b 52, ' '                                                   ; Unused
RomHeaderRegion:
    dc.b  '\REGION'                                                 ; Supported regions
    dcb.b 16 - strlen('\REGION'), ' '                               ; Supported regions padding

    SECTION_END
