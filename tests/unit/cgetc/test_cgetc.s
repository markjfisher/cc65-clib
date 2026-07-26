.export _test_func
.export _test_result

.import _cgetc

.segment "CODE"

_test_result:
.res 6

.code
_test_func:
  jsr _cgetc
  sta _test_result + 0
  stx _test_result + 1

  jsr _cgetc
  sta _test_result + 2
  stx _test_result + 3

  jsr _cgetc
  sta _test_result + 4
  stx _test_result + 5

  rts
