;------------------------------------------------------------------------------------------
; Camera system
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Map structures
; ----------------
    DEFINE_STRUCT Camera
        STRUCT_MEMBER.w camX
        STRUCT_MEMBER.w camY
        STRUCT_MEMBER.w camMinX
        STRUCT_MEMBER.w camMaxX
        STRUCT_MEMBER.w camMinY
        STRUCT_MEMBER.w camMaxY
        STRUCT_MEMBER.l camScrollUpdate
        STRUCT_MEMBER.w camXDisplacement
        STRUCT_MEMBER.w camYDisplacement
        STRUCT_MEMBER.w camAbsoluteMaxX
        STRUCT_MEMBER.w camAbsoluteMaxY
    DEFINE_STRUCT_END

    DEFINE_VAR FAST
        VAR.Camera camera
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize camera to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: Address of scroll update routine. If null the default will be used (update first entry of horizontal/vertical scroll ram)
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
CameraInit:
_VIEWPORT_CLAMP Macro component, mapSize, screenSize
                tst.w   \component
                bpl     .positive\@
                moveq   #0, \component
                bra     .clampDone\@

            .positive\@:
                move.w  \mapSize(a1), d7
                sub.w   (vdpMetrics + \screenSize), d7
                cmp.w   d7, \component
                blt     .clampDone\@
                move.w  d7, \component

            .clampDone\@:
        Endm

        ; Set scroll update routine
        cmpa.w  #0, a0
        bne     .scrollHandlerSupplied
        lea     _CameraDefaultScrollUpdate, a0

    .scrollHandlerSupplied:
        move.l  a0, (camera + camScrollUpdate)

        ; Store maximum camera bounds based on the current map
        movea.l loadedMap, a1
        move.l  mapWidthPixels(a1), d2
        sub.l   (vdpMetrics + vdpScreenWidth), d2  ; Can never yield a negative result
        move.l  d2, (camera + camAbsoluteMaxX)     ; Update both camAbsoluteMaxX and camAbsoluteMaxY

        ; Clamp viewport to map
        _VIEWPORT_CLAMP d0, mapWidthPixels,  vdpScreenWidth
        _VIEWPORT_CLAMP d1, mapHeightPixels, vdpScreenHeight

        move.w  d0, d2
        move.w  d1, d3
        moveq   #0, d4
        move.w  d0, (camera + camX)
        move.w  d1, (camera + camY)
        move.l  d4, (camera + camXDisplacement)    ; Reset both camXDisplacement and camYDisplacement

        ; Clamp VPD plane to map
        _VIEWPORT_CLAMP d0, mapWidthPixels,  vdpPlaneWidth
        _VIEWPORT_CLAMP d1, mapHeightPixels, vdpPlaneHeight

        ; Calculate camera min position based on VDP plane (pattern aligned)
        andi.w  #~PATTERN_MASK, d0
        andi.w  #~PATTERN_MASK, d1
        move.w  d0, (camera + camMinX)
        move.w  d1, (camera + camMinY)
        move.w  d0, d4
        move.w  d1, d5

        ; Calculate camera max position
        add.w   (vdpMetrics + vdpPlaneWidth), d0
        add.w   (vdpMetrics + vdpPlaneHeight), d1
        sub.w   (vdpMetrics + vdpScreenWidth), d0
        sub.w   (vdpMetrics + vdpScreenHeight), d1
        move.w  d0, (camera + camMaxX)
        move.w  d1, (camera + camMaxY)

        ; Update scroll
        move.w  d2, d0
        move.w  d3, d1
        jsr     (a0)

        ; Render map at min position
        lsr.w   #PATTERN_SHIFT, d4                  ; Calculate map position in (8 pixel) columns and rows
        lsr.w   #PATTERN_SHIFT, d5
        move.w  d4, d1
        move.w  d5, d0
        move.l  #VDP_PLANE_A, d2
        jsr     MapRender

        Purge _VIEWPORT_CLAMP
        rts


;-------------------------------------------------
; Default hardware scroll camera update handler
; ----------------
; Input:
; - d0: Horizontal scroll
; - d1: Vertical scroll
; Uses: d0-d1
_CameraDefaultScrollUpdate:
        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR
        neg.w   d0
        move.w  d0, (MEM_VDP_DATA)

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $00
        move.w  d1, (MEM_VDP_DATA)
        rts


;-------------------------------------------------
; Adjust camera displacement in both directions for the following update cycle
; ----------------
; Input:
; - d0: Horizontal displacement
; - d1: Vertical displacement
; Uses: d0-d1
CameraMove:
        add.w  d0, (camera + camXDisplacement)
        add.w  d1, (camera + camYDisplacement)
        rts


