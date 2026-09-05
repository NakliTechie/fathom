/* crt0.S — reset stub. Sets sp, enters the traced region, never returns.
   Deliberately OUTSIDE [pc_start, pc_end): SPEC §1.2 excludes the startup stub
   by construction, so no join has to resolve an instruction with no C source. */
    .section .text.crt0, "ax"
    .globl _start
_start:
    la   sp, _stack_top
    j    fathom_main
