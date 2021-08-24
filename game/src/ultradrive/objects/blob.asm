;------------------------------------------------------------------------------------------
; Blob "AI"
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Blob constants
; ----------------
BLOB_TILE_ID Equ 1300
BLOB_EXTENTS Equ 8


;-------------------------------------------------
; Blob main structures
; ----------------

    ; ObjectDescriptor
    DEFINE_STRUCT BlobDescriptor, EXTENDS, MapStatefulObjectDescriptor
        STRUCT_MEMBER.MapObjectPosition blobPosition
    DEFINE_STRUCT_END

    ; State
    DEFINE_STRUCT BlobState
        STRUCT_MEMBER.w blobX
        STRUCT_MEMBER.w blobY
    DEFINE_STRUCT_END

    ; Type
    DEFINE_OBJECT_TYPE Blob, BlobState
        dc.l    BlobInit
        dc.l    BlobUpdate
    DEFINE_OBJECT_TYPE_END


;-------------------------------------------------
; Load tiles
; ----------------
; Uses: a0
BlobLoad:

        VDP_ADDR_SET WRITE, VRAM, (BLOB_TILE_ID * $20), $2

        lea MEM_VDP_DATA, a0

        move.l #$00000000, (a0)
        move.l #$00000000, (a0)
        move.l #$00000000, (a0)
        move.l #$00000000, (a0)
        move.l #$00000aaa, (a0)
        move.l #$000aaab8, (a0)
        move.l #$00aabb8b, (a0)
        move.l #$0aab8bba, (a0)

        move.l #$aab8bbab, (a0)
        move.l #$abbbbaba, (a0)
        move.l #$ab8babaa, (a0)
        move.l #$abbbabaa, (a0)
        move.l #$abbbabaa, (a0)
        move.l #$aabbbaaa, (a0)
        move.l #$9aaaaaaa, (a0)
        move.l #$09999999, (a0)

        move.l #$00000000, (a0)
        move.l #$00000000, (a0)
        move.l #$00000000, (a0)
        move.l #$00000000, (a0)
        move.l #$aaa00000, (a0)
        move.l #$8baaa000, (a0)
        move.l #$bbbaaa00, (a0)
        move.l #$baaaa9a0, (a0)

        move.l #$aaaaaa9a, (a0)
        move.l #$aaaaaa9a, (a0)
        move.l #$aaaaaa9a, (a0)
        move.l #$aaaaa99a, (a0)
        move.l #$aaaaa99a, (a0)
        move.l #$aaaa99aa, (a0)
        move.l #$aaaaaaa9, (a0)
        move.l #$99999990, (a0)
        rts


;-------------------------------------------------
; Init state
; ----------------
; Input:
; - a0: BlobDescriptor address
; - a1: BlobState address
BlobInit:
        move.w  blobPosition + opX(a0), blobX(a1)
        move.w  blobPosition + opY(a0), blobY(a1)
        rts


;-------------------------------------------------
; Update and render
; ----------------
; Input:
; - a0: BlobDescriptor address
; - a1: BlobState address
; Uses: d0-d4/a5-a6
BlobUpdate:
        ; Convert horizontal map coordinates to screen coordinates
        VIEWPORT_GET_X d0
        move.w  blobX(a1), d3
        sub.w   d0, d3
        subq.w  #BLOB_EXTENTS, d3

        ; Check left screen bounds
        cmpi.w  #-BLOB_EXTENTS * 2, d3
        ble     .notVisible

        ; Check right screen bounds
        cmpi.w  #320, d3
        bge     .notVisible

        ; Convert vertical map coordinates to screen coordinates
        VIEWPORT_GET_Y d1
        move.w  blobY(a1), d4
        sub.w   d1, d4
        subq.w  #BLOB_EXTENTS, d4

        ; Check top screen bounds
        cmpi.w  #-BLOB_EXTENTS * 2, d4
        bmi     .notVisible

        ; Check bottom screen bounds
        cmpi.w  #224, d4
        bge     .notVisible

            ; Convert to sprite coordinates
            addi.w  #128, d3
            addi.w  #128, d4

            ; Allocate sprite
            moveq   #1, d0
            jsr     VDPSpriteAlloc

            ; Update sprite attribute
            move.w  d3, vdpSpriteX(a0)
            move.w  d4, vdpSpriteY(a0)
            move.b  #VDP_SPRITE_SIZE_H2 | VDP_SPRITE_SIZE_V2, vdpSpriteSize(a0)
            move.w  #BLOB_TILE_ID, vdpSpriteAttr3(a0)

    .notVisible:
        rts
