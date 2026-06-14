/* Diagnostic direct open/write/read path on real DFS. */
#include <conio.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

static void mark(const char* s) {
    cputs(s);
    cputs("\r\n");
}

int main(void) {
    int fd;
    char buf[32];
    int n;

    clrscr();
    mark("W0");

    fd = open("TSYS", O_WRONLY | O_CREAT | O_TRUNC);
    if (fd < 0) {
        mark("WOPENFAIL");
        return 1;
    }
    mark("W1");

    n = write(fd, "Hello World", 11);
    if (n != 11) {
        mark("WWRITEFAIL");
        return 1;
    }
    mark("W2");

    if (close(fd) != 0) {
        mark("WCLOSEFAIL");
        return 1;
    }
    mark("W3");

    fd = open("TSYS", O_RDONLY);
    if (fd < 0) {
        mark("ROPENFAIL");
        return 1;
    }
    mark("R1");

    n = read(fd, buf, sizeof(buf) - 1);
    if (n < 0) {
        mark("RREADFAIL");
        return 1;
    }
    buf[n] = '\0';
    mark("R2");

    if (close(fd) != 0) {
        mark("RCLOSEFAIL");
        return 1;
    }
    mark("R3");

    if (strcmp(buf, "Hello World") == 0) {
        mark("SYSOK");
    } else {
        mark("SYSBAD");
    }

    return 0;
}
