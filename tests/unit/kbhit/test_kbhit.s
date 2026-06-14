.export _test_func
.export _test_result

.import _kbhit
.import pusha

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  jsr _kbhit
  sta _test_result + 0

  lda #1
  sta _test_result + 1

  rts