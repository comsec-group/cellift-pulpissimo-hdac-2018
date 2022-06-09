#!/usr/python3

# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

import re
import sys

# sys.argv[1]: name of the Verilog file where to fix the global imports.
# sys.argv[2]: name of the Verilog saved result file.

if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise ValueError("Takes 2 arguments: the Verilog file paths.")

    with open(sys.argv[1], "r") as f:
        verilog_content = f.read()

    # Modules and interfaces
    while True:
        new_verilog_content = re.sub("\n\s*(import [a-zA-Z0-9_]+::\*;)((?:\s|\n|(?://|`)[^\n]*\n)*)((?:module|interface)(?:\s|\n)+[a-zA-Z0-9_]+)", r"\g<2>\g<3> \g<1>", verilog_content, flags=re.MULTILINE, count=0)
        has_not_changed = new_verilog_content == verilog_content
        verilog_content = new_verilog_content
        if (has_not_changed):
            break

    # Packages
    while True:
        new_verilog_content = re.sub("\n\s*(import [a-zA-Z0-9_]+::\*;)((?:\s|\n|(?://|`)[^\n]*\n)*)((?:package)(?:\s|\n)+[a-zA-Z0-9_]+\s*;)", r"\g<2>\g<3>\n\g<1>", verilog_content, flags=re.MULTILINE, count=0)
        has_not_changed = new_verilog_content == verilog_content
        verilog_content = new_verilog_content
        if (has_not_changed):
            break

    with open(sys.argv[2], "w") as f:
        f.write(verilog_content)
