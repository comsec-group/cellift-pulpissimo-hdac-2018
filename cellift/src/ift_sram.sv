// Copyright 2022 Flavien Solt, ETH Zurich.
// Licensed under the General Public License, Version 3.0, see LICENSE for details.
// SPDX-License-Identifier: GPL-3.0-only

// Supports interleaving.

module ift_sram #(
  parameter int unsigned NumWords     = 32'd1024, // Number of Words in data array
  parameter int unsigned DataWidth    = 32'd128,  // Data signal width
  parameter int unsigned ByteWidth    = 32'd8,    // Width of a data byte
  parameter int unsigned NumBanks     = 32'd8,    // To manage the interleaving                
  parameter int unsigned BankId       = 32'd0,    // Bank id in the interleaved array of banks 
  parameter int unsigned NumPorts     = 32'd1,    // MUST BE 1
  parameter int unsigned Latency      = 32'd1,    // Latency when the read data is available
  parameter bit          PrintSimCfg  = 1'b0,     // Print configuration
  
  parameter logic [31:0] AddrOffset   = 32'h1C000000, // Offset in the address map
  parameter int unsigned NumTaints = 1,

  // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
  parameter int unsigned AddrWidth  = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
  parameter int unsigned WidthBytes = (DataWidth + ByteWidth - 32'd1) / ByteWidth // ceil_div
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  // input ports
  input  logic                  req_i,      // request
  input  logic                  we_i,       // write enable
  input  logic [AddrWidth-1:0]  addr_i,     // request address
  input  logic [DataWidth-1:0]  wdata_i,    // write data
  input  logic [WidthBytes-1:0] be_i,       // write byte enable
  // output ports
  output logic [DataWidth-1:0]  rdata_o,    // read data

  // Taint signals

  input  logic [NumTaints-1:0]                 clk_i_t0,
  input  logic [NumTaints-1:0]                 rst_ni_t0,

  input  logic [NumTaints-1:0]                 req_i_t0,
  input  logic [NumTaints-1:0]                 we_i_t0,
  input  logic [NumTaints-1:0][AddrWidth-1:0]  addr_i_t0,
  input  logic [NumTaints-1:0][DataWidth-1:0]  wdata_i_t0,
  input  logic [NumTaints-1:0][WidthBytes-1:0] be_i_t0,

  output logic [NumTaints-1:0][DataWidth-1:0]  rdata_o_t0
);

  initial begin
    assert(NumTaints == 1);
  end

  // Taint the full sram if a write occurs with a tainted address.
  logic [NumTaints-1:0][DataWidth-1:0] rdata_o_taint_before_conservative;
  for (genvar taint_id = 0; taint_id < NumTaints; taint_id++) begin : gen_taints_conservative
    logic is_mem_fully_tainted_d, is_mem_fully_tainted_q;
    assign is_mem_fully_tainted_d = is_mem_fully_tainted_q | ((req_i | req_i_t0[taint_id]) & (we_i | we_i_t0[taint_id]) & |((be_i | be_i_t0[taint_id]) & addr_i_t0[taint_id]));
    always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
        is_mem_fully_tainted_q <= '0;
      end else begin
        is_mem_fully_tainted_q <= is_mem_fully_tainted_d;
      end
    end

    // Remember whether the request was made with a tainted address. Sensitivity to reset is important.
    logic was_req_addr_tainted_d, was_req_addr_tainted_q;
    assign was_req_addr_tainted_d = |addr_i_t0[taint_id] | req_i_t0[taint_id] | (req_i & we_i_t0[taint_id]);
    always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
        was_req_addr_tainted_q <= '0;
      end else begin
        was_req_addr_tainted_q <= was_req_addr_tainted_d;
      end
    end

    // Taint the read data if the addr was tainted.
    assign rdata_o_t0[taint_id] = rdata_o_taint_before_conservative[taint_id] | {(DataWidth){was_req_addr_tainted_q | is_mem_fully_tainted_q}};
  end

  import "DPI-C" function read_elf(input string filename);
  import "DPI-C" function byte get_section(output longint address, output longint len);
  import "DPI-C" context function byte read_section(input longint address, inout byte buffer[]);
  import "DPI-C" function string Get_SRAM_ELF_object_filename();
  import "DPI-C" function string Get_SRAM_TaintsPath();

  import "DPI-C" function init_taint_vectors(input longint num_taints);
  import "DPI-C" function read_taints(input string filename);
  import "DPI-C" function byte get_taint_section(input longint taint_id, output longint address, output longint len);
  import "DPI-C" context function byte read_taint_section(input longint taint_id, input longint address, inout byte buffer[]);

  logic [DataWidth-1:0] memory [bit [31:0]];
  int sections [bit [31:0]];

