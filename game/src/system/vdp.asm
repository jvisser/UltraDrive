;------------------------------------------------------------------------------------------
; Video Display Processor (VDP)
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'
    Include './system/include/init.inc'
    Include './system/include/vdp.inc'
    Include './system/include/memory.inc'

;-------------------------------------------------
; VDP state
; ----------------
    ; Allocate VDPContext
    DEFINE_VAR SHORT
        VAR.VDPContext  vdpContext
        VAR.VDPMetrics  vdpMetrics
    DEFINE_VAR_END

    ; VDPContext initial values
    INIT_STRUCT vdpContext
        INIT_STRUCT_MEMBER.vdpRegMode1          VDP_CMD_RS_MODE1        | MODE1_HIGH_COLOR
        INIT_STRUCT_MEMBER.vdpRegMode2          VDP_CMD_RS_MODE2        | MODE2_MODE_5 | MODE2_DMA_ENABLE | MODE2_VBLANK_ENABLE
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
        INIT_STRUCT_MEMBER.screenWidth           320
        INIT_STRUCT_MEMBER.screenHeight          224
        INIT_STRUCT_MEMBER.screenWidthPatterns   40
        INIT_STRUCT_MEMBER.screenHeightPatterns  28
        INIT_STRUCT_MEMBER.planeWidth            64 * 8
        INIT_STRUCT_MEMBER.planeHeight           32 * 8
        INIT_STRUCT_MEMBER.planeWidthPatterns    64
        INIT_STRUCT_MEMBER.planeHeightPatterns   32
        INIT_STRUCT_MEMBER.planeWidthShift       7       ; Adjusted for word sized shift
        INIT_STRUCT_MEMBER.planeHeightShift      6
    INIT_STRUCT_END


;----------------------------------------------
; Initialize the VDP for first use
; ----------------
 SYS_INIT VDPInit
        bsr _VDPUnlock
        bsr _VDPInitRegisters

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
; Wait for the vertical blanking period to end
; ----------------
; Uses: a0
VDPVSyncEndWait:
        lea     MEM_VDP_CTRL + 1, a0

    .waitVBLankEndLoop:
        btst    #VDP_STATUS_VBLANK, (a0)
        bne     .waitVBLankEndLoop
        rts


;-------------------------------------------------
; Set the plane size and update VDP metrics
; ----------------
; Input:
; - d0: plane size register value (word size)
; Uses: d0-d1/a0
VDPSetPlaneSize
_WRITE_PLANE_SIZE_METRICS Macro
            move.l  .planeMetrics(pc, d0), VDPMetrics_planeWidth(a0)
            move.w  .planeMetrics + SIZE_LONG(pc, d0), VDPMetrics_planeWidth + SIZE_LONG(a0)
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
        move.w #240, (vdpMetrics + VDPMetrics_screenHeight)
        move.w #30, (vdpMetrics + VDPMetrics_screenHeightPatterns)
        rts


;-------------------------------------------------
; Set V28/228p display mode
; ----------------
VDPSetV28CellMode:
        VDP_REG_SET_BITS vdpRegMode2, MODE2_V30_CELL
        move.w #224, (vdpMetrics + VDPMetrics_screenHeight)
        move.w #28, (vdpMetrics + VDPMetrics_screenHeightPatterns)
        rts


;-------------------------------------------------
; Set H40/320px display mode
; ----------------
VDPSetH40CellMode:
        VDP_REG_SET_BITS vdpRegMode4, MODE4_H40_CELL
        move.w #320, (vdpMetrics + VDPMetrics_screenWidth)
        move.w #40, (vdpMetrics + VDPMetrics_screenWidthPatterns)
        rts


;-------------------------------------------------
; Set H32/256px display mode
; ----------------
VDPSetH32CellMode:
        VDP_REG_RESET_BITS vdpRegMode4, MODE4_H40_CELL
        move.w #256, (vdpMetrics + VDPMetrics_screenWidth)
        move.w #32, (vdpMetrics + VDPMetrics_screenWidthPatterns)
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
