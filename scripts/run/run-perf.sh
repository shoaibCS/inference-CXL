#!/bin/bash
#
# A small example to user perf
#

# ,L1D_Cache_Fill_BW,L2_Cache_Fill_BW,L3_Cache_Access_BW,L3_Cache_Fill_BW,Load_Miss_Real_Latency,CPI,CPU_Utilization,Instructions,Kernel_Utilization,Backend_Bound,Bad_Speculation,Frontend_Bound,Retiring

sudo perf stat -e cycles -e instructions -e mem-loads -e mem-stores \
    -M L1MPKI,L2MPKI,L3MPKI,L1D_Cache_Fill_BW,L2_Cache_Fill_BW,L3_Cache_Access_BW,L3_Cache_Fill_BW,Load_Miss_Real_Latency,CPI,CPU_Utilization,Instructions,Kernel_Utilization,Backend_Bound,Bad_Speculation,Frontend_Bound,Retiring \
    -- numactl --cpunodebind=0 --membind=1 ./cmd.sh
