
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
    li x1, 0
    la x2, gpio_lock_addr
    .rept 40
    nop # Taint injected here
    .endr
    sw x1, (x2)
infinite_loop:
    j infinite_loop
