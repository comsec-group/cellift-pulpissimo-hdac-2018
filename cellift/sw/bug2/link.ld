OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  beyond_l2_addr = 0x1C081000;
  . = 0x1c008000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
}
