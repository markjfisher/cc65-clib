; Real test for the OSFIND wrapper (_osfind).
;
; _osfind(mode, name) must return the file handle that MOS leaves in A.
; A regression long lived here because the wrapper used to read the handle
; from Y (the name-pointer high byte), so fopen()/open() got a bogus non-zero
; handle and every later OSBGET/OSBPUT failed with DFS "Channel".
;
; The harness file mock returns the handle in FILE_HVAR ($0A03) on a
; successful open, or 0 when FILE_HVAR is 0 (simulating "file not found").

.export _test_func
.export _test_result

.import _osfind
.import pusha

.segment "CODE"

_test_result:
.res 3

.rodata
fname:  .byte "F", $0D

.code
_test_func:
        ; result[0] = osfind($40 read, fname) -- expect the handle ($11)
        lda     #$40
        jsr     pusha               ; push mode
        lda     #<fname
        ldx     #>fname
        jsr     _osfind
        sta     _test_result + 0    ; handle in A

        ; result[1] = high byte of the 16-bit return (should be 0)
        stx     _test_result + 1

        lda     #1
        sta     _test_result + 2
        rts
