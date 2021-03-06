;------------------------------------------------------------------------------------------
; Camera system.
;
; NB: Managed by Viewport. API should not be used directly
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Camera structure
; ----------------
    DEFINE_STRUCT Camera
        STRUCT_MEMBER.w camX
        STRUCT_MEMBER.w camY
        STRUCT_MEMBER.w camMinX
        STRUCT_MEMBER.w camMaxX
        STRUCT_MEMBER.w camMinY
        STRUCT_MEMBER.w camMaxY
        STRUCT_MEMBER.w camXDisplacement
        STRUCT_MEMBER.w camYDisplacement
        STRUCT_MEMBER.w camLastXDisplacement
        STRUCT_MEMBER.w camLastYDisplacement
        STRUCT_MEMBER.w camAbsoluteMaxX
        STRUCT_MEMBER.w camAbsoluteMaxY
        STRUCT_MEMBER.l camMapAddress
        STRUCT_MEMBER.l camPlaneId
        STRUCT_MEMBER.w camWidthPatterns
        STRUCT_MEMBER.w camHeightPatterns
        ; Externally managed
        STRUCT_MEMBER.l camMoveCallback             ; Mandatory
        STRUCT_MEMBER.l camData
    DEFINE_STRUCT_END


;-------------------------------------------------
; Add camera displacement
; ----------------
; Input:
; - a0: Camera
CAMERA_MOVE Macro xDisp, yDisp
        add.w  \xDisp, camXDisplacement(a0)
        add.w  \yDisp, camYDisplacement(a0)
    Endm


;-------------------------------------------------
; Initialize camera to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: Camera to initialize
; - a1: Map to associate with camera
; - d0: x
; - d1: y
; - d2: width
; - d3: height
; - d4: Associated plane id
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

        ; Associate map
        move.l  a1, camMapAddress(a0)

		; Set plane id
		move.l	d4, camPlaneId(a0)

        ; Store maximum camera bounds based on the current map
        move.w  mapWidthPixels(a1), d5
        move.w  mapHeightPixels(a1), d6
        sub.w   (vdpMetrics + vdpScreenWidth), d5
        sub.w   (vdpMetrics + vdpScreenHeight), d6
        subq.w  #1, d5
        subq.w  #1, d6
        move.w  d5, camAbsoluteMaxX(a0)
        move.w  d6, camAbsoluteMaxY(a0)

        ; Clamp camera position to map
        _VIEWPORT_CLAMP d0, mapWidthPixels,  vdpScreenWidth
        _VIEWPORT_CLAMP d1, mapHeightPixels, vdpScreenHeight

        moveq   #0, d4
        move.w  d0, camX(a0)
        move.w  d1, camY(a0)
        move.l  d4, camXDisplacement(a0)    ; Reset both camXDisplacement and camYDisplacement
        move.l  d4, camLastXDisplacement(a0); Reset both camLastXDisplacement and camLastYDisplacement

        ; Clamp VPD plane to map
        _VIEWPORT_CLAMP d0, mapWidthPixels,  vdpPlaneWidth
        _VIEWPORT_CLAMP d1, mapHeightPixels, vdpPlaneHeight

        ; Special case optimization: if (plane size == map size) then render full plane and effectively disable runtime map streaming
        move.w  mapWidthPixels(a1), d5
        swap    d5
        move.w  mapHeightPixels(a1), d5
        move.w  (vdpMetrics + vdpPlaneWidth), d6
        swap    d6
        move.w  (vdpMetrics + vdpPlaneHeight), d6
        sub.l   d5, d6
        bne     .skipMapPlaneOptimization
            move.w  mapWidthPixels(a1), d2
            move.w  mapHeightPixels(a1), d3
    .skipMapPlaneOptimization:

        ; Store camera size in patterns
        move.w  d2, d5
        move.w  d3, d6
        lsr.w   #PATTERN_SHIFT, d5
        lsr.w   #PATTERN_SHIFT, d6
        move.w  d5, camWidthPatterns(a0)
        move.w  d6, camHeightPatterns(a0)

        ; Calculate camera min position
        andi.w  #~PATTERN_MASK, d0
        andi.w  #~PATTERN_MASK, d1
        move.w  d0, camMinX(a0)
        move.w  d1, camMinY(a0)

        ; Calculate camera max position
        sub.w   (vdpMetrics + vdpScreenWidth), d2
        sub.w   (vdpMetrics + vdpScreenHeight), d3
        add.w   d2, d0
        add.w   d3, d1
        subq.w  #1, d0
        subq.w  #1, d1
        move.w  d0, camMaxX(a0)
        move.w  d1, camMaxY(a0)

        ; Initialize movement handler
        movea.l  camMoveCallback(a0), a1
        jsr     (a1)

        Purge _VIEWPORT_CLAMP
        rts


;-------------------------------------------------
; Render the complete camera view
; ----------------
; Input:
; - a0: Camera
; Uses: d0-d7/a0-a6
CameraRenderView:
        ; Render map at min position
        move.w  camMinY(a0), d0
        move.w  camMinX(a0), d1
        lsr.w   #PATTERN_SHIFT, d0
        lsr.w   #PATTERN_SHIFT, d1
        move.w  camWidthPatterns(a0), d2
        move.w  camHeightPatterns(a0), d3
        move.l  camPlaneId(a0), d4
        movea.l camMapAddress(a0), a0
        jsr     MapRender
    rts


;-------------------------------------------------
; Processes pending camera movement updates
; Maximum movement speed is 8 pixels in either direction.
; If the current displacement exceeds 8 pixels multiple update cycles will be required to complete the camera movemement.
; Should be called once per application main update cycle
; ----------------
; Input:
; - a0: Camera
; Uses: d0-d7/a1-a6
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
                sub.w   d0, \displacement(a0)                   ; Update remaining displacement
                swap    d0
        Endm

