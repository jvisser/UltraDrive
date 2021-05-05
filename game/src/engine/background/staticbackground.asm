;------------------------------------------------------------------------------------------
; Static background tracker implementation. Initializes the camera once to the background plane size and never updates the camera position.
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Static background tracker structures
; ----------------
    ; struct BackgroundTracker
    staticBackgroundTracker:
        ; .btInit
        dc.l _StaticBackgroundTrackerInit
        ; .btSync
        dc.l NoOperation


;-------------------------------------------------
; Sets the camera size to the plane size
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
