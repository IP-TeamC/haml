#!/bin/bash

rm -f haml.zip
zip -r haml.zip codegen/src codegen/pom.xml data docs software src test ds_v6.xds haml.ucf haml.xise README.md run-wave.sh run.sh vhdl_ls.toml -x "docs/.vitepress/*" -x "docs/public/*" -x docs/index.md -x docs/about.md