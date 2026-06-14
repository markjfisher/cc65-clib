/*
 * test_kbhit.c - tests blocking keyboard input via cgetc() on the real MOS.
 *
 * Prints a prompt, blocks in cgetc() until the test injects a key, then echoes
 * the character back so the test can confirm the exact key was read.
 *
 * Expected screen output (after the test types 'A'):
 *   PRESS
 *   GOT A
 */
#include <conio.h>

int main(void) {
    char ch;

    clrscr();
    cputs("PRESS\r\n");

    ch = cgetc();

    cputs("GOT ");
    cputc(ch);
    cputs("\r\n");

    return 0;
}
