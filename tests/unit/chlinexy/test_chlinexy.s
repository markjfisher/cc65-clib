.export _test_func
.export _test_result
.export _main

.import _chlinexy
.import pusha

.segment "CODE"

_main:
  rts

_test_result:
.res 3

.code
_test_func:
  lda #5
  jsr pusha
  lda #10
  jsr pusha
  lda #15
  jsr _chlinexy

  lda #1
  sta _test_result + 0
  rts