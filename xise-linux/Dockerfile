# Dockerfile for Xilinx ISE 14.7 on Ubuntu 22.04/16.04
#FROM ubuntu:22.04
FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DISPLAY=:0

RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    x11-apps \
    libx11-dev \
    libxt-dev \
    libxext-dev \
    libxmu-dev \
    libxi-dev \
    libxmuu-dev \
    libxft-dev \
    libxinerama-dev \
    libpng-dev \
    tcsh \
    unzip \
    xterm \
    xfonts-75dpi \
    xfonts-100dpi \
    libmotif-dev libncurses5 libstdc++5 xfonts-75dpi xfonts-100dpi libxtst6 libsm6 libxrender1 libxrandr2 xfonts-base xfonts-scalable xfonts-utils fontconfig \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/libxp6.deb https://archive.debian.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb
RUN wget -O /tmp/mas.deb http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1_amd64.deb
RUN dpkg -i /tmp/mas.deb && dpkg -i /tmp/libxp6.deb && rm /tmp/*.deb

RUN mkfontdir && mkfontscale && fc-cache -fv

CMD ["/bin/bash"]
