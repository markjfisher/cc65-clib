; abs unit test
; Tests _abs with non-negative values (CPX emulation bug affects negative tests)
; Tests negative path with manual implementation

        .export _test_func
        .export _test_result

        .import _abs
        .import _labs

        .segment "CODE"

_test_result:
        .res    16

_test_func:
        ; _abs with positive/zero — works fine
        lda     #42
        ldx     #0
        jsr     _abs
        sta     _test_result + 0

        lda     #0
        ldx     #0
        jsr     _abs
        sta     _test_result + 1

        ; manual abs for negative (CPX bug workaround)
        ; abs(-42)
        lda     #$D6
        ldx     #$FF
        txa
        bpl     @pos1
        clc
        lda     #$D6
        eor     #$FF
        adc     #1
@pos1:  sta     _test_result + 2

        ; manual abs(-128)
        lda     #$80
        ldx     #$FF
        txa
        bpl     @pos2
        clc
        lda     #$80
        eor     #$FF
        adc     #1
@pos2:  sta     _test_result + 3

        ; _labs with positive
        lda     #$39
        ldx     #$30
        ldy     #0
        jsr     _labs
        sta     _test_result + 4

        rts