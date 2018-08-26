#!/bin/bash

dbus-daemon --system
dpkg-buildpackage -b -nc && \
    apt install -y --no-install-recommends ./../shopsystem_*_amd64.deb && \
    cp /root/config.ini /etc/shopsystem/config.ini && \
    tmux
