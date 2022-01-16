;------------------------------------------------------------------------------------------
; Mid screen palette swap raster effect. Uses the palettes from the loaded tileset. And calculates the screenposition of the swap based on the viewport position.
;
; Supports 2 modes:
; - Look up based (no cram dots): Will transfer the palette over multiple lines using a color transition lookup table indicating what colors and in which order to transfer them (Sonic 3 algorithm).
; - DMA based (cram dots): Brute force DMA transfer, used when there is no color transition table
;
; TODO: Remove direct Tileset dependency (Move required data to PaletteSwapRasterEffectConfiguration)
;------------------------------------------------------------------------------------------

    Include './common/include/debug.inc'

    Include './system/include/m68k.inc'
    Include './system/include/z80.inc'
    Include './system/include/memory.inc'
    Include './system/include/vdp.inc'

;-------------------------------------------------
; Palette swap raster effect structs
; ----------------
    DEFINE_STRUCT PaletteSwapRasterEffectConfiguration
        STRUCT_MEMBER.l verticalPosition                                ; Address of the variable containing the vertical absolute position
    DEFINE_STRUCT_END

    DEFINE_STRUCT PaletteSwapRasterEffectState
        STRUCT_MEMBER.w screenLine                                      ; currently used screen relative position of verticalPosition
        STRUCT_MEMBER.l startPalette                                    ; currently used starting palette
        STRUCT_MEMBER.w maxScreenLine                                   ; Max screenline the hint can occur at (to prevent vblank conflicts)
        STRUCT_MEMBER.w minScreenLine                                   ; Min screenline the hint can occur at
        STRUCT_MEMBER.w hIntScreenLineOffset                            ; Line difference between hint line and the visual effect actually appearing
        STRUCT_MEMBER.w hIntPosition                                    ; Horizontal interrupt line (vdpRegHRate register value)
        STRUCT_MEMBER.b hIntHandled                                     ; Used to prevent multiple hblank interrupts per frame
    DEFINE_STRUCT_END

    ;-------------------------------------------------
    ; Palette swap RasterEffect
    ; ----------------
    ; struct RasterEffect
    paletteSwapRasterEffect:
        ; .setupFrame
        dc.l    _PaletteSwapRasterEffectSetupFrame
        ; .prepareNextFrame
        dc.l    _PaletteSwapRasterEffectPrepareNextFrame
        ; .resetFrame
        dc.l    _PaletteSwapRasterEffectResetFrame
        ; .init
        dc.l    _PaletteSwapRasterEffectInit
        ; .destroy
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
        bne.s .tileSetOk

            OS_KILL 'No tileset loaded!'

    .tileSetOk:
        movea.l d0, a1                                                  ; a1 = tileset address
        tst.l   Tileset_alternativePaletteAddress(a1)
        bne.s   .paletteOk

            OS_KILL 'No alternative palette available in tileset!'

    .paletteOk:

        tst.l   Tileset_colorTransitionTableAddress(a1)
        beq.s   .useDMA

            DEBUG_MSG 'Palette swap raster effect using color transition table'

            ; d0 = hIntScreenLineOffset = 1: one line for the setup process
            moveq  #1, d0

            ; PaletteSwapRasterEffectState_maxScreenLine = VDPMetrics_screenHeight - hIntScreenLineOffset - transitionTable.size - 2 (Add 2 lines for safety to prevent vblank conflicts)
            move.w  (vdpMetrics + VDPMetrics_screenHeight), d1
            movea.l Tileset_colorTransitionTableAddress(a1), a2
            sub.w   TilesetColorTransitionTable_count(a2), d1
            sub.w   d0, d1
            subq.w  #2, d1

            move.w  d0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntScreenLineOffset)
            move.w  d1, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_maxScreenLine)

            ; Return interrupt handler address in a3
            lea _PaletteSwapRasterEffectColorTransitionHblank, a3
        bra.s   .setupPaletteSwapMethodDone

    .useDMA:

            DEBUG_MSG 'Palette swap raster effect using DMA'

            ; d0 = PaletteSwapRasterEffectState_hIntScreenLineOffset = 0
            moveq  #0, d0

            ; maxScreenLine = VDPMetrics_screenHeight - hIntScreenLineOffset - 6 (Add 4 lines for DMA and 2 lines for safety to prevent vblank conflicts)
            move.w  (vdpMetrics + VDPMetrics_screenHeight), d1
            sub.w   d0, d1
            subq.w  #6, d1

            move.w  d0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntScreenLineOffset)
            move.w  d1, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_maxScreenLine)

            ; Return interrupt handler address in a3
            lea _PaletteSwapRasterEffectDMAHblank, a3

    .setupPaletteSwapMethodDone:

            ; minScreenLine = 1 + hIntScreenLineOffset
            move.w  (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntScreenLineOffset), d0
            addq.w  #1, d0
            move.w  d0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_minScreenLine)

            ; screenLine = verticalPosition - viewport.y
            move.w  PaletteSwapRasterEffectConfiguration_verticalPosition(a0), d0
            VIEWPORT_GET_Y d1
            sub.w   d1, d0
            move.w  d0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_screenLine)

            ; startPalette = (screenLine < minScreenLine) ? Tileset_alternativePaletteAddress : Tileset_paletteAddress
            cmp.w   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_minScreenLine), d0
            bge.s   .normalPalette
                move.l  Tileset_alternativePaletteAddress(a1), (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_startPalette)
            bra.s   .paletteSelectDone
        .normalPalette:
                move.l  Tileset_paletteAddress(a1), (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_startPalette)
        .paletteSelectDone:

            ; hIntPosition = $ff (disable hint, setup by prepareNextFrame)
            move.w  #$ff, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntPosition)

            ; VDPDMAQueueAddCommandList(startPalette)
            movea.l (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_startPalette), a0
            jsr     VDPDMAQueueAddCommandList

            ; Return HBLank interrupt handler address
            movea.l a3, a0
        rts


