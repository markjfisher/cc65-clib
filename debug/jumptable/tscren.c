/*
 * test_screen.c - tests cursor positioning and vertical scrolling.
 *
 * Prints five numbered lines from the home position, then uses gotoxy() to
 * jump down and print a marker. clrscr() first so the *RUN command echo does
 * not interfere with the screen assertions.
 *
 * Expected (MODE 7):
 *   rows 0..4:  "0: LINE" .. "4: LINE"
 *   row 10:     "MODE7OK"   (placed by gotoxy(0, 10))
 */
#include <conio.h>

int main(void) {
    unsigned char i;

    clrscr();

    for (i = 0; i < 5; i++) {
        cputc('0' + i);
        cputs(": LINE\r\n");
    }

    gotoxy(0, 10);
    cputs("MODE7OK\r\n");

    return 0;
}
