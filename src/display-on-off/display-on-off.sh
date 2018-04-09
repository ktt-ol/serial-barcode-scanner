#!/bin/bash

function getMqttConfig 
{
	echo `mdbus2 -s io.mainframe.shopsystem.Config /io/mainframe/shopsystem/config io.mainframe.shopsystem.Config.GetString MQTT $1 | cut -d"'" -f 2`
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
