# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

import sys
import re

# sys.argv[1]: targetm file to modify in place
# sys.argv[2]: target file path (will be a copy of the source file, modified).

REPLACEMENTS_REGEX = [ # List of (old, new)
(r"soc_clk_rst_gen\s+i_clk_rst_gen(?:(?:.|\n)+?);", """
    assign s_soc_clk = dft_test_mode_i ? test_clk_i : ref_clk_i;
    assign s_cluster_clk = dft_test_mode_i ? test_clk_i : ref_clk_i;
    assign s_periph_clk = dft_test_mode_i ? test_clk_i : ref_clk_i;
    assign s_soc_rstn = rstn_glob_i;
    assign s_cluster_rstn = rstn_glob_i;

    // Ignore the FLL bus transactions for now.
    assign s_soc_fll_master.ack = '1;
    assign s_soc_fll_master.r_data = '0;
    assign s_soc_fll_master.lock = '1;
    assign s_per_fll_master.ack = '1;
    assign s_per_fll_master.r_data = '0;
    assign s_per_fll_master.lock = '1;
    assign s_cluster_fll_master.ack = '1;
    assign s_cluster_fll_master.r_data = '0;
    assign s_cluster_fll_master.lock = '1;
"""),
# Enable fetch from the start on. Not useful in the HDAC'18 version of PULPissimo, as fetch_en is already enabled by default.
(r"(r_fetchen\s*<=\s*1?'[a-zA-Z])[01]", r"\g<1>1"),
# # Disable PMP by default: apparently, no PMP on HDAC'18 version
# (r"(parameter\s*USE_PMP\s*=\s*(?:1'[a-zA-Z])?)1", r"\g<1>0"),
# Use an IFT-ready bootrom (done in the exact version)
# (r"boot_rom((?:\n|\s)*#\s*\())", r"ift_boot_rom_hdac\g<1>"),
# Use IFT-ready SRAM (also directly fillable in simulation initialization)
# (r"tc_sram(\s*#\s*\([\n\s]*\.NumWords\s*\(\s*BANK_SIZE_INTL_SRAM\s*\),[\n\s]*\.DataWidth\s*\(\s*32\s*\),[\n\s]*\.NumPorts\s*\(\s*1\s*\))", r"ift_sram\g<1>,"+"\n         .NumBanks(NB_BANKS),\n         .BankId( i ),\n      .AddrOffset( `SOC_MEM_MAP_PRIVATE_BANK1_END_ADDR )"),
]

