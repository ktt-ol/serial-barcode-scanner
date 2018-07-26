#!/bin/bash

cd dbus
make install
cd config
make install

export LD_LIBRARY_PATH=/mnt/serial-barcode-scanner/libcairobarcode

cd ../..
dbus-daemon --system
echo "Ready!"
tmux
