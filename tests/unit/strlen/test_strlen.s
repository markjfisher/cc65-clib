.export _test_func
.export _test_result

.import _strlen

.segment "CODE"

_test_result:
.res 5

.rodata
_str_empty:
.byte 0
_str_a:
.byte "A",0
_str_hello:
.byte "Hello",0
_str_digits:
.byte "1234567890",0
_str_long:
.byte "A longer string with spaces",0

.code
_test_func:
  lda #<_str_empty
  ldx #>_str_empty
  jsr _strlen
  sta _test_result + 0

  lda #<_str_a
  ldx #>_str_a
  jsr _strlen
  sta _test_result + 1

  lda #<_str_hello
  ldx #>_str_hello
  jsr _strlen
  sta _test_result + 2

  lda #<_str_digits
  ldx #>_str_digits
  jsr _strlen
  sta _test_result + 3

  lda #<_str_long
  ldx #>_str_long
  jsr _strlen
  sta _test_result + 4

  rts