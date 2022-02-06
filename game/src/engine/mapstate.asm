;------------------------------------------------------------------------------------------
; Map state + state change handling routines
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'

    Include './engine/include/map.inc'

;-------------------------------------------------
; Constants
; ----------------
MAP_STATE_CHANGE_QUEUE_SIZE Equ (64*SIZE_WORD)


;-------------------------------------------------
; Map state
; ----------------
    DEFINE_VAR SHORT
        VAR.w mapStateAddress
        VAR.b mapStateFlags
        VAR.b mapNewStateFlags
        VAR.w mapStateChangeQueueAddress
        VAR.w mapStateChangeQueueCount
    DEFINE_VAR_END


;-------------------------------------------------
; Allocate map state area
; ----------------
; Input:
; - a0: MapHeader
; Uses: d0
MapInitState:
        ; Reset state flags
        clr.b   mapStateFlags
        clr.b   mapNewStateFlags
        
        ; Save map ptr
        PUSHL   a0
        
        ; Allocate map state memory
        move.w  MapHeader_stateSize(a0), d0
        jsr     MemoryAllocate
        move.w  a0, mapStateAddress

        ; Allocate state change queue
        move.w  #MAP_STATE_CHANGE_QUEUE_SIZE, d0
        jsr     MemoryAllocate
        move.w  a0, mapStateChangeQueueAddress
        clr.w   mapStateChangeQueueCount

        ; Restore map ptr
        POPL    a0
        rts


;-------------------------------------------------
; Process queued state changes
; ----------------
MapProcessStateChanges:
        ; Run queued state change handlers
        move.w  mapStateChangeQueueCount, d7
        beq.s   .noStateChanges
            movea.w  mapStateChangeQueueAddress, a6
            subq.w  #1, d7
        .stateChangeLoop:
            move.w  -(a6), d0                           ; d0 = State change type
            jsr     __StateChangeJmpTable(pc, d0)
            dbra    d7, .stateChangeLoop
        move.w  a6, mapStateChangeQueueAddress
        clr.w   mapStateChangeQueueCount
    .noStateChanges:

        ; Update state flags
        move.b  mapNewStateFlags, mapStateFlags
        rts

__StateChangeJmpTable:
    jmp _MapStateChangeAttachTransferableObject.l
    jmp _MapStateChangeAscendTransferableObject.l
    jmp _MapStateChangeActivateTransferableObject.l
    jmp _MapStateChangeDeactivateTransferableObject.l

