; file_mock.s — in-memory file system mock for the soft65c02 test harness.
;
; Implements OSFIND / OSBGET / OSBPUT / OSARGS so the cc65 bbc file I/O layer
; (osfind, open, read, write, close, lseek) can be exercised without a real
; filing system. OSBYTE &7F (read EOF status) lives in osbyte_stub.s and reads
; the same state.
;
; Deliberately models a SINGLE file (DFS-style small files are enough for unit
; tests). Tests drive it through fixed-address state in low RAM:
;
;   FILE_BUF    ($0900, 256 bytes)  file contents
;   FILE_LEN    ($0A00)             current length (bytes)
;   FILE_PTR    ($0A01)             read/write position
;   FILE_OPEN   ($0A02)             0 = closed, 1 = read, 2 = write, 3 = update
;   FILE_HVAR   ($0A03)             handle OSFIND hands out for a successful
;                                   open; if 0, OSFIND reports "not found"
;
; A test sets FILE_BUF/FILE_LEN (and FILE_HVAR, default $11) before running,
; then inspects FILE_BUF/FILE_LEN/FILE_PTR afterwards.
;
; Real BBC OSFIND returns the file handle in A (this is exactly the contract
; the osfind.s wrapper must honour — the regression this mock guards).

        .export h_osfind_entry
        .export h_osbget_entry
        .export h_osbput_entry
        .export h_osargs_entry
        .export file_mock_eof_status
        .importzp ptr1

        .segment "CODE"

FILE_BUF   = $0900
FILE_LEN   = $0A00
FILE_PTR   = $0A01
FILE_OPEN  = $0A02
FILE_HVAR  = $0A03

fm_tmp     = $0A04          ; scratch (not in cc65 / MOS ZP)
LAST_OPEN_MODE = $0A10
LAST_OPEN_PTR  = $0A11
LAST_OPEN_NAME = $0A20

; ---------------------------------------------------------------------------
; OSFIND — A selects the operation; X/Y point at a CR-terminated name (open).
;   A=$00 close, A=$40 input, A=$80 output, A=$C0 update.
;   On exit A = handle (0 = open failed / not found).
; ---------------------------------------------------------------------------
h_osfind_entry:
        sta     LAST_OPEN_MODE
        cmp     #$00
        beq     @close

        stx     LAST_OPEN_PTR
        sty     LAST_OPEN_PTR+1
        stx     ptr1
        sty     ptr1+1
        ldy     #$00
@copy_name:
        lda     (ptr1),y
        sta     LAST_OPEN_NAME,y
        cmp     #$0D
        beq     @dispatch
        iny
        cpy     #127
        bcc     @copy_name
        lda     #$0D
        sta     LAST_OPEN_NAME+127

@dispatch:
        lda     LAST_OPEN_MODE
        cmp     #$80
        beq     @output
        cmp     #$C0
        beq     @update
        ; default: open for input ($40)
        lda     FILE_HVAR
        beq     @done           ; handle 0 => "not found", return A=0
        lda     #$00
        sta     FILE_PTR
        lda     #$01
        sta     FILE_OPEN
        lda     FILE_HVAR
        rts

@output:
        lda     FILE_HVAR
        beq     @done
        lda     #$00
        sta     FILE_PTR
        sta     FILE_LEN        ; truncate on open-for-write
        lda     #$02
        sta     FILE_OPEN
        lda     FILE_HVAR
        rts

@update:
        lda     FILE_HVAR
        beq     @done
        lda     #$00
        sta     FILE_PTR
        lda     #$03
        sta     FILE_OPEN
        lda     FILE_HVAR
        rts

@close:
        ; Y = handle (0 closes all); just mark closed.
        lda     #$00
        sta     FILE_OPEN
@done:
        rts

; ---------------------------------------------------------------------------
; OSBGET — Y = handle. Returns A = byte, C clear; or C set at EOF.
; ---------------------------------------------------------------------------
h_osbget_entry:
        ldx     FILE_PTR
        cpx     FILE_LEN
        bcs     @eof            ; PTR >= LEN -> end of file
        lda     FILE_BUF, x
        inc     FILE_PTR
        clc
        rts
@eof:
        lda     #$FE            ; arbitrary; carry indicates EOF
        sec
        rts

; ---------------------------------------------------------------------------
; OSBPUT — Y = handle, A = byte. Writes at PTR, extends LEN as needed.
; ---------------------------------------------------------------------------
h_osbput_entry:
        ldx     FILE_PTR
        sta     FILE_BUF, x
        inc     FILE_PTR
        ; if PTR > LEN, LEN = PTR
        lda     FILE_PTR
        cmp     FILE_LEN
        bcc     @ok
        sta     FILE_LEN
@ok:
        rts

; ---------------------------------------------------------------------------
; OSARGS — A = action, X = zero-page address of a 4-byte control block,
;          Y = handle. Supports the subset lseek uses:
;            A=$00 read PTR, A=$01 write PTR, A=$02 read EXT(length).
;          Files are <=256 bytes, so only the low byte is significant.
; ---------------------------------------------------------------------------
h_osargs_entry:
        cmp     #$01
        beq     @write_ptr
        cmp     #$02
        beq     @read_ext
        ; A=$00 read PTR
        lda     FILE_PTR
        jmp     @store_block
@read_ext:
        lda     FILE_LEN
@store_block:
        ; write A into zp[X], zero zp[X+1..X+3]
        sta     $00, x
        lda     #$00
        sta     $01, x
        sta     $02, x
        sta     $03, x
        rts
@write_ptr:
        lda     $00, x          ; low byte of requested PTR
        sta     FILE_PTR
        rts

; ---------------------------------------------------------------------------
; Helper used by osbyte_stub's OSBYTE &7F: returns X = $FF at EOF else $00.
; ---------------------------------------------------------------------------
file_mock_eof_status:
        ldx     FILE_PTR
        cpx     FILE_LEN
        bcc     @noteof
        ldx     #$FF
        rts
@noteof:
        ldx     #$00
        rts
