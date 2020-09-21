;------------------------------------------------------------------------------------------
; Controller port IO
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; IO 68000 interface.
; ----------------
MEM_IO_CTRL1_DATA       Equ $00a10003
MEM_IO_CTRL1_CTRL       Equ $00a10009

MEM_IO_CTRL2_DATA       Equ $00a10005
MEM_IO_CTRL2_CTRL       Equ $00a1000b


;-------------------------------------------------
; IO register specifics
; ----------------

; Parallel control port bit names. 
IO_CTRL_PC0             Equ $01         ; PC0-6 determine the comms mode for the corresponding bit on the associated data port (1 = write, 0 = read)
IO_CTRL_PC1             Equ $02
IO_CTRL_PC2             Equ $04
IO_CTRL_PC3             Equ $08
IO_CTRL_PC4             Equ $10
IO_CTRL_PC5             Equ $20
IO_CTRL_PC6             Equ $40
IO_CTRL_INT             Equ $80         ; Enable external interrupt

; Generic data port bit names
IO_DATA_PD0             Equ $01
IO_DATA_PD1             Equ $02
IO_DATA_PD2             Equ $04
IO_DATA_PD3             Equ $08
IO_DATA_PD4             Equ $10
IO_DATA_PD5             Equ $20
IO_DATA_PD6             Equ $40
IO_DATA_PD7             Equ $80

; Dataport bit names corresponding to the physical port
IO_DATA_UP              Equ $01         ; PD0
IO_DATA_DOWN            Equ $02         ; PD1
IO_DATA_LEFT            Equ $04         ; PD2
IO_DATA_RIGHT           Equ $08         ; PD3
IO_DATA_TL              Equ $10         ; PD4
IO_DATA_TR              Equ $20         ; PD5
IO_DATA_TH              Equ $40         ; PD6 Used to switch read mode for reading Mega Drive controllers (PC6 = 1)

; Mega Drive controller specific data port bit names
IO_DATA_READ_B          Equ $10         ; PD4 (TH = 0)
IO_DATA_READ_C          Equ $20         ; PD5 (TH = 0)
IO_DATA_READ_A          Equ $10         ; PD4 (TH = 1)
IO_DATA_READ_START      Equ $20         ; PD5 (TH = 1)


;-------------------------------------------------
; Device ID's
; ----------------
IO_DEVICE_ID_MD_PAD     Equ $0d


;-------------------------------------------------
; Device types. Some peripherals need specialized detection code and so we can not rely on Device ID alone (6 button controller for example)
; ----------------
IO_DEVICE_UNKNOWN                   Equ $00
IO_DEVICE_MEGA_DRIVE_3_BUTTON       Equ $01


;-------------------------------------------------
; Device specific state bits
; ----------------

; Mega Drive 3 button controller device state bits
MD_PAD_UP               Equ $01
MD_PAD_DOWN             Equ $02
MD_PAD_LEFT             Equ $04
MD_PAD_RIGHT            Equ $08
MD_PAD_B                Equ $10
MD_PAD_C                Equ $20
MD_PAD_A                Equ $40
MD_PAD_START            Equ $80


;-------------------------------------------------
; Cached device readings
; ----------------
    DEFINE_STRUCT IODeviceState
        STRUCT_MEMBER b, deviceState
        STRUCT_MEMBER b, deviceType
        STRUCT_MEMBER l, dataPortAddress
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        STRUCT  IODeviceState, ioDeviceState1
        STRUCT  IODeviceState, ioDeviceState2
    DEFINE_VAR_END

    INIT_STRUCT ioDeviceState1
        INIT_STRUCT_MEMBER dataPortAddress, MEM_IO_CTRL1_DATA
    INIT_STRUCT_END

    INIT_STRUCT ioDeviceState2
        INIT_STRUCT_MEMBER dataPortAddress, MEM_IO_CTRL2_DATA
    INIT_STRUCT_END


;-------------------------------------------------
; Optional Z80 locking during IO access. Z80 -> 68000 access and 68000 -> IO access cannot occur simultaniously.
; ----------------
_IO_Z80_LOCK Macro
        If def(io_z80_safe)
            Z80_REQUEST_BUS
        EndIf
    Endm

_IO_Z80_UNLOCK Macro
        If def(io_z80_safe)
            Z80_RELEASE
        EndIf
    Endm

    
