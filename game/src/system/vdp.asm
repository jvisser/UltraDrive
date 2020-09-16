;------------------------------------------------------------------------------------------
; Video Display Processor (VDP)
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; VDP related 68000 memory addresses
; ----------------
MEM_REG_VERSION     Equ $00a10000
MEM_TMSS            Equ $00a14000   ; TradeMark Security System

; VDP interface
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
; VDP register shadow variables
; ----------------

    ; VDPContext structure
    DEFINE_STRUCT VDPContext
        STRUCT_MEMBER w, vdpRegMode1
        STRUCT_MEMBER w, vdpRegMode2
        STRUCT_MEMBER w, vdpRegMode3
        STRUCT_MEMBER w, vdpRegMode4
        STRUCT_MEMBER w, vdpRegPlaneA
        STRUCT_MEMBER w, vdpRegPlaneB
        STRUCT_MEMBER w, vdpRegSprite
        STRUCT_MEMBER w, vdpRegWindow
        STRUCT_MEMBER w, vdpRegHScroll
        STRUCT_MEMBER w, vdpRegPlaneSize
        STRUCT_MEMBER w, vdpRegWinX
        STRUCT_MEMBER w, vdpRegWinY
        STRUCT_MEMBER w, vdpRegIncr
        STRUCT_MEMBER w, vdpRegBGCol
        STRUCT_MEMBER w, vdpRegHRate
    DEFINE_STRUCT_END

    ; Allocate VDPContext
    DEFINE_VAR FAST
        STRUCT VDPContext, vdpContext
    DEFINE_VAR_END

    ; VDPContext initial value (sensible defaults)
    INIT_STRUCT vdpContext
        INIT_STRUCT_MEMBER vdpRegMode1,     VDP_CMD_RS_MODE1
        INIT_STRUCT_MEMBER vdpRegMode2,     VDP_CMD_RS_MODE2
        INIT_STRUCT_MEMBER vdpRegMode3,     VDP_CMD_RS_MODE3
        INIT_STRUCT_MEMBER vdpRegMode4,     VDP_CMD_RS_MODE4        | MODE4_H40_CELL
        INIT_STRUCT_MEMBER vdpRegPlaneA,    VDP_CMD_RS_PLANE_A      | PLANE_A_ADDR_c000
        INIT_STRUCT_MEMBER vdpRegPlaneB,    VDP_CMD_RS_PLANE_B      | PLANE_B_ADDR_e000
        INIT_STRUCT_MEMBER vdpRegSprite,    VDP_CMD_RS_SPRITE       | SPRITE_ADDR_bc00
        INIT_STRUCT_MEMBER vdpRegWindow,    VDP_CMD_RS_WINDOW
        INIT_STRUCT_MEMBER vdpRegHScroll,   VDP_CMD_RS_HSCROLL      | HSCROLL_ADDR_b800
        INIT_STRUCT_MEMBER vdpRegPlaneSize, VDP_CMD_RS_PLANE_SIZE   | PLANE_SIZE_H64_V32
        INIT_STRUCT_MEMBER vdpRegWinX,      VDP_CMD_RS_WIN_X
        INIT_STRUCT_MEMBER vdpRegWinY,      VDP_CMD_RS_WIN_Y
        INIT_STRUCT_MEMBER vdpRegIncr,      VDP_CMD_RS_AUTO_INC     | $02
        INIT_STRUCT_MEMBER vdpRegBGCol,     VDP_CMD_RS_BG_COLOR
        INIT_STRUCT_MEMBER vdpRegHRate,     VDP_CMD_RS_HINT_RATE    | $ff
    INIT_STRUCT_END


;----------------------------------------------
; Initialize the VDP for first use
; ----------------
VDPInit:
        bsr VDPUnlock

        bsr VDPInitRegisters

        bsr VDPClearVRAM
        bsr VDPClearVSRAM
        bsr VDPClearCRAM

        rts


;-------------------------------------------------
; Unlock VDP by TradeMark Security System (TMSS) protocol
; ----------------
; Uses: d0
VDPUnlock:
        andi.b  #$0f, MEM_REG_VERSION
        beq.s   .noTMSS
        move.l  #'SEGA', MEM_TMSS

    .noTMSS:
        ; Read VDP control port. If unlock failed the code will not continue (buslock by IO Controller)
        move.w  MEM_VDP_CTRL, d0
        rts


;-------------------------------------------------
; Write initial VDP register values
; ----------------
VDPInitRegisters:
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
VRAM_CLEAR Macro vramAddrCommand, vramSize
            moveq   #0, d1
            move.w  #(\vramSize\ / SIZE_LONG) - 1, d0
            move.l  #\vramAddrCommand\, MEM_VDP_CTRL
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
        VRAM_CLEAR VDP_CMD_AS_VRAM_WRITE, VRAM_SIZE_BYTE
        rts


;-------------------------------------------------
; Clear Vertical Scroll RAM (VSRAM)
; ----------------
; Uses: d0-d1/a0
VDPClearVSRAM:
        VRAM_CLEAR VDP_CMD_AS_VSRAM_WRITE, VSRAM_SIZE_BYTE
        rts


;-------------------------------------------------
; Clear Color RAM (CRAM)
; ----------------
; Uses: d0-d1/a0
VDPClearCRAM:
        VRAM_CLEAR VDP_CMD_AS_CRAM_WRITE, CRAM_SIZE_BYTE
        rts
