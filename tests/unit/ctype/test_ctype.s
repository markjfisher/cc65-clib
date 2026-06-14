.export _test_func
.export _test_result

.import _isalpha
.import _isdigit
.import _isalnum
.import _isspace
.import _islower
.import _isupper
.import _isxdigit
.import _toupper
.import _tolower
.import _ispunct
.import _isprint
.import _iscntrl
.import pusha

.segment "CODE"

_test_result:
.res 32

.code
_test_func:
  lda #'A'
  jsr pusha
  jsr _isalpha
  sta _test_result + 0
  lda #'z'
  jsr pusha
  jsr _isalpha
  sta _test_result + 1
  lda #'0'
  jsr pusha
  jsr _isalpha
  sta _test_result + 2
  lda #$20
  jsr pusha
  jsr _isalpha
  sta _test_result + 3

  lda #'5'
  jsr pusha
  jsr _isdigit
  sta _test_result + 4
  lda #'0'
  jsr pusha
  jsr _isdigit
  sta _test_result + 5
  lda #'A'
  jsr pusha
  jsr _isdigit
  sta _test_result + 6

  lda #'A'
  jsr pusha
  jsr _isalnum
  sta _test_result + 7
  lda #'9'
  jsr pusha
  jsr _isalnum
  sta _test_result + 8
  lda #'#'
  jsr pusha
  jsr _isalnum
  sta _test_result + 9

  lda #$20
  jsr pusha
  jsr _isspace
  sta _test_result + 10
  lda #$09
  jsr pusha
  jsr _isspace
  sta _test_result + 11
  lda #'A'
  jsr pusha
  jsr _isspace
  sta _test_result + 12
  lda #$0A
  jsr pusha
  jsr _isspace
  sta _test_result + 13

  lda #'a'
  jsr pusha
  jsr _islower
  sta _test_result + 14
  lda #'A'
  jsr pusha
  jsr _islower
  sta _test_result + 15
  lda #'Z'
  jsr pusha
  jsr _isupper
  sta _test_result + 16
  lda #'z'
  jsr pusha
  jsr _isupper
  sta _test_result + 17

  lda #'f'
  jsr pusha
  jsr _isxdigit
  sta _test_result + 18
  lda #'G'
  jsr pusha
  jsr _isxdigit
  sta _test_result + 19

  lda #'a'
  jsr pusha
  jsr _toupper
  sta _test_result + 20
  lda #'A'
  jsr pusha
  jsr _toupper
  sta _test_result + 21
  lda #'5'
  jsr pusha
  jsr _toupper
  sta _test_result + 22
  lda #'Z'
  jsr pusha
  jsr _tolower
  sta _test_result + 23
  lda #'z'
  jsr pusha
  jsr _tolower
  sta _test_result + 24
  lda #'$'
  jsr pusha
  jsr _tolower
  sta _test_result + 25

  lda #'.'
  jsr pusha
  jsr _ispunct
  sta _test_result + 26
  lda #'A'
  jsr pusha
  jsr _ispunct
  sta _test_result + 27

  lda #$20
  jsr pusha
  jsr _isprint
  sta _test_result + 28
  lda #$01
  jsr pusha
  jsr _isprint
  sta _test_result + 29
  lda #'~'
  jsr pusha
  jsr _isprint
  sta _test_result + 30
  lda #$01
  jsr pusha
  jsr _iscntrl
  sta _test_result + 31

  rts