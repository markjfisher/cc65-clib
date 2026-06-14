/*
 * abs/labs unit test for cc65 bbc library.
 */
#include <stdlib.h>

unsigned char test_result[16];

void test_func(void) {
    /* abs: positive */
    test_result[0] = (unsigned char)abs(42);

    /* abs: negative */
    test_result[1] = (unsigned char)abs(-42);

    /* abs: zero */
    test_result[2] = (unsigned char)abs(0);

    /* abs: max negative (implementation-defined, but should not crash) */
    test_result[3] = (unsigned char)abs(-128);

    /* labs: positive long */
    test_result[4] = (unsigned char)labs(12345L);

    /* labs: negative long */
    test_result[5] = (unsigned char)labs(-98765L);

    /* labs: zero */
    test_result[6] = (unsigned char)labs(0L);
}