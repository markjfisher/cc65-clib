.export _test_func
.export _test_result
.export _main

.import _set_brk_ret_debug
.import _set_brk_debug_mode_only
.import _disarm_brk_ret
.import _install_brk_handler_global

.segment "CODE"

_main:
  rts

_test_result:
.res 8

cause_brk:
  brk
  .byte $02
  .byte "test", 0
  nop
  nop

_test_func:
  jsr _install_brk_handler_global

  ; Debug mode only (no arm) — verify it returns 0
  jsr _set_brk_debug_mode_only
  sta _test_result + 0

  jsr _disarm_brk_ret

  ; Arm with debug recovery
  jsr _set_brk_ret_debug
  ; Returns 0 here (armed). On BRK recovery, returns 1 here.
  ; We store the value right after — first pass stores 0, second stores 1.
  sta _test_result + 1

  ; On first pass (A=0): jump to BRK trigger
  cmp #0
  bne skip_brk1
  jmp cause_brk
  ; After recovery (A=1): fall through, A is 1
skip_brk1:
  ; _test_result + 1 now contains 1 (recovery value)

  jsr _disarm_brk_ret

  lda #1
  sta _test_result + 2
  rts