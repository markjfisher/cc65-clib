.export _test_func
.export _test_result

.import _itoa
.import _ltoa
.import _strlen
.import pushax

.segment "CODE"

_test_result:
.res 10

.bss
_buf_itoa:
.res 16
_buf_hex:
.res 16
_buf_ltoa:
.res 16

.code
_test_func:
  lda #$15
  ldx #$03
  jsr pushax
  lda #<_buf_itoa
  ldx #>_buf_itoa
  jsr pushax
  lda #10
  jsr _itoa
  lda #<_buf_itoa
  ldx #>_buf_itoa
  jsr _strlen
  sta _test_result + 0
  lda _buf_itoa + 0
  sta _test_result + 1
  lda _buf_itoa + 2
  sta _test_result + 2

  lda #0
  ldx #0
  jsr pushax
  lda #<_buf_itoa
  ldx #>_buf_itoa
  jsr pushax
  lda #10
  jsr _itoa
  lda #<_buf_itoa
  ldx #>_buf_itoa
  jsr _strlen
  sta _test_result + 3
  lda _buf_itoa + 0
  sta _test_result + 4

  lda #$FF
  ldx #$00
  jsr pushax
  lda #<_buf_hex
  ldx #>_buf_hex
  jsr pushax
  lda #16
  jsr _itoa
  lda #<_buf_hex
  ldx #>_buf_hex
  jsr _strlen
  sta _test_result + 5
  lda _buf_hex + 0
  sta _test_result + 6
  lda _buf_hex + 1
  sta _test_result + 7

  lda #$FF
  ldx #$FF
  jsr pushax
  lda #$19
  ldx #$FC
  jsr pushax
  lda #<_buf_ltoa
  ldx #>_buf_ltoa
  jsr pushax
  lda #10
  jsr _ltoa
  lda _buf_ltoa + 0
  sta _test_result + 8
  lda #<_buf_ltoa
  ldx #>_buf_ltoa
  jsr _strlen
  sta _test_result + 9

  rts