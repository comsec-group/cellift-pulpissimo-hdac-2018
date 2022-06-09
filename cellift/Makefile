# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

ifeq "" "$(CELLIFT_ENV_SOURCED)"
$(error Please re-source env.sh first, in the meta repo, and run from there, not this repo. See README.md in the meta repo)
endif

# Modelsim-specific
MODELSIM_VERSION ?= questa-2021.2

PYTHON ?= python3
RESOURCEWRAPPER_TAG ?= pulpissimo

TOP_MODULE = soc_domain
TOP_EXECUTABLE_NAME = Vsoc_domain

# Make the SoC parseable by Yosys and Verilator, and remove duplicates.
MODULES_TO_REMOVE = soc_clk_rst_gen pad_frame pulpissimo pad_functional_pd pad_functional_pu axi_cdc_src_intf axi_lite_cdc_src_intf register_file_1w_64b_1r_32b boot_rom tc_sram riscv_fpu \
model_sram_28672x32_scm_512x32 scm_512x32 freq_meter
MODULES_TO_UNIQUIFY = axi_buffer axi_slice axi_slice_wrap

# The `passthrough` target is useful so that the log matches with the sv on the generated block names, typically for ideal taint experiments.
TARGET_NAMES = vanilla cellift glift passthrough

include $(CELLIFT_DESIGN_PROCESSING_ROOT)/common/design.mk

# This target makes the design until the Yosys instrumentation. From there on, the Makefile can run in parallel for the various instrumentation targets.
before_instrumentation: generated/sv2v_out.v

#
# 1. Gather the source code.
#

generated/bender.sources: | generated
	cd ..; bender sources -f -t rtl -t synthesis -t verilator -t synth -t synth_test > cellift/$@; cd -
	sed -i 's/sv,/sv/g' $@

#
# 2. Pickle the source code.
#

generated/pickled.sv: generated/bender.sources
	morty -f $< -DVERILATOR -DSYNTHESIS -DTRACE_EXECUTION -DIFT_BLACKBOX > $@

#
# 3. Prepare the pickled file to be adapted for sv2v and Yosys.
#

generated/pickled_prepared.sv: generated/pickled.sv python_scripts/replace_instances_hdac.py | build
	$(PYTHON) python_scripts/fix_global_imports.py $< build/tmp_pickle.sv
	$(PYTHON) python_scripts/remove_modules.py build/tmp_pickle.sv build/tmp_pickle.sv $(MODULES_TO_REMOVE) $(MODULES_TO_UNIQUIFY)
	$(PYTHON) python_scripts/replace_instances_hdac.py build/tmp_pickle.sv build/tmp_pickle.sv
	$(PYTHON) python_scripts/remove_pragma_translate_off.py build/tmp_pickle.sv build/tmp_pickle.sv
# Remove all Verilog attributes.
	sed -iE 's/[\(]\*[^\*]*\*[\)]//g' build/tmp_pickle.sv
# Add the IFT bootrom and SRAM blackboxes.
	mv build/tmp_pickle.sv $@

#
# 4. Simplify the language constructs using sv2v.
#

generated/sv2v_out_pre_blackbox.v: generated/pickled_prepared.sv
	sv2v -DIFT_BLACKBOX $^ -w $@
# Add newline in the end of the file because sv2v does not.
	echo  >> $@

generated/sv2v_out.v: generated/sv2v_out_pre_blackbox.v src/ift_boot_rom_hdac_blackbox.sv src/ift_sram_blackbox.sv
	cat $^ > $@
	$(PYTHON) python_scripts/insert_blackbox_attrs.py $@ $@

#
# 5. Instrument using Yosys.
#

generated/out/vanilla.sv: generated/pickled_prepared.sv | generated/out logs
	$(PYTHON) python_scripts/remove_modules.py $< build/tmp.sv ift_boot_rom_hdac ift_sram model_6144x32_2048x32scm
	sed -E 's/[\(]\*[^\*]*\*[\)]//g' build/tmp.sv > $@
	rm -f build/tmp.sv

generated/out/vanilla.sv.log: | generated/out
	touch $@

YOSYS_INSTRUMENTATION_TARGETS_SV=$(patsubst %,generated/out/%_precompact.sv, cellift glift passthrough)

$(YOSYS_INSTRUMENTATION_TARGETS_SV): generated/out/%_precompact.sv: $(CELLIFT_YS)/instrument.ys.tcl generated/sv2v_out.v | generated/out logs
	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=$* VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_MODULE) $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) $* instr yosys -c $< -l $@.log

#
# 6. Compacify the wide concatenations.
#

OUT_SV_TARGETS_NO_VANILLA=$(patsubst %,generated/out/%.sv, cellift glift passthrough)

$(OUT_SV_TARGETS_NO_VANILLA): generated/out/%.sv: generated/out/%_precompact.sv | generated/out logs
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/expand_left_operand.py $< generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compress_concats.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/divide_concat_into_subconcats.py generated/interm.sv generated/interm.sv
	$(PYTHON) python_scripts/deparam_mem_module_names.py generated/interm.sv generated/interm.sv
	cat generated/interm.sv > $@
	rm -f generated/interm.sv
	cp $<.log $@.log

#
# 7. Build with Verilator through FuseSoC
# - properly run with Verilator.
# - insert the right SRAMs.
#

# Phony targets

