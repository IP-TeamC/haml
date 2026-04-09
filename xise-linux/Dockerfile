# Dockerfile for Xilinx ISE 14.7 on Ubuntu 14.04
FROM ubuntu:14.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV DISPLAY=:0
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

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
    expect libfontconfig1 libfreetype6 libglib2.0-0 libsm6 libxi6 locales sudo libxp6 multiarch-support
RUN rm -rf /var/lib/apt/lists/*

# Kram für Ubuntu ab 16.04, lieber ganz alt... :)
#RUN wget -O /tmp/libxp6.deb https://archive.debian.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb
#RUN wget -O /tmp/mas.deb http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1_amd64.deb
#RUN dpkg -i /tmp/mas.deb && dpkg -i /tmp/libxp6.deb && rm /tmp/*.deb

RUN mkfontdir && mkfontscale && fc-cache -fv

CMD ["/bin/bash"]
