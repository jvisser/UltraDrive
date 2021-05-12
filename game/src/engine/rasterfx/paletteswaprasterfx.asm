;------------------------------------------------------------------------------------------
; Mid screen palette swap raster effect. Uses the palettes from the loaded tileset. And calculates the screenposition of the swap based on the viewport position.
;
; Supports 2 modes:
; - Look up based (no cram dots): Will transfer the palette over multiple lines using a color transition lookup table indicating what colors and in which order to transfer them (Sonic 3 algorithm).
; - DMA based (cram dots): Brute force DMA transfer, used when there is no color transition table
;
; TODO: Remove direct Tileset dependency (Move required data to PaletteSwapRasterEffectConfiguration)
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Palette swap raster effect structs
; ----------------
    DEFINE_STRUCT PaletteSwapRasterEffectConfiguration
        STRUCT_MEMBER.l psrecVerticalPosition                           ; Address of the variable containing the vertical absolute position
    DEFINE_STRUCT_END

    DEFINE_STRUCT PaletteSwapRasterEffectState
        STRUCT_MEMBER.w psresScreenLine                                 ; currently used screen relative position of psrecVerticalPosition
        STRUCT_MEMBER.l psresStartPalette                               ; currently used starting palette
        STRUCT_MEMBER.w psresMaxScreenLine                              ; Max screenline the hint can occur at (to prevent vblank conflicts)
        STRUCT_MEMBER.w psresMinScreenLine                              ; Min screenline the hint can occur at
        STRUCT_MEMBER.w psresHIntScreenLineOffset                       ; Line difference between hint line and the visual effect actually appearing
        STRUCT_MEMBER.w psresHIntPosition                               ; Horizontal interrupt line (vdpRegHRate register value)
        STRUCT_MEMBER.b psresHIntHandled                                ; Used to prevent multiple hblank interrupts per frame
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Palette swap RasterEffect
    ; ----------------
    ; struct RasterEffect
    paletteSwapRasterEffect:
        ; .rfxSetupFrame
        dc.l    _PaletteSwapRasterEffectSetupFrame
        ; .rfxPrepareNextFrame
        dc.l    _PaletteSwapRasterEffectPrepareNextFrame
        ; .rfxResetFrame
        dc.l    _PaletteSwapRasterEffectResetFrame
        ; .rfxInit
        dc.l    _PaletteSwapRasterEffectInit
        ; .rfxDestroy
        dc.l    _PaletteSwapRasterEffectDestroy

    ;-------------------------------------------------
    ; Allocate PaletteSwapRasterEffectState in raster effect memory pool
    ; ----------------
paletteSwapRasterEffectState Equ rasterEffectMemoryPool


