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


; Default VDP object addresses
VDP_PLANE_A_ADDR        Equ $c000
VDP_PLANE_B_ADDR        Equ $e000
VDP_WINDOW_ADDR         Equ $b000
VDP_SPRITE_ADDR         Equ $bc00
VDP_HSCROLL_ADDR        Equ $b800


    ; Plane identifiers (double as address set commands)
    VDP_ADDR_SET_CONST.VDP_WINDOW   WRITE, VRAM, VDP_WINDOW_ADDR
    VDP_ADDR_SET_CONST.VDP_PLANE_A  WRITE, VRAM, VDP_PLANE_A_ADDR
    VDP_ADDR_SET_CONST.VDP_PLANE_B  WRITE, VRAM, VDP_PLANE_B_ADDR


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

    ; VDP metrics structure
    DEFINE_STRUCT VDPMetrics
        STRUCT_MEMBER.w vdpScreenWidth
        STRUCT_MEMBER.w vdpScreenHeight
        STRUCT_MEMBER.w vdpScreenWidthPatterns
        STRUCT_MEMBER.w vdpScreenHeightPatterns
        STRUCT_MEMBER.w vdpPlaneWidth
        STRUCT_MEMBER.w vdpPlaneHeight
        STRUCT_MEMBER.w vdpPlaneWidthPatterns
        STRUCT_MEMBER.w vdpPlaneHeightPatterns
        STRUCT_MEMBER.w vdpPlaneWidthShift
        STRUCT_MEMBER.w vdpPlaneHeightShift
    DEFINE_STRUCT_END

    ; Allocate VDPContext
    DEFINE_VAR FAST
        VAR.VDPContext  vdpContext
        VAR.VDPMetrics  vdpMetrics
    DEFINE_VAR_END

    ; VDPContext initial values
    INIT_STRUCT vdpContext
        INIT_STRUCT_MEMBER.vdpRegMode1          VDP_CMD_RS_MODE1        | MODE1_HIGH_COLOR
        INIT_STRUCT_MEMBER.vdpRegMode2          VDP_CMD_RS_MODE2        | MODE2_MODE_5 | MODE2_DMA_ENABLE
        INIT_STRUCT_MEMBER.vdpRegMode3          VDP_CMD_RS_MODE3
        INIT_STRUCT_MEMBER.vdpRegMode4          VDP_CMD_RS_MODE4        | MODE4_H40_CELL
        INIT_STRUCT_MEMBER.vdpRegPlaneA         VDP_CMD_RS_PLANE_A      | PLANE_A_ADDR_\$VDP_PLANE_A_ADDR
        INIT_STRUCT_MEMBER.vdpRegPlaneB         VDP_CMD_RS_PLANE_B      | PLANE_B_ADDR_\$VDP_PLANE_B_ADDR
        INIT_STRUCT_MEMBER.vdpRegSprite         VDP_CMD_RS_SPRITE       | SPRITE_ADDR_\$VDP_SPRITE_ADDR
        INIT_STRUCT_MEMBER.vdpRegWindow         VDP_CMD_RS_WINDOW       | WINDOW_ADDR_\$VDP_WINDOW_ADDR
        INIT_STRUCT_MEMBER.vdpRegHScroll        VDP_CMD_RS_HSCROLL      | HSCROLL_ADDR_\$VDP_HSCROLL_ADDR
        INIT_STRUCT_MEMBER.vdpRegPlaneSize      VDP_CMD_RS_PLANE_SIZE   | PLANE_SIZE_H64_V32
        INIT_STRUCT_MEMBER.vdpRegWinX           VDP_CMD_RS_WIN_X
        INIT_STRUCT_MEMBER.vdpRegWinY           VDP_CMD_RS_WIN_Y
        INIT_STRUCT_MEMBER.vdpRegIncr           VDP_CMD_RS_AUTO_INC     | $02
        INIT_STRUCT_MEMBER.vdpRegBGCol          VDP_CMD_RS_BG_COLOR
        INIT_STRUCT_MEMBER.vdpRegHRate          VDP_CMD_RS_HINT_RATE    | $ff
    INIT_STRUCT_END

    INIT_STRUCT vdpMetrics
        INIT_STRUCT_MEMBER.vdpScreenWidth           320
        INIT_STRUCT_MEMBER.vdpScreenHeight          224
        INIT_STRUCT_MEMBER.vdpScreenWidthPatterns   40
        INIT_STRUCT_MEMBER.vdpScreenHeightPatterns  28
        INIT_STRUCT_MEMBER.vdpPlaneWidth            64 * 8
        INIT_STRUCT_MEMBER.vdpPlaneHeight           32 * 8
        INIT_STRUCT_MEMBER.vdpPlaneWidthPatterns    64
        INIT_STRUCT_MEMBER.vdpPlaneHeightPatterns   32
        INIT_STRUCT_MEMBER.vdpPlaneWidthShift       7       ; Adjusted for word sized shift
        INIT_STRUCT_MEMBER.vdpPlaneHeightShift      6
    INIT_STRUCT_END


