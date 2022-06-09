# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

export TRACEFILE=$PWD/traces/sim.fst

export SIMLEN=80
export SIMROMELF=$PWD/sw/bootrom/bootrom.o

export SIMSRAMELF=$PWD/sw/bug5/main.o
export SIMSRAMTAINT=$PWD/taint_data/bug5/taint_data.txt
export INJECT_INTO_REGISTER=32
