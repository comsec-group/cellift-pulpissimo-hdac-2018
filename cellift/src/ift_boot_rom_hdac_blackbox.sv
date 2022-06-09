// Copyright 2022 Flavien Solt, ETH Zurich.
// Licensed under the General Public License, Version 3.0, see LICENSE for details.
// SPDX-License-Identifier: GPL-3.0-only

(* blackbox *)
module ift_boot_rom_hdac (
   clk_i,
   rst_ni,
   init_ni,
   wdata,
   add,
   csn,
   wen,
   be,
   id,
   rdata,
   test_mode_i
);
   parameter ROM_ADDR_WIDTH = 13;
   parameter [31:0] AddrOffset = 32'h1a000000;
   input wire clk_i;
   input wire rst_ni;
   input wire init_ni;
   input wire [31:0] wdata;
   input wire [31:0] add;
   input wire [31:0] csn;
   input wire wen;
   input wire be;
   input wire [3:0] id;
   output wire [31:0] rdata;
   input wire test_mode_i;
endmodule
