;------------------------------------------------------------------------------------------
; Main binary assembly
;------------------------------------------------------------------------------------------

; TODO: Move macros to separate files due to M68K expanding macros in a single pass :/ (or just switch to a better/modern assembler)

    Include 'asmopts.asm'
    Include 'layout.asm'

    ;-------------------------------------------------
    ; System
    ; ----------------
    Include './system/constants.asm'
    Include './system/m68k.asm'
    Include './system/debug.asm'
    Include './system/profile.asm'
    Include './system/system.asm'
    Include './system/memory.asm'
    Include './system/z80.asm'
    Include './system/io.asm'
    Include './system/vdpcmd.asm'
    Include './system/vdp.asm'
    Include './system/exception.asm'
    Include './system/os.asm'
    Include './system/vdptaskqueue.asm'
    Include './system/rasterfx.asm'
    Include './system/vdpdma.asm'
    Include './system/vdpdmaqueue.asm'
    Include './system/vdpsprite.asm'
    Include './system/init.asm'


    ;-------------------------------------------------
    ; Engine
    ; ----------------
    Include './engine/engine.asm'
    Include './engine/linkedlist.asm'
    Include './engine/fp16.asm'
    Include './engine/scheduler.asm'
    Include './engine/trigtable.asm'
    Include './engine/comper.asm'
    Include './engine/entity.asm'
    Include './engine/object.asm'
    Include './engine/collision.asm'
    Include './engine/map.asm'
    Include './engine/maprender.asm'
    Include './engine/camera.asm'
    Include './engine/background.asm'
    Include './engine/background/relativebackground.asm'
    Include './engine/background/staticbackground.asm'
    Include './engine/scroll.asm'
    Include './engine/scroll/vdpscrollshared.asm'
    Include './engine/scroll/vdpplanehscroll.asm'
    Include './engine/scroll/vdpplanevscroll.asm'
    Include './engine/scroll/vdpdmascroll.asm'
    Include './engine/scroll/vdplinehscroll.asm'
    Include './engine/scroll/vdpcellhscroll.asm'
    Include './engine/scroll/vdpcellvscroll.asm'
    Include './engine/scroll/updaters/planescrollcamera.asm'
    Include './engine/scroll/updaters/multivaluescrollcamera.asm'
    Include './engine/scroll/updaters/rotatescroll.asm'
    Include './engine/viewport.asm'
    Include './engine/viewportconfig.asm'
    Include './engine/mapobject.asm'
    Include './engine/tileset.asm'
    Include './engine/rasterfx/paletteswaprasterfx.asm'
    Include './engine/mapcollision.asm'


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
    Include 'ultradrive/assets/tilesets.asm'
    Include 'ultradrive/assets/maps.asm'

    ; Main
    Include 'ultradrive/main.asm'


    ;-------------------------------------------------
    ; ROM header
    ; ----------------
    ; Produce ROM header once all symbols have been resolved
    Include './system/m68kvector.asm'
    Include './system/segaheader.asm'

RomImageEnd

    SECTION_ALLOCATION_REPORT

    MEMORY_ALLOCATION_REPORT

    End
