.export _test_func
.export _test_result

.import _strcmp
.import pushax

.segment "CODE"

_test_result:
.res 6

.rodata
_str_abc_a:
.byte "ABC",0
_str_abc_b:
.byte "ABC",0
_str_cde:
.byte "CDE",0
_str_empty:
.byte 0
_str_a:
.byte "A",0
_str_ab:
.byte "AB",0
_str_lower:
.byte "abc",0

.code
_test_func:
  lda #<_str_abc_a
  ldx #>_str_abc_a
  jsr pushax
  lda #<_str_abc_b
  ldx #>_str_abc_b
  jsr _strcmp
  sta _test_result + 0
  txa
  ora _test_result + 0
  sta _test_result + 0

  lda #<_str_abc_a
  ldx #>_str_abc_a
  jsr pushax
  lda #<_str_cde
  ldx #>_str_cde
  jsr _strcmp
  sta _test_result + 1
  txa
  ora _test_result + 1
  sta _test_result + 1

  lda #<_str_cde
  ldx #>_str_cde
  jsr pushax
  lda #<_str_abc_a
  ldx #>_str_abc_a
  jsr _strcmp
  sta _test_result + 2
  txa
  ora _test_result + 2
  sta _test_result + 2

  lda #<_str_empty
  ldx #>_str_empty
  jsr pushax
  lda #<_str_a
  ldx #>_str_a
  jsr _strcmp
  sta _test_result + 3
  txa
  ora _test_result + 3
  sta _test_result + 3

  lda #<_str_ab
  ldx #>_str_ab
  jsr pushax
  lda #<_str_abc_a
  ldx #>_str_abc_a
  jsr _strcmp
  sta _test_result + 4
  txa
  ora _test_result + 4
  sta _test_result + 4

  lda #<_str_lower
  ldx #>_str_lower
  jsr pushax
  lda #<_str_abc_a
  ldx #>_str_abc_a
  jsr _strcmp
  sta _test_result + 5
  txa
  ora _test_result + 5
  sta _test_result + 5

  rts