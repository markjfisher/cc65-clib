/* End-to-end lseek() through the file mock: a deferred seek (SEEK_SET/CUR/END)
 * is applied on the next read() via __seekcheck -> OSARGS write-PTR. The mock
 * file holds "ABCDE". */
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

unsigned char test_result[8];

int main(void) { return 0; }  /* unused: resolves the C runtime callmain ref */

void test_func(void) {
    int fd;
    char buf[2];
    off_t pos;

    fd = open("F", O_RDONLY);
    test_result[0] = (fd >= 0) ? 1 : 0;

    pos = lseek(fd, 2, SEEK_SET);     /* -> position 2 */
    test_result[1] = (unsigned char)pos;
    read(fd, buf, 1);
    test_result[2] = buf[0];           /* 'C' */

    pos = lseek(fd, 0, SEEK_SET);     /* back to start */
    test_result[3] = (unsigned char)pos;
    read(fd, buf, 1);
    test_result[4] = buf[0];           /* 'A' */

    pos = lseek(fd, 0, SEEK_END);     /* end -> 5 */
    test_result[5] = (unsigned char)pos;

    close(fd);
    test_result[6] = 1;
}
