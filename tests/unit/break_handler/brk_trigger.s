; brk_trigger.s — helper to raise BRK with non-ESC error byte
; Exported with leading underscores for C.

        .export _cause_brk_non_esc

        .code

_cause_brk_non_esc:
        brk
        .byte $02          ; non-ESC error number
        .byte "Test",0
        nop
        nop