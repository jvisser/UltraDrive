;------------------------------------------------------------------------------------------
; All engine includes
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_INC))
__ENGINE_INC Equ 1

    Include './engine/include/background.inc'
    Include './engine/include/camera.inc'
    Include './engine/include/collision.inc'
    Include './engine/include/entity.inc'
    Include './engine/include/fp16.inc'
    Include './engine/include/linkedlist.inc'
    Include './engine/include/map.inc'
    Include './engine/include/mapobject.inc'
    Include './engine/include/maprender.inc'
    Include './engine/include/object.inc'
    Include './engine/include/scheduler.inc'
    Include './engine/include/scroll.inc'
    Include './engine/include/tileset.inc'
    Include './engine/include/angle.inc'
    Include './engine/include/viewport.inc'

    EndIf