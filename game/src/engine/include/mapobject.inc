;------------------------------------------------------------------------------------------
; Map object structures / macros
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_MAPOBJECT_INC))
__ENGINE_MAPOBJECT_INC Equ 1

; MAP_TRANSFERABLE_OBJECT_QUEUE_STATE_CHANGE state change parameters
MAP_OBJECT_STATE_CHANGE_ATTACH              Equ (_MapAttachTransferableObject - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_ATTACH_FLOOR        Equ (_MapAttachTransferableObjectFloor - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_ACTIVATE            Equ (_MapActivateTransferableObject - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_DEACTIVATE          Equ (_MapDeactivateTransferableObject - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_ACTIVATE_GLOBAL     Equ (_MapActivateTransferableObjectGlobal - _MapProcessObjectStateChangesBaseOffset)
MAP_OBJECT_STATE_CHANGE_DEACTIVATE_GLOBAL   Equ (_MapDeactivateTransferableObjectGlobal - _MapProcessObjectStateChangesBaseOffset)


;-------------------------------------------------
; Queue object state change.
; This macros is to be used within MapObjectType.update() to prevent concurrent modifications to the object update list while updating;
;
; TODO: Add bounds check
; ----------------
; Input:
; - stateChange: MAP_OBJECT_STATE_CHANGE_* representing the change requested
; - objectStateAddress: Object state address
; - scratch: Address register to use as scratch register
; - param1: Optional state change specific parameter 1
; - param2: Optional state change specific parameter 2
MAP_TRANSFERABLE_OBJECT_QUEUE_STATE_CHANGE Macro stateChange, objectStateAddress, scratch, param1, param2
        movea.w mapTransferableStateChangeQueueAddress, \scratch
        If (narg>4)
            move.w  \param2, (\scratch)+
        EndIf
        If (narg>3)
            move.w  \param1, (\scratch)+
        EndIf
        move.w  \objectStateAddress, (\scratch)+
        move.w  #\stateChange, (\scratch)+
        move.w  \scratch, mapTransferableStateChangeQueueAddress
        addq.w  #1, mapTransferableStateChangeQueueCount
    Endm

    EndIf
