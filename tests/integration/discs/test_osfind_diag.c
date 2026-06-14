#include <conio.h>

unsigned char __fastcall__ osfind(unsigned char mode, const char* name);

static const char cr_name[] = "EXIST\r";

int main(void) {
    unsigned char h;

    clrscr();
    cputs("F0\r\n");
    h = osfind(0x40, cr_name);
    cprintf("H=%u\r\n", h);
    return 0;
}
