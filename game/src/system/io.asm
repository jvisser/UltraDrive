;------------------------------------------------------------------------------------------
; Controller port IO
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'
    Include './system/include/io.inc'
    Include './system/include/z80.inc'

;-------------------------------------------------
; Cached device readings
; ----------------
    DEFINE_VAR SHORT
        VAR.IODeviceState ioDeviceState1
        VAR.IODeviceState ioDeviceState2
    DEFINE_VAR_END

    INIT_STRUCT ioDeviceState1
        INIT_STRUCT_MEMBER.updateCallback   NoOperation
        INIT_STRUCT_MEMBER.dataPortAddress  MEM_IO_CTRL1_DATA
    INIT_STRUCT_END

    INIT_STRUCT ioDeviceState2
        INIT_STRUCT_MEMBER.updateCallback   NoOperation
        INIT_STRUCT_MEMBER.dataPortAddress  MEM_IO_CTRL2_DATA
    INIT_STRUCT_END


;-------------------------------------------------
; Optional automatic Z80 locking during IO access. Z80 -> 68000 access and 68000 -> IO access cannot occur simultaniously.
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
; ----------------
; Input:
; - a1: Data port address
_IO_TH_HIGH Macro
        move.b  #IO_DATA_TH, (a1)
    Endm


;-------------------------------------------------
; Set TH low on the specified port
; ----------------
; Input:
; - a1: Data port address
_IO_TH_LOW Macro
        move.b  #0, (a1)
    Endm


;-------------------------------------------------
; Wait for IO state reset. ~One display frame time.
; ----------------
; Uses: d6
_IO_RESET Macro
            move.w #$3fff, d6
        .ioResetLoop\@:
            dbra d6, .ioResetLoop\@
    Endm


;-------------------------------------------------
; Read port
; ----------------
; Input:
; - a1: Port to read
; Output: d0 high (TH=1), d0 low (TH = 0)
; Uses: d0/a1
_IO_READ_DATA_PORT Macro
        _IO_TH_HIGH
        _IO_WAIT

        move.b (a1), d0
        swap    d0

        _IO_TH_LOW
        _IO_WAIT

        move.b (a1), d0
    Endm


;-------------------------------------------------
; Probe data port without reading (Switch TH)
; ----------------
; Input:
; - a1: Port to read
_IO_PROBE_DATA_PORT Macro
        _IO_TH_HIGH
        _IO_WAIT

        _IO_TH_LOW
        _IO_WAIT
    Endm


;-------------------------------------------------
; Initialize IO hardware
; ----------------
IOInit:
_IO_UPDATE_DEVICE_INFO Macro deviceStateStruct
            bsr     \deviceStateStruct\Init
            lea     \deviceStateStruct, a0
            bsr     IOUpdateDeviceInfo
        Endm

        ; First wait for IO reset. Can be in partially initialized state if machine is reset.
        _IO_RESET

        _IO_Z80_LOCK

        ; Set write mode for PD6 = TH on both ports
        move.b  #IO_DATA_TH, (MEM_IO_CTRL1_CTRL)
        move.b  #IO_DATA_TH, (MEM_IO_CTRL2_CTRL)

        _IO_Z80_UNLOCK

        _IO_WAIT

        _IO_UPDATE_DEVICE_INFO ioDeviceState1
        _IO_UPDATE_DEVICE_INFO ioDeviceState2

        _IO_RESET

        bsr IOUpdateDeviceState

        ; Wait for IO reset so device readings down the line yield correct results
        _IO_RESET

        Purge _IO_UPDATE_DEVICE_INFO
        rts


;-------------------------------------------------
; Update device states. Should be called at most once per display frame.
; ----------------
; Uses: d0-d1/a0-a1
IOUpdateDeviceState:
_IO_UPDATE_DEVICE Macro deviceStateStruct
            lea     \deviceStateStruct, a0
            movea.l IODeviceState_updateCallback(a0), a1
            jsr     (a1)
        Endm

        _IO_UPDATE_DEVICE ioDeviceState1
        _IO_UPDATE_DEVICE ioDeviceState2

        Purge _IO_UPDATE_DEVICE
        rts;


