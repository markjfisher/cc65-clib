.export _test_func
.export _test_result

.import _atoi
.import _atol

.segment "CODE"

_test_result:
.res 7

.rodata
_str_123:
.byte "123",0
_str_neg42:
.byte "-42",0
_str_zero:
.byte "0",0
_str_ws5:
.byte "  5",0
_str_abc:
.byte "abc",0
_str_65535:
.byte "65535",0
_str_neg999:
.byte "-999",0

.code
_test_func:
  lda #<_str_123
  ldx #>_str_123
  jsr _atoi
  sta _test_result + 0

  lda #<_str_neg42
  ldx #>_str_neg42
  jsr _atoi
  sta _test_result + 1

  lda #<_str_zero
  ldx #>_str_zero
  jsr _atoi
  sta _test_result + 2

  lda #<_str_ws5
  ldx #>_str_ws5
  jsr _atoi
  sta _test_result + 3

  lda #<_str_abc
  ldx #>_str_abc
  jsr _atoi
  sta _test_result + 4

  lda #<_str_65535
  ldx #>_str_65535
  jsr _atol
  sta _test_result + 5

  lda #<_str_neg999
  ldx #>_str_neg999
  jsr _atol
  sta _test_result + 6

  rts