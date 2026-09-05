/* popcount.c — freestanding RV32I, -O0, no libc. Program 2: branches.
   Counts the set bits of a constant by testing one bit per iteration. The
   inner `if` is taken and not-taken in a data-dependent pattern; the loop
   branch is taken 7 times and falls through once. Bottoms out in a
   memory-mapped write of the count, so the descent still ends at a store. */
#define UART_TX ((volatile unsigned char *)0x10000000)

static int popcount8(unsigned int x) {
    int n = 0;
    for (int i = 0; i < 8; i++) {
        if (x & 1u) { n++; }
        x >>= 1;
    }
    return n;
}

void fathom_main(void) {
    int n = popcount8(0xA5u);          /* 1010 0101 -> 4 */
    *UART_TX = (unsigned char)('0' + n);
    for (;;) { }
}
