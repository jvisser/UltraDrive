;------------------------------------------------------------------------------------------
; Viewport. Manages background and foreground plane etc...
;------------------------------------------------------------------------------------------

    Include './common/include/debug.inc'

    Include './system/include/vdp.inc'

    Include './engine/include/viewport.inc'
    Include './engine/include/background.inc'
    Include './engine/include/map.inc'
    Include './engine/include/scroll.inc'

;-------------------------------------------------
; Viewport variables
; ----------------
    DEFINE_VAR SHORT
        VAR.Viewport viewport
    DEFINE_VAR_END


;-------------------------------------------------
; Initialize the viewport library with defaults. Called on engine init.
; ----------------
ViewportEngineInit:
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK background
        VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK foreground

        move.l  #_ViewportCameraChanged, (viewport + Viewport_foreground + Camera_moveCallback)
        rts


;-------------------------------------------------
; Initialize the viewport to point at the specified coordinates (within the bounds of the currently loaded map)
; ----------------
; Input:
; - a0: ViewportConfiguration address. If NULL the ViewportConfiguration of the currently loaded map is used.
; - d0: x
; - d1: y
; Uses: d0-d7/a0-a6
ViewportInit:
_INIT_SCROLL Macro orientation
            PEEKL   a1                                  ; a1 = current viewport configuration address
            lea     ViewportConfiguration_\orientation\ScrollConfiguration(a1), a1
            move.l  ScrollConfiguration_vdpScrollUpdaterAddress(a1), a2
            move.l  a2, (viewport + Viewport_\orientation\VDPScrollUpdater)
            move.l  VDPScrollUpdater_init(a2), a2
            lea     viewport, a0
            jsr     (a2)
        Endm

        VIEWPORT_TRACK_ENTITY_END

        ; Determine which viewport configuration to use and store in local variable
        MAP_GET a1
        cmpa.l  #NULL, a0
        bne.s   .viewportConfigurationOk
            ; Use map's default viewport configuration if non specified
            movea.l  MapHeader_viewportConfigurationAddress(a1), a0
    .viewportConfigurationOk:
        PUSHL   a0                                      ; Store current viewport configuration address in local variable

        ; Initialize foreground plane camera
        lea     (viewport + Viewport_foreground), a0
        movea.l MapHeader_foregroundAddress(a1), a1
        move.w  (vdpMetrics + VDPMetrics_screenWidth), d2
        addq.w  #PATTERN_DIMENSION, d2                                  ; Foreground camera width = screen width + 1 pattern for scrolling
        move.w  (vdpMetrics + VDPMetrics_screenHeight), d3
        addq.w  #PATTERN_DIMENSION, d3                                  ; Foreground camera height = screen height + 1 pattern for scrolling
        move.l  #VDP_PLANE_A, d4
        jsr     CameraInit

        ; Replace foreground camera renderers to render from the chunkRefCache
        move.l  #_ViewportRenderRow, Camera_rowRenderer(a0)
        move.l  #_ViewportRenderColumn, Camera_columnRenderer(a0)

        ; Let background tracker initialize the background camera
        MAP_GET a1
        PEEKL   a4                                      ; a4 = current viewport configuration address
        movea.l ViewportConfiguration_backgroundTrackerConfiguration(a4), a3
        move.l  a3, (viewport + Viewport_backgroundTrackerConfiguration)
        movea.l ViewportConfiguration_backgroundTracker(a4), a4
        move.l  a4, (viewport + Viewport_backgroundTracker)
        movea.l BackgroundTracker_init(a4), a4
        lea     (viewport + Viewport_background), a0
        movea.l MapHeader_backgroundAddress(a1), a1
        lea     (viewport + Viewport_foreground), a2
        move.l  #VDP_PLANE_B, d0
        jsr     (a4)

        ; Initialize scroll updaters
        _INIT_SCROLL horizontal
        _INIT_SCROLL vertical

        ; Restore stack (remove local used to save viewport configuration)
        POPL

        ; Init active object groups
        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1
        bsr     _ViewportInitActiveViewportData

        ; Render background
        jsr     VDPDMAQueueFlush        ; Causes at least 28 DMA queue entries, so flush first
        lea     (viewport + Viewport_background), a0
        jsr     CameraRenderView

        ; Render foreground
        jsr     VDPDMAQueueFlush
        lea     (viewport + Viewport_foreground), a0
        jsr     CameraRenderView

        ; One final DMA queue flush for a fresh start
        jmp     VDPDMAQueueFlush

        Purge _INIT_SCROLL


