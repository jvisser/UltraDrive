;------------------------------------------------------------------------------------------
; Orbison "AI"
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Orbison constants
; ----------------
ORBISON_TILE_ID Equ 1100
ORBISON_EXTENTS Equ 8


;-------------------------------------------------
; Orbison main structures
; ----------------

    ; State
    DEFINE_STRUCT OrbisonState, EXTENDS, ObjectState
        STRUCT_MEMBER.w orbisonX
        STRUCT_MEMBER.w orbisonY
    DEFINE_STRUCT_END

    ; Type
    DEFINE_OBJECT_TYPE Orbison, OrbisonState
        dc.l    OrbisonInit
        dc.l    OrbisonUpdate
    DEFINE_OBJECT_TYPE_END


;-------------------------------------------------
; Load tiles
; ----------------
; Uses: a0
OrbisonLoad:

        VDP_ADDR_SET WRITE, VRAM, (ORBISON_TILE_ID * $20), $2

        lea MEM_VDP_DATA, a0

        move.l #$00000077, (a0)
        move.l #$00007888, (a0)
        move.l #$00089cba, (a0)
        move.l #$0059cccb, (a0)
        move.l #$068abcbb, (a0)
        move.l #$08a9abba, (a0)
        move.l #$789a9aa9, (a0)
        move.l #$6899aa9a, (a0)

        move.l #$58899999, (a0)
        move.l #$66889898, (a0)
        move.l #$05678878, (a0)
        move.l #$06576687, (a0)
        move.l #$00765765, (a0)
        move.l #$00076556, (a0)
        move.l #$00007655, (a0)
        move.l #$00000075, (a0)

        move.l #$77000000, (a0)
        move.l #$87770000, (a0)
        move.l #$98876000, (a0)
        move.l #$aa887600, (a0)
        move.l #$a9988760, (a0)
        move.l #$9a997870, (a0)
        move.l #$a9988757, (a0)
        move.l #$98987875, (a0)

        move.l #$89786765, (a0)
        move.l #$97875976, (a0)
        move.l #$78767850, (a0)
        move.l #$67578760, (a0)
        move.l #$65797600, (a0)
        move.l #$78776000, (a0)
        move.l #$55660000, (a0)
        move.l #$67000000, (a0)
        rts


;-------------------------------------------------
; Init state
; ----------------
; Input:
; - a0: ObjectSpawnData address
; - a1: OrbisonState address
OrbisonInit:
        move.w  osdX(a0), orbisonX(a1)
        move.w  osdY(a0), orbisonY(a1)
        rts


;-------------------------------------------------
; Update and render
; ----------------
; Input:
; - a0: ObjectSpawnData address
; - a1: OrbisonState address
; - a2: ObjectType Table base address
; Uses: d0-d4/a5-a6
OrbisonUpdate:
        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1

        ; Convert map coordinates to (top/left) screen coordinates
        move.w  orbisonX(a1), d3
        sub.w   d0, d3
        subq.w  #ORBISON_EXTENTS, d3

        move.w  orbisonY(a1), d4
        sub.w   d1, d4
        subq.w  #ORBISON_EXTENTS, d4

        ; Check left screen bounds
        cmpi.w  #-ORBISON_EXTENTS * 2, d3
        ble     .notVisible

        ; Check top screen bounds
        cmpi.w  #-ORBISON_EXTENTS * 2, d4
        bmi     .notVisible

        ; Check right screen bounds
        cmpi.w  #320, d3
        bge     .notVisible

        ; Check bottom screen bounds
        cmpi.w  #224, d4
        bge     .notVisible

            ; Save a0-a1
            movea.l a0, a5
            movea.l a1, a6

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
            move.w  #ORBISON_TILE_ID | (1 << PATTERN_REF_PALETTE_SHIFT), vdpSpriteAttr3(a0)

            ; Restore a0-a1
            movea.l a5, a0
            movea.l a6, a1

    .notVisible:
        rts
