; brk_helper.s — provides cause_brk_func for test_break.c
        .export _cause_brk_func

        .code
_cause_brk_func:
        brk
        .byte $02
        .byte "T", 0
        nop
        nop
        rts