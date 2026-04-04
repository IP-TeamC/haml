#!/bin/bash

# Vorher auf Host
# sudo dnf install xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi xorg-x11-fonts-Type1 xorg-x11-fonts-misc
# xset fp rehash

podman run --rm --replace -it --name xilinx-ise \
  -e DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v .:/xise-installer \
  -v /opt/Xilinx:/opt/Xilinx \
  -v ~/xise-projects:/projects \
  -v ~/.Xilinx:/root/.Xilinx \
  xilinx-ise:14.7-legacy
