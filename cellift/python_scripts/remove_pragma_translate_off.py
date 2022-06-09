# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

import re
import sys

# sys.argv[1]: source Verilog file path
# sys.argv[2]: target Verilog file path

PRAGMA_TRANSLATE_OFF_REGEX = r"\n\s*//\s*(pragma|synopsys) translate_off(.|\n)+?(pragma|synopsys) translate_on"

if __name__ == "__main__":
    src_filename = sys.argv[1]
    tgt_filename = sys.argv[2]

    with open(src_filename, "r") as f:
        content = f.read()

    content, nb_subs = re.subn(PRAGMA_TRANSLATE_OFF_REGEX, "", content, flags=re.MULTILINE|re.DOTALL) 

    print ("Num removed pragma_translate_off: {}".format(nb_subs))

    with open(tgt_filename, "w") as f:
        f.write(content)