; Assumes camera position in d1
_UPDATE_POSITION Macro maxPosition, displacement
                add.w   d0, d1                                  ; Add displacement
                blt     .camMinOverflow\@
                cmp.w   \maxPosition(a0), d1
                ble     .camOk\@

                ; Camera position > max: Reset displacement and set camera position to max
                clr.w   \displacement(a0)
                move.w  \maxPosition(a0), d1
                bra     .camOk\@

            .camMinOverflow\@:
                ; Camera position < 0: Reset displacement and set camera position to 0
                moveq   #0, d2
                move.w  d2, \displacement(a0)
                move.w  d2, d1

            .camOk\@:
                swap d1
                swap d0
        Endm

; Assumes camera position in d1
_UPDATE_MIN_MAX Macro minMax, store
                Local MIN_MAX_DISPLACEMENT
MIN_MAX_DISPLACEMENT Equ (PATTERN_DIMENSION << 16) | PATTERN_DIMENSION

                move.l  \minMax(a0), d4                         ; d4 = camMin:camMax
                cmp.w   d4, d1                                  ; Max overflow?
                bgt     .camMaxOverflow\@
                swap    d4
                cmp.w   d4, d1                                  ; Min overflow
                bge     .camOk\@

             .camMinOverflow\@:
                subi.l  #MIN_MAX_DISPLACEMENT, d4
                swap    d4
                move.l  d4, \minMax(a0)
                ori.w   #$01, d5
                bra     .camDone\@

            .camMaxOverflow\@:
                addi.l  #MIN_MAX_DISPLACEMENT, d4
                move.l  d4, \minMax(a0)
                ori.w   #$02, d5
                bra     .camDone\@

            .camOk\@:
                swap    d4

            .camDone\@:
                move.l  d4, \store
        Endm

_MAP_UPDATE Macro renderer, size
				PUSHL 	a0
                lsr.w   #PATTERN_SHIFT, d0
                lsr.w   #PATTERN_SHIFT, d1
                move.w  \size(a0), d2
                move.l  camPlaneId(a0), d3
                movea.l camMapAddress(a0), a0
                jsr     \renderer
				POPL 	a0
        Endm

        ; ---------------------------------------------------------------------------------------
        ; Start of sub routine CameraFinalize
        ; ----------------

        move.l  camXDisplacement(a0), d0                        ; Read camXDisplacement:camYDisplacement into d0
        bne     .updatePosition
        ; Nothing to update, clear last displacement and return
        moveq   #0, d4
        move.l  d4, camLastXDisplacement(a0)
        rts

    .updatePosition:
        ; Clamp displacement values to the maximum allowed for one update cycle
        _DISPLACEMENT_CLAMP camYDisplacement
        _DISPLACEMENT_CLAMP camXDisplacement

        ; Update camera position
        move.l  camX(a0), d1                                    ; Read camX:camY into d1
        move.l  d1, d3

        ; Update camera position within the bounds of the map
        _UPDATE_POSITION camAbsoluteMaxY, camYDisplacement
        _UPDATE_POSITION camAbsoluteMaxX, camXDisplacement

        ; Store new camera position (camX and camY)
        move.l  d1, camX(a0)

        ; Store actual movement of the camera
        move.l  d1, d4
        sub.w   d3, d4
        move.w  d4, camLastYDisplacement(a0)
        swap d3
        swap d4
        sub.w   d3, d4
        move.w  d4, camLastXDisplacement(a0)

        ; Check if there was movement. If so call movement callback
        tst.l   d4
        beq     .noMovement
            PUSHM   d1/a0
            movea.l camMoveCallback(a0), a1
            jsr     (a1)
            POPM    d1/a0
        .noMovement:

        ; Update min max for both dimensions
        moveq   #0, d5                                          ; d5 = render flags (0 = min, 1 = max)
        _UPDATE_MIN_MAX camMinY, d6                             ; d6 = updated min/max for y
        swap    d1
        add.w   d5, d5                                          ; Next render flag set
        add.w   d5, d5
        _UPDATE_MIN_MAX camMinX, d7                             ; d7 = updated min/max for x

        ; Stream new background data if necessary
        tst.l   d5
        beq     .done
            btst    #2, d5
            beq     .checkMaxY
                    PUSHM   d5/d7
                        swap    d6
                        move.w  d6, d0
                        move.w  camMinX(a0), d1

                        _MAP_UPDATE MapRenderRow, camWidthPatterns
                    POPM    d5/d7
                bra     .checkBackgroundYDone
            .checkMaxY:
                btst    #3, d5
                beq     .checkBackgroundYDone
                    PUSHM   d5/d7
                        move.w  d6, d0
                        add.w   (vdpMetrics + vdpScreenHeight), d0
                        move.w  camMinX(a0), d1

                        _MAP_UPDATE MapRenderRow, camWidthPatterns
                    POPM    d5/d7
            .checkBackgroundYDone:

            btst    #0, d5
            beq     .checkMaxX
                    swap    d7
                    move.w  d7, d0
                    move.w  camMinY(a0), d1

                    _MAP_UPDATE MapRenderColumn, camHeightPatterns
                bra     .checkBackgroundXDone
            .checkMaxX:
                btst    #1, d5
                beq     .checkBackgroundXDone
                    move.w  d7, d0
                    add.w   (vdpMetrics + vdpScreenWidth), d0
                    move.w  camMinY(a0), d1

                    _MAP_UPDATE MapRenderColumn, camHeightPatterns
            .checkBackgroundXDone:

    .done:
        Purge _DISPLACEMENT_CLAMP
        Purge _UPDATE_POSITION
        Purge _UPDATE_MIN_MAX
        Purge _MAP_UPDATE
        rts