REPLACEMENTS_EXACT = [
  # Use tc sram for private bank 1
  ("""      generic_memory #(
         .ADDR_WIDTH ( MEM_ADDR_WIDTH_PRI  ),
         .DATA_WIDTH ( 32                  )
      ) bank_sram_pri1_i (
         .CLK   ( clk_i                      ),
         .INITN ( 1'b1                       ),
         .CEN   ( mem_pri_slave[1].csn       ),
         .BEN   ( ~mem_pri_slave[1].be       ),
         .WEN   ( mem_pri_slave[1].wen       ),
         .A     ( mem_pri_slave[1].add[MEM_ADDR_WIDTH_PRI-1:0] ),
         .D     ( mem_pri_slave[1].wdata     ),
         .Q     ( mem_pri_slave[1].rdata     )
      );""","""
    ift_sram #(
      .NumWords  ( BANK_SIZE_PRI1 ),
      .DataWidth ( 32             ),
      .NumPorts  ( 1              ),
      .Latency   ( 1              ),
      .NumBanks( 1 ),
      .BankId( 0 ),
      .AddrOffset( 32'h1C00_8000 )
    ) bank_sram_pri1_i (
      .clk_i,
      .rst_ni,
      .req_i   ( ~mem_pri_slave[1].csn                  ),
      .we_i    ( ~mem_pri_slave[1].wen                  ),
      .addr_i  (  mem_pri_slave[1].add[MEM_ADDR_WIDTH_PRI-1:0] ),
      .wdata_i (  mem_pri_slave[1].wdata                ),
      .be_i    (  mem_pri_slave[1].be                   ),
      .rdata_o (  mem_pri_slave[1].rdata                )
    );"""),
  ("""                  model_sram_28672x32_scm_512x32 bank_i (
                     .CLK   ( clk_i                                ),
		     .RSTN  ( rst_ni                               ),
                     .D     ( mem_slave[i].wdata                   ),
                     .A     ( mem_slave[i].add[MEM_ADDR_WIDTH-1:0] ),
                     .CEN   ( mem_slave[i].csn                     ),
                     .WEN   ( mem_slave[i].wen                     ),
                     .BEN   ( ~mem_slave[i].be                     ),
                     .Q     ( mem_slave[i].rdata                   )
                  );""","""       ift_sram #(
         .NumWords  ( BANK_SIZE_INTL_SRAM ),
         .DataWidth ( 32                  ),
         .NumPorts  ( 1                   ),
         .NumBanks(NB_BANKS),
         .BankId( i ),
      .AddrOffset( 32'h1C01_0000 )
       ) bank_i (
         .clk_i,
         .rst_ni,
         .req_i   ( ~mem_slave[i].csn                                  ),
         .we_i    ( ~mem_slave[i].wen                                  ),
         .addr_i  (  mem_slave[i].add[MEM_ADDR_WIDTH-1:0] ), // Remove LSBs for byte addressing (2 bits)
                                                                                                              // and bank selection (log2(NB_BANKS) bits)
         .wdata_i (  mem_slave[i].wdata                                ),
         .be_i    (  mem_slave[i].be                                   ),
         .rdata_o (  mem_slave[i].rdata                                )
       );"""),

("""boot_rom #(
        .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH)
    ) boot_rom_i (
        .clk_i       ( s_soc_clk       ),
        .rst_ni      ( s_soc_rstn      ),
        .init_ni     ( 1'b1            ),
        .mem_slave   ( s_mem_rom_bus   ),
        .test_mode_i ( dft_test_mode_i )
    );""", """ift_boot_rom_hdac #(
        .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH)
    ) boot_rom_i (
        .clk_i       ( s_soc_clk           ),
        .rst_ni      ( s_soc_rstn          ),
        .init_ni     ( 1'b1                ),
        .wdata       ( s_mem_rom_bus.wdata ),
        .add         ( s_mem_rom_bus.add   ),
        .csn         ( s_mem_rom_bus.csn   ),
        .wen         ( s_mem_rom_bus.wen   ),
        .be          ( s_mem_rom_bus.be    ),
        .id          ( s_mem_rom_bus.id    ),
        .rdata       ( s_mem_rom_bus.rdata ),
        .test_mode_i ( dft_test_mode_i     )
    );"""),
]

TO_ADD = []

if __name__ == "__main__":
    assert (len(sys.argv) == 3)
    src_filename = sys.argv[1] 
    dest_filename = sys.argv[2] 

    with open(src_filename, "r") as f:
        content = f.read()

    # Replace with regex.
    for elem in REPLACEMENTS_REGEX:
      # Check whether the replacement origin exists (for future-proofness)
      if (re.search(elem[0], content) is None):
        raise ValueError("Regex replacement origin {} was not found in file {}.".format(elem[0], src_filename))
      content = re.sub(elem[0], elem[1], content, flags=re.MULTILINE|re.DOTALL)

    # Replace with exact match.
    for elem in REPLACEMENTS_EXACT:
      # Check whether the replacement origin exists (for future-proofness)
      if not elem[0] in content:
        raise ValueError("Exact replacement origin {} was not found in file {}.".format(elem[0], src_filename))
      content = content.replace(elem[0], elem[1])

    # Add.
    content += "\n\n".join(TO_ADD)

    with open(dest_filename, "w") as f:
        f.write(content)
