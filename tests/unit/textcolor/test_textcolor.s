.export _test_func
.export _test_result

.import _textcolor
.import _bgcolor
.import _bordercolor

.segment "CODE"

_test_result:
.res 6

.code
_test_func:
  ; textcolor(1) — should return old color (0 initially)
  lda #1
  jsr _textcolor
  sta _test_result + 0

  ; textcolor(2) — should return old color (1)
  lda #2
  jsr _textcolor
  sta _test_result + 1

  ; bgcolor(3) — should return old bgcolor (0 initially)
  lda #3
  jsr _bgcolor
  sta _test_result + 2

  ; bgcolor(4) — should return old bgcolor (3)
  lda #4
  jsr _bgcolor
  sta _test_result + 3

  ; bordercolor — stub that returns 1
  jsr _bordercolor
  sta _test_result + 4

  lda #1
  sta _test_result + 5

  rts