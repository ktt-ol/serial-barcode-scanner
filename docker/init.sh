#!/bin/bash

cd dbus
make install
cd config
make install

cd ../..
dbus-daemon --system
echo "Ready!"
tmux
