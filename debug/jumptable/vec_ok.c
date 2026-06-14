/*
 * Contrast case that (in testing) WORKED: a direct ROM call (cputc, which is
 * ROM-resident) is made BEFORE the vectored strlen() call. Prints "ROM" then
 * "L5". Useful to compare against vec_fail.c when step-debugging.
 */
#include <conio.h>
#include <string.h>

int main(void) {
    unsigned n;
    clrscr();
    cputc('R'); cputc('O'); cputc('M'); cputc('\r'); cputc('\n');  /* ROM-direct */
    n = strlen("Hello");           /* VECTORED */
    cputc('L'); cputc('0' + (char)n);
    return 0;
}
