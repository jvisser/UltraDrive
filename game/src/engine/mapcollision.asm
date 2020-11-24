;------------------------------------------------------------------------------------------
; Map collision routines
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Performance measurement macros
; ----------------
_MAP_COLLISION_PROFILE_ENABLE = FALSE

_MAP_COLLISION_PROFILE_START Macro
        If (_MAP_COLLISION_PROFILE_ENABLE = TRUE)
            PROFILE_CPU_START
        Endif
    Endm

_MAP_COLLISION_PROFILE_END Macro
        If (_MAP_COLLISION_PROFILE_ENABLE = TRUE)
            PROFILE_CPU_END
        Endif
    Endm


;-------------------------------------------------
; Find floor collision point
; ----------------
; Input:
; - a0: map
; - d0: x position
; - d1: y position
; Output:
; - d0: x position
; - d1: y position
; - d2: angle
MapCollisionFindFloor:
;-------------------------------------------------
; MapCollisionFindFloor specific macros
; ----------------
; Required:
; - d3: chunk ref
; - a6: chunk table address
; Output:
; - a4: chunk base address
; - a5: block offset table base address
_LOAD_CHUNK Macro scratch
            ; Get chunk address
            move.w  d3, \scratch                                    ; Mask by CHUNK_REF_INDEX_MASK not needed as all bits are shifted out
            lsl.w   #7, \scratch
            lea     (a6, \scratch), a4                              ; a4 = chunk base address

            ; Get block offset table address
            move.w  d3, \scratch
            andi.w  #CHUNK_REF_ORIENTATION_MASK, \scratch
            lsr.w   #CHUNK_REF_ORIENTATION_SHIFT - 6, \scratch
            lea     ChunkBlockOffsetTable.w, a5
            lea     (a5, \scratch), a5                              ; a5 = Block offset table base address
        Endm

; Required:
; - a5: block offset table base address
; - a4: chunk base address
; - d7: chunk block offset table offset
_READ_BLOCK_REF Macro target
            move.b  (a5, d7), \target
            ext.w   \target
            move.w  (a4, \target), \target
        Endm

; Required:
; - d3: chunk ref
_VERIFY_CHUNK_HAS_COLLISION Macro invalidLabel
            btst    #CHUNK_REF_COLLISION, d3
            beq     \invalidLabel
        Endm

; Required:
; - d2: block ref
_VERIFY_TOP_SOLIDITY Macro invalidLabel
            btst    #BLOCK_REF_SOLID_TOP, d2
            beq     \invalidLabel
        Endm

; Required:
; - d3: chunk ref
; - d2: block ref
; Output:
; - d3: block orientation flags
_VERIFY_NO_VFLIP Macro invalidLabel
            eor.w   d2, d3                                  ; d3 = block orientation
            btst    #BLOCK_REF_VFLIP, d3
            bne     \invalidLabel
        Endm

        ; ---------------------------------------------------------------------------------------
        ; Start of sub routine MapCollisionFindFloor
        ; ----------------

        _MAP_COLLISION_PROFILE_START

        lea         mapRowOffsetTable(a0), a2
        movea.l     mapDataAddress(a0), a3

        ; Get chunk ref
        move.w  d1, d2
        lsr.w   #7, d2
        add.w   d2, d2
        move.w  (a2, d2), d5                                        ; d5 = map row offset
        move.w  d0, d2
        lsr.w   #7, d2
        add.w   d2, d2
        add.w   d2, d5                                              ; d5 = chunk ref offset
        move.w  (a3, d5), d3                                        ; d3 = chunk ref

        _VERIFY_CHUNK_HAS_COLLISION .noCollision

            lea     chunkTable, a6

            _LOAD_CHUNK d4

            ; Get block ref
            move.w  d1, d2
            lsr.w   #1, d2
            andi.w  #$0038, d2
            move.w  d0, d7
            lsr.w   #4, d7
            andi.w  #$0007, d7
            add.w   d2, d7                                          ; d7 = Chunk block offset table offset

            _READ_BLOCK_REF d2

            _VERIFY_TOP_SOLIDITY .noCollision

            ; Get meta data id (collision + angle index)
            movea.l tilesetMetaDataMapping, a2
            move.w  d2, d4
            andi.w  #BLOCK_REF_INDEX_MASK, d4
            add.w   d4, d4
            move.w  (a2, d4), d4                                    ; d4 = block meta data id
            bne     .collisionBlockFound

                ; We found a solid block we need to also check one block up (slope case)

                ; Set Y to the top of the top of block
                andi.w  #~$0f, d1
                subq.w  #1, d1

                ; Try to find above block in current chunk
                sub.w   #CHUNK_DIMENSION, d7
                bmi     .chunkUp

                    _READ_BLOCK_REF d2                              ; d6 = block ref

                    bra .checkTopBlock

            .chunkUp:
                ; Find above block in above chunk

                ; Set chunk block offset at top of chunk
                add.w   #CHUNK_ELEMENT_COUNT, d7

                ; Go one row up in the map
                sub.w   mapStride(a0), d5
                move.w  (a3, d5), d3                                ; d3 = chunk ref

                _VERIFY_CHUNK_HAS_COLLISION .topNoCollision

                _LOAD_CHUNK     d2
                _READ_BLOCK_REF d2                                  ; d2 = block ref

            .checkTopBlock:

                    _VERIFY_NO_VFLIP     .topNoCollision
                    _VERIFY_TOP_SOLIDITY .topNoCollision

                    ; We have found a collision block above. Update meta data id
                    andi.w  #BLOCK_REF_INDEX_MASK, d2
                    add.w   d2, d2
                    move.w  (a2, d2), d4                            ; d4 = block meta data id

                    bra .validCollisionFound

                .topNoCollision:

                    ; Angle is always 0 for solid block
                    moveq   #0, d2

                    _MAP_COLLISION_PROFILE_END
                    rts

            .collisionBlockFound:

                ; Check if orientation of the block is in alignment with this operation (= non v flipped)
                _VERIFY_NO_VFLIP .noCollision

            .validCollisionFound:

                ; Load block meta data addresses
                movea.l tilesetCollisionData, a2
                movea.l tilesetAngleData, a1

                ; Get angle
                move.b  (a1, d4), d2

                ; Get collision field address
                lsl.w   #4, d4
                lea     (a2, d4), a2                                ; a2 = collision field base address
                move.w  d0, d5
                andi.w  #$0f, d5                                    ; d5 = collision field index

                btst    #BLOCK_REF_HFLIP, d3
                beq     .blockNoHFlip

                    ; Horizontally flipped so add 90 degrees to angle
                    add.w   #ANGLE_90, d2

                    ; Invert collision field index
                    not.w   d5
                    andi.w  #$0f, d5

            .blockNoHFlip:

                ; Get collision field height
                move.b  (a2, d5), d5
                ext.w   d5

                ; Update y position
                move.w  d1, d6
                ori.w   #$0f, d6
                sub.w   d5, d6
                cmp.w   d6, d1
                ble     .noCollision

                    ; Store adjusted Y position
                    move.w  d6, d1

                _MAP_COLLISION_PROFILE_END
                rts

    .noCollision:

            ; Set angle to -1 indicating no collision
            moveq   #-1, d2

            _MAP_COLLISION_PROFILE_END

        Purge _VERIFY_NO_VFLIP
        Purge _VERIFY_TOP_SOLIDITY
        Purge _VERIFY_CHUNK_HAS_COLLISION
        Purge _LOAD_CHUNK
        Purge _READ_BLOCK_REF
        rts


