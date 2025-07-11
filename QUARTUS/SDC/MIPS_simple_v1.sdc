#**************************************************************
# 					Create Clock
# Constrain clock port clk with a 20-ns requirement
#**************************************************************
create_clock -period 20 [get_ports in_clock]

#**************************************************************
# Automatically apply a generate clock on the output of phase-locked loops (PLLs)
# This command can be safely left in the SDC even if no PLLs exist in the design
#**************************************************************
derive_pll_clocks

#**************************************************************
# Set False Path
#**************************************************************
