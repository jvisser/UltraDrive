;------------------------------------------------------------------------------------------
; Linked list
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Linked list/node structure. Uses short pointers so only works for addresses >= $ff8000
; ----------------
    DEFINE_STRUCT LinkedList
        STRUCT_MEMBER.w next
        STRUCT_MEMBER.w previous
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
        movea.w LinkedList_previous(\existingNode), \scratch
        cmpa.w  #NULL, \scratch
        beq.s   .noPrevious\@
            move.w  \newNode, LinkedList_next(\scratch)
    .noPrevious\@:
        move.w  \newNode, LinkedList_previous(\existingNode)
        move.w  \scratch, LinkedList_previous(\newNode)
        move.w  \existingNode, LinkedList_next(\newNode)
    Endm


;-------------------------------------------------
; Insert after (inputs must be address registers)
; ----------------
LINKED_LIST_INSERT_AFTER Macro existingNode, newNode, scratch
        movea.w LinkedList_next(\existingNode), \scratch
        cmpa.w  #NULL, \scratch
        beq.s   .noNext\@
            move.w  \newNode, LinkedList_previous(\scratch)
    .noNext\@:
        move.w  \newNode, LinkedList_next(\existingNode)
        move.w  \scratch, LinkedList_next(\newNode)
        move.w  \existingNode, LinkedList_previous(\newNode)
    Endm


;-------------------------------------------------
; Remove self from list
; ----------------
LINKED_LIST_REMOVE Macro node, scratch
        movea.w LinkedList_next(\node), \scratch
        cmpa.w  #NULL, \scratch
        beq.s   .noNext\@
            move.w  LinkedList_previous(\node), LinkedList_previous(\scratch)
    .noNext\@:

        movea.w LinkedList_previous(\node), \scratch
        cmpa.w  #NULL, \scratch
        beq.s   .noPrevious\@
            move.w  LinkedList_next(\node), LinkedList_next(\scratch)
    .noPrevious\@:
    Endm
