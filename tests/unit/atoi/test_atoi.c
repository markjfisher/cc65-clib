/*
 * atoi/atol unit test for cc65 bbc library.
 */
#include <stdlib.h>

unsigned char test_result[16];
char buf[16];

void test_func(void) {
    unsigned char i;

    for (i = 0; i < 16; i++) buf[i] = 0;

    /* atoi: positive number */
    test_result[0] = (unsigned char)atoi("123");

    /* atoi: negative number */
    test_result[1] = (unsigned char)atoi("-42");

    /* atoi: zero */
    test_result[2] = (unsigned char)atoi("0");

    /* atoi: leading whitespace (should be rejected or return 0) */
    test_result[3] = (unsigned char)atoi("  5");

    /* atoi: non-numeric */
    test_result[4] = (unsigned char)atoi("abc");

    /* atol: positive long */
    test_result[5] = (unsigned char)atol("65535");

    /* atol: negative long */
    test_result[6] = (unsigned char)atol("-999");
}