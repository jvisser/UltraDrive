;------------------------------------------------------------------------------------------
; Support macros for building DMA based VDP scroll updaters for multi value scroll modes
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Setup scroll tables and DMA
; ----------------
; Input:
; - a0: Viewport
; - a1: ScrollConfiguration
VDP_SCROLL_DMA_UPDATER_INIT Macro orientation, config, stateType, dmaTransferTemplate, dmaTransferAddress
        PUSHM   a0-a1   ; Preserve inputs

        ; Initialize scroll tables
        VDP_SCROLL_UPDATER_INIT \orientation\, \config\, \stateType

        ; Setup DMA

        ; Copy DMA transfer command list template to RAM to its source address can be patched with the address of the dynamically allocated scroll table
        MEMORY_ALLOCATE VDPDMATransferCommandList_Size, a2, a3
        move.l  a2, \dmaTransferAddress
        movea.l a2, a1
        lea     \dmaTransferTemplate, a0
        move.w  #VDPDMATransferCommandList_Size, d0
        jsr     MemCopy

        ; Patch DMA source address to that of the allocated scroll buffer
        VDP_SCROLL_UPDATER_GET_TABLE_ADDRESS \orientation\, \config\, d0
        VDP_DMA_TRANSFER_COMMAND_LIST_PATCH_SOURCE a2, d0

        ; Transfer initial scroll values to the VDP
        VDP_DMA_TRANSFER_COMMAND_LIST_INDIRECT \dmaTransferAddress

        POPM   a0-a1
    Endm


;-------------------------------------------------
; Update scroll tables and initiate DMA transfers when scroll values have changed
; ----------------
; Input:
; - a0: Viewport
; Uses: d0-d1/a0-a6
VDP_SCROLL_DMA_UPDATER_UPDATE Macro orientation, backgroundDMATransferAddress, foregroundDMATransferAddress
            VDP_SCROLL_UPDATER_UPDATE \orientation

            move.w  d0, d1

            btst    #VDP_SCROLL_UPDATE_BACKGROUND, d1
            beq     .noBackgroundScroll\@

                VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT \backgroundDMATransferAddress

        .noBackgroundScroll\@:

            btst    #VDP_SCROLL_UPDATE_FOREGROUND, d1
            beq     .noForegroundScroll\@

                VDP_DMA_QUEUE_ADD_COMMAND_LIST_INDIRECT \foregroundDMATransferAddress

        .noForegroundScroll\@:
    Endm
