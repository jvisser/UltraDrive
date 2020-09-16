;------------------------------------------------------------------------------------------
; Assembler (ASM68K/SNASM) configuration
;------------------------------------------------------------------------------------------

    OPT c+,     & ; Case sensitive
        l+,     & ; Use . prefix for local labels
        ws+,    & ; Allow white space
        op+,    & ; PC relative optimisation 
        os+,    & ; Short branch optimisation
        ow+,    & ; Absolute word addressing optimisation
        oz+,    & ; Zero offset optimisation
        oaq+,   & ; addq optimisation
        osq+,   & ; subq optimisation
        omq+      ; moveq optimisation
