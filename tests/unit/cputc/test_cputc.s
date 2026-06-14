.export _test_func
.export _test_result

.import _putchar
.import _cputc

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  lda #'A'
  jsr _cputc

  lda #'!'
  jsr _cputc

  lda #1
  sta _test_result + 0
  sta _test_result + 1
  rts