;-------------------------------------------------
; Wait for data availability after TH mode change (~1 micro second)
; ----------------
_IO_WAIT Macro
            nop
            nop
    Endm


;-------------------------------------------------
; Set TH high on the specified port
; Input:
; - a1: Data port address
; ----------------
_IO_TH_HIGH Macros
        move.b  #IO_DATA_TH, (a1)


;-------------------------------------------------
; Set TH low on the specified port
; Input:
; - a1: Data port address
; ----------------
_IO_TH_LOW Macros
        move.b  #0, (a1)


;-------------------------------------------------
; Initialize IO hardware
; ----------------
IOInit:
        _IO_Z80_LOCK

        ; Set write mode for PD6 = TH on both ports
        move.b  #IO_DATA_TH, (MEM_IO_CTRL1_CTRL)
        move.b  #IO_DATA_TH, (MEM_IO_CTRL2_CTRL)

        _IO_Z80_UNLOCK

        _IO_WAIT

        ; Initialize device state for both ports
        bsr.s   ioDeviceState1Init
        bsr.s   ioDeviceState2Init
        lea     ioDeviceState1, a0
        moveq   #0, d0

    .updateDeviceLoop:
        bsr.s   IOUpdateDeviceInfo
        bsr.s   IOUpdateDeviceState

        adda.l  #IODeviceState_Size, a0
        dbra    d0, .updateDeviceLoop
        rts


;-------------------------------------------------
; Update device input readings
; Input:
; - a0: Device state structure of device to update
; Uses: d0-d1/a1
; ----------------
IOUpdateDeviceState:
        movea.l dataPortAddress(a0), a1

        _IO_Z80_LOCK

        _IO_TH_HIGH
        _IO_WAIT

        move.b (a1), d0

        _IO_TH_LOW
        _IO_WAIT

        move.b (a1), d1

        _IO_Z80_UNLOCK

        andi.b  #(IO_DATA_UP | IO_DATA_DOWN | IO_DATA_LEFT | IO_DATA_RIGHT | IO_DATA_READ_B | IO_DATA_READ_C), d0
        andi.b  #(IO_DATA_READ_A | IO_DATA_READ_START), d1
        add.b   d1, d1
        add.b   d1, d1
        or.b    d1, d0

        move.b  d0, deviceState(a0)
        rts


;-------------------------------------------------
; Update device type
; Input:
; - a0: Device state structure of device to update
; Uses: d0-d3/a1
; ----------------
IOUpdateDeviceInfo:
        bsr.s   _IOGetDeviceId

        cmpi.b  #IO_DEVICE_ID_MD_PAD, d0
        bne.s   .unknownDevice
        move.b  #IO_DEVICE_MEGA_DRIVE_3_BUTTON, deviceType(a0)
        bra.s   .done

    .unknownDevice:
        move.b  #IO_DEVICE_UNKNOWN, deviceType(a0)

    .done:
        rts


;-------------------------------------------------
; Determine device ID connected to the specified port
; Input:
; - a0: Device state structure of device
; Output: device id in d0
; Uses: d0-d3/a1
; ----------------
_IOGetDeviceId:
_IO_GET_DEVICE_ID_BIT Macro bits
            move.b  d1, d3
            andi.b  #(\bits), d3
            sne     d3
            and.b   d2, d3
            or.b    d3, d0
            add.b   d2, d2
        Endm

        moveq   #0, d0      ; Device Id
        moveq   #1, d2      ; Current bit of device id being processed

        movea.l dataPortAddress(a0), a1

        _IO_Z80_LOCK

        _IO_TH_LOW
        _IO_WAIT

        move.b  (a1), d1

        _IO_GET_DEVICE_ID_BIT (IO_DATA_PD0 | IO_DATA_PD1)
        _IO_GET_DEVICE_ID_BIT (IO_DATA_PD2 | IO_DATA_PD3)

        _IO_TH_HIGH
        _IO_WAIT

        move.b  (a1), d1

        _IO_GET_DEVICE_ID_BIT (IO_DATA_PD0 | IO_DATA_PD1)
        _IO_GET_DEVICE_ID_BIT (IO_DATA_PD2 | IO_DATA_PD3)

        _IO_Z80_UNLOCK
        rts
