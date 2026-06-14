/*
 * test_console.c - tests console output functions on the real BBC MOS.
 *
 * Exercises cputc, cputs, gotoxy and textcolor, all of which reach the screen
 * via OSWRCH. clrscr() first so the only thing on screen is this program's
 * output (the *RUN command echo is wiped), which keeps the screen assertions
 * unambiguous.
 *
 * Expected screen layout (MODE 7):
 *   row 0:  ABC
 *   row 5:  POSITION   (placed by gotoxy(0, 5))
 *   row 6:  COLOUROK   (after textcolor(1))
 */
#include <conio.h>

int main(void) {
    clrscr();

    cputc('A');
    cputc('B');
    cputc('C');

    gotoxy(0, 5);
    cputs("POSITION");

    textcolor(1);
    gotoxy(0, 6);
    cputs("COLOUROK\r\n");

    return 0;
}
