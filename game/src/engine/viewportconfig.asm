;------------------------------------------------------------------------------------------
; Provides the default viewport configuration and some setup macros for alternative configurations
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Default viewport configuration. Relative background using plane based scrolling based on the camera
; ----------------
defaultViewportConfiguration:
    ; .backgroundTracker
    dc.l relativeBackgroundTracker
    ; .backgroundTrackerConfiguration
    dc.l relativeHorizontalVerticalBackgroundTrackerConfiguration
    ; .horizontalScrollConfiguration
        ; .vdpScrollUpdaterAddress
        dc.l planeHorizontalVDPScrollUpdater
        ; .backgroundScrollUpdaterConfiguration
            ; .camera
            dc.w Viewport_background
            ; .updaterData
            dc.l planeHorizontalScrollCameraConfig
            ; .updater
            dc.l planeScrollCamera
        ; .foregroundScrollUpdaterConfiguration
            ; .camera
            dc.w Viewport_foreground
            ; .updaterData
            dc.l planeHorizontalScrollCameraConfig
            ; .updater
            dc.l planeScrollCamera
    ; .verticalScrollConfiguration
        ; .vdpScrollUpdaterAddress
        dc.l planeVerticalVDPScrollUpdater
        ; .backgroundScrollUpdaterConfiguration
            ; .camera
            dc.w Viewport_background
            ; .updaterData
            dc.l planeVerticalScrollCameraConfig
            ; .updater
            dc.l planeScrollCamera
        ; .foregroundScrollUpdaterConfiguration
            ; .camera
            dc.w Viewport_foreground
            ; .updaterData
            dc.l planeVerticalScrollCameraConfig
            ; .updater
            dc.l planeScrollCamera


;-------------------------------------------------
; Create a viewport configuration with a static background that scrolls as a rate relative to the foreground camera. Effectively making the background repeat infinitely.
; Speed can be ommitted to scroll at the same speed as the foreground or have one of the following values:
; - HalfSpeed: Half speed of the foreground camera movement.
; - QuarterSpeed: Quarter speed of the foreground camera movement.
; ----------------
DEFINE_TILING_BACKGROUND_VIEWPORT_CONFIG Macro speed
        ; .backgroundTracker
        dc.l staticBackgroundTracker
        ; .backgroundTrackerConfiguration
        dc.l NULL
        ; .horizontalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l planeHorizontalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeHorizontalScrollCamera\speed\Config
                ; .updater
                dc.l planeScrollCamera
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeHorizontalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
        ; .verticalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l planeVerticalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeVerticalScrollCamera\speed\Config
                ; .updater
                dc.l planeScrollCamera
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l planeVerticalScrollCameraConfig
                ; .updater
                dc.l planeScrollCamera
    Endm


;-------------------------------------------------
; Create a viewport configuration with a static background that rotates and translates according to the specified RotateScrollCameraConfiguration
; ----------------
DEFINE_ROTATING_BACKGROUND_VIEWPORT_CONFIG Macro config
        ; .backgroundTracker
        dc.l staticBackgroundTracker
        ; .backgroundTrackerConfiguration
        dc.l NULL
        ; .horizontalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l lineHorizontalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_background
                ; .updaterData
                dc.l \config
                ; .updater
                dc.l rotateHorizontalLineScroll
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l lineHorizontalScrollCameraConfig
                ; .updater
                dc.l multiScrollCamera
        ; .verticalScrollConfiguration
            ; .vdpScrollUpdaterAddress
            dc.l cellVerticalVDPScrollUpdater
            ; .backgroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_background
                ; .updaterData
                dc.l \config
                ; .updater
                dc.l rotateVerticalCellScroll
            ; .foregroundScrollUpdaterConfiguration
                ; .camera
                dc.w Viewport_foreground
                ; .updaterData
                dc.l cellVerticalScrollCameraConfig
                ; .updater
                dc.l multiScrollCamera
    Endm
