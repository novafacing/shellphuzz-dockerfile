#include <stdio.h>
#include <stdlib.h>

int main() {
    int buf[8];
    fread(buf, sizeof(int), 8, stdin);
    for (int i = 2; i < 8; i++) {
        if (buf[i] != buf[i - 1] + buf[i - 2]) {
            return 1;
        }
    }
    // crash
    *(char *)NULL = 1;
}
