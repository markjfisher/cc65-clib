; OSWORD stub for soft65c02 harness.
;
; OSWORD &0E copies seven BCD date/time bytes from MOCK_OSWORD_CLOCK into the
; caller-supplied block. Tests can rewrite that backing store directly.

        .export h_osword_entry

        .import h_unknown_entry
        .importzp ptr1

        .segment "CODE"

MOCK_OSWORD_CLOCK = $0AB0

h_osword_entry:
        cmp     #$0E
        bne     @unknown

        stx     ptr1
        sty     ptr1+1
        ldy     #$00
@copy:
        lda     MOCK_OSWORD_CLOCK,y
        sta     (ptr1),y
        iny
        cpy     #$07
        bcc     @copy
        rts

@unknown:
        jmp     h_unknown_entry
