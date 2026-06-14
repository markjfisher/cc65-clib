/*
 * test_dir.c - tests directory listing via opendir()/readdir()/closedir(),
 * which drive OSGBPB against the real DFS catalogue.
 *
 * The disc (built by build_test_discs.sh) also carries data files ALPHA and
 * BETA, so the listing should include them (plus the program itself, TDIR).
 *
 * Expected screen output: each catalogue entry name on its own line, then END.
 */
#include <stddef.h>
#include <dirent.h>
#include <conio.h>

int main(void) {
    DIR *d;
    struct dirent *e;

    clrscr();

    d = opendir(".");
    if (d == NULL) {
        cputs("NODIR\r\n");
        return 1;
    }

    while ((e = readdir(d)) != NULL) {
        cputs(e->d_name);
        cputs("\r\n");
    }

    closedir(d);
    cputs("END\r\n");
    return 0;
}
