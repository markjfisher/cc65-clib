.export _test_func
.export _test_result

.import _clock
.import h_unknown_entry

.segment "CODE"

_test_result:
.res 4

.code
_test_func:
  ; Patch OSWORD vector ($FFF2-$FFF3) to redirect to our handler.
  ; The MOS_VECTORS segment contains:
  ;   osword_vector: jmp h_unknown_entry   at $FFF1 (opcode), $FFF2 (lo), $FFF3 (hi)
  lda #<_osword_handler
  sta $FFF2
  lda #>_osword_handler
  sta $FFF3

  jsr _clock
  sta _test_result + 0
  txa
  sta _test_result + 1

  jsr _clock
  sta _test_result + 2
  txa
  sta _test_result + 3

  rts

; OSWORD handler: handles OSWORD 1 (read system clock)
; A = OSWORD number
; X/Y = pointer to parameter block
_osword_handler:
  cmp #1
  bne _pass_through
  ; Fill 5-byte block with: low=0, mid=0, high=0, high_high=0, centiseconds=1
  lda #0
  sta $00,x
  sta $01,x
  sta $02,x
  sta $03,x
  lda #1
  sta $04,x
  rts

_pass_through:
  jmp h_unknown_entry