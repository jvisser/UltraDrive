;------------------------------------------------------------------------------------------
; Fireball "AI"
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Fireball constants
; ----------------
FIREBALL_TILE_ID Equ 1200
FIREBALL_EXTENTS Equ 8


;-------------------------------------------------
; Fireball main structures
; ----------------

    ; MapObjectDescriptor
    DEFINE_STRUCT FireballDescriptor, MapObjectDescriptor
        STRUCT_MEMBER.MapObjectPosition position
    DEFINE_STRUCT_END

    ; Type (MapObjectType)
    DEFINE_OBJECT_TYPE Fireball
        dc.l    NoOperation                 ; MapObjectType.init()
        dc.l    FireballUpdate              ; MapObjectType.update()
    DEFINE_OBJECT_TYPE_END


;-------------------------------------------------
; Load tiles
; ----------------
; Uses: a0
FireballLoad:

        VDP_ADDR_SET WRITE, VRAM, (FIREBALL_TILE_ID * $20), $2

        lea MEM_VDP_DATA, a0

        move.l #$00000011, (a0)
        move.l #$00002123, (a0)
        move.l #$00012232, (a0)
        move.l #$00123124, (a0)
        move.l #$02232343, (a0)
        move.l #$01213432, (a0)
        move.l #$12324313, (a0)
        move.l #$13243241, (a0)

        move.l #$1324323c, (a0)
        move.l #$12324314, (a0)
        move.l #$01213432, (a0)
        move.l #$02232343, (a0)
        move.l #$00123124, (a0)
        move.l #$00012232, (a0)
        move.l #$00002123, (a0)
        move.l #$00000011, (a0)

        move.l #$11000000, (a0)
        move.l #$32120000, (a0)
        move.l #$23221000, (a0)
        move.l #$42132100, (a0)
        move.l #$34323220, (a0)
        move.l #$23431210, (a0)
        move.l #$41342321, (a0)
        move.l #$c3234231, (a0)

        move.l #$14234231, (a0)
        move.l #$31342321, (a0)
        move.l #$23431210, (a0)
        move.l #$34323220, (a0)
        move.l #$42132100, (a0)
        move.l #$23221000, (a0)
        move.l #$32120000, (a0)
        move.l #$11000000, (a0)
        rts


;-------------------------------------------------
; Update and render
; ----------------
; Input:
; - a0: FireballDescriptor address
; Uses: d0-d5/a0-a1
FireballUpdate:
        ; Convert horizontal map coordinates to screen coordinates
        VIEWPORT_GET_X d0
        move.w  FireballDescriptor_position + MapObjectPosition_x(a0), d3
        move.w  d3, d5
        sub.w   d0, d3
        subq.w  #FIREBALL_EXTENTS, d3

        ; Check left screen bounds
        cmpi.w  #-FIREBALL_EXTENTS * 2, d3
        ble     .notVisible

        ; Check right screen bounds
        cmpi.w  #320, d3
        bge     .notVisible

            ; Convert vertical map coordinates to screen coordinates
            VIEWPORT_GET_Y d1
            move.w  FireballDescriptor_position + MapObjectPosition_y(a0), d4
            sub.w   d1, d4
            subq.w  #FIREBALL_EXTENTS, d4

            ; Get sine table index based on frame counter and x position
            OS_GET_FRAME_COUNTER_W d0
            add.w   d0, d0
            add.w   d5, d0
            andi.w  #ANGLE_MASK, d0
            cmpi.w  #ANGLE_180, d0
            bhi     .notVisible         ; Not visible when sin is negative (ie below lava)

                ; Movement
                lea     Sin.w, a1
                add.w   d0, d0
                move.w  (a1, d0), d0
                lsr.w   #2, d0
                sub.w   d0, d4

                ; Check top screen bounds
                cmpi.w  #-FIREBALL_EXTENTS * 2, d4
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
                    move.w  d3, VDPSprite_x(a0)
                    move.w  d4, VDPSprite_y(a0)
                    move.b  #VDP_SPRITE_SIZE_H2 | VDP_SPRITE_SIZE_V2, VDPSprite_size(a0)
                    move.w  #FIREBALL_TILE_ID | (1 << PATTERN_REF_PALETTE_SHIFT), VDPSprite_attr(a0)

    .notVisible:
        rts
