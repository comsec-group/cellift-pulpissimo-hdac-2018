set signals [list \
    "top.soc_domain.ref_clk_i" \
    "top.soc_domain.slow_clk_i" \
    "top.soc_domain.rstn_glob_i" \
]

gtkwave::addSignalsFromList $signals
