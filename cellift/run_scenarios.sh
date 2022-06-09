# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

# Make sure to have synthesized run_cellift_trace before calling this script.

#
# First, run all the experiments.
#

unset PREINJECT_INTO_GPIO_LOCK

export SIMLEN=200
export SIMROMELF=$PWD/sw/bootrom/bootrom.o

make -C $PWD/sw/bug1_6_8
export TRACEFILE=$PWD/traces/bug1_6_8.vcd
export SIMSRAMELF=$PWD/sw/bug1_6_8/main.o
export SIMSRAMTAINT=$PWD/taint_data/bug1_6_8/taint_data.txt
export INJECT_INTO_REGISTER=32
make rerun_cellift_trace

make -C $PWD/sw/bug22
export SIMSRAMELF=$PWD/sw/bug22/main.o
export SIMSRAMTAINT=$PWD/taint_data/bug22/taint_data.txt
export TRACEFILE=$PWD/traces/bug22.vcd
unset INJECT_INTO_REGISTER
make rerun_cellift_trace

make -C $PWD/sw/bug4
export SIMSRAMELF=$PWD/sw/bug4/main.o
export SIMSRAMTAINT=$PWD/taint_data/bug4/taint_data.txt
export TRACEFILE=$PWD/traces/bug4.vcd
export INJECT_INTO_REGISTER=32
make rerun_cellift_trace

make -C $PWD/sw/bug27
export SIMSRAMELF=$PWD/sw/bug27/main.o
export SIMSRAMTAINT=$PWD/taint_data/bug27/taint_data.txt
export TRACEFILE=$PWD/traces/bug27.vcd
export INJECT_INTO_REGISTER=32
make rerun_cellift_trace

make -C $PWD/sw/bug5
export SIMSRAMELF=$PWD/sw/bug5/main.o
export SIMSRAMTAINT=$PWD/taint_data/bug5/taint_data.txt
export TRACEFILE=$PWD/traces/bug5.vcd
export PREINJECT_INTO_GPIO_LOCK
make rerun_cellift_trace
unset PREINJECT_INTO_GPIO_LOCK

make -C $PWD/sw/bug25
export SIMSRAMELF=$PWD/sw/bug25/main.o
export SIMSRAMTAINT=$PWD/taint_data/bug25/taint_data.txt
export TRACEFILE=$PWD/traces/bug25.vcd
make rerun_cellift_trace

#
# Second, analyze the experiments.
#

python3 scenarios.py