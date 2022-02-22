;------------------------------------------------------------------------------------------
; Main binary assembly
;------------------------------------------------------------------------------------------

    Include 'asmopts.asm'
    Include 'layout.asm'

    ;-------------------------------------------------
    ; Common
    ; ----------------
    Include './lib/common/include/common.inc'

    Include './lib/common/nooperation.asm'
    Include './lib/common/trigtable.asm'
    Include './lib/common/compression/comper.asm'
    ;Include './lib/common/compression/unaplib.asm'


    ;-------------------------------------------------
    ; System
    ; ----------------
    Include './system/include/system.inc'

    Include './system/memory.asm'
    Include './system/z80.asm'
    Include './system/exception.asm'
    Include './system/tmss.asm'
    Include './system/io.asm'
    Include './system/vdp.asm'
    Include './system/vdptaskqueue.asm'
    Include './system/rasterfx.asm'
    Include './system/vdpdmaqueue.asm'
    Include './system/vdpsprite.asm'
    Include './system/os.asm'
    Include './system/boot.asm'


    ;-------------------------------------------------
    ; Engine
    ; ----------------
    Include './engine/include/engine.inc'

    Include './engine/scheduler.asm'
    Include './engine/tileset.asm'
    Include './engine/map.asm'
    Include './engine/mapstate.asm'
    Include './engine/maprender.asm'
    Include './engine/mapobject.asm'
    Include './engine/mapcollision.asm'
    Include './engine/camera.asm'
    Include './engine/viewport.asm'
    Include './engine/collision.asm'
    Include './engine/background/relativebackground.asm'
    Include './engine/background/staticbackground.asm'
    Include './engine/scroll/vdpscroll.asm'
    Include './engine/scroll/vdpplanehscroll.asm'
    Include './engine/scroll/vdpplanevscroll.asm'
    Include './engine/scroll/vdplinehscroll.asm'
    Include './engine/scroll/vdpcellhscroll.asm'
    Include './engine/scroll/vdpcellvscroll.asm'
    Include './engine/scroll/updaters/scrollupdaterutil.asm'
    Include './engine/scroll/updaters/planescrollcamera.asm'
    Include './engine/scroll/updaters/multivaluescrollcamera.asm'
    Include './engine/scroll/updaters/rotatescroll.asm'
    Include './engine/rasterfx/paletteswaprasterfx.asm'


    ;-------------------------------------------------
    ; Game
    ; ----------------

    ; Game code
    Include 'ultradrive/metadata.asm'
    Include 'ultradrive/player.asm'
    Include 'ultradrive/viewport.asm'
    Include 'ultradrive/water.asm'
    Include 'ultradrive/collisiontypes.asm'
    Include 'ultradrive/objects/orbison.asm'
    Include 'ultradrive/objects/fireball.asm'
    Include 'ultradrive/objects/blob.asm'

    ; Assets
    Include 'ultradrive/assets/generated/tilesets.asm'
    Include 'ultradrive/assets/generated/maps.asm'

    ; Main
    Include 'ultradrive/main.asm'


    ;-------------------------------------------------
    ; ROM header
    ; ----------------
    ; Produce ROM header once all symbols have been resolved
    Include './system/m68kvector.asm'
    Include './system/segaheader.asm'


    ;-------------------------------------------------
    ; Finalize program/ROM layout
    ; ----------------
    LAYOUT_FINALIZE

RomImageEnd

    SECTION_ALLOCATION_REPORT

    MEMORY_ALLOCATION_REPORT

    End