;-------------------------------------------------
; Install a raster effect
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectInit:
        TILESET_GET d0
        bne .tileSetOk

            OS_KILL 'No tileset loaded!'

    .tileSetOk:
        movea.l d0, a1                                                  ; a1 = tileset address
        tst.l   tsAlternativePaletteAddress(a1)
        bne     .paletteOk

            OS_KILL 'No alternative palette available in tileset!'

    .paletteOk:

        tst.l   tsColorTransitionTableAddress(a1)
        beq     .useDMA

            DEBUG_MSG 'Palette swap raster effect using color transition table'

            ; d0 = psresHIntScreenLineOffset = 1: one line for the setup process
            moveq  #1, d0

            ; psresMaxScreenLine = vdpScreenHeight - psresHIntScreenLineOffset - transitionTable.size - 2 (Add 2 lines for safety to prevent vblank conflicts)
            move.w  (vdpMetrics + vdpScreenHeight), d1
            movea.l tsColorTransitionTableAddress(a1), a2
            sub.w   tscttCount(a2), d1
            sub.w   d0, d1
            subq.w  #2, d1

            move.w  d0, (paletteSwapRasterEffectState + psresHIntScreenLineOffset)
            move.w  d1, (paletteSwapRasterEffectState + psresMaxScreenLine)

            ; Return interrupt handler address in a3
            lea _PaletteSwapRasterEffectColorTransitionHblank, a3
        bra     .setupPaletteSwapMethodDone

    .useDMA:

            DEBUG_MSG 'Palette swap raster effect using DMA'

            ; d0 = psresHIntScreenLineOffset = 0
            moveq  #0, d0

            ; psresMaxScreenLine = vdpScreenHeight - psresHIntScreenLineOffset - 6 (Add 4 lines for DMA and 2 lines for safety to prevent vblank conflicts)
            move.w  (vdpMetrics + vdpScreenHeight), d1
            sub.w   d0, d1
            subq.w  #6, d1

            move.w  d0, (paletteSwapRasterEffectState + psresHIntScreenLineOffset)
            move.w  d1, (paletteSwapRasterEffectState + psresMaxScreenLine)

            ; Return interrupt handler address in a3
            lea _PaletteSwapRasterEffectDMAHblank, a3

    .setupPaletteSwapMethodDone:

            ; psresMinScreenLine = 1 + psresHIntScreenLineOffset
            move.w  (paletteSwapRasterEffectState + psresHIntScreenLineOffset), d0
            addq.w  #1, d0
            move.w  d0, (paletteSwapRasterEffectState + psresMinScreenLine)

            ; psresScreenLine = psrecVerticalPosition - viewport.y
            move.w  psrecVerticalPosition(a0), d0
            VIEWPORT_GET_Y d1
            sub.w   d1, d0
            move.w  d0, (paletteSwapRasterEffectState + psresScreenLine)

            ; psresStartPalette = (psresScreenLine < psresMinScreenLine) ? tsAlternativePaletteAddress : tsPaletteAddress
            cmp.w   (paletteSwapRasterEffectState + psresMinScreenLine), d0
            bge     .normalPalette
                move.l  tsAlternativePaletteAddress(a1), (paletteSwapRasterEffectState + psresStartPalette)
            bra .paletteSelectDone
        .normalPalette:
                move.l  tsPaletteAddress(a1), (paletteSwapRasterEffectState + psresStartPalette)
        .paletteSelectDone:

            ; psresHIntPosition = $ff (disable hint, setup by prepareNextFrame)
            move.w  #$ff, (paletteSwapRasterEffectState + psresHIntPosition)

            ; VDPDMAQueueAddCommandList(psresStartPalette)
            movea.l (paletteSwapRasterEffectState + psresStartPalette), a0
            jsr     VDPDMAQueueAddCommandList

            ; Return HBLank interrupt handler address
            movea.l a3, a0
        rts


;-------------------------------------------------
; Install a raster effect
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectDestroy:
        ; TODO: Queue default palette for DMA
        DEBUG_MSG '_PaletteSwapRasterEffectDestroy'
        rts


;-------------------------------------------------
; Install a raster effect
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectPrepareNextFrame:

        ; Determine current screen line
        move.w  psrecVerticalPosition(a0), d0
        VIEWPORT_GET_Y d1
        sub.w   d1, d0                                                      ; d0 = current screen line

        ; if (screenline < psresMinScreenLine)
        cmp.w   (paletteSwapRasterEffectState + psresMinScreenLine), d0
        bge     .checkMaxScreenLine

            ; if (psresScreenLine >= psresMinScreenLine)
            move.w  (paletteSwapRasterEffectState + psresScreenLine), d1
            cmp.w   (paletteSwapRasterEffectState + psresMinScreenLine), d1
            blt .skipTopPaletteDMA

                TILESET_GET a0

                ; Starting palette changed
                movea.l tsAlternativePaletteAddress(a0), a0
                move.l a0, (paletteSwapRasterEffectState + psresStartPalette)

                ; Queue palette change
                jsr VDPDMAQueueAddCommandList

        .skipTopPaletteDMA:

            ; Disable hint
            move.w  #$ff, (paletteSwapRasterEffectState + psresHIntPosition)

        bra     .screenLineCheckDone
    .checkMaxScreenLine:
        ; else if (screenline > psresMaxScreenLine)
        cmp.w   (paletteSwapRasterEffectState + psresMaxScreenLine), d0
        ble     .midScreenLine

            ; if (psresScreenLine <= maxScreenLine)
            move.w  (paletteSwapRasterEffectState + psresScreenLine), d1
            cmp.w   (paletteSwapRasterEffectState + psresMaxScreenLine), d1
            bgt .skipBottomPaletteDMA

                TILESET_GET a0

                ; Starting palette changed
                movea.l tsPaletteAddress(a0), a0
                move.l a0, (paletteSwapRasterEffectState + psresStartPalette)

                ; Queue palette change
                jsr VDPDMAQueueAddCommandList

        .skipBottomPaletteDMA:

            ; Disable hint
            move.w  #$ff, (paletteSwapRasterEffectState + psresHIntPosition)

        bra     .screenLineCheckDone
        ; else
    .midScreenLine:

        TILESET_GET a0

        ; Always refresh palette for when mid screen
        movea.l tsPaletteAddress(a0), a0
        move.l a0, (paletteSwapRasterEffectState + psresStartPalette)

        ; Queue palette change
        jsr VDPDMAQueueAddCommandList

        ; Set hint to screen line position
        move.w  d0, d1
        sub.w   (paletteSwapRasterEffectState + psresHIntScreenLineOffset), d1
        move.w  d1, (paletteSwapRasterEffectState + psresHIntPosition)

    .screenLineCheckDone:

        move.w  d0, (paletteSwapRasterEffectState + psresScreenLine)
        rts


