;------------------------------------------------------------------------------------------
; Engine update ticker
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Generic ticker constants
; ----------------
TICKER_COUNT            Equ 1


;-------------------------------------------------
; Subsystem ticker identifiers
; ----------------
TICKER_TILESET          Equ $80
TICKER_ALL              Equ TICKER_TILESET


;-------------------------------------------------
; Ticker state
; ----------------
    DEFINE_VAR FAST
        VAR.l       engineTickerCallbacks,    TICKER_COUNT
        VAR.b       engineTickerFlags                             ; Flag set by subsystem to indicate ticker is enabled
        VAR.b       engineTickerMask                              ; Mask set by program to mask which subsystems can execute
    DEFINE_VAR_END

    EngineTickers:
        dc.l        TilesetTick
        dc.b        0
        dc.b        TICKER_ALL
    EngineTickersEnd:


;-------------------------------------------------
; Enable the specified ticker
; NB: Should only be used by engine subsystems. Use the mask macros to temporarily disable subsystems
; ----------------
ENGINE_TICKER_ENABLE Macros tickerId
    ori.b  #\tickerId, engineTickerFlags


;-------------------------------------------------
; Disable the specified ticker.
; NB: Should only be used by engine subsystems. Use the mask macros to temporarily disable subsystems
; ----------------
ENGINE_TICKER_DISABLE Macros tickerId
    andi.b  #~\tickerId & $ff, engineTickerFlags


;-------------------------------------------------
; Mask the specified ticker (disable it)
; ----------------
ENGINE_TICKER_MASK Macros tickerId
    andi.b   #~\tickerId & $ff, engineTickerMask


;-------------------------------------------------
; Unmask the specified ticker
; ----------------
ENGINE_TICKER_UNMASK Macros tickerId
    ori.b    #\tickerId, engineTickerMask


;-------------------------------------------------
; Initialize the engine state ticker
; ----------------
EngineTickInit:
        lea     EngineTickers, a0
        lea     engineTickerCallbacks, a1
        move.w  #EngineTickersEnd - EngineTickers, d0
        jsr     MemCopy

        lea     EngineTick, a0
        jmp     OSSetFrameProcessedCallback


;-------------------------------------------------
; Update all engine subsystems
; ----------------
; Uses: d0-d7/a0-a6 (Unknown due to delegation)
EngineTick:
        move.w  #TICKER_COUNT - 1, d0
        move.b  engineTickerFlags, d1
        and.b   engineTickerMask, d1
        lea     engineTickerCallbacks, a0

    .updateSubSystemLoop:
        add.b   d1, d1
        bcc     .subSystemDisabled

        PUSHM   d0-d1/a0
        movea.l (a0), a0
        jsr     (a0)
        POPM    d0-d1/a0

    .subSystemDisabled:
        addq.l  #SIZE_LONG, a0
        dbra    d0, .updateSubSystemLoop
        rts
