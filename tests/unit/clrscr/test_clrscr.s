.export _test_func
.export _test_result

.import _clrscr
.import _gotoxy
.import _wherex
.import _wherey
.import _cclear
.import _chline
.import _cvline
.import pusha

; Stub to satisfy bbc library dependency chain (callmain -> _main)
.export _main

.segment "CODE"

_main:
  rts

_test_result:
.res 3

.code
_test_func:
  lda #5
  jsr pusha
  lda #10
  jsr pusha
  jsr _gotoxy

  jsr _clrscr

  jsr _wherex
  sta _test_result + 0

  jsr _wherey
  sta _test_result + 1

  lda #20
  jsr pusha
  jsr _cclear

  lda #15
  jsr pusha
  jsr _chline

  lda #8
  jsr pusha
  jsr _cvline

  lda #1
  sta _test_result + 2

  rts