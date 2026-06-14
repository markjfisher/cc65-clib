        .include "clib_imports.inc"

        .segment "HEADER"

rom_header:
        .byte   $00, $00, $00           ; language entry
        jmp     clib_svc                ; service
        .byte   $82                     ; rom type: service ROM, 6502 code

        .byte   <(clib_copyright)

        .byte   $01                     ; version

clib_rom_tite:
        .byte   "cc65 CLIB"

clib_vers_str:
        .byte   0, "0.01"

clib_copyright:
        .byte   0,"(C) Copyright Mark Fisher 2026",0                

        ; Fixed-address jump table (vectoring layer). clib_imports_jmp.inc contains
        ; one `jmp <function>` per slot, in jumptable.def order, and is placed in the
        ; JUMPTABLE segment so the slots live at a stable base ($8100) independent of
        ; where the real function bodies end up.
        .segment "JUMPTABLE"
        .include "clib_imports_jmp.inc"

        .code
clib_svc:
        rts