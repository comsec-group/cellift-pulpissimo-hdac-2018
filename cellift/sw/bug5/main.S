
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
infinite_loop:
    j infinite_loop
