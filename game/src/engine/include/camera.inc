;------------------------------------------------------------------------------------------
; Camera structures / macros.
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_CAMERA_INC))
__ENGINE_CAMERA_INC Equ 1

    Include './system/include/memory.inc'

;-------------------------------------------------
; Camera structure
; ----------------
    DEFINE_STRUCT Camera
        STRUCT_MEMBER.w x
        STRUCT_MEMBER.w y
        STRUCT_MEMBER.w minX
        STRUCT_MEMBER.w maxX
        STRUCT_MEMBER.w minY
        STRUCT_MEMBER.w maxY
        STRUCT_MEMBER.w xDisplacement
        STRUCT_MEMBER.w yDisplacement
        STRUCT_MEMBER.w lastXDisplacement
        STRUCT_MEMBER.w lastYDisplacement
        STRUCT_MEMBER.w absoluteMaxX
        STRUCT_MEMBER.w absoluteMaxY
        STRUCT_MEMBER.l mapAddress
        STRUCT_MEMBER.l planeId
        STRUCT_MEMBER.w widthPatterns
        STRUCT_MEMBER.w heightPatterns
        STRUCT_MEMBER.l rowRenderer
        STRUCT_MEMBER.l columnRenderer
        ; Externally managed
        STRUCT_MEMBER.l moveCallback                                ; Mandatory
        STRUCT_MEMBER.l data
    DEFINE_STRUCT_END


;-------------------------------------------------
; Add camera displacement
; ----------------
; Input:
; - a0: Camera
CAMERA_MOVE Macro xDisp, yDisp
        add.w  \xDisp, Camera_xDisplacement(a0)
        add.w  \yDisp, Camera_yDisplacement(a0)
    Endm

    EndIf
