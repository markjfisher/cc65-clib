.export _test_func
.export _test_result

.import _memcpy
.import pushax

.segment "CODE"

_test_result:
.res 7

.rodata
_src_data:
.byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15

.bss
_dst_buf:
.res 32
_dst_buf2:
.res 32
_dst_buf3:
.res 32

.code
_test_func:
  lda #<_dst_buf
  ldx #>_dst_buf
  jsr pushax
  lda #<_src_data
  ldx #>_src_data
  jsr pushax
  lda #5
  ldx #0
  jsr _memcpy
  lda _dst_buf + 0
  sta _test_result + 0
  lda _dst_buf + 4
  sta _test_result + 1

  lda #$FF
  sta _dst_buf2
  lda #<_dst_buf2
  ldx #>_dst_buf2
  jsr pushax
  lda #<_src_data
  ldx #>_src_data
  jsr pushax
  lda #0
  ldx #0
  jsr _memcpy
  lda _dst_buf2
  sta _test_result + 2

  lda #<_dst_buf3
  ldx #>_dst_buf3
  jsr pushax
  lda #<_src_data
  ldx #>_src_data
  jsr pushax
  lda #16
  ldx #0
  jsr _memcpy
  lda _dst_buf3 + 0
  sta _test_result + 3
  lda _dst_buf3 + 15
  sta _test_result + 4

  lda #<_dst_buf3
  ldx #>_dst_buf3
  jsr pushax
  lda #<_src_data + 10
  ldx #>_src_data
  jsr pushax
  lda #3
  ldx #0
  jsr _memcpy
  lda _dst_buf3 + 0
  sta _test_result + 5
  lda _dst_buf3 + 2
  sta _test_result + 6

  rts