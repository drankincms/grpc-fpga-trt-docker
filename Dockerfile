# syntax=docker/dockerfile:experimental

FROM centos:7

RUN yum -y install git gcc-c++ epel-release kernel-devel \
    libunwind libunwind-devel make openssl-devel openssl patch \
    autoconf automake libtool file which
RUN yum -y install golang 

WORKDIR /grpc
RUN git clone -b v1.27.0 https://github.com/grpc/grpc .
RUN git submodule update --init
RUN mkdir -p cmake/build 

WORKDIR /cmake
RUN git clone -b v3.13.5 https://github.com/Kitware/CMake.git .
RUN ./bootstrap && make -j8  && make install

WORKDIR /grpc/cmake/build
RUN cmake ../..
COPY urandom_test.patch /tmp/urandom_test.patch
RUN patch -d /grpc/third_party/boringssl -p1 < /tmp/urandom_test.patch
RUN make -j 30 && make install

WORKDIR /protobuf
RUN git clone https://github.com/google/protobuf.git .
RUN ./autogen.sh && ./configure && make -j 30 && make install

ADD xrt_201920.2.3.1301_7.4.1708-xrt.rpm /tmp/xrt_201920.2.3.1301_7.4.1708-xrt.rpm
RUN yum -y localinstall /tmp/xrt_201920.2.3.1301_7.4.1708-xrt.rpm
RUN yum -y install boost-filesystem opencl-headers ocl-icd ocd-icd-devel clinfo

WORKDIR /grpc/examples/grpc-trt-fgpa
RUN git clone https://github.com/drankincms/grpc-trt-fgpa.git . -b aws

ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig

RUN git submodule update --init

RUN --mount=type=bind,target=/tools,source=/tools source /opt/xilinx/xrt/setup.sh && source /tools/xilinx/Vivado/2019.2/settings64.sh && make -j 16

WORKDIR /grpc/examples/grpc-trt-fgpa/hls4ml_c
COPY haproxy-2.0.14.tar.gz /tmp/haproxy.tar.gz
RUN tar -xvf /tmp/haproxy.tar.gz
WORKDIR haproxy-2.0.14
RUN make clean
#RUN make -j 8 TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_SYSTEMD=1 USE_THREAD=1
RUN make -j 8 TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_THREAD=1
RUN make install

WORKDIR /grpc/examples/grpc-trt-fgpa/hls4ml_c

COPY haproxy.cfg haproxy.cfg
COPY run_proxy_plus_server.sh run_proxy_plus_server.sh
#CMD source /opt/xilinx/xrt/setup.sh && ./haproxy-2.0.14/haproxy -f haproxy.cfg >& srv.log & && ../server build_dir.hw.xilinx_u250_xdma_201830_2/alveo_hls4ml.xclbin 8083 8
CMD source /opt/xilinx/xrt/setup.sh && ./run_proxy_plus_server.sh

