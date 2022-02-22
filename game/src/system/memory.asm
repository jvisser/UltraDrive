;------------------------------------------------------------------------------------------
; Dynamic memory allocation.
;
; Consists of 2 memory allocators with different lifecycles:
;   - Global; Lifecycle managed by the user.
;       - Allocates upwards from the bottom of free memory.
;   - DMA; Lifecycle managed by the DMA queue.
;       - Allocates downwards from the top of free memory.
;       - All allocations will be released after a DMA queue flush.
;------------------------------------------------------------------------------------------

    Include './lib/common/include/debug.inc'

    Include './system/include/memory.inc'
    Include './system/include/os.inc'

    ;-------------------------------------------------
    ; Memory allocator state
    ; ----------------
    DEFINE_VAR SHORT
        VAR.w   memAllocationPointer
        VAR.w   memDMAAllocationPointer
    DEFINE_VAR_END


;-------------------------------------------------
; Fill RAM with zero's. This resets the stack so can only be called from top level code (SysInit or Main).
; ----------------
; Uses: d0-d1/a0-a1
MemoryInit:
_CLR_RAM_LOOP_UNROLL Equ 8

        ; Save return address
        move.l (sp), a1

        moveq   #0, d1
        move.l  d1, a0
        move.w  #(MEM_RAM_SIZE_LONG / _CLR_RAM_LOOP_UNROLL) - 1, d0

    .clearLoop:
        Rept _CLR_RAM_LOOP_UNROLL
            move.l  d1, -(a0)
        Endr
        dbra    d0, .clearLoop

        ; Reset stack pointer and return
        movea.l d1, sp

        bsr.s   MemoryAllocatorReset
        bsr.s   MemoryDMAAllocatorReset
        jmp (a1)


;-------------------------------------------------
; Reset global allocator
; ----------------
MemoryAllocatorReset:
        move.w  RomHeaderRamStart + SIZE_WORD, memAllocationPointer
        rts


;-------------------------------------------------
; Reset frame allocator. Called by the DMA Queue (should not be called directly!)
; ----------------
MemoryDMAAllocatorReset:
        move.w  RomHeaderRamEnd + SIZE_WORD, memDMAAllocationPointer
        rts


;-------------------------------------------------
; Allocate global memory
; ----------------
; Input:
; - d0: Number of bytes to allocate
; Output:
; - a0: Address of allocated memory
; Uses: d0/a0-a1
MemoryAllocate:
        movea.w  memAllocationPointer, a0
        movea.l a0, a1
        addq.w  #1, d0
        andi.w  #$fffe, d0
        adda.w  d0, a1
        move.w  a1, memAllocationPointer

        __MEMORY_CHECK_OVERFLOW a1

        rts


;-------------------------------------------------
; Copy memory from source to destination
; ----------------
; Input:
; - a0: Source address
; - a1: Destination address
; - d0; Length in bytes
; Uses: d0/a0-a1
MemoryCopy:
        subq.w  #1, d0

    .copyLoop:
        move.b  (a0)+, (a1)+
        dbra    d0, .copyLoop
        rts


;-------------------------------------------------
; Allocate frame memory
; ----------------
; Input:
; - d0: Number of bytes to allocate
; Output:
; - a0: Address of allocated memory
; Uses: d0/a0-a1
MemoryDMAAllocate:
        OS_LOCK

        movea.w  memDMAAllocationPointer, a0
        addq.w  #1, d0
        andi.w  #$fffe, d0
        suba.w  d0, a0
        move.w  a0, memDMAAllocationPointer

        __MEMORY_CHECK_OVERFLOW a1

        OS_UNLOCK
        rts
