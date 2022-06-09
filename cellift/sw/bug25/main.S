
  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
    csrw mstatus, t0 # This instruction will be completely tainted.
infinite_loop:
    j infinite_loop

# Should check the taint of x2