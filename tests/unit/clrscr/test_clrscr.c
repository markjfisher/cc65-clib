/*
 * gotoxy/clrscr/wherex/wherey unit test for cc65 bbc library.
 * These functions make OSWRCH/VDU calls - verify they don't crash.
 */
#include <conio.h>

unsigned char test_result[16];

void test_func(void) {
    unsigned char i;

    for (i = 0; i < 16; i++) test_result[i] = 0;

    /* cursor positioning */
    gotoxy(10, 5);

    /* screen clear */
    clrscr();

    /* read cursor positions */
    test_result[0] = wherex();
    test_result[1] = wherey();

    /* single-line clear */
    cclear(20);

    /* horizontal/vertical lines */
    chline(15);
    cvline(8);

    test_result[2] = 1;
}