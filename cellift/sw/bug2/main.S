
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
    la x1, beyond_l2_addr
    li x2, 0
    .rept 40
    nop # Taint injected here
    .endr
    sw x2, (x1)
infinite_loop:
    j infinite_loop
