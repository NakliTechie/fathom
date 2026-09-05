/* uart_puts.c — freestanding RV32I, -O0, no libc */
#define UART_TX ((volatile unsigned char *)0x10000000)

static void uart_putc(char c) { *UART_TX = (unsigned char)c; }

static void uart_puts(const char *s) {
    while (*s) { uart_putc(*s); s++; }
}

void _start(void) {
    uart_puts("hi\n");
    for (;;) { }
}
