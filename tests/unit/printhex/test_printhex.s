.export _test_func
.export _test_result

.import printhex

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  lda #$A5
  jsr printhex

  lda #$03
  jsr printhex

  lda #1
  sta _test_result + 0
  rts