;-------------------------------------------------
; Write cached register value to VDP
; ----------------
_VDP_REG_SYNC Macro vdpReg
        move.w  (vdpContext + \vdpReg), MEM_VDP_CTRL
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
        andi.b   #~\flag & $ff, (vdpContext + \vdpReg + 1)

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
; Initialize the VDP for first use
; ----------------
VDPInit:
        bsr _VDPUnlock
        bsr _VDPInitRegisters
        bsr vdpMetricsInit

        bsr VDPClearVRAM
        bsr VDPClearVSRAM
        bsr VDPClearCRAM
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
; ----------------
; Uses: a0
VDPVSyncWait:
        lea     MEM_VDP_CTRL + 1, a0

    .waitVBLankEndLoop:
        btst    #VDP_STATUS_VBLANK, (a0)
        bne     .waitVBLankEndLoop

    .waitVBlankStartLoop:
        btst    #VDP_STATUS_VBLANK, (a0)
        beq     .waitVBlankStartLoop
        rts


;-------------------------------------------------
; Set the plane size and update VDP metrics
; ----------------
; Input:
; - d0: plane size register value (word size)
; Uses: d0-d1/a0
VDPSetPlaneSize
_WRITE_PLANE_SIZE_METRICS Macro
            move.l  .planeMetrics(pc, d0), vdpPlaneWidth(a0)
            move.w  .planeMetrics + SIZE_LONG(pc, d0), vdpPlaneWidth + SIZE_LONG(a0)
        Endm

        move.w  #VDP_CMD_RS_PLANE_SIZE, d1
        move.b  d0, d1
        move.w  d1, MEM_VDP_CTRL
        lsr.b   #2, d1
        andi.b  #3, d0
        add.b   d0, d0
        add.b   d0, d0
        lea     vdpMetrics, a0
        _WRITE_PLANE_SIZE_METRICS

        move.b  d1, d0
        _WRITE_PLANE_SIZE_METRICS
        rts

    .planeMetrics:
        ;     | sizePixels | sizePatterns | shiftPatterns |
        dc.w     32 * 8,     32,            6
        dc.w     64 * 8,     64,            7
        dc.w     0,           0,            0  ; Invalid
        dc.w    128 * 8,    128,            8

    Purge _WRITE_PLANE_SIZE_METRICS


;-------------------------------------------------
; Set V30/240p (PAL) display mode
; ----------------
VDPSetV30CellMode:
        VDP_REG_SET_BITS vdpRegMode2, MODE2_V30_CELL
        move.w #240, (vdpMetrics + vdpScreenHeight)
        move.w #30, (vdpMetrics + vdpScreenHeightPatterns)
        rts


;-------------------------------------------------
; Set V28/228p display mode
; ----------------
VDPSetV28CellMode:
        VDP_REG_SET_BITS vdpRegMode2, MODE2_V30_CELL
        move.w #224, (vdpMetrics + vdpScreenHeight)
        move.w #28, (vdpMetrics + vdpScreenHeightPatterns)
        rts


;-------------------------------------------------
; Set H40/320px display mode
; ----------------
VDPSetH40CellMode:
        VDP_REG_SET_BITS vdpRegMode4, MODE4_H40_CELL
        move.w #320, (vdpMetrics + vdpScreenWidth)
        move.w #40, (vdpMetrics + vdpScreenWidthPatterns)
        rts


;-------------------------------------------------
; Set H32/256px display mode
; ----------------
VDPSetH32CellMode:
        VDP_REG_RESET_BITS vdpRegMode4, MODE4_H40_CELL
        move.w #256, (vdpMetrics + vdpScreenWidth)
        move.w #32, (vdpMetrics + vdpScreenWidthPatterns)
        rts


;-------------------------------------------------
; Enable display
; ----------------
VDPEnableDisplay:
        VDP_REG_SET_BITS vdpRegMode2, MODE2_DISPLAY_ENABLE
        rts


;-------------------------------------------------
; Disable display
; ----------------
VDPDisableDisplay:
        VDP_REG_RESET_BITS vdpRegMode2, MODE2_DISPLAY_ENABLE
        rts