;-------------------------------------------------
; Processes pending camera movement updates
; Maximum movement speed is 8 pixels in either direction.
; If the current displacement exceeds 8 pixels multiple update cycles will be required to complete the camera movemement.
; Should be called once per display frame.
; ----------------
; Uses: d0-d7/a0-a6
CameraFinalize:
_DISPLACEMENT_CLAMP Macro displacement
                cmpi.w  #-PATTERN_DIMENSION, d0
                blt     .clampMin\@
                cmpi.w  #PATTERN_DIMENSION, d0
                blt     .clampOk\@
                move.w  #PATTERN_DIMENSION, d0
                bra     .clampOk\@

            .clampMin\@:
                move.w  #-PATTERN_DIMENSION, d0

            .clampOk\@:
                sub.w   d0, (camera + \displacement)            ; Update remaining displacement
                swap    d0
        Endm

; Assumes camera position in d1
_UPDATE_POSITION Macro maxPosition, displacement
                add.w   d0, d1                                  ; Add displacement
                blt     .camMinOverflow\@
                cmp.w   (camera + \maxPosition), d1
                blt     .camMaxOk\@

                ; Camera position > max: Reset displacement and set camera position to max
                move.w  #0, (camera + \displacement)
                move.w  (camera + \maxPosition), d1
                bra     .camMaxOk\@

            .camMinOverflow\@:
                ; Camera position < 0: Reset displacement and set camera position to 0
                moveq   #0, d2
                move.w  d2, (camera + \displacement)
                move.w  d2, d1

            .camMaxOk\@:
                swap d1
                swap d0
        Endm

; Assumes camera position in d1
_UPDATE_MIN_MAX Macro minMax, opposingMin, planePosition, screenSize, mapRenderer
                Local MIN_MAX_DISPLACEMENT

MIN_MAX_DISPLACEMENT Equ (PATTERN_DIMENSION << 16) | PATTERN_DIMENSION

                move.l  (camera + \minMax), d4                  ; d4 = camMin:camMax
                cmp.w   d4, d1                                  ; Max overflow?
                bgt     .camMaxOverflow\@
                swap    d4
                cmp.w   d4, d1                                  ; Min overflow
                bge     .camOk\@

             .camMinOverflow\@:
                PUSHL   d1
                subi.l  #MIN_MAX_DISPLACEMENT, d4
                move.w  d4, d0
                swap    d4
                move.l  d4, (camera + \minMax)
                move.w  (camera + opposingMin), d1
                lsr.w   #PATTERN_SHIFT, d0                      ; d0 = Map source row/column (based on camMin)
                lsr.w   #PATTERN_SHIFT, d1                      ; d1 = Map start
                move.l  #VDP_PLANE_A, d2                        ; d2 = Target plane
                jsr     \mapRenderer
                POPL    d1
                bra     .camOk\@

            .camMaxOverflow\@:
                PUSHL   d1
                move.w  d4, d0
                addi.l  #MIN_MAX_DISPLACEMENT, d4
                move.l  d4, (camera + \minMax)
                add.w   (vdpMetrics + \screenSize), d0
                move.w  (camera + opposingMin), d1
                lsr.w   #PATTERN_SHIFT, d0                      ; d0 = Map source row/column (based on camMax)
                lsr.w   #PATTERN_SHIFT, d1                      ; d1 = Map start
                move.l  #VDP_PLANE_A, d2                        ; d2 = Target plane
                jsr     \mapRenderer
                POPL    d1
            .camOk\@:
        Endm

        ; ---------------------------------------------------------------------------------------
        ; Start of sub routine CameraFinalize
        ; ----------------

        move.l  (camera + camXDisplacement), d0                 ; Read camXDisplacement:camYDisplacement into d0
        bne     .updatePosition
        rts                                                     ; Nothing to update

    .updatePosition:
        ; Clamp displacement values to the maximum allowed for one update cycle
        _DISPLACEMENT_CLAMP camYDisplacement
        _DISPLACEMENT_CLAMP camXDisplacement

        ; Update camera position
        move.l  (camera + camX), d1                             ; Read camX:camY into d1

        ; Update camera position within the bounds of the map
        _UPDATE_POSITION camAbsoluteMaxY, camYDisplacement
        _UPDATE_POSITION camAbsoluteMaxX, camXDisplacement

        ; Store new camera position (camX and camY)
        move.l  d1, (camera + camX)

        ; Check if background plane should be updated
        _UPDATE_MIN_MAX camMinY, camMinX, camPlaneRow, vdpScreenHeight, MapRenderRow
        swap    d1
        _UPDATE_MIN_MAX camMinX, camMinY, camPlaneColumn, vdpScreenWidth, MapRenderColumn

    .done:
        Purge _DISPLACEMENT_CLAMP
        Purge _UPDATE_POSITION
        Purge _UPDATE_MIN_MAX
        rts


;-------------------------------------------------
; Prepares the next display frame with the updated camera position.
; Should be called during vblank only
; ----------------
CameraPrepareNextFrame:
        move.l  (camera + camX), d1
        move.l  d1, d0
        swap    d0
        movea.l (camera + camScrollUpdate), a3
        jmp (a3)
