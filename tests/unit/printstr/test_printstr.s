.export _test_func
.export _test_result

.import printstr

.rodata
str_test:
.byte "HELLO", 0

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  lda #<str_test
  sta $F2
  lda #>str_test
  sta $F3

  jsr printstr

  lda #1
  sta _test_result + 0
  rts