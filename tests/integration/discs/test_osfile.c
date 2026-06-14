/*
 * test_osfile.c - tests the OSFILE wrappers (osfile_save/read/delete) against
 * real DFS. These call OS_File (&FFDD) and return the object type in A with
 * catalogue info written back through pointers.
 *
 * Sequence: save 5 bytes to OSFDAT, read it back (expect type=1 file, size=5),
 * delete it, read again (expect type=0 not-found).
 *
 * Expected screen output: SAVEOK, READOK, DELOK.
 *
 * NOTE: the OSFILE wrappers are __cdecl__ (all args on the stack); they must
 * be declared as such or the call corrupts the stack.
 */
#include <conio.h>

typedef unsigned long bits32;
typedef unsigned char byte;

extern void __cdecl__ osfile_save(const char *name, bits32 load, bits32 exec,
                                  const byte *data, const byte *end);
extern byte __cdecl__ osfile_read(const char *name, bits32 *load, bits32 *exec,
                                  long *size, bits32 *attr);
extern byte __cdecl__ osfile_delete(const char *name, bits32 *load, bits32 *exec,
                                    long *size, bits32 *attr);

int main(void) {
    static const byte data[5] = { 10, 20, 30, 40, 50 };
    byte t;
    bits32 load, exec, attr;
    long size;

    clrscr();

    osfile_save("OSFDAT", 0x1900UL, 0x1900UL, data, data + 5);
    cputs("SAVEOK\r\n");

    t = osfile_read("OSFDAT", &load, &exec, &size, &attr);
    if (t == 1 && size == 5) {
        cputs("READOK\r\n");
    } else {
        cputs("READBAD\r\n");
    }

    osfile_delete("OSFDAT", &load, &exec, &size, &attr);
    t = osfile_read("OSFDAT", &load, &exec, &size, &attr);
    if (t == 0) {
        cputs("DELOK\r\n");
    } else {
        cputs("DELBAD\r\n");
    }

    return 0;
}
