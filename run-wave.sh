#!/bin/bash
set -e

if [ "$#" -eq 0 ]; then
    echo "Usage: ./run-wave.sh ENTITY [STOP_TIME, default 1ms]"
    echo "Example: ./run-wave.sh bq_knnc_tb"
    exit 1
fi

mkdir -p work
cd work

echo "Import src and test..."
ghdl -i --std=93 $(find ../src -name "*.vhd") $(find ../test -name "*.vhd")

echo "Make $1..."
ghdl -m --std=93 --workdir=. $1

echo "Run $1..."
ghdl -r --std=93 $1 --stop-time=${2:-1ms} --wave=$1.ghw --assert-level=${3:-error}

echo "Wave $1..."
gtkwave $1.ghw --rcvar 'do_initial_zoom_fit yes'
