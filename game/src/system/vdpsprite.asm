;------------------------------------------------------------------------------------------
; VDP Low level sprite handling routines/macros
;------------------------------------------------------------------------------------------

    Include './common/include/debug.inc'

    Include './system/include/vdp.inc'
    Include './system/include/vdpdmaqueue.inc'

;-------------------------------------------------
; Sprite attribute table constants
; ----------------
VDP_MAX_SPRITES Equ 80


;-------------------------------------------------
; VDP sprite structures
; ----------------

    ; RAM shadow attribute table
    DEFINE_VAR SHORT
        VAR.VDPSprite       vdpSpriteAttrTable,             VDP_MAX_SPRITES
        VAR.w               vdpSpriteAttrTableTail
        VAR.w               vdpSpriteCount
        VAR.VDPDMATransfer  vdpSpriteAttrTableDMATransfer
    DEFINE_VAR_END

    VDPSpriteAttrTableDMATransferTemplate:
        VDP_DMA_DEFINE_VRAM_TRANSFER vdpSpriteAttrTable, VDP_SPRITE_ADDR, vdpSpriteAttrTable_Size / 2


;-------------------------------------------------
; Initialize the sprite system
; ----------------
VDPSpriteInit
        bsr     VDPSpriteClear

        lea     VDPSpriteAttrTableDMATransferTemplate, a0
        lea     vdpSpriteAttrTableDMATransfer, a1
        move.w  #VDPDMATransfer_Size, d0
        jmp MemoryCopy


;-------------------------------------------------
; Allocate and link sprites
; ----------------
; Input:
; - d0: Number of sprites to allocate
; Output:
; - a0: Address of first sprite
; Uses: d0-d2/a0-a1
VDPSpriteAlloc:
        move.w  vdpSpriteCount, d1
        move.w  d1, d2
        add.w   d0, d2
        cmp.w   #VDP_MAX_SPRITES, d2
        bge.s   .spriteAllocFull

        move.w  vdpSpriteAttrTableTail, a0
        movea.l a0, a1

        ; Link previous terminal sprite to the head of newly allocated sprite list
        tst.w   d1
        beq.s   .noPreviousSprite
        move.b  d1, VDPSprite_link - VDPSprite_Size(a0)
    .noPreviousSprite:

        ; Allocate and link requested amount of sprites
        subq    #1, d0
    .spriteAllocLoop:
        addq.w  #1, d1
        move.b  d1, VDPSprite_link(a1)
        addq.l  #VDPSprite_Size, a1
        dbra    d0, .spriteAllocLoop

        ; Terminate sprite list
        move.b  #0, VDPSprite_link - VDPSprite_Size(a1)

        ; Store current allocation tracking information
        move.w  d1, vdpSpriteCount
        move.w  a1, vdpSpriteAttrTableTail

        If (def(debug))
                bra.s   .spriteAllocDone

            .spriteAllocFull:
                DEBUG_MSG   'VDP Sprite allocation overflow!'

            .spriteAllocDone:
        Else
            .spriteAllocFull:
        EndIf
        rts


;-------------------------------------------------
; Clear all sprites
; ----------------
; Uses: d0
VDPSpriteClear:
        move.w  #vdpSpriteAttrTable, vdpSpriteAttrTableTail
        moveq   #0, d0
        move.w  d0, vdpSpriteCount
        move.l  d0, vdpSpriteAttrTable
        move.l  d0, vdpSpriteAttrTable + SIZE_LONG
        rts


;-------------------------------------------------
; Unlink sprites after the specified sprite index
; ----------------
; Input:
; - d0: Last sprite number to retain
; Uses: d0-d1/a0
VDPSpriteUnlinkAfter:
        move.w  d0, d1

        ; Set sprite count
        addq.w  #1, d1
        move.w  d1, vdpSpriteCount

        ; Get address of last sprite
        lsr.w   #3, d0
        lea     vdpSpriteAttrTable, a0
        adda.w  d0, a0

        ; Reset link
        clr.b   VDPSprite_link(a0)

        ; Set new tail ptr
        addq.l  #8, a0
        move.w  a0, vdpSpriteAttrTableTail
        rts


;-------------------------------------------------
; Commit sprites to the VDP
; ----------------
; Uses: d0/a0-a1
VDPSpriteCommit:
        move.w  vdpSpriteCount, d0
        bne.s   .nonEmpty
        moveq   #1, d0                                  ; Always transfer the first sprite to reset linking
    .nonEmpty:

        add.w   d0, d0
        add.w   d0, d0
        lea     vdpSpriteAttrTableDMATransfer, a0
        move.w  d0, VDPDMATransfer_length(a0)

        VDP_DMA_QUEUE_ADD_INDIRECT.l a0

        rts

