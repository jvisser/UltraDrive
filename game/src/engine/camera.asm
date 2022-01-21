;------------------------------------------------------------------------------------------
; Camera system.
;
; NB: Managed by Viewport. API should not be used directly
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'

    Include './engine/include/camera.inc'
    Include './engine/include/map.inc'

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
                bpl.s   .positive\@
                moveq   #0, \component
                bra.s   .clampDone\@

            .positive\@:
                move.w  \mapSize(a1), d7
                sub.w   (vdpMetrics + \screenSize), d7
                cmp.w   d7, \component
                blt.s   .clampDone\@
                move.w  d7, \component

            .clampDone\@:
        Endm

        ; Associate map
        move.l  a1, Camera_mapAddress(a0)

		; Set plane id
		move.l	d4, Camera_planeId(a0)

        ; Set default renderers
        move.l  #_CameraRenderRow, Camera_rowRenderer(a0)
        move.l  #_CameraRenderColumn, Camera_columnRenderer(a0)

        ; Store maximum camera bounds based on the current map
        move.w  Map_widthPixels(a1), d5
        move.w  Map_heightPixels(a1), d6
        sub.w   (vdpMetrics + VDPMetrics_screenWidth), d5
        sub.w   (vdpMetrics + VDPMetrics_screenHeight), d6
        subq.w  #1, d5
        subq.w  #1, d6
        move.w  d5, Camera_absoluteMaxX(a0)
        move.w  d6, Camera_absoluteMaxY(a0)

        ; Clamp camera position to map
        _VIEWPORT_CLAMP d0, Map_widthPixels,  VDPMetrics_screenWidth
        _VIEWPORT_CLAMP d1, Map_heightPixels, VDPMetrics_screenHeight

        moveq   #0, d4
        move.w  d0, Camera_x(a0)
        move.w  d1, Camera_y(a0)
        move.l  d4, Camera_xDisplacement(a0)                        ; Reset both xDisplacement and yDisplacement
        move.l  d4, Camera_lastXDisplacement(a0)                    ; Reset both lastXDisplacement and lastYDisplacement

        ; Clamp VPD plane to map
        _VIEWPORT_CLAMP d0, Map_widthPixels,  VDPMetrics_planeWidth
        _VIEWPORT_CLAMP d1, Map_heightPixels, VDPMetrics_planeHeight

        ; Special case optimization: if (plane size == map size) then render full plane and effectively disable runtime map streaming
        move.w  Map_widthPixels(a1), d5
        swap    d5
        move.w  Map_heightPixels(a1), d5
        move.w  (vdpMetrics + VDPMetrics_planeWidth), d6
        swap    d6
        move.w  (vdpMetrics + VDPMetrics_planeHeight), d6
        sub.l   d5, d6
        bne.s   .skipMapPlaneOptimization
            move.w  Map_widthPixels(a1), d2
            move.w  Map_heightPixels(a1), d3
    .skipMapPlaneOptimization:

        ; Store camera size in patterns
        move.w  d2, d5
        move.w  d3, d6
        lsr.w   #PATTERN_SHIFT, d5
        lsr.w   #PATTERN_SHIFT, d6
        move.w  d5, Camera_widthPatterns(a0)
        move.w  d6, Camera_heightPatterns(a0)

        ; Calculate camera min position
        andi.w  #~PATTERN_MASK, d0
        andi.w  #~PATTERN_MASK, d1
        move.w  d0, Camera_minX(a0)
        move.w  d1, Camera_minY(a0)

        ; Calculate camera max position
        sub.w   (vdpMetrics + VDPMetrics_screenWidth), d2
        sub.w   (vdpMetrics + VDPMetrics_screenHeight), d3
        add.w   d2, d0
        add.w   d3, d1
        subq.w  #1, d0
        subq.w  #1, d1
        move.w  d0, Camera_maxX(a0)
        move.w  d1, Camera_maxY(a0)

        ; Initialize movement handler
        movea.l  Camera_moveCallback(a0), a1
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
        move.w  Camera_minY(a0), d0
        move.w  Camera_minX(a0), d1
        lsr.w   #PATTERN_SHIFT, d0
        lsr.w   #PATTERN_SHIFT, d1
        move.w  Camera_widthPatterns(a0), d2
        move.l  Camera_planeId(a0), d3
        move.w  Camera_heightPatterns(a0), d4
        movea.l Camera_rowRenderer(a0), a1

        subq.w  #1, d4

    .rowLoop:
            PUSHM.w d0-d2/d4
            PUSHM.l d3/a0-a1
            jsr     (a1)
            POPM.l  d3/a0-a1
            POPM.w  d0-d2/d4

            addq.w  #1, d0
        dbra    d4, .rowLoop
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
                blt.s   .clampMin\@
                cmpi.w  #PATTERN_DIMENSION, d0
                blt.s   .clampOk\@
                move.w  #PATTERN_DIMENSION, d0
                bra.s   .clampOk\@

            .clampMin\@:
                move.w  #-PATTERN_DIMENSION, d0

            .clampOk\@:
                sub.w   d0, \displacement(a0)                       ; Update remaining displacement
                swap    d0
        Endm

