/* Behavioral coverage for BBC open() support of O_CREAT/O_TRUNC/O_APPEND/O_EXCL. */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

static volatile unsigned char* const file_buf = (unsigned char*) 0x0900;
static volatile unsigned char* const file_len = (unsigned char*) 0x0A00;
static volatile unsigned char* const file_ptr = (unsigned char*) 0x0A01;
static volatile unsigned char* const file_open = (unsigned char*) 0x0A02;
static volatile unsigned char* const file_hvar = (unsigned char*) 0x0A03;
static volatile unsigned char* const file_ctrl = (unsigned char*) 0x0A04;
static volatile unsigned char* const file_exists = (unsigned char*) 0x0A05;
static volatile unsigned char* const last_open_mode = (unsigned char*) 0x0A10;

unsigned char test_result[24];

int main(void) { return 0; }

static void set_exists(unsigned char exists) {
    *file_ctrl = 1;
    *file_exists = exists;
    *file_hvar = 0x11;
    *file_ptr = 0;
    *file_open = 0;
}

void test_func(void) {
    int fd;
    char ch;

    set_exists(0);
    fd = open("MISS", O_WRONLY);
    test_result[0] = (fd < 0) ? 1 : 0;
    test_result[1] = (unsigned char)__errno;

    set_exists(0);
    *file_len = 9;
    fd = open("NEW", O_WRONLY | O_CREAT);
    test_result[2] = (unsigned char)fd;
    test_result[3] = (unsigned char)__errno;
    test_result[4] = *file_exists;
    test_result[5] = *file_len;
    test_result[6] = *last_open_mode;
    if (fd >= 0) {
        close(fd);
    }

    set_exists(1);
    file_buf[0] = 'A';
    file_buf[1] = 'B';
    *file_len = 2;
    fd = open("APP", O_WRONLY | O_APPEND);
    if (fd >= 0) {
        write(fd, "CD", 2);
        close(fd);
    }
    test_result[7] = (fd >= 0) ? 1 : 0;
    test_result[8] = *file_len;
    test_result[9] = file_buf[0];
    test_result[10] = file_buf[1];
    test_result[11] = file_buf[2];
    test_result[12] = file_buf[3];

    set_exists(1);
    file_buf[0] = 'X';
    file_buf[1] = 'Y';
    file_buf[2] = 'Z';
    *file_len = 3;
    fd = open("TRN", O_RDWR | O_TRUNC);
    test_result[13] = (fd >= 0) ? 1 : 0;
    test_result[14] = *file_len;
    test_result[15] = *last_open_mode;
    if (fd >= 0) {
        close(fd);
    }

    set_exists(1);
    fd = open("OLD", O_WRONLY | O_CREAT | O_EXCL);
    test_result[16] = (fd < 0) ? 1 : 0;
    test_result[17] = (unsigned char)__errno;

    set_exists(0);
    fd = open("RW", O_WRONLY | O_CREAT | O_EXCL);
    test_result[20] = *last_open_mode;
    if (fd >= 0) {
        write(fd, "Z", 1);
        close(fd);
    } else {
        ch = 0;
    }
    test_result[18] = (fd >= 0) ? 1 : 0;
    test_result[19] = *file_exists;

    set_exists(1);
    fd = open("BAD", O_RDONLY | O_TRUNC);
    test_result[21] = (fd < 0) ? 1 : 0;
    test_result[22] = (unsigned char)__errno;
    test_result[23] = 1;
}
