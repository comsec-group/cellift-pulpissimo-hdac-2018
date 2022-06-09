# IFT in PULPissimo

This folder contains all the modifications applied to PULPissimo to make it runnable with Verilator and parsable by Yosys.

## Requirements

- [Verilator](https://github.com/verilator/verilator)
- [Morty](https://github.com/zarubaf/morty)
- [Bender](https://github.com/pulp-platform/bender)
- [FuseSoC](https://github.com/olofk/fusesoc)
- [GNU RISC-V toolchain](https://github.com/riscv/riscv-gnu-toolchain)
- [sv2v](https://github.com/zachjs/sv2v)
- GTKWave (e.g., `sudo apt-get install gtkwave`)
- CellIFT-enabled Yosys


## Writing your own software

### Bootrom

The bootrom is located in `sw/boot_rom`.
It can be modified and recompiled at will.
The ELF file `sw/boot_rom/boot_rom.o` is loaded into the simulation bootrom when the simulation starts. 

Typically, the bootrom will jump to address `0x1C000080`: the reset handler position of the program loaded into RAM.

### RAM

Some ELF can also be loaded into RAM.
It can be modified and recompiled at will.
The ELF file `sw/sram/sram.o` is loaded into the simulation RAM when the simulation starts.

To make a CoreMark executable, use the `coremark` target in `sw/sram/`.

## Noticeable Makefile targets

- `make run_vanilla`: Compiles the non-instrumented SystemVerilog design and the testbenches and runs the testbench.
- `make rerun_vanilla`: Runs the testbench without recompilation.
- `make recompile`: Recompiles the C++ testbench located in `dv`, but not the SystemVerilog design, which is quite long.
- `make wave`: View the waveforms corresponding to the last simulation run.
Tip: you do not need to wait for the end of the simulation to start looking at the waves.

## Modifying the testbench

The C++ testbench is located in the `dv` folder.
You can freely modify them.
Any modification should be followed by a compilation through `make run_<something>` or `make recompile`.
`ift_sram_test` was useful for some unit tests applied to the IFT-ready SRAM.


## Information flow tracking

WIP

