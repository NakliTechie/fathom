/* chase.c — freestanding RV32I, -O0, no libc. Program 3: load-use.
   Walks a linked list in ROM. Every step is a load whose result is used by
   the very next instruction, so the pipeline's load-use stall fires on each
   hop. The tail node holds the byte written to the UART. */
#define UART_TX ((volatile unsigned char *)0x10000000)

struct node { const struct node *next; unsigned char val; };

static const struct node n3 = { 0,   'z' };
static const struct node n2 = { &n3, 'y' };
static const struct node n1 = { &n2, 'x' };
static const struct node n0 = { &n1, 'w' };

void fathom_main(void) {
    const struct node *p = &n0;
    while (p->next) { p = p->next; }
    *UART_TX = p->val;
    for (;;) { }
}
