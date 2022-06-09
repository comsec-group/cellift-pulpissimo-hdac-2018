OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  gpio_start_addr = 0x1A100000;
  . = 0x1c008000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
}
