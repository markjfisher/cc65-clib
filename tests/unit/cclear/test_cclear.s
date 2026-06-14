.export _test_func
.export _test_result

.import _cclear

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  lda #20
  jsr _cclear

  lda #1
  sta _test_result + 0
  rts