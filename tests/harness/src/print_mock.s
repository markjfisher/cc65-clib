; Capture OSWRCH output for unit-test assertions.
; Buffer lives at $C800 (not in the harness binary — tests clear/load that RAM via DSL).
; Capture is enabled when mock_print_armed is non-zero (see test scripts).
; PRESERVES X register — critical for loops that use X as counter (chline, cclear, etc).

        .export  mock_print_pos
        .export  mock_print_armed
        .export  h_oswrch_entry

        .segment "CODE"

MOCK_PRINT_BUFFER       = $C800
MOCK_PRINT_BUFFER_SIZE  = 256

mock_print_pos:
        .byte   0
mock_print_armed:
        .byte   0
mock_print_char:
        .byte   0

mock_save_x:
        .byte   0

h_oswrch_entry:
        stx     mock_save_x
        sta     mock_print_char
        lda     mock_print_armed
        beq     @discard
        ldx     mock_print_pos
        cpx     #MOCK_PRINT_BUFFER_SIZE - 1
        bcs     @done
        lda     mock_print_char
        sta     MOCK_PRINT_BUFFER,x
        inx
        stx     mock_print_pos
@done:
        lda     mock_print_char
        ldx     mock_save_x
        rts

@discard:
        lda     mock_print_char
        ldx     mock_save_x
        rts