;-------------------------------------------------
; Move the viewport by the specified amount
; ----------------
; - d0: Horizontal displacement
; - d1: Vertical displacement
ViewportMove:
        lea     (viewport + Viewport_foreground), a0
        CAMERA_MOVE d0, d1
        rts


;-------------------------------------------------
; Update cameras
; ----------------
; Uses: d0-d7/a0-a6
ViewportFinalize:
_UPDATE_SCROLL Macro orientation
            move.l  (viewport + Viewport_\orientation\VDPScrollUpdater), a2
            move.l  VDPScrollUpdater_update(a2), a2
            lea     viewport, a0
            jsr     (a2)
        Endm

        lea     (viewport + Viewport_foreground), a0
        move.w  (viewport + Viewport_trackingEntity), d0
        beq.s   .noTrackingEntity
        movea.w d0, a1
        bsr     _ViewportEnsureEntityVisible
    .noTrackingEntity:

        ; Finalize foreground camera
        jsr     CameraFinalize

        ; Let the background tracker update the background camera
        movea.l (viewport + Viewport_backgroundTracker), a3
        movea.l BackgroundTracker_sync(a3), a3
        lea     (viewport + Viewport_background), a0
        lea     (viewport + Viewport_foreground), a1
        movea.l (viewport + Viewport_backgroundTrackerConfiguration), a2
        jsr     (a3)

        ; Finalize background camera
        lea     (viewport + Viewport_background), a0
        jsr     CameraFinalize

        ; Update VDP scroll tables
        _UPDATE_SCROLL horizontal
        _UPDATE_SCROLL vertical

        rts

        Purge _UPDATE_SCROLL


;-------------------------------------------------
; Update all objects in the viewport
; ----------------
; Uses: d0/d7/a0/a3-a6
ViewportUpdateObjects:
        lea     (viewport + Viewport_activeObjectGroups), a3
        move.w  (viewport + Viewport_activeObjectGroupCount), d7
        jmp     MapUpdateObjects


;-------------------------------------------------
; Ensure the tracking entity is within the viewport bounds
; ----------------
; Input:
; - a0: foreground camera
; - a1: tracking entity
; Uses: d0-d3
_ViewportEnsureEntityVisible
_ENSURE_ACTIVE_AREA Macro screenMetric, activeAreaSize, axis, result
                move.w  (vdpMetrics + \screenMetric), d2
                move.w   #\activeAreaSize, d3
                sub.w   d3, d2
                lsr.w   #1, d2
                move.w  Entity_\axis(a1), \result
                sub.w   Camera_\axis(a0), \result
                sub.w   Camera_\axis\Displacement(a0), \result
                sub.w   d2, \result
                ble.s   .done\@
                cmp.w   d3, \result
                ble.s   .ok\@
                sub.w   d3, \result
                bra.s   .done\@
            .ok\@:
                moveq   #0, \result
            .done\@:
        Endm

        _ENSURE_ACTIVE_AREA VDPMetrics_screenWidth,  VIEWPORT_ACTIVE_AREA_SIZE_H, x, d0
        _ENSURE_ACTIVE_AREA VDPMetrics_screenHeight, VIEWPORT_ACTIVE_AREA_SIZE_V, y, d1

        CAMERA_MOVE d0, d1

        Purge _ENSURE_ACTIVE_AREA
        rts


;-------------------------------------------------
; Called whenever the foreground camera changes
; ----------------
; Input:
; - a0: Camera
_ViewportCameraChanged
        PUSHL   a0
        bsr     _ViewportUpdateActiveViewportData
        POPL    a0

        movea.l  (viewport + Viewport_foregroundMovementCallback), a1
        jmp     (a1)


;-------------------------------------------------
; Calculate sub chunk id (as divided in 64x32 parts)
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: result, scratch
; Output:
; - result: sub chunk id
_CALCULATE_SUB_CHUNK_ID Macro result, scratch
        move.w  d0, \result
        move.w  d1, \scratch
        add.w   \result, \result
        andi.w  #$80, \result
        andi.w  #$60, \scratch
        or.w    \scratch, \result
    Endm


