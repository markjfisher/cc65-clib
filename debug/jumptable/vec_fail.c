/*
 * Minimal bbc-clib repro for the jump-table (vectoring) hang.
 *
 * clrscr() and cputs() are LOCAL (built into the app); strlen() is VECTORED
 * (resolved to the fixed jump-table slot in the CLIB ROM, e.g. _strlen := $812D
 * -> jmp <real strlen>). With the jump-table ROM this program prints "BEFORE"
 * and then HANGS at the strlen() call: "AFTER" / the '5' never appear.
 *
 * Build:  cl65 -t bbc-clib --start-addr 0x1900 -Ln vec_fail.lbl -o VECFAIL vec_fail.c
 * Run:    CLIB ROM in a sideways slot, *RUN VECFAIL.
 */
#include <conio.h>
#include <string.h>

int main(void) {
    unsigned n;
    clrscr();
    cputs("BEFORE\r\n");            /* local: prints */
    n = strlen("Hello");           /* VECTORED: jsr $812D -> jmp real strlen */
    cputs("AFTER\r\n");            /* if strlen returned, prints */
    cputc('0' + (char)n);          /* expect '5' */
    cputs("\r\nDONE\r\n");
    return 0;
}
