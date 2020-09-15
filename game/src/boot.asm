;------------------------------------------------------------------------------------------
; Code
;------------------------------------------------------------------------------------------
    org 0

    include 'metadata.asm'

    include 'vector68k.asm'
    include 'segaheader.asm'


Exception:
        rte


HBlankInterrupt:
        rte


VBlankInterrupt:
        rte


; Uses only scratch registers according to gcc 68k calling convention
GensKModDebugAlert:
        move.w  #0x9e00, d0
        move.b  (a0)+, d0
        beq.s   @done
        movea.l #$c00004, a1

    @writeLoop:
        move.w  d0, (a1)
        move.b  (a0)+, d0
        bne.s   @writeLoop
        move.w  d0, (a1)

    @done:
        rts


DEBUG macro
        movem.l d0/a0-a1, -(sp)
        lea     debugMessage\@, a0
        bsr.s   GensKModDebugAlert
        movem.l (sp)+, d0/a0-a1
        bra.s   done\@

    debugMessage\@:
        dc.b    \1, $00

        even
    done\@:
    endm


EntryPoint:
    DEBUG '\TITLE\ Started!'

    @mainLoop:
        bra.s   @mainLoop


RomImageEnd
