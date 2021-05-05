;------------------------------------------------------------------------------------------
; Provides the default viewport configuration and some setup macros for alternative configurations
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Default viewport configuration. Relative background using plane based scrolling based on the camera
; ----------------
defaultViewportConfiguration:
    ; .vcBackgroundTracker
    dc.l relativeBackgroundTracker
    ; .vcHorizontalScrollConfiguration
        ; .scVDPScrollUpdaterAddress
        dc.l planeHorizontalVDPScrollUpdater
        ; .scBackgroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportBackground
            ; .svucUpdaterData
            dc.l planeHorizontalScrollCameraConfig
            ; .svucUpdater
            dc.l planeScrollCamera
        ; .scForegroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdaterData
            dc.l planeHorizontalScrollCameraConfig
            ; .svucUpdater
            dc.l planeScrollCamera
    ; .vcVerticalScrollConfiguration
        ; .scVDPScrollUpdaterAddress
        dc.l planeVerticalVDPScrollUpdater
        ; .scBackgroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportBackground
            ; .svucUpdaterData
            dc.l planeVerticalScrollCameraConfig
            ; .svucUpdater
            dc.l planeScrollCamera
        ; .scForegroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdaterData
            dc.l planeVerticalScrollCameraConfig
            ; .svucUpdater
            dc.l planeScrollCamera


;-------------------------------------------------
; Create a viewport configuration with a static background that scrolls as a rate relative to the foreground camera. Effectively making the background repeat infinitely.
; Speed can be ommitted to scroll at the same speed as the foreground or have one of the following values:
; - HalfSpeed: Half speed of the foreground camera movement.
; - QuarterSpeed: Quarter speed of the foreground camera movement.
; ----------------
DEFINE_TILING_BACKGROUND_VIEWPORT_CONFIG Macro speed
        ; .vcBackgroundTracker
        dc.l staticBackgroundTracker
        ; .vcHorizontalScrollConfiguration
            ; .scVDPScrollUpdaterAddress
            dc.l planeHorizontalVDPScrollUpdater
            ; .scBackgroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportForeground
                ; .svucUpdaterData
                dc.l planeHorizontalScrollCamera\speed\Config
                ; .svucUpdater
                dc.l planeScrollCamera
            ; .scForegroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportForeground
                ; .svucUpdaterData
                dc.l planeHorizontalScrollCameraConfig
                ; .svucUpdater
                dc.l planeScrollCamera
        ; .vcVerticalScrollConfiguration
            ; .scVDPScrollUpdaterAddress
            dc.l planeVerticalVDPScrollUpdater
            ; .scBackgroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportForeground
                ; .svucUpdaterData
                dc.l planeVerticalScrollCamera\speed\Config
                ; .svucUpdater
                dc.l planeScrollCamera
            ; .scForegroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportForeground
                ; .svucUpdaterData
                dc.l planeVerticalScrollCameraConfig
                ; .svucUpdater
                dc.l planeScrollCamera
    Endm


;-------------------------------------------------
; Create a viewport configuration with a static background that rotates and translates according to the specified RotateScrollCameraConfiguration
; ----------------
DEFINE_ROTATING_BACKGROUND_VIEWPORT_CONFIG Macro config
        ; .vcBackgroundTracker
        dc.l staticBackgroundTracker
        ; .vcHorizontalScrollConfiguration
            ; .scVDPScrollUpdaterAddress
            dc.l lineHorizontalVDPScrollUpdater
            ; .scBackgroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportBackground
                ; .svucUpdaterData
                dc.l \config
                ; .svucUpdater
                dc.l rotateHorizontalLineScrollCamera
            ; .scForegroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportForeground
                ; .svucUpdaterData
                dc.l lineHorizontalScrollCameraConfig
                ; .svucUpdater
                dc.l multiScrollCamera
        ; .vcVerticalScrollConfiguration
            ; .scVDPScrollUpdaterAddress
            dc.l cellVerticalVDPScrollUpdater
            ; .scBackgroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportBackground
                ; .svucUpdaterData
                dc.l \config
                ; .svucUpdater
                dc.l rotateVerticalCellScrollCamera
            ; .scForegroundScrollUpdaterConfiguration
                ; .svucCamera
                dc.w viewportForeground
                ; .svucUpdaterData
                dc.l cellVerticalScrollCameraConfig
                ; .svucUpdater
                dc.l multiScrollCamera
    Endm