;-------------------------------------------------
; Just transfer the current starting palette directly
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectResetFrame:
        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE (paletteSwapRasterEffectState + psresStartPalette)
        rts


;-------------------------------------------------
; Install a raster effect
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectSetupFrame:
        ; Clear interrupt handled state
        clr.b   (paletteSwapRasterEffectState + psresHIntHandled)

        ; Setup horizontal interrupt position
        move.w  #VDP_CMD_RS_HINT_RATE, d0
        or.w    (paletteSwapRasterEffectState + psresHIntPosition), d0
        move.w  d0, MEM_VDP_CTRL
        rts


;-------------------------------------------------
; Color transition table based palette swap hblank handler (Based on Sonic 3's implementation)
; ----------------
_PaletteSwapRasterEffectColorTransitionHblank:
        tst.b   (paletteSwapRasterEffectState + psresHIntHandled)
        bne     .handled

            seq     (paletteSwapRasterEffectState + psresHIntHandled)

            ; Disable hint after the next occurence
            VDP_REG_SET vdpRegHRate, $ff

            PUSHM   d0-d1/a0-a4

            ; Request Z80 as z80->68000 accesses could mess up the timing (actually just waiting for BUS_REQ could also do that :/)
            Z80_GET_BUS

            ; Load adresses
            TILESET_GET a0
            movea.l tsColorTransitionTableAddress(a0), a1
            movea.l tsAlternativePaletteAddress(a0), a0
            adda.l  #tsColors, a0
            lea     MEM_VDP_DATA, a2
            lea     MEM_VDP_CTRL, a3

            ; Wait until the end of line (66 cycles)
            moveq   #4, d1      ; 4 cycles
        .wait1:
            dbra    d1, .wait1  ; 4 * 10 + 14 cycles
            nop                 ; 4 cycles
            nop                 ; 4 cycles

            moveq   #0, d1
            move.w  (a1)+, d0                           ; d0 = number of color triplets in color transition table
            subq.w  #1, d0                              ; d0 = line counter
        .lineLoop:

                ; Get color offset of triplet
                move.w (a1)+, d1                        ; d1 = offset of color triplet

                ; Get color address
                lea (a0, d1), a4                        ; a4 = RAM address of color triplet

                ; Set VDP access mode to CRAM write at color triplet CRAM address
                addi.w  #$c000, d1
                swap    d1                              ; d1 = "write cram[index]" VDP command
                move.l  d1, (a3)

                ; Write color
                move.l  (a4)+, (a2)
                move.w  (a4)+, (a2)

                swap    d1

                ; Wait until the end of line (392 cycles)
                moveq   #37, d1     ; 4 cycles
            .wait2:
                dbra    d1, .wait2  ; 37 * 10 + 14 cycles
                nop                 ; 4 cycles

            dbra d0, .lineLoop

            Z80_RELEASE

            POPM   d0-d1/a0-a4

    .handled:
        rte


;-------------------------------------------------
; DMA based palette swap hblank handler
; ----------------
_PaletteSwapRasterEffectDMAHblank:
        tst.b   (paletteSwapRasterEffectState + psresHIntHandled)
        bne     .handled

            seq     (paletteSwapRasterEffectState + psresHIntHandled)

            ; Disable hint after the next occurence
            VDP_REG_SET vdpRegHRate, $ff

            PUSHM a0-a1

                TILESET_GET a0

                VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE tsAlternativePaletteAddress(a0)

            POPM a0-a1

    .handled:
        rte
