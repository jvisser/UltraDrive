;------------------------------------------------------------------------------------------
; Orbison "AI"
;------------------------------------------------------------------------------------------

    Include './system/include/memory.inc'

    Include './engine/include/object.inc'
    Include './engine/include/map.inc'

;-------------------------------------------------
; Orbison constants
; ----------------
ORBISON_TILE_ID Equ 1100
ORBISON_EXTENTS Equ 8


;-------------------------------------------------
; Orbison main structures
; ----------------

    ; MapObjectDescriptor
    DEFINE_STRUCT OrbisonDescriptor, MapObjectDescriptor
        STRUCT_MEMBER.w x
        STRUCT_MEMBER.w y
    DEFINE_STRUCT_END

    ; Type (MapObjectType)
    DEFINE_OBJECT_TYPE Orbison
        dc.l    OrbisonLoad                 ; MapObjectType.loadResources()
        dc.l    NoOperation                 ; MapObjectType.releaseResources()
        dc.l    NoOperation                 ; MapObjectType.init()
        dc.l    OrbisonUpdate               ; MapObjectType.update()
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
; Update and render
; ----------------
; Input:
; - a0: OrbisonDescriptor address
; Uses: d0-d4/a0-a1
OrbisonUpdate:
        ; Convert horizontal map coordinates to screen coordinates
        VIEWPORT_GET_X d0
        move.w  OrbisonDescriptor_x(a0), d3
        sub.w   d0, d3
        subq.w  #ORBISON_EXTENTS, d3

        ; Check left screen bounds
        cmpi.w  #-ORBISON_EXTENTS * 2, d3
        ble.s   .notVisible

        ; Check right screen bounds
        cmpi.w  #320, d3
        bge.s   .notVisible

        ; Convert vertical map coordinates to screen coordinates
        VIEWPORT_GET_Y d1
        move.w  OrbisonDescriptor_y(a0), d4
        sub.w   d1, d4
        subq.w  #ORBISON_EXTENTS, d4

        ; Check top screen bounds
        cmpi.w  #-ORBISON_EXTENTS * 2, d4
        bmi.s   .notVisible

        ; Check bottom screen bounds
        cmpi.w  #224, d4
        bge.s   .notVisible

            ; Convert to sprite coordinates
            addi.w  #128, d3
            addi.w  #128, d4

            ; Allocate sprite
            moveq   #1, d0
            jsr     VDPSpriteAlloc

            ; Update sprite attribute
            move.w  d3, VDPSprite_x(a0)
            move.w  d4, VDPSprite_y(a0)
            move.b  #VDP_SPRITE_SIZE_H2 | VDP_SPRITE_SIZE_V2, VDPSprite_size(a0)
            move.w  #ORBISON_TILE_ID | (1 << PATTERN_REF_PALETTE_SHIFT), VDPSprite_attr(a0)

    .notVisible:
        rts
