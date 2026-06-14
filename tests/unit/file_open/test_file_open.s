.export _test_func
.export _test_result

.import _open
.import _close
.import pushax

.segment "CODE"

_test_result:
.res 3

.rodata
_invalid_name:
.byte "ZZZZNONEXIST",0

.code
_test_func:
  lda #<_invalid_name
  ldx #>_invalid_name
  jsr pushax
  lda #0
  ldx #0
  jsr _open
  cmp #$FF
  bne _not_minus1_0
  txa
  cmp #$FF
  bne _not_minus1_0
  lda #1
  sta _test_result + 0
  jmp _cont0
_not_minus1_0:
  lda #0
  sta _test_result + 0
_cont0:
  lda #$FF
  ldx #$FF
  jsr _close
  cmp #$FF
  bne _not_minus1_2
  txa
  cmp #$FF
  bne _not_minus1_2
  lda #1
  sta _test_result + 2
  rts
_not_minus1_2:
  lda #0
  sta _test_result + 2
  rts