#!/bin/bash

# Vorher auf Host
# sudo dnf install xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi xorg-x11-fonts-Type1 xorg-x11-fonts-misc
# xset fp rehash

xhost +local:docker
podman run --rm --replace -it --name xilinx-ise \
  -e DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v .:/xise-installer \
  -v /opt/Xilinx:/opt/Xilinx \
  -v ~/xise-projects:/projects \
  -v ~/.Xilinx:/root/.Xilinx \
  --entrypoint "/opt/Xilinx/14.7/ISE_DS/run.sh" \
  xilinx-ise:14.7-legacy

# Entrypoint auskommentieren für Installation
# /opt/Xilinx/14.7/ISE_DS/run.sh enthält:
### #!/bin/bash
### cd /opt/Xilinx/14.7/ISE_DS
### . ./settings64.sh
### ./ISE/bin/lin64/ise
