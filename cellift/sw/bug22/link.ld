OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  rom_mid_addr = 0x1a101000;
  . = 0x1c008000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
}
