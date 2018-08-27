#!/bin/bash

function getMqttConfig
{
	echo `busctl --system call io.mainframe.shopsystem.Config /io/mainframe/shopsystem/config io.mainframe.shopsystem.Config GetString ss MQTT $1 | sed -s "s;s ;;"`
}

BROKER=$(getMqttConfig broker)
TOPIC=$(getMqttConfig topic)
ON=$(getMqttConfig displayOn)
OFF=$(getMqttConfig displayOff)

mosquitto_sub -h $BROKER -t $TOPIC | while read RAW_DATA
do
	case $RAW_DATA	in
	$ON)
		vbetool dpms on
		;;
	$OFF)
		vbetool dpms off
		;;
	*)
		#vbetool dpms on
		;;
	esac
done
