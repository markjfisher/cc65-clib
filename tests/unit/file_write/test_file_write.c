/* Exercises open(O_WRONLY)/write()/close() through the harness file mock.
 * After running, the mock's FILE_BUF ($0900) holds the written bytes and
 * FILE_LEN ($0A00) the count, which the test script asserts directly. */
#include <fcntl.h>
#include <unistd.h>

unsigned char test_result[8];

int main(void) { return 0; }  /* unused: resolves the C runtime callmain ref */

void test_func(void) {
    int fd, n;

    fd = open("F", O_WRONLY);
    test_result[0] = (fd >= 0) ? 1 : 0;

    n = write(fd, "ABC", 3);
    test_result[1] = (unsigned char)n;        /* 3 bytes written */

    close(fd);
    test_result[2] = 1;
}
