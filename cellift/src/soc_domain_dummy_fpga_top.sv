module soc_domain_fpga_top #(
    parameter CORE_TYPE            = 0,
    parameter USE_FPU              = 1,
    parameter AXI_ADDR_WIDTH       = 32,
    parameter AXI_DATA_IN_WIDTH    = 64,
    parameter AXI_DATA_OUT_WIDTH   = 32,
    parameter AXI_ID_IN_WIDTH      = 4,
    parameter AXI_ID_INT_WIDTH     = 8,
    parameter AXI_ID_OUT_WIDTH     = 6,
    parameter AXI_USER_WIDTH       = 6,
    parameter AXI_STRB_IN_WIDTH    = AXI_DATA_IN_WIDTH/8,
    parameter AXI_STRB_OUT_WIDTH   = AXI_DATA_OUT_WIDTH/8,
    parameter BUFFER_WIDTH         = 8,
    parameter EVNT_WIDTH           = 8
) (
        input logic                             ref_clk_i,
        input logic                             slow_clk_i,
        input logic                             test_clk_i,
        input logic                             rstn_glob_i,

        input logic                             dft_test_mode_i,
        input logic                             dft_cg_enable_i,
        input logic                             sel_fll_clk_i,

        input logic                             mode_select_i,

        input logic                             boot_l2_i,
        input logic                             jtag_tck_i,
        input logic                             jtag_trst_ni,
        input logic                             jtag_tms_i,
        input logic                             jtag_td_i,
        input logic                             jtag_axireg_tdi_i,
        input logic                             jtag_axireg_tdo_o,
        input logic                             jtag_axireg_sel_i,
        input logic                             jtag_shift_dr_i,
        input logic                             jtag_update_dr_i,
        input logic                             jtag_capture_dr_i,

        //////////////////////
        // Not aggregated
        //////////////////////

        output logic                             uart_tx_o,
        input  logic                             uart_rx_i,

        input  logic                             cam_clk_i,
        input  logic [7:0]                       cam_data_i,
        input  logic                             cam_hsync_i,
        input  logic                             cam_vsync_i,

        output logic [3:0]                       timer_ch0_o,
        output logic [3:0]                       timer_ch1_o,
        output logic [3:0]                       timer_ch2_o,
        output logic [3:0]                       timer_ch3_o,

        input  logic                             i2c0_scl_i,
        output logic                             i2c0_scl_o,
        output logic                             i2c0_scl_oe_o,
        input  logic                             i2c0_sda_i,
        output logic                             i2c0_sda_o,
        output logic                             i2c0_sda_oe_o,

        input  logic                             i2c1_scl_i,
        output logic                             i2c1_scl_o,
        output logic                             i2c1_scl_oe_o,
        input  logic                             i2c1_sda_i,
        output logic                             i2c1_sda_o,
        output logic                             i2c1_sda_oe_o,

        input  logic                             i2s_sd0_i,
        input  logic                             i2s_sd1_i,
        input  logic                             i2s_sck_i,
        input  logic                             i2s_ws_i,
        output logic                             i2s_sck0_o,
        output logic                             i2s_ws0_o,
        output logic [1:0]                       i2s_mode0_o,
        output logic                             i2s_sck1_o,
        output logic                             i2s_ws1_o,
        output logic [1:0]                       i2s_mode1_o,

        output logic                             spi_master0_clk_o,
        output logic                             spi_master0_csn0_o,
        output logic                             spi_master0_csn1_o,
        output logic [1:0]                       spi_master0_mode_o,
        output logic                             spi_master0_sdo0_o,
        output logic                             spi_master0_sdo1_o,
        output logic                             spi_master0_sdo2_o,
        output logic                             spi_master0_sdo3_o,
        input  logic                             spi_master0_sdi0_i,
        input  logic                             spi_master0_sdi1_i,
        input  logic                             spi_master0_sdi2_i,
        input  logic                             spi_master0_sdi3_i,

        output logic                             sdio_clk_o,
        output logic                             sdio_cmd_o,
        input  logic                             sdio_cmd_i,
        output logic                             sdio_cmd_oen_o,
        output logic                       [3:0] sdio_data_o,
        input  logic                       [3:0] sdio_data_i,
        output logic                       [3:0] sdio_data_oen_o

        // CLUSTER
        output logic                             cluster_clk_o,
        output logic                             cluster_rstn_o,
        input  logic                             cluster_busy_i,
        output logic                             cluster_irq_o,

        output logic                             cluster_rtc_o,
        output logic                             cluster_fetch_enable_o,
        output logic [63:0]                      cluster_boot_addr_o,
        output logic                             cluster_test_en_o,
        output logic                             cluster_pow_o,
        output logic                             cluster_byp_o,

        // EVENT BUS
        output logic [BUFFER_WIDTH-1:0]          cluster_events_wt_o,
        input  logic [BUFFER_WIDTH-1:0]          cluster_events_rp_i,
        output logic [EVNT_WIDTH-1:0]            cluster_events_da_o,

        output logic                             dma_pe_evt_ack_o,
        input  logic                             dma_pe_evt_valid_i,

        output logic                             dma_pe_irq_ack_o,
        input  logic                             dma_pe_irq_valid_i,

        output logic                             pf_evt_ack_o,
        input logic                              pf_evt_valid_i,


        //////////////////////
        // Agrgegated
        //////////////////////
        input logic soc_i,
        output logic soc_o,
        input logic gpio_i,
        output logic gpio_o,
        output logic padmux_o,
        output logic padcfg_o,

        input logic all_axi_i,
        output logic all_axi_o
    );



    // Clocks
    assign slow_clk_i = ref_clk_i;
    assign test_clk_i = ref_clk_i;

    // SoC
    logic [7:0]                       soc_jtag_reg_i;
    logic [7:0]                       soc_jtag_reg_o;
    assign soc_jtag_reg_i = {8{soc_i}};
    assign soc_o = |soc_jtag_reg_o;

    // GPIO
    logic [31:0]                      gpio_in_i;
    logic [31:0]                      gpio_out_o;
    logic [31:0]                      gpio_dir_o;
    logic [191:0]                     gpio_cfg_o;
    assign gpio_in_i = {32{gpio_i}};
    assign gpio_o = |gpio_out_o || |gpio_dir_o || |gpio_cfg_o;

    // Padmux
    logic [127:0] pad_mux_o;
    logic [383:0] pad_cfg_o;
    assign padmux_o = |pad_mux_o;
    assign padcfg_o = |pad_cfg_o;

    // AXI4 SLAVE
    logic [7:0]                       data_slave_aw_writetoken_i;
    logic [AXI_ADDR_WIDTH-1:0]        data_slave_aw_addr_i;
    logic [2:0]                       data_slave_aw_prot_i;
    logic [3:0]                       data_slave_aw_region_i;
    logic [7:0]                       data_slave_aw_len_i;
    logic [2:0]                       data_slave_aw_size_i;
    logic [1:0]                       data_slave_aw_burst_i;
    logic                             data_slave_aw_lock_i;
    logic [3:0]                       data_slave_aw_cache_i;
    logic [3:0]                       data_slave_aw_qos_i;
    logic [AXI_ID_IN_WIDTH-1:0]       data_slave_aw_id_i;
    logic [AXI_USER_WIDTH-1:0]        data_slave_aw_user_i;
    logic [7:0]                       data_slave_aw_readpointer_o;

    logic [7:0]                       data_slave_ar_writetoken_i;
    logic [AXI_ADDR_WIDTH-1:0]        data_slave_ar_addr_i;
    logic [2:0]                       data_slave_ar_prot_i;
    logic [3:0]                       data_slave_ar_region_i;
    logic [7:0]                       data_slave_ar_len_i;
    logic [2:0]                       data_slave_ar_size_i;
    logic [1:0]                       data_slave_ar_burst_i;
    logic                             data_slave_ar_lock_i;
    logic [3:0]                       data_slave_ar_cache_i;
    logic [3:0]                       data_slave_ar_qos_i;
    logic [AXI_ID_IN_WIDTH-1:0]       data_slave_ar_id_i;
    logic [AXI_USER_WIDTH-1:0]        data_slave_ar_user_i;
    logic [7:0]                       data_slave_ar_readpointer_o;

    logic [7:0]                       data_slave_w_writetoken_i;
    logic [AXI_DATA_IN_WIDTH-1:0]     data_slave_w_data_i;
    logic [AXI_STRB_IN_WIDTH-1:0]     data_slave_w_strb_i;
    logic [AXI_USER_WIDTH-1:0]        data_slave_w_user_i;
    logic                             data_slave_w_last_i;
    logic [7:0]                       data_slave_w_readpointer_o;

    logic [7:0]                       data_slave_r_writetoken_o;
    logic [AXI_DATA_IN_WIDTH-1:0]     data_slave_r_data_o;
    logic [1:0]                       data_slave_r_resp_o;
    logic                             data_slave_r_last_o;
    logic [AXI_ID_IN_WIDTH-1:0]       data_slave_r_id_o;
    logic [AXI_USER_WIDTH-1:0]        data_slave_r_user_o;
    logic [7:0]                       data_slave_r_readpointer_i;

    logic [7:0]                       data_slave_b_writetoken_o;
    logic [1:0]                       data_slave_b_resp_o;
    logic [AXI_ID_IN_WIDTH-1:0]       data_slave_b_id_o;
    logic [AXI_USER_WIDTH-1:0]        data_slave_b_user_o;
    logic [7:0]                       data_slave_b_readpointer_i;

    // AXI4 MASTER
    logic [7:0]                       data_master_aw_writetoken_o;
    logic [AXI_ADDR_WIDTH-1:0]        data_master_aw_addr_o;
    logic [2:0]                       data_master_aw_prot_o;
    logic [3:0]                       data_master_aw_region_o;
    logic [7:0]                       data_master_aw_len_o;
    logic [2:0]                       data_master_aw_size_o;
    logic [1:0]                       data_master_aw_burst_o;
    logic                             data_master_aw_lock_o;
    logic [3:0]                       data_master_aw_cache_o;
    logic [3:0]                       data_master_aw_qos_o;
    logic [AXI_ID_OUT_WIDTH-1:0]      data_master_aw_id_o;
    logic [AXI_USER_WIDTH-1:0]        data_master_aw_user_o;
    logic [7:0]                       data_master_aw_readpointer_i;

    logic [7:0]                       data_master_ar_writetoken_o;
    logic [AXI_ADDR_WIDTH-1:0]        data_master_ar_addr_o;
    logic [2:0]                       data_master_ar_prot_o;
    logic [3:0]                       data_master_ar_region_o;
    logic [7:0]                       data_master_ar_len_o;
    logic [2:0]                       data_master_ar_size_o;
    logic [1:0]                       data_master_ar_burst_o;
    logic                             data_master_ar_lock_o;
    logic [3:0]                       data_master_ar_cache_o;
    logic [3:0]                       data_master_ar_qos_o;
    logic [AXI_ID_OUT_WIDTH-1:0]      data_master_ar_id_o;
    logic [AXI_USER_WIDTH-1:0]        data_master_ar_user_o;
    logic [7:0]                       data_master_ar_readpointer_i;

    logic [7:0]                       data_master_w_writetoken_o;
    logic [AXI_DATA_OUT_WIDTH-1:0]    data_master_w_data_o;
    logic [AXI_STRB_OUT_WIDTH-1:0]    data_master_w_strb_o;
    logic [AXI_USER_WIDTH-1:0]        data_master_w_user_o;
    logic                             data_master_w_last_o;
    logic [7:0]                       data_master_w_readpointer_i;

    logic [7:0]                       data_master_r_writetoken_i;
    logic [AXI_DATA_OUT_WIDTH-1:0]    data_master_r_data_i;
    logic [1:0]                       data_master_r_resp_i;
    logic                             data_master_r_last_i;
    logic [AXI_ID_OUT_WIDTH-1:0]      data_master_r_id_i;
    logic [AXI_USER_WIDTH-1:0]        data_master_r_user_i;
    logic [7:0]                       data_master_r_readpointer_o;

    logic [7:0]                       data_master_b_writetoken_i;
    logic [1:0]                       data_master_b_resp_i;
    logic [AXI_ID_OUT_WIDTH-1:0]      data_master_b_id_i;
    logic [AXI_USER_WIDTH-1:0]        data_master_b_user_i;
    logic [7:0]                       data_master_b_readpointer_o;

    // Input AXI assignments
    assign data_slave_aw_writetoken_i   = {8{all_axi_i}};
    assign data_slave_aw_prot_i         = {3{all_axi_i}};
    assign data_slave_aw_region_i       = {4{all_axi_i}};
    assign data_slave_aw_len_i          = {8{all_axi_i}};
    assign data_slave_aw_size_i         = {3{all_axi_i}};
    assign data_slave_aw_burst_i        = {2{all_axi_i}};
    assign data_slave_aw_cache_i        = {4{all_axi_i}};
    assign data_slave_aw_qos_i          = {4{all_axi_i}};
    assign data_slave_ar_writetoken_i   = {8{all_axi_i}};
    assign data_slave_ar_prot_i         = {3{all_axi_i}};
    assign data_slave_ar_region_i       = {4{all_axi_i}};
    assign data_slave_ar_len_i          = {8{all_axi_i}};
    assign data_slave_ar_size_i         = {3{all_axi_i}};
    assign data_slave_ar_burst_i        = {2{all_axi_i}};
    assign data_slave_ar_cache_i        = {4{all_axi_i}};
    assign data_slave_ar_qos_i          = {4{all_axi_i}};
    assign data_slave_w_writetoken_i    = {8{all_axi_i}};
    assign data_slave_r_readpointer_i   = {8{all_axi_i}};
    assign data_slave_b_readpointer_i   = {8{all_axi_i}};
    assign data_master_aw_readpointer_i = {8{all_axi_i}};
    assign data_master_ar_readpointer_i = {8{all_axi_i}};
    assign data_master_w_readpointer_i  = {8{all_axi_i}};
    assign data_master_r_writetoken_i   = {8{all_axi_i}};
    assign data_master_r_resp_i         = {2{all_axi_i}};
    assign data_master_b_writetoken_i   = {8{all_axi_i}};
    assign data_master_b_resp_i         = {2{all_axi_i}};

    assign data_slave_aw_lock_i = all_axi_i;
    assign data_slave_ar_lock_i = all_axi_i;
    assign data_slave_w_last_i  = all_axi_i;
    assign data_master_r_last_i = all_axi_i;

    assign data_slave_aw_addr_i = {AXI_ADDR_WIDTH     {all_axi_i}};
    assign data_slave_aw_id_i   = {AXI_ID_IN_WIDTH    {all_axi_i}};
    assign data_slave_aw_user_i = {AXI_USER_WIDTH     {all_axi_i}};
    assign data_slave_ar_addr_i = {AXI_ADDR_WIDTH     {all_axi_i}};
    assign data_slave_ar_id_i   = {AXI_ID_IN_WIDTH    {all_axi_i}};
    assign data_slave_ar_user_i = {AXI_USER_WIDTH     {all_axi_i}};
    assign data_slave_w_data_i  = {AXI_DATA_IN_WIDTH  {all_axi_i}};
    assign data_slave_w_strb_i  = {AXI_STRB_IN_WIDTH  {all_axi_i}};
    assign data_slave_w_user_i  = {AXI_USER_WIDTH     {all_axi_i}};
    assign data_master_r_data_i = {AXI_DATA_OUT_WIDTH {all_axi_i}};
    assign data_master_r_id_i   = {AXI_ID_OUT_WIDTH   {all_axi_i}};
    assign data_master_r_user_i = {AXI_USER_WIDTH     {all_axi_i}};
    assign data_master_b_id_i   = {AXI_ID_OUT_WIDTH   {all_axi_i}};
    assign data_master_b_user_i = {AXI_USER_WIDTH     {all_axi_i}};

    // Output AXI assignments
    assign all_axi_o = |data_slave_aw_readpointer_o ||
        |data_slave_ar_readpointer_o ||
        |data_slave_w_readpointer_o ||
        |data_slave_r_writetoken_o ||
        |data_slave_r_data_o ||
        |data_slave_r_resp_o ||
        |data_slave_r_last_o ||
        |data_slave_r_id_o ||
        |data_slave_r_user_o ||
        |data_slave_b_writetoken_o ||
        |data_slave_b_resp_o ||
        |data_slave_b_id_o ||
        |data_slave_b_user_o ||
        |data_master_aw_writetoken_o ||
        |data_master_aw_addr_o ||
        |data_master_aw_prot_o ||
        |data_master_aw_region_o ||
        |data_master_aw_len_o ||
        |data_master_aw_size_o ||
        |data_master_aw_burst_o ||
        |data_master_aw_lock_o ||
        |data_master_aw_cache_o ||
        |data_master_aw_qos_o ||
        |data_master_aw_id_o ||
        |data_master_aw_user_o ||
        |data_master_ar_writetoken_o ||
        |data_master_ar_addr_o ||
        |data_master_ar_prot_o ||
        |data_master_ar_region_o ||
        |data_master_ar_len_o ||
        |data_master_ar_size_o ||
        |data_master_ar_burst_o ||
        |data_master_ar_lock_o ||
        |data_master_ar_cache_o ||
        |data_master_ar_qos_o ||
        |data_master_ar_id_o ||
        |data_master_ar_user_o ||
        |data_master_w_writetoken_o ||
        |data_master_w_data_o ||
        |data_master_w_strb_o ||
        |data_master_w_user_o ||
        |data_master_w_last_o ||
        |data_master_r_readpointer_o ||
        |data_master_b_readpointer_o;


    soc_domain #(
        .CORE_TYPE(CORE_TYPE),
        .USE_FPU(USE_FPU),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_IN_WIDTH(AXI_DATA_IN_WIDTH),
        .AXI_DATA_OUT_WIDTH(AXI_DATA_OUT_WIDTH),
        .AXI_ID_IN_WIDTH(AXI_ID_IN_WIDTH),
        .AXI_ID_INT_WIDTH(AXI_ID_INT_WIDTH),
        .AXI_ID_OUT_WIDTH(AXI_ID_OUT_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH),
        .AXI_STRB_IN_WIDTH(AXI_STRB_IN_WIDTH),
        .AXI_STRB_OUT_WIDTH(AXI_STRB_OUT_WIDTH),
        .BUFFER_WIDTH(BUFFER_WIDTH),
        .EVNT_WIDTH(EVNT_WIDTH)
    ) i_soc_domain (
        .*
    );

endmodule
