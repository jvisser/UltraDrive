;------------------------------------------------------------------------------------------
; VDP control port commands
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_VDP_CMD_INC))
__SYSTEM_VDP_CMD_INC Equ 1

;-------------------------------------------------
; VDP address set commands
; ----------------
VDP_CMD_AS_VRAM_WRITE       Equ $40000000
VDP_CMD_AS_CRAM_WRITE       Equ $c0000000
VDP_CMD_AS_VSRAM_WRITE      Equ $40000010

VDP_CMD_AS_VRAM_READ        Equ $00000000
VDP_CMD_AS_CRAM_READ        Equ $00000020
VDP_CMD_AS_VSRAM_READ       Equ $00000010

VDP_CMD_AS_DMA              Equ $00000080   ; Or with a specific AS write command to mark it as the start of a DMA transfer to the specified target memory


;-------------------------------------------------
; VDP register set commands (or with register value before writing to VDP control port)
; ----------------
VDP_CMD_RS_MODE1            Equ $8000        ; Mode register #1
VDP_CMD_RS_MODE2            Equ $8100        ; Mode register #2
VDP_CMD_RS_MODE3            Equ $8b00        ; Mode register #3
VDP_CMD_RS_MODE4            Equ $8c00        ; Mode register #4
VDP_CMD_RS_PLANE_A          Equ $8200        ; Plane A table address
VDP_CMD_RS_PLANE_B          Equ $8400        ; Plane B table address
VDP_CMD_RS_SPRITE           Equ $8500        ; Sprite table address
VDP_CMD_RS_WINDOW           Equ $8300        ; Window table address
VDP_CMD_RS_HSCROLL          Equ $8d00        ; HScroll table address
VDP_CMD_RS_PLANE_SIZE       Equ $9000        ; Plane A and B size
VDP_CMD_RS_WIN_X            Equ $9100        ; Window X split position
VDP_CMD_RS_WIN_Y            Equ $9200        ; Window Y split position
VDP_CMD_RS_AUTO_INC         Equ $8f00        ; Autoincrement
VDP_CMD_RS_BG_COLOR         Equ $8700        ; Background color
VDP_CMD_RS_HINT_RATE        Equ $8a00        ; HBlank interrupt rate
VDP_CMD_RS_DMA_LEN_L        Equ $9300        ; DMA length (low)
VDP_CMD_RS_DMA_LEN_H        Equ $9400        ; DMA length (high)
VDP_CMD_RS_DMA_SRC_L        Equ $9500        ; DMA source (low)
VDP_CMD_RS_DMA_SRC_M        Equ $9600        ; DMA source (mid)
VDP_CMD_RS_DMA_SRC_H        Equ $9700        ; DMA source (high)

VDP_CMD_RS_DBG_LOG          Equ $9e00        ; Virtual register used for debug logging (GensKMod/Exodus emulator)
VDP_CMD_RS_DBG_BP           Equ $9d00        ; Virtual register used for software breakpoint  (GensKMod/Exodus emulator)
VDP_CMD_RS_DBG_TIMER        Equ $9f00        ; Virtual register used for starting/stopping a timer  (GensKMod/Exodus emulator)


;-------------------------------------------------
; VDP register specifics
; ----------------

; Mode 1 register
MODE1_HVCOUNTER_FREEZE      Equ $02          ; Freeze HV Counter on external interrupt
MODE1_HIGH_COLOR            Equ $04          ; Mega Drive 9 bit color mode (3 otherwise)
MODE1_HBLANK_ENABLE         Equ $10          ; Enable horizontal blank interrupt signal
MODE1_DISABLE_COLUMN0       Equ $20          ; Disable the first 8 pixel column (show background color)

; Mode 2 register
MODE2_MODE_5                Equ $04          ; Mega Drive display mode 5 (else Master System mode 4)
MODE2_V30_CELL              Equ $08          ; Enable vertical 30 cell mode (PAL only)
MODE2_DMA_ENABLE            Equ $10          ; Enable DMA
MODE2_VBLANK_ENABLE         Equ $20          ; Enable vertical blank interrupt signal
MODE2_DISPLAY_ENABLE        Equ $40          ; Enable display

; Mode 3 register
MODE3_HSCROLL_FULL          Equ $00          ; Full screen horizontal scroll mode (default).
MODE3_HSCROLL_CELL          Equ $02          ; Per cell (8 pixels) horizontal scroll mode
MODE3_HSCROLL_LINE          Equ $03          ; Per line horizontal scroll mode
MODE3_HSCROLL_MASK          Equ $03          ; Bitmask isolating HSCROLL bits
MODE3_VSCROLL_CELL          Equ $04          ; Enable per 2 cell (16 pixels) vertical scroll mode
MODE3_EXT_INT_ENABLE        Equ $08          ; Enable external interrupt (68000 level 2)

