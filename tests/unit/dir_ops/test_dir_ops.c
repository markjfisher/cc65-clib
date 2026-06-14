/* Exercises the BBC opendir()/closedir() fixed DIR pool semantics. */
#include <dirent.h>
#include <errno.h>

#define DIR_USED_OFFSET 13

unsigned char test_result[12];

int main(void) { return 0; }

void test_func(void) {
    DIR* d1;
    DIR* d2;
    DIR* d3;
    DIR* d4;

    d1 = opendir(".");
    d2 = opendir(".");
    d3 = opendir(".");

    test_result[0] = (d1 != 0) ? 1 : 0;
    test_result[1] = (d2 != 0) ? 1 : 0;
    test_result[2] = (d3 == 0) ? 1 : 0;
    test_result[3] = (unsigned char)__errno;
    test_result[4] = (d1 != 0) ? ((unsigned char*) d1)[DIR_USED_OFFSET] : 0;
    test_result[5] = (d2 != 0) ? ((unsigned char*) d2)[DIR_USED_OFFSET] : 0;

    test_result[6] = (unsigned char)closedir(d1);
    test_result[7] = (d1 != 0) ? ((unsigned char*) d1)[DIR_USED_OFFSET] : 0;

    d4 = opendir(".");
    test_result[8] = (d4 != 0) ? 1 : 0;
    test_result[9] = (d4 != 0) ? ((unsigned char*) d4)[DIR_USED_OFFSET] : 0;
    test_result[10] = (d4 == d1) ? 1 : 0;

    test_result[11] = (unsigned char)closedir((DIR*) 0);

    if (d2 != 0) {
        closedir(d2);
    }
    if (d4 != 0) {
        closedir(d4);
    }
}
