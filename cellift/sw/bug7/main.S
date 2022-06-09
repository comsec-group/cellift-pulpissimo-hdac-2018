
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
    li x1, gpio_start_addr
    la x2, 0
    .rept 40
    nop # Taint injected here
    .endr
    sw x0, (x1)
infinite_loop:
    j infinite_loop
