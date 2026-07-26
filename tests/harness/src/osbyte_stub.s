; Minimal test harness MOS: OSBYTE entry compatible with BBC JSR/JMP $FFF4.
;
; Provides stubs for all OSBYTE calls that the cc65 bbc library might use.
; Tests can configure specific OSBYTE behaviour by writing to exposed variables
; (e.g. osbyte_break_type, osbyte_76_fake_keyboard).

        .export  h_osbyte_entry
        .export  h_osbyte_do_jmp
        .export  osbyte_76_fake_keyboard
        .export  osbyte_8f_claim_type
        .export  osbyte_break_type

        .export  osbyte_76
        .export  osbyte_83
        .export  osbyte_84
        .export  osbyte_8f
        .export  osbyte_a8
        .export  osbyte_ea
        .export  osbyte_ec
        .export  osbyte_fd

        .export  osbyte_80
        .export  osbyte_91
        .export  osbyte_7f

        .import  file_mock_eof_status

        .segment "CODE"

osbyte_noop:
        rts

osbyte_01:
        rts

osbyte_04:
        rts

; OSBYTE 236 — character destination (print_char); return screen in X.
osbyte_ec:
        ldx     #$00
        rts

osbyte_76_fake_keyboard:
        .byte   0               ; bit7 = CTRL for OSBYTE &76

osbyte_8f_claim_type:
        .byte   0               ; capture the claimed type for testing

osbyte_break_type:
        .byte   1               ; 0=soft, 1=power up, 2=hard

osbyte_saveX:
        .byte   0

; Preserve MOS parameters, dispatch by A (OSBYTE number) via RTS trampoline
h_osbyte_entry:
        stx     osbyte_saveX
        tax
        lda     osbyte_table_hi,x
        pha
        lda     osbyte_table_lo,x
        pha
        txa
        ldx     osbyte_saveX
h_osbyte_do_jmp:
        rts

osbyte_unimplemented:
        brk

osbyte_table_lo:
.repeat 256, cmd
        .if     cmd = $01
        .byte   .lobyte(osbyte_01 - 1)
        .elseif cmd = $02
        .byte   .lobyte(osbyte_noop - 1)
        .elseif cmd = $03
        .byte   .lobyte(osbyte_noop - 1)
        .elseif cmd = $04
        .byte   .lobyte(osbyte_04 - 1)
        .elseif cmd = $07
        .byte   .lobyte(osbyte_noop - 1)
        .elseif cmd = $08
        .byte   .lobyte(osbyte_noop - 1)
        .elseif cmd = $15
        .byte   .lobyte(osbyte_noop - 1)
        .elseif cmd = $76
        .byte   .lobyte(osbyte_76 - 1)
        .elseif cmd = $7f
        .byte   .lobyte(osbyte_7f - 1)
        .elseif cmd = $7e
        .byte   .lobyte(osbyte_noop - 1)
        .elseif cmd = $83
        .byte   .lobyte(osbyte_83 - 1)
        .elseif cmd = $84
        .byte   .lobyte(osbyte_84 - 1)
        .elseif cmd = $80
        .byte   .lobyte(osbyte_80 - 1)
        .elseif cmd = $91
        .byte   .lobyte(osbyte_91 - 1)
        .elseif cmd = $a8
        .byte   .lobyte(osbyte_a8 - 1)
        .elseif cmd = $8f
        .byte   .lobyte(osbyte_8f - 1)
        .elseif cmd = $ea
        .byte   .lobyte(osbyte_ea - 1)
        .elseif cmd = $ec
        .byte   .lobyte(osbyte_ec - 1)
        .elseif cmd = $fd
        .byte   .lobyte(osbyte_fd - 1)
        .else
        .byte   .lobyte(osbyte_unimplemented - 1)
        .endif
.endrepeat

osbyte_table_hi:
.repeat 256, cmd
        .if     cmd = $01
        .byte   .hibyte(osbyte_01 - 1)
        .elseif cmd = $02
        .byte   .hibyte(osbyte_noop - 1)
        .elseif cmd = $03
        .byte   .hibyte(osbyte_noop - 1)
        .elseif cmd = $04
        .byte   .hibyte(osbyte_04 - 1)
        .elseif cmd = $07
        .byte   .hibyte(osbyte_noop - 1)
        .elseif cmd = $08
        .byte   .hibyte(osbyte_noop - 1)
        .elseif cmd = $15
        .byte   .hibyte(osbyte_noop - 1)
        .elseif cmd = $76
        .byte   .hibyte(osbyte_76 - 1)
        .elseif cmd = $7f
        .byte   .hibyte(osbyte_7f - 1)
        .elseif cmd = $7e
        .byte   .hibyte(osbyte_noop - 1)
        .elseif cmd = $83
        .byte   .hibyte(osbyte_83 - 1)
        .elseif cmd = $84
        .byte   .hibyte(osbyte_84 - 1)
        .elseif cmd = $80
        .byte   .hibyte(osbyte_80 - 1)
        .elseif cmd = $91
        .byte   .hibyte(osbyte_91 - 1)
        .elseif cmd = $a8
        .byte   .hibyte(osbyte_a8 - 1)
        .elseif cmd = $8f
        .byte   .hibyte(osbyte_8f - 1)
        .elseif cmd = $ea
        .byte   .hibyte(osbyte_ea - 1)
        .elseif cmd = $ec
        .byte   .hibyte(osbyte_ec - 1)
        .elseif cmd = $fd
        .byte   .hibyte(osbyte_fd - 1)
        .else
        .byte   .hibyte(osbyte_unimplemented - 1)
        .endif
.endrepeat

; OSBYTE $80 — check RS423 buffer (X=$FE, Y=$FF); returns count in X.
; Default: always returns 0 (no data).
osbyte_80:
        cpx     #$FE
        bne     @done
        ldx     #$00
@done:
        rts

; OSBYTE $91 — read RS423 (X=1, Y=0); character in Y, C clear on success.
; Default: always returns SEC (no character).
osbyte_91:
        cpx     #$01
        bne     @no_char
        sec
        rts
@no_char:
        sec
        rts

; OSBYTE $7F — read EOF status. X = handle on entry; return X = $FF at EOF
; else 0. Delegates to the file mock so it tracks the same file state.
osbyte_7f:
        jmp     file_mock_eof_status

; OSBYTE $83 — OSHWM (top of user memory); YX = address.
osbyte_83:
        ldx     #$00
        ldy     #$19
        rts

; OSBYTE $84 — HIMEM; YX = address.
osbyte_84:
        ldx     #$00
        ldy     #$80
        rts

; AUG: A preserved, X bit7 set if CTRL pressed, Y undefined
osbyte_76:
        pha
        lda     osbyte_76_fake_keyboard
        and     #$80
        tax
        iny
        pla
        rts

; Issue paged ROM service request
osbyte_8f:
        stx     osbyte_8f_claim_type
        bcc     @do_sec
        clc
        bcc     @after_swap
@do_sec:
        sec
@after_swap:
        txa
        ldx     #$0E
        jmp     $8003

; AUG: A preserved, C undefined. X = $9F, Y = $0D for OS 1.2
osbyte_a8:
        ldx     #$9F
        ldy     #$0D
        rts

; tube check — return 00 in X to say no tube
osbyte_ea:
        ldx     #$00
        rts

; read hard/soft break
osbyte_fd:
        ldx     osbyte_break_type
        rts