;-------------------------------------------------
; Detect connected device (Slow!)
; ----------------
; Input:
; - a0: Device state structure of device to update
; Uses: d0-d3,d6/a1
IOUpdateDeviceInfo:
_IO_SET_DEVICE_TYPE Macro deviceTypeId, deviceUpdateCallback
            move.l  #\deviceUpdateCallback, IODeviceState_updateCallback(a0)
            move.b  #\deviceTypeId, IODeviceState_deviceType(a0)
        Endm

        movea.l IODeviceState_dataPortAddress(a0), a1

        bsr     _IOGetDeviceId
        move.b  d0, IODeviceState_deviceId(a0)

        cmpi.b  #IO_DEVICE_ID_MD_PAD, d0
        beq.s   .mdpad
        _IO_SET_DEVICE_TYPE IO_DEVICE_UNSUPPORTED, NoOperation
        bra.s   .done

    .mdpad:
        ; Mega Drive pad detected, now detect type (3 or 6 button)

        ; First reset IO (Because the device ID reading messed up the 6 button pad detection protocol)
        _IO_RESET

        _IO_Z80_LOCK

        ; Start 6 button pad detection
        _IO_PROBE_DATA_PORT
        _IO_PROBE_DATA_PORT
        _IO_READ_DATA_PORT  ; 6th port access (TH = 0) will contain the 6 button pad distinction data: PD0-3 = 0

        _IO_TH_HIGH

        _IO_Z80_UNLOCK

        andi.b  #$0f, d0
        beq.s   .mdpad6

        _IO_SET_DEVICE_TYPE IO_DEVICE_MEGA_DRIVE_3_BUTTON, _IOUpdate3ButtonPad
        bra.s   .done

    .mdpad6:
        _IO_SET_DEVICE_TYPE IO_DEVICE_MEGA_DRIVE_6_BUTTON, _IOUpdate6ButtonPad

    .done:

        Purge _IO_SET_DEVICE_TYPE
        rts


;-------------------------------------------------
; Determine device ID of device connected to the specified port
; ----------------
; Input:
; - a1: Data port address
; Output: device id in d0
; Uses: d0-d3
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

        Purge _IO_GET_DEVICE_ID_BIT
        rts


;-------------------------------------------------
; Mega Drive 3 button pad update callback
; ----------------
; Input:
; - a0: Device state structure of device to update
; Uses: d0-d1/a1
_IOUpdate3ButtonPad:
        movea.l IODeviceState_dataPortAddress(a0), a1

        _IO_Z80_LOCK

        _IO_READ_DATA_PORT

        _IO_Z80_UNLOCK

        move.b  d0, d1
        swap    d0
        andi.b  #(IO_DATA_UP | IO_DATA_DOWN | IO_DATA_LEFT | IO_DATA_RIGHT | IO_DATA_READ_B | IO_DATA_READ_C), d0
        andi.b  #(IO_DATA_READ_A | IO_DATA_READ_START), d1
        add.b   d1, d1
        add.b   d1, d1
        or.b    d1, d0

        move.w  d0, IODeviceState_deviceState(a0)
        rts


;-------------------------------------------------
; Mega Drive 6 button pad update callback
; ----------------
; Input:
; - a0: Device state structure of device to update
; Uses: d0-d1/a1
_IOUpdate6ButtonPad:
        bsr _IOUpdate3ButtonPad ; We reuse a1 from _IOUpdate3ButtonPad

        _IO_Z80_LOCK

        _IO_PROBE_DATA_PORT
        _IO_PROBE_DATA_PORT

        _IO_TH_HIGH     ; NB: TH must be left high at the end of the 6 button pad access sequence!
        _IO_WAIT

        move.b  (a1), d0

        _IO_Z80_UNLOCK

        andi.b  #(IO_DATA_READ_X | IO_DATA_READ_Y | IO_DATA_READ_Z | IO_DATA_READ_MODE), d0
        move.b  d0, IODeviceState_deviceState(a0)
        rts


    Purge _IO_Z80_LOCK
    Purge _IO_Z80_UNLOCK
    Purge _IO_WAIT
    Purge _IO_TH_HIGH
    Purge _IO_TH_LOW
    Purge _IO_RESET
    Purge _IO_READ_DATA_PORT
    Purge _IO_PROBE_DATA_PORT