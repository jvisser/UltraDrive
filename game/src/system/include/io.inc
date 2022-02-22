;------------------------------------------------------------------------------------------
; Controller port IO
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_IO_INC))
__SYSTEM_IO_INC Equ 1

    Include './lib/common/include/constants.inc'

    Include './system/include/memory.inc'

;-------------------------------------------------
; IO 68000 interface.
; ----------------
MEM_IO_CTRL1_DATA                   Equ $00a10003
MEM_IO_CTRL1_CTRL                   Equ $00a10009

MEM_IO_CTRL2_DATA                   Equ $00a10005
MEM_IO_CTRL2_CTRL                   Equ $00a1000b


;-------------------------------------------------
; IO register specifics
; ----------------

; Parallel control port bit names.
IO_CTRL_PC0                         Equ $01         ; PC0-6 determine the comms mode for the corresponding bit on the associated data port (1 = write, 0 = read)
IO_CTRL_PC1                         Equ $02
IO_CTRL_PC2                         Equ $04
IO_CTRL_PC3                         Equ $08
IO_CTRL_PC4                         Equ $10
IO_CTRL_PC5                         Equ $20
IO_CTRL_PC6                         Equ $40
IO_CTRL_INT                         Equ $80         ; Enable external interrupt

; Data port bit names
IO_DATA_PD0                         Equ $01
IO_DATA_PD1                         Equ $02
IO_DATA_PD2                         Equ $04
IO_DATA_PD3                         Equ $08
IO_DATA_PD4                         Equ $10
IO_DATA_PD5                         Equ $20
IO_DATA_PD6                         Equ $40
IO_DATA_PD7                         Equ $80

; Data port bit names corresponding to the physical port
IO_DATA_UP                          Equ $01         ; PD0
IO_DATA_DOWN                        Equ $02         ; PD1
IO_DATA_LEFT                        Equ $04         ; PD2
IO_DATA_RIGHT                       Equ $08         ; PD3
IO_DATA_TL                          Equ $10         ; PD4
IO_DATA_TR                          Equ $20         ; PD5
IO_DATA_TH                          Equ $40         ; PD6 Used to switch read mode for reading Mega Drive controllers (PC6 = 1)

; Mega Drive controller specific data port bit names
IO_DATA_READ_B                      Equ $10         ; PD4 (TH = 0)
IO_DATA_READ_C                      Equ $20         ; PD5 (TH = 0)
IO_DATA_READ_A                      Equ $10         ; PD4 (TH = 1)
IO_DATA_READ_START                  Equ $20         ; PD5 (TH = 1)
IO_DATA_READ_Z                      Equ $01         ; PD0
IO_DATA_READ_Y                      Equ $02         ; PD1
IO_DATA_READ_X                      Equ $04         ; PD2
IO_DATA_READ_MODE                   Equ $08         ; PD3


;-------------------------------------------------
; Known device ID's (as returned by the connected device)
; ----------------
IO_DEVICE_ID_MENACER                Equ $00
IO_DEVICE_ID_JUSTIFIER              Equ $01         ; Konami light gun
IO_DEVICE_ID_MOUSE                  Equ $03
IO_DEVICE_ID_TEAMPLAYER             Equ $07
IO_DEVICE_ID_MD_PAD                 Equ $0d


;-------------------------------------------------
; Supported device types. Some peripherals need specialized detection code and so we can not rely on Device ID alone (6 button controller for example)
; ----------------
IO_DEVICE_UNSUPPORTED               Equ $00
IO_DEVICE_MEGA_DRIVE_3_BUTTON       Equ $01
IO_DEVICE_MEGA_DRIVE_6_BUTTON       Equ $02


;-------------------------------------------------
; Input port identifiers
; ----------------
IO_PORT_1                           Equ 1
IO_PORT_2                           Equ 2


;-------------------------------------------------
; Device specific state bits
; ----------------

    ; Mega Drive 3 button controller device state bits
    BIT_CONST.MD_PAD_UP     0
    BIT_CONST.MD_PAD_DOWN   1
    BIT_CONST.MD_PAD_LEFT   2
    BIT_CONST.MD_PAD_RIGHT  3
    BIT_CONST.MD_PAD_B      4
    BIT_CONST.MD_PAD_C      5
    BIT_CONST.MD_PAD_A      6
    BIT_CONST.MD_PAD_START  7

    ; Mega Drive 6 button controller device state bits
    BIT_CONST.MD_PAD_Z      8
    BIT_CONST.MD_PAD_Y      9
    BIT_CONST.MD_PAD_X      10
    BIT_CONST.MD_PAD_MODE   11


;-------------------------------------------------
; Device state structures
; ----------------
    DEFINE_STRUCT IODeviceState
        STRUCT_MEMBER.w deviceState
        STRUCT_MEMBER.l updateCallback
        STRUCT_MEMBER.l dataPortAddress
        STRUCT_MEMBER.b deviceId
        STRUCT_MEMBER.b deviceType
    DEFINE_STRUCT_END


;-------------------------------------------------
; Read device state for the specified port into into target
; ----------------
IO_GET_DEVICE_STATE Macro port, target
        Local __PORT_NUMBER
__PORT_NUMBER Equ \port
        move.w  ioDeviceState\#__PORT_NUMBER, \target
    Endm

    EndIf
