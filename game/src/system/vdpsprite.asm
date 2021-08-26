;------------------------------------------------------------------------------------------
; VDP Low level sprite handling routines/macros
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Sprite attribute table constants
; ----------------
VDP_MAX_SPRITES Equ 80


;-------------------------------------------------
; Sprite attribute constants
; ----------------

; Vertical sizes
VDP_SPRITE_SIZE_V1 Equ                      $00
VDP_SPRITE_SIZE_V2 Equ                      $01
VDP_SPRITE_SIZE_V3 Equ                      $02
VDP_SPRITE_SIZE_V4 Equ                      $03

; Horizontal sizes
VDP_SPRITE_SIZE_H1 Equ                      $00
VDP_SPRITE_SIZE_H2 Equ                      $04
VDP_SPRITE_SIZE_H3 Equ                      $08
VDP_SPRITE_SIZE_H4 Equ                      $0c

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
; VDP sprite structures
; ----------------

    ; VDP hardware sprite attribute struct (8 bytes)
    DEFINE_STRUCT VDPSprite
        STRUCT_MEMBER.w y
        STRUCT_MEMBER.b size
        STRUCT_MEMBER.b link
        STRUCT_MEMBER.w attr
        STRUCT_MEMBER.w x
    DEFINE_STRUCT_END

    ; RAM shadow attribute table
    DEFINE_VAR FAST
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
        bge     .spriteAllocFull

        move.w  vdpSpriteAttrTableTail, a0
        movea.l a0, a1

        ; Link previous terminal sprite to the head of newly allocated sprite list
        tst.w   d1
        beq     .noPreviousSprite
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
                bra     .spriteAllocDone

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
        bne     .nonEmpty
        moveq   #1, d0                                  ; Always transfer the first sprite to reset linking
    .nonEmpty:

        add.w   d0, d0
        add.w   d0, d0
        lea     vdpSpriteAttrTableDMATransfer, a0
        move.w  d0, VDPDMATransfer_length(a0)

        VDP_DMA_QUEUE_ADD_INDIRECT a0

        rts

