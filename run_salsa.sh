#!/bin/bash
set -x
set -e

cd  ~/code
docker run -v /home/jlblanco/code/mrpt-salsa:/tmp/mrpt-salsa -it --rm mrpt_builder \
    /bin/bash -c "cd /tmp && mkdir build && cp -r mrpt-salsa build/ && cd build/mrpt-salsa && rm .vscode/ -fr && gbp buildpackage && bash"
