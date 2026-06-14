; MOS stubs — provides mock implementations for key entry points.
; h_unknown_entry is the default for unimplemented vectors (BRK).
; h_osrdch_entry provides a synthetic character stream for cgetc tests.

        .export h_unknown_entry
        .export h_osrdch_entry
        .export mock_rdch_pos
        .export mock_rdch_buf

        .segment "CODE"

MOCK_RDCH_BUF = $1E00

mock_rdch_pos:
        .byte   0
mock_rdch_buf:
        .word   MOCK_RDCH_BUF

h_unknown_entry:
        brk

; OSRDCH — reads next byte from mock_rdch_buf.
; Returns char in A with C=0 on success, C=1 on end-of-data (byte=0).
h_osrdch_entry:
        stx     $00             ; save X to temp
        ldx     mock_rdch_pos
        lda     MOCK_RDCH_BUF, x
        beq     @eof
        inx
        stx     mock_rdch_pos
        ldx     $00             ; restore X
        clc
        rts
@eof:
        ldx     $00             ; restore X
        sec
        rts