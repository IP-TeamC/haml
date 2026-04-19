#!/bin/bash

xhost +local:docker
podman start -ai xilinx-ise
