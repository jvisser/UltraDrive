;------------------------------------------------------------------------------------------
; Trigonometry tables constants
;------------------------------------------------------------------------------------------

    If (~def(__LIB_COMMON_ANGLE_INC))
__LIB_COMMON_ANGLE_INC Equ 1

;-------------------------------------------------
; Angle constants (table indices)
; ----------------
ANGLE_0         Equ 0
ANGLE_45        Equ 32
ANGLE_90        Equ (ANGLE_45 * 2)
ANGLE_135       Equ (ANGLE_45 * 3)
ANGLE_180       Equ (ANGLE_45 * 4)
ANGLE_225       Equ (ANGLE_45 * 5)
ANGLE_270       Equ (ANGLE_45 * 6)
ANGLE_315       Equ (ANGLE_45 * 7)
ANGLE_360       Equ ANGLE_0

ANGLE_MASK      Equ ((ANGLE_180 * 2) - 1)

    EndIf