; Mode 4 register
MODE4_H40_CELL              Equ $81          ; Enable horizontal 40 cell mode
MODE4_INTERLACE_NONE        Equ $00          ; No interlaced video output (default).
MODE4_INTERLACE_ENABLE      Equ $02          ; Enable 240i
MODE4_INTERLACE_DOUBLE_RES  Equ $06          ; Enable 480i
MODE4_INTERLACE_MASK        Equ $06          ; Bitmask isolating interlace mode bits
MODE4_ENABLE_SH             Equ $08          ; Enable shadow and highlight mode

; Plane size register (both planes)
PLANE_SIZE_H32_V32          Equ $00          ; 256 * 256 plane size
PLANE_SIZE_H32_V64          Equ $10          ; 256 * 512 plane size
PLANE_SIZE_H64_V32          Equ $01          ; 512 * 256 plane size
PLANE_SIZE_H64_V64          Equ $11          ; 512 * 512 plane size
PLANE_SIZE_H32_V128         Equ $30          ; 256 * 1024 plane size
PLANE_SIZE_H128_V32         Equ $03          ; 1024 * 256 plane size

; Window position registers
WIN_X_RIGHT                 Equ $80          ; Show window on the right
WIN_Y_DOWN                  Equ $80          ; Show window from bottom

; DMA source high register values for fill/copy dma mode
DMA_SRC_H_FILL              Equ $80
DMA_SRC_H_COPY              Equ $c0

; Plane A address register possible values
PLANE_A_ADDR_0000           Equ $00
PLANE_A_ADDR_2000           Equ ($2000 >> 10)
PLANE_A_ADDR_4000           Equ ($4000 >> 10)
PLANE_A_ADDR_6000           Equ ($6000 >> 10)
PLANE_A_ADDR_8000           Equ ($8000 >> 10)
PLANE_A_ADDR_A000           Equ ($a000 >> 10)
PLANE_A_ADDR_C000           Equ ($c000 >> 10)
PLANE_A_ADDR_E000           Equ ($e000 >> 10)

; Plane B address register possible values
PLANE_B_ADDR_0000           Equ $00
PLANE_B_ADDR_2000           Equ ($2000 >> 13)
PLANE_B_ADDR_4000           Equ ($4000 >> 13)
PLANE_B_ADDR_6000           Equ ($6000 >> 13)
PLANE_B_ADDR_8000           Equ ($8000 >> 13)
PLANE_B_ADDR_A000           Equ ($a000 >> 13)
PLANE_B_ADDR_C000           Equ ($c000 >> 13)
PLANE_B_ADDR_E000           Equ ($e000 >> 13)

