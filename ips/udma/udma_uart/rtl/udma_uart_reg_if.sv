// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

///////////////////////////////////////////////////////////////////////////////
//
// Description: UART configuration interface
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////


`define REG_RX_SADDR     5'b00000 //BASEADDR+0x00 
`define REG_RX_SIZE      5'b00001 //BASEADDR+0x04
`define REG_RX_CFG       5'b00010 //BASEADDR+0x08  
`define REG_RX_INTCFG    5'b00011 //BASEADDR+0x0C  

`define REG_TX_SADDR     5'b00100 //BASEADDR+0x10
`define REG_TX_SIZE      5'b00101 //BASEADDR+0x14
`define REG_TX_CFG       5'b00110 //BASEADDR+0x18
`define REG_TX_INTCFG    5'b00111 //BASEADDR+0x1C

`define REG_STATUS       5'b01000 //BASEADDR+0x20
`define REG_UART_SETUP   5'b01001 //BASEADDR+0x24

module udma_uart_reg_if #(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE     = 16
) (
	input  logic 	                  clk_i,
	input  logic   	                  rstn_i,

	input  logic               [31:0] cfg_data_i,
	input  logic                [4:0] cfg_addr_i,
	input  logic                      cfg_valid_i,
	input  logic                      cfg_rwn_i,
	output logic               [31:0] cfg_data_o,
	output logic                      cfg_ready_o,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_rx_size_o,
    output logic                      cfg_rx_continuous_o,
    output logic                      cfg_rx_en_o,
    output logic                      cfg_rx_clr_o,
    input  logic                      cfg_rx_en_i,
    input  logic                      cfg_rx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_tx_size_o,
    output logic                      cfg_tx_continuous_o,
    output logic                      cfg_tx_en_o,
    output logic                      cfg_tx_clr_o,
    input  logic                      cfg_tx_en_i,
    input  logic                      cfg_tx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_tx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_tx_bytes_left_i,

    input  logic               [2:0]  status_i,
    output logic                      err_clr_o,
    output logic                      stop_bits_o,
    output logic                      parity_en_o,
    output logic              [15:0]  divider_o,
    output logic               [1:0]  num_bits_o,
    output logic                      en_rx_o,
    output logic                      en_tx_o
);

    logic [L2_AWIDTH_NOAL-1:0] r_rx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_rx_size;
    logic                      r_rx_continuous;
    logic                      r_rx_en;
    logic                      r_rx_clr;

    logic [L2_AWIDTH_NOAL-1:0] r_tx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_tx_size;
    logic                      r_tx_continuous;
    logic                      r_tx_en;
    logic                      r_tx_clr;

    logic                      r_uart_en_tx;
    logic                      r_uart_en_rx;
    logic               [15:0] r_uart_div;
    logic                      r_uart_stop_bits;
    logic                [1:0] r_uart_bits;
    logic                      r_uart_parity_en;

    logic                [4:0] s_wr_addr;
    logic                [4:0] s_rd_addr;

    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    assign cfg_rx_startaddr_o  = r_rx_startaddr;
    assign cfg_rx_size_o       = r_rx_size;
    assign cfg_rx_continuous_o = r_rx_continuous;
    assign cfg_rx_en_o         = r_rx_en;
    assign cfg_rx_clr_o        = r_rx_clr;

    assign cfg_tx_startaddr_o  = r_tx_startaddr;
    assign cfg_tx_size_o       = r_tx_size;
    assign cfg_tx_continuous_o = r_tx_continuous;
    assign cfg_tx_en_o         = r_tx_en;
    assign cfg_tx_clr_o        = r_tx_clr;

    assign en_tx_o         = r_uart_en_tx;
    assign en_rx_o         = r_uart_en_rx;
    assign divider_o       = r_uart_div;
    assign num_bits_o      = r_uart_bits;
    assign parity_en_o     = r_uart_parity_en;
    assign stop_bits_o     = r_uart_stop_bits;

    always_ff @(posedge clk_i, negedge rstn_i) 
    begin
        if(~rstn_i) 
        begin
            // SPI REGS
            r_rx_startaddr     <=  'h0;
            r_rx_size          <=  'h0;
            r_rx_continuous    <=  'h0;
            r_rx_en             =  'h0;
            r_rx_clr            =  'h0;
            r_tx_startaddr     <=  'h0;
            r_tx_size          <=  'h0;
            r_tx_continuous    <=  'h0;
            r_tx_en             =  'h0;
            r_tx_clr            =  'h0;
            r_uart_div         <=  'h0;
            r_uart_stop_bits   <=  'h0;
            r_uart_bits        <=  'h0;
            r_uart_parity_en   <=  'h0;
            r_uart_en_tx       <=  'h0;
            r_uart_en_rx       <=  'h0;
        end
        else
        begin
            r_rx_en   =  'h0;
            r_rx_clr  =  'h0;
            r_tx_en   =  'h0;
            r_tx_clr  =  'h0;

            if (cfg_valid_i & ~cfg_rwn_i)
            begin
                case (s_wr_addr)
                `REG_RX_SADDR:
                    r_rx_startaddr    <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_RX_SIZE:
                    r_rx_size         <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_RX_CFG:
                begin
                    r_rx_clr           = cfg_data_i[5];
                    r_rx_en            = cfg_data_i[4];
                    r_rx_continuous   <= cfg_data_i[0];
                end
                `REG_TX_SADDR:
                    r_tx_startaddr    <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_TX_SIZE:
                    r_tx_size         <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_TX_CFG:
                begin
                    r_tx_clr           = cfg_data_i[5];
                    r_tx_en            = cfg_data_i[4];
                    r_tx_continuous   <= cfg_data_i[0];
                end

                `REG_UART_SETUP:
                begin
                    r_uart_div        <= cfg_data_i[31:16];
                    r_uart_en_tx      <= cfg_data_i[8];
                    r_uart_en_rx      <= cfg_data_i[9];
                    r_uart_stop_bits  <= cfg_data_i[3];
                    r_uart_bits       <= cfg_data_i[2:1];
                    r_uart_parity_en  <= cfg_data_i[0];
                end

                endcase
            end
        end
    end //always

    always_comb
    begin
        cfg_data_o = 32'h0;
        err_clr_o = 1'b0;
        case (s_rd_addr)
        `REG_RX_SADDR:
            cfg_data_o = cfg_rx_curr_addr_i;
        `REG_RX_SIZE:
            cfg_data_o[TRANS_SIZE-1:0] = cfg_rx_bytes_left_i;
        `REG_RX_CFG:
            cfg_data_o = {26'h0,cfg_rx_pending_i,cfg_rx_en_i,3'h0,r_rx_continuous};
        `REG_TX_SADDR:
            cfg_data_o = cfg_tx_curr_addr_i;
        `REG_TX_SIZE:
            cfg_data_o[TRANS_SIZE-1:0] = cfg_tx_bytes_left_i;
        `REG_TX_CFG:
            cfg_data_o = {26'h0,cfg_tx_pending_i,cfg_tx_en_i,3'h0,r_tx_continuous};
        `REG_UART_SETUP:
            cfg_data_o = {r_uart_div, 6'h0, r_uart_en_rx, r_uart_en_tx, 4'h0, r_uart_stop_bits,r_uart_bits, r_uart_parity_en};
        `REG_STATUS:
        begin
            cfg_data_o = {29'h0,status_i};
	        err_clr_o = 1'b1;
	    end
        default:
            cfg_data_o = 'h0;
        endcase
    end

    assign cfg_ready_o  = 1'b1;

endmodule 
