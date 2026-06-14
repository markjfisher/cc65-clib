.export _test_func
.export _test_result
.export _main

.import initmainargs
.import __argc, __argv

.rodata
cmd_line:
  .byte "PROG", 32, "ARG1", 32, "ARG2", 0

.segment "CODE"

_main:
  rts

_test_result:
.res 6

.code
_test_func:
  lda #<cmd_line
  sta $F2
  lda #>cmd_line
  sta $F3

  jsr initmainargs

  lda __argc
  sta _test_result + 0
  lda __argc + 1
  sta _test_result + 1

  lda __argv
  sta _test_result + 2
  lda __argv + 1
  sta _test_result + 3

  lda #1
  sta _test_result + 4
  sta _test_result + 5

  rts