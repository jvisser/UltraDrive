;------------------------------------------------------------------------------------------
; All common includes
;------------------------------------------------------------------------------------------

    If (~def(__COMMON_INC))
__COMMON_INC Equ 1

    Include './common/include/constants.inc'
    Include './common/include/debug.inc'
    Include './common/include/profile.inc'
    Include './common/include/angle.inc'
    Include './common/include/fp16.inc'
    Include './common/include/linkedlist.inc'

    EndIf
