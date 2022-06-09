#!/usr/python3

# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

import re
import sys

# sys.argv[1]: name of the Verilog file where to deparametrize the memory module names.
# sys.argv[2]: name of the Verilog saved result file.

REGEX = []
REGEX.append(r"\\\$paramod[\w\\='$]+\s+boot_rom_i")
REGEX.append(r"\\\$paramod[\w\\='$]+\s+\\l2_ram_i\.CUTS\[(\d)\]\.bank_i")
REGEX.append(r"\\\$paramod[\w\\='$]+\s+\\l2_ram_i\.bank_sram_pri1_i")
REGEX.append(r"model_6144x32_2048x32scm(?:(?:.|\n)+?)\)[\s\n]*;")

REPLACE = []
REPLACE.append(r"ift_boot_rom_hdac boot_rom_i")

REPLACE.append(r"""ift_sram #(
    .NumWords(32'h7000),
    .DataWidth(32),
    .NumBanks(4),
    .BankId(\g<1>),
    .AddrOffset(32'h1C01_0000 + 4*32'h7000*\g<1>)
    ) interleaved_sram_\g<1>_i
""")

REPLACE.append(r"""ift_sram #(
    .NumWords(32'h2000),
    .DataWidth(32),
    .NumBanks(1),
    .BankId(0),
    .AddrOffset(32'h1C00_8000)
    ) pri1_sram_i
""")

REPLACE.append(r"""
  assign \\s_mem_l2_pri_bus[0].rdata = 0;
  assign \\fc_subsystem_i.fc_demux_data_i.rdata_port1 = 0;
  assign \\fc_subsystem_i.fc_demux_data_i.rdata_port1_t0 = 0;
  assign \\fc_subsystem_i.fc_demux_instr_i.rdata_port1 = 0;
  assign \\fc_subsystem_i.fc_demux_instr_i.rdata_port1_t0 = 0;
  assign \\s_mem_l2_pri_bus[0].rdata_t0 = 0;
""")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Takes 2 arguments: the Verilog file paths.")

    with open(sys.argv[1], "r") as f:
        content = f.read()

    for i in range(4):
        content, num_subs = re.subn(REGEX[i], REPLACE[i], content, flags=re.MULTILINE)
        print("Num subs of index {}: {}".format(i, num_subs))
        assert(num_subs > 0)

    with open(sys.argv[2], "w") as f:
        f.write(content)
