
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
    la x1, irq_mask_addr # Mid addr in the ROM, which is not accessible in the original PULPissimo design.
    .rept 40
    nop # Taint injected here
    .endr
    sw x2, (x1)
infinite_loop:
    j infinite_loop