; Sprite address register possible values (40 cell mode)
SPRITE_ADDR_0000            Equ $00
SPRITE_ADDR_0400            Equ ($0400 >> 9)
SPRITE_ADDR_0800            Equ ($0800 >> 9)
SPRITE_ADDR_0C00            Equ ($0c00 >> 9)
SPRITE_ADDR_1000            Equ ($1000 >> 9)
SPRITE_ADDR_1400            Equ ($1400 >> 9)
SPRITE_ADDR_1800            Equ ($1800 >> 9)
SPRITE_ADDR_1C00            Equ ($1c00 >> 9)
SPRITE_ADDR_2000            Equ ($2000 >> 9)
SPRITE_ADDR_2400            Equ ($2400 >> 9)
SPRITE_ADDR_2800            Equ ($2800 >> 9)
SPRITE_ADDR_2C00            Equ ($2c00 >> 9)
SPRITE_ADDR_3000            Equ ($3000 >> 9)
SPRITE_ADDR_3400            Equ ($3400 >> 9)
SPRITE_ADDR_3800            Equ ($3800 >> 9)
SPRITE_ADDR_3C00            Equ ($3c00 >> 9)
SPRITE_ADDR_4000            Equ ($4000 >> 9)
SPRITE_ADDR_4400            Equ ($4400 >> 9)
SPRITE_ADDR_4800            Equ ($4800 >> 9)
SPRITE_ADDR_4C00            Equ ($4c00 >> 9)
SPRITE_ADDR_5000            Equ ($5000 >> 9)
SPRITE_ADDR_5400            Equ ($5400 >> 9)
SPRITE_ADDR_5800            Equ ($5800 >> 9)
SPRITE_ADDR_5C00            Equ ($5c00 >> 9)
SPRITE_ADDR_6000            Equ ($6000 >> 9)
SPRITE_ADDR_6400            Equ ($6400 >> 9)
SPRITE_ADDR_6800            Equ ($6800 >> 9)
SPRITE_ADDR_6C00            Equ ($6c00 >> 9)
SPRITE_ADDR_7000            Equ ($7000 >> 9)
SPRITE_ADDR_7400            Equ ($7400 >> 9)
SPRITE_ADDR_7800            Equ ($7800 >> 9)
SPRITE_ADDR_7C00            Equ ($7c00 >> 9)
SPRITE_ADDR_8000            Equ ($8000 >> 9)
SPRITE_ADDR_8400            Equ ($8400 >> 9)
SPRITE_ADDR_8800            Equ ($8800 >> 9)
SPRITE_ADDR_8C00            Equ ($8c00 >> 9)
SPRITE_ADDR_9000            Equ ($9000 >> 9)
SPRITE_ADDR_9400            Equ ($9400 >> 9)
SPRITE_ADDR_9800            Equ ($9800 >> 9)
SPRITE_ADDR_9C00            Equ ($9c00 >> 9)
SPRITE_ADDR_A000            Equ ($a000 >> 9)
SPRITE_ADDR_A400            Equ ($a400 >> 9)
SPRITE_ADDR_A800            Equ ($a800 >> 9)
SPRITE_ADDR_AC00            Equ ($ac00 >> 9)
SPRITE_ADDR_B000            Equ ($b000 >> 9)
SPRITE_ADDR_B400            Equ ($b400 >> 9)
SPRITE_ADDR_B800            Equ ($b800 >> 9)
SPRITE_ADDR_BC00            Equ ($bc00 >> 9)
SPRITE_ADDR_C000            Equ ($c000 >> 9)
SPRITE_ADDR_C400            Equ ($c400 >> 9)
SPRITE_ADDR_C800            Equ ($c800 >> 9)
SPRITE_ADDR_CC00            Equ ($cc00 >> 9)
SPRITE_ADDR_D000            Equ ($d000 >> 9)
SPRITE_ADDR_D400            Equ ($d400 >> 9)
SPRITE_ADDR_D800            Equ ($d800 >> 9)
SPRITE_ADDR_DC00            Equ ($dc00 >> 9)
SPRITE_ADDR_E000            Equ ($e000 >> 9)
SPRITE_ADDR_E400            Equ ($e400 >> 9)
SPRITE_ADDR_E800            Equ ($e800 >> 9)
SPRITE_ADDR_EC00            Equ ($ec00 >> 9)
SPRITE_ADDR_F000            Equ ($f000 >> 9)
SPRITE_ADDR_F400            Equ ($f400 >> 9)
SPRITE_ADDR_F800            Equ ($f800 >> 9)
SPRITE_ADDR_FC00            Equ ($fc00 >> 9)

; Window address register possible values (40 cell mode)
WINDOW_ADDR_0000            Equ $00
WINDOW_ADDR_1000            Equ ($1000 >> 10)
WINDOW_ADDR_2000            Equ ($2000 >> 10)
WINDOW_ADDR_3000            Equ ($3000 >> 10)
WINDOW_ADDR_4000            Equ ($4000 >> 10)
WINDOW_ADDR_5000            Equ ($5000 >> 10)
WINDOW_ADDR_6000            Equ ($6000 >> 10)
WINDOW_ADDR_7000            Equ ($7000 >> 10)
WINDOW_ADDR_8000            Equ ($8000 >> 10)
WINDOW_ADDR_9000            Equ ($9000 >> 10)
WINDOW_ADDR_A000            Equ ($a000 >> 10)
WINDOW_ADDR_B000            Equ ($b000 >> 10)
WINDOW_ADDR_C000            Equ ($c000 >> 10)
WINDOW_ADDR_D000            Equ ($d000 >> 10)
WINDOW_ADDR_E000            Equ ($e000 >> 10)
WINDOW_ADDR_F000            Equ ($f000 >> 10)

