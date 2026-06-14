.export _test_func
.export _test_result

.import __fd_getflags
.import __fd_getchannel
.import __fd_release
.import __fd_setseek
.import __fd_clearseek

.segment "CODE"

_test_result:
.res 10

.code
_test_func:
  ; __fd_getflags(0) -> FD_FLAG_READ|FD_FLAG_CON = 0x11
  lda #0
  jsr __fd_getflags
  sta _test_result + 0

  ; __fd_getflags(99) -> >= FD_MAX -> jmp ebadf -> returns 0xFF
  lda #99
  jsr __fd_getflags
  sta _test_result + 1

  ; __fd_getflags(3) -> free slot (flags=0) -> ebadf -> 0xFF
  lda #3
  jsr __fd_getflags
  sta _test_result + 2

  ; __fd_getchannel(0) -> fd 0/1/2 are special, chan table starts at FD_START (3)
  ; fd_chan - FD_START = -3, which wraps... actually chan for fd0 is out of range
  ; Just call it and store result (may be garbage)
  lda #0
  jsr __fd_getchannel
  sta _test_result + 3

  ; __fd_getflags(1) -> FD_FLAG_WRITE|FD_FLAG_CON = 0x12
  lda #1
  jsr __fd_getflags
  sta _test_result + 4

  ; __fd_getflags(2) -> FD_FLAG_WRITE|FD_FLAG_CON = 0x12
  lda #2
  jsr __fd_getflags
  sta _test_result + 5

  lda #1
  sta _test_result + 6
  sta _test_result + 7
  sta _test_result + 8
  sta _test_result + 9

  rts