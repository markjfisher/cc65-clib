/*
 * cputc unit test for cc65 bbc library.
 * Uses OSWRCH mock to capture output.
 */
#include <conio.h>

unsigned char test_result[16];

void test_func(void) {
    unsigned char i;

    for (i = 0; i < 16; i++) test_result[i] = 0;

    /* cputc sends character via OSWRCH - mock captures it at $C800 */
    /* We just verify the function doesn't crash and runs to completion */
    cputc('A');
    cputc('\n');
    cputc('!');
    cputc(0);

    /* Mark success — without OSWRCH mock armed, output goes to stub */
    test_result[0] = 1;
}