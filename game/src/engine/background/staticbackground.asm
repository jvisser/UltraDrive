;------------------------------------------------------------------------------------------
; Static background tracker implementation. Initializes the camera once to the background plane size and never updates the camera position.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Static background tracker structures
; ----------------
    DEFINE_VAR FAST
        VAR.BackgroundTracker  staticBackgroundTracker
    DEFINE_VAR_END

    INIT_STRUCT staticBackgroundTracker
        INIT_STRUCT_MEMBER.btInit      _StaticBackgroundTrackerInit
        INIT_STRUCT_MEMBER.btSync      NoOperation
    INIT_STRUCT_END


;-------------------------------------------------
; Initialize the background tracker. Called by engine init.
; ----------------
StaticBackgroundTrackerInit Equ staticBackgroundTrackerInit


;-------------------------------------------------
; Default background tracker init implementation. Calculates the ratio between the back/foreground maps. And initializes the background camera.
; ----------------
; Input:
; - a0: Background camera to initialize
; - a1: Background map address
; - a2: Foreground camera
; - d0: Background camera plane id
; Uses: d0-d5/a3-a4
_StaticBackgroundTrackerInit:
        move.l  d0, d4
        moveq   #0, d0
        moveq   #0, d1
        move.w  (vdpMetrics + vdpPlaneWidth), d2
        move.w  (vdpMetrics + vdpPlaneHeight), d3
        jsr     CameraInit
        rts
