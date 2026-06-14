.export _test_func
.export _test_result

.import _memset
.import pushax

.segment "CODE"

_test_result:
.res 9

.bss
_buf:
.res 16

.code
_test_func:
  lda #$FF
  sta _buf + 0
  sta _buf + 1
  sta _buf + 2
  sta _buf + 3
  sta _buf + 4
  sta _buf + 5
  sta _buf + 6
  sta _buf + 7

  lda #<_buf
  ldx #>_buf
  jsr pushax
  lda #$AA
  ldx #0
  jsr pushax
  lda #4
  ldx #0
  jsr _memset
  lda _buf + 0
  sta _test_result + 0
  lda _buf + 3
  sta _test_result + 1
  lda _buf + 4
  sta _test_result + 2

  lda #<_buf
  ldx #>_buf
  jsr pushax
  lda #0
  ldx #0
  jsr pushax
  lda #2
  ldx #0
  jsr _memset
  lda _buf + 0
  sta _test_result + 3
  lda _buf + 1
  sta _test_result + 4

  lda #$BB
  sta _buf + 0
  lda #<_buf
  ldx #>_buf
  jsr pushax
  lda #$BB
  ldx #0
  jsr pushax
  lda #0
  ldx #0
  jsr _memset
  lda _buf + 0
  sta _test_result + 5

  lda #$FF
  sta _buf + 0
  sta _buf + 1
  sta _buf + 2
  sta _buf + 3
  sta _buf + 4
  sta _buf + 5
  sta _buf + 6
  sta _buf + 7

  lda #<_buf
  ldx #>_buf
  jsr pushax
  lda #$FF
  ldx #0
  jsr pushax
  lda #8
  ldx #0
  jsr _memset
  lda _buf + 0
  sta _test_result + 6
  lda _buf + 7
  sta _test_result + 7
  lda _buf + 8
  sta _test_result + 8

  rts