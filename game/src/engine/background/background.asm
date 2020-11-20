;------------------------------------------------------------------------------------------
; Initialization code and shared macros for background trackers
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; One time initialization for all trackers. Called by engine init.
; ----------------
BackgroundTrackerInit:
        jsr     StreamingBackgroundTrackerInit
        jsr     TilingBackgroundTrackerInit
        rts


;-------------------------------------------------
; Set background scroll to specified values
; ----------------
; Uses: d0
BACKGROUND_UPDATE_VDP_SCROLL Macro x, y

        ; Update horizontal scroll
        VDP_ADDR_SET WRITE, VRAM, VDP_HSCROLL_ADDR + 2
        move.w  \x, d0
        neg.w   d0
        move.w  d0, (MEM_VDP_DATA)

        ; Update vertical scroll
        VDP_ADDR_SET WRITE, VSRAM, $02
        move.w  \y, d0
        move.w  d0, (MEM_VDP_DATA)
    Endm
