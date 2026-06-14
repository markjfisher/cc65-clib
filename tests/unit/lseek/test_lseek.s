.export _test_func
.export _test_result
.export _main

.import _lseek
.import pusha
.importzp sreg
.import ___errno

.segment "CODE"

_main:
  rts

_test_result:
.res 14

.code
_test_func:
  ; Test 1: lseek(999, 0, SEEK_SET) -> invalid fd -> return -1, errno=EBADF
  ; Push fd=999 (int, 2 bytes, low first)
  lda #<999
  jsr pusha
  lda #>999
  jsr pusha

  ; Push offset=0 (off_t, 4 bytes, low first)
  lda #0
  jsr pusha
  jsr pusha
  jsr pusha
  jsr pusha

  ; whence = SEEK_SET = 0
  lda #0
  ldx #0
  jsr _lseek

  ; Store result (off_t: A=low, X=high, sreg=top)
  sta _test_result + 0
  stx _test_result + 1
  lda sreg
  sta _test_result + 2
  lda sreg + 1
  sta _test_result + 3

  ; Store __errno
  lda ___errno
  sta _test_result + 4
  lda ___errno + 1
  sta _test_result + 5

  ; Test 2: lseek(0, 0, SEEK_SET) -> CON fd -> return -1, errno=ESPIPE
  lda #<0
  jsr pusha
  lda #>0
  jsr pusha

  lda #0
  jsr pusha
  jsr pusha
  jsr pusha
  jsr pusha

  lda #0
  ldx #0
  jsr _lseek

  sta _test_result + 6
  stx _test_result + 7
  lda sreg
  sta _test_result + 8
  lda sreg + 1
  sta _test_result + 9

  lda ___errno
  sta _test_result + 10
  lda ___errno + 1
  sta _test_result + 11

  lda #1
  sta _test_result + 12
  sta _test_result + 13

  rts