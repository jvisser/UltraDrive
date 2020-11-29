;------------------------------------------------------------------------------------------
; Map collision routines (Work for slopes with normals between 45 and 90 degrees)
;------------------------------------------------------------------------------------------
; Sub routines:
; - MapCollisionFindFloor
; - MapCollisionFindCeiling
; - MapCollisionFindLeftWall
; - MapCollisionFindRightWall


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
; Macros shared between all collision detection routines
; ----------------

;-------------------------------------------------
; Read block ref from current chunk
; ----------------
; Required:
; - a3: map data base address
; - d5: map chunk ref offset
; Output:
; - d3: chunk ref
_READ_CHUNK_REF Macro
        move.w  (a3, d5), d3                                ; d3 = chunk ref
    Endm


;-------------------------------------------------
; Load data table addresses, calculate chunk/block offsets and read chunk/block refs
; ----------------
; Required:
; - d0: x in pixels
; - d1: y in pixels
; Output:
; - a2: row offset table base address
; - a3: map data base address
; - d3: chunk ref
_START_CHUNK Macro
        lea     mapRowOffsetTable(a0), a2
        movea.l mapDataAddress(a0), a3
        move.w  d1, d2
        lsr.w   #7, d2
        add.w   d2, d2
        move.w  (a2, d2), d5                                        ; d5 = map row offset
        move.w  d0, d2
        lsr.w   #7, d2
        add.w   d2, d2
        add.w   d2, d5                                              ; d5 = chunk ref offset

        _READ_CHUNK_REF
    Endm


;-------------------------------------------------
; Read block ref from current chunk
; ----------------
; Required:
; - a5: block offset table base address
; - a4: chunk base address
; - d7: chunk relative block offset
; Output:
; - d2: block ref
_READ_BLOCK_REF Macro
        move.b  (a5, d7), d2
        ext.w   d2
        move.w  (a4, d2), d2
    Endm


;-------------------------------------------------
; Load chunk data base address and block offset table base address
; ----------------
; Required:
; - a5: block offset table base address
; - a4: chunk base address
; - d0: x in pixels
; - d1: y in pixels
; - d3: chunk ref
; Output:
; - a4: chunk data base address
; - a5: block offset table base address
; - a6: chunk table address
; - d2: chunk ref
; - d7: chunk relative block offset
_LOAD_CHUNK Macro scratch
        lea     chunkTable, a6

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

        ; Calculate chunk relative block offset
        move.w  d1, d2
        lsr.w   #1, d2
        andi.w  #$0038, d2
        move.w  d0, d7
        lsr.w   #4, d7
        andi.w  #$0007, d7
        add.w   d2, d7                                          ; d7 = Chunk block offset table offset

        _READ_BLOCK_REF
    Endm


;-------------------------------------------------
; Verify chunk contains collision data. If not jump to specified label.
; ----------------
; Required:
; - d3: chunk ref
_VERIFY_CHUNK_COLLISION_PRESENT Macro invalidLabel
        btst    #CHUNK_REF_COLLISION, d3
        beq     \invalidLabel
    Endm


;-------------------------------------------------
; Verify that block has the proper solidity. If not jump to the specified label.
; ----------------
; Required:
; - d2: block ref
_VERIFY_BLOCK_SOLIDITY Macro invalidLabel
        btst    #BLOCK_REF_SOLID_\0, d2
        beq     \invalidLabel
    Endm


;-------------------------------------------------
; Load chunk data base address and block offset table base address
; ----------------
; Required:
; - a2: tileset block meta data mapping table
; Output:
; - d4: meta data id
_READ_BLOCK_META_DATA_ID Macro blockRef
        andi.w  #BLOCK_REF_INDEX_MASK, \blockRef
        add.w   \blockRef, \blockRef
        move.w  (a2, \blockRef), d4                                    ; d4 = block meta data id    Endm
    Endm


;-------------------------------------------------
; Load chunk data base address and block offset table base address
; ----------------
; Required:
; - d4: meta data id
; Output:
; - a2: collision data base address
; - d2: angle (byte)
; - d5: collision data index
_READ_BLOCK_META_DATA Macro
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
    Endm