//  localparam string TaintsPath = "../../../taint_data/sram/sram_taint_data.txt";

  localparam bit PreloadELF = 1;
  localparam bit PreloadTaints = 1;

  localparam int unsigned PreloadBufferSize = 100000;
  initial begin // Load the binary into memory.
    // Assume that all sections are aligned on NumBanks * WidthBytes
    if (PreloadELF) begin
      automatic string binary = Get_SRAM_ELF_object_filename(); // defaults to "../../../sw/sram/sram.o";
      longint section_addr, section_len;
      byte buffer[PreloadBufferSize];
      void'(read_elf(binary));
      $display("Preloading SRAM ELF with: %s (bank %d)", binary, BankId);
      while (get_section(section_addr, section_len)) begin
        automatic int num_words = (section_len+(WidthBytes-1))/WidthBytes;
        sections[section_addr/WidthBytes] = num_words;
        // buffer = new [num_words*WidthBytes];
        // assert(num_words*WidthBytes >= PreloadBufferSize);
        void'(read_section(section_addr, buffer));

        for (int i = 0; i < num_words; i++) begin
          automatic logic [WidthBytes-1:0][7:0] word = '0;
          for (int j = 0; j < WidthBytes; j++) begin
            word[j] = buffer[i*WidthBytes+j];
          end

          // Only write the word to the (right-shifted) memory if this corresponds to the right bank.
          if (section_addr >= AddrOffset && ((section_addr-AddrOffset)/WidthBytes+i)%NumBanks == BankId) begin
            memory[((section_addr-AddrOffset)/WidthBytes+i)/NumBanks] = word;
            $display("Bank %d: loading addr/wbytes %x to SRAM addr %x: %x", BankId, section_addr/WidthBytes+i, ((section_addr-AddrOffset)/WidthBytes+i)/NumBanks, word);
          end
        end
      end
      $display("Done preloading SRAM ELF (bank %d).", BankId);
    end
  end

  //
  //  Data
  //

  always_ff @(posedge clk_i) begin
		if (req_i) begin
      if (we_i) begin
          for (int i = 0; i < DataWidth; i = i + 1)
            if (be_i[i>>3])
              memory[addr_i][i] = wdata_i[i];  // Blocking assignment because some commercial tool does not support non-blocking assignments here.
        end
        else
          rdata_o <= memory[addr_i];
      end
  end

  for (genvar taint_id = 0; taint_id < NumTaints; taint_id++) begin : gen_taints
    logic [DataWidth-1:0] mem_taints [bit [31:0]];

    initial begin // Load the taint into memory.
      if (PreloadTaints) begin
        automatic string binary = Get_SRAM_TaintsPath();
        longint section_addr, section_len;
        byte buffer[PreloadBufferSize];
        void'(init_taint_vectors(NumTaints));
        void'(read_taints(binary));
        $display("Preloading SRAM taints with: %s (bank %d) (addroffset %x)", binary, BankId, AddrOffset);
        for (int taint_id = 0; taint_id < NumTaints; taint_id++) begin
          while (get_taint_section(taint_id, section_addr, section_len)) begin
            automatic int num_words = (section_len+(WidthBytes-1))/WidthBytes;
            sections[section_addr/WidthBytes] = num_words;
            // assert(num_words*WidthBytes >= PreloadBufferSize);
            void'(read_taint_section(taint_id, section_addr, buffer));

            for (int i = 0; i < num_words; i++) begin
              automatic logic [WidthBytes-1:0][7:0] word = '0;
              for (int j = 0; j < WidthBytes; j++) begin
                word[j] = buffer[i*WidthBytes+j];
              end
              if (!mem_taints.exists(((section_addr-AddrOffset)/WidthBytes+i)/NumBanks))
                mem_taints[((section_addr-AddrOffset)/WidthBytes+i)/NumBanks] = {NumTaints*DataWidth{1'b0}};

              // Only write the taint word to the (right-shifted) taint memory if this corresponds to the right bank.
              if (section_addr >= AddrOffset && ((section_addr-AddrOffset)/WidthBytes+i)%NumBanks == BankId) begin
                mem_taints[((section_addr-AddrOffset)/WidthBytes+i)/NumBanks][taint_id] |= word;
                $display("Bank %d: tainting addr/wbytes %x to SRAM addr %x: %x. result: %x",
                        BankId, section_addr/WidthBytes+i, ((section_addr-AddrOffset)/WidthBytes+i)/NumBanks, word,
                        mem_taints[((section_addr-AddrOffset)/WidthBytes+i)/NumBanks][taint_id]);
              end
            end
          end
        end
        $display("Done preloading SRAM taints (bank %d).", BankId);
      end
    end

    always_ff @(posedge clk_i) begin
      if (req_i) begin
        if (we_i) begin
            for (int i = 0; i < DataWidth; i = i + 1)
              if (be_i[i>>3])
                mem_taints[addr_i][i] = wdata_i_t0[taint_id][i]; // Blocking assignment because some commercial tool does not support non-blocking assignments here. 
          end
          else
            if (mem_taints.exists(addr_i))
              rdata_o_taint_before_conservative[taint_id] = mem_taints[addr_i];
            else
              rdata_o_taint_before_conservative[taint_id] = '0;
        end
    end
  end
  
endmodule
