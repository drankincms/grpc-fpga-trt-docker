#!/bin/bash

set -m

../server ./aws_hls4ml.awsxclbin 8083 8 &
./haproxy-2.0.14/haproxy -f haproxy.cfg >& srv.log

fg %1
