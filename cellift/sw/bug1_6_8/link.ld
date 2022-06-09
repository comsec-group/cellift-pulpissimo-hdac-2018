OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  soc_ctrl_addr = 0x1a104000;
  . = 0x1c008000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
}
