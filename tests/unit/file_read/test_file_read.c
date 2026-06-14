/* Exercises open()/read()/close() end-to-end through the harness file mock.
 * The mock serves FILE_BUF ($0900) of length FILE_LEN ($0A00) and hands out
 * handle FILE_HVAR ($0A03). This catches the OSFIND A-vs-Y regression at the
 * full stdio/POSIX layer (a bogus handle made read() fail/loop). */
#include <fcntl.h>
#include <unistd.h>

unsigned char test_result[8];

int main(void) { return 0; }  /* unused: resolves the C runtime callmain ref */

void test_func(void) {
    int fd, n;
    char buf[8];

    fd = open("F", O_RDONLY);
    test_result[0] = (fd >= 0) ? 1 : 0;      /* open succeeded */

    n = read(fd, buf, 8);
    test_result[1] = (unsigned char)n;        /* bytes read = file length (2) */
    test_result[2] = buf[0];                  /* 'H' */
    test_result[3] = buf[1];                  /* 'i' */

    n = read(fd, buf, 8);                      /* now at EOF */
    test_result[4] = (unsigned char)n;        /* 0 bytes */

    close(fd);
    test_result[5] = 1;                        /* completed */
}
