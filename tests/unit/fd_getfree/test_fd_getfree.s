.export _test_func
.export _test_result
.export _main

.import __fd_getfree

.segment "CODE"

_main:
  rts

_test_result:
.res 6

.code
_test_func:
  lda #$11
  ldx #7
  jsr __fd_getfree
  sta _test_result + 0
  stx _test_result + 1
  lda #$22
  ldx #8
  jsr __fd_getfree
  sta _test_result + 2
  stx _test_result + 3
  lda #1
  sta _test_result + 4
  rts