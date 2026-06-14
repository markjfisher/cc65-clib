.export _test_func
.export _test_result

.segment "CODE"

_test_result:
.res 3

.code
_test_func:
  ; Install IRQ/BRK vector at $FFFE to point to our dispatcher
  sei
  lda #<_irq_dispatcher
  sta $FFFE
  lda #>_irq_dispatcher
  sta $FFFF
  cli

  lda #0
  sta _test_result + 0

  ; Push _brk_landing as the return address for BRK recovery
  lda #>(_brk_landing - 1)
  pha
  lda #<(_brk_landing - 1)
  pha

  ; Save stack pointer (points to _brk_landing return address)
  tsx
  stx _saved_s

  ; Trigger a non-ESC BRK
  brk
  .byte $02
  .byte "Test",0
  nop

_brk_landing:
  lda #1
  sta _test_result + 1
  lda #1
  sta _test_result + 2
  rts

; IRQ/BRK dispatcher.
; Stack at entry (after CPU pushed P, PC):
;   SP+0: PC_low (from BRK)
;   SP+1: PC_high
;   SP+2: P (B=1 for BRK, B=0 for IRQ)
_irq_dispatcher:
  pha
  txa
  pha
  tsx
  lda $104,x    ; saved P at offset 4 from SP (after A, X pushes)
  and #$10      ; B flag
  beq _pass_irq

  ; BRK detected — restore stack and return to _brk_landing
  pla
  tax
  pla
  ldx _saved_s
  txs
  ; RTS pops _brk_landing address and jumps there
  rts

_pass_irq:
  pla
  tax
  pla
  rti

.bss
_saved_s:
.res 1