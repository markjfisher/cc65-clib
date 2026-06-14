.export _test_func
.export _test_result

.import _gotoxy
.import _wherey
.import _gotoy
.import pusha

.segment "CODE"

_test_result:
.res 4

.code
_test_func:
  ; gotoxy(x=10, y=5) — fastcall: rightmost (y=5) in A, x=10 on stack
  lda #10
  jsr pusha
  lda #5
  jsr _gotoxy

  jsr _wherey
  sta _test_result + 0

  lda #7
  jsr _gotoy

  jsr _wherey
  sta _test_result + 1

  lda #1
  sta _test_result + 2
  rts