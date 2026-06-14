.export _test_func
.export _test_result

.import _gotoxy
.import _wherex
.import _wherey
.import pusha

.segment "CODE"

_test_result:
.res 4

.code
_test_func:
  jsr _wherex
  sta _test_result + 0

  jsr _wherey
  sta _test_result + 1

  ; gotoxy(x=10, y=5) — fastcall: rightmost (y=5) in A, x=10 on stack
  lda #10
  jsr pusha           ; x=10 pushed
  lda #5              ; y=5 in A (rightmost, fastcall)
  jsr _gotoxy

  jsr _wherex
  sta _test_result + 2

  jsr _wherey
  sta _test_result + 3

  rts