#!/bin/bash

xhost +local:docker
podman start -ai xilinx-ise
podman exec -it xilinx-ise /opt/Xilinx/14.7/ISE_DS/run.sh
