; strncpy(dst, src, n) - the one string function the legacy test-c-comprehensive
; covered that the unit suite did not. Verifies both behaviours:
;   - src shorter than n  -> remaining bytes of dst are NUL-padded
;   - src length >= n      -> exactly n bytes copied, NO NUL terminator added

.export _test_func
.export _test_result

.import _strncpy
.import pushax

.segment "CODE"

_test_result:
.res 8

.rodata
_src_hi:    .byte "Hi", 0
_src_world: .byte "World", 0

.bss
_dstA: .res 8
_dstB: .res 8

.code
_test_func:
        ; Pre-fill both destinations with $AA so we can tell padded NULs and
        ; untouched bytes apart.
        ldx     #7
        lda     #$AA
fill:
        sta     _dstA, x
        sta     _dstB, x
        dex
        bpl     fill

        ; Test A: strncpy(dstA, "Hi", 5) -> 'H','i',0,0,0
        lda     #<_dstA
        ldx     #>_dstA
        jsr     pushax
        lda     #<_src_hi
        ldx     #>_src_hi
        jsr     pushax
        lda     #5
        ldx     #0
        jsr     _strncpy
        lda     _dstA + 0
        sta     _test_result + 0        ; 'H'
        lda     _dstA + 1
        sta     _test_result + 1        ; 'i'
        lda     _dstA + 2
        sta     _test_result + 2        ; 0 (terminator within n)
        lda     _dstA + 4
        sta     _test_result + 3        ; 0 (NUL padding)

        ; Test B: strncpy(dstB, "World", 3) -> 'W','o','r', dstB[3] untouched
        lda     #<_dstB
        ldx     #>_dstB
        jsr     pushax
        lda     #<_src_world
        ldx     #>_src_world
        jsr     pushax
        lda     #3
        ldx     #0
        jsr     _strncpy
        lda     _dstB + 0
        sta     _test_result + 4        ; 'W'
        lda     _dstB + 2
        sta     _test_result + 5        ; 'r'
        lda     _dstB + 3
        sta     _test_result + 6        ; $AA (no NUL added: src len >= n)

        rts
