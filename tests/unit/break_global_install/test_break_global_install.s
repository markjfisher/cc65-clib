.export _test_func
.export _test_result
.export _main

.import _install_brk_handler_global
.import _uninstall_brk_handler_global
.import BRKV

.segment "CODE"

_main:
  rts

_test_result:
.res 6

.code
_test_func:
  lda BRKV
  sta _test_result + 0
  lda BRKV + 1
  sta _test_result + 1
  jsr _install_brk_handler_global
  lda BRKV
  sta _test_result + 2
  lda BRKV + 1
  sta _test_result + 3
  jsr _uninstall_brk_handler_global
  lda BRKV
  sta _test_result + 4
  lda BRKV + 1
  sta _test_result + 5
  rts