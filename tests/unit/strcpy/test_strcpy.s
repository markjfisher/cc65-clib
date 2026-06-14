.export _test_func
.export _test_result

.import _strcpy
.import _strlen
.import pushax

.segment "CODE"

_test_result:
.res 8

.rodata
_src_hello:
.byte "Hello",0
_src_empty:
.byte 0
_src_az:
.byte "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0
_src_hi:
.byte "Hi",0

.bss
_dst_buf:
.res 64

.code
_test_func:
  lda #<_dst_buf
  ldx #>_dst_buf
  jsr pushax
  lda #<_src_hello
  ldx #>_src_hello
  jsr _strcpy
  lda #<_dst_buf
  ldx #>_dst_buf
  jsr _strlen
  sta _test_result + 0

  lda #<_dst_buf
  ldx #>_dst_buf
  jsr pushax
  lda #<_src_empty
  ldx #>_src_empty
  jsr _strcpy
  lda #<_dst_buf
  ldx #>_dst_buf
  jsr _strlen
  sta _test_result + 1

  lda #<_dst_buf
  ldx #>_dst_buf
  jsr pushax
  lda #<_src_az
  ldx #>_src_az
  jsr _strcpy
  lda #<_dst_buf
  ldx #>_dst_buf
  jsr _strlen
  sta _test_result + 2
  lda _dst_buf
  sta _test_result + 3
  lda _dst_buf + 1
  sta _test_result + 4

  lda #<_dst_buf
  ldx #>_dst_buf
  jsr pushax
  lda #<_src_hi
  ldx #>_src_hi
  jsr _strcpy
  lda _dst_buf
  sta _test_result + 5
  lda _dst_buf + 1
  sta _test_result + 6
  lda _dst_buf + 2
  sta _test_result + 7

  rts