#!/bin/bash

function getConfig
{
	VAR=$(echo `busctl --system call io.mainframe.shopsystem.Config /io/mainframe/shopsystem/config io.mainframe.shopsystem.Config GetString ss $1 $2 | sed -s 's;s ;;'`)
	VAR=${VAR//\"}
	echo $VAR
}

SOURCE="$(getConfig DISPLAY use)"

if [ "$SOURCE" = "mqtt" ]; then
	BROKER=$(getConfig MQTT broker)
	TOPIC=$(getConfig MQTT topic)
	ON=$(getConfig MQTT displayOn)
	OFF=$(getConfig MQTT displayOff)

	mosquitto_sub -h "$BROKER" -t "$TOPIC" | while read RAW_DATA
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
elif [ "$SOURCE" = "spaceapi" ]; then
	URL=$(getConfig SPACEAPI url)
	POLLRATE=$(getConfig SPACEAPI pollrate)
	while : ; do
		JSON=$(wget -q -O - $URL) || break
		case $(echo $JSON | jq '.state.open') in
		"true")
                        vbetool dpms on
			;;
                "false")
                        vbetool dpms off
			;;
                *)
                        #vbetool dpms on
                        ;;
                esac

		sleep $POLLRATE
	done
else
	exit 1
fi

