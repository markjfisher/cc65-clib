/* Diagnostic write path against a pre-existing DFS file. */
#include <conio.h>
#include <fcntl.h>
#include <unistd.h>

static void mark(const char* s) {
    cputs(s);
    cputs("\r\n");
}

int main(void) {
    int fd;
    int n;

    clrscr();
    mark("E0");

    fd = open("EXIST", O_WRONLY);
    if (fd < 0) {
        mark("EOPENFAIL");
        return 1;
    }
    mark("E1");

    n = write(fd, "Z", 1);
    if (n != 1) {
        mark("EWRITEFAIL");
        return 1;
    }
    mark("E2");

    if (close(fd) != 0) {
        mark("ECLOSEFAIL");
        return 1;
    }
    mark("EOK");
    return 0;
}
