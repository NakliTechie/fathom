/* sum_lib.c — Program 4, TU 2 of 2. A loop with a call frame, in its own unit. */
int sum_to(int n) {
    int s = 0;
    for (int i = 0; i <= n; i++) { s += i; }
    return s;
}
