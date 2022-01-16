;------------------------------------------------------------------------------------------
; Video Display Processor (VDP) constants / macros
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_VDP_INC))
__SYSTEM_VDP_INC Equ 1

    Include './common/include/constants.inc'

    Include './system/include/memory.inc'
    Include './system/include/vdpcmd.inc'
    Include './system/include/vdpdma.inc'

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

; Default VDP object addresses
VDP_PLANE_A_ADDR    Equ $c000       ; Corresponds to VDP_PLANE_A identifier
VDP_PLANE_B_ADDR    Equ $e000       ; Corresponds to VDP_PLANE_B identifier
VDP_WINDOW_ADDR     Equ $b000       ; Corresponds to VDP_WINDOW identifier
VDP_SPRITE_ADDR     Equ $bc00
VDP_HSCROLL_ADDR    Equ $b800


;-------------------------------------------------
; VDP Status register bits
; ----------------
    BIT_CONST.VDP_STATUS_PAL          0   ; PAL, 0 = NTSC
    BIT_CONST.VDP_STATUS_DMA          1   ; DMA Busy
    BIT_CONST.VDP_STATUS_HBLANK       2   ; HBlank active
    BIT_CONST.VDP_STATUS_VBLANK       3   ; VBlank active
    BIT_CONST.VDP_STATUS_ODD          4   ; Odd frame in interlace mode
    BIT_CONST.VDP_STATUS_COLLISION    5   ; Sprite collision happened between non zero sprite pixels
    BIT_CONST.VDP_STATUS_SOVERLFLOW   6   ; Sprite overflow happened
    BIT_CONST.VDP_STATUS_VINT         7   ; Vertical interrup happened
    BIT_CONST.VDP_STATUS_FIFO_FULL    8   ; Write FIFO full
    BIT_CONST.VDP_STATUS_FIFO_EMPTY   9   ; Write FIFO empty


;-------------------------------------------------
; VDP plane pattern reference structure (16 bit)
; ----------------
    BIT_MASK.PATTERN_REF_INDEX        0,    11
    BIT_MASK.PATTERN_REF_ORIENTATION  11,   2
    BIT_CONST.PATTERN_REF_HFLIP       11
    BIT_CONST.PATTERN_REF_VFLIP       12
    BIT_MASK.PATTERN_REF_PALETTE      13,   2
    BIT_CONST.PATTERN_REF_PRIORITY    15


;-------------------------------------------------
; VDP Pattern metrics
; ----------------
PATTERN_DIMENSION   Equ 8
PATTERN_SIZE        Equ (PATTERN_DIMENSION * SIZE_LONG)
PATTERN_SHIFT       Equ 3
PATTERN_MASK        Equ 7


;-------------------------------------------------
; Sprite attribute constants
; ----------------
; Vertical sizes
VDP_SPRITE_SIZE_V1  Equ $00
VDP_SPRITE_SIZE_V2  Equ $01
VDP_SPRITE_SIZE_V3  Equ $02
VDP_SPRITE_SIZE_V4  Equ $03

; Horizontal sizes
VDP_SPRITE_SIZE_H1  Equ $00
VDP_SPRITE_SIZE_H2  Equ $04
VDP_SPRITE_SIZE_H3  Equ $08
VDP_SPRITE_SIZE_H4  Equ $0c

    ;-------------------------------------------------
    ; Sprite attribute constants
    ; ----------------
    ; Size bit masks
    BIT_MASK.VDP_SPRITE_VSIZE               0, 2
    BIT_MASK.VDP_SPRITE_HSIZE               2, 2
    BIT_MASK.VDP_SPRITE_SIZE                0, 4

    ; Sprite content reference. Same structure as pattern name table ref
    BIT_MASK.VDP_SPRITE_ATTR3_ORIENTATION   11, 2
    BIT_CONST.VDP_SPRITE_ATTR3_HFLIP        11
    BIT_CONST.VDP_SPRITE_ATTR3_VFLIP        12
    BIT_MASK.VDP_SPRITE_ATTR3_PALETTE       13, 2
    BIT_CONST.VDP_SPRITE_ATTR3_PRIORITY     15


