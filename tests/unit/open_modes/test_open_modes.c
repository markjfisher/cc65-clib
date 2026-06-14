/* Verifies BBC open() mode mapping and filename copy/truncation behaviour. */
#include <fcntl.h>
#include <unistd.h>

static volatile unsigned char* const last_open_mode = (unsigned char*) 0x0A10;
static volatile unsigned char* const last_open_name = (unsigned char*) 0x0A20;

unsigned char test_result[8];

static const char long_name[] =
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AA";

int main(void) { return 0; }

void test_func(void) {
    int fd;

    fd = open("R", O_RDONLY);
    test_result[0] = *last_open_mode;
    test_result[1] = (fd >= 0) ? 1 : 0;
    if (fd >= 0) {
        close(fd);
    }

    fd = open("W", O_WRONLY);
    test_result[2] = *last_open_mode;
    test_result[3] = (fd >= 0) ? 1 : 0;
    if (fd >= 0) {
        close(fd);
    }

    fd = open(long_name, O_RDWR);
    test_result[4] = *last_open_mode;
    test_result[5] = (fd >= 0) ? 1 : 0;
    test_result[6] = last_open_name[126];
    test_result[7] = last_open_name[127];
    if (fd >= 0) {
        close(fd);
    }
}
