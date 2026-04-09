#!/bin/bash

# WSL: für Ubuntu
# sudo apt install x11-xserver-utils

xhost +local:docker
podman run --rm --replace -it --name xilinx-ise \
  -e DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v .:/xise-installer \
  -v $HOME/Xilinx:/opt/Xilinx \
  -v /mnt/c/Projects:/projects \
  -v /mnt/c/Users/admin/.Xilinx:/root/.Xilinx \
  --entrypoint "/opt/Xilinx/14.7/ISE_DS/run.sh" \
  xilinx-ise:14.7-legacy

# Entrypoint auskommentieren für Installation
# /opt/Xilinx/14.7/ISE_DS/run.sh enthält:
### #!/bin/bash
### cd /opt/Xilinx/14.7/ISE_DS
### . ./settings64.sh
### ./ISE/bin/lin64/ise
