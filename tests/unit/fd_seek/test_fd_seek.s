.export _test_func
.export _test_result
.export _main

.import __fd_getseek
.import __fd_setseek
.import __fd_clearseek
.import __fd_getflags
.import __fd_getfree
.import pusha

.segment "CODE"

_main:
  rts

_test_result:
.res 8

.code
_test_func:
  lda #$11
  ldx #7
  jsr __fd_getfree
  sta _test_result + 0   ; should be 3

  ; __fd_setseek(off_t pos, unsigned char fd) — fastcall, fd in A
  ; Push pos = 12345 (0x00003039): 4 bytes, low first
  lda #$39
  jsr pusha
  lda #$30
  jsr pusha
  lda #0
  jsr pusha
  lda #0
  jsr pusha

  lda #3
  jsr __fd_setseek
  sta _test_result + 1   ; should be 0

  ; Read back seek value
  lda #3
  jsr __fd_getseek
  sta _test_result + 2
  stx _test_result + 3

  lda #3
  jsr __fd_getflags
  sta _test_result + 4

  lda #3
  jsr __fd_clearseek
  sta _test_result + 5

  lda #3
  jsr __fd_getflags
  sta _test_result + 6

  lda #1
  sta _test_result + 7
  rts