PREPARE_TARGETS_NOTRACE=$(patsubst %,prepare_%_notrace, $(TARGET_NAMES))
PREPARE_TARGETS_TRACE=$(patsubst %,prepare_%_trace, $(TARGET_NAMES))
PREPARE_TARGETS_TRACE_FST=$(patsubst %,prepare_%_trace_fst, $(TARGET_NAMES))
.PHONY: $(PREPARE_TARGETS_NOTRACE)  
$(PREPARE_TARGETS_NOTRACE) $(PREPARE_TARGETS_TRACE): prepare_%: build/run_%_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)

# Actual targets

BUILD_TARGETS_NOTRACE=$(patsubst %,build/run_%_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME), $(TARGET_NAMES))
BUILD_TARGETS_TRACE=$(patsubst %,build/run_%_trace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME), $(TARGET_NAMES))
BUILD_TARGETS_TRACE_FST=$(patsubst %,build/run_%_trace_fst_0.1/default-verilator/$(TOP_EXECUTABLE_NAME), $(TARGET_NAMES))

$(BUILD_TARGETS_NOTRACE): build/run_%_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME): generated/out/%.sv generated/out/%.sv.log src/ift_boot_rom_hdac.sv src/model_6144x32_2048x32scm.sv src/ift_sram.sv
	rm -f fusesoc.conf
	fusesoc library add run_$*_notrace .
	$(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) $*_notrace synth fusesoc run --build run_$*_notrace
	cp $<.log $@.log
$(BUILD_TARGETS_TRACE): build/run_%_trace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME): generated/out/%.sv generated/out/%.sv.log src/ift_boot_rom_hdac.sv src/model_6144x32_2048x32scm.sv src/ift_sram.sv
	rm -f fusesoc.conf
	fusesoc library add run_$*_trace .
	$(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) $*_trace synth fusesoc run --build run_$*_trace
	cp $<.log $@.log
$(BUILD_TARGETS_TRACE_FST): build/run_%_trace_fst_0.1/default-verilator/$(TOP_EXECUTABLE_NAME): generated/out/%.sv generated/out/%.sv.log src/ift_boot_rom_hdac.sv src/model_6144x32_2048x32scm.sv src/ift_sram.sv
	rm -f fusesoc.conf
	fusesoc library add run_$*_trace_fst .
	$(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) $*_trace_fst synth fusesoc run --build run_$*_trace_fst
	cp $<.log $@.log

#
# Recompile, if only the Verilator C++ testbench has changed
#

RECOMPILE_TARGETS_NOTRACE=$(patsubst %,recompile_%_notrace, $(TARGET_NAMES))
RECOMPILE_TARGETS_TRACE=$(patsubst %,recompile_%_trace, $(TARGET_NAMES))
RECOMPILE_TARGETS_TRACE_FST=$(patsubst %,recompile_%_trace_fst, $(TARGET_NAMES))
RECOMPILE_TARGETS = $(RECOMPILE_TARGETS_NOTRACE) $(RECOMPILE_TARGETS_TRACE) $(RECOMPILE_TARGETS_TRACE_FST)

.PHONY: $(RECOMPILE_TARGETS)
$(RECOMPILE_TARGETS): recompile_%: build/run_%_0.1
	rm -f $</default-verilator/toplevel.o
	rm -f $</default-verilator/$(TOP_EXECUTABLE_NAME)
	rm -rf $</src/run_$*_0.1/dv
	rm -rf ./build/dv
	cp -r dv $</src/run_$*_0.1
	cp -r $(CELLIFT_DESIGN_PROCESSING_ROOT)/common/dv ./build
	make -C $</default-verilator


#
# Rerun, while making sure that nothing will be recompiled because of this call.
#

RERUN_TARGETS_NOTRACE=$(patsubst %,rerun_%_notrace, $(TARGET_NAMES))
RERUN_TARGETS_TRACE=$(patsubst %,rerun_%_trace, $(TARGET_NAMES))
RERUN_TARGETS_TRACE_FST=$(patsubst %,rerun_%_trace_fst, $(TARGET_NAMES))
RERUN_TARGETS = $(RERUN_TARGETS_NOTRACE) $(RERUN_TARGETS_TRACE) $(RERUN_TARGETS_TRACE_FST)

.PHONY: $(RERUN_TARGETS)
$(RERUN_TARGETS_TRACE) $(RERUN_TARGETS_TRACE_FST): | traces
$(RERUN_TARGETS): rerun_%: build/run_%_0.1/
	$</default-verilator/$(TOP_EXECUTABLE_NAME)

#
# Run, potentially after compiling.
#

RUN_TARGETS_NOTRACE=$(patsubst %,run_%_notrace, $(TARGET_NAMES))
RUN_TARGETS_TRACE=$(patsubst %,run_%_trace, $(TARGET_NAMES))
RUN_TARGETS_TRACE_FST=$(patsubst %,run_%_trace_fst, $(TARGET_NAMES))
RUN_TARGETS = $(RUN_TARGETS_NOTRACE) $(RUN_TARGETS_TRACE) $(RUN_TARGETS_TRACE_FST)

$(RUN_TARGETS_TRACE) $(RUN_TARGETS_TRACE_FST): | traces
$(RUN_TARGETS): run_%: ./build/run_%_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)
	cd build/run_$*_0.1/default-verilator && $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) $* run ./$(TOP_EXECUTABLE_NAME)

#
# Extract Yosys cell statistics
#

STATISTICS_TARGETS=$(patsubst %,statistics/%.log, $(TARGET_NAMES))

$(STATISTICS_TARGETS): statistics/%.log: $(CELLIFT_YS)/statistics.ys.tcl generated/sv2v_out.v | statistics
	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=$* TOP_MODULE=$(TOP_MODULE) $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) $* stat yosys -c $< -l $@
