// Copyright 2022 Flavien Solt, ETH Zurich.
// Licensed under the General Public License, Version 3.0, see LICENSE for details.
// SPDX-License-Identifier: GPL-3.0-only

#include <chrono>

#include "testbench.h"
#include "ticks.h"

#include "Vsoc_domain__Syms.h"
#include "Vsoc_domain___024root.h"


static bool is_autostop(void)
{
  const char *autostop_env = std::getenv("AUTOSTOP"); // allow override for batch execution from python
  return autostop_env != NULL;
}

// Sets the n LSBs to 1 and the rest to 0.
static uint32_t set_n_lsbs (int n) {
  // Could be more efficient but only called 1 time so ok
  assert (n >= 0);
  assert (n <= 32);
  uint32_t ret = 0;
  for (int i = 0; i < n; i++) {
    ret |= 1 << i;
  }
  return ret;
}

/**
 * Runs the testbench.
 *
 * @param tb a pointer to a testbench instance
 */
static unsigned long run_test(Testbench *tb, int simlen, const char* inject_in_register_env, const char* preinject_into_gpio_lock_env) {
  // Iniialize all inputs to zero.
  tb->module_->ref_clk_i = 0L;
  tb->module_->slow_clk_i = 0L;
  tb->module_->test_clk_i = 0L;
  tb->module_->rstn_glob_i = 0L;
  tb->module_->dft_test_mode_i = 0L;
  tb->module_->dft_cg_enable_i = 0L;
  tb->module_->mode_select_i = 0L;
  tb->module_->sel_fll_clk_i = 0L;
  tb->module_->soc_jtag_reg_i = 0L;
  tb->module_->boot_l2_i = 0L;
  tb->module_->jtag_tck_i = 0L;
  tb->module_->jtag_tms_i = 0L;
  tb->module_->jtag_td_i = 0L;
  tb->module_->jtag_axireg_tdi_i = 0L;
  tb->module_->jtag_axireg_sel_i = 0L;
  tb->module_->jtag_shift_dr_i = 0L;
  tb->module_->jtag_update_dr_i = 0L;
  tb->module_->jtag_capture_dr_i = 0L;
  tb->module_->gpio_in_i = 0L;
  tb->module_->uart_rx_i = 0L;
  tb->module_->cam_clk_i = 0L;
  tb->module_->cam_data_i = 0L;
  tb->module_->cam_hsync_i = 0L;
  tb->module_->cam_vsync_i = 0L;
  tb->module_->i2c0_scl_i = 0L;
  tb->module_->i2c0_sda_i = 0L;
  tb->module_->i2c1_scl_i = 0L;
  tb->module_->i2c1_sda_i = 0L;
  tb->module_->i2s_sd0_i = 0L;
  tb->module_->i2s_sd1_i = 0L;
  tb->module_->i2s_sck_i = 0L;
  tb->module_->i2s_ws_i = 0L;
  tb->module_->spi_master0_sdi0_i = 0L;
  tb->module_->spi_master0_sdi1_i = 0L;
  tb->module_->spi_master0_sdi2_i = 0L;
  tb->module_->spi_master0_sdi3_i = 0L;
  tb->module_->sdio_cmd_i = 0L;
  tb->module_->sdio_data_i = 0L;
  tb->module_->cluster_busy_i = 0L;
  tb->module_->cluster_events_rp_i = 0L;
  tb->module_->dma_pe_evt_valid_i = 0L;
  tb->module_->dma_pe_irq_valid_i = 0L;
  tb->module_->pf_evt_valid_i = 0L;
  tb->module_->data_slave_aw_writetoken_i = 0L;
  tb->module_->data_slave_aw_addr_i = 0L;
  tb->module_->data_slave_aw_prot_i = 0L;
  tb->module_->data_slave_aw_region_i = 0L;
  tb->module_->data_slave_aw_len_i = 0L;
  tb->module_->data_slave_aw_size_i = 0L;
  tb->module_->data_slave_aw_burst_i = 0L;
  tb->module_->data_slave_aw_lock_i = 0L;
  tb->module_->data_slave_aw_cache_i = 0L;
  tb->module_->data_slave_aw_qos_i = 0L;
  tb->module_->data_slave_aw_id_i = 0L;
  tb->module_->data_slave_aw_user_i = 0L;
  tb->module_->data_slave_ar_writetoken_i = 0L;
  tb->module_->data_slave_ar_addr_i = 0L;
  tb->module_->data_slave_ar_prot_i = 0L;
  tb->module_->data_slave_ar_region_i = 0L;
  tb->module_->data_slave_ar_len_i = 0L;
  tb->module_->data_slave_ar_size_i = 0L;
  tb->module_->data_slave_ar_burst_i = 0L;
  tb->module_->data_slave_ar_lock_i = 0L;
  tb->module_->data_slave_ar_cache_i = 0L;
  tb->module_->data_slave_ar_qos_i = 0L;
  tb->module_->data_slave_ar_id_i = 0L;
  tb->module_->data_slave_ar_user_i = 0L;
  tb->module_->data_slave_w_writetoken_i = 0L;
  tb->module_->data_slave_w_data_i = 0L;
  tb->module_->data_slave_w_strb_i = 0L;
  tb->module_->data_slave_w_user_i = 0L;
  tb->module_->data_slave_w_last_i = 0L;
  tb->module_->data_slave_r_readpointer_i = 0L;
  tb->module_->data_slave_b_readpointer_i = 0L;
  tb->module_->data_master_aw_readpointer_i = 0L;
  tb->module_->data_master_ar_readpointer_i = 0L;
  tb->module_->data_master_w_readpointer_i = 0L;
  tb->module_->data_master_r_writetoken_i = 0L;
  tb->module_->data_master_r_data_i = 0L;
  tb->module_->data_master_r_resp_i = 0L;
  tb->module_->data_master_r_last_i = 0L;
  tb->module_->data_master_r_id_i = 0L;
  tb->module_->data_master_r_user_i = 0L;
  tb->module_->data_master_b_writetoken_i = 0L;
  tb->module_->data_master_b_resp_i = 0L;
  tb->module_->data_master_b_id_i = 0L;
  tb->module_->data_master_b_user_i = 0L;
  
  // Boot from L2.
  tb->module_->boot_l2_i = 1;

  // Preinject if requested (typically to find registers that are not being reset correctly)
#if !defined(IS_VANILLA) && !defined(IS_PASSTHROUGH)
  if (preinject_into_gpio_lock_env != NULL) {
    tb->module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__soc_peripherals_i__02eapb_gpio_i__DOT__r_gpio_lock_t0 = -1;
    tb->tick(2);
  }
#endif // !defined(IS_VANILLA) && !defined(IS_PASSTHROUGH)

  std::chrono::time_point<std::chrono::steady_clock> start, stop;

#if defined(IS_VANILLA) || defined(IS_PASSTHROUGH)
    return tb_run_ticks(tb, simlen, true);
#else // IS_VANILLA || IS_PASSTHROUGH
  if (inject_in_register_env != NULL) {
    // Transform env var to int
    // Read at what time to inject taints
    unsigned int injection_time = 0;
    std::stringstream ss;
    ss << std::dec << inject_in_register_env;
    ss >> injection_time;

    // Number of bits to taint
    std::cout << "Will inject taint into register at cycle " << injection_time << std::endl;

    tb->reset();
    start = std::chrono::steady_clock::now();
    tb->tick(injection_time);
    // Inject the taint into register x2
    tb->module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__fc_subsystem_i__02eFC_CORE__02elFC_CORE__DOT__id_stage_i__DOT__registers_i__DOT__mem_t0[2U] = -1;
    tb->tick(simlen-injection_time);
    stop = std::chrono::steady_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(stop - start).count();
  } else {
    // If no injection required, run normally.
    return tb_run_ticks(tb, simlen, true);
  }
#endif // IS_VANILLA || IS_PASSTHROUGH
}


