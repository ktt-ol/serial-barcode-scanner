all: scanner-session

scanner-session: main.vala scannersession.vala scannersession-interface.vala ../database/db-interface.vala ../serial-device/serial-device-interface.vala ../audio/audio-interface.vala ../price.vapi
	valac -o $@ --pkg gio-2.0 $^

clean:
	rm -rf scanner-session

.PHONY: all clean
