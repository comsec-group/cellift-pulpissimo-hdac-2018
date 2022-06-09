# TODO march is rv32imc in the led example.

RVXLEN = 32

CFLAGS = -march=rv32im -mabi=ilp32 -ffreestanding -mcmodel=medany -nostdlib -nostartfiles -O0
LDFLAGS = -Tlink.ld

bootrom.o: bootrom.S
	riscv$(RVXLEN)-unknown-elf-gcc $(CFLAGS) $(LDFLAGS) $^ -o $@

.PHONY: objdump
objdump:
	riscv$(RVXLEN)-unknown-elf-objdump -D bootrom.o
