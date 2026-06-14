.export _test_func
.export _test_result

.import screensize

.segment "CODE"

_test_result:
.res 4

.code
_test_func:
  jsr screensize
  stx _test_result + 0
  sty _test_result + 1

  lda #1
  sta _test_result + 2
  sta _test_result + 3

  rts