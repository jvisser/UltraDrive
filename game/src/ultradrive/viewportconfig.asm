;------------------------------------------------------------------------------------------
; Custom viewport configurations
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Static background scrolls at 1/4 the rate of the foreground
; ----------------
TilingBackgroundViewportConfiguration:
    ; .vcBackgroundTracker
    dc.l staticBackgroundTracker
    ; .vcScrollConfiguration
        ; .scVDPScrollUpdaterAddress
        dc.l planeVDPScrollUpdater
        ; .scBackgroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdater
            dc.l planeScrollCameraDiv4
        ; .scForegroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdater
            dc.l planeScrollCamera


;-------------------------------------------------
; Line scrolling test
; ----------------
LineViewportConfiguration:
    ; .vcBackgroundTracker
    dc.l relativeBackgroundTracker
    ; .vcScrollConfiguration
        ; .scVDPScrollUpdaterAddress
        dc.l lineVDPScrollUpdater
        ; .scBackgroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportBackground
            ; .svucUpdater
            dc.l lineScrollCamera
        ; .scForegroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdater
            dc.l lineScrollCamera
