/* sum.c — freestanding RV32I, -O0, no libc. Program 4, TU 1 of 2.
   Calls into a second translation unit and writes the result. Exists to prove
   join 1 across compile units: two DWARF line tables, two file tables. */
#define UART_TX ((volatile unsigned char *)0x10000000)

extern int sum_to(int n);

void fathom_main(void) {
    int s = sum_to(4);                 /* 0+1+2+3+4 = 10 */
    int tens = 0;
    while (s >= 10) { s -= 10; tens++; }   /* no M extension: no divide */
    *UART_TX = (unsigned char)('0' + tens);
    *UART_TX = (unsigned char)('0' + s);
    for (;;) { }
}
