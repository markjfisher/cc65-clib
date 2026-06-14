/*
 * test_break.c - tests the BBC BRK handler via set_brk_ret / disarm_brk_ret.
 *
 * set_brk_ret() has setjmp/longjmp semantics:
 *   - it returns 0 the first time (the handler is now "armed");
 *   - when a subsequent non-ESC BRK fires, the handler long-jumps back to the
 *     set_brk_ret() call site, which then "returns" a second time with 1.
 *
 * cause_brk_func() (brk_helper.s) executes a BRK with a non-ESC error number,
 * so the expected sequence is:
 *   ARMED    (first return, r == 0)
 *   CAUGHT   (second return via the BRK long-jump, r == 1)
 *
 * If the handler did not catch the BRK the language's own BRK handler would
 * abort the program with an error message and neither CAUGHT nor the trailing
 * marker would appear.
 */
#include <conio.h>

extern unsigned char __fastcall__ set_brk_ret(void);
extern void          __fastcall__ disarm_brk_ret(void);
extern void          cause_brk_func(void);

int main(void) {
    unsigned char r;

    clrscr();

    r = set_brk_ret();
    if (r == 0) {
        cputs("ARMED\r\n");
        cause_brk_func();      /* BRK -> long-jumps back into set_brk_ret() */
        cputs("NOTRAP\r\n");   /* should never be reached */
        return 1;
    }

    /* Second return: we arrived here via the BRK long-jump (r == 1). */
    cputs("CAUGHT\r\n");
    disarm_brk_ret();
    cputs("DONE\r\n");
    return 0;
}
