;------------------------------------------------------------------------------------------
; Blob "AI"
;------------------------------------------------------------------------------------------

    Include './engine/include/object.inc'
    Include './engine/include/entity.inc'
    Include './engine/include/map.inc'
    Include './engine/include/collision.inc'

;-------------------------------------------------
; Blob constants
; ----------------
BLOB_TILE_ID    Equ 1300
BLOB_EXTENTS    Equ 8
BLOB_SPEED      Equ 1


;-------------------------------------------------
; Blob main structures
; ----------------

    ; MapObjectDescriptor
    DEFINE_STRUCT BlobDescriptor, MapStatefulObjectDescriptor
        STRUCT_MEMBER.MapObjectPosition position
    DEFINE_STRUCT_END

    ; State
    DEFINE_STRUCT BlobState, Entity
        STRUCT_MEMBER.w deathCounter
        STRUCT_MEMBER.w spriteAttr
        STRUCT_MEMBER.w speed
    DEFINE_STRUCT_END

    ; Type (MapObjectType)
    DEFINE_OBJECT_TYPE Blob, BlobState
        dc.l    BlobLoad                    ; MapObjectType.loadResources()
        dc.l    NoOperation                 ; MapObjectType.releaseResources()
        dc.l    BlobInit                    ; MapObjectType.init()
        dc.l    BlobUpdate                  ; MapObjectType.update()
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
        ; Position
        move.w  BlobDescriptor_position + MapObjectPosition_x(a0), Entity_x(a1)
        move.w  BlobDescriptor_position + MapObjectPosition_y(a0), Entity_y(a1)
        clr.w   BlobState_deathCounter(a1)

        ; Orientation/Movement direction
        move.w  #BLOB_SPEED, BlobState_speed(a1)
        move.b  MapObjectDescriptor_flags(a0), d0
        andi.w  #MODF_ORIENTATION_MASK, d0
        beq.s   .notFlipped
            neg.w   BlobState_speed(a1)
    .notFlipped:
        lsl.w   #VDP_SPRITE_ATTR3_ORIENTATION_SHIFT - MODF_ORIENTATION_SHIFT, d0
        addi.w  #BLOB_TILE_ID, d0
        move.w  d0, BlobState_spriteAttr(a1)
        rts


;-------------------------------------------------
; Update and render
; ----------------
; Input:
; - a0: BlobDescriptor address
; - a1: BlobState address
; Uses: d0-d4/a5-a6
BlobUpdate:
        ; Dying?
        move.w  BlobState_deathCounter(a1), d0
        beq.s   .alive

            ; We are dying, update death counter
            subq.w  #1, d0
            move.w  d0, BlobState_deathCounter(a1)
            bne.s .notDeadYet

                ; We are dead so remove from playfield
                MAP_TRANSFERABLE_OBJECT_QUEUE_STATE_CHANGE  &
                    MAP_OBJECT_STATE_CHANGE_DEACTIVATE,     &
                    a1,                                     &
                    a2
                rts

            .notDeadYet:

                ; Death animation (blink)
                btst    #0, d0
                beq.s   .skipRender
                    bra     _BlobRender
            .skipRender:
                rts

    .alive:
        ;PROFILE_CPU_START

        PUSHW   d6
        PUSHW   d7
        PUSHM.l a3-a6

        bsr.s   _BlobMove
        bsr     _BlobRender

        ; Do collision check
        COLLISION_ALLOCATE_ELEMENT          &
            #HandlerCollisionElement_Size,  &
            a0, a2, a3

        move.w  Entity_x(a1), d0
        move.w  Entity_y(a1), d1
        moveq   #BLOB_EXTENTS, d2
        sub.w   d2, d0
        sub.w   d2, d1
        move.w  #EnemyCollisionTypeMetadata, CollisionElement_metadata(a0)
        move.w  d0, AABBCollisionElement_minX(a0)
        move.w  d1, AABBCollisionElement_minY(a0)
        add.w   d2, d2
        subq.w  #1, d2  ; inclusive max
        add.w   d2, d0
        add.w   d2, d1
        move.w  d0, AABBCollisionElement_maxX(a0)
        move.w  d1, AABBCollisionElement_maxY(a0)
        move.w  a1, HandlerCollisionElement_data(a0)
        move.l  #BlobCollision, HandlerCollisionElement_handlerAddress(a0)

        jsr     CollisionCheck

        POPM.l  a3-a6
        POPW    d7
        POPW    d6

        ;PROFILE_CPU_END
        rts


