;------------------------------------------------------------------------------------------
; Video Display Processor (VDP)
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; VDP 68000 interface
; ----------------

MEM_VDP_DATA        Equ $00c00000
MEM_VDP_CTRL        Equ $00c00004
MEM_VDP_HVCOUNTER   Equ $00c00008


;-------------------------------------------------
; VRAM Related contants
; ----------------
VRAM_SIZE_BYTE      Equ $10000
VRAM_SIZE_WORD      Equ (VRAM_SIZE_BYTE / SIZE_WORD)
VRAM_SIZE_LONG      Equ (VRAM_SIZE_BYTE / SIZE_LONG)

VSRAM_SIZE_BYTE     Equ 80
VSRAM_SIZE_WORD     Equ (VSRAM_SIZE_BYTE / SIZE_WORD)
VSRAM_SIZE_LONG     Equ (VSRAM_SIZE_BYTE / SIZE_LONG)

CRAM_SIZE_BYTE      Equ 128
CRAM_SIZE_WORD      Equ (CRAM_SIZE_BYTE / SIZE_WORD)
CRAM_SIZE_LONG      Equ (CRAM_SIZE_BYTE / SIZE_LONG)


;-------------------------------------------------
; VDP Status register bits
; ----------------
VDP_STATUS_PAL          Equ $0001   ; PAL, 0 = NTSC
VDP_STATUS_DMA          Equ $0002   ; DMA Busy
VDP_STATUS_HBLANK       Equ $0004   ; HBlank active
VDP_STATUS_VBLANK       Equ $0008   ; VBlank active
VDP_STATUS_ODD          Equ $0010   ; Odd frame in interlace mode
VDP_STATUS_COLLISION    Equ $0020   ; Sprite collision happened between non zero sprite pixels
VDP_STATUS_SOVERLFLOW   Equ $0040   ; Sprite overflow happened
VDP_STATUS_VINT         Equ $0080   ; Vertical interrup happened
VDP_STATUS_FIFO_FULL    Equ $0100   ; Write FIFO full
VDP_STATUS_FIFO_EMPTY   Equ $0200   ; Write FIFO empty


;-------------------------------------------------
; VDP register shadow variables
; ----------------

    ; VDPContext structure
    DEFINE_STRUCT VDPContext
        STRUCT_MEMBER.w vdpRegMode1
        STRUCT_MEMBER.w vdpRegMode2
        STRUCT_MEMBER.w vdpRegMode3
        STRUCT_MEMBER.w vdpRegMode4
        STRUCT_MEMBER.w vdpRegPlaneA
        STRUCT_MEMBER.w vdpRegPlaneB
        STRUCT_MEMBER.w vdpRegSprite
        STRUCT_MEMBER.w vdpRegWindow
        STRUCT_MEMBER.w vdpRegHScroll
        STRUCT_MEMBER.w vdpRegPlaneSize
        STRUCT_MEMBER.w vdpRegWinX
        STRUCT_MEMBER.w vdpRegWinY
        STRUCT_MEMBER.w vdpRegIncr
        STRUCT_MEMBER.w vdpRegBGCol
        STRUCT_MEMBER.w vdpRegHRate
    DEFINE_STRUCT_END

    ; Allocate VDPContext
    DEFINE_VAR FAST
        VAR.VDPContext vdpContext
    DEFINE_VAR_END

    ; VDPContext initial value (sensible defaults)
    INIT_STRUCT vdpContext
        INIT_STRUCT_MEMBER.vdpRegMode1      VDP_CMD_RS_MODE1        | MODE1_HIGH_COLOR
        INIT_STRUCT_MEMBER.vdpRegMode2      VDP_CMD_RS_MODE2        | MODE2_MODE_5 | MODE2_DMA_ENABLE | MODE2_DISPLAY_ENABLE | MODE2_VBLANK_ENABLE
        INIT_STRUCT_MEMBER.vdpRegMode3      VDP_CMD_RS_MODE3
        INIT_STRUCT_MEMBER.vdpRegMode4      VDP_CMD_RS_MODE4        | MODE4_H40_CELL
        INIT_STRUCT_MEMBER.vdpRegPlaneA     VDP_CMD_RS_PLANE_A      | PLANE_A_ADDR_c000
        INIT_STRUCT_MEMBER.vdpRegPlaneB     VDP_CMD_RS_PLANE_B      | PLANE_B_ADDR_e000
        INIT_STRUCT_MEMBER.vdpRegSprite     VDP_CMD_RS_SPRITE       | SPRITE_ADDR_fc00
        INIT_STRUCT_MEMBER.vdpRegWindow     VDP_CMD_RS_WINDOW
        INIT_STRUCT_MEMBER.vdpRegHScroll    VDP_CMD_RS_HSCROLL      | HSCROLL_ADDR_f800
        INIT_STRUCT_MEMBER.vdpRegPlaneSize  VDP_CMD_RS_PLANE_SIZE   | PLANE_SIZE_H64_V32
        INIT_STRUCT_MEMBER.vdpRegWinX       VDP_CMD_RS_WIN_X
        INIT_STRUCT_MEMBER.vdpRegWinY       VDP_CMD_RS_WIN_Y
        INIT_STRUCT_MEMBER.vdpRegIncr       VDP_CMD_RS_AUTO_INC     | $02
        INIT_STRUCT_MEMBER.vdpRegBGCol      VDP_CMD_RS_BG_COLOR
        INIT_STRUCT_MEMBER.vdpRegHRate      VDP_CMD_RS_HINT_RATE    | $ff
    INIT_STRUCT_END


