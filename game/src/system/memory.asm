;------------------------------------------------------------------------------------------
; Random Access Memory (ROM/RAM) functions and variable allocation
;------------------------------------------------------------------------------------------

    Include './common/include/debug.inc'

    Include './system/include/memory.inc'

    ;-------------------------------------------------
    ; Memory allocator state
    ; ----------------
    DEFINE_VAR SHORT
        VAR.w   memAllocationPointer
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

        MEMORY_ALLOCATOR_RESET
        jmp (a1)


;-------------------------------------------------
; Allocate memory
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

        __MEMORY_CHECK_OVERFLOW a1

        move.w  a1, memAllocationPointer
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
