.export _test_func
.export _test_result

.import _cgetc

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  jsr _cgetc
  sta _test_result + 0

  jsr _cgetc
  sta _test_result + 1

  rts