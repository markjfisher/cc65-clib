; MOS vectors table at $FFB9..$FFF9.
; Maps every BBC MOS entry point to the harness stub.
; OSWRCH redirects to print_mock; OSBYTE redirects to osbyte_stub;
; all other vectors hit a brk (unimplemented).

        .segment "MOS_VECTORS"

.import h_osbyte_entry
.import h_oswrch_entry
.import h_unknown_entry
.import h_osrdch_entry
.import h_osfind_entry
.import h_osbget_entry
.import h_osbput_entry
.import h_osargs_entry
.import h_osword_entry

osrdrm_vector:  jmp h_unknown_entry
                jmp h_unknown_entry
oseven_vector:  jmp h_unknown_entry
gsinit_vector:  jmp h_unknown_entry
gsread_vector:  jmp h_unknown_entry
nvwrch_vector:  jmp h_unknown_entry
nvrdch_vector:  jmp h_unknown_entry
osfind_vector:  jmp h_osfind_entry
osgbpb_vector:  jmp h_unknown_entry
osbput_vector:  jmp h_osbput_entry
osbget_vector:  jmp h_osbget_entry
osargs_vector:  jmp h_osargs_entry
osfile_vector:  jmp h_unknown_entry
osrdch_vector:  jmp h_osrdch_entry
osasci_vector:  cmp #$0d
                bne oswrch_vector
osnewl_vector:  lda #$0a
                jsr oswrch_vector
                lda #$0d
oswrch_vector:  jmp h_oswrch_entry
osword_vector:  jmp h_osword_entry
osbyte_vector:  jmp h_osbyte_entry
oscli_vector:   jmp h_unknown_entry