;-------------------------------------------------
; Setup viewport data
; ----------------
; Uses: d0-d7/a0-a6
_ViewportInitActiveViewportData:
        clr.l   (viewport + Viewport_activeObjectGroupConfigurationId)

        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1

        _CALCULATE_SUB_CHUNK_ID d2, d3

        move.w  d2, (viewport + Viewport_subChunkId)
        bra.s   __ViewportUpdateActiveViewportData


;-------------------------------------------------
; Update viewport data. Only updates when new chunks of the map become visible.
; ----------------
; Uses: d0-d7/a0-a6
_ViewportUpdateActiveViewportData:
        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1

        _CALCULATE_SUB_CHUNK_ID d2, d3

        move.w  (viewport + Viewport_subChunkId), d3
        eor.w   d2, d3
        bne.s   .updateActiveViewportData
            rts

    .updateActiveViewportData:
        move.w  d2, (viewport + Viewport_subChunkId)

        ; NB: Fall through to __ViewportUpdateActiveViewportData


;-------------------------------------------------
; Update/collect viewport data for the current viewport:
; - Viewport chunk cache
; - Active object groups
; - Shared object resource update routines
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
__ViewportUpdateActiveViewportData:

        clr.w   (viewport + Viewport_activeObjectGroupCount)

        ; Get number of columns in view
        moveq   #4, d2
        btst    #6, d0
        seq     d3
        ext.w   d3
        add.w   d3, d2
        move.w  d2, d3
        add.w   d3, d3
        move.w  d3, (viewport + Viewport_chunkRefCacheStride)
        subq.w  #1, d2                                                          ; d2 = number of columns - 1

        ; Get number of rows in view
        moveq   #2, d3
        move.w  d1, d4
        andi.w  #$0060, d4
        seq     d4
        ext.w   d4
        add.w   d4, d3                                                          ; d3 = number of rows - 1

        ; Convert pixel coordinates to chunk coordinates
        lsr.w   #7, d0                                                          ; d0 = horizontal chunk coordinate
        lsr.w   #7, d1                                                          ; d1 = vertical chunk coordinate

        ; Get pointers
        MAP_GET a0
        movea.l MapHeader_metadataMapAddress(a0), a1                            ; a1 = metadataMapAddress
        movea.l MapMetadataMap_containersTableAddress(a1), a2                   ; a2 = containersTableAddress
        lea     (viewport + Viewport_chunkRefCache), a3                         ; a3 = current chunk ref cache address
        movea.l MapMetadataMap_objectGroupsBaseAddress(a1), a4                  ; a4 = objectGroupsBaseAddress
        lea     (viewport + Viewport_activeObjectGroups), a5                    ; a5 = activeObjectGroups
        movea.l MapHeader_foregroundAddress(a0), a0
        move.w  Map_stride(a0), d4
        subq.w  #SIZE_WORD, d4
        sub.w   d2, d4
        sub.w   d2, d4                                                          ; d4 map stride - number of columns in view
        move.w  d1, d5
        add.w   d5, d5
        move.w  Map_rowOffsetTable(a0, d5), d5                                  ; d5 = map row offset of top visible row
        movea.l Map_dataAddress(a0), a0
        adda.w  d5, a0
        move.w  d0, d6
        add.w   d6, d6
        adda.w  d6, a0                                                          ; a0 = address of top left coordinate of first chunk in viewport

        moveq   #0, d6                                                          ; d6 = accumulated group flags
    .rowLoop:

        swap    d4
        move.w  d2, d4                                                          ; d4 = number of columns - 1
        move.w  d0, d5                                                          ; d5 = horizontal chunk coordinate
        .colLoop:

            ; Load object container address
            move.w  d1, d7
            lsr.w   #3, d7
            add.w   d7, d7
            move.w  MapMetadataMap_rowOffsetTable(a1, d7), a6                   ; a6 = container table vertical offset
            move.w  d5, d7
            lsr.w   #3, d7
            add.w   d7, d7
            add.w   d7, d7
            add.w   a6, d7                                                      ; d7 = container offset
            movea.l (a2, d7), a6                                                ; a6 = containersTableAddress[d7] (= container address)

            ; Load chunk ref
            move.w  (a0)+, d7                                                   ; d7 = chunk ref

            ; Update chunk ref cache
            move.w  d7, (a3)+

            ; Load object group from container if any
            andi.w  #CHUNK_REF_OBJECT_GROUP_IDX_MASK, d7
            beq.s   .emptyObjectGroup
                rol.w   #3, d7                                                  ; d7 = container group id

                subq.w  #1, d7                                                  ; d7 = container group index
                add.w   d7, d7
                move.w  MapMetadataContainer_objectGroupOffsetTable(a6, d7), d7 ; d7 = object group offset
                lea     (a4, d7), a6                                            ; a6 = object group address

                ; Check if new group
                move.b  MapObjectGroup_flagNumber(a6), d7
                bset    d7, d6
                bne.s   .objectGroupAlreadyActive

                    addq.w #1, (viewport + Viewport_activeObjectGroupCount)

                    ; Add to active group list
                    move.l  a6, (a5)+

            .objectGroupAlreadyActive:

        .emptyObjectGroup:

            addq.w  #1, d5
            dbra    d4, .colLoop

        swap    d4
        adda.w  d4, a0
        addq.w  #1, d1
        dbra    d3, .rowLoop

        ; Check if the viewport's object group configuration changed (d6 == viewport object group configuration == all found object group flags combined)
        cmp.l   (viewport + Viewport_activeObjectGroupConfigurationId), d6
        beq     .viewportObjectGroupConfigurationChangeDone

            ; Store new viewport object group configuration id
            move.l  d6, (viewport + Viewport_activeObjectGroupConfigurationId)

            ; TODO: If so update shared resource updaters for objects in the active groups
                ; TODO: using k-way set merge where each set element is an rle element into the map's object type array
                    ; TODO: Sort map object array by edge strength between nodes (how many times are they related in groups)

            DEBUG_MSG 'VIEWPORT_OBJECT_GROUP_CONFIG_CHANGE'

    .viewportObjectGroupConfigurationChangeDone:
        rts


