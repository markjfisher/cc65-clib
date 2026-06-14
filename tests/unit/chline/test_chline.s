.export _test_func
.export _test_result
.export _main

.import _chline
.import _cvline

.segment "CODE"

_main:
  rts

_test_result:
.res 2

.code
_test_func:
  lda #15
  jsr _chline

  lda #8
  jsr _cvline

  lda #1
  sta _test_result + 0
  rts