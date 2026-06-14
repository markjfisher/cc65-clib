.export _test_func
.export _test_result
.export _main

.import _cclearxy
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
  lda #20
  jsr _cclearxy

  lda #1
  sta _test_result + 0
  rts