int main(int argc, char **argv, char **env) {

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(VM_TRACE);

  ////////
  // Get the env vars early to avoid Verilator segfaults.
  ////////

  bool autostop = is_autostop();
  int simlen = get_sim_length_cycles(0);

  const char* inject_in_register_env = std::getenv("INJECT_INTO_REGISTER"); // Inject into the register. Must contain the injection time in cycles
  const char* preinject_into_gpio_lock_env = std::getenv("PREINJECT_INTO_GPIO_LOCK");

  ////////
  // Initialize testbench.
  ////////

  Testbench *tb = new Testbench(cl_get_tracefile(), autostop);

  if (autostop)
    std::cout << "The testbench will autostop at the end of the benchmark and run for a maximum of SIMLEN cycles." << std::endl;
  else
    std::cout << "The testbench will not autostop at the end of the benchmark." << std::endl;

  if (inject_in_register_env != NULL) {
    std::cout << "Will inject taints into register." << std::endl;
  } else {
    std::cout << "No taint injection will be performed." << std::endl;
  }

  ////////
  // Run the testbench.
  ////////

  unsigned int duration = run_test(tb, simlen, inject_in_register_env, preinject_into_gpio_lock_env);

  ////////
  // Display the results.
  ////////

#if VM_TRACE
  std::cout << "Testbench with traces complete!" << std::endl;
  std::cout << "Elapsed time: " << std::dec << duration << "." << std::endl;
#else // VM_TRACE
  std::cout << "Testbench complete!" << std::endl;
  std::cout << "Elapsed time (traces enabled): " << std::dec << duration << "." << std::endl;
#endif // VM_TRACE

  delete tb;
  exit(0);
}