;-------------------------------------------------
; Write cached register value to VDP
; ----------------
_VDP_REG_SYNC Macro vdpReg
        move.w  (vdpContext + \vdpReg), (MEM_VDP_CTRL)
    Endm


;-------------------------------------------------
; Set register value
; ----------------
VDP_REG_SET Macro vdpReg, value
        move.b   #\value, (vdpContext + \vdpReg + 1)

        _VDP_REG_SYNC \vdpReg
    Endm


;-------------------------------------------------
; Enable a VDP flag in the specified register
; ----------------
VDP_REG_SET_BITS Macro vdpReg, flag
        ori.b   #\flag, (vdpContext + \vdpReg + 1)

        _VDP_REG_SYNC \vdpReg
    Endm


;-------------------------------------------------
; Disable a VDP flag in the specified register
; ----------------
VDP_REG_RESET_BITS Macro vdpReg, flag
        andi.b   #~\flag, (vdpContext + \vdpReg + 1)

        _VDP_REG_SYNC \vdpReg
    Endm


;-------------------------------------------------
; Set bit field
; ----------------
VDP_REG_SET_BIT_FIELD Macro vdpReg, bitFieldMask, bitFieldValue
        andi.b  #~\bitFieldMask, (vdpContext + \vdpReg + 1)
        ori.b   #\bitFieldValue, (vdpContext + \vdpReg + 1)

        _VDP_REG_SYNC \vdpReg
    Endm


;----------------------------------------------
; Set vram address, access type and data stride
; ----------------
VDP_ADDR_SET Macro accessType, ramType, address, dataStride
        If (narg = 4)
            VDP_REG_SET vdpRegIncr, \dataStride
        EndIf

        If (strcmp('\ramType', 'VRAM'))
            move.l #VDP_CMD_AS_VRAM_\accessType | ((\address & $3fff) << 16) | ((\address & $c000) >> 14), (MEM_VDP_CTRL)
        Else
            move.l #VDP_CMD_AS_\ramType\_\accessType | (\address << 16), (MEM_VDP_CTRL)
        EndIf
    Endm


;----------------------------------------------
; Initialize the VDP for first use
; ----------------
VDPInit:
        bsr   _VDPUnlock
        bsr   _VDPInitRegisters

        bsr   VDPClearVRAM
        bsr   VDPClearVSRAM
        bsr   VDPClearCRAM
        rts


;-------------------------------------------------
; Unlock VDP by TradeMark Security System (TMSS) protocol
; ----------------
; Uses: d0
_VDPUnlock:
        jsr TMSSUnlock

        ; Read VDP status. If TMSS unlock failed the code will not continue (buslock by IO Controller)
        move.w  MEM_VDP_CTRL, d0
        rts


;-------------------------------------------------
; Write initial VDP register values
; ----------------
; Uses: d0/a0-a1
_VDPInitRegisters:
        bsr     vdpContextInit

        lea     vdpContext, a0
        lea     MEM_VDP_CTRL, a1
        move.w  #(VDPContext_Size / SIZE_WORD) - 1, d0

    .vdpRegisterSetLoop:
        move.w  (a0)+, (a1)
        dbra    d0, .vdpRegisterSetLoop
        rts


;------------------------------------------------
; Produce code that clears specified VRAM type
; ----------------
; Uses: d0-d1/a0
_VDP_VRAM_CLEAR Macro ramType
            VDP_ADDR_SET WRITE, \ramType, $00, $02

            moveq   #0, d1
            move.w  #\ramType\_SIZE_LONG - 1, d0
            lea     MEM_VDP_DATA, a0

        .clrVramLoop:
            move.l  d1, (a0)
            dbra    d0, .clrVramLoop
    Endm


;------------------------------------------------
; Clear Main VRAM
; ----------------
; Uses: d0-d1/a0
VDPClearVRAM:
        _VDP_VRAM_CLEAR VRAM
        rts


;-------------------------------------------------
; Clear Vertical Scroll RAM (VSRAM)
; ----------------
; Uses: d0-d1/a0
VDPClearVSRAM:
        _VDP_VRAM_CLEAR VSRAM
        rts


;-------------------------------------------------
; Clear Color RAM (CRAM)
; ----------------
; Uses: d0-d1/a0
VDPClearCRAM:
        _VDP_VRAM_CLEAR CRAM
        rts


;-------------------------------------------------
; Wait for the next vertical blanking period to start
; Uses: a0
; ----------------
VDPVSyncWait:
        lea     MEM_VDP_CTRL + 1, a0

    .waitVBLankEndLoop:
        btst    #3, (a0)
        bne     .waitVBLankEndLoop

    .waitVBlankStartLoop:
        btst    #3, (a0)
        beq     .waitVBlankStartLoop
        rts
