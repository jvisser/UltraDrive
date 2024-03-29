;------------------------------------------------------------------------------------------
; Engine internal stuff for VDPScrollUpdater implementations and state management
;
; User facing side is implemented by ScrollValueUpdater. See file scroll.inc and ./updaters/*.
;------------------------------------------------------------------------------------------

    If (~def(__ENGINE_VDP_SCROLL_INC))
__ENGINE_VDP_SCROLL_INC Equ 1

    Include './lib/common/include/constants.inc'
    
    Include './system/include/memory.inc'
    Include './system/include/vdpdmaqueue.inc'

;-------------------------------------------------
; Update flags
; ----------------
    BIT_CONST.VDP_SCROLL_UPDATE_FOREGROUND      0
    BIT_CONST.VDP_SCROLL_UPDATE_BACKGROUND      1


;-------------------------------------------------
; Structs
; ----------------
    DEFINE_STRUCT VDPScrollUpdaterState
        STRUCT_MEMBER.l   backgroundScrollValueUpdateAddress
        STRUCT_MEMBER.l   backgroundScrollValueTableAddress
        STRUCT_MEMBER.l   backgroundScrollValueStateAddress
        STRUCT_MEMBER.l   backgroundScrollValueConfigurationAddress
        STRUCT_MEMBER.w   backgroundScrollValueCameraOffset
        STRUCT_MEMBER.w   backgroundDMATransferCommandListAddress

        STRUCT_MEMBER.l   foregroundScrollValueUpdateAddress
        STRUCT_MEMBER.l   foregroundScrollValueTableAddress
        STRUCT_MEMBER.l   foregroundScrollValueStateAddress
        STRUCT_MEMBER.l   foregroundScrollValueConfigurationAddress
        STRUCT_MEMBER.w   foregroundScrollValueCameraOffset
        STRUCT_MEMBER.w   foregroundDMATransferCommandListAddress

        STRUCT_MEMBER.b   updateFlags
    DEFINE_STRUCT_END


;-------------------------------------------------
; Put the address of the specified scroll table in target
; ----------------
VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS Macros orientation, config, target
    move.l  vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueTableAddress, \target


;-------------------------------------------------
; Initialize the scroll values for the specified scroll updater configuration
; ----------------
; Input:
; - a0: Viewport
; - a1: ScrollConfiguration
; Uses: Uses: d0-d7/a2-a6
VDP_SCROLL_UPDATER_INIT Macro orientation, config, scrollTableType
        PUSHL   a0
        PUSHL   a1

        lea     ScrollConfiguration_\config\ScrollUpdaterConfiguration(a1), a3                                                      ; a3 = Scroll updater configuration address

        ; Store scroll value updater configuration for later use
        movea.l ScrollValueUpdaterConfiguration_updaterData(a3), a2                                                                 ; a2 = Scroll value updater configuration address
        move.l  a2, vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueConfigurationAddress

        ; Store scroll updater camera offset for later use
        move.w  ScrollValueUpdaterConfiguration_camera(a3), d0                                                                      ; d0 = Viewport camera offset
        move.w  d0, vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueCameraOffset

        ; Get camera address
        lea     (a0, d0), a0                                                                                                        ; a0 = Camera address

        ; Allocate scroll table
        MEMORY_ALLOCATE \scrollTableType\_Size, a1, a4

        ; Store scroll value table address for later use
        move.l  a1, vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueTableAddress

        move.l  ScrollValueUpdaterConfiguration_updater(a3), a3                                                                     ; a3 = scroll updater address

        ; Store scroll value updater update routine address for later use
        move.l  ScrollValueUpdater_update(a3), vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueUpdateAddress

        ; Call scroll value updater: init(a0, a1)
        move.l  ScrollValueUpdater_init(a3), a3                                                                                     ; a3 = scroll updater init subroutine address
        jsr     (a3)

        ; Store address of scroll value updater allocated memory for later use
        move.l  a0, vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueStateAddress

        POPL   a1
        POPL   a0
    Endm


;-------------------------------------------------
; Initialize the scroll values for the specified scroll updater configuration
; ----------------
; Input:
; - a0: Viewport
; Output:
; - d0: Foreground/Background update flags
; - ccr: Condition codes related to update flags
; Uses: Uses: d0-d7/a2-a6
VDP_SCROLL_UPDATER_UPDATE Macro orientation
_CALL_SCROLL_VALUE_UPDATER Macro orientation, config
            move.w  vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueCameraOffset, d0
            lea     (a0, d0), a0                                                                                                    ; a0 = Camera address
            move.l  vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueTableAddress, a1              ; a1 = Scroll table address
            move.l  vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueConfigurationAddress, a2      ; a2 = Scroll value updater configuration
            move.l  vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueStateAddress, a3              ; a3 = Scroll value updater state address
            move.l  vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\ScrollValueUpdateAddress, a4             ; a3 = Scroll value update routine address

            ; update(a0, a1, a2, a3)
            jsr     (a4)
        Endm

        PUSHL   a0

        ; Call background scroll value updater
        _CALL_SCROLL_VALUE_UPDATER \orientation, background

        add.w   d0, d0
        move.w  d0, vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_updateFlags

        PEEKL   a0                                                                                                                  ; a0 = viewport address

        ; Call foreground scroll value updater
        _CALL_SCROLL_VALUE_UPDATER \orientation, foreground

        POPL

        move.w  vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_updateFlags, d1
        or.w    d1, d0
        move.w  d0, vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_updateFlags

        Purge _CALL_SCROLL_VALUE_UPDATER
    Endm

;-------------------------------------------------
; Setup scroll tables and DMA
; ----------------
; Input:
; - a0: Viewport
; - a1: ScrollConfiguration
VDP_SCROLL_DMA_UPDATER_INIT Macro orientation, config, stateType, dmaTransferTemplate, dmaTransferAddress
        PUSHL   a0   ; Preserve inputs
        PUSHL   a1

        ; Initialize scroll tables
        VDP_SCROLL_UPDATER_INIT \orientation\, \config\, \stateType

        ; Setup DMA

        ; Copy DMA transfer command list template to RAM so its source address can be patched with the address of the dynamically allocated scroll table
        MEMORY_ALLOCATE VDPDMATransferCommandList_Size, a2, a3
        move.w  a2, (vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_\config\DMATransferCommandListAddress)
        movea.l a2, a1
        lea     \dmaTransferTemplate, a0
        move.w  #VDPDMATransferCommandList_Size, d0
        jsr     MemoryCopy

        ; Patch DMA source address to that of the allocated scroll buffer
        VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS \orientation\, \config\, d0
        VDP_DMA_TRANSFER_COMMAND_LIST_PATCH_SOURCE a2, d0

        ; Transfer initial scroll values to the VDP
        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT.l a2

        POPL   a1
        POPL   a0
    Endm


;-------------------------------------------------
; Update scroll tables and initiate DMA transfers when scroll values have changed
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a0-a6
VDP_SCROLL_DMA_UPDATER_UPDATE Macro orientation
            VDP_SCROLL_UPDATER_UPDATE \orientation

            move.w  d0, d1

            btst    #VDP_SCROLL_UPDATE_BACKGROUND, d1
            beq.s   .noBackgroundScroll\@

                VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT.w (vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_backgroundDMATransferCommandListAddress)

        .noBackgroundScroll\@:

            btst    #VDP_SCROLL_UPDATE_FOREGROUND, d1
            beq.s   .noForegroundScroll\@

                VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT.w (vsus\orientation\VDPScrollUpdaterState + VDPScrollUpdaterState_foregroundDMATransferCommandListAddress)

        .noForegroundScroll\@:
    Endm

    EndIf
