# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

# This script runs the scenarios from the CellIFT paper. It should be called through run_scenarios.sh.

import os
from vcdvcd import VCDVCD

experiment_names = [
    'bug1_6_8',
    'bug22',
    'bug4',
    'bug27',
    'bug5',
    'bug25',
]

for experiment_name in experiment_names:
    experiment_vcd_path = os.path.join('traces', f"{experiment_name}.vcd")

    # Do the parsing.
    vcd = VCDVCD(experiment_vcd_path)

    #
    # Check experiment by experiment
    #

    if experiment_name == 'bug1_6_8':
        # We confirm here that there is taint in the SPI, in the GPIO and in SoC control
        is_gpio_tainted    = False
        is_spi_tainted     = False
        is_socctrl_tainted = False
        # GPIO
        for signame in vcd.references_to_ids:
            if not is_gpio_tainted and 'gpio' in signame and '_t0' in signame:
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar != '0':
                            is_gpio_tainted = True 
                            break
                    if is_gpio_tainted:
                        break
        # SPI master
        for signame in vcd.references_to_ids:
            if not is_spi_tainted and 'udma' in signame and 'spim' in signame and '_t0' in signame:
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar != '0':
                            is_spi_tainted = True 
                            break
                    if is_spi_tainted:
                        break
        # SoC control
        for signame in vcd.references_to_ids:
            if not is_socctrl_tainted and 'soc' in signame and 'ctrl' in signame and '_t0' in signame:
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar != '0':
                            is_socctrl_tainted = True 
                            break
                    if is_socctrl_tainted:
                        break

        if is_spi_tainted and is_gpio_tainted:
            print("Bug 1 detected:  SPI and GPIO are tainted with the same store operation.")
        if is_socctrl_tainted and is_gpio_tainted:
            print("Bug 6 detected:  SoC control and GPIO (APB) are tainted with the same store operation.")
        if is_spi_tainted and is_socctrl_tainted and is_gpio_tainted:
            print("Bug 8 detected:  SoC control and SPI and GPIO are tainted with the same store operation.")

    if experiment_name == 'bug22':
        is_regfile_tainted = False
        for signame in vcd.references_to_ids:
            if not is_regfile_tainted and 'id_stage' in signame and 'registers' in signame and 'mem_t0' in signame:
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar != '0':
                            is_regfile_tainted = True 
                            break
                    if is_regfile_tainted:
                        break
        # For convenience, we have increased the size of the ROM manually, so we removed this bug.
        # To see the bug again live, please re-reduce the ROM size and invert the condition below.
        if is_regfile_tainted:
            print("Bug 22 detected: ROM was smaller than expected.")

    if experiment_name == 'bug4':
        is_gpio_lock_tainted = False
        for signame in vcd.references_to_ids:
            if not is_gpio_lock_tainted and 'gpio_lock_t0' in signame:
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar != '0':
                            is_gpio_lock_tainted = True 
                            break
                    if is_gpio_lock_tainted:
                        break
        if is_gpio_lock_tainted:
            print("Bug 4 detected:  GPIO lock has been written to by software.")

    if experiment_name == 'bug27':
        is_irq_mask_tainted = False
        for signame in vcd.references_to_ids:
            if not is_irq_mask_tainted and 'fc_eu_i' in signame and 'mask' in signame and '_t0' in signame:
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar != '0':
                            is_irq_mask_tainted = True 
                            break
                    if is_irq_mask_tainted:
                        break
        if is_irq_mask_tainted:
            print("Bug 27 detected: Interrupt mask written from user mode.")

    if experiment_name == 'bug5':
        is_gpio_lock_untainted = False
        for signame in vcd.references_to_ids:
            if not is_gpio_lock_untainted and 'gpio_lock_t0' in signame:
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar == '0':
                            is_gpio_lock_untainted = True 
                            break
                    if is_gpio_lock_untainted:
                        break
        if is_gpio_lock_untainted:
            print("Bug 5 detected:  GPIO lock has been reset.")

    if experiment_name == 'bug25':
        candidate_csr_taint_time = None
        do_taint_times_match = True
        for signame in vcd.references_to_ids:
            if not candidate_csr_taint_time and 'cs_registers_i' and 'q_t0' in signame and ('mstatus' in signame or 'mcause' in signame or 'utvec_o' in signame or 'ucause_q' in signame):
                for tvpair in vcd[signame].tv:
                    for mychar in tvpair[1]:
                        if mychar != '0':
                            curr_taint_time = tvpair[0]
                            if candidate_csr_taint_time is None:
                                candidate_csr_taint_time = curr_taint_time
                            else:
                                if curr_taint_time != candidate_csr_taint_time:
                                    do_taint_times_match = False
                    if not do_taint_times_match:
                        break
        if do_taint_times_match:
            print("Bug 25 hinted:   No mismatch in taint occurrence clock cycles.")

print("Experiment complete.")