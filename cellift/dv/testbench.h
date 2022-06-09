// Copyright 2022 Flavien Solt, ETH Zurich.
// Licensed under the General Public License, Version 3.0, see LICENSE for details.
// SPDX-License-Identifier: GPL-3.0-only

#include "Vsoc_domain.h"
#include "verilated.h"

#include "Vsoc_domain__Syms.h"
#include "Vsoc_domain___024root.h"

#if VM_TRACE
#if VM_TRACE_FST
#include <verilated_fst_c.h>
#else
#include <verilated_vcd_c.h>
#endif // VM_TRACE_FST
#endif // VM_TRACE

#include <iostream>
#include <stdlib.h>

#ifndef TESTBENCH_H
#define TESTBENCH_H

#define PRECISE_RANDOM_INPUTS 1

const int kResetLength = 5;
// Depth of the trace.
const int kTraceLevel = 6;

typedef Vsoc_domain Module;

#ifdef IS_VANILLA
static inline bool is_mem_addr_accessed(std::string prefix, unsigned char *reqn_ptr, unsigned int *addr_ptr, unsigned char *wen_ptr, unsigned char *be_ptr, long unsigned int addr, unsigned int addr_mask=0x7FF, bool verbose=false){
#else // IS_VANILLA
static inline bool is_mem_addr_accessed(std::string prefix, unsigned char *reqn_ptr, unsigned int *addr_ptr, unsigned char *wen_ptr, unsigned int *be_ptr, long unsigned int addr, unsigned int addr_mask=0x7FF, bool verbose=false){
#endif
  bool is_req = (!(*reqn_ptr>>1)) & 1;
#ifdef IS_VANILLA
  bool is_we = (!(*wen_ptr>>1)) & ((*be_ptr & 0x10U) >> 4) & 1;
  if (verbose && is_req && is_we) {
    printf("%s: 0x%4lx, we: %d, mask: 0x%x, req: %d\n", prefix.c_str(), *addr_ptr << 2, is_we, addr_mask, is_req);
    printf("Addr ptr val: %x, addr val: %x\n", *addr_ptr << 2, addr);
  }
  return is_req && is_we && ((*addr_ptr << 2) & addr_mask) == addr;
#else // IS_VANILLA
  bool is_we = (!(*wen_ptr>>4)) & ((*be_ptr & 0x10000U) >> 16) & 1;
  if (verbose && is_req && is_we) {
    printf("%s: 0x%4lx, we: %d, mask: 0x%x, req: %d\n", prefix.c_str(), *addr_ptr >> 13, is_we, addr_mask, is_req);
    printf("Addr ptr val: %x, addr val: %x\n", *addr_ptr >> 13, addr);
  }
  return is_req && is_we && ((*addr_ptr >> 13) & addr_mask) == addr;
#endif
}

class Testbench {
 public:
  Testbench(const std::string &trace_filename = "", bool autostop = false)
      : module_(new Module), tick_count_(0l), autostop(autostop) {
#if VM_TRACE
#if VM_TRACE_FST
    trace_ = new VerilatedFstC;
#else // VM_TRACE_FST
    trace_ = new VerilatedVcdC;
#endif // VM_TRACE_FST
    module_->trace(trace_, kTraceLevel);
    trace_->open(trace_filename.c_str());
#endif // VM_TRACE
  }

  ~Testbench(void) { close_trace(); }

  void reset(void) {
    module_->rstn_glob_i = 1;
    this->tick(1);
    module_->rstn_glob_i = 0;
    this->tick(kResetLength);
    module_->rstn_glob_i = 1;
  }

  void close_trace(void) {
#if VM_TRACE  
    trace_->close();
#endif // VM_TRACE
  }

  bool is_autostop() {
    return autostop;
  };
  void set_autostop(bool new_autostop) {
    autostop = new_autostop;
  };

  /**
   * Performs one or multiple clock cycles.
   *
   * @param num_ticks the number of ticks to perform. A value of -1 means autostop.
   */
   // @return true iff the benchmark was autostopped.
  bool tick(int num_ticks = 1, bool false_tick = false) {
    for (size_t i = 0; i < num_ticks || num_ticks == -1; i++) {
      tick_count_++;

      module_->ref_clk_i = 0;
      module_->slow_clk_i = 0;
      module_->test_clk_i = 0;
      module_->eval();

#ifdef IS_VANILLA
      if (autostop) {
        if (is_mem_addr_accessed("Addr: ", &(module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__i_soc_interconnect_wrap__DOT__mem_pri_csn), &(module_->rootp->vlSymsp->TOP.__PVT__soc_domain__DOT__pulp_soc_i__DOT__s_mem_l2_pri_bus__BRA__1__KET__->add), &(module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__i_soc_interconnect_wrap__DOT__mem_pri_wen), &(module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__i_soc_interconnect_wrap__DOT____Vcellout__i_soc_interconnect__L2_pri_BE_o), 0, 0x1FFF, true)) {
          printf("Mem accessed!\n");
          return true;
        }
      }
#else // IS_VANILLA
      if (autostop) {
        if (is_mem_addr_accessed("Addr: ", &(module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__i_soc_interconnect_wrap__02emem_pri_csn), &(module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__i_soc_interconnect_wrap__02emem_pri_add), &(module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__i_soc_interconnect_wrap__02ei_soc_interconnect__DOT__PER_data_wen_TO_BRIDGE), &(module_->rootp->vlSymsp->TOP.soc_domain__DOT__pulp_soc_i__DOT__i_soc_interconnect_wrap__02ei_soc_interconnect__DOT__PER_data_be_TO_BRIDGE), 0, 0x1FFF, true)) {
          printf("Mem accessed!\n");
          return true;
        }
      }
#endif // IS_VANILLA

#if VM_TRACE
      trace_->dump(5 * tick_count_ - 1);
#endif // VM_TRACE

      module_->ref_clk_i = !false_tick;
      module_->slow_clk_i = !false_tick;
      module_->test_clk_i = !false_tick;
      module_->eval();

#if VM_TRACE
      trace_->dump(5 * tick_count_);
#endif // VM_TRACE

      module_->ref_clk_i = 0;
      module_->slow_clk_i = 0;
      module_->test_clk_i = 0;
      module_->eval();

#if VM_TRACE
      trace_->dump(5 * tick_count_ + 2);
      trace_->flush();
#endif // VM_TRACE
    }
    return false;
  }

  std::unique_ptr<Module> module_;
 private:
  vluint32_t tick_count_;
  bool autostop;

#if VM_TRACE
#if VM_TRACE_FST
  VerilatedFstC *trace_;
#else
  VerilatedVcdC *trace_;
#endif // VM_TRACE_FST
#endif // VM_TRACE

  // Masks that contain ones in the corresponding fields.
  uint32_t id_mask_;
  uint32_t content_mask_;
};

#endif // TESTBENCH_H