; HScroll register possible values
HSCROLL_ADDR_0000           Equ $00
HSCROLL_ADDR_0400           Equ ($0400 >> 10)
HSCROLL_ADDR_0800           Equ ($0800 >> 10)
HSCROLL_ADDR_0C00           Equ ($0c00 >> 10)
HSCROLL_ADDR_1000           Equ ($1000 >> 10)
HSCROLL_ADDR_1400           Equ ($1400 >> 10)
HSCROLL_ADDR_1800           Equ ($1800 >> 10)
HSCROLL_ADDR_1C00           Equ ($1c00 >> 10)
HSCROLL_ADDR_2000           Equ ($2000 >> 10)
HSCROLL_ADDR_2400           Equ ($2400 >> 10)
HSCROLL_ADDR_2800           Equ ($2800 >> 10)
HSCROLL_ADDR_2C00           Equ ($2c00 >> 10)
HSCROLL_ADDR_3000           Equ ($3000 >> 10)
HSCROLL_ADDR_3400           Equ ($3400 >> 10)
HSCROLL_ADDR_3800           Equ ($3800 >> 10)
HSCROLL_ADDR_3C00           Equ ($3c00 >> 10)
HSCROLL_ADDR_4000           Equ ($4000 >> 10)
HSCROLL_ADDR_4400           Equ ($4400 >> 10)
HSCROLL_ADDR_4800           Equ ($4800 >> 10)
HSCROLL_ADDR_4C00           Equ ($4c00 >> 10)
HSCROLL_ADDR_5000           Equ ($5000 >> 10)
HSCROLL_ADDR_5400           Equ ($5400 >> 10)
HSCROLL_ADDR_5800           Equ ($5800 >> 10)
HSCROLL_ADDR_5C00           Equ ($5c00 >> 10)
HSCROLL_ADDR_6000           Equ ($6000 >> 10)
HSCROLL_ADDR_6400           Equ ($6400 >> 10)
HSCROLL_ADDR_6800           Equ ($6800 >> 10)
HSCROLL_ADDR_6C00           Equ ($6c00 >> 10)
HSCROLL_ADDR_7000           Equ ($7000 >> 10)
HSCROLL_ADDR_7400           Equ ($7400 >> 10)
HSCROLL_ADDR_7800           Equ ($7800 >> 10)
HSCROLL_ADDR_7C00           Equ ($7c00 >> 10)
HSCROLL_ADDR_8000           Equ ($8000 >> 10)
HSCROLL_ADDR_8400           Equ ($8400 >> 10)
HSCROLL_ADDR_8800           Equ ($8800 >> 10)
HSCROLL_ADDR_8C00           Equ ($8c00 >> 10)
HSCROLL_ADDR_9000           Equ ($9000 >> 10)
HSCROLL_ADDR_9400           Equ ($9400 >> 10)
HSCROLL_ADDR_9800           Equ ($9800 >> 10)
HSCROLL_ADDR_9C00           Equ ($9c00 >> 10)
HSCROLL_ADDR_A000           Equ ($a000 >> 10)
HSCROLL_ADDR_A400           Equ ($a400 >> 10)
HSCROLL_ADDR_A800           Equ ($a800 >> 10)
HSCROLL_ADDR_AC00           Equ ($ac00 >> 10)
HSCROLL_ADDR_B000           Equ ($b000 >> 10)
HSCROLL_ADDR_B400           Equ ($b400 >> 10)
HSCROLL_ADDR_B800           Equ ($b800 >> 10)
HSCROLL_ADDR_BC00           Equ ($bc00 >> 10)
HSCROLL_ADDR_C000           Equ ($c000 >> 10)
HSCROLL_ADDR_C400           Equ ($c400 >> 10)
HSCROLL_ADDR_C800           Equ ($c800 >> 10)
HSCROLL_ADDR_CC00           Equ ($cc00 >> 10)
HSCROLL_ADDR_D000           Equ ($d000 >> 10)
HSCROLL_ADDR_D400           Equ ($d400 >> 10)
HSCROLL_ADDR_D800           Equ ($d800 >> 10)
HSCROLL_ADDR_DC00           Equ ($dc00 >> 10)
HSCROLL_ADDR_E000           Equ ($e000 >> 10)
HSCROLL_ADDR_E400           Equ ($e400 >> 10)
HSCROLL_ADDR_E800           Equ ($e800 >> 10)
HSCROLL_ADDR_EC00           Equ ($ec00 >> 10)
HSCROLL_ADDR_F000           Equ ($f000 >> 10)
HSCROLL_ADDR_F400           Equ ($f400 >> 10)
HSCROLL_ADDR_F800           Equ ($f800 >> 10)
HSCROLL_ADDR_FC00           Equ ($fc00 >> 10)

    EndIf
