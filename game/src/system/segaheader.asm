;------------------------------------------------------------------------------------------
; Mega Drive specific rom header meta data format
;------------------------------------------------------------------------------------------

; Pre format composed fields
HEADER_FIELD_COPY_RIGHT_RELEASE_DATE    Equs '(C)\COPYRIGHT_HOLDER\ \#RELEASE_YEAR\.\#RELEASE_MONTH\'
HEADER_FIELD_SERIAL_NUMBER              Equs '\SERIAL_NUMBER\-\REVISION\'

    SECTION_START S_HEADER

RomHeader:
    dc.b  'SEGA MEGA DRIVE '                                        ; Console name
    dc.b  '\HEADER_FIELD_COPY_RIGHT_RELEASE_DATE'                   ; Copyright holder and release date
    dcb.b 16 - strlen('\HEADER_FIELD_COPY_RIGHT_RELEASE_DATE'), ' ' ; Copyright padding
    dc.b  '\TITLE'                                                  ; Domestic name
    dcb.b 48 - strlen('\TITLE'), ' '                                ; Domestic name padding
    dc.b  '\TITLE'                                                  ; International name
    dcb.b 48 - strlen('\TITLE'), ' '                                ; International name padding
    dc.b  '\HEADER_FIELD_SERIAL_NUMBER'                             ; Serial number
    dcb.b 14 - strlen('\HEADER_FIELD_SERIAL_NUMBER'), ' '           ; Serial number padding
    dc.w  $0000                                                     ; Checksum
    dc.b  '\DEVICE_SUPPORT'                                         ; Supported devices
    dcb.b 16 - strlen('\DEVICE_SUPPORT'), ' '                       ; Supported devices padding
    dc.l  $00000000                                                 ; Start address of ROM
    dc.l  RomImageEnd                                               ; End address of ROM
    dc.l  $00ff0000                                                 ; Start address of RAM
    dc.l  $00ffffff                                                 ; End address of RAM
    dc.l  $00000000                                                 ; SRAM descriptor
    dc.l  $00000000                                                 ; Start address of SRAM
    dc.l  $00000000                                                 ; End address of SRAM
    dcb.b 52, ' '                                                   ; Unused
    dc.b  '\REGION'                                                 ; Supported regions
    dcb.b 16 - strlen('\REGION'), ' '                               ; Supported regions padding

    SECTION_END