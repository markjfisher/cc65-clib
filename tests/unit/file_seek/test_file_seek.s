.export _test_func
.export _test_result
.export _main

.import _open
.import _lseek
.import _read
.import _close
.import pushax
.import pusha
.import ___errno

.include "fcntl.inc"
.include "stdio.inc"

.segment "CODE"

_main:
  rts

_test_result:
.res 13

_fd:
.res 1

_buf:
.res 2

.rodata
_fname:
  .byte "F",0

.code
_test_func:
  lda #<_fname
  ldx #>_fname
  jsr pushax
  lda #O_RDONLY
  ldx #0
  jsr pushax
  lda #0
  ldx #0
  jsr _open
  sta _fd
  cmp #$FF
  beq @open_failed
  lda #1
  sta _test_result + 0
  jmp @seek_set

@open_failed:
  lda #0
  sta _test_result + 0

@seek_set:
  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #$00
  jsr pusha
  jsr pusha
  jsr pusha
  lda #$02
  jsr pusha
  lda #SEEK_SET
  ldx #0
  jsr _lseek
  sta _test_result + 1

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #$00
  jsr pusha
  jsr pusha
  jsr pusha
  lda #$01
  jsr pusha
  lda #SEEK_CUR
  ldx #0
  jsr _lseek
  sta _test_result + 2

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #<_buf
  ldx #>_buf
  jsr pushax
  lda #$01
  ldx #0
  jsr _read
  lda _buf
  sta _test_result + 3
  lda $0A01
  sta _test_result + 4

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #$FF
  jsr pusha
  jsr pusha
  jsr pusha
  lda #$FF
  jsr pusha
  lda #SEEK_CUR
  ldx #0
  jsr _lseek
  sta _test_result + 5

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #<_buf
  ldx #>_buf
  jsr pushax
  lda #$01
  ldx #0
  jsr _read
  lda _buf
  sta _test_result + 6

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #$FF
  jsr pusha
  jsr pusha
  jsr pusha
  lda #$FF
  jsr pusha
  lda #SEEK_END
  ldx #0
  jsr _lseek
  sta _test_result + 7

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #$FF
  jsr pusha
  jsr pusha
  jsr pusha
  lda #$FA
  jsr pusha
  lda #SEEK_END
  ldx #0
  jsr _lseek
  sta _test_result + 8
  lda ___errno
  sta _test_result + 9

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #$00
  jsr pusha
  jsr pusha
  jsr pusha
  jsr pusha
  lda #SEEK_SET
  ldx #0
  jsr _lseek
  sta _test_result + 10

  lda #$00
  jsr pusha
  lda _fd
  jsr pusha
  lda #<_buf
  ldx #>_buf
  jsr pushax
  lda #$01
  ldx #0
  jsr _read
  lda _buf
  sta _test_result + 11

  lda _fd
  ldx #0
  jsr _close

  lda #1
  sta _test_result + 12
  rts
