.export _test_func
.export _test_result

.import disable_cursor_edit
.import restore_cursor_edit

.segment "CODE"

_test_result:
.res 2

.code
_test_func:
  jsr disable_cursor_edit
  jsr restore_cursor_edit

  lda #1
  sta _test_result + 0
  rts