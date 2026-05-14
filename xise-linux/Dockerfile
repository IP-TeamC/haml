# Dockerfile for Xilinx ISE 14.7 on Ubuntu 14.04
FROM ubuntu:14.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV DISPLAY=:0
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

RUN dpkg --add-architecture i386 && apt update
RUN apt install -y \
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
    expect libfontconfig1 libfreetype6 libglib2.0-0 libsm6 libxi6 locales sudo libxp6 multiarch-support \
    libc6:i386 libstdc++6:i386 zlib1g:i386 libncurses5:i386 libx11-6:i386 libxext6:i386 lsb-core \
    openssh-server openssh-client
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.ssh && \
    ssh-keygen -t rsa -b 2048 -N "" -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    chmod 700 /root/.ssh && \
    ssh-keygen -A && \
    mkdir /var/run/sshd && \
    /usr/sbin/sshd

RUN mkfontdir && mkfontscale && fc-cache -fv

CMD ["/bin/bash"]
