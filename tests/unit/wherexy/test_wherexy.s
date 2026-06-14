.export _test_func
.export _test_result

.import _gotox
.import _gotoy
.import _wherex
.import _wherey

.segment "CODE"

_test_result:
.res 4

.code
_test_func:
  jsr _wherex
  sta _test_result + 0

  jsr _wherey
  sta _test_result + 1

  lda #20
  jsr _gotox

  lda #10
  jsr _gotoy

  jsr _wherex
  sta _test_result + 2

  jsr _wherey
  sta _test_result + 3

  rts