;-------------------------------------------------
; Floor vertical collision point finding algorithm
; ----------------
; General register allocation:
; - a0: map address
; - a2: map row offset table
; - a3: map data address
; - a4: chunk data base address
; - a5: block offset table base address
; - a6: chunk table address
; - d0: x
; - d1: y
; - d2: block ref
; - d3: chunk ref
; - d4: meta data id
; - d5: map chunk ref offset
; - d7: chunk relative block offset
; Required (supplied by implementor):
; - Macro: _VERIFY_BLOCK_ORIENTATION
; - Macro: _NEXT_BLOCK
; - Macro: _NEXT_CHUNK
; - Macro: _COLLISION_BLOCK_FOUND
_FIND_VERTICAL_COLLISION Macro requiredSolidity, solidBlockAngle
        _MAP_COLLISION_PROFILE_START

        _START_CHUNK

        _VERIFY_CHUNK_COLLISION_PRESENT .noCollision\@

            _LOAD_CHUNK d4

            _VERIFY_BLOCK_SOLIDITY.\requiredSolidity .noCollision\@

            ; Get meta data id (collision + angle index)
            movea.l tilesetMetaDataMapping, a2
            move.w  d2, d4

            _READ_BLOCK_META_DATA_ID d4

            bne .collisionBlockFound\@

                ; We found a solid block we need to also check the vertically adjacent block (slope case)

                _NEXT_BLOCK .checkNextChunk\@

                    _READ_BLOCK_REF

                    bra .checkNextBlock\@

            .checkNextChunk\@:

                ; Find next block in next chunk

                _NEXT_CHUNK
                _READ_CHUNK_REF

                _VERIFY_CHUNK_COLLISION_PRESENT .topNoCollision\@

                _LOAD_CHUNK     d2
                _READ_BLOCK_REF

            .checkNextBlock\@:

                    eor.w   d2, d3                                  ; d3 = block orientation

                    _VERIFY_BLOCK_ORIENTATION                 .topNoCollision\@
                    _VERIFY_BLOCK_SOLIDITY.\requiredSolidity  .topNoCollision\@

                    ; We have found a collision block. Update meta data id
                    _READ_BLOCK_META_DATA_ID d2

                    bra .validCollisionFound\@

                .topNoCollision\@:

                    ; Solid blocks always have a fixed angle (up or down)
                    move.w   #\solidBlockAngle, d2

                    _MAP_COLLISION_PROFILE_END
                    rts

            .collisionBlockFound\@:

                eor.w   d2, d3                                  ; d3 = block orientation

                ; Check if orientation of the block is in alignment with this operation (= non v flipped)
                _VERIFY_BLOCK_ORIENTATION .noCollision\@

            .validCollisionFound\@:

                _READ_BLOCK_META_DATA

                _COLLISION_BLOCK_FOUND

    .noCollision\@:

            ; Set angle to -1 indicating no collision
            moveq   #-1, d2

            _MAP_COLLISION_PROFILE_END

        Purge _VERIFY_BLOCK_ORIENTATION
        Purge _NEXT_BLOCK
        Purge _NEXT_CHUNK
        Purge _COLLISION_BLOCK_FOUND
    Endm


;-------------------------------------------------
; Floor horizontal collision point finding algorithm
; ----------------
; General register allocation:
; - a0: map address
; - a2: map row offset table
; - a3: map data address
; - a4: chunk data base address
; - a5: block offset table base address
; - a6: chunk table address
; - d0: x
; - d1: y
; - d2: block ref
; - d3: chunk ref
; - d4: meta data id
; - d5: map chunk ref offset
; - d7: chunk relative block offset
; Required (supplied by implementor):
; - Macro: _COLLISION_BLOCK_FOUND
_FIND_HORIZONTAL_COLLISION Macro
        _MAP_COLLISION_PROFILE_START

        _START_CHUNK

        _VERIFY_CHUNK_COLLISION_PRESENT .noSolidCollision\@

            _LOAD_CHUNK d4

            _VERIFY_BLOCK_SOLIDITY.LRB .noSolidCollision\@

            ; Get meta data id (collision + angle index)
            movea.l tilesetMetaDataMapping, a2
            move.w  d2, d4

            _READ_BLOCK_META_DATA_ID d4

            bne .noSolidCollision\@

                _COLLISION_BLOCK_FOUND

                _MAP_COLLISION_PROFILE_END
                rts

        .noSolidCollision\@:

            ; Set angle to -1 indicating no collision
            moveq   #-1, d2

        _MAP_COLLISION_PROFILE_END

        Purge _COLLISION_BLOCK_FOUND
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
; Verify that block is not vertically flipped. If not jump to the specified label.
; ----------------
; Required:
; - d3: block orientation flags
_VERIFY_BLOCK_ORIENTATION Macro invalidLabel
                btst    #BLOCK_REF_VFLIP, d3
                bne     \invalidLabel
            Endm

