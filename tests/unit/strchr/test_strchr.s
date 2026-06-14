.export _test_func
.export _test_result

.import _strchr
.import pushax

.segment "CODE"

_test_result:
.res 8

.rodata
_str_hello:
.byte "Hello World",0

.code
_test_func:
  lda #<_str_hello
  ldx #>_str_hello
  jsr pushax
  lda #'W'
  jsr _strchr
  beq _not_found_0
  lda #1
  sta _test_result + 0
  bne _done_0
_not_found_0:
  lda #0
  sta _test_result + 0
_done_0:
  sta _test_result + 1      ; A = 1 (found) or 0 (not found) — doesn't matter

  lda #<_str_hello
  ldx #>_str_hello
  jsr pushax
  lda #'H'
  jsr _strchr
  beq _not_found_1
  lda #1
  bne _done_1
_not_found_1:
  lda #0
_done_1:
  sta _test_result + 2

  lda #<_str_hello
  ldx #>_str_hello
  jsr pushax
  lda #'d'
  jsr _strchr
  beq _not_found_2
  lda #1
  bne _done_2
_not_found_2:
  lda #0
_done_2:
  sta _test_result + 3

  lda #<_str_hello
  ldx #>_str_hello
  jsr pushax
  lda #'z'
  jsr _strchr
  beq _not_found_3
  lda #1
  bne _done_3
_not_found_3:
  lda #0
_done_3:
  sta _test_result + 4

  lda #<_str_hello
  ldx #>_str_hello
  jsr pushax
  lda #$20
  jsr _strchr
  beq _not_found_4
  lda #1
  bne _done_4
_not_found_4:
  lda #0
_done_4:
  sta _test_result + 5

  lda #<_str_hello
  ldx #>_str_hello
  jsr pushax
  lda #0
  jsr _strchr
  beq _not_found_5
  lda #1
  bne _done_5
_not_found_5:
  lda #0
_done_5:
  sta _test_result + 6

  lda _str_hello + 11
  sta _test_result + 7

  rts