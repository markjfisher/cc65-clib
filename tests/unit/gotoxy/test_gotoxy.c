/*
 * gotoxy unit test for cc65 bbc library.
 * Tests cursor positioning via VDU control codes.
 */
#include <conio.h>

unsigned char test_result[16];

void test_func(void) {
    unsigned char i;

    for (i = 0; i < 16; i++) test_result[i] = 0;

    /* goto various positions */
    gotox(0);
    gotoy(0);
    test_result[0] = wherex();
    test_result[1] = wherey();

    gotox(20);
    gotoy(10);
    test_result[2] = wherex();
    test_result[3] = wherey();

    /* set text colour - via OSWRCH VDU sequence */
    textcolor(COLOR_RED);
    bordercolor(COLOR_BLUE);

    test_result[4] = 1;
}