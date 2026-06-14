.export _test_func
.export _test_result

.import print0

.rodata
str_msg:
.byte "Hello print0!", 0

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  lda #<str_msg
  sta $F2
  lda #>str_msg
  sta $F3

  jsr print0

  lda #1
  sta _test_result + 0
  rts