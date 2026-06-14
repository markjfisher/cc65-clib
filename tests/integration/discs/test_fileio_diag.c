/* Diagnostic real-DFS file I/O trace for beebium. */
#include <conio.h>
#include <stdio.h>
#include <string.h>

static void mark(const char* s) {
    cputs(s);
    cputs("\r\n");
}

int main(void) {
    FILE* fp;
    char buf[32];
    int n;

    clrscr();
    mark("S0");

    fp = fopen("TSTFILE", "w");
    if (fp == 0) {
        mark("OPEN1FAIL");
        return 1;
    }
    mark("S1");

    n = fwrite("Hello World", 1, 11, fp);
    if (n != 11) {
        mark("WRITEFAIL");
        return 1;
    }
    mark("S2");

    if (fclose(fp) != 0) {
        mark("CLOSE1FAIL");
        return 1;
    }
    mark("S3");

    fp = fopen("TSTFILE", "r");
    if (fp == 0) {
        mark("OPEN2FAIL");
        return 1;
    }
    mark("S4");

    n = fread(buf, 1, sizeof(buf) - 1, fp);
    buf[n] = '\0';
    mark("S5");

    if (fclose(fp) != 0) {
        mark("CLOSE2FAIL");
        return 1;
    }
    mark("S6");

    if (strcmp(buf, "Hello World") == 0) {
        mark("FILEOK");
    } else {
        mark("FILEBAD");
    }

    return 0;
}
