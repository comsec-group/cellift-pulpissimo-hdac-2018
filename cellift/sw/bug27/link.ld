OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  irq_mask_addr = 0x1a109000;
  . = 0x1c008000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
}
