#include <stddef.h>

void *memset(void *str, int c, size_t num)
{
    unsigned char *ptr = (unsigned char *)str;
    const unsigned char ch = c;

    while(num--)
        *ptr++ = ch;

    return str;
}
