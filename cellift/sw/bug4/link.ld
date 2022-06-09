OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  gpio_lock_addr = 0x1A101048;
  . = 0x1c008000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
}
