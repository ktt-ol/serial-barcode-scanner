#!/bin/bash

export LD_LIBRARY_PATH=/mnt/serial-barcode-scanner/libcairobarcode

dbus-daemon --system

dpkg-buildpackage -b -nc && \
    apt install -y --no-install-recommends ./../shopsystem_*_amd64.deb && \
    cp /root/config.ini /etc/shopsystem/config.ini

if [[ $? != 0 ]]; then
    echo "Build failed."
    exit 1
fi

if [[ "$1" = 'tmux' ]]; then
    tmux
fi
