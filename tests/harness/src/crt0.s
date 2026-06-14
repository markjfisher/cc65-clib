; cc65 bbc target test harness - entry point and startup
;
; This harness sets up a minimal BBC MOS environment for soft65c02_unit
; to test individual cc65 bbc library functions in isolation.

        .export     halt
        .export     init_harness
        .export     end_init_harness
        .export     brk_dispatch

        .import     _test_func
        .importzp   c_sp

.ifdef APP_INC_PRESENT
        .include    "app.inc"
.endif

.segment "STARTUP"
halt:
        .byte   $db         ; STP in 65c02 emulator

.segment "CODE"
init_harness:
        ; Initialise the cc65 C parameter stack. Pure-asm tests get away with
        ; an uninitialised c_sp (their frames are tiny), but C library code with
        ; real locals (e.g. open()'s char filename[128]) would otherwise grow
        ; the stack down from $0000 and wrap into the MOS vector area at $FFB9+,
        ; corrupting OSFIND/OSBGET and hanging the test. Anchor it below the
        ; sideways ROM / I/O space at $8000.
        lda     #$00
        sta     c_sp
        lda     #$80
        sta     c_sp+1

        jsr     _test_func
end_init_harness:
        brk

; IRQ/BRK dispatch — reads BRKV ($0202) and jumps there
; This allows the cc65 break handler to work via the standard IRQ vector
brk_dispatch:
        pha
        lda     $0202
        sta     $00
        lda     $0203
        sta     $01
        pla
        jmp     ($00)

.segment "V_IRQ"
        .word brk_dispatch

.segment "V_RESET"
        .word halt