;-------------------------------------------------
; Load next block in case of the current block being a solid block
; ----------------
; Required:
; - d0: x
; - d1: y
; - d7: chunk relative block offset
; Output:
; - d1: y coordinate adjusted for solid block
; - d7: chunk relative block offset adjusted for next block
_NEXT_BLOCK Macro nextChunkLabel
                ; Set Y to the top of the top of block
                andi.w  #~$0f, d1
                subq.w  #1, d1

                ; Try to find above block in current chunk
                sub.w   #CHUNK_DIMENSION, d7
                bmi     \nextChunkLabel
            Endm

;-------------------------------------------------
; Load next block in case of the current block being a solid block
; ----------------
; Required:
; - a0: Map address
; - d0: x
; - d1: y
; - d7: chunk relative block offset
; Output:
; - d1: y coordinate adjusted for solid block
_NEXT_CHUNK Macro
            ; Set chunk block offset at top of chunk
            add.w   #CHUNK_ELEMENT_COUNT, d7

            ; Go one row up in the map
            sub.w   mapStride(a0), d5
        Endm

;-------------------------------------------------
; valid collision block has been found. Extract result to be returned from subroutine
; ----------------
; Required:
; - a2: collision field base address
; - d0: x
; - d1: y
; - d2: angle
; - d3: block orientation
; - d5: collision field index
; Output:
; - d1: y coordinate adjusted by height field
; - d2: angle adjusted by horizontal orientation
_COLLISION_BLOCK_FOUND Macro
            btst    #BLOCK_REF_HFLIP, d3
            beq     .blockNoHFlip\@

                ; Horizontally flipped so add 90 degrees to angle
                add.w   #ANGLE_90, d2

                ; Invert collision field index
                not.w   d5
                andi.w  #$0f, d5

            .blockNoHFlip\@:

                ; Get collision field height
                move.b  (a2, d5), d5
                ext.w   d5

                ; Update y position
                move.w  d1, d6
                ori.w   #$0f, d6
                sub.w   d5, d6
                cmp.w   d6, d1
                ble     .noCollision\@

                    ; Store adjusted Y position
                    move.w  d6, d1

                _MAP_COLLISION_PROFILE_END
                rts

            .noCollision\@:
        Endm

        ;-------------------------------------------------
        ; Start of sub routine MapCollisionFindFloor
        ; ----------------
        _FIND_VERTICAL_COLLISION TOP, ANGLE_90
        rts


;-------------------------------------------------
; Find ceiling collision point
; ----------------
; Input:
; - a0: map
; - d0: x position
; - d1: y position
; Output:
; - d0: x position
; - d1: y position
; - d2: angle
MapCollisionFindCeiling:
;-------------------------------------------------
; Verify that block is vertically flipped. If not jump to the specified label.
; ----------------
; Required:
; - d3: block orientation flags
_VERIFY_BLOCK_ORIENTATION Macro invalidLabel
                btst    #BLOCK_REF_VFLIP, d3
                beq     \invalidLabel
            Endm

;-------------------------------------------------
; Load next block in case of the current block being a solid block
; ----------------
; Required:
; - d0: x
; - d1: y
; - d7: chunk relative block offset
; Output:
; - d1: y coordinate adjusted for solid block
; - d7: chunk relative block offset adjusted for next block
_NEXT_BLOCK Macro nextChunkLabel
                ; Set Y to the bottom of the bottom of block
                ori.w   #$0f, d1
                addq.w  #1, d1

                ; Try to find below block in current chunk
                add.w   #CHUNK_DIMENSION, d7
                btst    #6, d7                  ; >= CHUNK_ELEMENT_COUNT (=64) then check chunk below
                bne     \nextChunkLabel
            Endm