;-------------------------------------------------
; VDP structs
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

    ; VDP metrics structure
    DEFINE_STRUCT VDPMetrics
        STRUCT_MEMBER.w screenWidth
        STRUCT_MEMBER.w screenHeight
        STRUCT_MEMBER.w screenWidthPatterns
        STRUCT_MEMBER.w screenHeightPatterns
        STRUCT_MEMBER.w planeWidth
        STRUCT_MEMBER.w planeHeight
        STRUCT_MEMBER.w planeWidthPatterns
        STRUCT_MEMBER.w planeHeightPatterns
        STRUCT_MEMBER.w planeWidthShift
        STRUCT_MEMBER.w planeHeightShift
    DEFINE_STRUCT_END

    ; VDP hardware sprite attribute struct (8 bytes)
    DEFINE_STRUCT VDPSprite
        STRUCT_MEMBER.w y
        STRUCT_MEMBER.b size
        STRUCT_MEMBER.b link
        STRUCT_MEMBER.w attr
        STRUCT_MEMBER.w x
    DEFINE_STRUCT_END


;-------------------------------------------------
; Write cached register value to VDP
; ----------------
__VDP_REG_SYNC Macro vdpReg
        move.w  (vdpContext + VDPContext_\vdpReg), MEM_VDP_CTRL
    Endm


;-------------------------------------------------
; Set register value
; ----------------
VDP_REG_SET Macro vdpReg, value
        move.b   #\value, (vdpContext + VDPContext_\vdpReg + 1)

        __VDP_REG_SYNC \vdpReg
    Endm


;-------------------------------------------------
; Enable a VDP flag in the specified register
; ----------------
VDP_REG_SET_BITS Macro vdpReg, flag
        ori.b   #\flag, (vdpContext + VDPContext_\vdpReg + 1)

        __VDP_REG_SYNC \vdpReg
    Endm


;-------------------------------------------------
; Disable a VDP flag in the specified register
; ----------------
VDP_REG_RESET_BITS Macro vdpReg, flag
        andi.b   #~\flag & $ff, (vdpContext + VDPContext_\vdpReg + 1)

        __VDP_REG_SYNC \vdpReg
    Endm


;-------------------------------------------------
; Set bit field
; ----------------
VDP_REG_SET_BIT_FIELD Macro vdpReg, bitFieldMask, bitFieldValue
        andi.b  #~\bitFieldMask, (vdpContext + VDPContext_\vdpReg + 1)
        ori.b   #\bitFieldValue, (vdpContext + VDPContext_\vdpReg + 1)

        __VDP_REG_SYNC \vdpReg
    Endm


;----------------------------------------------
; VDP Address set constants / macros
; ----------------
VDP_ADDR_SET_CONST Macro accessType, ramType, address
        If (strcmp('\ramType', 'VRAM'))
\0  Equ (VDP_CMD_AS_VRAM_\accessType | (((\address) & $3fff) << 16) | (((\address) & $c000) >> 14))
        Else
\0  Equ (VDP_CMD_AS_\ramType\_\accessType | ((\address) << 16))
        EndIf
    Endm


;----------------------------------------------
; Set vram address, access type and data stride
; ----------------
VDP_ADDR_SET Macro accessType, ramType, address, dataStride
        If (narg = 4)
            VDP_REG_SET vdpRegIncr, \dataStride
        EndIf

        Local __AS
        VDP_ADDR_SET_CONST.__AS  \accessType, \ramType, \address
        move.l #__AS, (MEM_VDP_CTRL)
    Endm


;----------------------------------------------
; Plane identifiers (double as address set commands)
; ----------------
    VDP_ADDR_SET_CONST.VDP_WINDOW   WRITE, VRAM, VDP_WINDOW_ADDR
    VDP_ADDR_SET_CONST.VDP_PLANE_A  WRITE, VRAM, VDP_PLANE_A_ADDR
    VDP_ADDR_SET_CONST.VDP_PLANE_B  WRITE, VRAM, VDP_PLANE_B_ADDR

    EndIf

