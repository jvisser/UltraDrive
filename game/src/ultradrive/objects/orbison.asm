;------------------------------------------------------------------------------------------
; Orbison "AI"
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Orbison main structures
; ----------------

    ; State
    DEFINE_STRUCT OrbisonState, EXTENDS, ObjectState
    DEFINE_STRUCT_END

    ; Type
    DEFINE_OBJECT_TYPE Orbison, OrbisonState
        dc.l    OrbisonInit
        dc.l    OrbisonUpdate
    DEFINE_OBJECT_TYPE_END

    
;-------------------------------------------------
; Init state
; ----------------
; Input:
; - a0: ObjectSpawnData address
; - a1: OrbisonState address
; Uses: 
OrbisonInit:
        rts
        
        
;-------------------------------------------------
; Update and render
; ----------------
; Input:
; - a0: ObjectSpawnData address
; - a1: OrbisonState address
; - a2: ObjectType Table base address
; Uses: 
OrbisonUpdate:
        rts
