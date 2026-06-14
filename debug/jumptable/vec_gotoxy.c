#include <conio.h>
int main(void){
    clrscr();
    cputs("A\r\n");        /* local */
    gotoxy(0, 5);          /* ROM-resident */
    cputs("HERE\r\n");
    cputs("DONE\r\n");
    return 0;
}
