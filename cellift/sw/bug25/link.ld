OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x1c008000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
}
