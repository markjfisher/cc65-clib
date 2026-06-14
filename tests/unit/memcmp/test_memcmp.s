.export _test_func
.export _test_result

.import _memcmp
.import pushax

.segment "CODE"

_test_result:
.res 5

.rodata
_buf1:
.byte 1, 2, 3, 4, 5
_buf2_same:
.byte 1, 2, 3, 4, 5
_buf3_diff:
.byte 1, 2, 0, 4, 5
_buf4_first_diff:
.byte 0, 2, 3, 4, 5
_buf5_last_diff:
.byte 1, 2, 3, 4, 0

.code
_test_func:
  lda #<_buf1
  ldx #>_buf1
  jsr pushax
  lda #<_buf2_same
  ldx #>_buf2_same
  jsr pushax
  lda #5
  ldx #0
  jsr _memcmp
  sta _test_result + 0
  txa
  ora _test_result + 0
  sta _test_result + 0

  lda #<_buf1
  ldx #>_buf1
  jsr pushax
  lda #<_buf3_diff
  ldx #>_buf3_diff
  jsr pushax
  lda #5
  ldx #0
  jsr _memcmp
  sta _test_result + 1
  txa
  ora _test_result + 1
  sta _test_result + 1

  lda #<_buf1
  ldx #>_buf1
  jsr pushax
  lda #<_buf2_same
  ldx #>_buf2_same
  jsr pushax
  lda #0
  ldx #0
  jsr _memcmp
  sta _test_result + 2
  txa
  ora _test_result + 2
  sta _test_result + 2

  lda #<_buf1
  ldx #>_buf1
  jsr pushax
  lda #<_buf4_first_diff
  ldx #>_buf4_first_diff
  jsr pushax
  lda #5
  ldx #0
  jsr _memcmp
  sta _test_result + 3
  txa
  ora _test_result + 3
  sta _test_result + 3

  lda #<_buf1
  ldx #>_buf1
  jsr pushax
  lda #<_buf5_last_diff
  ldx #>_buf5_last_diff
  jsr pushax
  lda #5
  ldx #0
  jsr _memcmp
  sta _test_result + 4
  txa
  ora _test_result + 4
  sta _test_result + 4

  rts