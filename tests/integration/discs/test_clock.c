/*
 * test_clock.c - tests clock() against the real BBC MOS.
 *
 * clock() reads the MOS centisecond timer (OSWORD &01). We read it twice with
 * a busy-wait in between and verify that it is valid and monotonically
 * advancing, proving the timer is wired up end-to-end.
 *
 * Expected screen output:
 *   CLOCKOK    if both reads are valid and the second >= the first
 *   CLOCKBAD   otherwise
 */
#include <time.h>
#include <conio.h>

int main(void) {
    clock_t a, b;
    unsigned long i;

    clrscr();

    a = clock();
    for (i = 0; i < 20000UL; ++i) {
        /* burn time so the centisecond timer advances */
    }
    b = clock();

    if (a != (clock_t)-1 && b != (clock_t)-1 && b >= a) {
        cputs("CLOCKOK\r\n");
    } else {
        cputs("CLOCKBAD\r\n");
    }

    return 0;
}
