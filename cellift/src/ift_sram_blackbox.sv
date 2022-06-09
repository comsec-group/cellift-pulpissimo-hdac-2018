// Copyright 2022 Flavien Solt, ETH Zurich.
// Licensed under the General Public License, Version 3.0, see LICENSE for details.
// SPDX-License-Identifier: GPL-3.0-only

// Supports interleaving.

(* blackbox *)
module ift_sram (
  clk_i,
  rst_ni,
  req_i,
  we_i,
  addr_i,
  wdata_i,
  be_i,
  rdata_o
);
  parameter [31:0] NumWords = 32'd1024;
  parameter [31:0] DataWidth = 32'd128;
  parameter [31:0] ByteWidth = 32'd8;
  parameter [31:0] NumBanks = 32'd8;
  parameter [31:0] BankId = 32'd0;
  parameter [31:0] NumPorts = 32'd1;
  parameter [31:0] Latency = 32'd1;
  parameter [0:0] PrintSimCfg = 1'b0;
  parameter [31:0] AddrOffset = 32'h1c000000;
  parameter [31:0] NumTaints = 2;
  parameter [31:0] AddrWidth = (NumWords > 32'd1 ? $clog2(NumWords) : 32'd1);
  parameter [31:0] WidthBytes = ((DataWidth + ByteWidth) - 32'd1) / ByteWidth;
  input wire clk_i;
  input wire rst_ni;
  input wire req_i;
  input wire we_i;
  input wire [AddrWidth - 1:0] addr_i;
  input wire [DataWidth - 1:0] wdata_i;
  input wire [WidthBytes - 1:0] be_i;
  output wire [DataWidth - 1:0] rdata_o;
endmodule
