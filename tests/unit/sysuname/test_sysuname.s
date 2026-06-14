.export _test_func
.export _test_result

.import __sysuname

MACHINE_OFFSET = 44

.segment "CODE"

_test_result:
.res 70

.code
_test_func:
  lda #<_test_result
  ldx #>_test_result
  jsr __sysuname

  sta _test_result + 68

  lda #1
  sta _test_result + 69

  rts