;-------------------------------------------------
;
; ----------------
MapCollisionFindCeiling:
    rts


;-------------------------------------------------
;
; ----------------
MapCollisionFindLeftWall:
    rts


;-------------------------------------------------
;
; ----------------
MapCollisionFindRightWall:
    rts


;-------------------------------------------------
; Block offsets per possible orientation
; ----------------
    SECTION_START S_FASTDATA

ChunkBlockOffsetTable:
    ; Default
    dc.b $00, $02, $04, $06, $08, $0a, $0c, $0e
    dc.b $10, $12, $14, $16, $18, $1a, $1c, $1e
    dc.b $20, $22, $24, $26, $28, $2a, $2c, $2e
    dc.b $30, $32, $34, $36, $38, $3a, $3c, $3e
    dc.b $40, $42, $44, $46, $48, $4a, $4c, $4e
    dc.b $50, $52, $54, $56, $58, $5a, $5c, $5e
    dc.b $60, $62, $64, $66, $68, $6a, $6c, $6e
    dc.b $70, $72, $74, $76, $78, $7a, $7c, $7e

    ; Horizontal flip
    dc.b $0e, $0c, $0a, $08, $06, $04, $02, $00
    dc.b $1e, $1c, $1a, $18, $16, $14, $12, $10
    dc.b $2e, $2c, $2a, $28, $26, $24, $22, $20
    dc.b $3e, $3c, $3a, $38, $36, $34, $32, $30
    dc.b $4e, $4c, $4a, $48, $46, $44, $42, $40
    dc.b $5e, $5c, $5a, $58, $56, $54, $52, $50
    dc.b $6e, $6c, $6a, $68, $66, $64, $62, $60
    dc.b $7e, $7c, $7a, $78, $76, $74, $72, $70

    ; Vertical flip
    dc.b $70, $72, $74, $76, $78, $7a, $7c, $7e
    dc.b $60, $62, $64, $66, $68, $6a, $6c, $6e
    dc.b $50, $52, $54, $56, $58, $5a, $5c, $5e
    dc.b $40, $42, $44, $46, $48, $4a, $4c, $4e
    dc.b $30, $32, $34, $36, $38, $3a, $3c, $3e
    dc.b $20, $22, $24, $26, $28, $2a, $2c, $2e
    dc.b $10, $12, $14, $16, $18, $1a, $1c, $1e
    dc.b $00, $02, $04, $06, $08, $0a, $0c, $0e

    ; Horizontal and vertical flip
    dc.b $7e, $7c, $7a, $78, $76, $74, $72, $70
    dc.b $6e, $6c, $6a, $68, $66, $64, $62, $60
    dc.b $5e, $5c, $5a, $58, $56, $54, $52, $50
    dc.b $4e, $4c, $4a, $48, $46, $44, $42, $40
    dc.b $3e, $3c, $3a, $38, $36, $34, $32, $30
    dc.b $2e, $2c, $2a, $28, $26, $24, $22, $20
    dc.b $1e, $1c, $1a, $18, $16, $14, $12, $10
    dc.b $0e, $0c, $0a, $08, $06, $04, $02, $00

    SECTION_END