;-------------------------------------------------
; Load next block in case of the current block being a solid block
; ----------------
; Required:
; - a0: Map address
; - d0: x
; - d1: y
; - d7: chunk relative block offset
; Output:
; - d1: y coordinate adjusted for solid block
_NEXT_CHUNK Macro
            ; Set chunk block offset at bottom of chunk
            sub.w   #CHUNK_ELEMENT_COUNT, d7

            ; Go one row down in the map
            add.w   mapStride(a0), d5
        Endm

;-------------------------------------------------
; valid collision block has been found. Extract result to be returned from subroutine
; ----------------
; Required:
; - a2: collision field base address
; - d0: x
; - d1: y
; - d2: angle
; - d3: block orientation
; - d5: collision field index
; Output:
; - d1: y coordinate adjusted by height field
; - d2: angle adjusted by horizontal orientation
_COLLISION_BLOCK_FOUND Macro
            add.w   #ANGLE_270, d2

            btst    #BLOCK_REF_HFLIP, d3
            beq     .blockNoHFlip\@

                ; Horizontally flipped so subtract 90 degrees from angle
                sub.w   #ANGLE_90, d2

                ; Invert collision field index
                not.w   d5
                andi.w  #$0f, d5

            .blockNoHFlip\@:

                ; Get collision field height
                move.b  (a2, d5), d5
                ext.w   d5

                ; Update y position
                move.w  d1, d6
                andi.w   #~$0f, d6
                add.w   d5, d6
                cmp.w   d6, d1
                bgt     .noCollision\@

                    ; Store adjusted Y position
                    move.w  d6, d1

                _MAP_COLLISION_PROFILE_END
                rts

            .noCollision\@:
        Endm

        ;-------------------------------------------------
        ; Start of sub routine MapCollisionFindCeiling
        ; ----------------
        _FIND_VERTICAL_COLLISION LRB, ANGLE_270
    rts


;-------------------------------------------------
; Find left wall collision point
; ----------------
; Input:
; - a0: map
; - d0: x position
; - d1: y position
; Output:
; - d0: x position
; - d1: y position
; - d2: angle
MapCollisionFindLeftWall:
;-------------------------------------------------
; Valid collision block has been found. Extract result to be returned from subroutine
; ----------------
_COLLISION_BLOCK_FOUND Macro
        move.w  #ANGLE_180, d2
        ori.w   #$0f, d0
        addq.w  #1, d0
    Endm

    _FIND_HORIZONTAL_COLLISION
    rts


;-------------------------------------------------
; Find right wall collision point
; ----------------
; Input:
; - a0: map
; - d0: x position
; - d1: y position
; Output:
; - d0: x position
; - d1: y position
; - d2: angle
MapCollisionFindRightWall:
;-------------------------------------------------
; Valid collision block has been found. Extract result to be returned from subroutine
; ----------------
_COLLISION_BLOCK_FOUND Macro
        move.w  #ANGLE_0, d2
        andi.w  #~$0f, d0
        subq.w  #1, d0
    Endm

    _FIND_HORIZONTAL_COLLISION
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


    ;-------------------------------------------------
    ; Cleanup macros
    ; ----------------
    Purge _READ_CHUNK_REF
    Purge _START_CHUNK
    Purge _READ_BLOCK_REF
    Purge _LOAD_CHUNK
    Purge _VERIFY_CHUNK_COLLISION_PRESENT
    Purge _VERIFY_BLOCK_SOLIDITY
    Purge _READ_BLOCK_META_DATA_ID
    Purge _READ_BLOCK_META_DATA
    Purge _FIND_VERTICAL_COLLISION
    Purge _FIND_HORIZONTAL_COLLISION
    Purge _MAP_COLLISION_PROFILE_START
    Purge _MAP_COLLISION_PROFILE_END