;-------------------------------------------------
; Move entity along the floor. Crude implementation...
; ----------------
; Input:
; - a0: BlobDescriptor address
; - a1: BlobState address
; Uses: d0-d7/a2
_BlobMove:
        MAP_GET a0
        movea.l MapHeader_foregroundAddress(a0), a0
        move.w  Entity_x(a1), d0
        move.w  Entity_y(a1), d1
        add.w   BlobState_speed(a1), d0

        ; Floor
        add.w   #BLOB_EXTENTS * 2, d1
        PUSHL   a1
        jsr     MapCollisionFindFloor
        POPL    a1
        tst.w   d2
        bmi.s   .noFloor
    .floor:
            sub.w   #BLOB_EXTENTS - 1, d1
            bra.s   .floorDone
    .noFloor:
            ; Restore position
            sub.w   #BLOB_EXTENTS * 2, d1
            sub.w   BlobState_speed(a1), d0
            ; Change direction
            eori.w  #VDP_SPRITE_ATTR3_HFLIP_MASK, BlobState_spriteAttr(a1)
            neg.w   BlobState_speed(a1)
    .floorDone:

        ; Wall
        tst.w   BlobState_speed(a1)
        bmi.s   .moveLeft
    .moveRight:
            add.w   #BLOB_EXTENTS - 1, d0
            PUSHL   a1
            jsr     MapCollisionFindRightWall
            POPL    a1
            sub.w   #BLOB_EXTENTS - 1, d0
            bra.s   .wallDone
    .moveLeft:
            sub.w   #BLOB_EXTENTS, d0
            PUSHL   a1
            jsr     MapCollisionFindLeftWall
            POPL    a1
            add.w   #BLOB_EXTENTS, d0
    .wallDone:
        tst.w   d2
        bmi.s   .noWall
    .wall:
            ; Change direction on wall collision
            eori.w  #VDP_SPRITE_ATTR3_HFLIP_MASK, BlobState_spriteAttr(a1)
            neg.w   BlobState_speed(a1)
    .noWall:

        ; Save position
        move.w  d0, Entity_x(a1)
        move.w  d1, Entity_y(a1)
    rts


;-------------------------------------------------
; Render sprite
; ----------------
; Input:
; - a1: BlobState address
; Uses: d0-d4
_BlobRender:
        ; Convert horizontal map coordinates to screen coordinates
        VIEWPORT_GET_X d0
        move.w  Entity_x(a1), d3
        sub.w   d0, d3
        subq.w  #BLOB_EXTENTS, d3

        ; Check left screen bounds
        cmpi.w  #-BLOB_EXTENTS * 2, d3
        ble.s   .notVisible

        ; Check right screen bounds
        cmpi.w  #320, d3
        bge.s   .notVisible

        ; Convert vertical map coordinates to screen coordinates
        VIEWPORT_GET_Y d1
        move.w  Entity_y(a1), d4
        sub.w   d1, d4
        subq.w  #BLOB_EXTENTS, d4

        ; Check top screen bounds
        cmpi.w  #-BLOB_EXTENTS * 2, d4
        bmi.s   .notVisible

        ; Check bottom screen bounds
        cmpi.w  #224, d4
        bge.s   .notVisible

            ; Convert to sprite coordinates
            addi.w  #128, d3
            addi.w  #128, d4

            ; Allocate sprite
            PUSHW   a1
            moveq   #1, d0
            jsr     VDPSpriteAlloc
            POPW    a1

            ; Update sprite attribute
            move.w  d3, VDPSprite_x(a0)
            move.w  d4, VDPSprite_y(a0)
            move.b  #VDP_SPRITE_SIZE_H2 | VDP_SPRITE_SIZE_V2, VDPSprite_size(a0)
            move.w  BlobState_spriteAttr(a1), VDPSprite_attr(a0)
    .notVisible:
        rts


;-------------------------------------------------
; Handle collision
; ----------------
; Input:
; - a0: HandlerCollisionElement we created
; - a1: Colliding/target CollisionElement
BlobCollision:
        movea.w HandlerCollisionElement_data(a0), a6                            ; a6 = BlobState

        cmpi.w  #EnemyCollisionTypeMetadata, CollisionElement_metadata(a1)
        beq.s   .enemyCollision

    .hurtCollision:

        ; Flip vertically
        ori.w   #VDP_SPRITE_ATTR3_VFLIP_MASK, BlobState_spriteAttr(a6)

        ; Reposition
        addi.w  #4, Entity_y(a6)

        ; Blink for 1,5 seconds before dying
        move.w  #90, BlobState_deathCounter(a6)

        rts

    .enemyCollision:

        ; Change direction
        eori.w  #VDP_SPRITE_ATTR3_HFLIP_MASK, BlobState_spriteAttr(a6)
        neg.w   BlobState_speed(a6)

        rts
