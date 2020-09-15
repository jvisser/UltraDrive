;------------------------------------------------------------------------------------------
; Mega Drive specific rom header meta data format
;------------------------------------------------------------------------------------------

RomHeader:
    dc.b    'SEGA MEGA DRIVE'               ; Console name
    dcb.b   $110-*, ' '                     ; Padding
    dc.b    '\COPYRIGHT'                    ; Copyright holder
    dc.b    ' '                             ; Padding
    dc.b    '\RELEASE_DATE'                 ; Release date
    dcb.b   $120-*, ' '                     ; Padding
    dc.b    '\TITLE'                        ; Domestic name
    dcb.b   $150-*, ' '                     ; Padding
    dc.b    '\TITLE'                        ; International name
    dcb.b   $180-*, ' '                     ; Padding
    dc.b    'GM \SERIAL_NUMBER\-\REVISION'  ; Version number
    dcb.b   $18e-*, ' '                     ; Padding
    dc.w    0x0000                          ; Checksum
    dc.b    '\DEVICE_SUPPORT'               ; Device support
    dcb.b   $1a0-*, ' '                     ; Padding
    dc.l    0x00000000                      ; Start address of ROM
    dc.l    RomImageEnd                     ; End address of ROM
    dc.l    0x00ff0000                      ; Start address of RAM
    dc.l    0x00ffffff                      ; End address of RAM
    dc.l    0x00000000                      ; SRAM enabled
    dc.l    0x00000000                      ; Unused
    dc.l    0x00000000                      ; Start address of SRAM
    dc.l    0x00000000                      ; End address of SRAM
    dcb.b   $1f0-*, ' '                     ; Padding
    dc.b    '\REGION'                       ; Region support
    dcb.b   $200-*, ' '                     ; Padding
