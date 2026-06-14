/*
 * test_fileio.c - tests stdio file I/O (fopen/fwrite/fclose/fread) on real DFS.
 *
 * Writes a short string to a DFS file, reads it back, and compares.
 *
 * Expected screen output:
 *   FILEOK     on a successful write/read round-trip
 *   FILEBAD    if the data read back does not match
 *   OPEN1FAIL / OPEN2FAIL on open failures
 *
 * KNOWN ISSUE: on the current cc65 bbc target this hangs at the first OSBGET/
 * OSBPUT. BASIC disc I/O (OPENOUT/PRINT#/BGET#) works in the same emulated
 * setup, so the fault is in the cc65 bbc read()/write() path, not DFS. The
 * integration test for this is marked xfail until the library is fixed.
 */
#include <stdio.h>
#include <string.h>
#include <conio.h>

int main(void) {
    FILE *fp;
    char buf[32];
    int n;

    clrscr();

    fp = fopen("TSTFILE", "w");
    if (fp == NULL) {
        cputs("OPEN1FAIL\r\n");
        return 1;
    }
    fwrite("Hello World", 1, 11, fp);
    fclose(fp);

    fp = fopen("TSTFILE", "r");
    if (fp == NULL) {
        cputs("OPEN2FAIL\r\n");
        return 1;
    }
    n = fread(buf, 1, sizeof(buf) - 1, fp);
    buf[n] = '\0';
    fclose(fp);

    if (strcmp(buf, "Hello World") == 0) {
        cputs("FILEOK\r\n");
    } else {
        cputs("FILEBAD\r\n");
    }

    return 0;
}