;-------------------------------------------------
; Restore default palette
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectDestroy:
        TILESET_GET a1
        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE Tileset_paletteAddress(a1)
        rts


;-------------------------------------------------
; Install a raster effect
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectPrepareNextFrame:

        ; Determine current screen line
        move.w  PaletteSwapRasterEffectConfiguration_verticalPosition(a0), d0
        VIEWPORT_GET_Y d1
        sub.w   d1, d0                                                  ; d0 = current screen line

        ; if (screenline < minScreenLine)
        cmp.w   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_minScreenLine), d0
        bge.s   .checkMaxScreenLine

            ; if (screenLine >= minScreenLine)
            move.w  (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_screenLine), d1
            cmp.w   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_minScreenLine), d1
            blt.s   .skipTopPaletteDMA

                TILESET_GET a0

                ; Starting palette changed
                movea.l Tileset_alternativePaletteAddress(a0), a0
                move.l a0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_startPalette)

                ; Queue palette change
                jsr VDPDMAQueueAddCommandList

        .skipTopPaletteDMA:

            ; Disable hint
            move.w  #$ff, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntPosition)

        bra.s   .screenLineCheckDone
    .checkMaxScreenLine:
        ; else if (screenline > maxScreenLine)
        cmp.w   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_maxScreenLine), d0
        ble.s   .midScreenLine

            ; if (screenLine <= maxScreenLine)
            move.w  (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_screenLine), d1
            cmp.w   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_maxScreenLine), d1
            bgt.s   .skipBottomPaletteDMA

                TILESET_GET a0

                ; Starting palette changed
                movea.l Tileset_paletteAddress(a0), a0
                move.l a0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_startPalette)

                ; Queue palette change
                jsr VDPDMAQueueAddCommandList

        .skipBottomPaletteDMA:

            ; Disable hint
            move.w  #$ff, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntPosition)

        bra.s   .screenLineCheckDone
        ; else
    .midScreenLine:

        TILESET_GET a0

        ; Always refresh palette for when mid screen
        movea.l Tileset_paletteAddress(a0), a0
        move.l a0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_startPalette)

        ; Queue palette change
        jsr VDPDMAQueueAddCommandList

        ; Set hint to screen line position
        move.w  d0, d1
        sub.w   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntScreenLineOffset), d1
        move.w  d1, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntPosition)

    .screenLineCheckDone:

        move.w  d0, (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_screenLine)
        rts


;-------------------------------------------------
; Just transfer the current starting palette directly
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectResetFrame:
        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_startPalette)
        rts


;-------------------------------------------------
; Install a raster effect
; ----------------
; Input:
; - a0: PaletteSwapRasterEffectConfiguration
_PaletteSwapRasterEffectSetupFrame:
        ; Clear interrupt handled state
        clr.b   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntHandled)

        ; Setup horizontal interrupt position
        move.w  #VDP_CMD_RS_HINT_RATE, d0
        or.w    (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntPosition), d0
        move.w  d0, MEM_VDP_CTRL
        rts


;-------------------------------------------------
; Color transition table based palette swap hblank handler (Based on Sonic 3's implementation)
; ----------------
_PaletteSwapRasterEffectColorTransitionHblank:
        tst.b   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntHandled)
        bne     .handled

            seq     (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntHandled)

            ; Disable hint after the next occurence
            VDP_REG_SET vdpRegHRate, $ff

            PUSHM.l  d0-d1/a0-a4

            ; Request Z80 as z80->68000 accesses could mess up the timing (actually just waiting for BUS_REQ could also do that :/)
            Z80_GET_BUS

            ; Load adresses
            TILESET_GET a0
            movea.l Tileset_colorTransitionTableAddress(a0), a1
            movea.l Tileset_alternativePaletteAddress(a0), a0
            adda.l  #TilesetPalette_colors, a0
            lea     MEM_VDP_DATA, a2
            lea     MEM_VDP_CTRL, a3

            ; Wait until the end of line (66 cycles)
            moveq   #4, d1      ; 4 cycles
        .wait1:
            dbra    d1, .wait1  ; 4 * 10 + 14 cycles
            nop                 ; 4 cycles
            nop                 ; 4 cycles

            moveq   #0, d1
            move.w  (a1)+, d0                                           ; d0 = number of color triplets in color transition table
            subq.w  #1, d0                                              ; d0 = line counter
        .lineLoop:

                ; Get color offset of triplet
                move.w (a1)+, d1                                        ; d1 = offset of color triplet

                ; Get color address
                lea (a0, d1), a4                                        ; a4 = RAM address of color triplet

                ; Set VDP access mode to CRAM write at color triplet CRAM address
                addi.w  #$c000, d1
                swap    d1                                              ; d1 = "write cram[index]" VDP command
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

            POPM.l  d0-d1/a0-a4

    .handled:
        rte


;-------------------------------------------------
; DMA based palette swap hblank handler
; ----------------
_PaletteSwapRasterEffectDMAHblank:
        tst.b   (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntHandled)
        bne.s   .handled

            seq     (paletteSwapRasterEffectState + PaletteSwapRasterEffectState_hIntHandled)

            ; Disable hint after the next occurence
            VDP_REG_SET vdpRegHRate, $ff

            PUSHL a0
            PUSHL a1

                TILESET_GET a0

                VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT_ROM_SAFE Tileset_alternativePaletteAddress(a0)

            POPL a1
            POPL a0

    .handled:
        rte
