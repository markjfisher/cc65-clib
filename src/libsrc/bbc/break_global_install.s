; brk_global_install.s — optional global catch-all installer (production chain)
        .export         _install_brk_handler_global
        .export         _uninstall_brk_handler_global

        .import         BRKV
        .import         brkhandler
        .import         bh_oldbrkv, bh_installed, bh_brkret
        .import         bh_mode, bh_dbg_entry

.code

_install_brk_handler_global:
        php
        sei
        lda     bh_installed
        bne     @done           ; already installed
        ; save current BRKV
        lda     BRKV
        sta     bh_oldbrkv
        lda     BRKV+1
        sta     bh_oldbrkv+1
        ; install our RAM handler
        lda     #<brkhandler
        sta     BRKV
        lda     #>brkhandler
        sta     BRKV+1
        lda     #1
        sta     bh_installed
@done:
        ; this also restores the interrupt flag, so we don't need CLI, and in fact should not call it.
        plp
        rts

_uninstall_brk_handler_global:
        php
        sei

        ; Clear debug knobs
        lda     #$00
        sta     bh_dbg_entry
        sta     bh_dbg_entry+1
        sta     bh_mode

        ; Also clear any lingering arm (important if app re-enters later)
        sta     bh_brkret
        sta     bh_brkret+1

        ; Restore BRKV if we installed it
        lda     bh_installed
        beq     @done
        lda     bh_oldbrkv
        sta     BRKV
        lda     bh_oldbrkv+1
        sta     BRKV+1
        lda     #$00
        sta     bh_installed
@done:
        plp
        rts
