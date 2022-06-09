
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
    la x1, rom_mid_addr # Mid addr in the ROM, which is not accessible in the original PULPissimo design.
    lw x2, (x1)
infinite_loop:
    j infinite_loop

# Should check the taint of x2