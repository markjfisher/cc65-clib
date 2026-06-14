.export _test_func
.export _test_result

.import _strcat
.import _strlen
.import pushax

.segment "CODE"

_test_result:
.res 8

.rodata
_src_world:
.byte " World",0
_src_empty:
.byte 0
_src_abc:
.byte "ABC",0

.bss
_buf_hello:
.res 32
_buf_alone:
.res 32
_buf_abc:
.res 32

.code
_test_func:
  lda #'H'
  sta _buf_hello
  lda #'e'
  sta _buf_hello + 1
  lda #'l'
  sta _buf_hello + 2
  lda #'l'
  sta _buf_hello + 3
  lda #'o'
  sta _buf_hello + 4
  lda #0
  sta _buf_hello + 5

  lda #<_buf_hello
  ldx #>_buf_hello
  jsr pushax
  lda #<_src_world
  ldx #>_src_world
  jsr _strcat
  lda #<_buf_hello
  ldx #>_buf_hello
  jsr _strlen
  sta _test_result + 0
  lda _buf_hello
  sta _test_result + 1
  lda _buf_hello + 6
  sta _test_result + 2

  lda #'A'
  sta _buf_alone
  lda #'l'
  sta _buf_alone + 1
  lda #'o'
  sta _buf_alone + 2
  lda #'n'
  sta _buf_alone + 3
  lda #'e'
  sta _buf_alone + 4
  lda #0
  sta _buf_alone + 5

  lda #<_buf_alone
  ldx #>_buf_alone
  jsr pushax
  lda #<_src_empty
  ldx #>_src_empty
  jsr _strcat
  lda #<_buf_alone
  ldx #>_buf_alone
  jsr _strlen
  sta _test_result + 3
  lda _buf_alone
  sta _test_result + 4

  lda #0
  sta _buf_abc
  sta _buf_abc + 1
  sta _buf_abc + 2
  sta _buf_abc + 3
  sta _buf_abc + 4
  sta _buf_abc + 5

  lda #<_buf_abc
  ldx #>_buf_abc
  jsr pushax
  lda #<_src_abc
  ldx #>_src_abc
  jsr _strcat
  lda #<_buf_abc
  ldx #>_buf_abc
  jsr _strlen
  sta _test_result + 5
  lda _buf_abc + 2
  sta _test_result + 6
  lda _buf_abc + 3
  sta _test_result + 7

  rts