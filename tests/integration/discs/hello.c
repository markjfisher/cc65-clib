/*
 * hello.c — minimal cc65 bbc test program
 * Prints "HELLO" to the screen using cputc.
 * Used as the base integration test for beebium.
 */
#include <conio.h>

int main(void) {
    clrscr();
    cputs("HELLO");
    return 0;
}