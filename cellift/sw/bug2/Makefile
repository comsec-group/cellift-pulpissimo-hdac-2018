RISCV_PREFIX = riscv64-unknown-elf


RV_ARCH_FLAGS ?= -march=rv32ic -mabi=ilp32
RISCV_GCC_OPTS ?= $(RV_ARCH_FLAGS) -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns -gdwarf-2
LDFLAGS = -Tlink.ld -static -nostdlib -nostartfiles -lm -lgcc
RISCV_OBJDUMP ?= $(RISCV_PREFIX)-objdump -d

CC = $(RISCV_PREFIX)-gcc

main.o: main.S link.ld
	$(CC) $(RISCV_GCC_OPTS) $< -o $@ $(LDFLAGS)
	$(RISCV_OBJDUMP) $@ > $@.dump