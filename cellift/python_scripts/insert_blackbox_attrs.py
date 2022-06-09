# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

# This script applies on the output of sv2v to make the memories black-box before running Yosys.

import re
import sys

# sys.argv[1]: source Verilog file path
# sys.argv[2]: target Verilog file path

BLACKBOX_ATTR_REGEX = r"\(\*\s*blackbox\s*\*\)"
BLACKBOX_ATTR_TEXT  = r"\n(* blackbox *)"

IFT_ROM_MODULE_DEF_REGEX  = r"\n\s*module\s+ift_boot_rom_hdac\b"
IFT_SRAM_MODULE_DEF_REGEX = r"\n\s*module\s+ift_sram\b"
IFT_SCM_MODULE_DEF_REGEX  = r"\n\s*module\s+model_6144x32_2048x32scm\b"

if __name__ == "__main__":
    src_filename = sys.argv[1]
    tgt_filename = sys.argv[2]

    with open(src_filename, "r") as f:
        content = f.read()

    # Make sure that no blackbox attribute exists (else, this script has probably been run twice)
    # blackbox_prematches = re.search(BLACKBOX_ATTR_REGEX, content)
    # if blackbox_prematches:
    #     raise ValueError("Error: found already present blackbox attributes in file {}. Did you run the script twice?".format(src_filename))

    # # IFT ROM
    # content, nb_subs = re.subn(IFT_ROM_MODULE_DEF_REGEX, BLACKBOX_ATTR_TEXT + r"\g<0>", content, flags=re.MULTILINE)
    # if nb_subs != 1:
    #     raise ValueError("Error: found ift_boot_rom_hdac module definition {} time(s), expected exactly one definition.".format(nb_subs))

    # # IFT SRAM
    # content, nb_subs = re.subn(IFT_SRAM_MODULE_DEF_REGEX, BLACKBOX_ATTR_TEXT + r"\g<0>", content, flags=re.MULTILINE)
    # if nb_subs != 1:
    #     raise ValueError("Error: found ift_sram module definition {} time(s), expected exactly one definition.".format(nb_subs))

    # SCM
    content, nb_subs = re.subn(IFT_SCM_MODULE_DEF_REGEX, BLACKBOX_ATTR_TEXT + r"\g<0>", content, flags=re.MULTILINE)
    if nb_subs != 1:
        raise ValueError("Error: found model_6144x32_2048x32scm module definition {} time(s), expected exactly one definition.".format(nb_subs))

    with open(tgt_filename, "w") as f:
        f.write(content)
