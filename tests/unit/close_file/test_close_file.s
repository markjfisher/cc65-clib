; Real test for close_file(channel): must close the OS channel via OSFIND A=0
; and return 0. The harness file mock clears FILE_OPEN ($0A02) when closed.

.export _test_func
.export _test_result

.import _close_file

.segment "CODE"

_test_result:
.res 3

.code
_test_func:
        ; close_file($11) -> returns 0 (A), and mock marks file closed
        lda     #$11
        jsr     _close_file
        sta     _test_result + 0    ; return value low byte (expect 0)
        stx     _test_result + 1    ; return value high byte (expect 0)
        lda     #1
        sta     _test_result + 2
        rts
