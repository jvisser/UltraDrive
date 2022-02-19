;------------------------------------------------------------------------------------------
; All engine includes
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_INC))
__ENGINE_INC Equ 1

    Include './engine/include/config.inc'

    Include './engine/include/background.inc'
    Include './engine/include/camera.inc'
    Include './engine/include/collision.inc'
    Include './engine/include/entity.inc'
    Include './engine/include/map.inc'
    Include './engine/include/object.inc'
    Include './engine/include/scheduler.inc'
    Include './engine/include/scroll.inc'
    Include './engine/include/tileset.inc'
    Include './engine/include/viewport.inc'
    Include './engine/include/viewport.inc'
    Include './engine/include/vdpscroll.inc'

    EndIf
