/* Verifies the current BBC _systime() decoding via the OSWORD &0E stub. */
#include <time.h>

static volatile unsigned char* const mock_clock = (unsigned char*) 0x0AB0;

unsigned char test_result[9];

time_t _systime(void);

int main(void) { return 0; }

static void store_time(unsigned char offset, time_t value) {
    unsigned long raw = (unsigned long) value;
    test_result[offset + 0] = (unsigned char)(raw & 0xFF);
    test_result[offset + 1] = (unsigned char)((raw >> 8) & 0xFF);
    test_result[offset + 2] = (unsigned char)((raw >> 16) & 0xFF);
    test_result[offset + 3] = (unsigned char)((raw >> 24) & 0xFF);
}

void test_func(void) {
    mock_clock[0] = 0x69;
    mock_clock[1] = 0x01;
    mock_clock[2] = 0x02;
    mock_clock[3] = 0x00;
    mock_clock[4] = 0x03;
    mock_clock[5] = 0x04;
    mock_clock[6] = 0x05;
    store_time(0, _systime());

    mock_clock[0] = 0x75;
    mock_clock[1] = 0x12;
    mock_clock[2] = 0x31;
    mock_clock[3] = 0x00;
    mock_clock[4] = 0x23;
    mock_clock[5] = 0x58;
    mock_clock[6] = 0x59;
    store_time(4, _systime());

    test_result[8] = 1;
}
