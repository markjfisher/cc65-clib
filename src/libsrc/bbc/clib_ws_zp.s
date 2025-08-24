; --- ZP pointers reserved for CLIB ---
.segment "CLIBZP"
        .exportzp clib_ws, clib_jptr
clib_ws:    .res 2      ; -> workspace in RAM
clib_jptr:  .res 2      ; scratch for jmp (ptr)