;-------------------------------------------------
; Render a row from the chunk ref cache
; ----------------
; Input:
; - a0: Camera
; - d0: Map row
; - d1: Map start column
; - d2: Width to render
; - d3.l: VDP plane id
; Uses: d0-d7/a0-a6
_ViewportRenderRow:
        move.w  Camera_y(a0), d4
        lsr.w   #PATTERN_SHIFT, d4                                              ; d4 = viewport absolute x position in 8 pixel columns
        andi.w  #~$0f, d4                                                       ; Align with map
        move.w  d0, d5
        sub.w   d4, d5                                                          ; d5 = viewport relative row number
        lsr.w   #4, d5                                                          ; d5 = chunkRefCache row number

        ; For now always assume 0 for column offset as this will only be called from the camera for full rows

        move.w  (viewport + Viewport_chunkRefCacheStride), d6                   ; d6 = chunk ref cache stride
        add.w   d5, d5                                                          ; d5 = offset into .rowOffsetTable
        moveq   #0, d4                                                          ; d4 = offset into chunkRefCache
        jmp   .rowOffsetTable(pc, d5)
    .rowOffsetTable:
        bra.s   .row0
        bra.s   .row1
.row2:  add.w   d6, d4
.row1:  add.w   d6, d4
.row0:
        lea     (viewport + Viewport_chunkRefCache), a1
        adda.w  d4, a1                                                          ; a1 = address of first chunk in row
        jmp     MapRenderRowBuffer                                              ; Pass the original coordinates as they are needed for VDP plane address calculations


;-------------------------------------------------
; Render a column from the chunk ref cache
; ----------------
; Input:
; - a0: Camera
; - d0: Map column
; - d1: Map start row
; - d2: Height to render
; - d3.l: VDP plane id
; Uses: d0-d7/a0-a6
_ViewportRenderColumn:
        move.w  Camera_x(a0), d4
        lsr.w   #PATTERN_SHIFT, d4                                              ; d4 = viewport absolute y position in 8 pixel columns
        andi.w  #~$0f, d4                                                       ; Align with map
        move.w  d0, d5
        sub.w   d4, d5                                                          ; d5 = viewport relative column number
        lsr.w   #4, d5                                                          ; d5 = chunkRefCache column number
        add.w   d5, d5                                                          ; d5 = chunkRefCache offset

        ; For now always assume 0 for row offset as this will only be called from the camera for full columns

        lea     (viewport + Viewport_chunkRefCache), a1
        adda.w  d5, a1                                                          ; a1 = address of first chunk in row
        movea.w (viewport + Viewport_chunkRefCacheStride), a6                   ; a6 = chunkRefCacheStride
        jmp     MapRenderColumnBuffer


    Purge _CALCULATE_SUB_CHUNK_ID
