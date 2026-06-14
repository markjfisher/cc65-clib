; Real test for preservezp / restorezp.
;
; preservezp saves the cc65 zero-page scratch area onto the C stack; restorezp
; copies it back. Verify behaviourally: seed a known value into a cc65 ZP
; location (ptr1), preserve, clobber it, restore, and confirm it came back.

.export _test_func
.export _test_result

.import preservezp
.import restorezp
.importzp ptr1

.segment "CODE"

_test_result:
.res 4

.code
_test_func:
        lda     #$AA
        sta     ptr1            ; seed a known ZP value

        jsr     preservezp

        lda     #$55
        sta     ptr1            ; clobber it while "preserved"
        sta     _test_result + 1  ; record the clobbered value ($55)

        jsr     restorezp

        lda     ptr1            ; should be restored to $AA
        sta     _test_result + 0

        lda     #1
        sta     _test_result + 2
        rts
