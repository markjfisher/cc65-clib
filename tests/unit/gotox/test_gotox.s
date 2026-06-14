.export _test_func
.export _test_result

.import _gotox
.import _gotoy

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  lda #10
  jsr _gotox

  lda #5
  jsr _gotoy

  lda #1
  sta _test_result + 0
  rts