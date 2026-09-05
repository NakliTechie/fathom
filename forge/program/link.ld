/* Minimal RV32I bare-metal map. ROM at 0x8000_0000, RAM below the MMIO window. */
ENTRY(_start)
MEMORY {
  ROM (rx)  : ORIGIN = 0x80000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x80010000, LENGTH = 64K
}
SECTIONS {
  .text   : { *(.text*) }            > ROM
  .rodata : { *(.rodata*) }          > ROM
  .data   : { *(.data*) }            > RAM
  .bss    : { *(.bss*) *(COMMON) }   > RAM
  . = ALIGN(16);
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
