;------------------------------------------------------------------------------------------
; Default viewport configuration
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Relative background
; ----------------
DefaultViewportConfiguration:
    ; .vcBackgroundTracker
    dc.l relativeBackgroundTracker
    ; .vcScrollConfiguration
        ; .scVDPScrollUpdaterAddress
        dc.l planeVDPScrollUpdater
        ; .scBackgroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportBackground
            ; .svucUpdater
            dc.l planeScrollCamera
        ; .scForegroundScrollUpdaterConfiguration
            ; .svucCamera
            dc.w viewportForeground
            ; .svucUpdater
            dc.l planeScrollCamera
