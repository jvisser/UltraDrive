;------------------------------------------------------------------------------------------
; Linked list
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Linked list/node structure. Uses short pointers so only works for addresses >= $ff8000
; ----------------
    DEFINE_STRUCT LinkedList
        STRUCT_MEMBER.w llNext
        STRUCT_MEMBER.w llPrevious
    DEFINE_STRUCT_END


;-------------------------------------------------
; Init links
; ----------------
LINKED_LIST_INIT Macro node
        clr.l \node
    Endm


;-------------------------------------------------
; Insert before (inputs must be address registers)
; ----------------
LINKED_LIST_INSERT_BEFORE Macro existingNode, newNode, scratch
        movea.w llPrevious(\existingNode), \scratch
        cmpa.w  #0, \scratch
        beq     .noPrevious\@
            move.w  \newNode, llNext(\scratch)
    .noPrevious\@:
        move.w  \newNode, llPrevious(\existingNode)
        move.w  \scratch, llPrevious(\newNode)
        move.w  \existingNode, llNext(\newNode)
    Endm


;-------------------------------------------------
; Insert after (inputs must be address registers)
; ----------------
LINKED_LIST_INSERT_AFTER Macro existingNode, newNode, scratch
        movea.w llNext(\existingNode), \scratch
        cmpa.w  #0, \scratch
        beq     .noNext\@
            move.w  \newNode, llPrevious(\scratch)
    .noNext\@:
        move.w  \newNode, llNext(\existingNode)
        move.w  \scratch, llNext(\newNode)
        move.w  \existingNode, llPrevious(\newNode)
    Endm


;-------------------------------------------------
; Remove self from list
; ----------------
LINKED_LIST_REMOVE Macro node, scratch
        movea.w llNext(\node), \scratch
        cmpa.w  #0, \scratch
        beq     .noNext\@
            move.w  llPrevious(\node), llPrevious(\scratch)
    .noNext\@:

        movea.w llPrevious(\node), \scratch
        beq     .noPrevious\@
        beq     .noNext\@
            move.w  llNext(\node), llNext(\scratch)
    .noPrevious\@:
    Endm