; Assumes camera position in d1
_UPDATE_POSITION Macro maxPosition, displacement
                add.w   d0, d1                                      ; Add displacement
                blt.s   .camMinOverflow\@
                cmp.w   \maxPosition(a0), d1
                ble.s   .camOk\@

                ; Camera position > max: Reset displacement and set camera position to max
                clr.w   \displacement(a0)
                move.w  \maxPosition(a0), d1
                bra.s   .camOk\@

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

                move.l  \minMax(a0), d4                             ; d4 = camMin:camMax
                cmp.w   d4, d1                                      ; Max overflow?
                bgt.s   .camMaxOverflow\@
                swap    d4
                cmp.w   d4, d1                                      ; Min overflow
                bge.s   .camOk\@

             .camMinOverflow\@:
                subi.l  #MIN_MAX_DISPLACEMENT, d4
                swap    d4
                move.l  d4, \minMax(a0)
                ori.w   #$01, d5
                bra.s   .camDone\@

            .camMaxOverflow\@:
                addi.l  #MIN_MAX_DISPLACEMENT, d4
                move.l  d4, \minMax(a0)
                ori.w   #$02, d5
                bra.s   .camDone\@

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
                move.l  Camera_planeId(a0), d3
                movea.l Camera_\renderer(a0), a1
                jsr     (a1)
				POPL 	a0
        Endm

        ; ---------------------------------------------------------------------------------------
        ; Start of sub routine CameraFinalize
        ; ----------------

        move.l  Camera_xDisplacement(a0), d0                        ; Read xDisplacement:yDisplacement into d0
        bne.s   .updatePosition
        ; Nothing to update, clear last displacement and return
        moveq   #0, d4
        move.l  d4, Camera_lastXDisplacement(a0)
        rts

    .updatePosition:
        ; Clamp displacement values to the maximum allowed for one update cycle
        _DISPLACEMENT_CLAMP Camera_yDisplacement
        _DISPLACEMENT_CLAMP Camera_xDisplacement

        ; Update camera position
        move.l  Camera_x(a0), d1                                    ; Read x:y into d1
        move.l  d1, d3

        ; Update camera position within the bounds of the map
        _UPDATE_POSITION Camera_absoluteMaxY, Camera_yDisplacement
        _UPDATE_POSITION Camera_absoluteMaxX, Camera_xDisplacement

        ; Store new camera position (x and y)
        move.l  d1, Camera_x(a0)

        ; Store actual movement of the camera
        move.l  d1, d4
        sub.w   d3, d4
        move.w  d4, Camera_lastYDisplacement(a0)
        swap d3
        swap d4
        sub.w   d3, d4
        move.w  d4, Camera_lastXDisplacement(a0)

        ; Check if there was movement. If so call movement callback
        tst.l   d4
        beq.s   .noMovement
            PUSHL   d1
            PUSHL   a0
            movea.l Camera_moveCallback(a0), a1
            jsr     (a1)
            POPL    a0
            POPL    d1
        .noMovement:

        ; Update min max for both dimensions
        moveq   #0, d5                                              ; d5 = render flags (0 = min, 1 = max)
        _UPDATE_MIN_MAX Camera_minY, d6                             ; d6 = updated min/max for y
        swap    d1
        add.w   d5, d5                                              ; Next render flag set
        add.w   d5, d5
        _UPDATE_MIN_MAX Camera_minX, d7                             ; d7 = updated min/max for x

        ; Stream new background data if necessary
        tst.l   d5
        beq     .done
            btst    #2, d5
            beq.s   .checkMaxY
                    PUSHW   d5
                    PUSHL   d7
                        swap    d6
                        move.w  d6, d0
                        move.w  Camera_minX(a0), d1

                        _MAP_UPDATE rowRenderer, Camera_widthPatterns
                    POPL    d7
                    POPW    d5
                bra.s   .checkBackgroundYDone
            .checkMaxY:
                btst    #3, d5
                beq.s   .checkBackgroundYDone
                    PUSHW   d5
                    PUSHL   d7
                        move.w  d6, d0
                        add.w   (vdpMetrics + VDPMetrics_screenHeight), d0
                        move.w  Camera_minX(a0), d1

                        _MAP_UPDATE rowRenderer, Camera_widthPatterns
                    POPL    d7
                    POPW    d5
            .checkBackgroundYDone:

            btst    #0, d5
            beq.s   .checkMaxX
                    swap    d7
                    move.w  d7, d0
                    move.w  Camera_minY(a0), d1

                    _MAP_UPDATE columnRenderer, Camera_heightPatterns
                bra.s   .checkBackgroundXDone
            .checkMaxX:
                btst    #1, d5
                beq.s   .checkBackgroundXDone
                    move.w  d7, d0
                    add.w   (vdpMetrics + VDPMetrics_screenWidth), d0
                    move.w  Camera_minY(a0), d1

                    _MAP_UPDATE columnRenderer, Camera_heightPatterns
            .checkBackgroundXDone:

    .done:
        Purge _DISPLACEMENT_CLAMP
        Purge _UPDATE_POSITION
        Purge _UPDATE_MIN_MAX
        Purge _MAP_UPDATE
        rts


;-------------------------------------------------
; Default camera row render implementation.
; ----------------
; Input:
; - a0: Camera
; - d0: Map row
; - d1: Map start column
; - d2: Width to render
; - d3.l: VDP plane id
; Uses: d0-d7/a0-a6
_CameraRenderRow:
        movea.l Camera_mapAddress(a0), a0
        jmp     MapRenderRow


;-------------------------------------------------
; Default camera column render implementation.
; ----------------
; - d0: Map column
; - d1: Map start row
; - d2: Height to render
; - d3.l: VDP plane id
; Uses: d0-d7/a0-a6
_CameraRenderColumn:
        movea.l Camera_mapAddress(a0), a0
        jmp     MapRenderColumn

