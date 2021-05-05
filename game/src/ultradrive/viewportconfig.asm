;------------------------------------------------------------------------------------------
; Custom viewport configurations
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Static background scrolls at 1/4 the rate of the foreground
; ----------------
TilingBackgroundViewportConfiguration:
    DEFINE_TILING_BACKGROUND_VIEWPORT_CONFIG QuarterSpeed


;-------------------------------------------------
; Line scrolling test
; ----------------
LineViewportConfiguration:
    ; .vcBackgroundTracker
    dc.l relativeBackgroundTracker
    ; .vcHorizontalScrollConfiguration
        ; .scVDPScrollUpdaterAddress
        dc.l lineHorizontalVDPScrollUpdater
        ; .scBackgroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportBackground
            ; .svucUpdaterData
            dc.l lineHorizontalScrollCameraConfig
            ; .svucUpdater
            dc.l multiScrollCamera
        ; .scForegroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdaterData
            dc.l lineHorizontalScrollCameraConfig
            ; .svucUpdater
            dc.l multiScrollCamera
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
; Cell scrolling test (Uses line scroll for horizontal and cell scroll for vertical = most cpu intensive scroll combination)
; Exibits vertical 2 column cell scroll bug on the left most column on older hardware revisions (ie my md1) :/
; ----------------
CellViewportConfiguration:
    ; .vcBackgroundTracker
    dc.l relativeBackgroundTracker
    ; .vcHorizontalScrollConfiguration
        ; .scVDPScrollUpdaterAddress
        dc.l lineHorizontalVDPScrollUpdater
        ; .scBackgroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportBackground
            ; .svucUpdaterData
            dc.l lineHorizontalScrollCameraConfig
            ; .svucUpdater
            dc.l multiScrollCamera
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
            dc.l cellVerticalScrollCameraConfig
            ; .svucUpdater
            dc.l multiScrollCamera
        ; .scForegroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdaterData
            dc.l cellVerticalScrollCameraConfig
            ; .svucUpdater
            dc.l multiScrollCamera
