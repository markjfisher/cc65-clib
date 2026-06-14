.export _test_func
.export _test_result

.import einval
.import ebadf
.import ___errno

.segment "CODE"

_test_result:
.res 4

.code
_test_func:
  jsr einval
  lda ___errno
  sta _test_result + 0
  jsr ebadf
  lda ___errno
  sta _test_result + 1
  lda #1
  sta _test_result + 2
  rts