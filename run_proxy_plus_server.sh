#!/bin/bash

set -m

../server build_dir.hw.xilinx_u250_xdma_201830_2/alveo_hls4ml.xclbin 8083 8 &
./haproxy-2.0.14/haproxy -f haproxy.cfg >& srv.log

fg %1
