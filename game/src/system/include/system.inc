;------------------------------------------------------------------------------------------
; All system includes
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_INC))
__SYSTEM_INC Equ 1

    Include './system/include/init.inc'
    Include './system/include/io.inc'
    Include './system/include/m68k.inc'
    Include './system/include/memory.inc'
    Include './system/include/os.inc'
    Include './system/include/rasterfx.inc'
    Include './system/include/tmss.inc'
    Include './system/include/vdp.inc'
    Include './system/include/vdpdmaqueue.inc'
    Include './system/include/vdptaskqueue.inc'
    Include './system/include/z80.inc'

    EndIf
