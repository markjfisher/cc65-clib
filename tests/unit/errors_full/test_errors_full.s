.export _test_func
.export _test_result

.import einval
.import ebadf
.import emfile
.import errout
.import ___errno

.segment "CODE"

_test_result:
.res 8

.code
_test_func:
  jsr einval
  lda ___errno
  sta _test_result + 0

  jsr ebadf
  lda ___errno
  sta _test_result + 1

  jsr emfile
  lda ___errno
  sta _test_result + 2

  lda #1
  sta _test_result + 3
  rts