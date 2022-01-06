;------------------------------------------------------------------------------------------
; Viewport. Manages background and foreground plane
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Viewport constants
; ----------------
VIEWPORT_ACTIVE_AREA_SIZE_H     Equ 320/4
VIEWPORT_ACTIVE_AREA_SIZE_V     Equ 224/4


;-------------------------------------------------
; Viewport structures
; ----------------
    DEFINE_STRUCT ViewportConfiguration
        STRUCT_MEMBER.l                     backgroundTracker                   ; Used to update the background camera position
        STRUCT_MEMBER.l                     backgroundTrackerConfiguration      ; Background tracker configuration address (if any)
        STRUCT_MEMBER.ScrollConfiguration   horizontalScrollConfiguration       ; Used to update horizontal VDP scroll values
        STRUCT_MEMBER.ScrollConfiguration   verticalScrollConfiguration         ; Used to update vertical VDP scroll values
    DEFINE_STRUCT_END

    DEFINE_STRUCT Viewport
        STRUCT_MEMBER.Camera    background
        STRUCT_MEMBER.Camera    foreground
        STRUCT_MEMBER.l         backgroundTracker                               ; Used to update the background camera
        STRUCT_MEMBER.l         backgroundTrackerConfiguration
        STRUCT_MEMBER.l         horizontalVDPScrollUpdater                      ; Used to update the horizontal VDP scroll values
        STRUCT_MEMBER.l         verticalVDPScrollUpdater                        ; Used to update the vertical VDP scroll values
        STRUCT_MEMBER.w         trackingEntity                                  ; Entity to keep in view
        STRUCT_MEMBER.w         subChunkId                                      ; Used to detect viewport chunk changes on movement
        STRUCT_MEMBER.l         foregroundMovementCallback
        STRUCT_MEMBER.l         objectGroupConfigurationId                      ; Current object group configuration (combined object group flags)
    DEFINE_STRUCT_END

    DEFINE_VAR SHORT
        VAR.Viewport viewport
    DEFINE_VAR_END


;-------------------------------------------------
; Install movement callback and camera data for the specified camera
; ----------------
VIEWPORT_INSTALL_MOVEMENT_CALLBACK Macro camera, callback, cameraData
        If (strcmp('\camera', 'foreground'))
            move.l  #\callback, (viewport + Viewport_foregroundMovementCallback)
        Else
            move.l  #\callback, (viewport + Viewport_\camera + Camera_moveCallback)
        EndIf
        move.l  \cameraData, (viewport + Viewport_\camera + Camera_data)
    Endm


;-------------------------------------------------
; Restore the default movement callback for the specified camera
; ----------------
VIEWPORT_UNINSTALL_MOVEMENT_CALLBACK Macro camera
        If (strcmp('\camera', 'foreground'))
            move.l  #NoOperation, (viewport + Viewport_foregroundMovementCallback)
        Else
            move.l  #NoOperation, (viewport + Viewport_\camera + Camera_moveCallback)
        EndIf
    Endm


;-------------------------------------------------
; Start tracking the specified entity
; ----------------
VIEWPORT_TRACK_ENTITY Macros entity
        move.w  \entity, (viewport + Viewport_trackingEntity)


;-------------------------------------------------
; Stop entity tracking
; ----------------
VIEWPORT_TRACK_ENTITY_END Macros
        clr.w  (viewport + Viewport_trackingEntity)


;-------------------------------------------------
; Get viewport X position
; ----------------
VIEWPORT_GET_X Macros target
    move.w  (viewport + Viewport_foreground + Camera_x), \target


;-------------------------------------------------
; Get viewport Y position
; ----------------
VIEWPORT_GET_Y Macros target
    move.w  (viewport + Viewport_foreground + Camera_y), \target


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
        addq.w  #8, d2                                  ; Foreground camera width = screen width + 1 pattern for scrolling
        move.w  (vdpMetrics + VDPMetrics_screenHeight), d3
        addq.w  #8, d3                                  ; Foreground camera height = screen height + 1 pattern for scrolling
        move.l  #VDP_PLANE_A, d4

        jsr     CameraInit

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

        ; Render views
        lea     (viewport + Viewport_background), a0
        jsr     CameraRenderView
        lea     (viewport + Viewport_foreground), a0
        jmp     CameraRenderView

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

        MAP_RENDER_RESET

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
; - d0: Left coordinate of view
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
    clr.l   (viewport + Viewport_objectGroupConfigurationId)

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
; Update viewport data:
; - Viewport chunk cache
; - Active object groups
; ----------------
; Input:
; - d0: Left coordinate of view
; - d1: Top coordinate of view
; Uses: d0-d7/a0-a6
__ViewportUpdateActiveViewportData:
        VIEWPORT_GET_X d0
        VIEWPORT_GET_Y d1
        
        clr.w   mapActiveObjectGroupCount

        ; Get number of columns in view
        moveq   #3, d2
        btst    #6, d0
        seq     d3
        ext.w   d3
        add.w   d3, d2                                                          ; d2 = number of columns - 1

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
        movea.l MapHeader_objectGroupMapAddress(a0), a1                         ; a1 = objectGroupMapAddress
        movea.l MapObjectGroupMap_containersTableAddress(a1), a2                ; a2 = containersTableAddress
        movea.l MapObjectGroupMap_containersBaseAddress(a1), a3                 ; a3 = containersBaseAddress
        movea.l MapObjectGroupMap_groupsBaseAddress(a1), a4                     ; a4 = groupsBaseAddress
        lea     mapActiveObjectGroups, a5                                       ; a5 = mapActiveObjectGroups
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
            move.w  MapObjectGroupMap_rowOffsetTable(a1, d7), a6                ; a6 = container table vertical offset
            move.w  d5, d7
            lsr.w   #3, d7
            add.w   d7, d7
            add.w   a6, d7                                                      ; d7 = container offset
            move.w  (a2, d7), d7                                                ; d7 = containersTableAddress[d7] (= container offset into containersBaseAddress)
            lea     (a3, d7), a6                                                ; a6 = containersBaseAddress[d7] (= container address)

            ; Load object group from container
            move.w  (a0)+, d7                                                   ; d7 = chunk ref
            andi.w  #CHUNK_REF_OBJECT_GROUP_IDX_MASK, d7
            rol.w   #3, d7                                                      ; d7 = container group id
            beq.s   .emptyObjectGroup

                subq.w  #1, d7                                                  ; d7 = container group index
                add.w   d7, d7
                move.w  (a6, d7), d7                                            ; d7 = object group offset
                lea     (a4, d7), a6                                            ; a6 = object group address

                ; Check if new group
                move.b  MapObjectGroup_flagNumber(a6), d7
                bset    d7, d6
                bne.s   .objectGroupAlreadyActive

                    addq.w #1, mapActiveObjectGroupCount

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
        cmp.l   (viewport + Viewport_objectGroupConfigurationId), d6
        beq     .viewportObjectGroupConfigurationChangeDone

            ; Store new viewport object group configuration id
            move.l  d6, (viewport + Viewport_objectGroupConfigurationId)

            ; TODO: If so update shared resource updaters for objects in the active groups
                ; TODO: using k-way set merge where each set element is an rle element into the map's object type array
                    ; TODO: Sort map object array by edge strength between nodes (how many times are they related in groups)

            DEBUG_MSG 'VIEWPORT_OBJECT_GROUP_CONFIG_CHANGE'

    .viewportObjectGroupConfigurationChangeDone:
        rts

    Purge _CALCULATE_SUB_CHUNK_ID
