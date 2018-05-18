#!/bin/bash
DBUS_FILE=/root/dbus.env

if [ "$SBC_DIR" == "" ]; then
  echo "SBC_DIR not set"
  exit 1
fi

if [ -f $DBUS_FILE ]; then
  echo "Already initialized."
  . $DBUS_FILE
else
  dbus-launch --sh-syntax > $DBUS_FILE
  . $DBUS_FILE

  mkdir -p $SBC_DIR

  # create symlink for service files that autostarts the single binaries
  mkdir -p /root/.local/share/dbus-1
  if [[ ! -d /root/.local/share/dbus-1/services ]]; then
    ln -s $SBC_DIR/dbus /root/.local/share/dbus-1/services
  fi
fi
