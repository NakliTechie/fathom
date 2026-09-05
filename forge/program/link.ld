/* Minimal RV32I bare-metal map. ROM at 0x8000_0000, RAM below the MMIO window. */
ENTRY(_start)
/* ROM starts at 0x8000_0080, not 0x8000_0000: Ibex's reset vector is
   boot_addr_i + 0x80, and boot_addr_i must be 256-byte aligned. Putting the
   program at the vector is cleaner than un-aligning the boot address. */
MEMORY {
  ROM (rx)  : ORIGIN = 0x80000080, LENGTH = 64K - 0x80
  RAM (rwx) : ORIGIN = 0x80010000, LENGTH = 64K
}
SECTIONS {
  .text   : { *(.text.crt0) *(.text*) } > ROM
  .rodata : { *(.rodata*) }          > ROM
  .data   : { *(.data*) }            > RAM
  .bss    : { *(.bss*) *(COMMON) }   > RAM
  . = ALIGN(16);
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
